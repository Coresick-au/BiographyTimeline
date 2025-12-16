import 'package:flutter/material.dart';
import 'color_palettes.dart';
import 'color_palettes.dart';
import 'design_tokens.dart';
import 'app_spacing.dart';
import 'app_radii.dart';

/// Represents a complete theme configuration for the Users Timeline app
class AppTheme {
  final String id;
  final String name;
  final String description;
  final ThemeMode mode;
  final ColorScheme colorScheme;
  final Color accentColor;
  final bool highContrast;
  final bool reducedMotion;
  final Map<String, dynamic> componentOverrides;

  const AppTheme({
    required this.id,
    required this.name,
    required this.description,
    required this.mode,
    required this.colorScheme,
    required this.accentColor,
    this.highContrast = false,
    this.reducedMotion = false,
    this.componentOverrides = const {},
  });

  /// Create a ThemeData object from this AppTheme
  ThemeData toThemeData() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      
      // Typography using design tokens
      textTheme: TextTheme(
        displayLarge: DesignTokens.displayLarge.copyWith(color: colorScheme.onBackground),
        displayMedium: DesignTokens.displayMedium.copyWith(color: colorScheme.onBackground),
        displaySmall: DesignTokens.displaySmall.copyWith(color: colorScheme.onBackground),
        headlineLarge: DesignTokens.headlineLarge.copyWith(color: colorScheme.onBackground),
        headlineMedium: DesignTokens.headlineMedium.copyWith(color: colorScheme.onBackground),
        headlineSmall: DesignTokens.headlineSmall.copyWith(color: colorScheme.onBackground),
        titleLarge: DesignTokens.titleLarge.copyWith(color: colorScheme.onSurface),
        titleMedium: DesignTokens.titleMedium.copyWith(color: colorScheme.onSurface),
        titleSmall: DesignTokens.titleSmall.copyWith(color: colorScheme.onSurface),
        bodyLarge: DesignTokens.bodyLarge.copyWith(color: colorScheme.onSurface),
        bodyMedium: DesignTokens.bodyMedium.copyWith(color: colorScheme.onSurface),
        bodySmall: DesignTokens.bodySmall.copyWith(color: colorScheme.onSurfaceVariant),
        labelLarge: DesignTokens.labelLarge.copyWith(color: colorScheme.onSurface),
        labelMedium: DesignTokens.labelMedium.copyWith(color: colorScheme.onSurfaceVariant),
        labelSmall: DesignTokens.labelSmall.copyWith(color: colorScheme.onSurfaceVariant),
      ),
      
