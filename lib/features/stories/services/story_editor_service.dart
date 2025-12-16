import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_quill/quill_delta.dart';
import '../data/repositories/story_repository.dart';
import '../../../shared/models/story.dart';
import '../../../shared/models/media_asset.dart';
import '../../../shared/models/timeline_event.dart';
import '../../../shared/error_handling/error_service.dart';
import '../../../shared/loading/loading_service.dart';
import '../../../core/database/database.dart';

/// Service for managing story editing operations
class StoryEditorService {
  final StoryRepository _repository;
  final ErrorService _errorService;
  final LoadingService _loadingService;
  final StreamController<Story?> _storyController = StreamController<Story?>.broadcast();
  final StreamController<bool> _savingController = StreamController<bool>.broadcast();
  final StreamController<String?> _errorController = StreamController<String?>.broadcast();
  
  Story? _currentStory;
  Timer? _autoSaveTimer;
  
  StoryEditorService(this._repository, [ErrorService? errorService, LoadingService? loadingService]) 
      : _errorService = errorService ?? ErrorService.instance,
        _loadingService = loadingService ?? LoadingService();

  /// Stream of the current story
  Stream<Story?> get storyStream => _storyController.stream;
  
  /// Stream of saving state
  Stream<bool> get savingStream => _savingController.stream;
  
  /// Stream of error messages
  Stream<String?> get errorStream => _errorController.stream;

  /// Get the current story
  Story? get currentStory => _currentStory;

  /// Load a story for editing
  Future<void> loadStory(String storyId) async {
    try {
      _savingController.add(true);
      final story = await _repository.getStory(storyId);
      _currentStory = story;
      _storyController.add(story);
      _errorController.add(null);
    } catch (e) {
      _errorController.add('Failed to load story: $e');
    } finally {
      _savingController.add(false);
    }
  }

  /// Create a new story
  Future<void> createStory({
    required String eventId,
    required String authorId,
    String? title,
  }) async {
    try {
      _savingController.add(true);
      
      final blocks = <StoryBlock>[];
      if (title != null) {
        blocks.add(StoryBlock.text(
          id: _generateId(),
          text: title,
        ));
      }
      blocks.add(StoryBlock.text(
        id: _generateId(),
        text: '',
      ));
      
      final story = Story(
        id: _generateId(),
        eventId: eventId,
        authorId: authorId,
        blocks: blocks,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        version: 1,
      );
      
      await _repository.saveStory(story);
      _currentStory = story;
      _storyController.add(story);
      _errorController.add(null);
    } catch (e) {
      _errorController.add('Failed to create story: $e');
    } finally {
      _savingController.add(false);
    }
  }

  /// Update story content from Quill controller
  Future<void> updateContent(QuillController controller) async {
    if (_currentStory == null) return;
    
    try {
      final delta = controller.document.toDelta();
      final blocks = _convertDeltaToStoryBlocks(delta);
      
      final updatedStory = _currentStory!.copyWith(
        blocks: blocks,
        updatedAt: DateTime.now(),
      );
      
      _currentStory = updatedStory;
      _storyController.add(updatedStory);
      
      // Trigger auto-save
      _scheduleAutoSave();
    } catch (e) {
      _errorController.add('Failed to update content: $e');
    }
  }

  /// Add a new block to the story
  Future<void> addBlock(StoryBlock block) async {
    if (_currentStory == null) return;
    
    try {
      final updatedBlocks = List<StoryBlock>.from(_currentStory!.blocks);
      updatedBlocks.add(block);
      
      final updatedStory = _currentStory!.copyWith(
        blocks: updatedBlocks,
        updatedAt: DateTime.now(),
      );
      
      _currentStory = updatedStory;
      _storyController.add(updatedStory);
      
      // Trigger auto-save
      _scheduleAutoSave();
    } catch (e) {
      _errorController.add('Failed to add block: $e');
    }
  }

  /// Update a specific block
  Future<void> updateBlock(int index, StoryBlock block) async {
    if (_currentStory == null || index < 0 || index >= _currentStory!.blocks.length) {
      return;
    }
    
    try {
      final updatedBlocks = List<StoryBlock>.from(_currentStory!.blocks);
      updatedBlocks[index] = block;
      
      final updatedStory = _currentStory!.copyWith(
        blocks: updatedBlocks,
        updatedAt: DateTime.now(),
      );
      
      _currentStory = updatedStory;
      _storyController.add(updatedStory);
      
      // Trigger auto-save
      _scheduleAutoSave();
    } catch (e) {
      _errorController.add('Failed to update block: $e');
    }
  }

