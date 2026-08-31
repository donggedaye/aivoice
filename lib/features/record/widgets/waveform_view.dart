import 'package:flutter/material.dart';

/// 即時波形。每個值是一段 100 ms 音訊的 RMS（0..1）。
class WaveformView extends StatelessWidget {
  const WaveformView({
    super.key,
    required this.levels,
    required this.capacity,
  });

  final List<double> levels;
  final int capacity;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 120,
      child: CustomPaint(
        painter: _WaveformPainter(
          levels: levels,
          capacity: capacity,
          color: Theme.of(context).colorScheme.primary,
        ),
        size: Size.infinite,
      ),
    );
  }
}

class _WaveformPainter extends CustomPainter {
  _WaveformPainter({
    required this.levels,
    required this.capacity,
    required this.color,
  });

  final List<double> levels;
  final int capacity;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final middle = size.height / 2;
    final slot = size.width / capacity;
    final barWidth = slot * 0.6;

    final paint = Paint()
      ..color = color
      ..strokeWidth = barWidth
      ..strokeCap = StrokeCap.round;

    for (var i = 0; i < levels.length; i++) {
      // RMS 語音多半落在很小的區間，開根號後視覺上才有變化。
      final level = levels[i].clamp(0.0, 1.0);
      final height = (middle - 4) * _scale(level);
      final x = slot * (capacity - levels.length + i) + slot / 2;
      canvas.drawLine(
        Offset(x, middle - height),
        Offset(x, middle + height),
        paint,
      );
    }
  }

  double _scale(double rms) {
    final scaled = rms <= 0 ? 0.0 : (rms * 4).clamp(0.0, 1.0);
    return 0.04 + scaled * 0.96;
  }

  @override
  bool shouldRepaint(covariant _WaveformPainter oldDelegate) =>
      oldDelegate.levels != levels || oldDelegate.color != color;
}
