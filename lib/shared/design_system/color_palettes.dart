import 'package:flutter/material.dart';

/// Color palettes for the Users Timeline application
/// Provides multiple theme options with accessibility-compliant contrast ratios
class ColorPalettes {
  // Private constructor to prevent instantiation
  ColorPalettes._();

  // ============================================================================
  // LIGHT THEME PALETTE
  // ============================================================================
  
  static const ColorScheme lightColorScheme = ColorScheme(
    brightness: Brightness.light,
    
    // Primary colors
    primary: Color(0xFF667EEA), // Modern blue-purple
    onPrimary: Color(0xFFFFFFFF),
    primaryContainer: Color(0xFFE8EEFF),
    onPrimaryContainer: Color(0xFF1A1B4B),
    
    // Secondary colors
    secondary: Color(0xFF764BA2), // Complementary purple
    onSecondary: Color(0xFFFFFFFF),
    secondaryContainer: Color(0xFFF0E8FF),
    onSecondaryContainer: Color(0xFF2A1B3D),
    
    // Tertiary colors
    tertiary: Color(0xFF52C4A0), // Fresh green accent
    onTertiary: Color(0xFFFFFFFF),
    tertiaryContainer: Color(0xFFE0F7F0),
    onTertiaryContainer: Color(0xFF0A3A2E),
    
    // Error colors
    error: Color(0xFFE53E3E),
    onError: Color(0xFFFFFFFF),
    errorContainer: Color(0xFFFFEDED),
    onErrorContainer: Color(0xFF5F2120),
    
    // Surface colors
    surface: Color(0xFFFFFBFF),
    onSurface: Color(0xFF1C1B1F),
    surfaceVariant: Color(0xFFF4F0F7),
    onSurfaceVariant: Color(0xFF47464F),
    
    // Background colors
    background: Color(0xFFFFFBFF),
    onBackground: Color(0xFF1C1B1F),
    
    // Outline colors
    outline: Color(0xFF79747E),
    outlineVariant: Color(0xFFCAC4D0),
    
    // Other colors
    shadow: Color(0xFF000000),
    scrim: Color(0xFF000000),
    inverseSurface: Color(0xFF313033),
    onInverseSurface: Color(0xFFF4EFF4),
    inversePrimary: Color(0xFFB8C5FF),
  );

  // ============================================================================
  // DARK THEME PALETTE
  // ============================================================================
  
  static const ColorScheme darkColorScheme = ColorScheme(
    brightness: Brightness.dark,
    
    // Primary colors
    primary: Color(0xFFB8C5FF), // Lighter blue for dark theme
    onPrimary: Color(0xFF1A1B4B),
    primaryContainer: Color(0xFF3A4A8A),
    onPrimaryContainer: Color(0xFFE8EEFF),
    
    // Secondary colors
    secondary: Color(0xFFD4B8FF), // Lighter purple for dark theme
    onSecondary: Color(0xFF2A1B3D),
    secondaryContainer: Color(0xFF4A3A6A),
    onSecondaryContainer: Color(0xFFF0E8FF),
    
    // Tertiary colors
    tertiary: Color(0xFF7FDFBF), // Lighter green for dark theme
    onTertiary: Color(0xFF0A3A2E),
    tertiaryContainer: Color(0xFF2A5A4A),
    onTertiaryContainer: Color(0xFFE0F7F0),
    
    // Error colors
    error: Color(0xFFFF6B6B),
    onError: Color(0xFF5F2120),
    errorContainer: Color(0xFF8C1D18),
    onErrorContainer: Color(0xFFFFEDED),
    
    // Surface colors
    surface: Color(0xFF141218),
    onSurface: Color(0xFFE6E1E5),
    surfaceVariant: Color(0xFF47464F),
    onSurfaceVariant: Color(0xFFCAC4D0),
    
    // Background colors
    background: Color(0xFF101014),
    onBackground: Color(0xFFE6E1E5),
    
    // Outline colors
    outline: Color(0xFF938F99),
    outlineVariant: Color(0xFF47464F),
    
    // Other colors
    shadow: Color(0xFF000000),
    scrim: Color(0xFF000000),
    inverseSurface: Color(0xFFE6E1E5),
    onInverseSurface: Color(0xFF313033),
    inversePrimary: Color(0xFF667EEA),
  );

  // ============================================================================
  // NEUTRAL THEME PALETTE (Warm grays with subtle color)
  // ============================================================================
  
