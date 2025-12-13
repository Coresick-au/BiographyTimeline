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
    print('🎨 THEME SERVICE: Setting theme for context: $contextType');
    final theme = TimelineTheme.forContextType(contextType);
    print('🎨 THEME SERVICE: Created theme: ${theme.name} with primary: ${theme.getColor('primary')}');
    _currentTheme = theme;
    _themeController.add(theme);
    print('🎨 THEME SERVICE: Theme updated and broadcasted');
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

    print('🎨 THEME SERVICE: Creating beautiful theme with primary: $primaryColor');

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      
      // Color scheme with beautiful gradients and harmonious colors
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        brightness: Brightness.light,
        primary: primaryColor,
        secondary: secondaryColor,
        surface: surfaceColor,
        background: backgroundColor,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: Colors.black87,
        onBackground: Colors.black87,
      ).copyWith(
        primary: primaryColor,
        secondary: secondaryColor,
        surface: surfaceColor,
        background: backgroundColor,
        surfaceVariant: surfaceColor.withOpacity(0.8),
        outline: primaryColor.withOpacity(0.2),
        outlineVariant: primaryColor.withOpacity(0.1),
      ),

      // Beautiful typography with better fonts and spacing
      textTheme: TextTheme(
        displayLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
          color: Colors.black87,
          height: 1.2,
        ),
        displayMedium: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.25,
          color: Colors.black87,
          height: 1.3,
        ),
        headlineLarge: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          letterSpacing: 0,
          color: Colors.black87,
          height: 1.3,
        ),
        headlineMedium: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.15,
          color: Colors.black87,
          height: 1.4,
        ),
        titleLarge: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.15,
          color: Colors.black87,
          height: 1.4,
        ),
        titleMedium: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.15,
          color: Colors.black87,
          height: 1.5,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          letterSpacing: 0.5,
          color: Colors.black87,
          height: 1.5,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          letterSpacing: 0.25,
          color: Colors.black87,
          height: 1.4,
        ),
        labelLarge: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.1,
          color: primaryColor,
          height: 1.3,
        ),
      ),

      // Enhanced app bar with beautiful styling
      appBarTheme: AppBarTheme(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: Colors.white,
          letterSpacing: 0.15,
        ),
        iconTheme: IconThemeData(
          color: Colors.white,
          size: 24,
        ),
        actionsIconTheme: IconThemeData(
          color: Colors.white,
          size: 24,
        ),
      ),

      // Beautiful cards with shadows and modern styling
      cardTheme: CardTheme(
        color: surfaceColor,
        elevation: 2,
        shadowColor: Colors.black.withOpacity(0.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),

      // Enhanced elevated buttons with gradients
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 2,
          shadowColor: primaryColor.withOpacity(0.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          textStyle: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),

      // Modern floating action button
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: secondaryColor,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),

      // Beautiful chips
      chipTheme: ChipThemeData(
        backgroundColor: primaryColor.withOpacity(0.1),
        selectedColor: primaryColor.withOpacity(0.2),
        disabledColor: Colors.grey.withOpacity(0.1),
        labelStyle: TextStyle(
          color: primaryColor,
          fontWeight: FontWeight.w500,
        ),
        secondaryLabelStyle: TextStyle(
          color: primaryColor.withOpacity(0.8),
        ),
        brightness: Brightness.light,
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),

      // Enhanced input decoration
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primaryColor.withOpacity(0.2)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primaryColor.withOpacity(0.2)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primaryColor, width: 2),
        ),
        labelStyle: TextStyle(
          color: primaryColor.withOpacity(0.7),
          fontWeight: FontWeight.w500,
        ),
        hintStyle: TextStyle(
          color: Colors.grey.withOpacity(0.6),
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),

      // Bottom navigation bar with modern styling
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: surfaceColor,
        selectedItemColor: primaryColor,
        unselectedItemColor: Colors.grey.withOpacity(0.6),
        selectedLabelStyle: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
        unselectedLabelStyle: TextStyle(
          fontWeight: FontWeight.w400,
          fontSize: 12,
        ),
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),

      // Modern list tiles
      listTileTheme: ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        tileColor: Colors.transparent,
        selectedTileColor: primaryColor.withOpacity(0.1),
        iconColor: primaryColor,
        textColor: Colors.black87,
        titleTextStyle: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: Colors.black87,
        ),
        subtitleTextStyle: TextStyle(
          fontSize: 14,
          color: Colors.grey.withOpacity(0.7),
        ),
      ),

      // Beautiful dividers
      dividerTheme: DividerThemeData(
        color: Colors.grey.withOpacity(0.2),
        thickness: 1,
        space: 1,
      ),

      // Modern dialog theme
      dialogTheme: DialogTheme(
        backgroundColor: surfaceColor,
        elevation: 8,
        shadowColor: Colors.black.withOpacity(0.2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
        contentTextStyle: TextStyle(
          fontSize: 16,
          color: Colors.black87,
        ),
      ),

      // Enhanced scaffold
      scaffoldBackgroundColor: backgroundColor,
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