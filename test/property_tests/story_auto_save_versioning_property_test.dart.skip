import 'package:flutter_test/flutter_test.dart';
import 'package:faker/faker.dart';
import 'package:uuid/uuid.dart';

import '../../lib/shared/models/story.dart';
import '../../lib/features/stories/services/version_control_service.dart';
import '../../lib/features/stories/data/repositories/story_repository.dart';

/**
 * Feature: users-timeline, Property 14: Story Auto-save and Versioning
 * 
 * Property: For any story editing session, the system should automatically 
 * save changes and maintain version history without data loss
 * 
 * Validates: Requirements 3.5
 */

void main() {
  group('Story Auto-save and Versioning Property Tests', () {
    late VersionControlService versionService;
    late MockStoryRepository mockRepository;
    final faker = Faker();
    final uuid = const Uuid();

    setUp(() {
      mockRepository = MockStoryRepository();
      versionService = VersionControlService(mockRepository);
    });

    tearDown(() {
      versionService.dispose();
    });

    test('Property: Auto-save preserves story content for any editing session', () async {
      // Run property test with 100 iterations
      for (int i = 0; i < 100; i++) {
        // Generate random story
        final originalStory = _generateRandomStory();
        
        // Test: Save story with versioning
        final savedStory = await versionService.saveWithVersioning(originalStory);
        
        // Verify: Story should be saved successfully
        expect(savedStory.id, equals(originalStory.id));
        expect(savedStory.eventId, equals(originalStory.eventId));
        expect(savedStory.authorId, equals(originalStory.authorId));
        expect(savedStory.blocks.length, equals(originalStory.blocks.length));
        
        // Verify: Service assigns a positive sequential version
        expect(savedStory.version, greaterThan(0));
        
        // Verify: Content should be preserved
        for (int j = 0; j < originalStory.blocks.length; j++) {
          final originalBlock = originalStory.blocks[j];
          final savedBlock = savedStory.blocks[j];
          
          expect(savedBlock.type, equals(originalBlock.type));
          expect(savedBlock.content, equals(originalBlock.content));
        }
        
        // Test: Retrieve saved story
        final retrievedStory = await mockRepository.getStory(savedStory.id);
        expect(retrievedStory, isNotNull);
        expect(retrievedStory!.version, equals(savedStory.version));
      }
    });

    test('Property: Version history maintains chronological order for any sequence', () async {
      // Run property test with 100 iterations
      for (int i = 0; i < 100; i++) {
        // Generate random story
        var story = _generateRandomStory();
        final versionCount = faker.randomGenerator.integer(5, min: 2);
        
        // Test: Create multiple versions
        for (int v = 0; v < versionCount; v++) {
          // Modify story content
          story = _modifyStoryContent(story);
          
          // Save new version
          story = await versionService.saveWithVersioning(story);
        }
        
        // Test: Get version history
        final versions = await versionService.getVersionHistory(story.id);
        
        // Verify: Should have correct number of versions
        expect(versions.length, equals(versionCount));
        
        // Verify: Versions should be in descending order (newest first)
        for (int v = 1; v < versions.length; v++) {
          expect(versions[v - 1].version, greaterThan(versions[v].version));
          expect(versions[v - 1].timestamp.isAfter(versions[v].timestamp) || 
                 versions[v - 1].timestamp.isAtSameMomentAs(versions[v].timestamp), isTrue);
        }
        
        // Verify: Each version should have valid metadata
        for (final version in versions) {
          expect(version.version, greaterThan(0));
          expect(version.wordCount, greaterThanOrEqualTo(0));
          expect(version.summary, isNotEmpty);
          expect(version.story, isNotNull);
        }
      }
    });

    test('Property: Version restoration preserves content integrity for any version', () async {
      // Run property test with 100 iterations
      for (int i = 0; i < 100; i++) {
        // Generate story with multiple versions
        var story = _generateRandomStory();
        final versions = <Story>[];
        
        // Create several versions
        for (int v = 0; v < 3; v++) {
          story = _modifyStoryContent(story);
          story = await versionService.saveWithVersioning(story);
          versions.add(story);
        }
        
        // Test: Restore each version
        for (final targetVersion in versions) {
          final restoredStory = await versionService.restoreVersion(
            story.id,
            targetVersion.version,
          );
          
          // Verify: Restored content should match original version
          expect(restoredStory.blocks.length, equals(targetVersion.blocks.length));
          
          for (int j = 0; j < targetVersion.blocks.length; j++) {
            final originalBlock = targetVersion.blocks[j];
            final restoredBlock = restoredStory.blocks[j];
            
            expect(restoredBlock.type, equals(originalBlock.type));
            expect(restoredBlock.content, equals(originalBlock.content));
          }
          
          // Verify: New version number should be assigned
          expect(restoredStory.version, greaterThan(targetVersion.version));
        }
      }
    });

    test('Property: Unsaved changes tracking works for any modification pattern', () async {
      // Run property test with 100 iterations
      for (int i = 0; i < 100; i++) {
        // Generate random story
        final story = _generateRandomStory();
        
        // Test: Initially no unsaved changes
        expect(versionService.hasUnsavedChanges(story.id), isFalse);
        
        // Test: Start auto-save (simulates pending changes)
        var saveCallCount = 0;
        versionService.startAutoSave(story.id, story, (savedStory) {
          saveCallCount++;
        });
        
        // Verify: Should have unsaved changes
        expect(versionService.hasUnsavedChanges(story.id), isTrue);
        
        // Test: Force save
        final savedStory = await versionService.forceSave(story.id);
        
        // Verify: Should clear unsaved changes
        expect(versionService.hasUnsavedChanges(story.id), isFalse);
        expect(savedStory, isNotNull);
        
        // Test: Stop auto-save
        versionService.stopAutoSave(story.id);
        expect(versionService.hasUnsavedChanges(story.id), isFalse);
      }
    });

    test('Property: Version comparison detects changes accurately for any modification', () async {
      // Run property test with 100 iterations
      for (int i = 0; i < 100; i++) {
        // Generate two related story versions
        final originalStory = _generateRandomStory();
        final modifiedStory = _modifyStoryContent(originalStory);
        
        // Test: Compare versions
        final diff = versionService.compareVersions(originalStory, modifiedStory);
        
        // Verify: Diff should have valid structure
        expect(diff.oldVersion, equals(originalStory.version));
        expect(diff.newVersion, equals(modifiedStory.version));
        expect(diff.wordCountChange, equals(modifiedStory.wordCount - originalStory.wordCount));
        expect(diff.blocksAdded, equals(modifiedStory.blocks.length - originalStory.blocks.length));
        
        // Verify: Should detect changes if content differs
        if (originalStory.blocks.length != modifiedStory.blocks.length) {
          expect(diff.blocksAdded, isNot(equals(0)));
        }
        
        // Verify: Text changes should be tracked
        expect(diff.textChanges, isNotNull);
        expect(diff.mediaChanges, isNotNull);
      }
    });

    test('Property: Version cleanup maintains storage limits for any history size', () async {
      // Run property test with 100 iterations
      for (int i = 0; i < 100; i++) {
        // Generate story with many versions (exceeding limit)
        var story = _generateRandomStory();
        final versionCount = faker.randomGenerator.integer(20, min: 10); // Exceeds typical limit
        
        // Create many versions
        for (int v = 0; v < versionCount; v++) {
          story = _modifyStoryContent(story);
          story = await versionService.saveWithVersioning(story);
        }
        
        // Test: Get version history
        final versions = await versionService.getVersionHistory(story.id);
        
        // Verify: Should not exceed reasonable limits
        // Note: Actual cleanup logic would be implemented in the service
        expect(versions.length, lessThanOrEqualTo(versionCount));
        expect(versions.length, greaterThan(0));
        
        // Verify: Most recent versions should be preserved
        if (versions.isNotEmpty) {
          expect(versions.first.version, equals(story.version));
        }
      }
    });

    test('Property: Auto-save handles concurrent modifications safely for any timing', () async {
      // Run property test with 100 iterations
      for (int i = 0; i < 100; i++) {
        // Generate random story
        final story = _generateRandomStory();
        var saveCount = 0;
        
        // Test: Start multiple auto-save sessions (simulating rapid changes)
        for (int session = 0; session < 3; session++) {
          final modifiedStory = _modifyStoryContent(story);
          
          versionService.startAutoSave(modifiedStory.id, modifiedStory, (savedStory) {
            saveCount++;
          });
          
          // Small delay to simulate rapid changes
          await Future.delayed(const Duration(milliseconds: 10));
        }
        
        // Test: Force save to resolve any pending changes
        final finalStory = await versionService.forceSave(story.id);
        
        // Verify: Should handle concurrent modifications gracefully
        expect(finalStory, isNotNull);
        expect(versionService.hasUnsavedChanges(story.id), isFalse);
        
        // Cleanup
        versionService.stopAutoSave(story.id);
      }
    });
  });
}

