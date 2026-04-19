import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:logbook_app/features/logbook/log_controller.dart';
import 'package:logbook_app/features/logbook/models/log_model.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() {
  late LogController controller;

  setUpAll(() async {
    await dotenv.load(fileName: ".env");

    final dir = Directory.systemTemp.createTempSync();
    Hive.init(dir.path);

    Hive.registerAdapter(LogModelAdapter());
    await Hive.openBox<LogModel>('offline_logs');
  });

  setUp(() async {
    controller = LogController(
      currentUsername: "uci",
      currentUserId: "1",
      currentUserRole: "Ketua",
      teamId: "MEKTRA_KLP_01",
    );

    await controller.initializationFuture;
  });

  tearDown(() async {
    await Hive.box<LogModel>('offline_logs').clear();
  });

  tearDownAll(() async {
    await Hive.close();
  });

  group('Modul 3 - Disk Storage (Hive)', () {
    test('TC01 - addLog berhasil menambah data', () async {
      int before = controller.logsNotifier.value.length;

      await controller.addLog("Test", "Coba", "Mechanical");

      int after = controller.logsNotifier.value.length;
      expect(after, before + 1);
    });

    test('TC02 - addLog gagal tanpa izin', () async {
      final controllerNoAccess = LogController(
        currentUsername: "uci",
        currentUserId: "1",
        currentUserRole: "Guest",
        teamId: "MEKTRA_KLP_01",
      );

      await controllerNoAccess.initializationFuture;

      expect(
        () async =>
            await controllerNoAccess.addLog("Test", "Coba", "Mechanical"),
        throwsException,
      );
    });

    test('TC03 - addLog gagal jika data kosong', () async {
      expect(() async => await controller.addLog("", "", ""), throwsException);
    });
  });
}
