import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_theme.dart';

/// Always dark — FocusFlow uses a fixed dark design system.
final themeModeProvider = Provider<ThemeMode>((_) => ThemeMode.dark);

/// Light theme (dark design system used for both modes).
final lightThemeProvider = Provider<ThemeData>((_) => AppTheme.dark());

/// Dark theme.
final darkThemeProvider = Provider<ThemeData>((_) => AppTheme.dark());
