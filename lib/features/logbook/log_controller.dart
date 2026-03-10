import 'dart:async';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:logbook_app/services/mongo_service.dart';
import 'package:logbook_app/services/connectivity_service.dart';
import 'package:logbook_app/services/access_control_service.dart';
import 'package:logbook_app/helpers/log_helper.dart';
import 'models/log_model.dart';

class LogController {
  final String currentUsername;
  final String currentUserId;
  final String currentUserRole;
  final String teamId;

  final ValueNotifier<List<LogModel>> logsNotifier = ValueNotifier([]);
  final ValueNotifier<bool> isLoading = ValueNotifier(false);
  final ValueNotifier<String?> errorMessage = ValueNotifier(null);
  final ValueNotifier<String> searchQueryNotifier = ValueNotifier('');
  late final ValueNotifier<List<LogModel>> filteredLogsNotifier;

  Box<LogModel>? _hiveBox;
  bool _isInitialized = false;
  late final Future<void> initializationFuture;
  final MongoService _mongoService = MongoService();
  Timer? _syncTimer;

  LogController({
    required this.currentUsername,
    required this.currentUserId,
    this.currentUserRole = 'Anggota',
    required this.teamId,
  }) {
    initializationFuture = _initialize();
    _setupFilteredLogsNotifier();
  }

  /// Setup filtered logs notifier to reactively update when search query or logs change
  void _setupFilteredLogsNotifier() {
    filteredLogsNotifier = ValueNotifier([]);

    void updateFilteredLogs() {
      final allLogs = logsNotifier.value;
      final query = searchQueryNotifier.value.toLowerCase();

      if (query.isEmpty) {
        filteredLogsNotifier.value = allLogs;
      } else {
        filteredLogsNotifier.value = allLogs.where((log) {
          final titleMatch = log.title.toLowerCase().contains(query);
          final descMatch = log.description.toLowerCase().contains(query);
          return titleMatch || descMatch;
        }).toList();
      }
    }

    logsNotifier.addListener(updateFilteredLogs);
    searchQueryNotifier.addListener(updateFilteredLogs);

    // Initial update
    updateFilteredLogs();
  }

  /// Update search query and trigger filtering
  void updateSearchQuery(String query) {
    searchQueryNotifier.value = query;
  }

  /// Inisialisasi Hive box dan setup background sync listener
  Future<void> _initialize() async {
    try {
      final startTime = DateTime.now();

      await LogHelper.writeLog(
        "INFO: LogController._initialize() starting...",
        source: "log_controller.dart",
        level: 3,
      );

      // Try to get box (should already be open from main.dart)
      try {
        _hiveBox = Hive.box<LogModel>('offline_logs');
        await LogHelper.writeLog(
          "INFO: Hive.box('offline_logs') obtained successfully",
          source: "log_controller.dart",
          level: 3,
        );
      } catch (boxError) {
        await LogHelper.writeLog(
          "ERROR: Failed to get Hive box - $boxError",
          source: "log_controller.dart",
          level: 1,
        );
        rethrow;
      }

      _isInitialized = true;

      await LogHelper.writeLog(
        "INFO: Hive box 'offline_logs' siap",
        source: "log_controller.dart",
        level: 3,
      );

      // Setup background sync listener
      _setupBackgroundSync();

      // Load data awal dari Hive
      await loadLogs(teamId);

      // Ensure loading screen is visible for at least 1.5 seconds
      final elapsed = DateTime.now().difference(startTime);
      if (elapsed.inMilliseconds < 1500) {
        await Future.delayed(
          Duration(milliseconds: 1500 - elapsed.inMilliseconds),
        );
      }
    } catch (e) {
      _isInitialized = false;
      await LogHelper.writeLog(
        "ERROR: Initialization failed - $e",
        source: "log_controller.dart",
        level: 1,
      );
      rethrow; // Let the Future complete with error so initializationFuture captures it
    }
  }

