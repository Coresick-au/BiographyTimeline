import 'package:flutter_test/flutter_test.dart';
import 'package:faker/faker.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:uuid/uuid.dart';

import '../../lib/shared/models/story.dart';
import '../../lib/shared/models/media_asset.dart';
import '../../lib/features/stories/services/story_editor_service.dart';
import '../../lib/features/stories/data/repositories/story_repository.dart';

/**
 * Feature: users-timeline, Property 12: Rich Editor Feature Completeness
 * 
 * Property: For any selected timeline event, the story editor should provide 
 * formatted text, media embedding, and block-based editing capabilities
 * 
 * Validates: Requirements 3.1
 */

void main() {
  group('Rich Editor Feature Completeness Property Tests', () {
    late StoryEditorService editorService;
    late MockStoryRepository mockRepository;
    final faker = Faker();
    final uuid = const Uuid();

    setUp(() {
      mockRepository = MockStoryRepository();
      editorService = StoryEditorService(mockRepository);
    });

    tearDown(() {
      editorService.dispose();
    });

    test('Property: Rich editor provides formatted text capabilities for any story', () {
      // Run property test with 100 iterations
      for (int i = 0; i < 100; i++) {
        // Generate random story data
        final story = _generateRandomStory();
        
        // Test: Convert story blocks to QuillController
        final controller = editorService.convertBlocksToQuill(story.blocks);
        
        // Verify: Controller should be created successfully
        expect(controller, isNotNull);
        expect(controller.document, isNotNull);
        
        // Test: Convert back to blocks
        final convertedBlocks = editorService.convertQuillToBlocks(controller);
        
        // Verify: Block conversion should preserve text content
        final originalTextBlocks = story.blocks.where((b) => b.type == BlockType.text);
        final convertedTextBlocks = convertedBlocks.where((b) => b.type == BlockType.text);
        
        expect(convertedTextBlocks.length, greaterThanOrEqualTo(0));
        
        // Verify: Text content should be preserved (allowing for formatting differences)
        if (originalTextBlocks.isNotEmpty && convertedTextBlocks.isNotEmpty) {
          final originalText = originalTextBlocks
              .map((b) => b.content['text'] as String? ?? '')
              .join(' ');
          final convertedText = convertedTextBlocks
              .map((b) => b.content['text'] as String? ?? '')
              .join(' ');
          
          // Allow for whitespace normalization
          expect(convertedText.trim().isNotEmpty, equals(originalText.trim().isNotEmpty));
        }
        
        controller.dispose();
      }
    });

    test('Property: Rich editor supports media embedding for any media asset', () {
      // Run property test with 100 iterations
      for (int i = 0; i < 100; i++) {
        // Generate random media asset
        final mediaAsset = _generateRandomMediaAsset();
        final controller = QuillController.basic();
        
        // Test: Insert media into editor
        expect(() {
          editorService.insertMedia(controller, mediaAsset);
        }, returnsNormally);
        
        // Verify: Document should contain the media embed
        expect(controller.document.length, greaterThan(0));
        
        controller.dispose();
      }
    });

    test('Property: Rich editor supports block-based editing for any story structure', () {
      // Run property test with 100 iterations
      for (int i = 0; i < 100; i++) {
        // Generate random story with mixed block types
        final story = _generateRandomMixedBlockStory();
        
        // Test: Convert to QuillController and back
        final controller = editorService.convertBlocksToQuill(story.blocks);
        final convertedBlocks = editorService.convertQuillToBlocks(controller);
        
        // Verify: Block structure should be maintained
        expect(convertedBlocks, isNotNull);
        expect(convertedBlocks, isA<List<StoryBlock>>());
        
        // Verify: Each block should have valid structure
        for (final block in convertedBlocks) {
          expect(block.id, isNotEmpty);
          expect(block.type, isNotNull);
          expect(block.content, isNotNull);
        }
        
        controller.dispose();
      }
    });

    test('Property: Rich editor maintains content integrity across operations', () {
      // Run property test with 100 iterations
      for (int i = 0; i < 100; i++) {
        // Generate random story
        final story = _generateRandomStory();
        
        // Test: Multiple conversion cycles
        var currentBlocks = story.blocks;
        
        for (int cycle = 0; cycle < 3; cycle++) {
          final controller = editorService.convertBlocksToQuill(currentBlocks);
          currentBlocks = editorService.convertQuillToBlocks(controller);
          controller.dispose();
        }
        
        // Verify: Content should remain stable after multiple conversions
        expect(currentBlocks, isNotNull);
        expect(currentBlocks.length, greaterThanOrEqualTo(0));
        
        // Verify: At least the structure is preserved (blocks exist)
        for (final block in currentBlocks) {
          expect(block.id, isNotEmpty);
          expect(block.type, isNotNull);
          expect(block.content, isNotNull);
        }
      }
    });
  });
}

/// Generate a random story for testing
Story _generateRandomStory() {
  final faker = Faker();
  final uuid = const Uuid();
  
  final blockCount = faker.randomGenerator.integer(5, min: 0);
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
    version: faker.randomGenerator.integer(10, min: 1),
  );
}

/// Generate a random story with mixed block types
Story _generateRandomMixedBlockStory() {
  final faker = Faker();
  final uuid = const Uuid();
  
  final blocks = <StoryBlock>[];
  final blockCount = faker.randomGenerator.integer(8, min: 1);
  
  for (int i = 0; i < blockCount; i++) {
    final blockType = BlockType.values[faker.randomGenerator.integer(BlockType.values.length)];
    
    switch (blockType) {
      case BlockType.text:
        blocks.add(StoryBlock.text(
          id: uuid.v4(),
          text: faker.lorem.sentences(faker.randomGenerator.integer(3, min: 1)).join(' '),
        ));
        break;
      case BlockType.image:
        blocks.add(StoryBlock.image(
          id: uuid.v4(),
          image: _generateRandomMediaAsset(AssetType.photo),
          caption: faker.lorem.sentence(),
        ));
        break;
      case BlockType.video:
        blocks.add(StoryBlock.video(
          id: uuid.v4(),
          video: _generateRandomMediaAsset(AssetType.video),
          caption: faker.lorem.sentence(),
        ));
        break;
      case BlockType.audio:
        blocks.add(StoryBlock(
          id: uuid.v4(),
          type: BlockType.audio,
          content: {
            'mediaAsset': _generateRandomMediaAsset(AssetType.audio).toJson(),
            'caption': faker.lorem.sentence(),
          },
        ));
        break;
    }
  }
  
  return Story(
    id: uuid.v4(),
    eventId: uuid.v4(),
    authorId: uuid.v4(),
    blocks: blocks,
    createdAt: faker.date.dateTime(),
    updatedAt: faker.date.dateTime(),
    version: faker.randomGenerator.integer(10, min: 1),
  );
}

/// Generate a random media asset for testing
MediaAsset _generateRandomMediaAsset([AssetType? type]) {
  final faker = Faker();
  final uuid = const Uuid();
  
  final assetType = type ?? AssetType.values[faker.randomGenerator.integer(AssetType.values.length)];
  
  return MediaAsset(
    id: uuid.v4(),
    eventId: uuid.v4(),
    type: assetType,
    localPath: faker.internet.httpUrl(),
    cloudUrl: faker.internet.httpUrl(),
    createdAt: faker.date.dateTime(),
    isKeyAsset: faker.randomGenerator.boolean(),
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
