import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../presentation/providers/providers.dart';
import 'app_theme.dart';

/// Exposes the current [ThemeMode] derived from persisted settings.
final themeModeProvider = Provider<ThemeMode>((ref) {
  final settingsAsync = ref.watch(settingsNotifierProvider);
  return settingsAsync.maybeWhen(
    data: (s) => s.themeMode,
    orElse: () => ThemeMode.system,
  );
});

/// Exposes the current accent color int value from persisted settings.
final accentColorProvider = Provider<int>((ref) {
  final settingsAsync = ref.watch(settingsNotifierProvider);
  return settingsAsync.maybeWhen(
    data: (s) => s.accentColor,
    orElse: () => 0xFF6750A4,
  );
});

/// Exposes the resolved light [ThemeData] for the current accent color.
final lightThemeProvider = Provider<ThemeData>((ref) {
  final accent = ref.watch(accentColorProvider);
  return AppTheme.light(accent);
});

/// Exposes the resolved dark [ThemeData] for the current accent color.
final darkThemeProvider = Provider<ThemeData>((ref) {
  final accent = ref.watch(accentColorProvider);
  return AppTheme.dark(accent);
});
