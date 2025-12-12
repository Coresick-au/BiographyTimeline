import 'package:flutter/material.dart';
import 'package:json_annotation/json_annotation.dart';
import 'context.dart';

part 'timeline_theme.g.dart';

@JsonSerializable()
class TimelineTheme {
  final String id;
  final String name;
  final ContextType contextType;
  final Map<String, int> colorPalette; // Store colors as int values for JSON serialization
  final Map<String, String> iconSet; // Store icon names as strings
  final Map<String, Map<String, dynamic>> typography; // Store text style properties
  final Map<String, bool> widgetFactories; // Store which widgets are enabled
  final bool enableGhostCamera;
  final bool enableBudgetTracking;
  final bool enableProgressComparison;

  const TimelineTheme({
    required this.id,
    required this.name,
    required this.contextType,
    required this.colorPalette,
    required this.iconSet,
    required this.typography,
    required this.widgetFactories,
    required this.enableGhostCamera,
    required this.enableBudgetTracking,
    required this.enableProgressComparison,
  });

  factory TimelineTheme.fromJson(Map<String, dynamic> json) =>
      _$TimelineThemeFromJson(json);
  Map<String, dynamic> toJson() => _$TimelineThemeToJson(this);

  /// Creates a default theme for a context type
  factory TimelineTheme.forContextType(ContextType contextType) {
    switch (contextType) {
      case ContextType.person:
        return TimelineTheme._personal();
      case ContextType.pet:
        return TimelineTheme._pet();
      case ContextType.project:
        return TimelineTheme._renovation();
      case ContextType.business:
        return TimelineTheme._business();
    }
  }

  factory TimelineTheme._personal() {
    return const TimelineTheme(
      id: 'personal_theme',
      name: 'Personal',
      contextType: ContextType.person,
      colorPalette: {
        'primary': 0xFF2196F3, // Blue
        'secondary': 0xFF03DAC6, // Teal
        'background': 0xFFFAFAFA, // Light grey
        'surface': 0xFFFFFFFF, // White
        'accent': 0xFFFF5722, // Deep orange
      },
      iconSet: {
        'event': 'event',
        'photo': 'photo',
        'story': 'book',
        'location': 'location_on',
        'person': 'person',
      },
      typography: {
        'headline': {'fontSize': 24.0, 'fontWeight': 'bold'},
        'body': {'fontSize': 16.0, 'fontWeight': 'normal'},
        'caption': {'fontSize': 12.0, 'fontWeight': 'normal'},
      },
      widgetFactories: {
        'milestoneCard': true,
        'locationCard': true,
        'photoGrid': true,
        'storyCard': true,
      },
      enableGhostCamera: false,
      enableBudgetTracking: false,
      enableProgressComparison: false,
    );
  }

  factory TimelineTheme._pet() {
    return const TimelineTheme(
      id: 'pet_theme',
      name: 'Pet',
      contextType: ContextType.pet,
      colorPalette: {
        'primary': 0xFF4CAF50, // Green
        'secondary': 0xFFFFEB3B, // Yellow
        'background': 0xFFF1F8E9, // Light green
        'surface': 0xFFFFFFFF, // White
        'accent': 0xFFFF9800, // Orange
      },
      iconSet: {
        'event': 'pets',
        'photo': 'photo_camera',
        'story': 'menu_book',
        'location': 'location_on',
        'weight': 'monitor_weight',
        'vet': 'local_hospital',
      },
      typography: {
        'headline': {'fontSize': 24.0, 'fontWeight': 'bold'},
        'body': {'fontSize': 16.0, 'fontWeight': 'normal'},
        'caption': {'fontSize': 12.0, 'fontWeight': 'normal'},
      },
      widgetFactories: {
        'milestoneCard': true,
        'weightCard': true,
        'vetCard': true,
        'photoGrid': true,
        'progressComparison': true,
      },
      enableGhostCamera: true,
      enableBudgetTracking: false,
      enableProgressComparison: true,
    );
  }

  factory TimelineTheme._renovation() {
    return const TimelineTheme(
      id: 'renovation_theme',
      name: 'Renovation',
      contextType: ContextType.project,
      colorPalette: {
        'primary': 0xFFFF9800, // Orange
        'secondary': 0xFF795548, // Brown
        'background': 0xFFFFF3E0, // Light orange
        'surface': 0xFFFFFFFF, // White
        'accent': 0xFF607D8B, // Blue grey
      },
      iconSet: {
        'event': 'construction',
        'photo': 'photo_camera',
        'story': 'description',
        'location': 'home',
        'cost': 'attach_money',
        'progress': 'trending_up',
      },
      typography: {
        'headline': {'fontSize': 24.0, 'fontWeight': 'bold'},
        'body': {'fontSize': 16.0, 'fontWeight': 'normal'},
        'caption': {'fontSize': 12.0, 'fontWeight': 'normal'},
      },
      widgetFactories: {
        'milestoneCard': true,
        'costCard': true,
        'progressCard': true,
        'photoGrid': true,
        'beforeAfterComparison': true,
      },
      enableGhostCamera: true,
      enableBudgetTracking: true,
      enableProgressComparison: true,
    );
  }