      // Card theme
      cardTheme: CardThemeData(
        elevation: DesignTokens.elevation2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
        ),
        margin: EdgeInsets.all(AppSpacing.sm),
      ),
      
      // Elevated button theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: DesignTokens.elevation2,
          padding: EdgeInsets.symmetric(
            horizontal: AppSpacing.xl,
            vertical: AppSpacing.md,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.sm),
          ),
          textStyle: DesignTokens.labelLarge,
        ),
      ),
      
      // Outlined button theme
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          padding: EdgeInsets.symmetric(
            horizontal: AppSpacing.xl,
            vertical: AppSpacing.md,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.sm),
          ),
          textStyle: DesignTokens.labelLarge,
        ),
      ),
      
      // Text button theme
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          padding: EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.sm,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.sm),
          ),
          textStyle: DesignTokens.labelLarge,
        ),
      ),
      
      // Input decoration theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surfaceVariant.withOpacity(0.5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.sm),
          borderSide: BorderSide(color: colorScheme.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.sm),
          borderSide: BorderSide(color: colorScheme.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.sm),
          borderSide: BorderSide(color: colorScheme.primary, width: 2.0),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.sm),
          borderSide: BorderSide(color: colorScheme.error),
        ),
        contentPadding: EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        labelStyle: DesignTokens.bodyMedium.copyWith(color: colorScheme.onSurfaceVariant),
        hintStyle: DesignTokens.bodyMedium.copyWith(color: colorScheme.onSurfaceVariant.withOpacity(0.6)),
      ),
      
      // App bar theme
      appBarTheme: AppBarTheme(
        elevation: DesignTokens.elevation0,
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        titleTextStyle: DesignTokens.titleLarge.copyWith(color: colorScheme.onSurface),
        iconTheme: IconThemeData(color: colorScheme.onSurface),
      ),
      
      // Bottom navigation bar theme
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: colorScheme.surface,
        selectedItemColor: colorScheme.primary,
        unselectedItemColor: colorScheme.onSurfaceVariant,
        type: BottomNavigationBarType.fixed,
        elevation: DesignTokens.elevation3,
      ),
      
      // Floating action button theme
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        elevation: DesignTokens.elevation3,
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.lg),
        ),
      ),
      
      // Dialog theme
      dialogTheme: DialogThemeData(
        elevation: DesignTokens.elevation6,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.lg),
        ),
        backgroundColor: colorScheme.surface,
        titleTextStyle: DesignTokens.headlineSmall.copyWith(color: colorScheme.onSurface),
        contentTextStyle: DesignTokens.bodyMedium.copyWith(color: colorScheme.onSurface),
      ),
      
      // Chip theme
      chipTheme: ChipThemeData(
        backgroundColor: colorScheme.surfaceVariant,
        labelStyle: DesignTokens.labelMedium.copyWith(color: colorScheme.onSurfaceVariant),
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.sm),
        ),
      ),
      
      // List tile theme
      listTileTheme: ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.sm,
        ),
        titleTextStyle: DesignTokens.bodyLarge.copyWith(color: colorScheme.onSurface),
        subtitleTextStyle: DesignTokens.bodyMedium.copyWith(color: colorScheme.onSurfaceVariant),
      ),
      
      // Divider theme
      dividerTheme: DividerThemeData(
        color: colorScheme.outlineVariant,
        thickness: 1.0,
        space: AppSpacing.lg,
      ),
      
      // Icon theme
      iconTheme: IconThemeData(
        color: colorScheme.onSurface,
        size: 24.0,
      ),
      
      // Primary icon theme
      primaryIconTheme: IconThemeData(
        color: colorScheme.primary,
        size: 24.0,
      ),
    );
  }

  /// Copy this theme with new values
  AppTheme copyWith({
    String? id,
    String? name,
    String? description,
    ThemeMode? mode,
    ColorScheme? colorScheme,
    Color? accentColor,
    bool? highContrast,
    bool? reducedMotion,
    Map<String, dynamic>? componentOverrides,
  }) {
    return AppTheme(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      mode: mode ?? this.mode,
      colorScheme: colorScheme ?? this.colorScheme,
      accentColor: accentColor ?? this.accentColor,
      highContrast: highContrast ?? this.highContrast,
      reducedMotion: reducedMotion ?? this.reducedMotion,
      componentOverrides: componentOverrides ?? this.componentOverrides,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AppTheme && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'AppTheme(id: $id, name: $name, mode: $mode)';
  }

  /// Get AppTheme accessor from BuildContext
  /// Returns a helper that provides convenient access to theme colors and text styles
  static AppThemeColors of(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return AppThemeColors(theme);
  }
}

/// Helper class providing convenient access to theme colors
class AppThemeColors {
  final ThemeData _theme;
  
  const AppThemeColors(this._theme);
  
  AppThemeColorAccessor get colors => AppThemeColorAccessor(_theme);
  AppThemeTextStyleAccessor get textStyles => AppThemeTextStyleAccessor(_theme);
}

/// Accessor for theme colors
class AppThemeColorAccessor {
  final ThemeData _theme;
  
  const AppThemeColorAccessor(this._theme);
  
  Color get background => _theme.colorScheme.background;
  Color get surface => _theme.colorScheme.surface;
  Color get surfaceVariant => _theme.colorScheme.surfaceVariant;
  Color get primary => _theme.colorScheme.primary;
  Color get onPrimary => _theme.colorScheme.onPrimary;
  Color get secondary => _theme.colorScheme.secondary;
  Color get error => _theme.colorScheme.error;
  Color get textPrimary => _theme.colorScheme.onSurface;
  Color get textSecondary => _theme.colorScheme.onSurfaceVariant;
}

/// Accessor for theme text styles
class AppThemeTextStyleAccessor {
  final ThemeData _theme;
  
  const AppThemeTextStyleAccessor(this._theme);
  