  /// ========== 4.2: LOAD DATA (Offline-First Strategy) ==========
  /// Langkah 1: Ambil data dari Hive (sangat cepat/instan)
  /// Langkah 2: Sync dari Cloud di background (non-blocking)
  Future<void> loadLogs(String teamId) async {
    try {
      // Ensure initialization is complete
      if (!_isInitialized) {
        await initializationFuture;
      }

      // Guard: Pastikan Hive box sudah initialized
      if (_hiveBox == null) {
        await LogHelper.writeLog(
          "WARNING: Hive box not yet initialized, deferring load",
          source: "log_controller.dart",
          level: 2,
        );
        await Future.delayed(const Duration(milliseconds: 500));
        return;
      }

      // Load dari Hive (INSTAN)
      final hiveData = _hiveBox!.values
          .where((log) => log.teamId == teamId)
          .toList();

      logsNotifier.value = hiveData;

      await LogHelper.writeLog(
        "INFO: Loaded ${hiveData.length} logs from Hive (offline)",
        source: "log_controller.dart",
        level: 3,
      );

      // Sync dari Cloud (BACKGROUND - Non-blocking)
      if (ConnectivityService().hasConnection) {
        _syncFromCloud(teamId);
      } else {
        await LogHelper.writeLog(
          "INFO: Offline mode - Using Hive cache",
          source: "log_controller.dart",
          level: 2,
        );
      }
    } catch (e) {
      errorMessage.value = 'Error loading logs: $e';
      await LogHelper.writeLog(
        "ERROR: loadLogs failed - $e",
        source: "log_controller.dart",
        level: 1,
      );
    }
  }

