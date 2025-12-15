import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/context.dart';

/// Simplified theme provider for Family-First MVP
/// Uses a single modern dark theme instead of context-based themes

/// Provider for the app's theme
final appThemeProvider = Provider<ThemeData>((ref) {
  return ThemeData(
    colorScheme: ColorScheme.fromSeed(
      seedColor: Colors.blue,
      brightness: Brightness.dark,
    ),
    useMaterial3: true,
  );
});

/// Provider for theme mode (light/dark)
final themeModeProvider = StateProvider<ThemeMode>((ref) {
  return ThemeMode.dark;
});

/// Provider for the current context type (used by theme switcher)
final contextTypeProvider = StateProvider<ContextType>((ref) {
  return ContextType.person;
});

/// Provider for the active theme based on context type
final activeThemeProvider = Provider<ThemeData>((ref) {
  // For now, return the same theme regardless of context
  // In the future, this could return different themes based on contextTypeProvider
  return ref.watch(appThemeProvider);
});
