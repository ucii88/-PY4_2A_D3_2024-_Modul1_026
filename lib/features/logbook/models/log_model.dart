import 'package:hive/hive.dart';
import 'package:mongo_dart/mongo_dart.dart';

part 'log_model.g.dart';

@HiveType(typeId: 0)
class LogModel {
  @HiveField(0)
  final String title;

  @HiveField(1)
  final String date;

  @HiveField(2)
  final String description;

  @HiveField(3)
  final String category;

  @HiveField(4)
  final String? id; // Untuk penyimpanan ID MongoDB

  @HiveField(5)
  final String authorId; // BARU: ID pembuat logbook

  @HiveField(6)
  final String teamId; // BARU: ID tim (untuk kolaborasi)

  @HiveField(7)
  final ObjectId? cloudId; // Untuk sinkronisasi dengan cloud

  @HiveField(8)
  final bool isPublic; // Privacy control: true = visible to all, false = only owner

  @HiveField(9)
  final String syncStatus; // NEW: 'pending', 'synced', 'deleted'

  LogModel({
    required this.title,
    required this.date,
    required this.description,
    this.category = "Mechanical", // Default kategori Mechanical
    this.id,
    required this.authorId,
    required this.teamId,
    this.cloudId,
    this.isPublic = false,
    this.syncStatus = 'pending',
  });

  // Untuk Tugas HOTS: Konversi Map (JSON) ke Object
  factory LogModel.fromMap(Map<String, dynamic> map) {
    return LogModel(
      title: map['title'] ?? '',
      date: map['date'] ?? '',
      description: map['description'] ?? '',
      category: map['category'] ?? "Pribadi",
      id: (map['_id'] as ObjectId?)?.oid,
      authorId: map['authorId'] ?? 'unknown_user',
      teamId: map['teamId'] ?? 'no_team',
      cloudId: map['cloudId'] != null ? ObjectId.parse(map['cloudId']) : null,
      isPublic: map['isPublic'] ?? false, // Default: Private
      syncStatus: map['syncStatus'] ?? 'synced',
    );
  }

  // Konversi Object ke Map (JSON) untuk disimpan
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'date': date,
      'description': description,
      'category': category,
      'authorId': authorId,
      'teamId': teamId,
      'isPublic': isPublic,
      'syncStatus': syncStatus,
      if (id != null) '_id': ObjectId.fromHexString(id!),
      if (cloudId != null) 'cloudId': cloudId!.oid,
    };
  }
}