  static const ColorScheme neutralColorScheme = ColorScheme(
    brightness: Brightness.light,
    
    // Primary colors - Warm gray with subtle blue
    primary: Color(0xFF6B7280),
    onPrimary: Color(0xFFFFFFFF),
    primaryContainer: Color(0xFFF3F4F6),
    onPrimaryContainer: Color(0xFF1F2937),
    
    // Secondary colors - Warm brown
    secondary: Color(0xFF8B7355),
    onSecondary: Color(0xFFFFFFFF),
    secondaryContainer: Color(0xFFF5F1EB),
    onSecondaryContainer: Color(0xFF2D251A),
    
    // Tertiary colors - Muted teal
    tertiary: Color(0xFF5D7C7C),
    onTertiary: Color(0xFFFFFFFF),
    tertiaryContainer: Color(0xFFE6F2F2),
    onTertiaryContainer: Color(0xFF1A2E2E),
    
    // Error colors
    error: Color(0xFFDC2626),
    onError: Color(0xFFFFFFFF),
    errorContainer: Color(0xFFFEF2F2),
    onErrorContainer: Color(0xFF7F1D1D),
    
    // Surface colors - Warm whites
    surface: Color(0xFFFAFAFA),
    onSurface: Color(0xFF1F2937),
    surfaceVariant: Color(0xFFF3F4F6),
    onSurfaceVariant: Color(0xFF4B5563),
    
    // Background colors
    background: Color(0xFFFDFDFD),
    onBackground: Color(0xFF1F2937),
    
    // Outline colors
    outline: Color(0xFF9CA3AF),
    outlineVariant: Color(0xFFD1D5DB),
    
    // Other colors
    shadow: Color(0xFF000000),
    scrim: Color(0xFF000000),
    inverseSurface: Color(0xFF374151),
    onInverseSurface: Color(0xFFF9FAFB),
    inversePrimary: Color(0xFFD1D5DB),
  );

  // ============================================================================
  // SEPIA THEME PALETTE (Warm vintage tones)
  // ============================================================================
  
  static const ColorScheme sepiaColorScheme = ColorScheme(
    brightness: Brightness.light,
    
    // Primary colors - Warm brown
    primary: Color(0xFF8B6F47),
    onPrimary: Color(0xFFFFFFFF),
    primaryContainer: Color(0xFFF0E6D9),
    onPrimaryContainer: Color(0xFF2D1F0F),
    
    // Secondary colors - Muted gold
    secondary: Color(0xFFB08D57),
    onSecondary: Color(0xFFFFFFFF),
    secondaryContainer: Color(0xFFF5EDE1),
    onSecondaryContainer: Color(0xFF2D2416),
    
    // Tertiary colors - Soft olive
    tertiary: Color(0xFF6B8E6B),
    onTertiary: Color(0xFFFFFFFF),
    tertiaryContainer: Color(0xFFE6F0E6),
    onTertiaryContainer: Color(0xFF1A2E1A),
    
    // Error colors - Warm red
    error: Color(0xFFC53030),
    onError: Color(0xFFFFFFFF),
    errorContainer: Color(0xFFFFE5E5),
    onErrorContainer: Color(0xFF7F1D1D),
    
    // Surface colors - Cream
    surface: Color(0xFFF4ECD8),
    onSurface: Color(0xFF5C4033),
    surfaceVariant: Color(0xFFEBE0C9),
    onSurfaceVariant: Color(0xFF6B5D54),
    
    // Background colors - Vintage paper
    background: Color(0xFFFAF6F0),
    onBackground: Color(0xFF5C4033),
    
    // Outline colors
    outline: Color(0xFF8B7969),
    outlineVariant: Color(0xFFD4C4B0),
    
    // Other colors
    shadow: Color(0xFF000000),
    scrim: Color(0xFF000000),
    inverseSurface: Color(0xFF4A3C2A),
    onInverseSurface: Color(0xFFF4ECD8),
    inversePrimary: Color(0xFFD4AF37),
  );

  // ============================================================================
  // ACCENT COLOR PALETTES (For customization)
  // ============================================================================
  
  /// Curated accent colors for user customization
  static const List<Color> accentColors = [
    Color(0xFF667EEA), // Default blue-purple
    Color(0xFF764BA2), // Purple
    Color(0xFF52C4A0), // Green
    Color(0xFFFF6B6B), // Coral red
    Color(0xFFFFB347), // Orange
    Color(0xFF4ECDC4), // Teal
    Color(0xFF45B7D1), // Sky blue
    Color(0xFF96CEB4), // Mint green
    Color(0xFFFECA57), // Yellow
    Color(0xFFFF9FF3), // Pink
    Color(0xFF54A0FF), // Bright blue
    Color(0xFF5F27CD), // Deep purple
  ];

  // ============================================================================
  // HIGH CONTRAST PALETTES (For accessibility)
  // ============================================================================
  
