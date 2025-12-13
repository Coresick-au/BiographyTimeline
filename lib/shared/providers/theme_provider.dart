import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/context.dart';
import '../models/timeline_theme.dart';
import '../../features/context/services/theme_service.dart';

/// Provider for the ThemeService instance
final themeServiceProvider = Provider<ThemeService>((ref) {
  final themeService = ThemeService();
  
  // Set default theme to personal context
  themeService.setThemeForContext(ContextType.person);
  
  // Dispose the service when the provider is disposed
  ref.onDispose(() {
    themeService.dispose();
  });
  
  return themeService;
});

/// Provider for the current theme stream
final currentThemeProvider = StreamProvider<TimelineTheme>((ref) {
  final themeService = ref.watch(themeServiceProvider);
  return themeService.themeStream;
});

/// Provider for the current active theme
final activeThemeProvider = Provider<TimelineTheme?>((ref) {
  final themeService = ref.watch(themeServiceProvider);
  return themeService.currentTheme;
});

/// Provider for the current Flutter ThemeData
final flutterThemeProvider = Provider<ThemeData>((ref) {
  final themeService = ref.watch(themeServiceProvider);
  final contextType = ref.watch(contextTypeProvider);
  
  // Update theme when context type changes
  themeService.setThemeForContext(contextType);
  
  final currentTheme = themeService.currentTheme;
  
  if (currentTheme == null) {
    print('🎨 THEME DEBUG: No current theme, using fallback purple theme');
    // Fallback to default theme if no theme is set
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      useMaterial3: true,
    );
  }
  
  final primaryColor = currentTheme.getColor('primary');
  print('🎨 THEME DEBUG: Applying theme for $contextType');
  print('🎨 THEME DEBUG: Primary color: $primaryColor');
  print('🎨 THEME DEBUG: Theme name: ${currentTheme.name}');
  
  final themeData = themeService.createFlutterTheme(currentTheme);
  print('🎨 THEME DEBUG: Created ThemeData with primary: ${themeData.primaryColor}');
  
  return themeData;
});

/// Provider to control the current context type
final contextTypeProvider = StateProvider<ContextType>((ref) {
  return ContextType.person;
});

/// Provider to update theme based on context type
final themeUpdaterProvider = Provider<void>((ref) {
  final themeService = ref.watch(themeServiceProvider);
  final contextType = ref.watch(contextTypeProvider);
  
  // Update theme when context type changes
  themeService.setThemeForContext(contextType);
});
