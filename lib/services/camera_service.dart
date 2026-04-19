import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class CameraService {
  CameraController? _controller;

  CameraController? get controller => _controller;

  bool get isInitialized => _controller?.value.isInitialized ?? false;

  bool get isRecording => _controller?.value.isRecordingVideo ?? false;

  Future<bool> initializeCamera({
    CameraLensDirection lensDirection = CameraLensDirection.back,
    ResolutionPreset resolution = ResolutionPreset.medium,
  }) async {
    try {
      final PermissionStatus cameraStatus = await Permission.camera.request();
      final PermissionStatus audioStatus = await Permission.microphone
          .request();

      if (!cameraStatus.isGranted || !audioStatus.isGranted) {
        debugPrint(' Camera/Audio permission denied');
        return false;
      }

      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        debugPrint(' Tidak ada kamera tersedia di perangkat ini');
        return false;
      }

      final CameraDescription camera = cameras.firstWhere(
        (cam) => cam.lensDirection == lensDirection,
        orElse: () => cameras.first,
      );

      _controller = CameraController(
        camera,
        resolution,
        enableAudio: true,
        imageFormatGroup: ImageFormatGroup.nv21,
      );

      await _controller!.initialize();

      debugPrint(' Kamera berhasil diinisialisasi');
      return true;
    } catch (e) {
      debugPrint(' Error inisialisasi kamera: $e');
      return false;
    }
  }

  Future<void> startImageStream(
    Future<dynamic> Function(CameraImage) onImageAvailable,
  ) async {
    if (!isInitialized) {
      debugPrint(' Kamera belum diinisialisasi');
      return;
    }

    try {
      await _controller?.startImageStream(onImageAvailable);
      debugPrint(' Image stream dimulai');
    } catch (e) {
      debugPrint(' Error memulai image stream: $e');
    }
  }

  Future<void> stopImageStream() async {
    if (_controller?.value.isStreamingImages ?? false) {
      try {
        await _controller?.stopImageStream();
        debugPrint(' Image stream dihentikan');
      } catch (e) {
        debugPrint(' Error menghentikan image stream: $e');
      }
    }
  }

  Future<void> setFlashMode(FlashMode mode) async {
    if (!isInitialized) return;
    try {
      await _controller?.setFlashMode(mode);
    } catch (e) {
      debugPrint(' Error mengatur flash: $e');
    }
  }

  Future<void> setExposureOffset(double offset) async {
    if (!isInitialized) return;
    try {
      final double clampedOffset = offset.clamp(-4.0, 4.0);
      await _controller!.setExposureOffset(clampedOffset);
    } catch (e) {
      debugPrint(' Error mengatur exposure: $e');
    }
  }

  /// Zoom in/out untuk investigasi detail kerusakan
  Future<void> setZoomLevel(double zoomLevel) async {
    if (!isInitialized) return;
    try {
      await _controller?.setZoomLevel(zoomLevel);
    } catch (e) {
      debugPrint(' Error mengatur zoom: $e');
    }
  }

  Future<void> dispose() async {
    try {
      await stopImageStream();

      if (_controller != null) {
        await _controller!.dispose();
        _controller = null;
      }

      debugPrint(' Camera Service disposed');
    } catch (e) {
      debugPrint(' Error saat dispose: $e');
    }
  }

  Future<bool> resume() async {
    if (isInitialized) {
      return true;
    }
    return await initializeCamera();
  }

  Future<void> pause() async {
    try {
      await stopImageStream();
      debugPrint(' Camera Service paused');
    } catch (e) {
      debugPrint(' Error saat pause: $e');
    }
  }
}
