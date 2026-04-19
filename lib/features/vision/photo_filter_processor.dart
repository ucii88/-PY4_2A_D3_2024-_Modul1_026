import 'dart:math';
import 'package:image/image.dart' as img;

class PhotoFilterProcessor {
  static img.Image applyGrayscale(img.Image image) {
    final grayscale = img.Image(width: image.width, height: image.height);
    for (int y = 0; y < image.height; y++) {
      for (int x = 0; x < image.width; x++) {
        final pixel = image.getPixel(x, y);
        final r = pixel.r.toInt();
        final g = pixel.g.toInt();
        final b = pixel.b.toInt();
        final luma = (0.299 * r + 0.587 * g + 0.114 * b).toInt();
        grayscale.setPixelRgba(x, y, luma, luma, luma, 255);
      }
    }
    return grayscale;
  }

  static img.Image applyEqualize(img.Image image) {
    final histogram = List<int>.filled(256, 0);
    final cdf = List<int>.filled(256, 0);
    final sampleRate = (image.width * image.height > 1000000) ? 4 : 1;
    for (int y = 0; y < image.height; y += sampleRate) {
      for (int x = 0; x < image.width; x += sampleRate) {
        final pixel = image.getPixel(x, y);
        final r = pixel.r.toInt();
        final g = pixel.g.toInt();
        final b = pixel.b.toInt();
        final luma = (0.299 * r + 0.587 * g + 0.114 * b).toInt();
        histogram[luma]++;
      }
    }
    cdf[0] = histogram[0];
    for (int i = 1; i < 256; i++) {
      cdf[i] = cdf[i - 1] + histogram[i];
    }
    final totalPixels = image.width * image.height;
    final equalized = img.Image(width: image.width, height: image.height);
    for (int y = 0; y < image.height; y++) {
      for (int x = 0; x < image.width; x++) {
        final pixel = image.getPixel(x, y);
        final r = pixel.r.toInt();
        final g = pixel.g.toInt();
        final b = pixel.b.toInt();
        final oldLuma = (0.299 * r + 0.587 * g + 0.114 * b).toInt();
        final newLuma = ((cdf[oldLuma] * 255) ~/ totalPixels).clamp(0, 255);
        equalized.setPixelRgba(x, y, newLuma, newLuma, newLuma, 255);
      }
    }
    return equalized;
  }

  static img.Image applyEdgeDetection(img.Image image) {
    final edges = img.Image(width: image.width, height: image.height);
    const sobelX = [
      [-1, 0, 1],
      [-2, 0, 2],
      [-1, 0, 1],
    ];
    const sobelY = [
      [-1, -2, -1],
      [0, 0, 0],
      [1, 2, 1],
    ];
    for (int y = 1; y < image.height - 1; y++) {
      for (int x = 1; x < image.width - 1; x++) {
        double gx = 0;
        double gy = 0;
        for (int ky = -1; ky <= 1; ky++) {
          for (int kx = -1; kx <= 1; kx++) {
            final pixel = image.getPixelSafe(x + kx, y + ky);
            final r = pixel.r.toInt();
            final g = pixel.g.toInt();
            final b = pixel.b.toInt();
            final luma = (0.299 * r + 0.587 * g + 0.114 * b).toInt();
            gx += luma * sobelX[ky + 1][kx + 1];
            gy += luma * sobelY[ky + 1][kx + 1];
          }
        }
        final edge = (sqrt(gx * gx + gy * gy)).toInt().clamp(0, 255);
        edges.setPixelRgba(x, y, edge, edge, edge, 255);
      }
    }
    return edges;
  }

  static img.Image applyBlur(img.Image image, {int radius = 5}) {
    return img.gaussianBlur(image, radius: radius);
  }

  static img.Image applySharpen(img.Image image) {
    const kernel = [
      [0, -1, 0],
      [-1, 5, -1],
      [0, -1, 0],
    ];
    final sharpened = img.Image(width: image.width, height: image.height);
    for (int y = 1; y < image.height - 1; y++) {
      for (int x = 1; x < image.width - 1; x++) {
        double r = 0, g = 0, b = 0;
        for (int ky = -1; ky <= 1; ky++) {
          for (int kx = -1; kx <= 1; kx++) {
            final pixel = image.getPixelSafe(x + kx, y + ky);
            final factor = kernel[ky + 1][kx + 1].toDouble();
            r += pixel.r * factor;
            g += pixel.g * factor;
            b += pixel.b * factor;
          }
        }
        r = r.clamp(0, 255);
        g = g.clamp(0, 255);
        b = b.clamp(0, 255);
        sharpened.setPixelRgba(x, y, r.toInt(), g.toInt(), b.toInt(), 255);
      }
    }
    return sharpened;
  }

