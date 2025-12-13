import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'navigation/main_navigation.dart';
import '../shared/providers/theme_provider.dart';

class UsersTimelineApp extends ConsumerWidget {
  const UsersTimelineApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the dynamic theme from our provider
    final theme = ref.watch(flutterThemeProvider);
    
    return MaterialApp(
      title: 'Users Timeline',
      theme: theme,
      home: const EnhancedNavigation(),
      debugShowCheckedModeBanner: false,
    );
  }
}