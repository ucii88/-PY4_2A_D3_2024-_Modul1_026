import 'package:flutter/material.dart';
import 'package:logbook_app/services/coordinate_mapper.dart';

class DetectionResult {
  final double left;
  final double top;
  final double width;
  final double height;

  final double confidence;

  final RoadDamageType damageType;

  final String? detectionId;

  final DateTime? detectedAt;

  DetectionResult({
    required this.left,
    required this.top,
    required this.width,
    required this.height,
    required this.confidence,
    required this.damageType,
    this.detectionId,
    this.detectedAt,
  });

  Rect toPaintRect(Size canvasSize) {
    return Rect.fromLTWH(
      left * canvasSize.width,
      top * canvasSize.height,
      width * canvasSize.width,
      height * canvasSize.height,
    );
  }

  Rect toPaintRectAdvanced(Size canvasSize, CoordinateMapper mapper) {
    return mapper.normalizedToLogicalPixels(
      normalizedX: left,
      normalizedY: top,
      normalizedWidth: width,
      normalizedHeight: height,
    );
  }

  @override
  String toString() =>
      '${damageType.label} (${damageType.code}): ${(confidence * 100).toStringAsFixed(1)}%';

  DetectionResult copyWith({
    double? left,
    double? top,
    double? width,
    double? height,
    double? confidence,
    RoadDamageType? damageType,
    String? detectionId,
    DateTime? detectedAt,
  }) {
    return DetectionResult(
      left: left ?? this.left,
      top: top ?? this.top,
      width: width ?? this.width,
      height: height ?? this.height,
      confidence: confidence ?? this.confidence,
      damageType: damageType ?? this.damageType,
      detectionId: detectionId ?? this.detectionId,
      detectedAt: detectedAt ?? this.detectedAt,
    );
  }
}

extension RoadDamageTypeParser on String {
  RoadDamageType? toRoadDamageType() {
    return switch (this.toLowerCase()) {
      'longitudinal' || 'd00' => RoadDamageType.longitudinal,
      'transverse' || 'd10' => RoadDamageType.transverse,
      'alligator' || 'd20' => RoadDamageType.alligator,
      'pothole' || 'd40' => RoadDamageType.pothole,
      _ => null,
    };
  }
}

enum DamageSeverity { low, medium, high, critical }

extension DamageSeverityDisplay on DamageSeverity {
  String get label {
    return switch (this) {
      DamageSeverity.low => 'Low',
      DamageSeverity.medium => 'Medium',
      DamageSeverity.high => 'High',
      DamageSeverity.critical => 'Critical',
    };
  }

  Color get color {
    return switch (this) {
      DamageSeverity.low => Colors.yellow,
      DamageSeverity.medium => Colors.orange,
      DamageSeverity.high => Colors.deepOrange,
      DamageSeverity.critical => Colors.red,
    };
  }
}

DamageSeverity calculateSeverity(RoadDamageType type, double confidence) {
  final baseWeight = switch (type) {
    RoadDamageType.longitudinal => 0.4,
    RoadDamageType.transverse => 0.5,
    RoadDamageType.alligator => 0.7,
    RoadDamageType.pothole => 0.9,
  };

  final score = baseWeight * confidence;

  return switch (score) {
    < 0.3 => DamageSeverity.low,
    < 0.6 => DamageSeverity.medium,
    < 0.8 => DamageSeverity.high,
    _ => DamageSeverity.critical,
  };
}
