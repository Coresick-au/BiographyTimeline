import 'package:sqflite/sqflite.dart';
import 'migration_runner.dart';

class Migration001InitialSchema extends Migration {
  @override
  int get version => 1;

  @override
  String get description => 'Create initial polymorphic schema with contexts, users, events, and relationships';

  @override
  Future<void> up(Database db) async {
    // Create users table
    await db.execute('''
      CREATE TABLE users (
        id TEXT PRIMARY KEY,
        email TEXT NOT NULL UNIQUE,
        display_name TEXT NOT NULL,
        profile_image_url TEXT,
        privacy_settings TEXT NOT NULL, -- JSON
        context_ids TEXT NOT NULL, -- JSON array
        created_at INTEGER NOT NULL,
        last_active_at INTEGER NOT NULL
      )
    ''');

    // Create contexts table (the polymorphic wrapper)
    await db.execute('''
      CREATE TABLE contexts (
        id TEXT PRIMARY KEY,
        owner_id TEXT NOT NULL,
        type TEXT NOT NULL, -- person, pet, project, business
        name TEXT NOT NULL,
        description TEXT,
        module_configuration TEXT NOT NULL, -- JSON
        theme_id TEXT NOT NULL,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        FOREIGN KEY (owner_id) REFERENCES users (id) ON DELETE CASCADE
      )
    ''');

    // Create timeline_events table (polymorphic with custom_attributes)
    await db.execute('''
      CREATE TABLE timeline_events (
        id TEXT PRIMARY KEY,
        context_id TEXT NOT NULL,
        owner_id TEXT NOT NULL,
        timestamp INTEGER NOT NULL,
        fuzzy_date TEXT, -- JSON
        location TEXT, -- JSON
        event_type TEXT NOT NULL, -- discriminator field
        custom_attributes TEXT NOT NULL, -- JSON for polymorphic data
        title TEXT,
        description TEXT,
        participant_ids TEXT NOT NULL, -- JSON array
        privacy_level TEXT NOT NULL,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        FOREIGN KEY (context_id) REFERENCES contexts (id) ON DELETE CASCADE,
        FOREIGN KEY (owner_id) REFERENCES users (id) ON DELETE CASCADE
      )
    ''');

    // Create media_assets table
    await db.execute('''
      CREATE TABLE media_assets (
        id TEXT PRIMARY KEY,
        event_id TEXT NOT NULL,
        type TEXT NOT NULL, -- photo, video, audio, document
        local_path TEXT NOT NULL,
        cloud_url TEXT,
        exif_data TEXT, -- JSON
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

    // Create stories table
    await db.execute('''
      CREATE TABLE stories (
        id TEXT PRIMARY KEY,
        event_id TEXT NOT NULL,
        author_id TEXT NOT NULL,
        blocks TEXT NOT NULL, -- JSON array
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        version INTEGER NOT NULL DEFAULT 1,
        collaborator_ids TEXT, -- JSON array
        FOREIGN KEY (event_id) REFERENCES timeline_events (id) ON DELETE CASCADE,
        FOREIGN KEY (author_id) REFERENCES users (id) ON DELETE CASCADE
      )
    ''');

    // Create relationships table (cross-context support)
    await db.execute('''
      CREATE TABLE relationships (
        id TEXT PRIMARY KEY,
        user_a_id TEXT NOT NULL,
        user_b_id TEXT NOT NULL,
        type TEXT NOT NULL, -- friend, family, partner, colleague
        shared_context_ids TEXT NOT NULL, -- JSON array
        start_date INTEGER NOT NULL,
        end_date INTEGER,
        status TEXT NOT NULL, -- pending, active, ended, archived
        context_permissions TEXT NOT NULL, -- JSON map of context_id -> permissions
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        FOREIGN KEY (user_a_id) REFERENCES users (id) ON DELETE CASCADE,
        FOREIGN KEY (user_b_id) REFERENCES users (id) ON DELETE CASCADE,
        UNIQUE (user_a_id, user_b_id)
      )
    ''');

    // Create timeline_themes table
    await db.execute('''
      CREATE TABLE timeline_themes (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        context_type TEXT NOT NULL,
        color_palette TEXT NOT NULL, -- JSON
        icon_set TEXT NOT NULL, -- JSON
        typography TEXT NOT NULL, -- JSON
        widget_factories TEXT NOT NULL, -- JSON
        enable_ghost_camera INTEGER NOT NULL DEFAULT 0,
        enable_budget_tracking INTEGER NOT NULL DEFAULT 0,
        enable_progress_comparison INTEGER NOT NULL DEFAULT 0
      )
    ''');

    // Create indexes for performance
    await db.execute('CREATE INDEX idx_contexts_owner_id ON contexts (owner_id)');
    await db.execute('CREATE INDEX idx_contexts_type ON contexts (type)');
    await db.execute('CREATE INDEX idx_timeline_events_context_id ON timeline_events (context_id)');
    await db.execute('CREATE INDEX idx_timeline_events_owner_id ON timeline_events (owner_id)');
    await db.execute('CREATE INDEX idx_timeline_events_timestamp ON timeline_events (timestamp)');
    await db.execute('CREATE INDEX idx_timeline_events_event_type ON timeline_events (event_type)');
    await db.execute('CREATE INDEX idx_media_assets_event_id ON media_assets (event_id)');
    await db.execute('CREATE INDEX idx_stories_event_id ON stories (event_id)');
    await db.execute('CREATE INDEX idx_relationships_user_a_id ON relationships (user_a_id)');
    await db.execute('CREATE INDEX idx_relationships_user_b_id ON relationships (user_b_id)');
    await db.execute('CREATE INDEX idx_relationships_status ON relationships (status)');
    await db.execute('CREATE INDEX idx_timeline_themes_context_type ON timeline_themes (context_type)');

    // Insert default timeline themes
    await _insertDefaultThemes(db);
  }

  @override
  Future<void> down(Database db) async {
    // Drop tables in reverse order to handle foreign key constraints
    await db.execute('DROP TABLE IF EXISTS timeline_themes');
    await db.execute('DROP TABLE IF EXISTS relationships');
    await db.execute('DROP TABLE IF EXISTS stories');
    await db.execute('DROP TABLE IF EXISTS media_assets');
    await db.execute('DROP TABLE IF EXISTS timeline_events');
    await db.execute('DROP TABLE IF EXISTS contexts');
    await db.execute('DROP TABLE IF EXISTS users');
  }

  Future<void> _insertDefaultThemes(Database db) async {
    // Insert default themes for each context type
    final themes = [
      {
        'id': 'personal_theme',
        'name': 'Personal',
        'context_type': 'person',
        'color_palette': '{"primary": 2196F3, "secondary": 03DAC6, "background": FAFAFA, "surface": FFFFFF, "accent": FF5722}',
        'icon_set': '{"event": "event", "photo": "photo", "story": "book", "location": "location_on", "person": "person"}',
        'typography': '{"headline": {"fontSize": 24.0, "fontWeight": "bold"}, "body": {"fontSize": 16.0, "fontWeight": "normal"}, "caption": {"fontSize": 12.0, "fontWeight": "normal"}}',
        'widget_factories': '{"milestoneCard": true, "locationCard": true, "photoGrid": true, "storyCard": true}',
        'enable_ghost_camera': 0,
        'enable_budget_tracking': 0,
        'enable_progress_comparison': 0,
      },
      {
        'id': 'pet_theme',
        'name': 'Pet',
        'context_type': 'pet',
        'color_palette': '{"primary": 4CAF50, "secondary": FFEB3B, "background": F1F8E9, "surface": FFFFFF, "accent": FF9800}',
        'icon_set': '{"event": "pets", "photo": "photo_camera", "story": "menu_book", "location": "location_on", "weight": "monitor_weight", "vet": "local_hospital"}',
        'typography': '{"headline": {"fontSize": 24.0, "fontWeight": "bold"}, "body": {"fontSize": 16.0, "fontWeight": "normal"}, "caption": {"fontSize": 12.0, "fontWeight": "normal"}}',
        'widget_factories': '{"milestoneCard": true, "weightCard": true, "vetCard": true, "photoGrid": true, "progressComparison": true}',
        'enable_ghost_camera': 1,
        'enable_budget_tracking': 0,
        'enable_progress_comparison': 1,
      },
      {
        'id': 'renovation_theme',
        'name': 'Renovation',
        'context_type': 'project',
        'color_palette': '{"primary": FF9800, "secondary": 795548, "background": FFF3E0, "surface": FFFFFF, "accent": 607D8B}',
        'icon_set': '{"event": "construction", "photo": "photo_camera", "story": "description", "location": "home", "cost": "attach_money", "progress": "trending_up"}',
        'typography': '{"headline": {"fontSize": 24.0, "fontWeight": "bold"}, "body": {"fontSize": 16.0, "fontWeight": "normal"}, "caption": {"fontSize": 12.0, "fontWeight": "normal"}}',
        'widget_factories': '{"milestoneCard": true, "costCard": true, "progressCard": true, "photoGrid": true, "beforeAfterComparison": true}',
        'enable_ghost_camera': 1,
        'enable_budget_tracking': 1,
        'enable_progress_comparison': 1,
      },
      {
        'id': 'business_theme',
        'name': 'Business',
        'context_type': 'business',
        'color_palette': '{"primary": 3F51B5, "secondary": 9C27B0, "background": F3E5F5, "surface": FFFFFF, "accent": 009688}',
        'icon_set': '{"event": "business", "photo": "photo", "story": "article", "location": "business_center", "revenue": "trending_up", "team": "group"}',
        'typography': '{"headline": {"fontSize": 24.0, "fontWeight": "bold"}, "body": {"fontSize": 16.0, "fontWeight": "normal"}, "caption": {"fontSize": 12.0, "fontWeight": "normal"}}',
        'widget_factories': '{"milestoneCard": true, "revenueCard": true, "teamCard": true, "photoGrid": true, "metricsDashboard": true}',
        'enable_ghost_camera': 0,
        'enable_budget_tracking': 1,
        'enable_progress_comparison': 0,
      },
    ];

    for (final theme in themes) {
      await db.insert('timeline_themes', theme);
    }
  }
}
