import 'dart:async';
import 'dart:convert';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'migrations/migration_runner.dart';

class AppDatabase {
  static Database? _database;
  static const String _databaseName = 'users_timeline.db';
  static const int _databaseVersion = 1;

  static Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  static Future<Database> _initDatabase() async {
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, _databaseName);

    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
      onOpen: _onOpen,
    );
  }

  static Future<void> _onCreate(Database db, int version) async {
    await MigrationRunner.runMigrations(db, 0, version);
  }

  static Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    await MigrationRunner.runMigrations(db, oldVersion, newVersion);
  }

  static Future<void> _onOpen(Database db) async {
    // Enable foreign key constraints
    await db.execute('PRAGMA foreign_keys = ON');
  }

  /// Closes the database connection
  static Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }

  /// Deletes the database (for testing purposes)
  static Future<void> deleteDatabase() async {
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, _databaseName);
    await databaseFactory.deleteDatabase(path);
    _database = null;
  }
}

/// Example usage of ContextManagementService:
/// ```dart
/// final db = await AppDatabase.database;
/// final service = ContextManagementService(db);
/// ```

/// Helper class for JSON operations in SQLite
class DatabaseJsonHelper {
  /// Converts a Map to JSON string for storage
  static String mapToJson(Map<String, dynamic> map) {
    return jsonEncode(map);
  }

  /// Converts a JSON string back to Map
  static Map<String, dynamic> jsonToMap(String jsonString) {
    return jsonDecode(jsonString) as Map<String, dynamic>;
  }

  /// Converts a List to JSON string for storage
  static String listToJson(List<dynamic> list) {
    return jsonEncode(list);
  }

  /// Converts a JSON string back to List
  static List<dynamic> jsonToList(String jsonString) {
    return jsonDecode(jsonString) as List<dynamic>;
  }

  /// Safely converts a List<String> to JSON
  static String stringListToJson(List<String> list) {
    return jsonEncode(list);
  }

  /// Safely converts JSON back to List<String>
  static List<String> jsonToStringList(String jsonString) {
    final decoded = jsonDecode(jsonString);
    if (decoded is List) {
      return decoded.cast<String>();
    }
    return [];
  }
}