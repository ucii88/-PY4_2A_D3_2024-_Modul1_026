import 'dart:math';

class ImageProcessor {
  static List<int> adjustBrightness(List<int> pixels, double value) {
    final result = <int>[];
    for (int i = 0; i < pixels.length; i += 4) {
      final a = pixels[i];
      final r = (pixels[i + 1] + value).clamp(0, 255).toInt();
      final g = (pixels[i + 2] + value).clamp(0, 255).toInt();
      final b = (pixels[i + 3] + value).clamp(0, 255).toInt();
      result.addAll([a, r, g, b]);
    }
    return result;
  }

  static List<int> adjustContrast(List<int> pixels, double factor) {
    final result = <int>[];
    for (int i = 0; i < pixels.length; i += 4) {
      final a = pixels[i];
      final r = (((pixels[i + 1] - 128) * factor) + 128).clamp(0, 255).toInt();
      final g = (((pixels[i + 2] - 128) * factor) + 128).clamp(0, 255).toInt();
      final b = (((pixels[i + 3] - 128) * factor) + 128).clamp(0, 255).toInt();
      result.addAll([a, r, g, b]);
    }
    return result;
  }

  static List<int> adjustSaturation(List<int> pixels, double factor) {
    final result = <int>[];
    for (int i = 0; i < pixels.length; i += 4) {
      final a = pixels[i];
      final r = pixels[i + 1].toDouble();
      final g = pixels[i + 2].toDouble();
      final b = pixels[i + 3].toDouble();
      final max = [r, g, b].reduce((a, b) => a > b ? a : b);
      final min = [r, g, b].reduce((a, b) => a < b ? a : b);
      final delta = max - min;
      var h = 0.0, s = 0.0, v = max / 255;
      if (max != 0) {
        s = delta / max;
      }
      if (delta != 0) {
        if (max == r) {
          h = ((g - b) / delta) % 6;
        } else if (max == g) {
          h = ((b - r) / delta) + 2;
        } else {
          h = ((r - g) / delta) + 4;
        }
        h /= 6;
      }
      s = (s * factor).clamp(0, 1);
      final c = v * s;
      final x = c * (1 - ((h * 6) % 2 - 1).abs());
      final m = v - c;
      double rp = 0, gp = 0, bp = 0;
      if (h < 1 / 6) {
        rp = c;
        gp = x;
      } else if (h < 2 / 6) {
        rp = x;
        gp = c;
      } else if (h < 3 / 6) {
        gp = c;
        bp = x;
      } else if (h < 4 / 6) {
        gp = x;
        bp = c;
      } else if (h < 5 / 6) {
        rp = x;
        bp = c;
      } else {
        rp = c;
        bp = x;
      }
      final newR = ((rp + m) * 255).clamp(0, 255).toInt();
      final newG = ((gp + m) * 255).clamp(0, 255).toInt();
      final newB = ((bp + m) * 255).clamp(0, 255).toInt();
      result.addAll([a, newR, newG, newB]);
    }
    return result;
  }

  static List<int> applyBlur(List<int> pixels, int width, int height) {
    const kernel = [
      1, 2, 1, //
      2, 4, 2, //
      1, 2, 1, //
    ];
    const kernelSum = 16;
    return _applyConvolution(pixels, width, height, kernel, kernelSum);
  }

  static List<int> applySharpen(List<int> pixels, int width, int height) {
    const kernel = [
      0, -1, 0, //
      -1, 5, -1, //
      0, -1, 0, //
    ];
    const kernelSum = 1;
    return _applyConvolution(pixels, width, height, kernel, kernelSum);
  }

  static List<int> applyEdgeDetection(List<int> pixels, int width, int height) {
    const kernel = [
      -1, 0, 1, //
      -2, 0, 2, //
      -1, 0, 1, //
    ];
    const kernelSum = 1;
    return _applyConvolution(pixels, width, height, kernel, kernelSum);
  }

  static List<int> applyEmboss(List<int> pixels, int width, int height) {
    const kernel = [
      -2, -1, 0, //
      -1, 1, 1, //
      0, 1, 2, //
    ];
    const kernelSum = 1;
    return _applyConvolution(pixels, width, height, kernel, kernelSum);
  }

