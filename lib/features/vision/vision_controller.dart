import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

class VisionController extends ChangeNotifier with WidgetsBindingObserver {
  CameraController? controller;
  bool isInitialized = false;
  bool isPaused = false;
  String? errorMessage;
  bool isPermissionDenied = false;
  String _loadingMessage = 'Menghubungkan ke Sensor Visual...';
  final List<CameraDescription> availableCameras;

  VisionController({required this.availableCameras}) {
    WidgetsBinding.instance.addObserver(this);
    initCamera();
  }

  Future<void> initCamera() async {
    try {
      _loadingMessage = 'Menghubungkan ke Sensor Visual...';
      notifyListeners();
      debugPrint('📷 [VisionController] Initializing camera...');
      if (availableCameras.isEmpty) {
        isPermissionDenied = true;
        _setError('Kamera tidak ditemukan pada perangkat');
        return;
      }

      final cameraDescription = availableCameras.firstWhere(
        (cam) => cam.lensDirection == CameraLensDirection.back,
        orElse: () => availableCameras.first,
      );

      debugPrint(
        ' [VisionController] Selected camera: ${cameraDescription.lensDirection}, Sensor: ${cameraDescription.sensorOrientation}°',
      );

      _loadingMessage = 'Inisialisasi Sensor...';
      notifyListeners();

      controller = CameraController(
        cameraDescription,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.nv21,
      );

      await controller!.initialize();

      isInitialized = true;
      isPaused = false;
      errorMessage = null;
      isPermissionDenied = false;

      debugPrint(' [VisionController] Camera initialized successfully');
      notifyListeners();
    } catch (e) {
      final errorMsg = e.toString();
      if (errorMsg.contains('permission') || errorMsg.contains('Permission')) {
        isPermissionDenied = true;
        _setError('Akses Kamera Ditolak');
      } else {
        isPermissionDenied = false;
        _setError('Gagal inisialisasi kamera: $e');
      }
      debugPrint(' [VisionController] Camera init error: $e');
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final CameraController? cameraController = controller;

    debugPrint('📱 [VisionController] AppLifecycleState changed to: $state');

    if (cameraController == null || !cameraController.value.isInitialized) {
      debugPrint(
        ' [VisionController] Controller not ready (null or not initialized)',
      );
      return;
    }

    switch (state) {
      case AppLifecycleState.paused:
        debugPrint('  [VisionController] Pausing camera (app paused)');
        _pauseCamera();
        break;

      case AppLifecycleState.resumed:
        debugPrint('  [VisionController] Resuming camera (app resumed)');
        _resumeCamera();
        break;

      case AppLifecycleState.inactive:
        debugPrint(' [VisionController] App inactive (intermediate state)');
        break;

      case AppLifecycleState.detached:
        debugPrint(' [VisionController] App detached (closing)');
        break;

      case AppLifecycleState.hidden:
        debugPrint(' [VisionController] App hidden');
        break;
    }
  }

  void _pauseCamera() {
    if (isPaused) return;

    try {
      if (controller?.value.isStreamingImages ?? false) {
        controller!
            .stopImageStream()
            .then((_) {
              isPaused = true;
              debugPrint(' [VisionController] Camera stream stopped');
            })
            .catchError((e) {
              debugPrint(' [VisionController] Error stopping stream: $e');
            });
      } else {
        isPaused = true;
      }
      notifyListeners();
    } catch (e) {
      debugPrint(' [VisionController] Pause error: $e');
    }
  }

  void _resumeCamera() {
    if (!isPaused || !isInitialized) return;

    try {
      if (controller == null || !controller!.value.isInitialized) {
        debugPrint(' [VisionController] Controller disposed, re-initializing');
        initCamera();
      } else {
        isPaused = false;
        debugPrint(' [VisionController] Camera resumed');
        notifyListeners();
      }
    } catch (e) {
      debugPrint(' [VisionController] Resume error: $e');
    }
  }

  @override
  Future<void> dispose() async {
    debugPrint('  [VisionController] Disposing...');

    try {
      WidgetsBinding.instance.removeObserver(this);
      debugPrint(' [VisionController] Observer removed');

      if (controller?.value.isStreamingImages ?? false) {
        try {
          await controller!.stopImageStream();
          debugPrint(' [VisionController] Image stream stopped');
        } catch (e) {
          debugPrint(' [VisionController] Error stopping stream: $e');
        }
      }

      if (controller != null) {
        await controller!.dispose();
        debugPrint(' [VisionController] CameraController disposed');
      }

      controller = null;
      isInitialized = false;
      isPaused = false;
      errorMessage = null;

      debugPrint(' [VisionController] Dispose complete');
    } catch (e) {
      debugPrint(' [VisionController] Dispose error: $e');
    }

    super.dispose();
  }

  void _setError(String message) {
    errorMessage = message;
    isInitialized = false;
    notifyListeners();
  }

  void pause() {
    _pauseCamera();
  }

  void resume() {
    if (errorMessage != null || !isInitialized) {
      // If there's an error, reinitialize
      errorMessage = null;
      isPermissionDenied = false;
      initCamera();
    } else {
      _resumeCamera();
    }
  }

  String get status {
    if (errorMessage != null) return errorMessage!;
    if (!isInitialized) return _loadingMessage;
    if (isPaused) return 'Paused';
    return 'Running';
  }
}
