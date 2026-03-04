import 'dart:developer' as dev;
import 'dart:io';
import 'package:intl/intl.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:path_provider/path_provider.dart';

class LogHelper {
  static Directory? _logsDirectory;

  static Future<void> initialize() async {
    try {
      await _getLogsDirectory();
    } catch (e) {
      dev.log("Failed to initialize logs directory: $e", name: "LogHelper");
    }
  }

  static Future<Directory> _getLogsDirectory() async {
    if (_logsDirectory != null && await _logsDirectory!.exists()) {
      return _logsDirectory!;
    }

    try {
      final projectLogsDir = Directory('logs');
      try {
        if (!await projectLogsDir.exists()) {
          await projectLogsDir.create(recursive: true);
        }
        _logsDirectory = projectLogsDir;
        dev.log(
          "✅ Logs directory created at: ${projectLogsDir.path}",
          name: "LogHelper",
          level: 800,
        );
        return projectLogsDir;
      } catch (e) {
        throw Exception("Relative path failed: $e");
      }
    } catch (e) {
      try {
        final appDocDir = await getApplicationDocumentsDirectory();
        final appLogsDir = Directory('${appDocDir.path}/logs');

        if (!await appLogsDir.exists()) {
          await appLogsDir.create(recursive: true);
        }

        _logsDirectory = appLogsDir;
        dev.log(
          "✅ Logs directory created at: ${appLogsDir.path}",
          name: "LogHelper",
          level: 800,
        );
        return appLogsDir;
      } catch (e) {
        dev.log(
          "⚠️ Failed to get logs directory: $e, using temp",
          name: "LogHelper",
          level: 900,
        );
        final tempDir = Directory.systemTemp;
        final tempLogsDir = Directory('${tempDir.path}/logbook_logs');
        if (!await tempLogsDir.exists()) {
          await tempLogsDir.create(recursive: true);
        }
        _logsDirectory = tempLogsDir;
        return tempLogsDir;
      }
    }
  }

  static String _getLogFileName() {
    final now = DateTime.now();
    return '${DateFormat('dd-MM-yyyy').format(now)}.log';
  }

  static Future<void> writeLog(
    String message, {
    String source = "Unknown",
    int level = 2,
  }) async {
    final int configLevel = int.tryParse(dotenv.env['LOG_LEVEL'] ?? '2') ?? 2;
    final String muteList = dotenv.env['LOG_MUTE'] ?? '';

    if (level > configLevel) return;
    if (muteList.split(',').map((s) => s.trim()).contains(source)) return;

    try {
      String timestamp = DateFormat('HH:mm:ss').format(DateTime.now());
      String fullTimestamp = DateFormat(
        'dd-MM-yyyy HH:mm:ss',
      ).format(DateTime.now());
      String label = _getLabel(level);
      String color = _getColor(level);
      String logLine = '[$fullTimestamp] [$label] [$source] -> $message';
      dev.log(message, name: source, time: DateTime.now(), level: level * 100);
      // ignore: avoid_print
      print('$color[$timestamp][$label][$source] -> $message\x1B[0m');
      await _writeToFile(logLine);
    } catch (e) {
      dev.log("Logging failed: $e", name: "SYSTEM", level: 1000);
    }
  }

  static Future<void> _writeToFile(String logLine) async {
    try {
      final logsDir = await _getLogsDirectory();
      final fileName = _getLogFileName();
      final logFile = File('${logsDir.path}/$fileName');
      await logFile.writeAsString(
        '$logLine\n',
        mode: FileMode.append,
        flush: true,
      );
    } catch (e) {
      dev.log(
        "Failed to write to log file: $e",
        name: "LogHelper",
        level: 1000,
      );
    }
  }

  static Future<String> getLogsFromFile() async {
    try {
      final logsDir = await _getLogsDirectory();
      final fileName = _getLogFileName();
      final logFile = File('${logsDir.path}/$fileName');

      if (await logFile.exists()) {
        return await logFile.readAsString();
      }
      return "No logs for today";
    } catch (e) {
      return "Error reading logs: $e";
    }
  }

  static Future<void> clearTodaysLogs() async {
    try {
      final logsDir = await _getLogsDirectory();
      final fileName = _getLogFileName();
      final logFile = File('${logsDir.path}/$fileName');

      if (await logFile.exists()) {
        await logFile.delete();
      }
    } catch (e) {
      dev.log("Error clearing logs: $e", name: "SYSTEM", level: 1000);
    }
  }

  static String _getLabel(int level) {
    switch (level) {
      case 1:
        return "ERROR";
      case 2:
        return "INFO";
      case 3:
        return "VERBOSE";
      default:
        return "LOG";
    }
  }

  static String _getColor(int level) {
    switch (level) {
      case 1:
        return '\x1B[31m'; // Merah
      case 2:
        return '\x1B[32m'; // Hijau
      case 3:
        return '\x1B[34m'; // Biru
      default:
        return '\x1B[0m';
    }
  }
}
