import 'package:camera/camera.dart' as cam;
import 'package:flutter/material.dart';
import 'package:logbook_app/main.dart' as app;
import 'package:logbook_app/features/vision/vision_controller.dart';
import 'package:logbook_app/services/coordinate_mapper.dart';
import 'package:logbook_app/services/detection_overlay_painter.dart';
import 'package:logbook_app/services/detection_model.dart';

class VisionPage extends StatefulWidget {
  const VisionPage({Key? key}) : super(key: key);
  @override
  State<VisionPage> createState() => _VisionPageState();
}

class _VisionPageState extends State<VisionPage> {
  late VisionController _visionController;
  List<DetectionResult> _detections = [];
  Rect? _targetArea;
  bool _showCrosshair = true;
  bool _showBoundingBox = true;
  bool _showInfoPanel = true;
  bool _useFlash = false;
  @override
  void initState() {
    super.initState();
    _visionController = VisionController(availableCameras: app.cameraRegistry);
    _visionController.addListener(_onVisionControllerChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setupTargetArea();
    });
  }

  void _onVisionControllerChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  void _setupTargetArea() {
    final screenSize = MediaQuery.of(context).size;
    const margin = 40.0;
    setState(() {
      _targetArea = Rect.fromLTWH(
        margin,
        screenSize.height / 4,
        screenSize.width - (2 * margin),
        screenSize.height / 2,
      );
    });
  }

  void _addDemoDetection() {
    setState(() {
      _detections.add(
        DetectionResult(
          left: 0.1,
          top: 0.2,
          width: 0.3,
          height: 0.4,
          confidence: 0.95,
          damageType: RoadDamageType.pothole,
        ),
      );
    });
  }

  void _clearDetections() {
    setState(() => _detections.clear());
  }

  void _toggleFlash() async {
    setState(() => _useFlash = !_useFlash);
    if (_visionController.controller != null) {
      await _visionController.controller!.setFlashMode(
        _useFlash ? cam.FlashMode.torch : cam.FlashMode.off,
      );
    }
  }

  void _toggleCrosshair() {
    setState(() => _showCrosshair = !_showCrosshair);
  }

  void _toggleInfoPanel() {
    setState(() => _showInfoPanel = !_showInfoPanel);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Digital Vision - Module 6'),
        elevation: 0,
        backgroundColor: Colors.black87,
      ),
      body: _buildBody(),
      bottomNavigationBar: _buildControlPanel(),
    );
  }

  Widget _buildBody() {
    if (_visionController.errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(_visionController.errorMessage!),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _visionController.resume(),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }
    if (!_visionController.isInitialized) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(_visionController.status),
          ],
        ),
      );
    }
    if (_visionController.controller == null) {
      return const Center(child: Text('Camera controller is null'));
    }
    return Stack(
      fit: StackFit.expand,
      children: [
        cam.CameraPreview(_visionController.controller!),
        Positioned.fill(
          child: CustomPaint(
            painter: DetectionOverlayPainter(
              detections: _detections,
              targetArea: _targetArea,
              fps: null,
              statusMessage: _detections.isEmpty
                  ? 'Scanning...'
                  : 'Detecting...',
              showBoundingBox: _showBoundingBox,
              showCrosshair: _showCrosshair,
              showInformationPanel: _showInfoPanel,
            ),
            isComplex: true,
            willChange: true,
          ),
        ),
        Positioned(
          top: 16,
          right: 16,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              FloatingActionButton.small(
                onPressed: _toggleFlash,
                backgroundColor: _useFlash ? Colors.amber : Colors.grey[700],
                child: Icon(
                  _useFlash ? Icons.flash_on : Icons.flash_off,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              FloatingActionButton.small(
                onPressed: _toggleCrosshair,
                backgroundColor: _showCrosshair
                    ? Colors.blue
                    : Colors.grey[700],
                child: const Icon(Icons.add, color: Colors.white),
              ),
              const SizedBox(height: 8),
              FloatingActionButton.small(
                onPressed: _toggleInfoPanel,
                backgroundColor: _showInfoPanel
                    ? Colors.cyan
                    : Colors.grey[700],
                child: const Icon(Icons.info, color: Colors.white),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildControlPanel() {
    return Container(
      color: Colors.black87,
      padding: const EdgeInsets.all(12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          ElevatedButton.icon(
            onPressed: _addDemoDetection,
            icon: const Icon(Icons.add),
            label: const Text('Add Detection'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
          ),
          ElevatedButton.icon(
            onPressed: _clearDetections,
            icon: const Icon(Icons.delete),
            label: const Text('Clear'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          ),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.blue,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'Detections: ${_detections.length}',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _visionController.removeListener(_onVisionControllerChanged);
    _visionController.dispose();
    super.dispose();
  }
}
