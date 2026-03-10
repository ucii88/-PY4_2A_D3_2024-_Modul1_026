import 'package:mongo_dart/mongo_dart.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:logbook_app/models/logbook_model.dart';
import 'package:logbook_app/features/logbook/models/log_model.dart';
import 'package:logbook_app/helpers/log_helper.dart';

class MongoService {
  static final MongoService _instance = MongoService._internal();
  Db? _db;
  DbCollection? _logsCollection;
  bool _isConnected = false;
  final String _source = "mongo_service.dart";

  MongoService._internal();

  factory MongoService() {
    return _instance;
  }

  Db? get db => _db;

  DbCollection? get logsCollection => _logsCollection;

  bool get isConnected => _isConnected;

  Future<DbCollection> _getSafeCollection() async {
    if (_db == null || !_db!.isConnected || _logsCollection == null) {
      await LogHelper.writeLog(
        "INFO: Koleksi belum siap, mencoba rekoneksi...",
        source: _source,
        level: 3,
      );
      await connect();
    }
    return _logsCollection!;
  }

  Future<void> connect() async {
    try {
      final mongoUri = dotenv.env['MONGODB_URI'];
      if (mongoUri == null || mongoUri.isEmpty) {
        throw Exception('MONGODB_URI tidak ditemukan di .env file');
      }

      await LogHelper.writeLog(
        "INFO: Mencoba koneksi ke MongoDB Atlas...",
        source: _source,
        level: 2,
      );

      _db = Db(mongoUri);

      await _db!.open().timeout(
        const Duration(seconds: 15),
        onTimeout: () => throw Exception(
          "Koneksi Timeout (15s). Cek IP Whitelist (0.0.0.0/0) atau sinyal HP.",
        ),
      );

      _isConnected = true;
      _logsCollection = _db!.collection('logs');

      await LogHelper.writeLog(
        "SUCCESS: Koneksi MongoDB & Koleksi 'logs' Siap",
        source: _source,
        level: 2,
      );
    } catch (e) {
      _isConnected = false;
      await LogHelper.writeLog(
        "ERROR: Gagal Connect - $e",
        source: _source,
        level: 1,
      );
      rethrow;
    }
  }

  Future<void> disconnect() async {
    if (_isConnected && _db != null) {
      await _db!.close();
      _isConnected = false;
      await LogHelper.writeLog(
        "INFO: Koneksi ditutup",
        source: _source,
        level: 2,
      );
    }
  }

  Future<void> close() async {
    await disconnect();
  }

  Future<ObjectId> insertLog(Logbook logbook) async {
    try {
      final collection = await _getSafeCollection();
      final map = logbook.toMap();
      final result = await collection.insertOne(map);

      await LogHelper.writeLog(
        "SUCCESS: Log '${logbook.title}' berhasil disimpan ke Cloud",
        source: _source,
        level: 2,
      );
      return result.id as ObjectId;
    } catch (e) {
      await LogHelper.writeLog(
        "ERROR: Insert Failed - $e",
        source: _source,
        level: 1,
      );
      rethrow;
    }
  }

  Future<List<Logbook>> getLogs(String username) async {
    try {
      final collection = await _getSafeCollection();

      await LogHelper.writeLog(
        "INFO: Fetching data from Cloud for user $username...",
        source: _source,
        level: 3,
      );

      final result = await collection.find({'username': username}).toList();

      await LogHelper.writeLog(
        "SUCCESS: Retrieved ${result.length} logs untuk $username",
        source: _source,
        level: 2,
      );

      return result.map((e) => Logbook.fromMap(e)).toList();
    } catch (e) {
      await LogHelper.writeLog(
        "ERROR: Get Logs Failed - $e",
        source: _source,
        level: 1,
      );
      rethrow;
    }
  }

  Future<bool> updateLog(ObjectId id, Logbook logbook) async {
    try {
      final collection = await _getSafeCollection();

      await collection.replaceOne(where.id(id), logbook.toMap());

      await LogHelper.writeLog(
        "SUCCESS: Log Update berhasil",
        source: _source,
        level: 2,
      );
      return true;
    } catch (e) {
      await LogHelper.writeLog(
        "ERROR: Update Failed - $e",
        source: _source,
        level: 1,
      );
      rethrow;
    }
  }

  Future<bool> deleteLog(ObjectId id) async {
    try {
      final collection = await _getSafeCollection();
      await collection.deleteOne(where.id(id));

      await LogHelper.writeLog(
        "SUCCESS: Log Delete berhasil",
        source: _source,
        level: 2,
      );
      return true;
    } catch (e) {
      await LogHelper.writeLog(
        "ERROR: Delete Failed - $e",
        source: _source,
        level: 1,
      );
      rethrow;
    }
  }

  Future<List<Logbook>> searchLogs(String query) async {
    try {
      final collection = await _getSafeCollection();

      await LogHelper.writeLog(
        "INFO: Searching for '$query' in Cloud...",
        source: _source,
        level: 3,
      );

      final result = await collection.find({
        r'$or': [
          {
            'title': {r'$regex': query, r'$options': 'i'},
          },
          {
            'description': {r'$regex': query, r'$options': 'i'},
          },
        ],
      }).toList();

      await LogHelper.writeLog(
        "SUCCESS: Search found ${result.length} results for '$query'",
        source: _source,
        level: 2,
      );

      return result.map((e) => Logbook.fromMap(e)).toList();
    } catch (e) {
      await LogHelper.writeLog(
        "ERROR: Search Failed - $e",
        source: _source,
        level: 1,
      );
      rethrow;
    }
  }

  // ========== LANGKAH 4: COLLABORATIVE SYNC METHODS ==========

