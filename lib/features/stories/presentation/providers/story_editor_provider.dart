import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_quill/flutter_quill.dart';
import '../../data/repositories/story_repository.dart';
// import '../../services/story_editor_service.dart';
import '../../../../shared/models/story.dart';
import '../../../../shared/models/media_asset.dart';
import '../../../../shared/models/timeline_event.dart';
import '../../../../core/database/database.dart';

/// Story editor state
class StoryEditorState {
  final Story story;
  final QuillController quillController;
  final List<MediaAsset> availableMedia;
  final String? errorMessage;
  final bool isSaving;
  final bool isAutoSaving;
  final DateTime? lastSaved;
  final bool hasUnsavedChanges;

  const StoryEditorState({
    required this.story,
    required this.quillController,
    required this.availableMedia,
    this.errorMessage,
    this.isSaving = false,
    this.isAutoSaving = false,
    this.lastSaved,
    this.hasUnsavedChanges = false,
  });

  StoryEditorState copyWith({
    Story? story,
    QuillController? quillController,
    List<MediaAsset>? availableMedia,
    String? errorMessage,
    bool? isSaving,
    bool? isAutoSaving,
    DateTime? lastSaved,
    bool? hasUnsavedChanges,
  }) {
    return StoryEditorState(
      story: story ?? this.story,
      quillController: quillController ?? this.quillController,
      availableMedia: availableMedia ?? this.availableMedia,
      errorMessage: errorMessage,
      isSaving: isSaving ?? this.isSaving,
      isAutoSaving: isAutoSaving ?? this.isAutoSaving,
      lastSaved: lastSaved ?? this.lastSaved,
      hasUnsavedChanges: hasUnsavedChanges ?? this.hasUnsavedChanges,
    );
  }
}

/// Provider for story repository
final storyRepositoryProvider = Provider<StoryRepository>((ref) {
  // Use a lazy async pattern - the repository will be initialized when first used
  return _LazyStoryRepository();
});

/// Lazy implementation that initializes database on first use
class _LazyStoryRepository implements StoryRepository {
  dynamic _inner;
  
  dynamic get _repo {
    return _inner ??= throw UnimplementedError('Repository not initialized - call initialize() first');
  }

  Future<void> initialize() async {
    if (_inner == null) {
      final database = await AppDatabase.database;
      _inner = LocalStoryRepository(database);
    }
  }

  @override
  Future<Story?> getStory(String storyId) async {
    await initialize();
    return _repo.getStory(storyId);
  }

  @override
  Future<void> saveStory(Story story) async {
    await initialize();
    return _repo.saveStory(story);
  }

  @override
  Future<List<Story>> getStoriesForEvent(String eventId) async {
    await initialize();
    return _repo.getStoriesForEvent(eventId);
  }

  @override
  Future<List<Story>> getStoryVersions(String storyId) async {
    await initialize();
    return _repo.getStoryVersions(storyId);
  }

  @override
  Future<void> deleteStory(String storyId) async {
    await initialize();
    return _repo.deleteStory(storyId);
  }

  @override
  Future<void> autoSaveStory(Story story) async {
    await initialize();
    return _repo.autoSaveStory(story);
  }
}

/// Provider for story editor state
final storyEditorProvider = StateNotifierProvider.family<StoryEditorNotifier, StoryEditorState, String>(
  (ref, storyId) {
    return StoryEditorNotifier(
      ref,
      storyId,
    );
  },
);

/// State notifier for story editor
class StoryEditorNotifier extends StateNotifier<StoryEditorState> {
  final String _storyId;
  final Ref _ref;

  StoryEditorNotifier(this._ref, this._storyId)
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
      final repository = _ref.read(storyRepositoryProvider);
      if (repository is _LazyStoryRepository) {
        await repository.initialize();
      }
      final story = await repository.getStory(_storyId);
      if (story != null) {
        // TODO: Implement story blocks to Quill conversion
        final controller = QuillController.basic();
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
    // TODO: Implement auto-save functionality
    state = state.copyWith(
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
  }

  /// Save story manually
  Future<void> saveStory() async {
    try {
      state = state.copyWith(isAutoSaving: true);
      
      // TODO: Implement story saving
      await Future.delayed(const Duration(milliseconds: 500));
      
      state = state.copyWith(
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
    // TODO: Dispose resources when StoryEditorService is implemented
    super.dispose();
  }
}