  factory TimelineTheme._business() {
    return const TimelineTheme(
      id: 'business_theme',
      name: 'Business',
      contextType: ContextType.business,
      colorPalette: {
        'primary': 0xFF3F51B5, // Indigo
        'secondary': 0xFF9C27B0, // Purple
        'background': 0xFFF3E5F5, // Light purple
        'surface': 0xFFFFFFFF, // White
        'accent': 0xFF009688, // Teal
      },
      iconSet: {
        'event': 'business',
        'photo': 'photo',
        'story': 'article',
        'location': 'business_center',
        'revenue': 'trending_up',
        'team': 'group',
      },
      typography: {
        'headline': {'fontSize': 24.0, 'fontWeight': 'bold'},
        'body': {'fontSize': 16.0, 'fontWeight': 'normal'},
        'caption': {'fontSize': 12.0, 'fontWeight': 'normal'},
      },
      widgetFactories: {
        'milestoneCard': true,
        'revenueCard': true,
        'teamCard': true,
        'photoGrid': true,
        'metricsDashboard': true,
      },
      enableGhostCamera: false,
      enableBudgetTracking: true,
      enableProgressComparison: false,
    );
  }

  /// Gets a color from the palette
  Color getColor(String colorName) {
    final colorValue = colorPalette[colorName];
    if (colorValue == null) {
      return Colors.grey; // Fallback color
    }
    return Color(colorValue);
  }

  /// Gets an icon from the icon set
  IconData getIcon(String iconName) {
    final iconString = iconSet[iconName];
    if (iconString == null) {
      return Icons.help_outline; // Fallback icon
    }
    // In a real implementation, you'd have a mapping from strings to IconData
    // For now, return a default icon
    return Icons.help_outline;
  }

  /// Checks if a widget type is enabled for this theme
  bool isWidgetEnabled(String widgetType) {
    return widgetFactories[widgetType] ?? false;
  }

  TimelineTheme copyWith({
    String? id,
    String? name,
    ContextType? contextType,
    Map<String, int>? colorPalette,
    Map<String, String>? iconSet,
    Map<String, Map<String, dynamic>>? typography,
    Map<String, bool>? widgetFactories,
    bool? enableGhostCamera,
    bool? enableBudgetTracking,
    bool? enableProgressComparison,
  }) {
    return TimelineTheme(
      id: id ?? this.id,
      name: name ?? this.name,
      contextType: contextType ?? this.contextType,
      colorPalette: colorPalette ?? this.colorPalette,
      iconSet: iconSet ?? this.iconSet,
      typography: typography ?? this.typography,
      widgetFactories: widgetFactories ?? this.widgetFactories,
      enableGhostCamera: enableGhostCamera ?? this.enableGhostCamera,
      enableBudgetTracking: enableBudgetTracking ?? this.enableBudgetTracking,
      enableProgressComparison: enableProgressComparison ?? this.enableProgressComparison,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TimelineTheme &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          contextType == other.contextType &&
          _mapEquals(colorPalette, other.colorPalette) &&
          _mapEquals(iconSet, other.iconSet) &&
          _mapEquals(typography, other.typography) &&
          _mapEquals(widgetFactories, other.widgetFactories) &&
          enableGhostCamera == other.enableGhostCamera &&
          enableBudgetTracking == other.enableBudgetTracking &&
          enableProgressComparison == other.enableProgressComparison;

  @override
  int get hashCode =>
      id.hashCode ^
      name.hashCode ^
      contextType.hashCode ^
      colorPalette.hashCode ^
      iconSet.hashCode ^
      typography.hashCode ^
      widgetFactories.hashCode ^
      enableGhostCamera.hashCode ^
      enableBudgetTracking.hashCode ^
      enableProgressComparison.hashCode;

  bool _mapEquals<K, V>(Map<K, V>? a, Map<K, V>? b) {
    if (a == null) return b == null;
    if (b == null || a.length != b.length) return false;
    for (final K key in a.keys) {
      if (!b.containsKey(key) || b[key] != a[key]) return false;
    }
    return true;
  }
}