import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/story_editor_state.dart';
import '../../services/scrollytelling_service.dart';
import '../../../../shared/models/story.dart';
import '../../../../shared/models/media_asset.dart';

/// Provider for scrollytelling service
final scrollytellingServiceProvider = Provider<ScrollytellingService>((ref) {
  return ScrollytellingService();
});

/// Provider for scrollytelling state
final scrollytellingProvider = StateNotifierProvider.family<ScrollytellingNotifier, ScrollytellingState, String>(
  (ref, storyId) {
    return ScrollytellingNotifier(
      ref.watch(scrollytellingServiceProvider),
      storyId,
    );
  },
);

/// State notifier for scrollytelling functionality
class ScrollytellingNotifier extends StateNotifier<ScrollytellingState> {
  final ScrollytellingService _service;
  final String _storyId;
  Timer? _autoScrollTimer;

  ScrollytellingNotifier(this._service, this._storyId)
      : super(ScrollytellingState(
          story: Story.empty(id: _storyId, eventId: '', authorId: ''),
        ));

  /// Set the story for scrollytelling
  void setStory(Story story) {
    // Assign scroll triggers to blocks if not already set
    final blocksWithTriggers = _service.assignScrollTriggers(story.blocks);
    final updatedStory = story.copyWith(blocks: blocksWithTriggers);
    
    state = state.copyWith(story: updatedStory);
  }

  /// Update scroll position and calculate active media/block
  void updateScrollPosition(double scrollPosition, double maxScrollExtent) {
    final activeMedia = _service.getActiveBackgroundMedia(
      state.story,
      scrollPosition,
      maxScrollExtent,
    );
    
    final activeBlockIndex = _service.getActiveBlockIndex(
      state.story,
      scrollPosition,
      maxScrollExtent,
    );

    state = state.copyWith(
      scrollPosition: scrollPosition,
      currentBackgroundMedia: activeMedia,
      activeBlockIndex: activeBlockIndex,
    );
  }

  /// Toggle auto-scroll functionality
  void toggleAutoScroll(ScrollController scrollController) {
    if (state.isPlaying) {
      _stopAutoScroll();
    } else {
      _startAutoScroll(scrollController);
    }
  }

  /// Start auto-scroll
  void _startAutoScroll(ScrollController scrollController) {
    state = state.copyWith(isPlaying: true);
    
    _autoScrollTimer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (!scrollController.hasClients) return;
      
      final currentOffset = scrollController.offset;
      final maxScrollExtent = scrollController.position.maxScrollExtent;
      
      // Auto-scroll speed (pixels per timer tick)
      const scrollSpeed = 2.0;
      final newOffset = currentOffset + scrollSpeed;
      
      if (newOffset >= maxScrollExtent) {
        // Reached the end, stop auto-scroll
        _stopAutoScroll();
        return;
      }
      
      scrollController.animateTo(
        newOffset,
        duration: const Duration(milliseconds: 50),
        curve: Curves.linear,
      );
    });
  }

  /// Stop auto-scroll
  void _stopAutoScroll() {
    _autoScrollTimer?.cancel();
    _autoScrollTimer = null;
    state = state.copyWith(isPlaying: false);
  }

  /// Jump to specific block
  void jumpToBlock(int blockIndex, ScrollController scrollController) {
    if (blockIndex < 0 || blockIndex >= state.story.blocks.length) return;
    if (!scrollController.hasClients) return;
    
    final maxScrollExtent = scrollController.position.maxScrollExtent;
    final targetPosition = (blockIndex / state.story.blocks.length) * maxScrollExtent;
    
    scrollController.animateTo(
      targetPosition,
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeInOut,
    );
  }

  /// Set background media for a specific block
  void setBlockBackgroundMedia(int blockIndex, MediaAsset? mediaAsset) {
    if (blockIndex < 0 || blockIndex >= state.story.blocks.length) return;
    
    final updatedBlocks = List<StoryBlock>.from(state.story.blocks);
    updatedBlocks[blockIndex] = updatedBlocks[blockIndex].copyWith(
      backgroundMedia: mediaAsset,
    );
    
    final updatedStory = state.story.copyWith(blocks: updatedBlocks);
    state = state.copyWith(story: updatedStory);
  }

  @override
  void dispose() {
    _autoScrollTimer?.cancel();
    super.dispose();
  }
}