import 'package:flutter/material.dart';

/// The 6 available accent colors with their display name and seed color.
class AccentColor {
  final String name;
  final int value;
  const AccentColor({required this.name, required this.value});
}

class AppColorSchemes {
  AppColorSchemes._();

  static const List<AccentColor> accentColors = [
    AccentColor(name: 'Violet',   value: 0xFF6750A4),
    AccentColor(name: 'Indigo',   value: 0xFF3F51B5),
    AccentColor(name: 'Teal',     value: 0xFF009688),
    AccentColor(name: 'Rose',     value: 0xFFE91E63),
    AccentColor(name: 'Amber',    value: 0xFFFF9800),
    AccentColor(name: 'Slate',    value: 0xFF607D8B),
  ];

  /// Returns the [ColorScheme] for the given accent color value and brightness.
  static ColorScheme schemeFor(int colorValue, Brightness brightness) {
    return ColorScheme.fromSeed(
      seedColor: Color(colorValue),
      brightness: brightness,
    );
  }
}
