import 'package:flutter_test/flutter_test.dart';
import 'package:faker/faker.dart';
import 'package:uuid/uuid.dart';

import '../../lib/shared/models/story.dart';
import '../../lib/shared/models/media_asset.dart';
import '../../lib/features/stories/services/scrollytelling_service.dart';

/**
 * Feature: users-timeline, Property 13: Scrollytelling Synchronization
 * 
 * Property: For any story with embedded media, scrolling through the narrative 
 * should trigger background media changes at the correct scroll positions
 * 
 * Validates: Requirements 3.2
 */

void main() {
  group('Scrollytelling Synchronization Property Tests', () {
    late ScrollytellingService scrollytellingService;
    final faker = Faker();
    final uuid = const Uuid();

    setUp(() {
      scrollytellingService = ScrollytellingService();
    });

    test('Property: Background media changes correctly for any scroll position', () {
      // Run property test with 100 iterations
      for (int i = 0; i < 100; i++) {
        // Generate random story with background media
        final story = _generateStoryWithBackgroundMedia();
        final maxScrollExtent = faker.randomGenerator.decimal(min: 100, scale: 2000);
        
        // Test multiple scroll positions
        for (int pos = 0; pos <= 10; pos++) {
          final scrollPosition = (pos / 10.0) * maxScrollExtent;
          
          // Test: Get active background media
          final activeMedia = scrollytellingService.getActiveBackgroundMedia(
            story,
            scrollPosition,
            maxScrollExtent,
          );
          
          // Verify: Should return valid media or null
          if (activeMedia != null) {
            expect(activeMedia, isA<MediaAsset>());
            expect(activeMedia.id, isNotEmpty);
            
            // Verify: Active media should be from story's background media
            final storyMedia = story.blocks
                .where((b) => b.backgroundMedia != null)
                .map((b) => b.backgroundMedia!)
                .toList();
            
            if (storyMedia.isNotEmpty) {
              expect(storyMedia.any((m) => m.id == activeMedia.id), isTrue);
            }
          }
        }
      }
    });

    test('Property: Active block index correlates with scroll position for any story', () {
      // Run property test with 100 iterations
      for (int i = 0; i < 100; i++) {
        // Generate random story
        final story = _generateRandomStory();
        if (story.blocks.isEmpty) continue;
        
        final maxScrollExtent = faker.randomGenerator.decimal(min: 100, scale: 2000);
        
        // Test: Scroll positions should map to valid block indices
        for (int pos = 0; pos <= 10; pos++) {
          final scrollPosition = (pos / 10.0) * maxScrollExtent;
          
          final activeBlockIndex = scrollytellingService.getActiveBlockIndex(
            story,
            scrollPosition,
            maxScrollExtent,
          );
          
          // Verify: Block index should be within valid range
          expect(activeBlockIndex, greaterThanOrEqualTo(0));
          expect(activeBlockIndex, lessThan(story.blocks.length));
          
          // Verify: Block index should increase with scroll position (generally)
          if (pos > 0) {
            final prevScrollPosition = ((pos - 1) / 10.0) * maxScrollExtent;
            final prevBlockIndex = scrollytellingService.getActiveBlockIndex(
              story,
              prevScrollPosition,
              maxScrollExtent,
            );
            
            expect(activeBlockIndex, greaterThanOrEqualTo(prevBlockIndex));
          }
        }
      }
    });

    test('Property: Scroll trigger assignment maintains order for any block sequence', () {
      // Run property test with 100 iterations
      for (int i = 0; i < 100; i++) {
        // Generate random story blocks
        final originalBlocks = _generateRandomBlocks();
        
        // Test: Assign scroll triggers
        final blocksWithTriggers = scrollytellingService.assignScrollTriggers(originalBlocks);
        
        // Verify: Same number of blocks
        expect(blocksWithTriggers.length, equals(originalBlocks.length));
        
        if (blocksWithTriggers.isNotEmpty) {
          // Verify: Trigger positions should be in ascending order
          for (int j = 1; j < blocksWithTriggers.length; j++) {
            final prevTrigger = blocksWithTriggers[j - 1].scrollTriggerPosition ?? 0.0;
            final currentTrigger = blocksWithTriggers[j].scrollTriggerPosition ?? 0.0;
            
            expect(currentTrigger, greaterThanOrEqualTo(prevTrigger));
          }
          
          // Verify: First trigger should be 0.0, last should be close to 1.0
          expect(blocksWithTriggers.first.scrollTriggerPosition, equals(0.0));
          
          if (blocksWithTriggers.length > 1) {
            final lastTrigger = blocksWithTriggers.last.scrollTriggerPosition ?? 0.0;
            expect(lastTrigger, lessThanOrEqualTo(1.0));
            expect(lastTrigger, greaterThan(0.0));
          }
        }
      }
    });

    test('Property: Parallax offset calculation is consistent for any input', () {
      // Run property test with 100 iterations
      for (int i = 0; i < 100; i++) {
        // Generate random scroll parameters
        final scrollPosition = faker.randomGenerator.decimal(min: 0, scale: 2000);
        final viewportHeight = faker.randomGenerator.decimal(min: 300, scale: 1200);
        final parallaxFactor = faker.randomGenerator.decimal(min: 0.1, scale: 1.0);
        
        // Test: Calculate parallax offset
        final offset = scrollytellingService.calculateParallaxOffset(
          scrollPosition,
          viewportHeight,
          parallaxFactor,
        );
        
        // Verify: Offset should be proportional to scroll position
        expect(offset, equals(scrollPosition * parallaxFactor));
        
        // Verify: Offset should scale with parallax factor
        final doubleFactorOffset = scrollytellingService.calculateParallaxOffset(
          scrollPosition,
          viewportHeight,
          parallaxFactor * 2,
        );
        expect(doubleFactorOffset, equals(offset * 2));
      }
    });

    test('Property: Media transitions maintain synchronization for any story structure', () {
      // Run property test with 100 iterations
      for (int i = 0; i < 100; i++) {
        // Generate story with multiple background media
        final story = _generateStoryWithMultipleBackgroundMedia();
        final maxScrollExtent = faker.randomGenerator.decimal(min: 500, scale: 2000);
        
        MediaAsset? previousMedia;
        int mediaChangeCount = 0;
        
        // Test: Scroll through entire story
        for (int pos = 0; pos <= 20; pos++) {
          final scrollPosition = (pos / 20.0) * maxScrollExtent;
          
          final currentMedia = scrollytellingService.getActiveBackgroundMedia(
            story,
            scrollPosition,
            maxScrollExtent,
          );
          
          // Count media changes
          if (currentMedia != previousMedia && currentMedia != null) {
            mediaChangeCount++;
          }
          previousMedia = currentMedia;
        }
        
        // Verify: Should have reasonable number of media changes
        final blocksWithMedia = story.blocks.where((b) => b.backgroundMedia != null).length;
        if (blocksWithMedia > 1) {
          expect(mediaChangeCount, greaterThan(0));
          expect(mediaChangeCount, lessThanOrEqualTo(blocksWithMedia));
        }
      }
    });

    test('Property: Scroll position boundaries are handled correctly for any story', () {
      // Run property test with 100 iterations
      for (int i = 0; i < 100; i++) {
        // Generate random story
        final story = _generateStoryWithBackgroundMedia();
        final maxScrollExtent = faker.randomGenerator.decimal(min: 100, scale: 2000);
        
        // Test: Boundary conditions
        
        // Test at scroll position 0
        final mediaAtStart = scrollytellingService.getActiveBackgroundMedia(
          story,
          0.0,
          maxScrollExtent,
        );
        final blockAtStart = scrollytellingService.getActiveBlockIndex(
          story,
          0.0,
          maxScrollExtent,
        );
        
        // Test at maximum scroll position
        final mediaAtEnd = scrollytellingService.getActiveBackgroundMedia(
          story,
          maxScrollExtent,
          maxScrollExtent,
        );
        final blockAtEnd = scrollytellingService.getActiveBlockIndex(
          story,
          maxScrollExtent,
          maxScrollExtent,
        );
        
        // Test beyond maximum scroll position
        final mediaOverscroll = scrollytellingService.getActiveBackgroundMedia(
          story,
          maxScrollExtent * 1.5,
          maxScrollExtent,
        );
        final blockOverscroll = scrollytellingService.getActiveBlockIndex(
          story,
          maxScrollExtent * 1.5,
          maxScrollExtent,
        );
        
        // Verify: Block indices should be within bounds
        if (story.blocks.isNotEmpty) {
          expect(blockAtStart, equals(0));
          expect(blockAtEnd, equals(story.blocks.length - 1));
          expect(blockOverscroll, equals(story.blocks.length - 1));
        }
        
        // Verify: Media should be consistent at boundaries
        expect(mediaAtEnd, equals(mediaOverscroll));
      }
    });
  });
}

