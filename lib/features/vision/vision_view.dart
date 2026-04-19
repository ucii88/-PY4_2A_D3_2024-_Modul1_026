import 'package:camera/camera.dart' as cam;
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:file_picker/file_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
import 'package:logbook_app/main.dart' as app;
import 'package:logbook_app/features/vision/vision_controller.dart';
import 'package:logbook_app/features/vision/damage_painter.dart';
import 'package:logbook_app/features/vision/mock_detector.dart';
import 'package:logbook_app/features/vision/pcd_panel.dart';
import 'package:logbook_app/features/vision/camera_frame_processor.dart';
import 'package:logbook_app/features/vision/photo_editor_screen.dart';
import 'package:logbook_app/features/vision/photo_filter_processor.dart';
import 'package:logbook_app/services/detection_model.dart';
import 'dart:async';

class VisionView extends StatefulWidget {
  const VisionView({super.key});
  @override
  State<VisionView> createState() => _VisionViewState();
}

class _VisionViewState extends State<VisionView> {
  late VisionController _visionController;
  late MockDetector _mockDetector;
  late Timer _detectionTimer;
  List<DetectionResult> _currentDetections = [];
  bool _torchOn = false;
  bool _showOverlay = true;
  double _brightnessValue = 0.0;
  double _contrastValue = 1.0;
  double _blurValue = 0.0;
  bool _grayscaleEnabled = false;
  bool _histogramEnabled = false;
  double _lumAverage = 128.0;
  int _frameCounter = 0;
  static const int _histogramUpdateInterval = 30;
  bool _isProcessingFrame = false;

