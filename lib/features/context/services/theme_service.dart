import 'dart:async';
import 'package:flutter/material.dart';
import '../../../shared/models/context.dart';
import '../../../shared/models/timeline_theme.dart';

/// Service for managing timeline themes and context-aware UI
class ThemeService {
  final StreamController<TimelineTheme> _themeController = StreamController<TimelineTheme>.broadcast();
  TimelineTheme? _currentTheme;

  /// Stream of theme changes
  Stream<TimelineTheme> get themeStream => _themeController.stream;

  /// Current active theme
  TimelineTheme? get currentTheme => _currentTheme;

  /// Sets the theme for a specific context
  Future<void> setThemeForContext(ContextType contextType) async {
    final theme = TimelineTheme.forContextType(contextType);
    _currentTheme = theme;
    _themeController.add(theme);
  }

  /// Gets theme for a context type
  TimelineTheme getThemeForContextType(ContextType contextType) {
    return TimelineTheme.forContextType(contextType);
  }

  /// Checks if a feature is enabled for the current theme
  bool isFeatureEnabled(String featureName) {
    if (_currentTheme == null) return false;
    
    switch (featureName) {
      case 'ghostCamera':
        return _currentTheme!.enableGhostCamera;
      case 'budgetTracking':
        return _currentTheme!.enableBudgetTracking;
      case 'progressComparison':
        return _currentTheme!.enableProgressComparison;
      default:
        return _currentTheme!.isWidgetEnabled(featureName);
    }
  }

  /// Gets available widgets for the current theme
  List<String> getAvailableWidgets() {
    if (_currentTheme == null) return [];
    
    return _currentTheme!.widgetFactories.entries
        .where((entry) => entry.value)
        .map((entry) => entry.key)
        .toList();
  }

