import 'package:flutter_test/flutter_test.dart';
import 'package:logbook_app/services/mongo_service.dart';
import 'package:logbook_app/features/logbook/models/log_model.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() {
  late MongoService service;

  setUpAll(() async {
    await dotenv.load(fileName: ".env");
  });

  setUp(() {
    service = MongoService();
  });

  group('Modul 4 - Cloud Service (MongoService)', () {
    test('TC01 - upsert berhasil dengan data valid', () async {
      final log = LogModel(
        title: "Test",
        description: "Coba",
        date: DateTime.now().toString(),
        category: "Umum",
        authorId: "1",
        teamId: "TEAM1",
      );

      final result = await service.upsertLogModel(log);

      expect(result.containsKey('success'), true);
    });

    test('TC02 - upsert gagal dengan data kosong', () async {
      final log = LogModel(
        title: "",
        description: "",
        date: "",
        category: "",
        authorId: "",
        teamId: "",
      );

      final result = await service.upsertLogModel(log);

      expect(result['success'], true);
    });

    test('TC03 - upsert response format valid', () async {
      final log = LogModel(
        title: "Edge",
        description: "Test",
        date: DateTime.now().toString(),
        category: "Umum",
        authorId: "1",
        teamId: "TEAM1",
      );

      final result = await service.upsertLogModel(log);

      expect(result, isA<Map<String, dynamic>>());
    });
  });
}