  /// Mendapatkan logs berdasarkan teamId (untuk kolaborasi antar tim)
  Future<List<LogModel>> getLogsByTeam(String teamId) async {
    try {
      final collection = await _getSafeCollection();

      await LogHelper.writeLog(
        "INFO: Fetching logs for Team: $teamId",
        source: _source,
        level: 3,
      );

      final List<Map<String, dynamic>> data = await collection
          .find(where.eq('teamId', teamId))
          .toList();

      final logs = data.map((json) => LogModel.fromMap(json)).toList();

      await LogHelper.writeLog(
        "SUCCESS: Retrieved ${logs.length} logs for teamId=$teamId",
        source: _source,
        level: 2,
      );

      return logs;
    } catch (e) {
      await LogHelper.writeLog(
        "ERROR: getLogsByTeam failed - $e",
        source: _source,
        level: 1,
      );
      return [];
    }
  }

  /// Insert LogModel ke MongoDB (untuk LogEditorPage create)
  Future<ObjectId?> insertLogModel(LogModel logModel) async {
    try {
      final collection = await _getSafeCollection();
      final map = logModel.toMap();
      final result = await collection.insertOne(map);

      await LogHelper.writeLog(
        "SUCCESS: LogModel '${logModel.title}' inserted to Cloud",
        source: _source,
        level: 2,
      );
      return result.id as ObjectId;
    } catch (e) {
      await LogHelper.writeLog(
        "ERROR: insertLogModel failed - $e",
        source: _source,
        level: 1,
      );
      return null;
    }
  }

  /// ========== UPSERT METHOD (Recommended untuk Offline-First) ==========
  /// Implementasi Upsert: Update jika sudah ada (by author+title+teamId), Insert kalau belum
  /// Ini adalah solusi resmi untuk cegah duplikat sesuai modul praktikum
  Future<Map<String, dynamic>> upsertLogModel(LogModel logModel) async {
    try {
      final collection = await _getSafeCollection();

      // Filter: cari data dengan author+title+teamId yang sama
      final filter = where
          .eq('authorId', logModel.authorId)
          .eq('title', logModel.title)
          .eq('teamId', logModel.teamId);

      final map = logModel.toMap();

      // Gunakan updateOne dengan upsert:true
      // Ini berarti: Update jika ada, Insert jika tidak ada
      await LogHelper.writeLog(
        "DEBUG: Attempting upsert for '${logModel.title}' (author: ${logModel.authorId})",
        source: _source,
        level: 3,
      );

      final result = await collection.updateOne(
        filter,
        {r'$set': map},
        upsert: true, // ← Ini adalah "magic" untuk cegah duplikat!
      );

      await LogHelper.writeLog(
        "SUCCESS: Upsert completed - matched: ${result.nMatched}, modified: ${result.nModified}, upserted: ${result.nUpserted}",
        source: _source,
        level: 2,
      );

      return {
        'success': true,
        'matched': result.nMatched,
        'modified': result.nModified,
        'upserted': result.nUpserted,
      };
    } catch (e) {
      await LogHelper.writeLog(
        "ERROR: upsertLogModel failed - $e",
        source: _source,
        level: 1,
      );
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Update LogModel di MongoDB (untuk LogEditorPage edit)
  Future<bool> updateLogModel(String id, LogModel logModel) async {
    try {
      final collection = await _getSafeCollection();
      final objectId = ObjectId.fromHexString(id);
      final map = logModel.toMap();

      await collection.replaceOne(where.id(objectId), map);

      await LogHelper.writeLog(
        "SUCCESS: LogModel '${logModel.title}' updated in Cloud",
        source: _source,
        level: 2,
      );
      return true;
    } catch (e) {
      await LogHelper.writeLog(
        "ERROR: updateLogModel failed - $e",
        source: _source,
        level: 1,
      );
      return false;
    }
  }

  /// Delete LogModel dari MongoDB
  Future<bool> deleteLogModel(String id) async {
    try {
      final collection = await _getSafeCollection();
      final objectId = ObjectId.fromHexString(id);

      final result = await collection.deleteOne(where.id(objectId));

      await LogHelper.writeLog(
        "SUCCESS: LogModel deleted from Cloud",
        source: _source,
        level: 2,
      );
      return result.ok == 1.0;
    } catch (e) {
      await LogHelper.writeLog(
        "ERROR: deleteLogModel failed - $e",
        source: _source,
        level: 1,
      );
      return false;
    }
  }

  /// Update LogModel by cloudId (untuk sync offline changes)
  Future<bool> updateLogByCloudId(ObjectId cloudId, LogModel logModel) async {
    try {
      final collection = await _getSafeCollection();
      final map = logModel.toMap();

      // Update dengan _id = cloudId
      await collection.replaceOne(where.id(cloudId), map);

      await LogHelper.writeLog(
        "SUCCESS: LogModel '${logModel.title}' synced to Cloud (cloudId: ${cloudId.oid})",
        source: _source,
        level: 2,
      );
      return true;
    } catch (e) {
      await LogHelper.writeLog(
        "ERROR: updateLogByCloudId failed - $e",
        source: _source,
        level: 1,
      );
      return false;
    }
  }

  /// Delete LogModel by cloudId (untuk sync offline deletions)
  Future<bool> deleteLogByCloudId(ObjectId cloudId) async {
    try {
      final collection = await _getSafeCollection();

      final result = await collection.deleteOne(where.id(cloudId));

      await LogHelper.writeLog(
        "SUCCESS: LogModel deleted from Cloud (cloudId: ${cloudId.oid})",
        source: _source,
        level: 2,
      );
      return result.ok == 1.0;
    } catch (e) {
      await LogHelper.writeLog(
        "ERROR: deleteLogByCloudId failed - $e",
        source: _source,
        level: 1,
      );
      return false;
    }
  }
}
