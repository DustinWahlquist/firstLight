import 'package:flutter/material.dart';

/// A Watcher's mark — a colored circle with a wing glyph. Stands in for the
/// eventual customizable mark (color + glyph, later a photo). Used as the
/// migration token on the flyway and as small avatars.
class WatcherToken extends StatelessWidget {
  const WatcherToken({
    super.key,
    required this.color,
    this.size = 30,
    this.glyphColor = Colors.white,
  });

  final Color color;
  final double size;
  final Color glyphColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      alignment: Alignment.center,
      child: Icon(Icons.flight, size: size * 0.5, color: glyphColor),
    );
  }
}
