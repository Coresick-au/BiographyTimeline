import 'dart:async';
import 'package:sqflite/sqflite.dart';
import '../../../core/database/database.dart';
import '../../../shared/models/context.dart';
import '../../../shared/models/timeline_theme.dart';

/// Service for managing timeline contexts and their configurations
class ContextManagementService {
  /// This is the sqflite database connection (type is from package:sqflite)
  final Database _database;
  final StreamController<List<Context>> _contextsController = StreamController<List<Context>>.broadcast();

  ContextManagementService(this._database);

  /// Stream of all contexts for the current user
  Stream<List<Context>> get contextsStream => _contextsController.stream;

  /// Creates a new context with the specified type and configuration
  Future<Context> createContext({
    required String ownerId,
    required ContextType type,
    required String name,
    String? description,
  }) async {
    final context = Context.create(
      id: _generateId(),
      ownerId: ownerId,
      type: type,
      name: name,
      description: description,
    );

    await _database.insertContext(context);
    await _refreshContexts(ownerId);
    
    return context;
  }

  /// Gets all contexts for a user
  Future<List<Context>> getContextsForUser(String userId) async {
    return await _database.getContextsForUser(userId);
  }

  /// Gets a specific context by ID
  Future<Context?> getContext(String contextId) async {
    return await _database.getContext(contextId);
  }

  /// Updates a context's configuration
  Future<Context> updateContext(Context context) async {
    final updatedContext = context.copyWith(updatedAt: DateTime.now());
    await _database.updateContext(updatedContext);
    await _refreshContexts(context.ownerId);
    return updatedContext;
  }

  /// Updates module configuration for a context
  Future<Context> updateModuleConfiguration(
    String contextId,
    Map<String, dynamic> moduleConfiguration,
  ) async {
    final context = await getContext(contextId);
    if (context == null) {
      throw Exception('Context not found: $contextId');
    }

    final updatedContext = context.copyWith(
      moduleConfiguration: moduleConfiguration,
      updatedAt: DateTime.now(),
    );

    await _database.updateContext(updatedContext);
    await _refreshContexts(context.ownerId);
    return updatedContext;
  }

  /// Deletes a context and all associated data
  Future<void> deleteContext(String contextId) async {
    final context = await getContext(contextId);
    if (context == null) {
      throw Exception('Context not found: $contextId');
    }

    await _database.deleteContext(contextId);
    await _refreshContexts(context.ownerId);
  }

  /// Gets the theme for a context
  Future<TimelineTheme> getThemeForContext(String contextId) async {
    final context = await getContext(contextId);
    if (context == null) {
      throw Exception('Context not found: $contextId');
    }

    return TimelineTheme.forContextType(context.type);
  }

  /// Checks if a feature is enabled for a context
  Future<bool> isFeatureEnabled(String contextId, String featureName) async {
    final context = await getContext(contextId);
    if (context == null) {
      return false;
    }

    return context.moduleConfiguration[featureName] == true;
  }

  /// Gets available context types
  List<ContextType> getAvailableContextTypes() {
    return ContextType.values;
  }

  /// Gets default configuration for a context type
  ///
  /// IMPORTANT: this calls a *public* API on Context.
  /// If your Context model currently only has `_getDefaultModuleConfiguration`,
  /// add a public wrapper there (see note below).
  Map<String, dynamic> getDefaultConfigurationForType(ContextType type) {
    return Context.getDefaultModuleConfiguration(type);
  }

  /// Refreshes the contexts stream
  Future<void> _refreshContexts(String userId) async {
    final contexts = await getContextsForUser(userId);
    _contextsController.add(contexts);
  }

  /// Generates a unique ID for contexts
  String _generateId() {
    return DateTime.now().millisecondsSinceEpoch.toString();
  }

  /// Disposes of resources
  void dispose() {
    _contextsController.close();
  }
}

/// Extension to add context-related database operations
///
/// This extends the sqflite `Database` connection with your app-specific helpers.
extension ContextDatabase on Database {
  Future<void> insertContext(Context context) async {
    await insert(
      'contexts',
      {
        'id': context.id,
        'owner_id': context.ownerId,
        'type': context.type.name,
        'name': context.name,
        'description': context.description,
        'module_configuration': DatabaseJsonHelper.mapToJson(context.moduleConfiguration),
        'theme_id': context.themeId,
        'created_at': context.createdAt.millisecondsSinceEpoch,
        'updated_at': context.updatedAt.millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Context>> getContextsForUser(String userId) async {
    final maps = await query(
      'contexts',
      where: 'owner_id = ?',
      whereArgs: [userId],
      orderBy: 'created_at DESC',
    );

    return maps.map(_mapToContext).toList();
  }

  Future<Context?> getContext(String contextId) async {
    final maps = await query(
      'contexts',
      where: 'id = ?',
      whereArgs: [contextId],
    );

    if (maps.isEmpty) return null;

    return _mapToContext(maps.first);
  }

  Future<void> updateContext(Context context) async {
    await update(
      'contexts',
      {
        'owner_id': context.ownerId,
        'type': context.type.name,
        'name': context.name,
        'description': context.description,
        'module_configuration': DatabaseJsonHelper.mapToJson(context.moduleConfiguration),
        'theme_id': context.themeId,
        'updated_at': context.updatedAt.millisecondsSinceEpoch,
      },
      where: 'id = ?',
      whereArgs: [context.id],
    );
  }

  Future<void> deleteContext(String contextId) async {
    await delete(
      'contexts',
      where: 'id = ?',
      whereArgs: [contextId],
    );
  }

  /// Maps a database row to a Context object
  Context _mapToContext(Map<String, dynamic> map) {
    return Context(
      id: map['id'] as String,
      ownerId: map['owner_id'] as String,
      type: ContextType.values.firstWhere(
        (type) => type.name == map['type'] as String,
        orElse: () => ContextType.person,
      ),
      name: map['name'] as String,
      description: map['description'] as String?,
      moduleConfiguration: DatabaseJsonHelper.jsonToMap(map['module_configuration'] as String),
      themeId: map['theme_id'] as String,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updated_at'] as int),
    );
  }
}