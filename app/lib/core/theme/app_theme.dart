import 'package:flutter/material.dart';

const _primary = Color(0xFF2596BE);
const _onPrimary = Color(0xFFFFFFFF);
const _primaryContainer = Color(0xFFBFE6F5);
const _onPrimaryContainer = Color(0xFF001E2C);
const _secondary = Color(0xFF1B6B3D);
const _onSecondary = Color(0xFFFFFFFF);
const _secondaryContainer = Color(0xFFAEEFC5);
const _onSecondaryContainer = Color(0xFF00210F);
const _background = Color(0xFFF5F0E8);
const _surface = Color(0xFFFBF8F3);
const _surfaceContainerLow = Color(0xFFF5F0E8);
const _surfaceContainer = Color(0xFFEDE8DF);
const _surfaceContainerHigh = Color(0xFFE4DED4);
const _surfaceContainerHighest = Color(0xFFDAD4C9);
const _onSurface = Color(0xFF1C1916);
const _onSurfaceVariant = Color(0xFF4D4742);
const _outline = Color(0xFF7A7470);
const _outlineVariant = Color(0xFFCBC5BC);
const _error = Color(0xFFBA1A1A);
const _errorContainer = Color(0xFFFFDAD6);
const _onErrorContainer = Color(0xFF410002);
const _scrim = Color(0x52000000);

final appColorScheme = const ColorScheme(
  brightness: Brightness.light,
  primary: _primary,
  onPrimary: _onPrimary,
  primaryContainer: _primaryContainer,
  onPrimaryContainer: _onPrimaryContainer,
  secondary: _secondary,
  onSecondary: _onSecondary,
  secondaryContainer: _secondaryContainer,
  onSecondaryContainer: _onSecondaryContainer,
  tertiary: _primary,
  onTertiary: _onPrimary,
  tertiaryContainer: _primaryContainer,
  onTertiaryContainer: _onPrimaryContainer,
  error: _error,
  onError: _onPrimary,
  errorContainer: _errorContainer,
  onErrorContainer: _onErrorContainer,
  surface: _surface,
  onSurface: _onSurface,
  onSurfaceVariant: _onSurfaceVariant,
  outline: _outline,
  outlineVariant: _outlineVariant,
  shadow: Color(0xFF000000),
  scrim: _scrim,
  inverseSurface: _onSurface,
  onInverseSurface: _surface,
  inversePrimary: _primaryContainer,
  surfaceContainerLowest: Color(0xFFFBF8F3),
  surfaceContainerLow: _surfaceContainerLow,
  surfaceContainer: _surfaceContainer,
  surfaceContainerHigh: _surfaceContainerHigh,
  surfaceContainerHighest: _surfaceContainerHighest,
);

final appTheme = ThemeData(
  useMaterial3: true,
  colorScheme: appColorScheme,
  scaffoldBackgroundColor: _background,
  navigationBarTheme: const NavigationBarThemeData(
    backgroundColor: _surface,
    indicatorColor: _primaryContainer,
  ),
  cardTheme: CardThemeData(
    color: _surfaceContainerLow,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    elevation: 0,
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: Colors.transparent,
    elevation: 0,
    scrolledUnderElevation: 0,
    foregroundColor: _onSurface,
  ),
);
