import 'package:sqflite/sqflite.dart';
import 'migration_001_initial_schema.dart';

class MigrationRunner {
  static final List<Migration> _migrations = [
    Migration001InitialSchema(),
  ];

  static Future<void> runMigrations(Database db, int fromVersion, int toVersion) async {
    for (int version = fromVersion + 1; version <= toVersion; version++) {
      final migration = _migrations.firstWhere(
        (m) => m.version == version,
        orElse: () => throw Exception('Migration for version $version not found'),
      );
      
      print('Running migration ${migration.version}: ${migration.description}');
      await migration.up(db);
      print('Migration ${migration.version} completed');
    }
  }

  static Future<void> rollbackMigration(Database db, int version) async {
    final migration = _migrations.firstWhere(
      (m) => m.version == version,
      orElse: () => throw Exception('Migration for version $version not found'),
    );
    
    print('Rolling back migration ${migration.version}: ${migration.description}');
    await migration.down(db);
    print('Migration ${migration.version} rolled back');
  }
}

abstract class Migration {
  int get version;
  String get description;
  
  Future<void> up(Database db);
  Future<void> down(Database db);
}