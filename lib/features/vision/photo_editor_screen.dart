import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:logbook_app/features/vision/photo_filter_processor.dart';

class PhotoEditorScreen extends StatefulWidget {
  final Uint8List photoBytes;
  const PhotoEditorScreen({super.key, required this.photoBytes});
  @override
  State<PhotoEditorScreen> createState() => _PhotoEditorScreenState();
}

class _PhotoEditorScreenState extends State<PhotoEditorScreen> {
  late img.Image originalImage;
  late img.Image currentImage;
  String _currentFilter = 'None';
  bool _isProcessing = false;
  double _brightnessValue = 0.0;
  double _contrastValue = 1.0;
  bool _showAdvancedControls = false;
  late List<int> _cachedHistogram;
  late double _cachedAvgLuma;

  static const Color primaryColor = Color.fromARGB(255, 254, 166, 209);
  static const Color accentColor = Color.fromARGB(255, 254, 166, 209);
  @override
  void initState() {
    super.initState();
    originalImage = img.decodeImage(widget.photoBytes)!;
    currentImage = img.Image.from(originalImage);
    _cachedHistogram = _calculateHistogram();
    _cachedAvgLuma = _calculateAverageLuminance();
  }

  @override
  void dispose() {
    originalImage = null as dynamic;
    currentImage = null as dynamic;
    _cachedHistogram.clear();
    super.dispose();
  }

  Future<void> _uploadImage() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = File(result.files.first.path!);
        final fileSize = await file.length();