/// Generate a random story with background media
Story _generateStoryWithBackgroundMedia() {
  final faker = Faker();
  final uuid = const Uuid();
  
  final blockCount = faker.randomGenerator.integer(5, min: 1);
  final blocks = <StoryBlock>[];
  
  for (int i = 0; i < blockCount; i++) {
    final hasBackgroundMedia = faker.randomGenerator.boolean();
    
    blocks.add(StoryBlock.text(
      id: uuid.v4(),
      text: faker.lorem.sentences(faker.randomGenerator.integer(3, min: 1)).join(' '),
      backgroundMedia: hasBackgroundMedia ? _generateRandomMediaAsset() : null,
      scrollTriggerPosition: i / blockCount,
    ));
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

/// Generate a story with multiple background media
Story _generateStoryWithMultipleBackgroundMedia() {
  final faker = Faker();
  final uuid = const Uuid();
  
  final blockCount = faker.randomGenerator.integer(8, min: 3);
  final blocks = <StoryBlock>[];
  
  for (int i = 0; i < blockCount; i++) {
    // Ensure at least half the blocks have background media
    final hasBackgroundMedia = i < blockCount / 2 || faker.randomGenerator.boolean();
    
    blocks.add(StoryBlock.text(
      id: uuid.v4(),
      text: faker.lorem.sentences(faker.randomGenerator.integer(2, min: 1)).join(' '),
      backgroundMedia: hasBackgroundMedia ? _generateRandomMediaAsset() : null,
      scrollTriggerPosition: i / blockCount,
    ));
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

/// Generate a random story
Story _generateRandomStory() {
  final faker = Faker();
  final uuid = const Uuid();
  
  final blockCount = faker.randomGenerator.integer(6, min: 0);
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

/// Generate random story blocks
List<StoryBlock> _generateRandomBlocks() {
  final faker = Faker();
  final uuid = const Uuid();
  
  final blockCount = faker.randomGenerator.integer(8, min: 0);
  return List.generate(blockCount, (index) {
    return StoryBlock.text(
      id: uuid.v4(),
      text: faker.lorem.sentences(faker.randomGenerator.integer(2, min: 1)).join(' '),
    );
  });
}

/// Generate a random media asset
MediaAsset _generateRandomMediaAsset() {
  final faker = Faker();
  final uuid = const Uuid();
  
  final assetType = AssetType.values[faker.randomGenerator.integer(AssetType.values.length)];
  
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
