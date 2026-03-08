import 'package:mongo_dart/mongo_dart.dart';

class Logbook {
  final ObjectId? id;
  final String title;
  final String description;
  final String date;
  final String category;
  final String username;

  Logbook({
    this.id,
    required this.title,
    required this.description,
    required this.date,
    this.category = "Pribadi",
    required this.username,
  });

  Map<String, dynamic> toMap() {
    return {
      '_id': id,
      'title': title,
      'description': description,
      'date': date,
      'category': category,
      'username': username,
    };
  }

  factory Logbook.fromMap(Map<String, dynamic> map) {
    return Logbook(
      id: map['_id'] as ObjectId?,
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      date: map['date'] ?? DateTime.now().toString(),
      category: map['category'] ?? 'Pribadi',
      username: map['username'] ?? '',
    );
  }

  static Logbook fromLogModel({
    ObjectId? id,
    required String title,
    required String description,
    required String date,
    required String category,
    required String username,
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
