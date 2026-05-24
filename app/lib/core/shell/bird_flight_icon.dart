import 'package:flutter/material.dart';

class BirdFlightIcon extends StatelessWidget {
  const BirdFlightIcon({super.key, required this.color});
  final Color color;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(24, 24),
      painter: _BirdFlightPainter(color),
    );
  }
}

class _BirdFlightPainter extends CustomPainter {
  const _BirdFlightPainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final cx = size.width / 2;
    final cy = size.height / 2;

    // Left wing: curves up-left from body centre
    final leftPath = Path()
      ..moveTo(cx, cy)
      ..cubicTo(cx - 4, cy - 2, cx - 8, cy - 6, cx - 11, cy - 4);
    canvas.drawPath(leftPath, paint);

    // Right wing: mirrors left
    final rightPath = Path()
      ..moveTo(cx, cy)
      ..cubicTo(cx + 4, cy - 2, cx + 8, cy - 6, cx + 11, cy - 4);
    canvas.drawPath(rightPath, paint);

    // Body: small teardrop pointing right
    final bodyPath = Path()
      ..moveTo(cx, cy)
      ..cubicTo(cx + 2, cy - 1, cx + 5, cy, cx + 6, cy + 2)
      ..cubicTo(cx + 5, cy + 3, cx + 2, cy + 2, cx, cy);
    canvas.drawPath(bodyPath, paint..style = PaintingStyle.fill);
  }

  @override
  bool shouldRepaint(_BirdFlightPainter old) => old.color != color;
}
