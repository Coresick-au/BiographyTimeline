import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../features/demo/demo_page.dart';

class UsersTimelineApp extends ConsumerWidget {
  const UsersTimelineApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'Users Timeline',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const DemoPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}