  /// Creates a Flutter ThemeData based on the timeline theme
  ThemeData createFlutterTheme(TimelineTheme timelineTheme) {
    final primaryColor = timelineTheme.getColor('primary');
    final secondaryColor = timelineTheme.getColor('secondary');
    final backgroundColor = timelineTheme.getColor('background');
    final surfaceColor = timelineTheme.getColor('surface');

    return ThemeData(
      primarySwatch: _createMaterialColor(primaryColor),
      primaryColor: primaryColor,
      scaffoldBackgroundColor: backgroundColor,
      cardColor: surfaceColor,
      appBarTheme: AppBarTheme(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: secondaryColor,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: primaryColor.withOpacity(0.1),
        labelStyle: TextStyle(color: primaryColor),
      ),
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        background: backgroundColor,
        surface: surfaceColor,
      ),
    );
  }

  /// Creates context-specific app bar
  PreferredSizeWidget createContextAppBar({
    required String title,
    required ContextType contextType,
    List<Widget>? actions,
  }) {
    final theme = getThemeForContextType(contextType);
    final primaryColor = theme.getColor('primary');
    
    return AppBar(
      title: Row(
        children: [
          Icon(
            _getContextIcon(contextType),
            color: Colors.white,
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(title),
        ],
      ),
      backgroundColor: primaryColor,
      foregroundColor: Colors.white,
      elevation: 0,
      actions: actions,
    );
  }

  /// Creates context-specific floating action button
  Widget createContextFAB({
    required ContextType contextType,
    required VoidCallback onPressed,
    String? tooltip,
  }) {
    final theme = getThemeForContextType(contextType);
    final secondaryColor = theme.getColor('secondary');
    
    return FloatingActionButton(
      onPressed: onPressed,
      backgroundColor: secondaryColor,
      tooltip: tooltip ?? 'Add Event',
      child: Icon(
        _getContextAddIcon(contextType),
        color: Colors.white,
      ),
    );
  }

  /// Creates context-specific bottom navigation bar
  Widget createContextBottomNav({
    required ContextType contextType,
    required int currentIndex,
    required Function(int) onTap,
  }) {
    final theme = getThemeForContextType(contextType);
    final primaryColor = theme.getColor('primary');
    
    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: onTap,
      selectedItemColor: primaryColor,
      unselectedItemColor: Colors.grey,
      type: BottomNavigationBarType.fixed,
      items: _getContextNavItems(contextType),
    );
  }

  /// Gets navigation items based on context type
  List<BottomNavigationBarItem> _getContextNavItems(ContextType contextType) {
    final baseItems = [
      const BottomNavigationBarItem(
        icon: Icon(Icons.timeline),
        label: 'Timeline',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.photo_library),
        label: 'Photos',
      ),
    ];

    switch (contextType) {
      case ContextType.person:
        return [
          ...baseItems,
          const BottomNavigationBarItem(
            icon: Icon(Icons.people),
            label: 'Social',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ];
      case ContextType.pet:
        return [
          ...baseItems,
          const BottomNavigationBarItem(
            icon: Icon(Icons.monitor_weight),
            label: 'Health',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.camera_alt),
            label: 'Camera',
          ),
        ];
      case ContextType.project:
        return [
          ...baseItems,
          const BottomNavigationBarItem(
            icon: Icon(Icons.attach_money),
            label: 'Budget',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.camera_alt),
            label: 'Progress',
          ),
        ];
      case ContextType.business:
        return [
          ...baseItems,
          const BottomNavigationBarItem(
            icon: Icon(Icons.trending_up),
            label: 'Metrics',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.group),
            label: 'Team',
          ),
        ];
    }
  }

  IconData _getContextIcon(ContextType contextType) {
    switch (contextType) {
      case ContextType.person:
        return Icons.person;
      case ContextType.pet:
        return Icons.pets;
      case ContextType.project:
        return Icons.construction;
      case ContextType.business:
        return Icons.business;
    }
  }

  IconData _getContextAddIcon(ContextType contextType) {
    switch (contextType) {
      case ContextType.person:
        return Icons.add;
      case ContextType.pet:
        return Icons.pets;
      case ContextType.project:
        return Icons.camera_alt;
      case ContextType.business:
        return Icons.add_business;
    }
  }

  /// Creates a MaterialColor from a Color
  MaterialColor _createMaterialColor(Color color) {
    final strengths = <double>[.05];
    final swatch = <int, Color>{};
    final int r = color.red, g = color.green, b = color.blue;

    for (int i = 1; i < 10; i++) {
      strengths.add(0.1 * i);
    }
    
    for (final strength in strengths) {
      final double ds = 0.5 - strength;
      swatch[(strength * 1000).round()] = Color.fromRGBO(
        r + ((ds < 0 ? r : (255 - r)) * ds).round(),
        g + ((ds < 0 ? g : (255 - g)) * ds).round(),
        b + ((ds < 0 ? b : (255 - b)) * ds).round(),
        1,
      );
    }
    
    return MaterialColor(color.value, swatch);
  }

  /// Disposes of resources
  void dispose() {
    _themeController.close();
  }
}

/// Widget that provides theme context to its children
class ThemeProvider extends StatefulWidget {
  final ContextType contextType;
  final Widget child;

  const ThemeProvider({
    Key? key,
    required this.contextType,
    required this.child,
  }) : super(key: key);

  @override
  State<ThemeProvider> createState() => _ThemeProviderState();

  static ThemeService? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<_InheritedTheme>()?.themeService;
  }
}

class _ThemeProviderState extends State<ThemeProvider> {
  late ThemeService _themeService;

  @override
  void initState() {
    super.initState();
    _themeService = ThemeService();
    _themeService.setThemeForContext(widget.contextType);
  }

  @override
  void didUpdateWidget(ThemeProvider oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.contextType != widget.contextType) {
      _themeService.setThemeForContext(widget.contextType);
    }
  }

  @override
  void dispose() {
    _themeService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _InheritedTheme(
      themeService: _themeService,
      child: widget.child,
    );
  }
}

class _InheritedTheme extends InheritedWidget {
  final ThemeService themeService;

  const _InheritedTheme({
    required this.themeService,
    required Widget child,
  }) : super(child: child);

  @override
  bool updateShouldNotify(_InheritedTheme oldWidget) {
    return themeService != oldWidget.themeService;
  }
}