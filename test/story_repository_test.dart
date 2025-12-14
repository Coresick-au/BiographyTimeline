import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../lib/shared/models/story.dart';
import '../lib/shared/models/media_asset.dart';
import '../lib/features/stories/data/repositories/story_repository.dart';
import '../lib/core/database/database.dart';

void main() {
  group('StoryRepository Tests', () {
    late Database database;
    late StoryRepository repository;

    setUpAll(() async {
      // Initialize FFI
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
      
      // Create test database
      database = await openDatabase(
        inMemoryDatabasePath,
        options: OpenDatabaseOptions(
          version: 1,
          onCreate: (db, version) async {
            await AppDatabase.createTables(db);
          },
        ),
      );
      
      repository = LocalStoryRepository(database);
    });

    tearDownAll(() async {
      await database.close();
    });

    test('should save and retrieve a story', () async {
      // Create test story
      final story = Story(
        id: 'test-story-1',
        eventId: 'test-event-1',
        authorId: 'test-user-1',
        blocks: [
          StoryBlock.text(
            id: 'block-1',
            text: 'This is a test story',
          ),
        ],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        version: 1,
      );

      // Save story
      await repository.saveStory(story);

      // Retrieve story
      final retrieved = await repository.getStory('test-story-1');

      expect(retrieved, isNotNull);
      expect(retrieved!.id, equals('test-story-1'));
      expect(retrieved.eventId, equals('test-event-1'));
      expect(retrieved.blocks.length, equals(1));
      expect(retrieved.blocks.first.content['text'], equals('This is a test story'));
    });

    test('should get stories for event', () async {
      // Create multiple stories for the same event
      final story1 = Story(
        id: 'test-story-2',
        eventId: 'test-event-2',
        authorId: 'test-user-1',
        blocks: [StoryBlock.text(id: 'block-2', text: 'Story 1')],
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
        updatedAt: DateTime.now().subtract(const Duration(hours: 2)),
        version: 1,
      );

      final story2 = Story(
        id: 'test-story-3',
        eventId: 'test-event-2',
        authorId: 'test-user-1',
        blocks: [StoryBlock.text(id: 'block-3', text: 'Story 2')],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        version: 1,
      );

      // Save stories
      await repository.saveStory(story1);
      await repository.saveStory(story2);

      // Get stories for event
      final stories = await repository.getStoriesForEvent('test-event-2');

      expect(stories.length, equals(2));
      expect(stories.first.id, equals('test-story-3')); // Should be ordered by created_at DESC
      expect(stories.last.id, equals('test-story-2'));
    });

    test('should delete a story', () async {
      // Create and save story
      final story = Story(
        id: 'test-story-4',
        eventId: 'test-event-3',
        authorId: 'test-user-1',
        blocks: [StoryBlock.text(id: 'block-4', text: 'To be deleted')],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        version: 1,
      );

      await repository.saveStory(story);

      // Verify story exists
      var retrieved = await repository.getStory('test-story-4');
      expect(retrieved, isNotNull);

      // Delete story
      await repository.deleteStory('test-story-4');

      // Verify story is deleted
      retrieved = await repository.getStory('test-story-4');
      expect(retrieved, isNull);
    });
  });
}
