import 'package:flutter/material.dart';

/// Match-only accents from the design handoff that aren't in the base app
/// theme — kicker amber, dusk/dawn gradients, and the sun.
abstract final class MatchPalette {
  static const kicker = Color(0xFFC98A3C);
  static const kickerBright = Color(0xFFE8A23D);

  static const duskTop = Color(0xFF2A3550);
  static const duskBottom = Color(0xFF6B4B5A);
  static const dawnTop = Color(0xFFFBEDD6);
  static const dawnGlow = Color(0xFFFBF1E0);

  static const handStripe = Color(0xFFCDEBD9);
  static const sunNight = Color(0xFFE8D9A8);
  static const sunDawn = Color(0xFFF5B843);

  /// Cream → background gradient behind the initiative screen.
  static const initiativeTop = Color(0xFFFBF1E0);
}
