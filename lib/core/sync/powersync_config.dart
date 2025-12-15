import 'package:powersync/powersync.dart';

/// PowerSync configuration for Family-First MVP
/// 
/// Sync Rules:
/// - Events with isPrivate = false → sync to family group
/// - Events with isPrivate = true → local only (never synced)
class PowerSyncConfig {
  /// PowerSync database instance
  static PowerSyncDatabase? _db;

  /// Initialize PowerSync with family sync rules
  static Future<PowerSyncDatabase> initialize({
    required String supabaseUrl,
    required String supabaseAnonKey,
    required String powerSyncUrl,
  }) async {
    if (_db != null) return _db!;

    // Create PowerSync schema
    final schema = Schema([
      // Timeline events table
      Table('timeline_events', [
        Column.text('id'),
        Column.text('tags'),
        Column.text('owner_id'),
        Column.integer('timestamp'),
        Column.text('fuzzy_date'),
        Column.text('location'),
        Column.text('event_type'),
        Column.text('custom_attributes'),
        Column.text('title'),
        Column.text('description'),
        Column.text('participant_ids'),
        Column.integer('is_private'),
        Column.integer('created_at'),
        Column.integer('updated_at'),
      ], indexes: [
        Index('owner_idx', [IndexedColumn('owner_id')]),
        Index('timestamp_idx', [IndexedColumn('timestamp')]),
        Index('private_idx', [IndexedColumn('is_private')]),
      ]),

      // Media assets table
      Table('media_assets', [
        Column.text('id'),
        Column.text('event_id'),
        Column.text('type'),
        Column.text('local_path'),
        Column.text('cloud_url'),
        Column.text('exif_data'),
        Column.text('caption'),
        Column.integer('created_at'),
        Column.integer('is_key_asset'),
        Column.integer('width'),
        Column.integer('height'),
        Column.integer('file_size_bytes'),
        Column.text('mime_type'),
      ], indexes: [
        Index('event_idx', [IndexedColumn('event_id')]),
      ]),

      // Stories table
      Table('stories', [
        Column.text('id'),
        Column.text('event_id'),
        Column.text('author_id'),
        Column.text('blocks'),
        Column.integer('created_at'),
        Column.integer('updated_at'),
        Column.integer('version'),
        Column.text('collaborator_ids'),
      ], indexes: [
        Index('event_idx', [IndexedColumn('event_id')]),
      ]),
    ]);

    // Initialize PowerSync
    _db = PowerSyncDatabase(
      schema: schema,
      path: 'powersync.db',
    );

    await _db!.initialize();

    return _db!;
  }

  /// Get the PowerSync database instance
  static PowerSyncDatabase get database {
    if (_db == null) {
      throw Exception('PowerSync not initialized. Call initialize() first.');
    }
    return _db!;
  }

  /// Sync rules for family sharing
  /// 
  /// Only sync events where is_private = 0 (false)
  static String get syncRules => '''
    # Family-First MVP Sync Rules
    # Only sync non-private events to family group
    
    bucket_definitions:
      family_events:
        # Sync timeline events that are not private
        SELECT * FROM timeline_events WHERE is_private = 0
        
      family_media:
        # Sync media assets for non-private events
        SELECT ma.* FROM media_assets ma
        INNER JOIN timeline_events te ON ma.event_id = te.id
        WHERE te.is_private = 0
        
      family_stories:
        # Sync stories for non-private events
        SELECT s.* FROM stories s
        INNER JOIN timeline_events te ON s.event_id = te.id
        WHERE te.is_private = 0
  ''';

  /// Check if an event should be synced
  static bool shouldSync(bool isPrivate) {
    return !isPrivate;
  }

  /// Get sync status for an event
  static Future<SyncStatus> getSyncStatus(String eventId) async {
    final db = database;
    
    // Query the event
    final result = await db.execute(
      'SELECT is_private FROM timeline_events WHERE id = ?',
      [eventId],
    );

    if (result.isEmpty) {
      return SyncStatus.notFound;
    }

    final isPrivate = result.first['is_private'] == 1;
    
    if (isPrivate) {
      return SyncStatus.localOnly;
    }

    // Check if synced (this would need PowerSync sync status API)
    // For now, assume non-private events are synced
    return SyncStatus.synced;
  }

  /// Close PowerSync connection
  static Future<void> close() async {
    await _db?.close();
    _db = null;
  }
}

/// Sync status for events
enum SyncStatus {
  /// Event not found
  notFound,
  
  /// Event is private and stays local only
  localOnly,
  
  /// Event is syncing to family group
  syncing,
  
  /// Event is synced to family group
  synced,
  
  /// Sync error occurred
  error,
}

/// PowerSync connector for Supabase backend
class SupabasePowerSyncConnector {
  final String supabaseUrl;
  final String supabaseAnonKey;
  final String powerSyncUrl;

  SupabasePowerSyncConnector({
    required this.supabaseUrl,
    required this.supabaseAnonKey,
    required this.powerSyncUrl,
  });

  /// Connect to PowerSync backend
  Future<void> connect() async {
    // TODO: Implement Supabase authentication
    // TODO: Configure PowerSync endpoint
    // TODO: Start sync process
    
    print('🔄 PowerSync: Connecting to backend...');
    print('   Supabase URL: $supabaseUrl');
    print('   PowerSync URL: $powerSyncUrl');
  }

  /// Disconnect from PowerSync backend
  Future<void> disconnect() async {
    print('🔄 PowerSync: Disconnecting...');
  }
}

/// Example usage:
/// 
/// ```dart
/// // Initialize PowerSync
/// await PowerSyncConfig.initialize(
///   supabaseUrl: 'https://your-project.supabase.co',
///   supabaseAnonKey: 'your-anon-key',
///   powerSyncUrl: 'https://your-powersync-instance.powersync.com',
/// );
/// 
/// // Check if event should sync
/// final shouldSync = PowerSyncConfig.shouldSync(event.isPrivate);
/// 
/// // Get sync status
/// final status = await PowerSyncConfig.getSyncStatus(eventId);
/// ```
