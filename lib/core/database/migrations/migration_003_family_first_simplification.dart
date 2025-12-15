import 'package:sqflite/sqflite.dart';
import 'migration_runner.dart';

/// Migration 003: Family-First MVP Simplification
/// 
/// This migration simplifies the database schema by:
/// 1. Replacing context_id with tags (JSON array)
/// 2. Replacing privacy_level (enum) with is_private (boolean)
/// 3. Migrating existing data to new schema
class Migration003FamilyFirstSimplification extends Migration {
  @override
  int get version => 3;

  @override
  String get description => 'Simplify schema for Family-First MVP: replace context_id with tags, privacy_level with is_private';

  @override
  Future<void> up(Database db) async {
    // Step 1: Add new columns to timeline_events
    await db.execute('''
      ALTER TABLE timeline_events 
      ADD COLUMN tags TEXT DEFAULT '["Family"]'
    ''');

    await db.execute('''
      ALTER TABLE timeline_events 
      ADD COLUMN is_private INTEGER DEFAULT 1
    ''');

    // Step 2: Migrate privacy_level to is_private
    // private -> 1 (true), shared/public -> 0 (false)
    await db.execute('''
      UPDATE timeline_events 
      SET is_private = CASE 
        WHEN privacy_level = 'private' THEN 1 
        ELSE 0 
      END
    ''');

    // Step 3: Migrate context_id to tags
    // Get all contexts and create tags from context names
    final contexts = await db.query('contexts', columns: ['id', 'name', 'type']);
    final contextMap = {for (var c in contexts) c['id'] as String: c};

    // Update each event with tag based on its context
    final events = await db.query('timeline_events', columns: ['id', 'context_id']);
    
    for (final event in events) {
      final eventId = event['id'] as String;
      final contextId = event['context_id'] as String?;
      
      if (contextId != null && contextMap.containsKey(contextId)) {
        final context = contextMap[contextId]!;
        final contextName = context['name'] as String;
        final contextType = context['type'] as String;
        
        // Create tags based on context
        final tags = <String>['Family'];
        
        // Add context name as tag if it's meaningful
        if (contextName.isNotEmpty && contextName != 'Default') {
          tags.add(contextName);
        }
        
        // Add type-based tag
        switch (contextType) {
          case 'pet':
            if (!tags.contains('Pets')) tags.add('Pets');
            break;
          case 'project':
            if (!tags.contains('Projects')) tags.add('Projects');
            break;
          case 'business':
            if (!tags.contains('Work')) tags.add('Work');
            break;
        }
        
        // Update event with tags
        await db.update(
          'timeline_events',
          {'tags': '${tags.map((t) => '"$t"').toList()}'},
          where: 'id = ?',
          whereArgs: [eventId],
        );
      } else {
        // No context found, use default
        await db.update(
          'timeline_events',
          {'tags': '["Family"]'},
          where: 'id = ?',
          whereArgs: [eventId],
        );
      }
    }

    // Step 4: Create temporary table without old columns
    await db.execute('''
      CREATE TABLE timeline_events_new (
        id TEXT PRIMARY KEY,
        tags TEXT NOT NULL DEFAULT '["Family"]',
        owner_id TEXT NOT NULL,
        timestamp INTEGER NOT NULL,
        fuzzy_date TEXT,
        location TEXT,
        event_type TEXT NOT NULL,
        custom_attributes TEXT NOT NULL,
        title TEXT,
        description TEXT,
        participant_ids TEXT NOT NULL,
        is_private INTEGER NOT NULL DEFAULT 1,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        FOREIGN KEY (owner_id) REFERENCES users (id) ON DELETE CASCADE
      )
    ''');

    // Step 5: Copy data to new table
    await db.execute('''
      INSERT INTO timeline_events_new 
      (id, tags, owner_id, timestamp, fuzzy_date, location, event_type, 
       custom_attributes, title, description, participant_ids, is_private, 
       created_at, updated_at)
      SELECT 
        id, tags, owner_id, timestamp, fuzzy_date, location, event_type,
        custom_attributes, title, description, participant_ids, is_private,
        created_at, updated_at
      FROM timeline_events
    ''');

    // Step 6: Drop old table and rename new one
    await db.execute('DROP TABLE timeline_events');
    await db.execute('ALTER TABLE timeline_events_new RENAME TO timeline_events');

    // Step 7: Recreate indexes
    await db.execute('CREATE INDEX idx_timeline_events_owner_id ON timeline_events (owner_id)');
    await db.execute('CREATE INDEX idx_timeline_events_timestamp ON timeline_events (timestamp)');
    await db.execute('CREATE INDEX idx_timeline_events_event_type ON timeline_events (event_type)');
    await db.execute('CREATE INDEX idx_timeline_events_is_private ON timeline_events (is_private)');

    // Step 8: Update media_assets foreign key (recreate table)
    await db.execute('''
      CREATE TABLE media_assets_new (
        id TEXT PRIMARY KEY,
        event_id TEXT NOT NULL,
        type TEXT NOT NULL,
        local_path TEXT NOT NULL,
        cloud_url TEXT,
        exif_data TEXT,
        caption TEXT,
        created_at INTEGER NOT NULL,
        is_key_asset INTEGER NOT NULL DEFAULT 0,
        width INTEGER,
        height INTEGER,
        file_size_bytes INTEGER,
        mime_type TEXT,
        FOREIGN KEY (event_id) REFERENCES timeline_events (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      INSERT INTO media_assets_new 
      SELECT * FROM media_assets
    ''');

    await db.execute('DROP TABLE media_assets');
    await db.execute('ALTER TABLE media_assets_new RENAME TO media_assets');
    await db.execute('CREATE INDEX idx_media_assets_event_id ON media_assets (event_id)');

    // Step 9: Update stories foreign key (recreate table)
    await db.execute('''
      CREATE TABLE stories_new (
        id TEXT PRIMARY KEY,
        event_id TEXT NOT NULL,
        author_id TEXT NOT NULL,
        blocks TEXT NOT NULL,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        version INTEGER NOT NULL DEFAULT 1,
        collaborator_ids TEXT,
        FOREIGN KEY (event_id) REFERENCES timeline_events (id) ON DELETE CASCADE,
        FOREIGN KEY (author_id) REFERENCES users (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      INSERT INTO stories_new 
      SELECT * FROM stories
    ''');

    await db.execute('DROP TABLE stories');
    await db.execute('ALTER TABLE stories_new RENAME TO stories');
    await db.execute('CREATE INDEX idx_stories_event_id ON stories (event_id)');

    print('✅ Migration 003: Successfully migrated to Family-First MVP schema');
    print('   - Replaced context_id with tags');
    print('   - Replaced privacy_level with is_private');
    print('   - Migrated ${events.length} events');
  }

  @override
  Future<void> down(Database db) async {
    // Rollback is complex because we've lost context relationships
    // For safety, this should only be used in development
    throw UnimplementedError(
      'Rollback of Migration 003 is not supported. '
      'This is a one-way migration from enterprise to MVP schema.'
    );
  }
}
