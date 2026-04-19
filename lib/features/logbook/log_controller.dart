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

    updateFilteredLogs();
  }

  void updateSearchQuery(String query) {
    searchQueryNotifier.value = query;
  }

  Future<void> _initialize() async {
    try {
      final startTime = DateTime.now();

      await LogHelper.writeLog(
        "INFO: LogController._initialize() starting...",
        source: "log_controller.dart",
        level: 3,
      );

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

      _setupBackgroundSync();

      await loadLogs(teamId);

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
      rethrow;
    }
  }

  Future<void> loadLogs(String teamId) async {
    try {
      // Ensure initialization is complete
      if (!_isInitialized) {
        await initializationFuture;
      }

      if (_hiveBox == null) {
        await LogHelper.writeLog(
          "WARNING: Hive box not yet initialized, deferring load",
          source: "log_controller.dart",
          level: 2,
        );
        await Future.delayed(const Duration(milliseconds: 500));
        return;
      }

      final hiveData = _hiveBox!.values
          .where((log) => log.teamId == teamId)
          .toList();

      logsNotifier.value = hiveData;

      await LogHelper.writeLog(
        "INFO: Loaded ${hiveData.length} logs from Hive (offline)",
        source: "log_controller.dart",
        level: 3,
      );

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

  Future<void> _syncFromCloud(String teamId) async {
    try {
      if (_hiveBox == null) return;

      isLoading.value = true;

      final cloudData = await _mongoService.getLogsByTeam(teamId);
      final localLogs = _hiveBox!.values.toList();

      final localIndexMap = <String, int>{};
      for (int i = 0; i < localLogs.length; i++) {
        final log = localLogs[i];
        if (log.id != null) {
          localIndexMap[log.id!] = i;
        }
        localIndexMap['${log.authorId}|${log.title}'] = i;
      }

      final cloudIdSet = <String?>{for (var log in cloudData) log.id};
      int syncCount = 0;

      for (var cloudLog in cloudData) {
        if (cloudLog.id == null) continue;

        if (localIndexMap.containsKey(cloudLog.id)) {
          final index = localIndexMap[cloudLog.id]!;
          await _hiveBox!.putAt(index, cloudLog);
          syncCount++;
        } else if (localIndexMap.containsKey(
          '${cloudLog.authorId}|${cloudLog.title}',
        )) {
          final index =
              localIndexMap['${cloudLog.authorId}|${cloudLog.title}']!;
          await _hiveBox!.putAt(index, cloudLog);
          syncCount++;
        } else {
          await _hiveBox!.add(cloudLog);
          syncCount++;
        }
      }

      final logsToDelete = <int>[];
      for (int i = 0; i < localLogs.length; i++) {
        final log = localLogs[i];
        if (log.id != null && !cloudIdSet.contains(log.id)) {
          logsToDelete.add(i);
        }
      }

      for (int i = logsToDelete.length - 1; i >= 0; i--) {
        await _hiveBox!.deleteAt(logsToDelete[i]);
      }

      final mergedData = _hiveBox!.values
          .where((log) => log.teamId == teamId)
          .toList();

      logsNotifier.value = mergedData;

      await LogHelper.writeLog(
        "SUCCESS: Smart merge - ${cloudData.length} cloud logs synced, ${logsToDelete.length} deletions, total updated: $syncCount",
        source: "log_controller.dart",
        level: 2,
      );
    } catch (e) {
      await LogHelper.writeLog(
        "WARNING: Cloud sync failed - $e",
        source: "log_controller.dart",
        level: 2,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> addLog(
    String title,
    String desc,
    String category, {
    bool isPublic = false,
  }) async {
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

    if (_hiveBox == null || !_isInitialized) {
      await LogHelper.writeLog(
        "ERROR: Hive not initialized in addLog (_hiveBox=$_hiveBox, _isInitialized=$_isInitialized)",
        source: "log_controller.dart",
        level: 1,
      );
      throw Exception("Database tidak siap. Mohon restart aplikasi.");
    }

    final canCreate = AccessControlService.canPerform(
      currentUserRole,
      AccessControlService.actionCreate,
    );
    if (!canCreate) {
      throw Exception("Anda tidak memiliki izin untuk membuat catatan");
    }

    if (title.isEmpty || desc.isEmpty || category.isEmpty) {
      throw Exception("Data tidak boleh kosong");
    }

    final newLog = LogModel(
      title: title,
      description: desc,
      date: DateTime.now().toString(),
      category: category,
      authorId: currentUserId,
      teamId: teamId,
      id: null,
      isPublic: isPublic,
    );

    try {
      final hiveIndex = await _hiveBox!.add(newLog);
      logsNotifier.value = [...logsNotifier.value, newLog];

      await LogHelper.writeLog(
        "SUCCESS: Log '$title' saved locally to Hive (Public: $isPublic)",
        source: "log_controller.dart",
        level: 3,
      );

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

  Future<void> updateLog(
    int index,
    String newTitle,
    String newDesc,
    String newCategory, {
    bool isPublic = false,
  }) async {
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
      if (_hiveBox == null) {
        throw Exception("Hive database belum siap");
      }

      await _hiveBox!.putAt(index, updatedLog);
      logsNotifier.value = [
        ...logsNotifier.value..setRange(index, index + 1, [updatedLog]),
      ];

      await LogHelper.writeLog(
        "SUCCESS: Log updated locally (Public: $isPublic)",
        source: "log_controller.dart",
        level: 3,
      );

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

  Future<void> removeLog(int index) async {
    await initializationFuture;

    final currentLogs = List<LogModel>.from(logsNotifier.value);
    if (index >= currentLogs.length) throw Exception("Invalid index");

    final targetLog = currentLogs[index];

    final isOwner = targetLog.authorId == currentUserId;
    if (!isOwner) {
      throw Exception(
        "Anda tidak bisa menghapus catatan orang lain. Hanya pembuat catatan yang bisa menghapus.",
      );
    }

    try {
      if (_hiveBox == null) {
        throw Exception("Hive database belum siap");
      }

      await _hiveBox!.deleteAt(index);
      final remaining = [...logsNotifier.value];
      remaining.removeAt(index);
      logsNotifier.value = remaining;

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

  void _setupBackgroundSync() {
    ConnectivityService().isConnected.addListener(_onConnectivityChanged);

    _syncTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      _performSync();
    });
  }

  void _onConnectivityChanged() {
    if (ConnectivityService().hasConnection) {
      LogHelper.writeLog(
        "INFO: Internet back online - triggering sync",
        source: "log_controller.dart",
        level: 2,
      );
      _performSync();
    }
  }

  Future<void> _performSync() async {
    try {
      isLoading.value = true;

      await LogHelper.writeLog(
        "INFO: Starting auto-sync cycle...",
        source: "log_controller.dart",
        level: 3,
      );

      await _pushLocalChanges();
      await _syncFromCloud(teamId);

      await LogHelper.writeLog(
        "SUCCESS: Auto-sync cycle completed",
        source: "log_controller.dart",
        level: 2,
      );
    } catch (e) {
      await LogHelper.writeLog(
        "ERROR: Auto-sync failed - $e",
        source: "log_controller.dart",
        level: 1,
      );
    } finally {
      isLoading.value = false;
    }
  }

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
            final result = await _mongoService.updateLogModel(log.id!, log);
            if (result) {
              await LogHelper.writeLog(
                "SUCCESS: Pushed local changes for '${log.title}' to cloud",
                source: "log_controller.dart",
                level: 3,
              );
            }
          } else {
            await LogHelper.writeLog(
              "DEBUG: Upserting offline-created log '${log.title}' to MongoDB",
              source: "log_controller.dart",
              level: 3,
            );

            final upsertResult = await _mongoService.upsertLogModel(log);
            if (upsertResult['success'] == true) {
              final syncedLog = LogModel(
                title: log.title,
                description: log.description,
                date: log.date,
                category: log.category,
                authorId: log.authorId,
                teamId: log.teamId,
                isPublic: log.isPublic,
                id: log.id,
                cloudId: null,
                syncStatus: 'synced',
              );

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

  Future<void> cleanupDuplicatesInCloud() async {
    try {
      isLoading.value = true;

      await LogHelper.writeLog(
        "INFO: cleanupDuplicatesInCloud() started...",
        source: "log_controller.dart",
        level: 2,
      );

      final allLogs = await _mongoService.getLogsByTeam(teamId);

      final grouped = <String, List<LogModel>>{};
      for (var log in allLogs) {
        final key = '${log.authorId}|${log.title}';
        grouped[key] ??= [];
        grouped[key]!.add(log);
      }

      int duplicateCount = 0;
      int deletedCount = 0;
      final duplicateGroups = <String, List<LogModel>>{};

      for (var entry in grouped.entries) {
        if (entry.value.length > 1) {
          duplicateCount += entry.value.length - 1;
          duplicateGroups[entry.key] = entry.value;

          entry.value.sort(
            (a, b) => DateTime.parse(b.date).compareTo(DateTime.parse(a.date)),
          );

          await LogHelper.writeLog(
            "WARNING: Found ${entry.value.length} copies of '${entry.key}'. Keeping newest, deleting ${entry.value.length - 1} old copies...",
            source: "log_controller.dart",
            level: 2,
          );

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

      if (deletedCount > 0) {
        await LogHelper.writeLog(
          "INFO: Successfully cleaned up $deletedCount duplicates (${duplicateGroups.length} groups). Reloading data...",
          source: "log_controller.dart",
          level: 2,
        );

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
