import '../../shared/models/context.dart';
import '../../shared/models/timeline_theme.dart';

/// Factory for creating contexts with extensible configuration
class ContextFactory {
  static final Map<ContextType, ContextConfiguration> _configurations = {
    ContextType.person: ContextConfiguration(
      defaultModuleConfiguration: {
        'enableGhostCamera': false,
        'enableBudgetTracking': false,
        'enableProgressComparison': false,
        'enableMilestoneTracking': true,
        'enableLocationTracking': true,
        'enableFaceDetection': true,
      },
      defaultThemeId: 'personal_theme',
      supportedEventTypes: ['photo', 'text', 'mixed', 'milestone'],
    ),
    ContextType.pet: ContextConfiguration(
      defaultModuleConfiguration: {
        'enableGhostCamera': true,
        'enableBudgetTracking': false,
        'enableProgressComparison': true,
        'enableMilestoneTracking': true,
        'enableWeightTracking': true,
        'enableVetVisitTracking': true,
      },
      defaultThemeId: 'pet_theme',
      supportedEventTypes: ['photo', 'text', 'mixed', 'pet_milestone'],
    ),
    ContextType.project: ContextConfiguration(
      defaultModuleConfiguration: {
        'enableGhostCamera': true,
        'enableBudgetTracking': true,
        'enableProgressComparison': true,
        'enableMilestoneTracking': true,
        'enableTaskTracking': true,
        'enableTeamTracking': true,
      },
      defaultThemeId: 'renovation_theme',
      supportedEventTypes: ['photo', 'text', 'mixed', 'renovation_progress'],
    ),
    ContextType.business: ContextConfiguration(
      defaultModuleConfiguration: {
        'enableGhostCamera': false,
        'enableBudgetTracking': true,
        'enableProgressComparison': false,
        'enableMilestoneTracking': true,
        'enableRevenueTracking': true,
        'enableTeamTracking': true,
      },
      defaultThemeId: 'business_theme',
      supportedEventTypes: ['photo', 'text', 'mixed', 'business_milestone'],
    ),
  };

  /// Creates a new context with appropriate configuration
  static Context createContext({
    required String id,
    required String ownerId,
    required ContextType type,
    required String name,
    String? description,
    Map<String, dynamic>? customModuleConfiguration,
    String? customThemeId,
  }) {
    final configuration = _configurations[type];
    if (configuration == null) {
      throw ArgumentError('Unsupported context type: $type');
    }

    final moduleConfiguration = customModuleConfiguration ?? 
        Map<String, dynamic>.from(configuration.defaultModuleConfiguration);
    
    final themeId = customThemeId ?? configuration.defaultThemeId;

    return Context.create(
      id: id,
      ownerId: ownerId,
      type: type,
      name: name,
      description: description,
    ).copyWith(
      moduleConfiguration: moduleConfiguration,
      themeId: themeId,
    );
  }

  /// Gets the configuration for a context type
  static ContextConfiguration? getConfiguration(ContextType type) {
    return _configurations[type];
  }

  /// Gets all available context types
  static List<ContextType> getAvailableContextTypes() {
    return _configurations.keys.toList();
  }

  /// Gets supported event types for a context type
  static List<String> getSupportedEventTypes(ContextType contextType) {
    final configuration = _configurations[contextType];
    return configuration?.supportedEventTypes ?? ['photo', 'text', 'mixed'];
  }

  /// Registers a new context type (for future extensibility)
  static void registerContextType({
    required ContextType type,
    required ContextConfiguration configuration,
  }) {
    _configurations[type] = configuration;
  }

  /// Updates the configuration for an existing context type
  static void updateContextConfiguration({
    required ContextType type,
    required ContextConfiguration configuration,
  }) {
    if (!_configurations.containsKey(type)) {
      throw ArgumentError('Context type $type is not registered');
    }
    _configurations[type] = configuration;
  }

  /// Creates a context with validation
  static Context createValidatedContext({
    required String id,
    required String ownerId,
    required ContextType type,
    required String name,
    String? description,
    Map<String, dynamic>? customModuleConfiguration,
    String? customThemeId,
  }) {
    // Validate that the context type is supported
    if (!_configurations.containsKey(type)) {
      throw ArgumentError('Context type $type is not supported');
    }

    // Validate custom module configuration if provided
    if (customModuleConfiguration != null) {
      _validateModuleConfiguration(type, customModuleConfiguration);
    }

    return createContext(
      id: id,
      ownerId: ownerId,
      type: type,
      name: name,
      description: description,
      customModuleConfiguration: customModuleConfiguration,
      customThemeId: customThemeId,
    );
  }

  /// Validates module configuration for a context type
  static void _validateModuleConfiguration(ContextType type, Map<String, dynamic> moduleConfiguration) {
    final configuration = _configurations[type]!;
    final defaultConfig = configuration.defaultModuleConfiguration;

    // Check for unknown configuration keys
    for (final key in moduleConfiguration.keys) {
      if (!defaultConfig.containsKey(key)) {
        throw ArgumentError('Unknown module configuration key "$key" for context type $type');
      }
    }

    // Validate configuration values
    for (final entry in moduleConfiguration.entries) {
      final key = entry.key;
      final value = entry.value;
      final defaultValue = defaultConfig[key];

      // Check type compatibility
      if (defaultValue != null && value.runtimeType != defaultValue.runtimeType) {
        throw ArgumentError('Module configuration "$key" must be of type ${defaultValue.runtimeType}');
      }
    }
  }
}

/// Configuration for a context type
class ContextConfiguration {
  final Map<String, dynamic> defaultModuleConfiguration;
  final String defaultThemeId;
  final List<String> supportedEventTypes;

  const ContextConfiguration({
    required this.defaultModuleConfiguration,
    required this.defaultThemeId,
    required this.supportedEventTypes,
  });

  ContextConfiguration copyWith({
    Map<String, dynamic>? defaultModuleConfiguration,
    String? defaultThemeId,
    List<String>? supportedEventTypes,
  }) {
    return ContextConfiguration(
      defaultModuleConfiguration: defaultModuleConfiguration ?? this.defaultModuleConfiguration,
      defaultThemeId: defaultThemeId ?? this.defaultThemeId,
      supportedEventTypes: supportedEventTypes ?? this.supportedEventTypes,
    );
  }
}