import 'package:flutter/material.dart';

class BirdcageIcon extends StatelessWidget {
  const BirdcageIcon({super.key, this.size = 24, this.color});
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _BirdcagePainter(
        color ?? IconTheme.of(context).color ?? Colors.black,
      ),
    );
  }
}

class _BirdcagePainter extends CustomPainter {
  const _BirdcagePainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.08
      ..strokeCap = StrokeCap.round;

    final w = size.width;
    final h = size.height;

    final cageLeft = w * 0.1;
    final cageRight = w * 0.9;
    final cageTop = h * 0.3;
    final cageBottom = h * 0.92;
    final radius = w * 0.12;

    final bodyRect = RRect.fromLTRBR(
      cageLeft, cageTop, cageRight, cageBottom,
      Radius.circular(radius),
    );
    canvas.drawRRect(bodyRect, paint);

    final barSpacing = (cageRight - cageLeft) / 4;
    for (int i = 1; i <= 3; i++) {
      final x = cageLeft + barSpacing * i;
      canvas.drawLine(
        Offset(x, cageTop + size.height * 0.02),
        Offset(x, cageBottom - size.height * 0.02),
        paint,
      );
    }

    final domePath = Path()
      ..moveTo(cageLeft, cageTop)
      ..quadraticBezierTo(w * 0.5, h * 0.08, cageRight, cageTop);
    canvas.drawPath(domePath, paint);

    final loopRect = Rect.fromCenter(
      center: Offset(w * 0.5, h * 0.05),
      width: w * 0.12,
      height: h * 0.1,
    );
    canvas.drawArc(loopRect, 3.14, 3.14, false, paint);
  }

  @override
  bool shouldRepaint(_BirdcagePainter old) => old.color != color;
}
