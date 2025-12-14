import 'package:sqflite/sqflite.dart';
import 'migration_runner.dart';

class Migration002CustomTemplates extends Migration {
  @override
  int get version => 2;

  @override
  String get description => 'Create custom_templates table for storing user-defined templates';

  @override
  Future<void> up(Database db) async {
    // Create custom_templates table
    await db.execute('''
      CREATE TABLE custom_templates (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        description TEXT,
        context_type TEXT NOT NULL,
        author TEXT NOT NULL,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        template_json TEXT NOT NULL,
        version TEXT NOT NULL DEFAULT '1.0.0',
        tags TEXT NOT NULL, -- JSON array
        is_active INTEGER NOT NULL DEFAULT 1
      )
    ''');

    // Create indexes for performance
    await db.execute('CREATE INDEX idx_custom_templates_context_type ON custom_templates (context_type)');
    await db.execute('CREATE INDEX idx_custom_templates_author ON custom_templates (author)');
    await db.execute('CREATE INDEX idx_custom_templates_active ON custom_templates (is_active)');
    await db.execute('CREATE INDEX idx_custom_templates_created_at ON custom_templates (created_at)');
  }

  @override
  Future<void> down(Database db) async {
    // Drop the custom_templates table
    await db.execute('DROP TABLE IF EXISTS custom_templates');
  }
}
