import 'package:flutter/material.dart';
import 'package:camera/camera.dart';

enum RoadDamageType {
  longitudinal, // D00
  transverse, // D10
  alligator, // D20
  pothole, // D40
}

/// Extension untuk mendapatkan label string
extension RoadDamageTypeLabel on RoadDamageType {
  String get label {
    return switch (this) {
      RoadDamageType.longitudinal => 'Longitudinal Crack',
      RoadDamageType.transverse => 'Transverse Crack',
      RoadDamageType.alligator => 'Alligator Crack',
      RoadDamageType.pothole => 'Pothole',
    };
  }

  String get code {
    return switch (this) {
      RoadDamageType.longitudinal => 'D00',
      RoadDamageType.transverse => 'D10',
      RoadDamageType.alligator => 'D20',
      RoadDamageType.pothole => 'D40',
    };
  }

  Color get severityColor {
    return switch (this) {
      RoadDamageType.longitudinal => Colors.yellow,
      RoadDamageType.transverse => Colors.orange,
      RoadDamageType.alligator => Colors.deepOrange,
      RoadDamageType.pothole => Colors.red,
    };
  }
}

class CoordinateMapper {
  final double cameraFrameWidth;
  final double cameraFrameHeight;

  final double screenWidth;
  final double screenHeight;

  final CameraLensDirection lensDirection;

  CoordinateMapper({
    required this.cameraFrameWidth,
    required this.cameraFrameHeight,
    required this.screenWidth,
    required this.screenHeight,
    required this.lensDirection,
  });

  Rect normalizedToLogicalPixels({
    required double normalizedX,
    required double normalizedY,
    required double normalizedWidth,
    required double normalizedHeight,
  }) {
    final double logicalX = normalizedX * screenWidth;
    final double logicalY = normalizedY * screenHeight;
    final double logicalW = normalizedWidth * screenWidth;
    final double logicalH = normalizedHeight * screenHeight;

    return Rect.fromLTWH(logicalX, logicalY, logicalW, logicalH);
  }

  Rect frameToLogicalPixels({
    required double frameX,
    required double frameY,
    required double frameWidth,
    required double frameHeight,
  }) {
    final double normalizedX = frameX / cameraFrameWidth;
    final double normalizedY = frameY / cameraFrameHeight;
    final double normalizedW = frameWidth / cameraFrameWidth;
    final double normalizedH = frameHeight / cameraFrameHeight;

    return normalizedToLogicalPixels(
      normalizedX: normalizedX,
      normalizedY: normalizedY,
      normalizedWidth: normalizedW,
      normalizedHeight: normalizedH,
    );
  }

  Rect logicalPixelsToNormalized({
    required double logicalX,
    required double logicalY,
    required double logicalW,
    required double logicalH,
  }) {
    final double normalizedX = logicalX / screenWidth;
    final double normalizedY = logicalY / screenHeight;
    final double normalizedW = logicalW / screenWidth;
    final double normalizedH = logicalH / screenHeight;

    return Rect.fromLTWH(normalizedX, normalizedY, normalizedW, normalizedH);
  }

  double get scaleFactorX => screenWidth / cameraFrameWidth;
  double get scaleFactorY => screenHeight / cameraFrameHeight;

  double get cameraAspectRatio => cameraFrameWidth / cameraFrameHeight;

  double get screenAspectRatio => screenWidth / screenHeight;

  bool isWithinFrame(double normalizedX, double normalizedY) {
    return normalizedX >= 0.0 &&
        normalizedX <= 1.0 &&
        normalizedY >= 0.0 &&
        normalizedY <= 1.0;
  }

  String get debugInfo {
    return '''
CoordinateMapper Debug Info:
  Camera Frame: ${cameraFrameWidth.toStringAsFixed(0)}×${cameraFrameHeight.toStringAsFixed(0)}
  Screen Logical: ${screenWidth.toStringAsFixed(0)}×${screenHeight.toStringAsFixed(0)}
  Scale Factor: X=${scaleFactorX.toStringAsFixed(2)}, Y=${scaleFactorY.toStringAsFixed(2)}
  Camera Aspect: ${cameraAspectRatio.toStringAsFixed(2)}
  Screen Aspect: ${screenAspectRatio.toStringAsFixed(2)}
''';
  }
}

enum CameraOrientation {
  portrait,
  portraitUpsideDown,
  landscapeLeft,
  landscapeRight,
}

class CameraOrientationHandler {
  final CameraOrientation sensorOrientation;

  CameraOrientation? currentAppOrientation;

  CameraOrientationHandler({
    required this.sensorOrientation,
    this.currentAppOrientation,
  });

  int getRotationDegreesNeeded() {
    if (currentAppOrientation == null) return 0;

    final sensorDegrees = switch (sensorOrientation) {
      CameraOrientation.portrait => 0,
      CameraOrientation.portraitUpsideDown => 180,
      CameraOrientation.landscapeLeft => 270,
      CameraOrientation.landscapeRight => 90,
    };

    final appDegrees = switch (currentAppOrientation!) {
      CameraOrientation.portrait => 0,
      CameraOrientation.portraitUpsideDown => 180,
      CameraOrientation.landscapeLeft => 270,
      CameraOrientation.landscapeRight => 90,
    };

    final difference = (appDegrees - sensorDegrees) % 360;
    return difference;
  }

  Rect rotateCoordinates(
    Rect originalRect,
    double originalFrameWidth,
    double originalFrameHeight,
  ) {
    final rotationDegrees = getRotationDegreesNeeded();

    if (rotationDegrees == 0 || rotationDegrees == 360) {
      return originalRect;
    }

    if (rotationDegrees == 90 || rotationDegrees == 270) {
      if (rotationDegrees == 90) {
        final newX = originalFrameHeight - originalRect.bottom;
        final newY = originalRect.left;
        final newW = originalRect.height;
        final newH = originalRect.width;

        return Rect.fromLTWH(newX, newY, newW, newH);
      } else {
        final newX = originalRect.top;
        final newY = originalFrameWidth - originalRect.right;
        final newW = originalRect.height;
        final newH = originalRect.width;

        return Rect.fromLTWH(newX, newY, newW, newH);
      }
    }

    return originalRect;
  }
}
