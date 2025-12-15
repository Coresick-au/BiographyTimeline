import 'package:flutter/material.dart';

/// A standardized Scaffold for the Users Timeline application.
/// 
/// Automatically applies the branded background gradient and handles safe areas.
/// Use this instead of the raw Material [Scaffold] for top-level screens.
class AppScaffold extends StatelessWidget {
  final Widget body;
  final PreferredSizeWidget? appBar;
  final Widget? floatingActionButton;
  final Widget? bottomNavigationBar;
  final Widget? drawer;
  final Color? backgroundColor;
  final bool resizeToAvoidBottomInset;
  final bool extendBodyBehindAppBar;

  const AppScaffold({
    super.key,
    required this.body,
    this.appBar,
    this.floatingActionButton,
    this.bottomNavigationBar,
    this.drawer,
    this.backgroundColor,
    this.resizeToAvoidBottomInset = true,
    this.extendBodyBehindAppBar = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: appBar,
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: bottomNavigationBar,
      drawer: drawer,
      backgroundColor: backgroundColor ?? Colors.transparent, // Handle gradient below
      resizeToAvoidBottomInset: resizeToAvoidBottomInset,
      extendBodyBehindAppBar: extendBodyBehindAppBar,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              theme.colorScheme.background,
              theme.colorScheme.surface,
            ],
            // Add subtle stops for depth if needed
          ),
        ),
        child: SafeArea(
          // Only wrap in SafeArea if not extending behind app bar 
          // (or let consumer handle it if they need precise control)
          top: !extendBodyBehindAppBar, 
          bottom: true,
          left: true,
          right: true,
          child: body,
        ),
      ),
    );
  }
}
