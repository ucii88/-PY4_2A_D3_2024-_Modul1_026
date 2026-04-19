import 'package:flutter/material.dart';

class PCDToolsPanel extends StatefulWidget {
  final double contrastValue;
  final double brightnessValue;
  final double blurValue;
  final bool grayscaleEnabled;
  final bool histogramEnabled;
  final Function(double) onContrastChanged;
  final Function(double) onBrightnessChanged;
  final Function(double) onBlurChanged;
  final Function(bool) onGrayscaleChanged;
  final Function(bool) onHistogramChanged;
  final VoidCallback onReset;
  const PCDToolsPanel({
    super.key,
    required this.contrastValue,
    required this.brightnessValue,
    required this.blurValue,
    required this.grayscaleEnabled,
    required this.histogramEnabled,
    required this.onContrastChanged,
    required this.onBrightnessChanged,
    required this.onBlurChanged,
    required this.onGrayscaleChanged,
    required this.onHistogramChanged,
    required this.onReset,
  });
  @override
  State<PCDToolsPanel> createState() => _PCDToolsPanelState();
}

class _PCDToolsPanelState extends State<PCDToolsPanel> {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.9),
        border: Border(
          top: BorderSide(color: Colors.white.withValues(alpha: 0.1), width: 1),
        ),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.build_circle, color: Colors.white70),
                      const SizedBox(width: 8),
                      const Text(
                        'PCD Tools',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  ElevatedButton(
                    onPressed: widget.onReset,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade700,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                    ),
                    child: const Text('Reset', style: TextStyle(fontSize: 11)),
                  ),
                ],
              ),
            ),
            const Divider(color: Colors.white10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () =>
                          widget.onGrayscaleChanged(!widget.grayscaleEnabled),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: widget.grayscaleEnabled
                            ? Colors.white
                            : Colors.grey.shade700,
                        foregroundColor: widget.grayscaleEnabled
                            ? Colors.black
                            : Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                      child: const Text(
                        'Grayscale',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () =>
                          widget.onHistogramChanged(!widget.histogramEnabled),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: widget.histogramEnabled
                            ? const Color.fromARGB(255, 254, 166, 209)
                            : Colors.grey.shade700,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (widget.histogramEnabled)
                            const Icon(Icons.check, size: 14),
                          if (widget.histogramEnabled) const SizedBox(width: 4),
                          const Text(
                            'Histogram',
                            style: TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Column(
                children: [
                  _buildSlider(
                    label: 'Contrast',
                    value: widget.contrastValue,
                    min: 0.5,
                    max: 2.0,
                    onChanged: widget.onContrastChanged,
                  ),
                  const SizedBox(height: 12),
                  _buildSlider(
                    label: 'Brightness',
                    value: widget.brightnessValue,
                    min: -50,
                    max: 50,
                    onChanged: widget.onBrightnessChanged,
                  ),
                  const SizedBox(height: 12),
                  _buildSlider(
                    label: 'Convolution Blur',
                    value: widget.blurValue,
                    min: 0.0,
                    max: 5.0,
                    onChanged: widget.onBlurChanged,
                  ),
                ],
              ),
            ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black26,
                border: Border(
                  top: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.camera, size: 14, color: Colors.white60),
                  const SizedBox(width: 6),
                  const Text(
                    'PCD: Natural • Exposure: Normal',
                    style: TextStyle(color: Colors.white60, fontSize: 11),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSlider({
    required String label,
    required double value,
    required double min,
    required double max,
    required Function(double) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              value.toStringAsFixed(2),
              style: const TextStyle(color: Colors.white70, fontSize: 11),
            ),
          ],
        ),
        const SizedBox(height: 6),
        SliderTheme(
          data: SliderThemeData(
            activeTrackColor: Colors.pink.shade300,
            inactiveTrackColor: Colors.grey.shade700,
            thumbColor: Colors.pink.shade300,
            overlayColor: Colors.pink.withValues(alpha: 0.2),
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
            trackHeight: 3,
          ),
          child: Slider(value: value, min: min, max: max, onChanged: onChanged),
        ),
      ],
    );
  }
}

class HistogramOverlay extends StatelessWidget {
  final bool enabled;
  final double lumAverage;
  const HistogramOverlay({
    super.key,
    required this.enabled,
    required this.lumAverage,
  });
  @override
  Widget build(BuildContext context) {
    if (!enabled) return const SizedBox.shrink();
    return Positioned(
      top: 16,
      left: 16,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white24, width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Histogram',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            SizedBox(
              width: 120,
              height: 40,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  for (int i = 0; i < 12; i++)
                    Expanded(
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 1),
                        height:
                            (30 * (lumAverage / 255.0) * (0.5 + (i / 12) * 0.5))
                                .clamp(3, 30)
                                .toDouble(),
                        decoration: BoxDecoration(
                          color: Colors.amber.withValues(
                            alpha: 0.4 + (lumAverage / 255.0) * 0.6,
                          ),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Luma avg: ${lumAverage.toStringAsFixed(0)}',
              style: const TextStyle(color: Colors.white70, fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }
}
