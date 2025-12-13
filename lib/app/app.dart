import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'navigation/main_navigation.dart';
import '../shared/providers/design_system_provider.dart';
import '../shared/providers/theme_provider.dart';

class UsersTimelineApp extends ConsumerWidget {
  const UsersTimelineApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Initialize the design system theme manager
    final themeInitialization = ref.watch(themeInitializationProvider);
    
    return themeInitialization.when(
      data: (_) => _buildApp(context, ref),
      loading: () => _buildLoadingApp(),
      error: (error, stack) => _buildErrorApp(error),
    );
  }

  Widget _buildApp(BuildContext context, WidgetRef ref) {
    // Watch the new design system theme
    final themeData = ref.watch(appThemeDataProvider);
    
    return MaterialApp(
      title: 'Users Timeline',
      theme: themeData,
      home: const EnhancedNavigation(),
      debugShowCheckedModeBanner: false,
    );
  }

  Widget _buildLoadingApp() {
    return MaterialApp(
      title: 'Users Timeline',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF667EEA)),
        useMaterial3: true,
      ),
      home: const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      ),
      debugShowCheckedModeBanner: false,
    );
  }

  Widget _buildErrorApp(Object error) {
    return MaterialApp(
      title: 'Users Timeline',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.red),
        useMaterial3: true,
      ),
      home: Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              const Text('Failed to initialize theme system'),
              const SizedBox(height: 8),
              Text('Error: $error'),
            ],
          ),
        ),
      ),
      debugShowCheckedModeBanner: false,
    );
  }
}