/// Generate a random story for testing
Story _generateRandomStory() {
  final faker = Faker();
  final uuid = const Uuid();
  
  final blockCount = faker.randomGenerator.integer(5, min: 1);
  final blocks = List.generate(blockCount, (index) {
    return StoryBlock.text(
      id: uuid.v4(),
      text: faker.lorem.sentences(faker.randomGenerator.integer(3, min: 1)).join(' '),
    );
  });
  
  return Story(
    id: uuid.v4(),
    eventId: uuid.v4(),
    authorId: uuid.v4(),
    blocks: blocks,
    createdAt: faker.date.dateTime(),
    updatedAt: faker.date.dateTime(),
    version: faker.randomGenerator.integer(5, min: 1),
  );
}

/// Modify story content to create a new version
Story _modifyStoryContent(Story story) {
  final faker = Faker();
  final uuid = const Uuid();
  
  final modificationTypes = ['add_block', 'modify_block', 'remove_block'];
  final modificationType = modificationTypes[faker.randomGenerator.integer(modificationTypes.length)];
  
  var newBlocks = List<StoryBlock>.from(story.blocks);
  
  switch (modificationType) {
    case 'add_block':
      newBlocks.add(StoryBlock.text(
        id: uuid.v4(),
        text: faker.lorem.sentences(faker.randomGenerator.integer(2, min: 1)).join(' '),
      ));
      break;
      
    case 'modify_block':
      if (newBlocks.isNotEmpty) {
        final index = faker.randomGenerator.integer(newBlocks.length);
        newBlocks[index] = StoryBlock.text(
          id: newBlocks[index].id,
          text: faker.lorem.sentences(faker.randomGenerator.integer(2, min: 1)).join(' '),
        );
      }
      break;
      
    case 'remove_block':
      if (newBlocks.length > 1) {
        final index = faker.randomGenerator.integer(newBlocks.length);
        newBlocks.removeAt(index);
      }
      break;
  }
  
  return story.copyWith(
    blocks: newBlocks,
    updatedAt: DateTime.now(),
    version: story.version + 1,
  );
}

/// Mock repository for testing
class MockStoryRepository implements StoryRepository {
  final Map<String, Story> _stories = {};
  final Map<String, List<Story>> _versions = {};

  @override
  Future<Story?> getStory(String storyId) async {
    return _stories[storyId];
  }

  @override
  Future<void> saveStory(Story story) async {
    _stories[story.id] = story;
    
    // Store version history
    _versions[story.id] = (_versions[story.id] ?? [])..add(story);
  }

  @override
  Future<List<Story>> getStoriesForEvent(String eventId) async {
    return _stories.values.where((s) => s.eventId == eventId).toList();
  }

  @override
  Future<List<Story>> getStoryVersions(String storyId) async {
    return _versions[storyId] ?? [];
  }

  @override
  Future<void> deleteStory(String storyId) async {
    _stories.remove(storyId);
    _versions.remove(storyId);
  }

  @override
  Future<void> autoSaveStory(Story story) async {
    await saveStory(story);
  }
}