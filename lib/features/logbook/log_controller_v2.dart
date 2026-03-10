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

  late Box<LogModel> _hiveBox;
  final MongoService _mongoService = MongoService();
  Timer? _syncTimer;

  LogController({
    required this.currentUsername,
    required this.currentUserId,
    this.currentUserRole = 'Anggota',
    this.teamId = 'default_team',
  }) {
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      _hiveBox = Hive.box<LogModel>('offline_logs');
      await LogHelper.writeLog(
        "INFO: Hive box 'offline_logs' siap",
        source: "log_controller.dart",
        level: 3,
      );

      _setupBackgroundSync();

      await loadLogs(teamId);
    } catch (e) {
      await LogHelper.writeLog(
        "ERROR: Initialization failed - $e",
        source: "log_controller.dart",
        level: 1,
      );
    }
  }

  Future<void> loadLogs(String teamId) async {
    try {
      final hiveData = _hiveBox.values
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
      isLoading.value = true;

      final cloudData = await _mongoService.getLogsByTeam(teamId);

      await _hiveBox.clear();
      for (var log in cloudData) {
        await _hiveBox.add(log);
      }

      logsNotifier.value = cloudData;

      await LogHelper.writeLog(
        "SUCCESS: Cloud sync completed - ${cloudData.length} logs synced",
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

  Future<void> addLog(String title, String desc, String category) async {
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
    );

    try {
      await _hiveBox.add(newLog);
      logsNotifier.value = [...logsNotifier.value, newLog];

      await LogHelper.writeLog(
        "SUCCESS: Log '$title' saved locally to Hive",
        source: "log_controller.dart",
        level: 3,
      );

      _uploadToCloud(newLog);
    } catch (e) {
      await LogHelper.writeLog(
        "ERROR: addLog failed - $e",
        source: "log_controller.dart",
        level: 1,
      );
      rethrow;
    }
  }

  Future<void> _uploadToCloud(LogModel log) async {
    try {
      if (!ConnectivityService().hasConnection) {
        await LogHelper.writeLog(
          "INFO: Offline - Log akan tersinkron saat online",
          source: "log_controller.dart",
          level: 3,
        );
        return;
      }

      final result = await _mongoService.insertLogModel(log);
      if (result != null) {
        await LogHelper.writeLog(
          "SUCCESS: Log synced to Cloud with ID ${result.oid}",
          source: "log_controller.dart",
          level: 2,
        );
      }
    } catch (e) {
      await LogHelper.writeLog(
        "WARNING: Background upload failed - ${log.title}",
        source: "log_controller.dart",
        level: 2,
      );
    }
  }

  Future<void> updateLog(
    int index,
    String newTitle,
    String newDesc,
    String newCategory,
  ) async {
    final currentLogs = List<LogModel>.from(logsNotifier.value);
    if (index >= currentLogs.length) throw Exception("Invalid index");

    final oldLog = currentLogs[index];

    final isOwner = oldLog.authorId == currentUserId;
    final canUpdate = AccessControlService.canPerform(
      currentUserRole,
      AccessControlService.actionUpdate,
      isOwner: isOwner,
    );
    if (!canUpdate) {
      throw Exception("Anda tidak memiliki izin untuk mengubah catatan ini");
    }

    final updatedLog = LogModel(
      title: newTitle,
      description: newDesc,
      date: DateTime.now().toString(),
      category: newCategory,
      authorId: oldLog.authorId,
      teamId: oldLog.teamId,
      id: oldLog.id,
    );

    try {
      currentLogs[index] = updatedLog;
      logsNotifier.value = currentLogs;

      await LogHelper.writeLog(
        "SUCCESS: Log updated locally",
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
    final currentLogs = List<LogModel>.from(logsNotifier.value);
    if (index >= currentLogs.length) throw Exception("Invalid index");

    final targetLog = currentLogs[index];

    final isOwner = targetLog.authorId == currentUserId;
    final canDelete = AccessControlService.canPerform(
      currentUserRole,
      AccessControlService.actionDelete,
      isOwner: isOwner,
    );
    if (!canDelete) {
      throw Exception("Anda tidak memiliki izin untuk menghapus catatan ini");
    }

    try {
      currentLogs.removeAt(index);
      logsNotifier.value = currentLogs;

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
    ConnectivityService().isConnected.addListener(() {
      if (ConnectivityService().hasConnection) {
        LogHelper.writeLog(
          "INFO: Internet back online - triggering sync",
          source: "log_controller.dart",
          level: 2,
        );
        _syncFromCloud(teamId);
      }
    });

    _syncTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      if (ConnectivityService().hasConnection) {
        _syncFromCloud(teamId);
      }
    });
  }

  Future<void> dispose() async {
    _syncTimer?.cancel();
    await LogHelper.writeLog(
      "INFO: LogController disposed",
      source: "log_controller.dart",
      level: 3,
    );
  }
}
