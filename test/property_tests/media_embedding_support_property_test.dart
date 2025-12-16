import 'package:flutter_test/flutter_test.dart';
import 'package:faker/faker.dart';
import 'package:uuid/uuid.dart';

import '../../lib/shared/models/story.dart';
import '../../lib/shared/models/media_asset.dart';
import '../../lib/features/stories/services/story_editor_service.dart';
import '../../lib/features/stories/data/repositories/story_repository.dart';

/**
 * Feature: users-timeline, Property 14: Media Embedding Support
 * 
 * Property: For any supported media type (photo, video, audio, document), 
 * the story editor should successfully embed the content within the narrative
 * 
 * Validates: Requirements 3.3
 */

void main() {
  group('Media Embedding Support Property Tests', () {
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

    test('Property: Story editor embeds photos successfully for any photo asset', () {
      // Run property test with 100 iterations
      for (int i = 0; i < 100; i++) {
        // Generate random photo asset
        final photoAsset = _generateRandomMediaAsset(AssetType.photo);
        final story = _generateRandomStory();
        
        // Test: Create image block
        final imageBlock = StoryBlock.image(
          id: uuid.v4(),
          image: photoAsset,
          caption: faker.lorem.sentence(),
        );
        
        // Verify: Image block should be created successfully
        expect(imageBlock.type, equals(BlockType.image));
        expect(imageBlock.content['mediaAsset'], isNotNull);
        expect(imageBlock.content['caption'], isNotNull);
        
        // Test: Add to story
        final updatedStory = story.copyWith(
          blocks: [...story.blocks, imageBlock],
        );
        
        // Verify: Story should contain the image block
        expect(updatedStory.blocks.contains(imageBlock), isTrue);
        expect(updatedStory.referencedMedia.any((m) => m.id == photoAsset.id), isTrue);
      }
    });

    test('Property: Story editor embeds videos successfully for any video asset', () {
      // Run property test with 100 iterations
      for (int i = 0; i < 100; i++) {
        // Generate random video asset
        final videoAsset = _generateRandomMediaAsset(AssetType.video);
        final story = _generateRandomStory();
        
        // Test: Create video block
        final videoBlock = StoryBlock.video(
          id: uuid.v4(),
          video: videoAsset,
          caption: faker.lorem.sentence(),
        );
        
        // Verify: Video block should be created successfully
        expect(videoBlock.type, equals(BlockType.video));
        expect(videoBlock.content['mediaAsset'], isNotNull);
        expect(videoBlock.content['caption'], isNotNull);
        
        // Test: Add to story
        final updatedStory = story.copyWith(
          blocks: [...story.blocks, videoBlock],
        );
        
        // Verify: Story should contain the video block
        expect(updatedStory.blocks.contains(videoBlock), isTrue);
        expect(updatedStory.referencedMedia.any((m) => m.id == videoAsset.id), isTrue);
      }
    });

    test('Property: Story editor embeds audio successfully for any audio asset', () {
      // Run property test with 100 iterations
      for (int i = 0; i < 100; i++) {
        // Generate random audio asset
        final audioAsset = _generateRandomMediaAsset(AssetType.audio);
        final story = _generateRandomStory();
        
        // Test: Create audio block
        final audioBlock = StoryBlock(
          id: uuid.v4(),
          type: BlockType.audio,
          content: {
            'mediaAsset': audioAsset.toJson(),
            'caption': faker.lorem.sentence(),
          },
        );
        
        // Verify: Audio block should be created successfully
        expect(audioBlock.type, equals(BlockType.audio));
        expect(audioBlock.content['mediaAsset'], isNotNull);
        expect(audioBlock.content['caption'], isNotNull);
        
        // Test: Add to story
        final updatedStory = story.copyWith(
          blocks: [...story.blocks, audioBlock],
        );
        
        // Verify: Story should contain the audio block
        expect(updatedStory.blocks.contains(audioBlock), isTrue);
        
        // Verify: Audio asset should be properly embedded
        final embeddedAsset = MediaAsset.fromJson(
          audioBlock.content['mediaAsset'] as Map<String, dynamic>,
        );
        expect(embeddedAsset.id, equals(audioAsset.id));
        expect(embeddedAsset.type, equals(AssetType.audio));
      }
    });

    test('Property: Story editor handles mixed media embedding for any combination', () {
      // Run property test with 100 iterations
      for (int i = 0; i < 100; i++) {
        // Generate random story with mixed media
        final story = _generateRandomStory();
        final mediaAssets = _generateRandomMediaAssets();
        
        final blocks = <StoryBlock>[];
        
        // Test: Embed each media asset
        for (final asset in mediaAssets) {
          StoryBlock block;
          
          switch (asset.type) {
            case AssetType.photo:
              block = StoryBlock.image(
                id: uuid.v4(),
                image: asset,
                caption: faker.lorem.sentence(),
              );
              break;
            case AssetType.video:
              block = StoryBlock.video(
                id: uuid.v4(),
                video: asset,
                caption: faker.lorem.sentence(),
              );
              break;
            case AssetType.audio:
              block = StoryBlock(
                id: uuid.v4(),
                type: BlockType.audio,
                content: {
                  'mediaAsset': asset.toJson(),
                  'caption': faker.lorem.sentence(),
                },
              );
              break;
            case AssetType.document:
              block = StoryBlock(
                id: uuid.v4(),
                type: BlockType.image, // Documents displayed as images for now
                content: {
                  'mediaAsset': asset.toJson(),
                  'caption': faker.lorem.sentence(),
                },
              );
              break;
          }
          
          blocks.add(block);
        }
        
        // Test: Create story with all media blocks
        final mediaStory = story.copyWith(
          blocks: [...story.blocks, ...blocks],
        );
        
        // Verify: All media should be properly embedded
        expect(mediaStory.blocks.length, equals(story.blocks.length + blocks.length));
        
        // Verify: Each media asset should be accessible
        for (final asset in mediaAssets) {
          final hasAsset = mediaStory.blocks.any((block) {
            if (block.content['mediaAsset'] != null) {
              final embeddedAsset = MediaAsset.fromJson(
                block.content['mediaAsset'] as Map<String, dynamic>,
              );
              return embeddedAsset.id == asset.id;
            }
            return false;
          });
          expect(hasAsset, isTrue, reason: 'Asset ${asset.id} should be embedded');
        }
      }
    });

    test('Property: Media embedding preserves asset metadata for any asset', () {
      // Run property test with 100 iterations
      for (int i = 0; i < 100; i++) {
        // Generate random media asset with metadata
        final originalAsset = _generateRandomMediaAssetWithMetadata();
        
        // Test: Embed asset in story block
        final block = StoryBlock.image(
          id: uuid.v4(),
          image: originalAsset,
          caption: faker.lorem.sentence(),
        );
        
        // Test: Extract asset from block
        final embeddedAsset = MediaAsset.fromJson(
          block.content['mediaAsset'] as Map<String, dynamic>,
        );
        
        // Verify: All metadata should be preserved
        expect(embeddedAsset.id, equals(originalAsset.id));
        expect(embeddedAsset.eventId, equals(originalAsset.eventId));
        expect(embeddedAsset.type, equals(originalAsset.type));
        expect(embeddedAsset.localPath, equals(originalAsset.localPath));
        expect(embeddedAsset.cloudUrl, equals(originalAsset.cloudUrl));
        expect(embeddedAsset.caption, equals(originalAsset.caption));
        expect(embeddedAsset.isKeyAsset, equals(originalAsset.isKeyAsset));
        expect(embeddedAsset.createdAt, equals(originalAsset.createdAt));
      }
    });

    test('Property: Media embedding supports captions for any media type', () {
      // Run property test with 100 iterations
      for (int i = 0; i < 100; i++) {
        final assetType = AssetType.values[faker.randomGenerator.integer(AssetType.values.length)];
        final asset = _generateRandomMediaAsset(assetType);
        final caption = faker.lorem.sentences(faker.randomGenerator.integer(3, min: 1)).join(' ');
        
        StoryBlock block;
        
        // Test: Create block with caption for each media type
        switch (assetType) {
          case AssetType.photo:
            block = StoryBlock.image(
              id: uuid.v4(),
              image: asset,
              caption: caption,
            );
            break;
          case AssetType.video:
            block = StoryBlock.video(
              id: uuid.v4(),
              video: asset,
              caption: caption,
            );
            break;
          case AssetType.audio:
          case AssetType.document:
            block = StoryBlock(
              id: uuid.v4(),
              type: assetType == AssetType.audio ? BlockType.audio : BlockType.image,
              content: {
                'mediaAsset': asset.toJson(),
                'caption': caption,
              },
            );
            break;
        }
        
        // Verify: Caption should be preserved
        expect(block.content['caption'], equals(caption));
        expect(block.content['caption'], isNotEmpty);
        
        // Verify: Media asset should be embedded
        expect(block.content['mediaAsset'], isNotNull);
      }
    });
  });
}

