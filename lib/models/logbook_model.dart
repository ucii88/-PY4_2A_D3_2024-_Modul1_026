import 'package:mongo_dart/mongo_dart.dart';

class Logbook {
  final ObjectId? id;
  final String title;
  final String description;
  final String date;
  final String category;
  final String username; // 🔥 TAMBAHKAN FIELD USER

  Logbook({
    this.id,
    required this.title,
    required this.description,
    required this.date,
    this.category = "Pribadi",
    required this.username, // 🔥 WAJIB ADA
  });

  /// Kirim ke MongoDB
  Map<String, dynamic> toMap() {
    return {
      '_id': id,
      'title': title,
      'description': description,
      'date': date,
      'category': category,
      'username': username, // 🔥 SIMPAN USER KE DATABASE
    };
  }

  /// Ambil dari MongoDB
  factory Logbook.fromMap(Map<String, dynamic> map) {
    return Logbook(
      id: map['_id'] as ObjectId?,
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      date: map['date'] ?? DateTime.now().toString(),
      category: map['category'] ?? 'Pribadi',
      username: map['username'] ?? '', // 🔥 BACA USER
    );
  }

  /// Bridge dari model lokal ke cloud
  static Logbook fromLogModel({
    ObjectId? id,
    required String title,
    required String description,
    required String date,
    required String category,
    required String username, // 🔥 TAMBAHKAN
  }) {
    return Logbook(
      id: id,
      title: title,
      description: description,
      date: date,
      category: category,
      username: username,
    );
  }
}
