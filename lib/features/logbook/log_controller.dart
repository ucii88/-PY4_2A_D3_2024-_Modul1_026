import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:logbook_app/services/mongo_service.dart';
import 'package:logbook_app/models/logbook_model.dart';
import 'package:logbook_app/helpers/log_helper.dart';
import 'models/log_model.dart';

class LogController {
  final String currentUsername;
  final ValueNotifier<List<LogModel>> logsNotifier = ValueNotifier([]);
  final ValueNotifier<List<LogModel>> filteredLogs = ValueNotifier([]);
  final ValueNotifier<bool> isLoading = ValueNotifier(false);
  final ValueNotifier<String?> errorMessage = ValueNotifier(null);

  String get _storageKey => 'user_logs_$currentUsername';

  final MongoService _mongoService = MongoService();

  LogController({required this.currentUsername}) {
    loadFromDisk();
  }

  Future<List<LogModel>> getLogsFromCloud() async {
    try {
      final cloudData = await _mongoService.getLogs(currentUsername);

      await Future.delayed(const Duration(seconds: 1));

      final convertedLogs = cloudData
          .map(
            (logbook) => LogModel(
              title: logbook.title,
              description: logbook.description,
              date: logbook.date,
              category: logbook.category,
              cloudId: logbook.id,
            ),
          )
          .toList();

      logsNotifier.value = convertedLogs;
      filteredLogs.value = convertedLogs;
      await saveToDisk();

      await LogHelper.writeLog(
        "SUCCESS: Cloud sync berhasil, ${convertedLogs.length} logs loaded",
        source: "log_controller.dart",
        level: 2,
      );

      return convertedLogs;
    } catch (e) {
      errorMessage.value = 'Gagal sinkronisasi cloud: $e';

      await LogHelper.writeLog(
        "ERROR: Cloud sync gagal - $e",
        source: "log_controller.dart",
        level: 1,
      );
      rethrow;
    }
  }