  static const ColorScheme highContrastLightColorScheme = ColorScheme(
    brightness: Brightness.light,
    
    // High contrast primary colors
    primary: Color(0xFF000080), // Dark blue
    onPrimary: Color(0xFFFFFFFF),
    primaryContainer: Color(0xFFE0E0FF),
    onPrimaryContainer: Color(0xFF000040),
    
    // High contrast secondary colors
    secondary: Color(0xFF800080), // Dark purple
    onSecondary: Color(0xFFFFFFFF),
    secondaryContainer: Color(0xFFFFE0FF),
    onSecondaryContainer: Color(0xFF400040),
    
    // High contrast tertiary colors
    tertiary: Color(0xFF008000), // Dark green
    onTertiary: Color(0xFFFFFFFF),
    tertiaryContainer: Color(0xFFE0FFE0),
    onTertiaryContainer: Color(0xFF004000),
    
    // High contrast error colors
    error: Color(0xFF800000), // Dark red
    onError: Color(0xFFFFFFFF),
    errorContainer: Color(0xFFFFE0E0),
    onErrorContainer: Color(0xFF400000),
    
    // High contrast surface colors
    surface: Color(0xFFFFFFFF), // Pure white
    onSurface: Color(0xFF000000), // Pure black
    surfaceVariant: Color(0xFFF0F0F0),
    onSurfaceVariant: Color(0xFF202020),
    
    // High contrast background colors
    background: Color(0xFFFFFFFF), // Pure white
    onBackground: Color(0xFF000000), // Pure black
    
    // High contrast outline colors
    outline: Color(0xFF404040),
    outlineVariant: Color(0xFF808080),
    
    // Other colors
    shadow: Color(0xFF000000),
    scrim: Color(0xFF000000),
    inverseSurface: Color(0xFF000000),
    onInverseSurface: Color(0xFFFFFFFF),
    inversePrimary: Color(0xFF8080FF),
  );

  static const ColorScheme highContrastDarkColorScheme = ColorScheme(
    brightness: Brightness.dark,
    
    // High contrast primary colors
    primary: Color(0xFF8080FF), // Bright blue
    onPrimary: Color(0xFF000040),
    primaryContainer: Color(0xFF000080),
    onPrimaryContainer: Color(0xFFE0E0FF),
    
    // High contrast secondary colors
    secondary: Color(0xFFFF80FF), // Bright purple
    onSecondary: Color(0xFF400040),
    secondaryContainer: Color(0xFF800080),
    onSecondaryContainer: Color(0xFFFFE0FF),
    
    // High contrast tertiary colors
    tertiary: Color(0xFF80FF80), // Bright green
    onTertiary: Color(0xFF004000),
    tertiaryContainer: Color(0xFF008000),
    onTertiaryContainer: Color(0xFFE0FFE0),
    
    // High contrast error colors
    error: Color(0xFFFF8080), // Bright red
    onError: Color(0xFF400000),
    errorContainer: Color(0xFF800000),
    onErrorContainer: Color(0xFFFFE0E0),
    
    // High contrast surface colors
    surface: Color(0xFF000000), // Pure black
    onSurface: Color(0xFFFFFFFF), // Pure white
    surfaceVariant: Color(0xFF202020),
    onSurfaceVariant: Color(0xFFE0E0E0),
    
    // High contrast background colors
    background: Color(0xFF000000), // Pure black
    onBackground: Color(0xFFFFFFFF), // Pure white
    
    // High contrast outline colors
    outline: Color(0xFFC0C0C0),
    outlineVariant: Color(0xFF808080),
    
    // Other colors
    shadow: Color(0xFF000000),
    scrim: Color(0xFF000000),
    inverseSurface: Color(0xFFFFFFFF),
    onInverseSurface: Color(0xFF000000),
    inversePrimary: Color(0xFF000080),
  );

  // ============================================================================
  // HELPER METHODS
  // ============================================================================
  
  /// Generate a color scheme with a custom accent color
  static ColorScheme generateAccentColorScheme({
    required Color accentColor,
    required Brightness brightness,
  }) {
    final baseScheme = brightness == Brightness.light 
        ? lightColorScheme 
        : darkColorScheme;
    
    return baseScheme.copyWith(
      primary: accentColor,
      primaryContainer: brightness == Brightness.light
          ? Color.alphaBlend(accentColor.withOpacity(0.2), Colors.white)
          : Color.alphaBlend(accentColor.withOpacity(0.3), Colors.black),
    );
  }
  
  /// Get a color scheme by name
  static ColorScheme getColorScheme(String schemeName, {bool highContrast = false}) {
    if (highContrast) {
      switch (schemeName.toLowerCase()) {
        case 'light':
          return highContrastLightColorScheme;
        case 'dark':
          return highContrastDarkColorScheme;
        default:
          return highContrastLightColorScheme;
      }
    }
    
    switch (schemeName.toLowerCase()) {
      case 'light':
        return lightColorScheme;
      case 'dark':
        return darkColorScheme;
      case 'neutral':
        return neutralColorScheme;
      case 'sepia':
        return sepiaColorScheme;
      default:
        return lightColorScheme;
    }
  }
  
  /// Check if a color has sufficient contrast against another color
  static bool hasGoodContrast(Color foreground, Color background) {
    final luminance1 = foreground.computeLuminance();
    final luminance2 = background.computeLuminance();
    final ratio = (luminance1 > luminance2)
        ? (luminance1 + 0.05) / (luminance2 + 0.05)
        : (luminance2 + 0.05) / (luminance1 + 0.05);
    
    return ratio >= 4.5; // WCAG AA standard
  }
}