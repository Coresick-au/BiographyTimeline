import 'dart:async';
import 'package:flutter/material.dart';
import '../../../shared/models/story.dart';
import '../../../shared/models/media_asset.dart';

/// Service for managing scrollytelling functionality
class ScrollytellingService {
  /// Calculate which background media should be active based on scroll position
  MediaAsset? getActiveBackgroundMedia(
    Story story,
    double scrollPosition,
    double maxScrollExtent,
  ) {
    if (story.blocks.isEmpty || maxScrollExtent == 0) return null;
    
    // Calculate scroll progress (0.0 to 1.0)
    final scrollProgress = (scrollPosition / maxScrollExtent).clamp(0.0, 1.0);
    
    // Find blocks with background media and scroll trigger positions
    final blocksWithMedia = story.blocks
        .where((block) => block.backgroundMedia != null)
        .toList();
    
    if (blocksWithMedia.isEmpty) return null;
    
    // Find the appropriate block based on scroll position
    for (int i = 0; i < blocksWithMedia.length; i++) {
      final block = blocksWithMedia[i];
      final triggerPosition = block.scrollTriggerPosition ?? (i / blocksWithMedia.length);
      
      // If this is the last block or scroll position is before next trigger
      if (i == blocksWithMedia.length - 1 || 
          scrollProgress < (blocksWithMedia[i + 1].scrollTriggerPosition ?? ((i + 1) / blocksWithMedia.length))) {
        if (scrollProgress >= triggerPosition) {
          return block.backgroundMedia;
        }
      }
    }
    
    return blocksWithMedia.first.backgroundMedia;
  }

  /// Calculate which story block is currently active based on scroll position
  int getActiveBlockIndex(
    Story story,
    double scrollPosition,
    double maxScrollExtent,
  ) {
    if (story.blocks.isEmpty || maxScrollExtent == 0) return 0;
    
    final scrollProgress = (scrollPosition / maxScrollExtent).clamp(0.0, 1.0);
    final blockProgress = scrollProgress * story.blocks.length;
    
    return blockProgress.floor().clamp(0, story.blocks.length - 1);
  }

  /// Create scroll trigger positions for story blocks
  List<StoryBlock> assignScrollTriggers(List<StoryBlock> blocks) {
    if (blocks.isEmpty) return blocks;
    
    final updatedBlocks = <StoryBlock>[];
    
    for (int i = 0; i < blocks.length; i++) {
      final triggerPosition = i / blocks.length;
      updatedBlocks.add(
        blocks[i].copyWith(
          scrollTriggerPosition: triggerPosition,
        ),
      );
    }
    
    return updatedBlocks;
  }

  /// Calculate parallax offset for background media
  double calculateParallaxOffset(
    double scrollPosition,
    double viewportHeight,
    double parallaxFactor,
  ) {
    return scrollPosition * parallaxFactor;
  }

  /// Animate background media transition
  Animation<double> createMediaTransition(
    AnimationController controller,
    Curve curve,
  ) {
    return Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: controller,
      curve: curve,
    ));
  }
}
