import 'package:flutter/material.dart';
import 'package:logbook_app/services/coordinate_mapper.dart';
import 'package:logbook_app/services/detection_model.dart';

class DamagePainter extends CustomPainter {
  final List<DetectionResult> detections;
  final Rect? targetArea;
  final int? fps;
  final String statusMessage;
  final bool showBoundingBox;
  final bool showCrosshair;
  final bool showInformationPanel;
  DamagePainter({
    required this.detections,
    required this.targetArea,
    required this.fps,
    required this.statusMessage,
    required this.showBoundingBox,
    required this.showCrosshair,
    required this.showInformationPanel,
  });
  @override
  void paint(Canvas canvas, Size size) {
    if (targetArea != null) {
      _drawTargetArea(canvas, size, targetArea!);
    }
    if (showBoundingBox) {
      for (final detection in detections) {
        _drawDetectionBox(canvas, size, detection);
      }
    }
    if (showInformationPanel) {
      _drawInformationPanel(canvas, size, detections.length, fps);
    }
    if (showCrosshair) {
      _drawCrosshair(canvas, size);
    }
    _drawStatusMessage(canvas, size, statusMessage);
  }

  void _drawDetectionBox(Canvas canvas, Size size, DetectionResult detection) {
    final pixelLeft = detection.left * size.width;
    final pixelTop = detection.top * size.height;
    final pixelWidth = detection.width * size.width;
    final pixelHeight = detection.height * size.height;
    final rect = Rect.fromLTWH(pixelLeft, pixelTop, pixelWidth, pixelHeight);
    final damageColor = _getDamageColor(detection.damageType);

    // Shadow/Glow effect
    final shadowPaint = Paint()
      ..color = damageColor.withOpacity(0.3)
      ..strokeWidth = 6.0
      ..style = PaintingStyle.stroke;
    canvas.drawRect(rect, shadowPaint);

    // Main box stroke
    final boxPaint = Paint()
      ..color = damageColor
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke;
    canvas.drawRect(rect, boxPaint);

    _drawDetectionLabel(canvas, rect, detection, damageColor);
  }

  void _drawDetectionLabel(
    Canvas canvas,
    Rect boxRect,
    DetectionResult detection,
    Color damageColor,
  ) {
    final damageCode = _getDamageCode(detection.damageType);
    final confidence = (detection.confidence * 100).toStringAsFixed(0);

    // Create text with shadow effect
    final textSpan = TextSpan(
      text: '$damageCode (${confidence}%)',
      style: const TextStyle(
        color: Colors.white,
        fontSize: 12,
        fontWeight: FontWeight.bold,
        shadows: [
          Shadow(
            offset: Offset(2, 2),
            blurRadius: 4,
            color: Color.fromARGB(128, 0, 0, 0),
          ),
          Shadow(
            offset: Offset(-1, -1),
            blurRadius: 3,
            color: Color.fromARGB(80, 0, 0, 0),
          ),
        ],
      ),
    );

    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();

    double labelY = boxRect.top - textPainter.height - 5;
    if (labelY < 0) {
      labelY = boxRect.bottom + 5;
    }

    // Background with gradient-like effect
    final labelBgPaint = Paint()
      ..color = damageColor.withOpacity(0.85)
      ..style = PaintingStyle.fill;

    // Border stroke for better definition
    final labelBorderPaint = Paint()
      ..color = Colors.white.withOpacity(0.6)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final labelBgRect = Rect.fromLTWH(
      boxRect.left - 4,
      labelY - 2,
      textPainter.width + 8,
      textPainter.height + 4,
    );

    // Draw background
    canvas.drawRRect(
      RRect.fromRectAndRadius(labelBgRect, const Radius.circular(3)),
      labelBgPaint,
    );

    // Draw border/stroke
    canvas.drawRRect(
      RRect.fromRectAndRadius(labelBgRect, const Radius.circular(3)),
      labelBorderPaint,
    );

    // Draw text with shadow already applied via TextStyle
    textPainter.paint(canvas, Offset(boxRect.left, labelY));
  }