        if (fileSize > 50 * 1024 * 1024) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Image too large (>50MB)')),
            );
          }
          return;
        }

        final imageBytes = await file.readAsBytes();
        final decodedImage = img.decodeImage(imageBytes);

        if (decodedImage != null && mounted) {
          if ((decodedImage.width * decodedImage.height) > 5000000) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Image resolution too high (>5MP)')),
            );
            return;
          }

          setState(() {
            originalImage = decodedImage;
            currentImage = img.Image.from(originalImage);
            _currentFilter = 'None';
            _brightnessValue = 0.0;
            _contrastValue = 1.0;
            _cachedHistogram = _calculateHistogram();
            _cachedAvgLuma = _calculateAverageLuminance();
          });
        }
      }
    } catch (e) {
      debugPrint('❌ [PhotoEditor] Upload error: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Upload failed: $e')));
      }
    }
  }

  void _updateBrightnessAndContrast() {
    if (mounted && !_isProcessing) {
      setState(() {
        currentImage = img.Image.from(originalImage);
        if (_brightnessValue != 0.0 || _contrastValue != 1.0) {
          currentImage = PhotoFilterProcessor.applyBrightnessAndContrast(
            currentImage,
            _brightnessValue / 100.0,
            _contrastValue,
          );
        }
        _cachedHistogram = _calculateHistogram();
        _cachedAvgLuma = _calculateAverageLuminance();
      });
    }
  }

  Future<void> _applyFilter(String filterName) async {
    setState(() => _isProcessing = true);
    await Future.delayed(const Duration(milliseconds: 100));
    try {
      img.Image filtered;
      switch (filterName) {
        case 'Grayscale':
          filtered = PhotoFilterProcessor.applyGrayscale(currentImage);
          break;
        case 'Equalize':
          filtered = PhotoFilterProcessor.applyEqualize(currentImage);
          break;
        case 'Edge':
          filtered = PhotoFilterProcessor.applyEdgeDetection(currentImage);
          break;
        case 'Noise':
          filtered = PhotoFilterProcessor.addNoise(currentImage);
          break;
        case 'Sharpen':
          filtered = PhotoFilterProcessor.applySharpen(currentImage);
          break;
        case 'Highpass':
          filtered = PhotoFilterProcessor.applyHighpass(currentImage);
          break;
        case 'Lowpass':
          filtered = PhotoFilterProcessor.applyLowpass(currentImage);
          break;
        case 'Blur':
          filtered = PhotoFilterProcessor.applyBlur(currentImage, radius: 5);
          break;
        default:
          filtered = img.Image.from(currentImage);
      }
      if (mounted) {
        setState(() {
          currentImage = filtered;
          _currentFilter = filterName;
          _isProcessing = false;
          _cachedHistogram = _calculateHistogram();
          _cachedAvgLuma = _calculateAverageLuminance();
        });
      }
    } catch (e) {
      debugPrint(' [PhotoEditor] Filter error: $e');
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  void _resetFilter() {
    setState(() {
      currentImage = img.Image.from(originalImage);
      _currentFilter = 'None';
      _brightnessValue = 0.0;
      _contrastValue = 1.0;
      _cachedHistogram = _calculateHistogram();
      _cachedAvgLuma = _calculateAverageLuminance();
    });
  }

  List<int> _calculateHistogram() {
    final histogram = List<int>.filled(256, 0);
    for (int y = 0; y < currentImage.height; y++) {
      for (int x = 0; x < currentImage.width; x++) {
        final pixel = currentImage.getPixel(x, y);
        final r = pixel.r.toInt();
        final g = pixel.g.toInt();
        final b = pixel.b.toInt();
        final luma = (0.299 * r + 0.587 * g + 0.114 * b).toInt();
        histogram[luma]++;
      }
    }
    return histogram;
  }

  double _calculateAverageLuminance() {
    int sum = 0;
    for (int y = 0; y < currentImage.height; y++) {
      for (int x = 0; x < currentImage.width; x++) {
        final pixel = currentImage.getPixel(x, y);
        final r = pixel.r.toInt();
        final g = pixel.g.toInt();
        final b = pixel.b.toInt();
        final luma = (0.299 * r + 0.587 * g + 0.114 * b).toInt();
        sum += luma;
      }
    }
    return sum / (currentImage.width * currentImage.height);
  }

  @override
  Widget build(BuildContext context) {
    final histogram = _cachedHistogram;
    final avgLuma = _cachedAvgLuma;
    final maxHistogram = histogram.isNotEmpty
        ? histogram.reduce((a, b) => a > b ? a : b)
        : 1;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Photo Studio'),
        backgroundColor: primaryColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton(
            onPressed: _resetFilter,
            child: const Text(
              'Reset',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            flex: 3,
            child: Container(
              color: Colors.grey[100],
              child: Center(
                child: _isProcessing
                    ? const CircularProgressIndicator(color: primaryColor)
                    : Image.memory(
                        img.encodePng(currentImage),
                        fit: BoxFit.cover,
                      ),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Histogram',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    Text(
                      'Luma avg: ${avgLuma.toStringAsFixed(1)}',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  height: 70,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!, width: 1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: CustomPaint(
                    painter: HistogramPainter(histogram, maxHistogram),
                    size: Size.infinite,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Active Filter: $_currentFilter',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Container(
              color: Colors.white,
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GestureDetector(
                        onTap: () {
                          setState(
                            () =>
                                _showAdvancedControls = !_showAdvancedControls,
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: accentColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: accentColor.withOpacity(0.3),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Advanced Controls',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                              ),
                              Icon(
                                _showAdvancedControls
                                    ? Icons.expand_less
                                    : Icons.expand_more,
                                color: accentColor,
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (_showAdvancedControls) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey[300]!),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Brightness',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  Text(
                                    _brightnessValue.toStringAsFixed(0),
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: accentColor,
                                    ),
                                  ),
                                ],
                              ),
                              Slider(
                                value: _brightnessValue,
                                onChanged: (value) {
                                  setState(() => _brightnessValue = value);
                                },
                                onChangeEnd: (value) {
                                  _updateBrightnessAndContrast();
                                },
                                min: -100,
                                max: 100,
                                divisions: 200,
                                activeColor: accentColor,
                                inactiveColor: Colors.grey[300],
                              ),
                              const SizedBox(height: 16),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Contrast',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  Text(
                                    _contrastValue.toStringAsFixed(2),
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: accentColor,
                                    ),
                                  ),
                                ],
                              ),
                              Slider(
                                value: _contrastValue,
                                onChanged: (value) {
                                  setState(() => _contrastValue = value);
                                },
                                onChangeEnd: (value) {
                                  _updateBrightnessAndContrast();
                                },
                                min: 0.5,
                                max: 3.0,
                                divisions: 50,
                                activeColor: accentColor,
                                inactiveColor: Colors.grey[300],
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),
                      const Text(
                        'Filters',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 12),
                      GridView.count(
                        crossAxisCount: 4,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        mainAxisSpacing: 6,
                        crossAxisSpacing: 6,
                        childAspectRatio: 2.5,
                        children: [
                          _buildFilterButton('Grayscale'),
                          _buildFilterButton('Noise'),
                          _buildFilterButton('Equalize'),
                          _buildFilterButton('Edge'),
                          _buildFilterButton('Sharpen'),
                          _buildFilterButton('Highpass'),
                          _buildFilterButton('Lowpass'),
                          _buildFilterButton('Blur'),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _uploadImage,
                          icon: const Icon(Icons.upload_file),
                          label: const Text('Upload Gambar'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterButton(String filterName) {
    final isActive = _currentFilter == filterName;
    return ElevatedButton(
      onPressed: _isProcessing ? null : () => _applyFilter(filterName),
      style: ElevatedButton.styleFrom(
        backgroundColor: isActive ? accentColor : Colors.grey[200],
        foregroundColor: isActive ? Colors.white : Colors.black87,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        elevation: isActive ? 3 : 0,
      ),
      child: Text(
        filterName,
        style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w500),
      ),
    );
  }
}

class HistogramPainter extends CustomPainter {
  final List<int> histogram;
  final int maxValue;
  HistogramPainter(this.histogram, this.maxValue);
  @override
  void paint(Canvas canvas, Size size) {
    const barCount = 64;
    final barWidth = size.width / barCount;
    final paint = Paint()
      ..color = const Color.fromARGB(255, 254, 166, 209).withOpacity(0.7)
      ..style = PaintingStyle.fill;
    for (int i = 0; i < barCount; i++) {
      final start = (i * histogram.length) ~/ barCount;
      final end = ((i + 1) * histogram.length) ~/ barCount;
      int sum = 0;
      for (int j = start; j < end; j++) {
        sum += histogram[j];
      }
      final avgBucketValue = (sum ~/ (end - start)).toDouble();
      final barHeight = (avgBucketValue / maxValue) * size.height;
      canvas.drawRect(
        Rect.fromLTWH(
          i * barWidth,
          size.height - barHeight,
          barWidth - 1,
          barHeight,
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
