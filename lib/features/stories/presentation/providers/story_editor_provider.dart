import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_quill/flutter_quill.dart';
import '../../data/repositories/story_repository.dart';
import '../../services/story_editor_service.dart';
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

/// Provider for story editor state using the new service
final storyEditorProvider = StateNotifierProvider.family<StoryEditorNotifier, StoryEditorState, String>(
  (ref, storyId) {
    final service = ref.watch(storyEditorServiceProviderFamily(storyId));
    return StoryEditorNotifier(
      ref,
      storyId,
      service,
    );
  },
);

/// State notifier for story editor
class StoryEditorNotifier extends StateNotifier<StoryEditorState> {
  final String _storyId;
  final Ref _ref;
  final StoryEditorService _service;

  StoryEditorNotifier(this._ref, this._storyId, this._service)
      : super(StoryEditorState(
          story: Story.empty(id: _storyId, eventId: '', authorId: ''),
          quillController: QuillController.basic(),
          availableMedia: [],
        )) {
    // Listen to service streams
    _service.storyStream.listen(_onStoryUpdated);
    _service.savingStream.listen(_onSavingStateChanged);
    _service.errorStream.listen(_onErrorOccurred);
  }

  /// Handle story updates from service
  void _onStoryUpdated(Story? story) {
    if (story != null && mounted) {
      final controller = _service.createQuillController();
      state = state.copyWith(
        story: story,
        quillController: controller,
      );
    }
  }

  /// Handle saving state changes
  void _onSavingStateChanged(bool isSaving) {
    if (mounted) {
      state = state.copyWith(
        isSaving: isSaving,
        isAutoSaving: isSaving && !state.isSaving,
      );
    }
  }

  /// Handle error messages
  void _onErrorOccurred(String? error) {
    if (mounted) {
      state = state.copyWith(errorMessage: error);
    }
  }

  /// Update story content
  void updateStory(Story story) {
    state = state.copyWith(
      story: story,
      hasUnsavedChanges: true,
    );
  }

  /// Update content from Quill controller
  void updateContent(QuillController controller) {
    _service.updateContent(controller);
  }

  /// Add a new block
  void addBlock(StoryBlock block) {
    _service.addBlock(block);
  }

  /// Update a specific block
  void updateBlock(int index, StoryBlock block) {
    _service.updateBlock(index, block);
  }

  /// Remove a block
  void removeBlock(int index) {
    _service.removeBlock(index);
  }

  /// Reorder blocks
  void reorderBlocks(int oldIndex, int newIndex) {
    _service.reorderBlocks(oldIndex, newIndex);
  }

  /// Start auto-saving (handled by service)
  void startAutoSave() {
    // Auto-save is automatically handled by the service
  }

  /// Save story manually
  Future<void> saveStory() async {
    await _service.save();
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