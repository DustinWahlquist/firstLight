import 'package:flutter/material.dart';

/// Line-art tree house — the migration's destination roost. Material has no
/// treehouse glyph, so this draws one: a trunk, a leafy canopy, and a little
/// hut with a peaked roof nestled in it.
class TreehouseIcon extends StatelessWidget {
  const TreehouseIcon({super.key, required this.color, this.size = 28});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) =>
      CustomPaint(size: Size(size, size), painter: _TreehousePainter(color));
}

class _TreehousePainter extends CustomPainter {
  _TreehousePainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = s * 0.075
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final fill = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    // Trunk
    canvas.drawLine(Offset(s * 0.5, s * 0.62), Offset(s * 0.5, s * 0.95), stroke);
    // Two roots/branches
    canvas.drawLine(Offset(s * 0.5, s * 0.78), Offset(s * 0.36, s * 0.7), stroke);
    canvas.drawLine(Offset(s * 0.5, s * 0.74), Offset(s * 0.64, s * 0.64), stroke);

    // Canopy (leafy cloud behind the hut)
    final canopy = Path()
      ..addOval(Rect.fromCircle(center: Offset(s * 0.32, s * 0.34), radius: s * 0.18))
      ..addOval(Rect.fromCircle(center: Offset(s * 0.68, s * 0.34), radius: s * 0.18))
      ..addOval(Rect.fromCircle(center: Offset(s * 0.5, s * 0.26), radius: s * 0.2));
    canvas.drawPath(canopy, stroke);

    // Hut body
    final hut = Rect.fromLTWH(s * 0.36, s * 0.4, s * 0.28, s * 0.2);
    canvas.drawRRect(
      RRect.fromRectAndRadius(hut, Radius.circular(s * 0.02)),
      stroke,
    );
    // Peaked roof
    final roof = Path()
      ..moveTo(s * 0.32, s * 0.41)
      ..lineTo(s * 0.5, s * 0.28)
      ..lineTo(s * 0.68, s * 0.41)
      ..close();
    canvas.drawPath(roof, stroke);
    // Little round door
    canvas.drawCircle(Offset(s * 0.5, s * 0.52), s * 0.045, fill);
  }

  @override
  bool shouldRepaint(_TreehousePainter old) => old.color != color;
}
