import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_quill/flutter_quill.dart';
import '../../data/models/story_editor_state.dart';
import '../../data/repositories/story_repository.dart';
import '../../services/story_editor_service.dart';
import '../../../../shared/models/story.dart';

/// Provider for story repository
final storyRepositoryProvider = Provider<StoryRepository>((ref) {
  return LocalStoryRepository();
});

/// Provider for story editor service
final storyEditorServiceProvider = Provider<StoryEditorService>((ref) {
  return StoryEditorService(ref.watch(storyRepositoryProvider));
});

/// Provider for story editor state
final storyEditorProvider = StateNotifierProvider.family<StoryEditorNotifier, StoryEditorState, String>(
  (ref, storyId) {
    return StoryEditorNotifier(
      ref.watch(storyEditorServiceProvider),
      storyId,
    );
  },
);

/// State notifier for story editor
class StoryEditorNotifier extends StateNotifier<StoryEditorState> {
  final StoryEditorService _service;
  final String _storyId;

  StoryEditorNotifier(this._service, this._storyId)
      : super(StoryEditorState(
          story: Story.empty(id: _storyId, eventId: '', authorId: ''),
          quillController: QuillController.basic(),
          availableMedia: [],
        )) {
    _loadStory();
  }

  /// Load story from repository
  Future<void> _loadStory() async {
    try {
      final story = await _service._repository.getStory(_storyId);
      if (story != null) {
        final controller = _service.convertBlocksToQuill(story.blocks);
        state = state.copyWith(
          story: story,
          quillController: controller,
        );
      }
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Failed to load story: $e',
      );
    }
  }

  /// Update story content
  void updateStory(Story story) {
    state = state.copyWith(
      story: story,
      hasUnsavedChanges: true,
    );
  }

  /// Start auto-saving
  void startAutoSave() {
    _service.startAutoSave(
      state.story,
      state.quillController,
      (updatedStory) {
        state = state.copyWith(
          story: updatedStory,
          isAutoSaving: true,
        );
        
        // Simulate save completion after a delay
        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) {
            state = state.copyWith(
              isAutoSaving: false,
              lastSaved: DateTime.now(),
              hasUnsavedChanges: false,
            );
          }
        });
      },
    );
  }

  /// Save story manually
  Future<void> saveStory() async {
    try {
      state = state.copyWith(isAutoSaving: true);
      
      final updatedStory = await _service.saveStory(
        state.story,
        state.quillController,
      );
      
      state = state.copyWith(
        story: updatedStory,
        isAutoSaving: false,
        lastSaved: DateTime.now(),
        hasUnsavedChanges: false,
        errorMessage: null,
      );
    } catch (e) {
      state = state.copyWith(
        isAutoSaving: false,
        errorMessage: 'Failed to save story: $e',
      );
    }
  }

  /// Set available media
  void setAvailableMedia(List<dynamic> media) {
    // Convert to MediaAsset list
    // TODO: Implement proper conversion
    state = state.copyWith(availableMedia: []);
  }

  @override
  void dispose() {
    _service.dispose();
    super.dispose();
  }
}