  @override
  void initState() {
    super.initState();
    _requestCameraPermission();
    _visionController = VisionController(availableCameras: app.cameraRegistry);
    _mockDetector = MockDetector();
    _detectionTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (mounted && !_isProcessingFrame) {
        setState(() {
          _currentDetections = _mockDetector.generateBatch();
        });
      }
    });
    _currentDetections = _mockDetector.generateBatch();

    try {
      _visionController.controller?.startImageStream((cam.CameraImage image) {
        _frameCounter++;
        if (_frameCounter % _histogramUpdateInterval == 0 &&
            !_isProcessingFrame) {
          _isProcessingFrame = true;
          if (mounted) {
            final lum = CameraFrameProcessor.calculateAverageLuminance(image);
            setState(() => _lumAverage = lum);
          }
          _isProcessingFrame = false;
        }
      });
    } catch (e) {
      debugPrint(' [VisionView] Stream error: $e');
    }
  }

  @override
  void dispose() {
    _detectionTimer.cancel();
    debugPrint('  [VisionView] Mock detection timer cancelled');
    try {
      _visionController.controller?.stopImageStream();
      debugPrint('  [VisionView] Image stream stopped');
    } catch (e) {
      debugPrint(' [VisionView] Error stopping image stream: $e');
    }
    _visionController.dispose();
    debugPrint(
      ' [VisionView.dispose] VisionController disposed - Camera turned off',
    );
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: const Text('Smart-Patrol Vision'),
        elevation: 0,
        backgroundColor: const Color.fromARGB(255, 254, 166, 209),
      ),
      body: ListenableBuilder(
        listenable: _visionController,
        builder: (context, child) {
          if (!_visionController.isInitialized) {
            return _buildLoadingScreen();
          }
          if (_visionController.errorMessage != null) {
            if (_visionController.isPermissionDenied) {
              return _buildPermissionDeniedScreen();
            }
            return _buildErrorScreen();
          }
          return _buildVisionStack();
        },
      ),
    );
  }

  Widget _buildLoadingScreen() {
    return Container(
      color: Colors.black87,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 80,
                  height: 80,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Colors.cyan.withOpacity(0.8),
                    ),
                  ),
                ),
                Icon(
                  Icons.camera_alt,
                  size: 36,
                  color: Colors.cyan.withOpacity(0.8),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              _visionController.status,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.cyan.withOpacity(0.9),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Mohon tunggu sebentar...',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.grey[400]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPermissionDeniedScreen() {
    return Container(
      color: Colors.black87,
      child: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.lock_outline,
                size: 80,
                color: Colors.red.withOpacity(0.8),
              ),
              const SizedBox(height: 24),
              Text(
                'Akses Kamera Ditolak',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.red.withOpacity(0.9),
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  'Aplikasi ini memerlukan akses ke kamera untuk melakukan deteksi kerusakan jalan. Silakan aktifkan izin kamera di Pengaturan.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[300],
                    height: 1.5,
                  ),
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () => openAppSettings(),
                icon: const Icon(Icons.settings),
                label: const Text('Buka Pengaturan'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.cyan.withOpacity(0.8),
                  foregroundColor: Colors.black87,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: () => _visionController.resume(),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: Colors.grey[500]!),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                ),
                child: const Text('Coba Lagi'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorScreen() {
    return Container(
      color: Colors.black87,
      child: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 80,
                color: Colors.orange.withOpacity(0.8),
              ),
              const SizedBox(height: 24),
              Text(
                'Terjadi Kesalahan',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange.withOpacity(0.9),
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  _visionController.errorMessage ??
                      'Terjadi kesalahan yang tidak diketahui',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[300],
                    height: 1.5,
                  ),
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () {
                  _visionController.resume();
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Coba Lagi'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.cyan.withOpacity(0.8),
                  foregroundColor: Colors.black87,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVisionStack() {
    if (_visionController.controller == null) {
      return const Center(child: Text('Camera controller is null'));
    }
    return Stack(
      fit: StackFit.expand,
      children: [
        ColorFiltered(
          colorFilter: _buildColorFilter(),
          child: _buildCameraPreview(),
        ),
        if (_showOverlay)
          Positioned.fill(
            child: ClipRect(
              child: CustomPaint(
                painter: DamagePainter(
                  detections: _currentDetections,
                  targetArea: _buildTargetArea(),
                  fps: null,
                  statusMessage: _currentDetections.isEmpty
                      ? 'Scanning for road damage...'
                      : 'Detected: ${_currentDetections.length} defect(s)',
                  showBoundingBox: true,
                  showCrosshair: true,
                  showInformationPanel: true,
                ),
                isComplex: true,
                willChange: true,
              ),
            ),
          ),
        HistogramOverlay(enabled: _histogramEnabled, lumAverage: _lumAverage),
        Positioned(
          top: 16,
          right: 16,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _toggleTorch,
                    borderRadius: BorderRadius.circular(20),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _torchOn ? Icons.flash_on : Icons.flash_off,
                            color: _torchOn ? Colors.amber : Colors.grey[300],
                            size: 20,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _torchOn ? 'Torch ON' : 'Torch OFF',
                            style: TextStyle(
                              color: Colors.grey[300],
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _toggleOverlay,
                    borderRadius: BorderRadius.circular(20),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _showOverlay ? Icons.layers : Icons.layers_clear,
                            color: _showOverlay
                                ? Colors.cyan
                                : Colors.grey[300],
                            size: 20,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _showOverlay ? 'Overlay ON' : 'Overlay OFF',
                            style: TextStyle(
                              color: Colors.grey[300],
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => _showPCDPanel(),
                    borderRadius: BorderRadius.circular(20),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.tune,
                            color:
                                (_contrastValue != 1.0 ||
                                    _brightnessValue != 0.0 ||
                                    _blurValue != 0.0)
                                ? Colors.amber
                                : Colors.grey[300],
                            size: 20,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'PCD Panel',
                            style: TextStyle(
                              color: Colors.grey[300],
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
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
        ),
        Positioned(
          bottom: 70,
          left: 0,
          right: 0,
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: _uploadImageFromGallery,
                  child: Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.8),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blue.withValues(alpha: 0.5),
                          blurRadius: 8,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.image,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                ),
                const SizedBox(width: 20),
                GestureDetector(
                  onTap: _capturePhoto,
                  child: Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.9),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.red.withValues(alpha: 0.5),
                          blurRadius: 8,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.camera_alt,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        Positioned(
          bottom: 16,
          left: 0,
          right: 0,
          child: Center(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(20),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_circle, color: Colors.white, size: 16),
                  SizedBox(width: 6),
                  Text(
                    'Visual scan aktif',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Rect? _buildTargetArea() {
    final screenSize = MediaQuery.of(context).size;
    final appBarHeight = kToolbarHeight + MediaQuery.of(context).padding.top;
    final targetLeft = 0.0;
    final targetTop = appBarHeight;
    final targetWidth = screenSize.width;
    final targetHeight = screenSize.height - appBarHeight;
    return Rect.fromLTWH(targetLeft, targetTop, targetWidth, targetHeight);
  }

  Future<void> _toggleTorch() async {
    try {
      if (_visionController.controller == null) return;
      setState(() => _torchOn = !_torchOn);
      await _visionController.controller!.setFlashMode(
        _torchOn ? cam.FlashMode.torch : cam.FlashMode.off,
      );
      debugPrint(' [VisionView] Torch ${_torchOn ? 'ON' : 'OFF'}');
    } catch (e) {
      debugPrint(' [VisionView] Torch error: $e');
      if (mounted) {
        setState(() => _torchOn = !_torchOn);
      }
    }
  }

  void _toggleOverlay() {
    setState(() => _showOverlay = !_showOverlay);
    debugPrint(' [VisionView] Overlay ${_showOverlay ? 'ON' : 'OFF'}');
  }

  Future<void> _requestCameraPermission() async {
    final status = await Permission.camera.request();
    debugPrint(' [VisionView] Camera permission: $status');
  }

  Future<bool> _requestStoragePermission() async {
    final status = await Permission.storage.request();
    debugPrint(' [VisionView] Storage permission: $status');
    return status.isGranted;
  }

  Future<void> _uploadImageFromGallery() async {
    try {
      final hasPermission = await _requestStoragePermission();
      if (!hasPermission) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Storage permission denied')),
          );
        }
        return;
      }

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

        if (mounted) {
          debugPrint(' [VisionView] Image uploaded, navigating to editor');
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PhotoEditorScreen(photoBytes: imageBytes),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint(' [VisionView] Upload error: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Upload failed: $e')));
      }
    }
  }

  Future<void> _capturePhoto() async {
    try {
      if (_visionController.controller == null) {
        debugPrint(' [VisionView] Camera not initialized');
        return;
      }
      debugPrint('📸 [VisionView] Capturing photo...');
      final xFile = await _visionController.controller!.takePicture();
      var photoBytes = await xFile.readAsBytes();

      var processedImage = img.decodeImage(photoBytes);
      if (processedImage != null) {
        if (_grayscaleEnabled) {
          processedImage = PhotoFilterProcessor.applyGrayscale(processedImage);
          debugPrint(
            ' [VisionView] Grayscale filter applied to captured photo',
          );
        }

        if (_brightnessValue != 0.0 || _contrastValue != 1.0) {
          processedImage = PhotoFilterProcessor.applyBrightnessAndContrast(
            processedImage,
            _brightnessValue / 100.0,
            _contrastValue,
          );
          debugPrint(
            ' [VisionView] Brightness (${_brightnessValue.toStringAsFixed(1)}) and Contrast (${_contrastValue.toStringAsFixed(2)}) applied',
          );
        }

        photoBytes = img.encodePng(processedImage);
      }

      if (mounted) {
        debugPrint(
          ' [VisionView] Photo captured and processed, navigating to editor',
        );
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PhotoEditorScreen(photoBytes: photoBytes),
          ),
        );
      }
    } catch (e) {
      debugPrint(' [VisionView] Capture error: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Capture failed: $e')));
      }
    }
  }

  void _resetProcessing() {
    setState(() {
      _brightnessValue = 0.0;
      _contrastValue = 1.0;
      _blurValue = 0.0;
      _grayscaleEnabled = false;
      _histogramEnabled = false;
    });
    debugPrint('🔄 [VisionView] Processing reset to defaults');
  }

  Widget _buildCameraPreview() {
    return FittedBox(
      fit: BoxFit.cover,
      child: SizedBox(
        width: _visionController.controller!.value.previewSize?.height ?? 1,
        height: _visionController.controller!.value.previewSize?.width ?? 1,
        child: cam.CameraPreview(_visionController.controller!),
      ),
    );
  }

  ColorFilter _buildColorFilter() {
    List<double> matrix = [
      1,
      0,
      0,
      0,
      0,
      0,
      1,
      0,
      0,
      0,
      0,
      0,
      1,
      0,
      0,
      0,
      0,
      0,
      1,
      0,
    ];
    if (_grayscaleEnabled) {
      const r = 0.299;
      const g = 0.587;
      const b = 0.114;
      final contrast = _contrastValue;
      final brightness = _brightnessValue / 100.0;
      matrix = [
        r * contrast,
        g * contrast,
        b * contrast,
        0,
        (brightness * 255) + ((1 - contrast) / 2 * 255),
        r * contrast,
        g * contrast,
        b * contrast,
        0,
        (brightness * 255) + ((1 - contrast) / 2 * 255),
        r * contrast,
        g * contrast,
        b * contrast,
        0,
        (brightness * 255) + ((1 - contrast) / 2 * 255),
        0,
        0,
        0,
        1,
        0,
      ];
    } else {
      final contrast = _contrastValue;
      final contrastOffset = (1 - contrast) / 2;
      matrix[0] = contrast;
      matrix[6] = contrast;
      matrix[12] = contrast;
      matrix[4] = contrastOffset * 255;
      matrix[9] = contrastOffset * 255;
      matrix[14] = contrastOffset * 255;
      final brightness = _brightnessValue / 100.0;
      matrix[4] += brightness * 255;
      matrix[9] += brightness * 255;
      matrix[14] += brightness * 255;
    }
    return ColorFilter.matrix(matrix);
  }

  void _showPCDPanel() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setStateModal) {
            return PCDToolsPanel(
              contrastValue: _contrastValue,
              brightnessValue: _brightnessValue,
              blurValue: _blurValue,
              grayscaleEnabled: _grayscaleEnabled,
              histogramEnabled: _histogramEnabled,
              onContrastChanged: (value) {
                setState(() => _contrastValue = value);
                setStateModal(() {});
              },
              onBrightnessChanged: (value) {
                setState(() => _brightnessValue = value);
                setStateModal(() {});
              },
              onBlurChanged: (value) {
                setState(() => _blurValue = value);
                setStateModal(() {});
              },
              onGrayscaleChanged: (value) {
                setState(() => _grayscaleEnabled = value);
                setStateModal(() {});
              },
              onHistogramChanged: (value) {
                setState(() => _histogramEnabled = value);
                setStateModal(() {});
              },
              onReset: () {
                _resetProcessing();
                setStateModal(() {});
              },
            );
          },
        );
      },
      isScrollControlled: false,
      backgroundColor: Colors.transparent,
    );
  }
}
