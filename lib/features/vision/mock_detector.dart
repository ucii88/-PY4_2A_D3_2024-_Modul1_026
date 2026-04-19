import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:logbook_app/services/coordinate_mapper.dart';
import 'package:logbook_app/services/detection_model.dart';

class MockDetector {
  static const double _minConfidence = 0.75;
  static const double _maxConfidence = 0.98;
  final _random = Random();
  DetectionResult generateMockDetection() {
    final damageTypes = RoadDamageType.values;
    final randomDamageType = damageTypes[_random.nextInt(damageTypes.length)];
    final boxSize = 0.15 + _random.nextDouble() * 0.1;
    final left = _random.nextDouble() * (1.0 - boxSize);
    final top = _random.nextDouble() * (1.0 - boxSize);
    final confidence =
        _minConfidence +
        _random.nextDouble() * (_maxConfidence - _minConfidence);
    _logScalingAnalysis(
      left: left,
      top: top,
      boxSize: boxSize,
      damageType: randomDamageType,
    );
    return DetectionResult(
      left: left,
      top: top,
      width: boxSize,
      height: boxSize,
      confidence: confidence,
      damageType: randomDamageType,
      detectionId: 'mock_${DateTime.now().millisecondsSinceEpoch}',
      detectedAt: DateTime.now(),
    );
  }

  List<DetectionResult> generateBatch() {
    final count = _random.nextInt(4);
    return List.generate(count, (_) => generateMockDetection());
  }

  void _logScalingAnalysis({
    required double left,
    required double top,
    required double boxSize,
    required RoadDamageType damageType,
  }) {
    if (!kDebugMode) return;
    final damageCode = _getDamageCode(damageType);
    final damageName = _getDamageName(damageType);
    const List<double> screenWidths = [360, 400, 500, 600];
    debugPrint(
      '📊 [SCALING ANALYSIS] Detection: $damageCode $damageName '
      '@ normalized(${left.toStringAsFixed(3)}, ${top.toStringAsFixed(3)}), '
      'size=${boxSize.toStringAsFixed(3)}',
    );
    for (final screenWidth in screenWidths) {
      final pixelLeft = left * screenWidth;
      final pixelTop = top * screenWidth;
      final pixelSize = boxSize * screenWidth;
      debugPrint(
        '   → Screen ${screenWidth.toInt()}px: '
        'pixel(${pixelLeft.toStringAsFixed(1)}, ${pixelTop.toStringAsFixed(1)}), '
        'size=${pixelSize.toStringAsFixed(1)}px',
      );
    }
  }

  String _getDamageCode(RoadDamageType damageType) {
    switch (damageType) {
      case RoadDamageType.longitudinal:
        return 'D00';
      case RoadDamageType.transverse:
        return 'D10';
      case RoadDamageType.alligator:
        return 'D20';
      case RoadDamageType.pothole:
        return 'D40';
    }
  }

  String _getDamageName(RoadDamageType damageType) {
    switch (damageType) {
      case RoadDamageType.longitudinal:
        return 'LONGITUDINAL';
      case RoadDamageType.transverse:
        return 'TRANSVERSE';
      case RoadDamageType.alligator:
        return 'ALLIGATOR';
      case RoadDamageType.pothole:
        return 'POTHOLE';
    }
  }
}