  static List<int> _applyConvolution(
    List<int> pixels,
    int width,
    int height,
    List<int> kernel,
    int kernelSum,
  ) {
    final result = List<int>.from(pixels);
    const kernelSize = 3;
    const kernelRadius = 1;
    for (int y = kernelRadius; y < height - kernelRadius; y++) {
      for (int x = kernelRadius; x < width - kernelRadius; x++) {
        var sumR = 0, sumG = 0, sumB = 0;
        for (int ky = -kernelRadius; ky <= kernelRadius; ky++) {
          for (int kx = -kernelRadius; kx <= kernelRadius; kx++) {
            final pixelIndex = ((y + ky) * width + (x + kx)) * 4;
            final kernelIndex =
                (ky + kernelRadius) * kernelSize + (kx + kernelRadius);
            sumR += result[pixelIndex + 1] * kernel[kernelIndex];
            sumG += result[pixelIndex + 2] * kernel[kernelIndex];
            sumB += result[pixelIndex + 3] * kernel[kernelIndex];
          }
        }
        final outIndex = (y * width + x) * 4;
        result[outIndex + 1] = (sumR / kernelSum).clamp(0, 255).toInt();
        result[outIndex + 2] = (sumG / kernelSum).clamp(0, 255).toInt();
        result[outIndex + 3] = (sumB / kernelSum).clamp(0, 255).toInt();
      }
    }
    return result;
  }

  static HistogramData calculateHistogram(List<int> pixels) {
    final histogramR = List<int>.filled(256, 0);
    final histogramG = List<int>.filled(256, 0);
    final histogramB = List<int>.filled(256, 0);
    for (int i = 0; i < pixels.length; i += 4) {
      histogramR[pixels[i + 1]]++;
      histogramG[pixels[i + 2]]++;
      histogramB[pixels[i + 3]]++;
    }
    final totalPixels = pixels.length ~/ 4;
    var meanR = 0.0, meanG = 0.0, meanB = 0.0;
    for (int i = 0; i < 256; i++) {
      meanR += i * histogramR[i];
      meanG += i * histogramG[i];
      meanB += i * histogramB[i];
    }
    meanR /= totalPixels;
    meanG /= totalPixels;
    meanB /= totalPixels;
    var varR = 0.0, varG = 0.0, varB = 0.0;
    for (int i = 0; i < 256; i++) {
      varR += (i - meanR) * (i - meanR) * histogramR[i];
      varG += (i - meanG) * (i - meanG) * histogramG[i];
      varB += (i - meanB) * (i - meanB) * histogramB[i];
    }
    final stdR = sqrt(varR / totalPixels);
    final stdG = sqrt(varG / totalPixels);
    final stdB = sqrt(varB / totalPixels);
    return HistogramData(
      histogramR: histogramR,
      histogramG: histogramG,
      histogramB: histogramB,
      meanR: meanR.toStringAsFixed(1),
      meanG: meanG.toStringAsFixed(1),
      meanB: meanB.toStringAsFixed(1),
      stdR: stdR.toStringAsFixed(1),
      stdG: stdG.toStringAsFixed(1),
      stdB: stdB.toStringAsFixed(1),
    );
  }

  static List<int> histogramEqualization(List<int> pixels) {
    final histogram = calculateHistogram(pixels);
    final cdfR = _calculateCDF(histogram.histogramR);
    final cdfG = _calculateCDF(histogram.histogramG);
    final cdfB = _calculateCDF(histogram.histogramB);
    final result = <int>[];
    for (int i = 0; i < pixels.length; i += 4) {
      result.add(pixels[i]);
      result.add(cdfR[pixels[i + 1]]);
      result.add(cdfG[pixels[i + 2]]);
      result.add(cdfB[pixels[i + 3]]);
    }
    return result;
  }

  static List<int> _calculateCDF(List<int> histogram) {
    final cdf = <int>[0];
    var sum = 0;
    final totalPixels = histogram.reduce((a, b) => a + b);
    for (int i = 1; i < histogram.length; i++) {
      sum += histogram[i - 1];
      final normalized = ((sum / totalPixels) * 255).round();
      cdf.add(normalized.clamp(0, 255).toInt());
    }
    return cdf;
  }
}

class HistogramData {
  final List<int> histogramR;
  final List<int> histogramG;
  final List<int> histogramB;
  final String meanR;
  final String meanG;
  final String meanB;
  final String stdR;
  final String stdG;
  final String stdB;
  HistogramData({
    required this.histogramR,
    required this.histogramG,
    required this.histogramB,
    required this.meanR,
    required this.meanG,
    required this.meanB,
    required this.stdR,
    required this.stdG,
    required this.stdB,
  });
}

enum FilterType {
  none('Tidak Ada'),
  brightness('Brightness'),
  contrast('Contrast'),
  saturation('Saturation'),
  blur('Blur'),
  sharpen('Sharpen'),
  edgeDetection('Edge Detection'),
  emboss('Emboss'),
  histogramEq('Histogram Eq');

  final String label;
  const FilterType(this.label);
}
