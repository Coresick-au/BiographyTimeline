/// Example usage of the ContextManagementService
/// 
/// This file demonstrates how to use the updated ContextManagementService
/// with the sqflite Database connection.

import 'package:sqflite/sqflite.dart';
import '../../../core/database/database.dart';
import '../../../shared/models/context.dart';
import '../services/context_management_service.dart';

/// Example class showing how to use ContextManagementService
class ContextServiceExample {
  late ContextManagementService _contextService;

  /// Initialize the service with database connection
  Future<void> initialize() async {
    // Get the sqflite database connection
    final Database db = await AppDatabase.database;
    
    // Create the context management service
    _contextService = ContextManagementService(db);
  }

  /// Example: Create a new pet context
  Future<Context> createPetContext(String ownerId) async {
    return await _contextService.createContext(
      ownerId: ownerId,
      type: ContextType.pet,
      name: 'My Pet Timeline',
      description: 'Tracking my pet\'s growth and milestones',
    );
  }

  /// Example: Create a renovation project context
  Future<Context> createRenovationContext(String ownerId) async {
    return await _contextService.createContext(
      ownerId: ownerId,
      type: ContextType.project,
      name: 'Kitchen Renovation',
      description: 'Complete kitchen remodel project',
    );
  }

  /// Example: Check if Ghost Camera is enabled for a context
  Future<bool> isGhostCameraEnabled(String contextId) async {
    return await _contextService.isFeatureEnabled(contextId, 'enableGhostCamera');
  }

  /// Example: Update module configuration
  Future<Context> enableBudgetTracking(String contextId) async {
    final context = await _contextService.getContext(contextId);
    if (context == null) {
      throw Exception('Context not found');
    }

    final updatedConfig = Map<String, dynamic>.from(context.moduleConfiguration);
    updatedConfig['enableBudgetTracking'] = true;

    return await _contextService.updateModuleConfiguration(contextId, updatedConfig);
  }

  /// Example: Get default configuration for a context type
  Map<String, dynamic> getDefaultPetConfiguration() {
    return _contextService.getDefaultConfigurationForType(ContextType.pet);
  }

  /// Example: Listen to context changes
  void listenToContextChanges() {
    _contextService.contextsStream.listen((contexts) {
      print('Contexts updated: ${contexts.length} contexts available');
      for (final context in contexts) {
        print('- ${context.name} (${context.type})');
      }
    });
  }

  /// Clean up resources
  void dispose() {
    _contextService.dispose();
  }
}

/// Static helper methods for common operations
class ContextServiceHelpers {
  /// Create a service instance
  static Future<ContextManagementService> createService() async {
    final db = await AppDatabase.database;
    return ContextManagementService(db);
  }

  /// Get all available context types with their default configurations
  static Map<ContextType, Map<String, dynamic>> getAllDefaultConfigurations() {
    final result = <ContextType, Map<String, dynamic>>{};
    
    for (final type in ContextType.values) {
      result[type] = Context.getDefaultModuleConfiguration(type);
    }
    
    return result;
  }

  /// Check if a context type supports a specific feature
  static bool doesContextTypeSupportFeature(ContextType type, String featureName) {
    final config = Context.getDefaultModuleConfiguration(type);
    return config.containsKey(featureName) && config[featureName] == true;
  }
}