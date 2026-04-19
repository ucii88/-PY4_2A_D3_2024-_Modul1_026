import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';

class CameraFrameProcessor {
  static Future<CameraImage?> applyBrightness(
    CameraImage image,
    double brightness,
  ) async {
    if (brightness == 0.0) return image;
    try {
      final planes = image.planes;
      final yPlane = planes[0];
      final yData = yPlane.bytes;
      final brightnessFactor = 1.0 + (brightness / 100.0);
      for (int i = 0; i < yData.length; i++) {
        final newValue = (yData[i] * brightnessFactor).clamp(0, 255).toInt();
        yData[i] = newValue;
      }
      return image;
    } catch (e) {
      debugPrint(' [CameraFrameProcessor] Brightness error: $e');
      return image;
    }
  }

  static Future<CameraImage?> applyContrast(
    CameraImage image,
    double contrast,
  ) async {
    if (contrast == 1.0) return image;
    try {
      final planes = image.planes;
      final yPlane = planes[0];
      final yData = yPlane.bytes;
      for (int i = 0; i < yData.length; i++) {
        final newValue = (((yData[i] - 128) * contrast) + 128)
            .clamp(0, 255)
            .toInt();
        yData[i] = newValue;
      }
      return image;
    } catch (e) {
      debugPrint(' [CameraFrameProcessor] Contrast error: $e');
      return image;
    }
  }

  static Future<CameraImage?> applyGrayscale(CameraImage image) async {
    if (image.format.group == ImageFormatGroup.yuv420) {
      try {
        final planes = image.planes;
        if (planes.length >= 3) {
          for (int i = 0; i < planes[1].bytes.length; i++) {
            planes[1].bytes[i] = 128;
            planes[2].bytes[i] = 128;
          }
        }
        return image;
      } catch (e) {
        debugPrint(' [CameraFrameProcessor] Grayscale error: $e');
        return image;
      }
    }
    return image;
  }

  static double calculateAverageLuminance(CameraImage image) {
    try {
      if (image.planes.isEmpty) return 128.0;
      final yPlane = image.planes[0];
      final yData = yPlane.bytes;
      if (yData.isEmpty) return 128.0;
      int sum = 0;
      int sampleCount = 0;
      final sampleRate = (yData.length > 500000)
          ? 50
          : (yData.length > 100000)
          ? 20
          : 10;
      for (int i = 0; i < yData.length; i += sampleRate) {
        sum += yData[i].toUnsigned(8);
        sampleCount++;
      }
      if (sampleCount == 0) return 128.0;
      final average = (sum ~/ sampleCount).toDouble();
      return average.clamp(0, 255);
    } catch (e) {
      debugPrint(' [CameraFrameProcessor] Luminance calc error: $e');
      return 128.0;
    }
  }

  static List<int> calculateHistogram(CameraImage image) {
    final histogram = List<int>.filled(256, 0);
    try {
      final yPlane = image.planes[0];
      final yData = yPlane.bytes;
      final sampleRate = (yData.length > 500000)
          ? 200
          : (yData.length > 100000)
          ? 100
          : 20;
      for (int i = 0; i < yData.length; i += sampleRate) {
        histogram[yData[i]]++;
      }
    } catch (e) {
      debugPrint(' [CameraFrameProcessor] Histogram error: $e');
    }
    return histogram;
  }
}
