import 'package:sqflite/sqflite.dart';
import '../../../core/database/database.dart';
import '../../../shared/models/context.dart';
import '../services/context_management_service.dart';

/// Simple example showing how to use ContextManagementService
class SimpleContextExample {
  /// Example of creating and using the service
  static Future<void> demonstrateUsage() async {
    // Step 1: Get the database connection
    final Database db = await AppDatabase.database;
    
    // Step 2: Create the service
    final service = ContextManagementService(db);
    
    // Step 3: Create a new pet context
    final petContext = await service.createContext(
      ownerId: 'user123',
      type: ContextType.pet,
      name: 'Buddy\'s Timeline',
      description: 'Tracking my dog Buddy\'s adventures',
    );
    
    print('Created pet context: ${petContext.name}');
    print('Ghost Camera enabled: ${await service.isFeatureEnabled(petContext.id, 'enableGhostCamera')}');
    
    // Step 4: Create a renovation project context
    final projectContext = await service.createContext(
      ownerId: 'user123',
      type: ContextType.project,
      name: 'Kitchen Renovation 2024',
      description: 'Complete kitchen remodel project',
    );
    
    print('Created project context: ${projectContext.name}');
    print('Budget tracking enabled: ${await service.isFeatureEnabled(projectContext.id, 'enableBudgetTracking')}');
    
    // Step 5: Get all contexts for the user
    final userContexts = await service.getContextsForUser('user123');
    print('User has ${userContexts.length} contexts');
    
    // Step 6: Update module configuration
    await service.updateModuleConfiguration(
      petContext.id,
      {
        ...petContext.moduleConfiguration,
        'enableBudgetTracking': true, // Enable budget tracking for pet expenses
      },
    );
    
    print('Updated pet context to enable budget tracking');
    
    // Step 7: Get theme for context
    final theme = await service.getThemeForContext(petContext.id);
    print('Pet context theme: ${theme.name}');
    
    // Step 8: Clean up
    service.dispose();
  }
  
  /// Example of checking default configurations
  static void demonstrateDefaultConfigurations() {
    print('Default configurations for each context type:');
    
    for (final contextType in ContextType.values) {
      final defaults = Context.getDefaultModuleConfiguration(contextType);
      print('\n${contextType.name.toUpperCase()} Context:');
      
      defaults.forEach((feature, enabled) {
        print('  $feature: $enabled');
      });
    }
  }
  
  /// Example of available context types
  static void demonstrateAvailableTypes() {
    final service = ContextManagementService(null as dynamic); // Just for demo
    final types = service.getAvailableContextTypes();
    
    print('Available context types:');
    for (final type in types) {
      print('  - ${type.name}');
    }
  }
}