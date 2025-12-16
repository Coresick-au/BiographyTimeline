import '../../../../shared/models/story.dart';
import '../../../../core/database/database.dart';
import 'package:sqflite/sqflite.dart';

/// Repository interface for story data operations
abstract class StoryRepository {
  /// Get a story by ID
  Future<Story?> getStory(String storyId);
  
  /// Save a story
  Future<void> saveStory(Story story);
  
  /// Get all stories for an event
  Future<List<Story>> getStoriesForEvent(String eventId);
  
  /// Get story version history
  Future<List<Story>> getStoryVersions(String storyId);
  
  /// Delete a story
  Future<void> deleteStory(String storyId);
  
  /// Auto-save story changes
  Future<void> autoSaveStory(Story story);
}

/// Local SQLite implementation of story repository
class LocalStoryRepository implements StoryRepository {
  final Database _database;

  LocalStoryRepository(this._database);

  @override
  Future<Story?> getStory(String storyId) async {
    final maps = await _database.query(
      'stories',
      where: 'id = ?',
      whereArgs: [storyId],
    );

    if (maps.isEmpty) return null;

    return _mapToStory(maps.first);
  }

  @override
  Future<void> saveStory(Story story) async {
    final map = _storyToMap(story);
    
    await _database.insert(
      'stories',
      map,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<List<Story>> getStoriesForEvent(String eventId) async {
    final maps = await _database.query(
      'stories',
      where: 'event_id = ?',
      whereArgs: [eventId],
      orderBy: 'created_at DESC',
    );

    return maps.map(_mapToStory).toList();
  }

  @override
  Future<List<Story>> getStoryVersions(String storyId) async {
    final maps = await _database.query(
      'stories',
      where: 'id = ?',
      whereArgs: [storyId],
      orderBy: 'version DESC',
    );

    return maps.map(_mapToStory).toList();
  }

  @override
  Future<void> deleteStory(String storyId) async {
    await _database.delete(
      'stories',
      where: 'id = ?',
      whereArgs: [storyId],
    );
  }

  @override
  Future<void> autoSaveStory(Story story) async {
    // For auto-save, we update the story with a new timestamp
    final updatedStory = story.copyWith(
      updatedAt: DateTime.now(),
    );
    
    await saveStory(updatedStory);
  }

  /// Maps a database row to a Story object
  Story _mapToStory(Map<String, dynamic> map) {
    return Story(
      id: map['id'] as String,
      eventId: map['event_id'] as String,
      authorId: map['author_id'] as String,
      blocks: _parseBlocks(map['blocks'] as String),
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updated_at'] as int),
      version: map['version'] as int,
      collaboratorIds: map['collaborator_ids'] != null 
          ? DatabaseJsonHelper.jsonToStringList(map['collaborator_ids'] as String)
          : null,
    );
  }

  /// Maps a Story object to a database row
  Map<String, dynamic> _storyToMap(Story story) {
    return {
      'id': story.id,
      'event_id': story.eventId,
      'author_id': story.authorId,
      'blocks': DatabaseJsonHelper.listToJson(story.blocks.map((b) => b.toJson()).toList()),
      'created_at': story.createdAt.millisecondsSinceEpoch,
      'updated_at': story.updatedAt.millisecondsSinceEpoch,
      'version': story.version,
      'collaborator_ids': story.collaboratorIds != null 
          ? DatabaseJsonHelper.stringListToJson(story.collaboratorIds!)
          : null,
    };
  }

  /// Parses blocks from JSON string
  List<StoryBlock> _parseBlocks(String blocksJson) {
    final List<dynamic> jsonList = DatabaseJsonHelper.jsonToList(blocksJson);
    return jsonList.map((json) => StoryBlock.fromJson(json as Map<String, dynamic>)).toList();
  }
}