  TextStyle get displayLarge => _theme.textTheme.displayLarge ?? const TextStyle();
  TextStyle get displayMedium => _theme.textTheme.displayMedium ?? const TextStyle();
  TextStyle get displaySmall => _theme.textTheme.displaySmall ?? const TextStyle();
  TextStyle get headlineLarge => _theme.textTheme.headlineLarge ?? const TextStyle();
  TextStyle get headlineMedium => _theme.textTheme.headlineMedium ?? const TextStyle();
  TextStyle get headlineSmall => _theme.textTheme.headlineSmall ?? const TextStyle();
  TextStyle get titleLarge => _theme.textTheme.titleLarge ?? const TextStyle();
  TextStyle get titleMedium => _theme.textTheme.titleMedium ?? const TextStyle();
  TextStyle get titleSmall => _theme.textTheme.titleSmall ?? const TextStyle();
  TextStyle get bodyLarge => _theme.textTheme.bodyLarge ?? const TextStyle();
  TextStyle get bodyMedium => _theme.textTheme.bodyMedium ?? const TextStyle();
  TextStyle get bodySmall => _theme.textTheme.bodySmall ?? const TextStyle();
  TextStyle get labelLarge => _theme.textTheme.labelLarge ?? const TextStyle();
  TextStyle get labelMedium => _theme.textTheme.labelMedium ?? const TextStyle();
  TextStyle get labelSmall => _theme.textTheme.labelSmall ?? const TextStyle();
}

/// Predefined themes for the Users Timeline app
class AppThemes {
  // Private constructor to prevent instantiation
  AppThemes._();

  /// Light theme with default colors
  static const AppTheme light = AppTheme(
    id: 'light',
    name: 'Light',
    description: 'Clean and bright theme for daytime use',
    mode: ThemeMode.light,
    colorScheme: ColorPalettes.lightColorScheme,
    accentColor: Color(0xFF667EEA),
  );

  /// Dark theme with default colors
  static const AppTheme dark = AppTheme(
    id: 'dark',
    name: 'Dark',
    description: 'Easy on the eyes for low-light environments',
    mode: ThemeMode.dark,
    colorScheme: ColorPalettes.darkColorScheme,
    accentColor: Color(0xFFB8C5FF),
  );

  /// Neutral theme with warm grays
  static const AppTheme neutral = AppTheme(
    id: 'neutral',
    name: 'Neutral',
    description: 'Warm and professional with subtle colors',
    mode: ThemeMode.light,
    colorScheme: ColorPalettes.neutralColorScheme,
    accentColor: Color(0xFF6B7280),
  );

  /// Sepia theme with warm vintage tones
  static const AppTheme sepia = AppTheme(
    id: 'sepia',
    name: 'Sepia',
    description: 'Warm vintage tones for comfortable reading',
    mode: ThemeMode.light,
    colorScheme: ColorPalettes.sepiaColorScheme,
    accentColor: Color(0xFF8B6F47),
  );

  /// High contrast light theme for accessibility
  static const AppTheme highContrastLight = AppTheme(
    id: 'high_contrast_light',
    name: 'High Contrast Light',
    description: 'Maximum contrast for better accessibility',
    mode: ThemeMode.light,
    colorScheme: ColorPalettes.highContrastLightColorScheme,
    accentColor: Color(0xFF000080),
    highContrast: true,
  );

  /// High contrast dark theme for accessibility
  static const AppTheme highContrastDark = AppTheme(
    id: 'high_contrast_dark',
    name: 'High Contrast Dark',
    description: 'Dark theme with maximum contrast',
    mode: ThemeMode.dark,
    colorScheme: ColorPalettes.highContrastDarkColorScheme,
    accentColor: Color(0xFF8080FF),
    highContrast: true,
  );

  /// All available themes
  static const List<AppTheme> allThemes = [
    light,
    dark,
    neutral,
    sepia,
    highContrastLight,
    highContrastDark,
  ];

  /// Get theme by ID
  static AppTheme? getThemeById(String id) {
    try {
      return allThemes.firstWhere((theme) => theme.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Get default theme
  static AppTheme get defaultTheme => light;

  /// Create a custom theme with accent color
  static AppTheme createCustomTheme({
    required String id,
    required String name,
    required Color accentColor,
    required Brightness brightness,
    bool highContrast = false,
  }) {
    final colorScheme = ColorPalettes.generateAccentColorScheme(
      accentColor: accentColor,
      brightness: brightness,
    );

    return AppTheme(
      id: id,
      name: name,
      description: 'Custom theme with ${accentColor.toString()} accent',
      mode: brightness == Brightness.light ? ThemeMode.light : ThemeMode.dark,
      colorScheme: colorScheme,
      accentColor: accentColor,
      highContrast: highContrast,
    );
  }
}
