import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'navigation/main_navigation.dart';
import '../shared/providers/theme_provider.dart';
import '../shared/widgets/loading_widgets.dart';

class UsersTimelineApp extends ConsumerWidget {
  const UsersTimelineApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _buildApp(context, ref);
  }

  Widget _buildApp(BuildContext context, WidgetRef ref) {
    // Watch the current theme from our new theme system
    final themeData = ref.watch(themeDataProvider);
    
    return MaterialApp(
      title: 'Timeline Biography',
      theme: themeData,
      darkTheme: themeData, // Use same theme for both modes (theme handles its own brightness)
      themeMode: ThemeMode.dark, // Let the theme control its appearance
      home: LoadingOverlay(
        child: const EnhancedNavigation(),
      ),
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