  Future<void> loadFromCloud() async {
    try {
      isLoading.value = true;
      errorMessage.value = null;

      final cloudData = await _mongoService.getLogs(currentUsername);
      await Future.delayed(const Duration(seconds: 1));

      final convertedLogs = cloudData
          .map(
            (logbook) => LogModel(
              title: logbook.title,
              description: logbook.description,
              date: logbook.date,
              category: logbook.category,
              cloudId: logbook.id,
            ),
          )
          .toList();

      logsNotifier.value = convertedLogs;
      filteredLogs.value = convertedLogs;

      await saveToDisk();

      await LogHelper.writeLog(
        "SUCCESS: Cloud sync berhasil, ${convertedLogs.length} logs loaded",
        source: "log_controller.dart",
        level: 2,
      );
    } catch (e) {
      errorMessage.value = 'Gagal sinkronisasi cloud: $e';

      await LogHelper.writeLog(
        "ERROR: Cloud sync gagal - $e",
        source: "log_controller.dart",
        level: 1,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> addLog(String title, String desc, String category) async {
    final newLog = LogModel(
      title: title,
      description: desc,
      date: DateTime.now().toString(),
      category: category,

      cloudId: null,
    );

    try {
      final cloudLogbook = Logbook.fromLogModel(
        id: null,
        title: newLog.title,
        description: newLog.description,
        date: newLog.date,
        category: newLog.category,
        username: currentUsername,
      );
      final insertedId = await _mongoService.insertLog(cloudLogbook);

      final logWithCloudId = LogModel(
        title: newLog.title,
        description: newLog.description,
        date: newLog.date,
        category: newLog.category,
        cloudId: insertedId,
      );

      final currentLogs = List<LogModel>.from(logsNotifier.value);
      currentLogs.add(logWithCloudId);
      logsNotifier.value = currentLogs;
      filteredLogs.value = logsNotifier.value;

      await saveToDisk();

      await LogHelper.writeLog(
        "SUCCESS: Log baru '$title' ditambahkan ke Cloud dengan ID ${insertedId.toHexString()}",
        source: "log_controller.dart",
        level: 2,
      );
    } catch (e) {
      await LogHelper.writeLog(
        "ERROR: Gagal tambah log ke cloud - $e",
        source: "log_controller.dart",
        level: 1,
      );
      errorMessage.value = 'Gagal tambah log: $e';
      rethrow;
    }
  }

  Future<void> updateLog(
    int index,
    String newTitle,
    String newDesc,
    String newCategory,
  ) async {
    final currentLogs = List<LogModel>.from(logsNotifier.value);
    final oldLog = currentLogs[index];

    if (oldLog.cloudId == null) {
      throw Exception(
        'Log belum tersimpan di cloud, tidak bisa update. Coba add ulang.',
      );
    }

    final updatedLog = LogModel(
      title: newTitle,
      description: newDesc,
      date: DateTime.now().toString(),
      category: newCategory,
      cloudId: oldLog.cloudId,
    );

    try {
      final cloudLogbook = Logbook.fromLogModel(
        id: oldLog.cloudId,
        title: updatedLog.title,
        description: updatedLog.description,
        date: updatedLog.date,
        category: updatedLog.category,
        username: currentUsername,
      );

      await _mongoService.updateLog(oldLog.cloudId!, cloudLogbook);

      currentLogs[index] = updatedLog;
      logsNotifier.value = currentLogs;
      filteredLogs.value = currentLogs;

      await saveToDisk();

      await LogHelper.writeLog(
        "SUCCESS: Log '${oldLog.title}' diupdate di Cloud",
        source: "log_controller.dart",
        level: 2,
      );
    } catch (e) {
      await LogHelper.writeLog(
        "ERROR: Gagal update log - $e",
        source: "log_controller.dart",
        level: 1,
      );
      errorMessage.value = 'Gagal update log: $e';
      rethrow;
    }
  }

  Future<void> removeLog(int index) async {
    final currentLogs = List<LogModel>.from(logsNotifier.value);
    final targetLog = currentLogs[index];

    if (targetLog.cloudId == null) {
      throw Exception(
        'Log belum tersimpan di cloud, tidak bisa hapus. Coba ulang.',
      );
    }

    try {
      await _mongoService.deleteLog(targetLog.cloudId!);

      currentLogs.removeAt(index);
      logsNotifier.value = currentLogs;
      filteredLogs.value = currentLogs;

      await saveToDisk();

      await LogHelper.writeLog(
        "SUCCESS: Log '${targetLog.title}' dihapus dari Cloud",
        source: "log_controller.dart",
        level: 2,
      );
    } catch (e) {
      await LogHelper.writeLog(
        "ERROR: Gagal hapus log - $e",
        source: "log_controller.dart",
        level: 1,
      );
      errorMessage.value = 'Gagal hapus log: $e';
      rethrow;
    }
  }

  void searchLog(String query) {
    if (query.isEmpty) {
      filteredLogs.value = logsNotifier.value;
    } else {
      filteredLogs.value = logsNotifier.value
          .where((log) => log.title.toLowerCase().contains(query.toLowerCase()))
          .toList();
    }
  }

  List<LogModel> get logs => logsNotifier.value;

  Future<void> saveToDisk() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final String encodedData = jsonEncode(
        logsNotifier.value.map((log) => log.toMap()).toList(),
      );

      await prefs.setString(_storageKey, encodedData);

      await LogHelper.writeLog(
        "SUCCESS: ${logsNotifier.value.length} logs disimpan ke lokal",
        source: "log_controller.dart",
        level: 3,
      );
    } catch (e) {
      await LogHelper.writeLog(
        "ERROR: Gagal simpan ke disk - $e",
        source: "log_controller.dart",
        level: 1,
      );
    }
  }

  Future<void> loadFromDisk() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? data = prefs.getString(_storageKey);

      if (data != null) {
        final List decoded = jsonDecode(data);
        final loadedLogs = decoded.map((e) => LogModel.fromMap(e)).toList();

        logsNotifier.value = loadedLogs;
        filteredLogs.value = loadedLogs;

        await LogHelper.writeLog(
          "SUCCESS: ${loadedLogs.length} logs dimuat dari cache lokal",
          source: "log_controller.dart",
          level: 3,
        );
      } else {
        await LogHelper.writeLog(
          "INFO: Tidak ada data lokal, mulai dengan list kosong",
          source: "log_controller.dart",
          level: 3,
        );
      }
    } catch (e) {
      await LogHelper.writeLog(
        "ERROR: Gagal load dari disk - $e",
        source: "log_controller.dart",
        level: 1,
      );
    }
  }
}