  static img.Image applyHighpass(img.Image image) {
    const kernel = [
      [-1, -1, -1],
      [-1, 8, -1],
      [-1, -1, -1],
    ];
    final filtered = img.Image(width: image.width, height: image.height);
    for (int y = 1; y < image.height - 1; y++) {
      for (int x = 1; x < image.width - 1; x++) {
        double r = 0, g = 0, b = 0;
        for (int ky = -1; ky <= 1; ky++) {
          for (int kx = -1; kx <= 1; kx++) {
            final pixel = image.getPixelSafe(x + kx, y + ky);
            final factor = kernel[ky + 1][kx + 1].toDouble();
            r += pixel.r * factor;
            g += pixel.g * factor;
            b += pixel.b * factor;
          }
        }
        r = (r + 128).clamp(0, 255);
        g = (g + 128).clamp(0, 255);
        b = (b + 128).clamp(0, 255);
        filtered.setPixelRgba(x, y, r.toInt(), g.toInt(), b.toInt(), 255);
      }
    }
    return filtered;
  }

  static img.Image applyLowpass(img.Image image) {
    const kernel = [
      [1, 2, 1],
      [2, 4, 2],
      [1, 2, 1],
    ];
    const divisor = 16;
    final filtered = img.Image(width: image.width, height: image.height);
    for (int y = 1; y < image.height - 1; y++) {
      for (int x = 1; x < image.width - 1; x++) {
        double r = 0, g = 0, b = 0;
        for (int ky = -1; ky <= 1; ky++) {
          for (int kx = -1; kx <= 1; kx++) {
            final pixel = image.getPixelSafe(x + kx, y + ky);
            final factor = kernel[ky + 1][kx + 1].toDouble();
            r += pixel.r * factor;
            g += pixel.g * factor;
            b += pixel.b * factor;
          }
        }
        r = (r ~/ divisor).clamp(0, 255).toDouble();
        g = (g ~/ divisor).clamp(0, 255).toDouble();
        b = (b ~/ divisor).clamp(0, 255).toDouble();
        filtered.setPixelRgba(x, y, r.toInt(), g.toInt(), b.toInt(), 255);
      }
    }
    return filtered;
  }

  static img.Image addNoise(img.Image image) {
    final noisy = img.Image.from(image);

    final random = Random();
    const noiseDensity = 0.05;

    for (int y = 0; y < image.height; y++) {
      for (int x = 0; x < image.width; x++) {
        if (random.nextDouble() < noiseDensity) {
          final saltOrPepper = random.nextDouble() < 0.5 ? 255 : 0;
          noisy.setPixelRgba(
            x,
            y,
            saltOrPepper,
            saltOrPepper,
            saltOrPepper,
            255,
          );
        }
      }
    }
    return noisy;
  }

  static img.Image applyBrightness(img.Image image, double brightness) {
    final adjusted = img.Image(width: image.width, height: image.height);
    final brightnessOffset = (brightness * 255).toInt();
    for (int y = 0; y < image.height; y++) {
      for (int x = 0; x < image.width; x++) {
        final pixel = image.getPixel(x, y);
        final r = (pixel.r.toInt() + brightnessOffset).clamp(0, 255);
        final g = (pixel.g.toInt() + brightnessOffset).clamp(0, 255);
        final b = (pixel.b.toInt() + brightnessOffset).clamp(0, 255);
        adjusted.setPixelRgba(x, y, r, g, b, 255);
      }
    }
    return adjusted;
  }

  static img.Image applyContrast(img.Image image, double contrast) {
    final adjusted = img.Image(width: image.width, height: image.height);
    final offset = ((1 - contrast) / 2 * 255).toInt();
    for (int y = 0; y < image.height; y++) {
      for (int x = 0; x < image.width; x++) {
        final pixel = image.getPixel(x, y);
        final r = ((pixel.r.toInt() * contrast) + offset).clamp(0, 255).toInt();
        final g = ((pixel.g.toInt() * contrast) + offset).clamp(0, 255).toInt();
        final b = ((pixel.b.toInt() * contrast) + offset).clamp(0, 255).toInt();
        adjusted.setPixelRgba(x, y, r, g, b, 255);
      }
    }
    return adjusted;
  }

  static img.Image applyBrightnessAndContrast(
    img.Image image,
    double brightness,
    double contrast,
  ) {
    final adjusted = img.Image(width: image.width, height: image.height);
    final brightnessOffset = (brightness * 255).toInt();
    final contrastOffset = ((1 - contrast) / 2 * 255).toInt();
    for (int y = 0; y < image.height; y++) {
      for (int x = 0; x < image.width; x++) {
        final pixel = image.getPixel(x, y);
        final r =
            (((pixel.r.toInt() * contrast) + contrastOffset) + brightnessOffset)
                .clamp(0, 255)
                .toInt();
        final g =
            (((pixel.g.toInt() * contrast) + contrastOffset) + brightnessOffset)
                .clamp(0, 255)
                .toInt();
        final b =
            (((pixel.b.toInt() * contrast) + contrastOffset) + brightnessOffset)
                .clamp(0, 255)
                .toInt();
        adjusted.setPixelRgba(x, y, r, g, b, 255);
      }
    }
    return adjusted;
  }
}