  /// Sync data dari Cloud ke Hive (SMART MERGE - Jangan hapus data lokal)
  Future<void> _syncFromCloud(String teamId) async {
    try {
      if (_hiveBox == null) return;

      isLoading.value = true;

      final cloudData = await _mongoService.getLogsByTeam(teamId);

      // ========== SMART MERGE: Keep lokal data, update dengan cloud ==========
      // Build map lokal untuk quick lookup by ID + ALSO by author+title (untuk cegah duplikat)
      final localLogs = _hiveBox!.values.toList();
      final localMap = {for (var log in localLogs) log.id: log};

      // Build unique key map untuk deteksi duplikat walaupun id belum ter-set
      final localUniqueMap = {
        for (var log in localLogs) '${log.authorId}|${log.title}': log,
      };

      // Build cloud ID map untuk deteksi deletion
      final cloudIdSet = {for (var log in cloudData) log.id};

      // Merge: Add/update cloud logs ke Hive
      for (var cloudLog in cloudData) {
        if (cloudLog.id == null) continue;

        // Check 1: Apakah udah ada di Hive dengan id yang sama?
        if (localMap.containsKey(cloudLog.id)) {
          // Update existing log
          final index = localLogs.indexWhere((l) => l.id == cloudLog.id);
          if (index != -1) {
            await _hiveBox!.putAt(index, cloudLog);
          }
        }
        // Check 2: Apakah udah ada dengan author+title yang sama? (cegah duplikat dari race condition)
        else if (localUniqueMap.containsKey(
          '${cloudLog.authorId}|${cloudLog.title}',
        )) {
          // Sudah ada, update dengan cloud version (yang punya id)
          final existingLog =
              localUniqueMap['${cloudLog.authorId}|${cloudLog.title}']!;
          final index = localLogs.indexWhere(
            (l) =>
                l.title == existingLog.title &&
                l.authorId == existingLog.authorId,
          );
          if (index != -1) {
            await _hiveBox!.putAt(index, cloudLog);
          }
        } else {
          // Add new log dari cloud (belum ada di lokal sama sekali)
          await _hiveBox!.add(cloudLog);
        }
      }

      // ========== DELETION SYNC: Remove logs yang sudah dihapus di cloud ==========
      // Hanya delete logs yang punya ID (sudah ter-sync sebelumnya)
      final logsToDelete = <int>[];
      for (int i = 0; i < localLogs.length; i++) {
        final log = localLogs[i];
        // Jika log punya ID tapi tidak ada di cloud → sudah dihapus di cloud
        if (log.id != null && !cloudIdSet.contains(log.id)) {
          logsToDelete.add(i);
          await LogHelper.writeLog(
            "INFO: Detected deletion in cloud for '${log.title}' (ID: ${log.id}). Syncing deletion to local...",
            source: "log_controller.dart",
            level: 2,
          );
        }
      }

      // Delete dari Hive (delete dari index tertinggi dulu agar tidak corrupt index)
      for (int i = logsToDelete.length - 1; i >= 0; i--) {
        await _hiveBox!.deleteAt(logsToDelete[i]);
      }

      if (logsToDelete.isNotEmpty) {
        await LogHelper.writeLog(
          "SUCCESS: Synced ${logsToDelete.length} deletions from cloud",
          source: "log_controller.dart",
          level: 2,
        );
      }

      // Reload & display merged data
      final mergedData = _hiveBox!.values
          .where((log) => log.teamId == teamId)
          .toList();

      logsNotifier.value = mergedData;

      await LogHelper.writeLog(
        "SUCCESS: Smart merge completed - ${cloudData.length} cloud logs synced, ${logsToDelete.length} deletions synced",
        source: "log_controller.dart",
        level: 2,
      );
    } catch (e) {
      await LogHelper.writeLog(
        "WARNING: Cloud sync failed - using cache",
        source: "log_controller.dart",
        level: 2,
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// ========== 4.2: ADD DATA (Instant Local + Background Cloud) ==========
  Future<void> addLog(
    String title,
    String desc,
    String category, {
    bool isPublic = false,
  }) async {
    // CRITICAL: Await initialization before proceed
    try {
      await initializationFuture;
    } catch (initError) {
      await LogHelper.writeLog(
        "ERROR: Initialization failed during addLog - $initError",
        source: "log_controller.dart",
        level: 1,
      );
      throw Exception(
        "Aplikasi gagal menginisialisasi. Error: $initError\n\nMohon restart aplikasi dan coba lagi.",
      );
    }

    // Guard: Pastikan Hive initialized
    if (_hiveBox == null || !_isInitialized) {
      await LogHelper.writeLog(
        "ERROR: Hive not initialized in addLog (_hiveBox=$_hiveBox, _isInitialized=$_isInitialized)",
        source: "log_controller.dart",
        level: 1,
      );
      throw Exception("Database tidak siap. Mohon restart aplikasi.");
    }

    // Gatekeeper: Permission check
    final canCreate = AccessControlService.canPerform(
      currentUserRole,
      AccessControlService.actionCreate,
    );
    if (!canCreate) {
      throw Exception("Anda tidak memiliki izin untuk membuat catatan");
    }

    final newLog = LogModel(
      title: title,
      description: desc,
      date: DateTime.now().toString(),
      category: category,
      authorId: currentUserId,
      teamId: teamId,
      id: null,
      isPublic: isPublic, // Privacy setting
    );

    try {
      // ACTION 1: Simpan ke Hive (INSTAN)
      final hiveIndex = await _hiveBox!.add(newLog);
      logsNotifier.value = [...logsNotifier.value, newLog];

      await LogHelper.writeLog(
        "SUCCESS: Log '$title' saved locally to Hive (Public: $isPublic)",
        source: "log_controller.dart",
        level: 3,
      );

      // ACTION 2: Kirim ke MongoDB (BACKGROUND - Non-blocking)
      // Pass hiveIndex untuk update id setelah MongoDB sync berhasil
      _uploadToCloud(newLog, hiveIndex);
    } catch (e) {
      await LogHelper.writeLog(
        "ERROR: addLog failed - $e",
        source: "log_controller.dart",
        level: 1,
      );
      rethrow;
    }
  }

  /// Upload log ke MongoDB di background
  /// [hiveIndex] - Index di Hive untuk update id setelah MongoDB sync
  Future<void> _uploadToCloud(LogModel log, int hiveIndex) async {
    try {
      final hasConnection = ConnectivityService().hasConnection;

      await LogHelper.writeLog(
        "DEBUG: _uploadToCloud() started - title='${log.title}', hasConnection=$hasConnection",
        source: "log_controller.dart",
        level: 3,
      );

      if (!hasConnection) {
        await LogHelper.writeLog(
          "INFO: Offline - Log akan tersinkron saat online",
          source: "log_controller.dart",
          level: 3,
        );
        return;
      }

      // ========== UPSERT STRATEGY (Modul Praktikum Step 4) ==========
      // Menggunakan upsert untuk:
      // 1. Cegah duplikat secara otomatis (MongoDB-level)
      // 2. Insert jika belum ada, Update jika sudah ada
      // 3. Atomic operation = tidak ada race condition
      //
      // Filter: author + title + teamId (kombinasi yang harus unik)

      await LogHelper.writeLog(
        "DEBUG: Upserting log '${log.title}' to MongoDB (author: ${log.authorId})...",
        source: "log_controller.dart",
        level: 3,
      );

      final upsertResult = await _mongoService.upsertLogModel(log);

      if (upsertResult['success'] == true) {
        final matched = upsertResult['matched'] as int? ?? 0;
        final modified = upsertResult['modified'] as int? ?? 0;
        final upserted = upsertResult['upserted'] as int? ?? 0;

        // Log hasil upsert
        if (matched > 0) {
          await LogHelper.writeLog(
            "SUCCESS: Log '${log.title}' UPDATED in MongoDB (matched: $matched, modified: $modified)",
            source: "log_controller.dart",
            level: 2,
          );
        } else if (upserted > 0) {
          await LogHelper.writeLog(
            "SUCCESS: Log '${log.title}' INSERTED in MongoDB (upserted: $upserted)",
            source: "log_controller.dart",
            level: 2,
          );
        }

        // Update Hive dengan syncStatus = 'synced'
        final syncedLog = LogModel(
          id: log.id,
          title: log.title,
          description: log.description,
          date: log.date,
          category: log.category,
          authorId: log.authorId,
          teamId: log.teamId,
          isPublic: log.isPublic,
          cloudId: null,
          syncStatus: 'synced',
        );

        if (_hiveBox != null &&
            hiveIndex >= 0 &&
            hiveIndex < _hiveBox!.length) {
          await _hiveBox!.putAt(hiveIndex, syncedLog);

          await LogHelper.writeLog(
            "SUCCESS: Hive updated with syncStatus='synced'",
            source: "log_controller.dart",
            level: 2,
          );
        }
      } else {
        await LogHelper.writeLog(
          "ERROR: Upsert failed for '${log.title}' - ${upsertResult['error']}",
          source: "log_controller.dart",
          level: 1,
        );
      }
    } catch (e) {
      await LogHelper.writeLog(
        "ERROR: _uploadToCloud failed - $e",
        source: "log_controller.dart",
        level: 1,
      );
    }
  }

  /// ========== UPDATE LOG ==========
  Future<void> updateLog(
    int index,
    String newTitle,
    String newDesc,
    String newCategory, {
    bool isPublic = false,
  }) async {
    // Await initialization
    await initializationFuture;

    final currentLogs = List<LogModel>.from(logsNotifier.value);
    if (index >= currentLogs.length) throw Exception("Invalid index");

    final oldLog = currentLogs[index];

    final isOwner = oldLog.authorId == currentUserId;
    if (!isOwner) {
      throw Exception(
        "Anda tidak bisa mengedit catatan orang lain. Hanya pembuat catatan yang bisa mengedit.",
      );
    }

    final updatedLog = LogModel(
      title: newTitle,
      description: newDesc,
      date: DateTime.now().toString(),
      category: newCategory,
      authorId: oldLog.authorId,
      teamId: oldLog.teamId,
      id: oldLog.id,
      isPublic: isPublic, // Update privacy setting
      cloudId: oldLog.cloudId, // Preserve cloud ID
    );

    try {
      // Guard: Check Hive initialized
      if (_hiveBox == null) {
        throw Exception("Hive database belum siap");
      }

      // ACTION 1: Update Hive + UI
      await _hiveBox!.putAt(index, updatedLog);
      logsNotifier.value = [
        ...logsNotifier.value..setRange(index, index + 1, [updatedLog]),
      ];

      await LogHelper.writeLog(
        "SUCCESS: Log updated locally (Public: $isPublic)",
        source: "log_controller.dart",
        level: 3,
      );

      // ACTION 2: Update Cloud (background)
      if (oldLog.id != null) {
        _updateCloud(oldLog.id!, updatedLog);
      }
    } catch (e) {
      await LogHelper.writeLog(
        "ERROR: updateLog failed - $e",
        source: "log_controller.dart",
        level: 1,
      );
      rethrow;
    }
  }

  /// Update log di MongoDB
  Future<void> _updateCloud(String id, LogModel log) async {
    try {
      if (!ConnectivityService().hasConnection) return;

      final result = await _mongoService.updateLogModel(id, log);
      if (result) {
        await LogHelper.writeLog(
          "SUCCESS: Log updated in Cloud",
          source: "log_controller.dart",
          level: 2,
        );
      }
    } catch (e) {
      await LogHelper.writeLog(
        "WARNING: Cloud update failed",
        source: "log_controller.dart",
        level: 2,
      );
    }
  }

  /// ========== DELETE LOG ==========
  Future<void> removeLog(int index) async {
    // Await initialization
    await initializationFuture;

    final currentLogs = List<LogModel>.from(logsNotifier.value);
    if (index >= currentLogs.length) throw Exception("Invalid index");

    final targetLog = currentLogs[index];

    // Task 5: Ownership-based sovereignty check (not role-based)
    // Only the owner can delete their own logs
    final isOwner = targetLog.authorId == currentUserId;
    if (!isOwner) {
      throw Exception(
        "Anda tidak bisa menghapus catatan orang lain. Hanya pembuat catatan yang bisa menghapus.",
      );
    }

    try {
      // Guard: Check Hive initialized
      if (_hiveBox == null) {
        throw Exception("Hive database belum siap");
      }

      // ACTION 1: Remove dari Hive
      await _hiveBox!.deleteAt(index);
      final remaining = [...logsNotifier.value];
      remaining.removeAt(index);
      logsNotifier.value = remaining;

      // ACTION 2: Remove dari Cloud (background)
      if (targetLog.id != null) {
        _deleteFromCloud(targetLog.id!);
      }

      await LogHelper.writeLog(
        "SUCCESS: Log removed locally",
        source: "log_controller.dart",
        level: 3,
      );
    } catch (e) {
      await LogHelper.writeLog(
        "ERROR: removeLog failed - $e",
        source: "log_controller.dart",
        level: 1,
      );
      rethrow;
    }
  }

  /// Delete log dari MongoDB
  Future<void> _deleteFromCloud(String id) async {
    try {
      if (!ConnectivityService().hasConnection) return;

      final result = await _mongoService.deleteLogModel(id);
      if (result) {
        await LogHelper.writeLog(
          "SUCCESS: Log deleted from Cloud",
          source: "log_controller.dart",
          level: 2,
        );
      }
    } catch (e) {
      await LogHelper.writeLog(
        "WARNING: Cloud delete failed",
        source: "log_controller.dart",
        level: 2,
      );
    }
  }

  /// ========== 4.3: BACKGROUND SYNC LISTENER ==========
  void _setupBackgroundSync() {
    ConnectivityService().isConnected.addListener(() {
      if (ConnectivityService().hasConnection) {
        LogHelper.writeLog(
          "INFO: Internet back online - triggering sync",
          source: "log_controller.dart",
          level: 2,
        );
        // IMPORTANT: Push local changes FIRST before pulling cloud data
        _pushLocalChanges();
        Future.delayed(const Duration(milliseconds: 500), () {
          _syncFromCloud(teamId);
        });
      }
    });

    // Periodic sync setiap 5 menit jika online
    _syncTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      if (ConnectivityService().hasConnection) {
        _pushLocalChanges();
        Future.delayed(const Duration(milliseconds: 500), () {
          _syncFromCloud(teamId);
        });
      }
    });
  }

  /// Push all local changes to MongoDB before pulling cloud data
  /// Handles 2 scenarios:
  /// 1. id != null → Update existing log in MongoDB
  /// 2. id == null → Insert new log to MongoDB (offline-first scenario)
  Future<void> _pushLocalChanges() async {
    try {
      if (_hiveBox == null || !ConnectivityService().hasConnection) return;

      await LogHelper.writeLog(
        "INFO: _pushLocalChanges() started - syncing offline-created notes",
        source: "log_controller.dart",
        level: 3,
      );

      final localLogs = _hiveBox!.values.toList();

      for (int i = 0; i < localLogs.length; i++) {
        final log = localLogs[i];

        try {
          if (log.id != null) {
            // Case 1: Update existing log yang sudah punya ID
            final result = await _mongoService.updateLogModel(log.id!, log);
            if (result) {
              await LogHelper.writeLog(
                "SUCCESS: Pushed local changes for '${log.title}' to cloud",
                source: "log_controller.dart",
                level: 3,
              );
            }
          } else {
            // Case 2: Upsert log (insert jika baru, update jika sudah ada)
            // Menggunakan upsert untuk handle offline-created logs & cegah duplikat
            await LogHelper.writeLog(
              "DEBUG: Upserting offline-created log '${log.title}' to MongoDB",
              source: "log_controller.dart",
              level: 3,
            );

            final upsertResult = await _mongoService.upsertLogModel(log);
            if (upsertResult['success'] == true) {
              // ========== SUCCESS: Mark log as synced ==========
              final syncedLog = LogModel(
                title: log.title,
                description: log.description,
                date: log.date,
                category: log.category,
                authorId: log.authorId,
                teamId: log.teamId,
                isPublic: log.isPublic,
                id: log.id, // Keep existing ID
                cloudId: null,
                syncStatus: 'synced',
              );

              // Update Hive record
              if (i < _hiveBox!.length) {
                await _hiveBox!.putAt(i, syncedLog);
              }

              await LogHelper.writeLog(
                "SUCCESS: Offline log '${log.title}' synced to Cloud (matched: ${upsertResult['matched']}, upserted: ${upsertResult['upserted']})",
                source: "log_controller.dart",
                level: 2,
              );
            } else {
              await LogHelper.writeLog(
                "WARNING: Failed to upsert offline log '${log.title}' - ${upsertResult['error']}",
                source: "log_controller.dart",
                level: 2,
              );
            }
          }
        } catch (e) {
          await LogHelper.writeLog(
            "WARNING: Failed to sync '${log.title}' - $e",
            source: "log_controller.dart",
            level: 2,
          );
        }
      }

      await LogHelper.writeLog(
        "INFO: _pushLocalChanges() completed",
        source: "log_controller.dart",
        level: 3,
      );
    } catch (e) {
      await LogHelper.writeLog(
        "ERROR: _pushLocalChanges failed - $e",
        source: "log_controller.dart",
        level: 1,
      );
    }
  }

  /// ========== CLEANUP DUPLICATES IN CLOUD ==========
  /// Detect & remove duplicate logs yang memiliki author+title sama
  /// Keep yang paling baru, delete yang lama
  Future<void> cleanupDuplicatesInCloud() async {
    try {
      isLoading.value = true;

      await LogHelper.writeLog(
        "INFO: cleanupDuplicatesInCloud() started...",
        source: "log_controller.dart",
        level: 2,
      );

      // Get all logs dari cloud
      final allLogs = await _mongoService.getLogsByTeam(teamId);

      // Group by author+title untuk deteksi duplikat
      final grouped = <String, List<LogModel>>{};
      for (var log in allLogs) {
        final key = '${log.authorId}|${log.title}';
        grouped[key] ??= [];
        grouped[key]!.add(log);
      }

      // Find duplicates & prepare for deletion
      int duplicateCount = 0;
      int deletedCount = 0;
      final duplicateGroups = <String, List<LogModel>>{};

      for (var entry in grouped.entries) {
        if (entry.value.length > 1) {
          // Duplikat ditemukan!
          duplicateCount += entry.value.length - 1; // Total duplikat yg ada
          duplicateGroups[entry.key] = entry.value;

          // Sort by date (newest first)
          entry.value.sort(
            (a, b) => DateTime.parse(b.date).compareTo(DateTime.parse(a.date)),
          );

          await LogHelper.writeLog(
            "WARNING: Found ${entry.value.length} copies of '${entry.key}'. Keeping newest, deleting ${entry.value.length - 1} old copies...",
            source: "log_controller.dart",
            level: 2,
          );

          // Delete old copies (index 1 onwards, keep index 0 yang paling baru)
          for (int i = 1; i < entry.value.length; i++) {
            final logToDelete = entry.value[i];

            try {
              final deleteSuccess = await _mongoService.deleteLogModel(
                logToDelete.id!,
              );

              if (deleteSuccess) {
                deletedCount++;
                await LogHelper.writeLog(
                  "SUCCESS: Deleted duplicate '${logToDelete.title}' (ID: ${logToDelete.id}, date: ${logToDelete.date})",
                  source: "log_controller.dart",
                  level: 2,
                );
              } else {
                await LogHelper.writeLog(
                  "WARNING: Failed to delete duplicate '${logToDelete.title}' (ID: ${logToDelete.id})",
                  source: "log_controller.dart",
                  level: 2,
                );
              }
            } catch (deleteError) {
              await LogHelper.writeLog(
                "ERROR: Failed to delete duplicate - $deleteError",
                source: "log_controller.dart",
                level: 1,
              );
            }
          }
        }
      }

      // Sync data after cleanup
      if (deletedCount > 0) {
        await LogHelper.writeLog(
          "INFO: Successfully cleaned up $deletedCount duplicates (${duplicateGroups.length} groups). Reloading data...",
          source: "log_controller.dart",
          level: 2,
        );

        // Reload data dari cloud
        await loadLogs(teamId);
      } else {
        await LogHelper.writeLog(
          "INFO: No duplicates found. All data is clean!",
          source: "log_controller.dart",
          level: 2,
        );
      }

      isLoading.value = false;

      await LogHelper.writeLog(
        "SUCCESS: Cleanup completed - Found $duplicateCount potential duplicates, deleted $deletedCount",
        source: "log_controller.dart",
        level: 2,
      );
    } catch (e) {
      isLoading.value = false;

      await LogHelper.writeLog(
        "ERROR: cleanupDuplicatesInCloud failed - $e",
        source: "log_controller.dart",
        level: 1,
      );

      rethrow;
    }
  }

  /// Cleanup resources
  Future<void> dispose() async {
    _syncTimer?.cancel();
    searchQueryNotifier.dispose();
    filteredLogsNotifier.dispose();
    logsNotifier.dispose();
    isLoading.dispose();
    errorMessage.dispose();
    await LogHelper.writeLog(
      "INFO: LogController disposed",
      source: "log_controller.dart",
      level: 3,
    );
  }
}
