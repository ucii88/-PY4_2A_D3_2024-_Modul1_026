import 'package:mongo_dart/mongo_dart.dart';

class LogModel {
  final String title;
  final String date;
  final String description;
  final String category;

  final ObjectId? cloudId;

  LogModel({
    required this.title,
    required this.date,
    required this.description,
    this.category = "Pribadi",
    this.cloudId,
  });

  // Untuk Tugas HOTS: Konversi Map (JSON) ke Object
  factory LogModel.fromMap(Map<String, dynamic> map) {
    return LogModel(
      title: map['title'],
      date: map['date'],
      description: map['description'],
      category: map['category'] ?? "Pribadi",
      cloudId: map['cloudId'] != null ? ObjectId.parse(map['cloudId']) : null,
    );
  }

  // Konversi Object ke Map (JSON) untuk disimpan
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'date': date,
      'description': description,
      'category': category,
      if (cloudId != null) 'cloudId': cloudId!.toHexString(),
    };
  }
}