  /// Remove a block from the story
  Future<void> removeBlock(int index) async {
    if (_currentStory == null || index < 0 || index >= _currentStory!.blocks.length) {
      return;
    }
    
    try {
      final updatedBlocks = List<StoryBlock>.from(_currentStory!.blocks);
      updatedBlocks.removeAt(index);
      
      final updatedStory = _currentStory!.copyWith(
        blocks: updatedBlocks,
        updatedAt: DateTime.now(),
      );
      
      _currentStory = updatedStory;
      _storyController.add(updatedStory);
      
      // Trigger auto-save
      _scheduleAutoSave();
    } catch (e) {
      _errorController.add('Failed to remove block: $e');
    }
  }

  /// Reorder blocks
  Future<void> reorderBlocks(int oldIndex, int newIndex) async {
    if (_currentStory == null || 
        oldIndex < 0 || oldIndex >= _currentStory!.blocks.length ||
        newIndex < 0 || newIndex >= _currentStory!.blocks.length) {
      return;
    }
    
    try {
      final updatedBlocks = List<StoryBlock>.from(_currentStory!.blocks);
      final block = updatedBlocks.removeAt(oldIndex);
      updatedBlocks.insert(newIndex, block);
      
      final updatedStory = _currentStory!.copyWith(
        blocks: updatedBlocks,
        updatedAt: DateTime.now(),
      );
      
      _currentStory = updatedStory;
      _storyController.add(updatedStory);
      
      // Trigger auto-save
      _scheduleAutoSave();
    } catch (e) {
      _errorController.add('Failed to reorder blocks: $e');
    }
  }

  /// Save the current story immediately
  Future<void> save() async {
    if (_currentStory == null) return;
    
    try {
      _savingController.add(true);
      _cancelAutoSave();
      
      await _repository.saveStory(_currentStory!);
      _errorController.add(null);
    } catch (e) {
      _errorController.add('Failed to save story: $e');
    } finally {
      _savingController.add(false);
    }
  }

  /// Auto-save the story
  Future<void> _autoSave() async {
    if (_currentStory == null) return;
    
    try {
      await _repository.autoSaveStory(_currentStory!);
      _errorController.add(null);
    } catch (e) {
      _errorController.add('Auto-save failed: $e');
    }
  }

  /// Schedule auto-save with debouncing
  void _scheduleAutoSave() {
    _cancelAutoSave();
    _autoSaveTimer = Timer(const Duration(seconds: 2), () {
      _autoSave();
    });
  }

  /// Cancel pending auto-save
  void _cancelAutoSave() {
    _autoSaveTimer?.cancel();
    _autoSaveTimer = null;
  }

  /// Convert Quill Delta to StoryBlocks
  List<StoryBlock> _convertDeltaToStoryBlocks(Delta delta) {
    final blocks = <StoryBlock>[];
    final doc = Document.fromDelta(delta);
    final lines = doc.toPlainText().split('\n');
    
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isNotEmpty) {
        // Create text blocks for all content
        blocks.add(StoryBlock.text(
          id: _generateId(),
          text: line,
        ));
      }
    }
    
    return blocks;
  }

  /// Convert StoryBlocks to Quill Document
  QuillController createQuillController() {
    if (_currentStory == null) {
      return QuillController.basic();
    }
    
    final doc = Document();
    final delta = Delta();
    
    for (final block in _currentStory!.blocks) {
      if (block.type == BlockType.text) {
        final text = block.content['text'] as String? ?? '';
        delta.insert(text);
        delta.insert('\n');
      }
    }
    
    return QuillController(
      document: Document.fromDelta(delta),
      selection: const TextSelection.collapsed(offset: 0),
    );
  }

  /// Generate a unique ID
  String _generateId() {
    return DateTime.now().millisecondsSinceEpoch.toString();
  }

  /// Dispose of resources
  void dispose() {
    _cancelAutoSave();
    _storyController.close();
    _savingController.close();
    _errorController.close();
  }
}

/// Lazy initialization wrapper for StoryRepository
class LazyStoryRepository implements StoryRepository {
  dynamic _inner;
  
  dynamic get _repo {
    return _inner ??= throw Exception('Repository not initialized - call initialize() first');
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

/// Provider for the story editor service
final storyEditorServiceProvider = Provider<StoryEditorService>((ref) {
  final repository = LazyStoryRepository();
  return StoryEditorService(repository, ErrorService.instance, LoadingService());
});

/// Provider for a specific story editor service instance
final storyEditorServiceProviderFamily = Provider.family<StoryEditorService, String>((ref, storyId) {
  final repository = LazyStoryRepository();
  final service = StoryEditorService(repository, ErrorService.instance, LoadingService());
  
  // Load the story when the provider is created
  WidgetsBinding.instance.addPostFrameCallback((_) {
    service.loadStory(storyId);
  });
  
  return service;
});
