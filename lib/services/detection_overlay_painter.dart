import 'package:flutter/material.dart';
import 'package:logbook_app/services/coordinate_mapper.dart';
import 'package:logbook_app/services/detection_model.dart';

class DetectionOverlayPainter extends CustomPainter {
  final List<DetectionResult> detections;

  final bool showBoundingBox;
  final bool showCrosshair;
  final bool showInformationPanel;

  final Rect? targetArea;

  final int? fps;
  final String? statusMessage;

  DetectionOverlayPainter({
    this.detections = const [],
    this.showBoundingBox = true,
    this.showCrosshair = true,
    this.showInformationPanel = true,
    this.targetArea,
    this.fps,
    this.statusMessage,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (targetArea != null) {
      _drawTargetArea(canvas, size, targetArea!);
    }

    for (final detection in detections) {
      _drawDetectionBox(canvas, size, detection);
    }

    if (showCrosshair) {
      _drawCrosshair(canvas, size);
    }

    if (showInformationPanel) {
      _drawInformationPanel(canvas, size);
    }
  }

  void _drawTargetArea(Canvas canvas, Size size, Rect targetArea) {
    final paint = Paint()
      ..color = const Color.fromARGB(100, 76, 175, 80)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    canvas.drawRect(targetArea, paint);

    const double cornerSize = 20.0;
    final cornerPaint = Paint()
      ..color = const Color.fromARGB(255, 76, 175, 80)
      ..strokeWidth = 3.0;

    canvas.drawLine(
      targetArea.topLeft,
      targetArea.topLeft.translate(cornerSize, 0),
      cornerPaint,
    );
    canvas.drawLine(
      targetArea.topLeft,
      targetArea.topLeft.translate(0, cornerSize),
      cornerPaint,
    );

    canvas.drawLine(
      targetArea.topRight,
      targetArea.topRight.translate(-cornerSize, 0),
      cornerPaint,
    );
    canvas.drawLine(
      targetArea.topRight,
      targetArea.topRight.translate(0, cornerSize),
      cornerPaint,
    );

    canvas.drawLine(
      targetArea.bottomLeft,
      targetArea.bottomLeft.translate(cornerSize, 0),
      cornerPaint,
    );
    canvas.drawLine(
      targetArea.bottomLeft,
      targetArea.bottomLeft.translate(0, -cornerSize),
      cornerPaint,
    );

    canvas.drawLine(
      targetArea.bottomRight,
      targetArea.bottomRight.translate(-cornerSize, 0),
      cornerPaint,
    );
    canvas.drawLine(
      targetArea.bottomRight,
      targetArea.bottomRight.translate(0, -cornerSize),
      cornerPaint,
    );
  }

  void _drawDetectionBox(Canvas canvas, Size size, DetectionResult detection) {
    final rect = detection.toPaintRect(size);

    final Color boxColor = detection.damageType.severityColor;

    final boxPaint = Paint()
      ..color = boxColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;
    canvas.drawRect(rect, boxPaint);

    const double labelHeight = 28.0;
    final headerRect = Rect.fromLTWH(
      rect.left,
      rect.top - labelHeight,
      rect.width,
      labelHeight,
    );

    final headerPaint = Paint()
      ..color = boxColor.withOpacity(0.85)
      ..style = PaintingStyle.fill;
    canvas.drawRect(headerRect, headerPaint);

    final label =
        '${detection.damageType.code} - ${detection.damageType.label}';
    final confidence = '${(detection.confidence * 100).toStringAsFixed(1)}%';

    final labelTextPainter = TextPainter(
      text: TextSpan(
        text: label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11.0,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    labelTextPainter.layout();

    final confidenceTextPainter = TextPainter(
      text: TextSpan(
        text: confidence,
        style: const TextStyle(color: Colors.white70, fontSize: 10.0),
      ),
      textDirection: TextDirection.ltr,
    );
    confidenceTextPainter.layout();

    labelTextPainter.paint(
      canvas,
      Offset(rect.left + 4, rect.top - labelHeight + 4),
    );
    confidenceTextPainter.paint(
      canvas,
      Offset(
        rect.right - confidenceTextPainter.width - 4,
        rect.top - labelHeight + 4,
      ),
    );
  }

  void _drawCrosshair(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    const double crosshairSize = 40.0;
    const double thickness = 2.0;

    final paint = Paint()
      ..color = Colors.cyan.withOpacity(0.7)
      ..strokeWidth = thickness;

    canvas.drawLine(
      center.translate(-crosshairSize, 0),
      center.translate(crosshairSize, 0),
      paint,
    );

    canvas.drawLine(
      center.translate(0, -crosshairSize),
      center.translate(0, crosshairSize),
      paint,
    );

    final dotPaint = Paint()
      ..color = Colors.cyan
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 4, dotPaint);
  }

  void _drawInformationPanel(Canvas canvas, Size size) {
    const double panelWidth = 200.0;
    const double panelHeight = 80.0;
    const double padding = 12.0;

    final panelRect = Rect.fromLTWH(padding, padding, panelWidth, panelHeight);

    // Draw semi-transparent background
    final bgPaint = Paint()
      ..color = const Color.fromARGB(180, 0, 0, 0)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(
      RRect.fromRectAndRadius(panelRect, const Radius.circular(8)),
      bgPaint,
    );

    final borderPaint = Paint()
      ..color = Colors.cyan
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawRRect(
      RRect.fromRectAndRadius(panelRect, const Radius.circular(8)),
      borderPaint,
    );

    String infoText = '';
    if (fps != null) {
      infoText += 'FPS: $fps\n';
    }
    if (statusMessage != null) {
      infoText += statusMessage!;
    }
    if (infoText.isEmpty) {
      infoText = 'Ready';
    }

    final textPainter = TextPainter(
      text: TextSpan(
        text: infoText,
        style: const TextStyle(
          color: Colors.cyan,
          fontSize: 11.0,
          fontFamily: 'monospace',
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(padding + 8, padding + 8));
  }

  @override
  bool shouldRepaint(DetectionOverlayPainter oldDelegate) {
    return oldDelegate.detections.length != detections.length ||
        oldDelegate.fps != fps ||
        oldDelegate.statusMessage != statusMessage ||
        oldDelegate.showBoundingBox != showBoundingBox ||
        oldDelegate.showCrosshair != showCrosshair ||
        oldDelegate.showInformationPanel != showInformationPanel;
  }
}