  void _drawTargetArea(Canvas canvas, Size size, Rect targetArea) {
    if (targetArea.width >= size.width * 0.95 &&
        targetArea.height >= size.height * 0.9) {
      return;
    }
    final roiPaint = Paint()
      ..color = Colors.white.withOpacity(0.5)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;
    canvas.drawRect(targetArea, roiPaint);
    const textStyle = TextStyle(
      color: Colors.white,
      fontSize: 11,
      fontWeight: FontWeight.normal,
    );
    final textSpan = TextSpan(text: 'TARGET AREA', style: textStyle);
    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(targetArea.left + 8, targetArea.top + 8));
  }

  void _drawCrosshair(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    const crosshairSize = 40.0;
    const crosshairRadius = 6.0;
    const crosshairGap = 10.0;
    final paint = Paint()
      ..color = Colors.cyan.withOpacity(0.7)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;
    canvas.drawLine(
      center - const Offset(crosshairSize, 0),
      center - const Offset(crosshairGap, 0),
      paint,
    );
    canvas.drawLine(
      center + const Offset(crosshairGap, 0),
      center + const Offset(crosshairSize, 0),
      paint,
    );
    canvas.drawLine(
      center - const Offset(0, crosshairSize),
      center - const Offset(0, crosshairGap),
      paint,
    );
    canvas.drawLine(
      center + const Offset(0, crosshairGap),
      center + const Offset(0, crosshairSize),
      paint,
    );
    canvas.drawCircle(center, crosshairRadius, paint);
    const bracketSize = 25.0;
    final bracketPaint = Paint()
      ..color = Colors.cyan.withOpacity(0.5)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;
    canvas.drawLine(
      center - const Offset(bracketSize, bracketSize),
      center - const Offset(bracketSize, bracketSize - 8),
      bracketPaint,
    );
    canvas.drawLine(
      center - const Offset(bracketSize, bracketSize),
      center - const Offset(bracketSize - 8, bracketSize),
      bracketPaint,
    );
    canvas.drawLine(
      center + const Offset(bracketSize, -bracketSize),
      center + const Offset(bracketSize, -bracketSize + 8),
      bracketPaint,
    );
    canvas.drawLine(
      center + const Offset(bracketSize, -bracketSize),
      center + const Offset(bracketSize - 8, -bracketSize),
      bracketPaint,
    );
    canvas.drawLine(
      center - const Offset(bracketSize, -bracketSize),
      center - const Offset(bracketSize, -bracketSize + 8),
      bracketPaint,
    );
    canvas.drawLine(
      center - const Offset(bracketSize, -bracketSize),
      center - const Offset(bracketSize - 8, -bracketSize),
      bracketPaint,
    );
    canvas.drawLine(
      center + const Offset(bracketSize, bracketSize),
      center + const Offset(bracketSize, bracketSize - 8),
      bracketPaint,
    );
    canvas.drawLine(
      center + const Offset(bracketSize, bracketSize),
      center + const Offset(bracketSize - 8, bracketSize),
      bracketPaint,
    );
  }

  void _drawInformationPanel(
    Canvas canvas,
    Size size,
    int detectionCount,
    int? fps,
  ) {
    const panelHeight = 60.0;
    final panelRect = Rect.fromLTWH(
      10,
      size.height - panelHeight - 10,
      150,
      panelHeight,
    );
    final panelPaint = Paint()
      ..color = Colors.black.withOpacity(0.7)
      ..style = PaintingStyle.fill;
    canvas.drawRect(panelRect, panelPaint);
    final borderPaint = Paint()
      ..color = Colors.cyan
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;
    canvas.drawRect(panelRect, borderPaint);
    final infoParts = [
      'Detections: $detectionCount',
      if (fps != null) 'FPS: $fps',
    ];
    const textStyle = TextStyle(
      color: Colors.cyan,
      fontSize: 11,
      fontFamily: 'monospace',
    );
    double yOffset = panelRect.top + 8;
    for (final infoPart in infoParts) {
      final textSpan = TextSpan(text: infoPart, style: textStyle);
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(panelRect.left + 8, yOffset));
      yOffset += 18;
    }
  }

  void _drawStatusMessage(Canvas canvas, Size size, String message) {
    const textStyle = TextStyle(
      color: Colors.white,
      fontSize: 14,
      fontWeight: FontWeight.bold,
      letterSpacing: 0.5,
    );
    final textSpan = TextSpan(text: message, style: textStyle);
    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    final offsetX = (size.width - textPainter.width) / 2;
    final offsetY = 16.0;
    final backgroundRect = Rect.fromLTWH(
      offsetX - 12,
      offsetY - 4,
      textPainter.width + 24,
      textPainter.height + 8,
    );
    final bgPaint = Paint()
      ..color = Colors.black.withOpacity(0.6)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(
      RRect.fromRectAndRadius(backgroundRect, const Radius.circular(6)),
      bgPaint,
    );
    final borderPaint = Paint()
      ..color = Colors.cyan.withOpacity(0.4)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    canvas.drawRRect(
      RRect.fromRectAndRadius(backgroundRect, const Radius.circular(6)),
      borderPaint,
    );
    textPainter.paint(canvas, Offset(offsetX, offsetY));
  }

  Color _getDamageColor(RoadDamageType damageType) {
    switch (damageType) {
      case RoadDamageType.longitudinal:
        return const Color(0xFFFF9800);
      case RoadDamageType.transverse:
        return const Color(0xFFFFC107);
      case RoadDamageType.alligator:
        return const Color(0xFFE91E63);
      case RoadDamageType.pothole:
        return const Color(0xFFD32F2F);
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

  @override
  bool shouldRepaint(DamagePainter oldDelegate) {
    if (oldDelegate.detections.length != detections.length) {
      return true;
    }
    if (oldDelegate.showBoundingBox != showBoundingBox ||
        oldDelegate.showCrosshair != showCrosshair ||
        oldDelegate.showInformationPanel != showInformationPanel) {
      return true;
    }
    if (oldDelegate.statusMessage != statusMessage) {
      return true;
    }
    for (int i = 0; i < detections.length; i++) {
      final oldDet = oldDelegate.detections[i];
      final newDet = detections[i];
      if (oldDet.left != newDet.left ||
          oldDet.top != newDet.top ||
          oldDet.width != newDet.width ||
          oldDet.height != newDet.height ||
          oldDet.confidence != newDet.confidence ||
          oldDet.damageType != newDet.damageType) {
        return true;
      }
    }
    return false;
  }

  @override
  bool shouldRebuildSemantics(DamagePainter oldDelegate) {
    return false;
  }
}