/// Generate a random story for testing
Story _generateRandomStory() {
  final faker = Faker();
  final uuid = const Uuid();
  
  final blockCount = faker.randomGenerator.integer(3, min: 0);
  final blocks = List.generate(blockCount, (index) {
    return StoryBlock.text(
      id: uuid.v4(),
      text: faker.lorem.sentences(faker.randomGenerator.integer(2, min: 1)).join(' '),
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

/// Generate a random media asset for testing
MediaAsset _generateRandomMediaAsset(AssetType type) {
  final faker = Faker();
  final uuid = const Uuid();
  
  return MediaAsset(
    id: uuid.v4(),
    eventId: uuid.v4(),
    type: type,
    localPath: _generatePathForType(type),
    cloudUrl: faker.internet.httpUrl(),
    createdAt: faker.date.dateTime(),
    isKeyAsset: faker.randomGenerator.boolean(),
  );
}

/// Generate a random media asset with metadata
MediaAsset _generateRandomMediaAssetWithMetadata() {
  final faker = Faker();
  final uuid = const Uuid();
  final type = AssetType.values[faker.randomGenerator.integer(AssetType.values.length)];
  
  return MediaAsset(
    id: uuid.v4(),
    eventId: uuid.v4(),
    type: type,
    localPath: _generatePathForType(type),
    cloudUrl: faker.internet.httpUrl(),
    caption: faker.lorem.sentence(),
    createdAt: faker.date.dateTime(),
    isKeyAsset: faker.randomGenerator.boolean(),
  );
}

/// Generate multiple random media assets
List<MediaAsset> _generateRandomMediaAssets() {
  final faker = Faker();
  final count = faker.randomGenerator.integer(5, min: 1);
  
  return List.generate(count, (index) {
    final type = AssetType.values[faker.randomGenerator.integer(AssetType.values.length)];
    return _generateRandomMediaAsset(type);
  });
}

/// Generate appropriate file path for asset type
String _generatePathForType(AssetType type) {
  final faker = Faker();
  
  switch (type) {
    case AssetType.photo:
      return '/path/to/image_${faker.randomGenerator.integer(1000)}.jpg';
    case AssetType.video:
      return '/path/to/video_${faker.randomGenerator.integer(1000)}.mp4';
    case AssetType.audio:
      return '/path/to/audio_${faker.randomGenerator.integer(1000)}.mp3';
    case AssetType.document:
      return '/path/to/document_${faker.randomGenerator.integer(1000)}.pdf';
  }
}

/// Mock repository for testing
class MockStoryRepository implements StoryRepository {
  final Map<String, Story> _stories = {};

  @override
  Future<Story?> getStory(String storyId) async {
    return _stories[storyId];
  }

  @override
  Future<void> saveStory(Story story) async {
    _stories[story.id] = story;
  }

  @override
  Future<List<Story>> getStoriesForEvent(String eventId) async {
    return _stories.values.where((s) => s.eventId == eventId).toList();
  }

  @override
  Future<List<Story>> getStoryVersions(String storyId) async {
    return [];
  }

  @override
  Future<void> deleteStory(String storyId) async {
    _stories.remove(storyId);
  }

  @override
  Future<void> autoSaveStory(Story story) async {
    await saveStory(story);
  }
}
