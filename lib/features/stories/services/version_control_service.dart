import 'dart:async';
import 'dart:convert';
import '../../../shared/models/story.dart';
import '../data/repositories/story_repository.dart';

/// Service for managing story version control and auto-save functionality
class VersionControlService {
  final StoryRepository _repository;
  final Map<String, Timer> _autoSaveTimers = {};
  final Map<String, Story> _pendingChanges = {};
  
  static const Duration _autoSaveDelay = Duration(seconds: 30);
  static const int _maxVersionHistory = 50;

  VersionControlService(this._repository);

  /// Start auto-save for a story
  void startAutoSave(String storyId, Story story, Function(Story) onSave) {
    // Cancel existing timer if any
    _autoSaveTimers[storyId]?.cancel();
    
    // Store pending changes
    _pendingChanges[storyId] = story;
    
    // Start new timer
    _autoSaveTimers[storyId] = Timer(_autoSaveDelay, () async {
      try {
        final storyToSave = _pendingChanges[storyId];
        if (storyToSave != null) {
          await _saveWithVersioning(storyToSave);
          onSave(storyToSave);
          _pendingChanges.remove(storyId);
        }
      } catch (e) {
        // Handle auto-save error
        print('Auto-save failed for story $storyId: $e');
      }
    });
  }

  /// Stop auto-save for a story
  void stopAutoSave(String storyId) {
    _autoSaveTimers[storyId]?.cancel();
    _autoSaveTimers.remove(storyId);
    _pendingChanges.remove(storyId);
  }

  /// Save story with version control
  Future<Story> saveWithVersioning(Story story) async {
    return await _saveWithVersioning(story);
  }

  /// Internal method to save story with versioning
  Future<Story> _saveWithVersioning(Story story) async {
    // Get current version from repository
    final existingStory = await _repository.getStory(story.id);
    
    // Increment version number
    final newVersion = (existingStory?.version ?? 0) + 1;
    
    // Create new version with updated metadata
    final versionedStory = story.copyWith(
      version: newVersion,
      updatedAt: DateTime.now(),
    );
    
    // Save the new version
    await _repository.saveStory(versionedStory);
    
    // Clean up old versions if necessary
    await _cleanupOldVersions(story.id);
    
    return versionedStory;
  }

  /// Get version history for a story
  Future<List<StoryVersion>> getVersionHistory(String storyId) async {
    final versions = await _repository.getStoryVersions(storyId);
    
    return versions.map((story) => StoryVersion(
      version: story.version,
      timestamp: story.updatedAt,
      wordCount: story.wordCount,
      summary: _generateVersionSummary(story),
      story: story,
    )).toList()..sort((a, b) => b.version.compareTo(a.version));
  }

  /// Restore a specific version
  Future<Story> restoreVersion(String storyId, int version) async {
    final versions = await _repository.getStoryVersions(storyId);
    final targetVersion = versions.firstWhere(
      (s) => s.version == version,
      orElse: () => throw Exception('Version $version not found'),
    );
    
    // Create new version based on the restored content
    final restoredStory = targetVersion.copyWith(
      version: (versions.map((s) => s.version).reduce((a, b) => a > b ? a : b)) + 1,
      updatedAt: DateTime.now(),
    );
    
    await _repository.saveStory(restoredStory);
    return restoredStory;
  }

  /// Compare two versions and get differences
  VersionDiff compareVersions(Story oldVersion, Story newVersion) {
    final oldText = _extractPlainText(oldVersion);
    final newText = _extractPlainText(newVersion);
    
    return VersionDiff(
      oldVersion: oldVersion.version,
      newVersion: newVersion.version,
      wordCountChange: newVersion.wordCount - oldVersion.wordCount,
      blocksAdded: newVersion.blocks.length - oldVersion.blocks.length,
      textChanges: _calculateTextChanges(oldText, newText),
      mediaChanges: _calculateMediaChanges(oldVersion, newVersion),
    );
  }

  /// Check if there are unsaved changes
  bool hasUnsavedChanges(String storyId) {
    return _pendingChanges.containsKey(storyId);
  }

  /// Force save pending changes
  Future<Story?> forceSave(String storyId) async {
    final pendingStory = _pendingChanges[storyId];
    if (pendingStory != null) {
      _autoSaveTimers[storyId]?.cancel();
      final savedStory = await _saveWithVersioning(pendingStory);
      _pendingChanges.remove(storyId);
      _autoSaveTimers.remove(storyId);
      return savedStory;
    }
    return null;
  }

  /// Clean up old versions to maintain storage limits
  Future<void> _cleanupOldVersions(String storyId) async {
    final versions = await _repository.getStoryVersions(storyId);
    
    if (versions.length > _maxVersionHistory) {
      // Sort by version and keep only the latest versions
      versions.sort((a, b) => b.version.compareTo(a.version));
      final versionsToDelete = versions.skip(_maxVersionHistory);
      
      for (final version in versionsToDelete) {
        await _repository.deleteStory('${version.id}_v${version.version}');
      }
    }
  }

  /// Generate a summary for a version
  String _generateVersionSummary(Story story) {
    if (story.blocks.isEmpty) return 'Empty story';
    
    final textBlocks = story.blocks.where((b) => b.type == BlockType.text);
    if (textBlocks.isEmpty) return 'Media-only story';
    
    final firstText = textBlocks.first.content['text'] as String? ?? '';
    final preview = firstText.length > 50 
        ? '${firstText.substring(0, 50)}...'
        : firstText;
    
    return preview.isEmpty ? 'Untitled story' : preview;
  }

  /// Extract plain text from story
  String _extractPlainText(Story story) {
    return story.blocks
        .where((block) => block.type == BlockType.text)
        .map((block) => block.content['text'] as String? ?? '')
        .join('\n');
  }

  /// Calculate text changes between versions
  List<TextChange> _calculateTextChanges(String oldText, String newText) {
    // Simple diff implementation - in production, use a proper diff library
    final changes = <TextChange>[];
    
    if (oldText != newText) {
      changes.add(TextChange(
        type: TextChangeType.modified,
        oldText: oldText,
        newText: newText,
      ));
    }
    
    return changes;
  }

  /// Calculate media changes between versions
  List<MediaChange> _calculateMediaChanges(Story oldVersion, Story newVersion) {
    final changes = <MediaChange>[];
    
    final oldMedia = oldVersion.referencedMedia;
    final newMedia = newVersion.referencedMedia;
    
    // Find added media
    for (final media in newMedia) {
      if (!oldMedia.any((m) => m.id == media.id)) {
        changes.add(MediaChange(
          type: MediaChangeType.added,
          mediaAsset: media,
        ));
      }
    }
    
    // Find removed media
    for (final media in oldMedia) {
      if (!newMedia.any((m) => m.id == media.id)) {
        changes.add(MediaChange(
          type: MediaChangeType.removed,
          mediaAsset: media,
        ));
      }
    }
    
    return changes;
  }

  /// Dispose of all timers
  void dispose() {
    for (final timer in _autoSaveTimers.values) {
      timer.cancel();
    }
    _autoSaveTimers.clear();
    _pendingChanges.clear();
  }
}

/// Represents a story version in history
class StoryVersion {
  final int version;
  final DateTime timestamp;
  final int wordCount;
  final String summary;
  final Story story;

  StoryVersion({
    required this.version,
    required this.timestamp,
    required this.wordCount,
    required this.summary,
    required this.story,
  });
}

/// Represents differences between two versions
class VersionDiff {
  final int oldVersion;
  final int newVersion;
  final int wordCountChange;
  final int blocksAdded;
  final List<TextChange> textChanges;
  final List<MediaChange> mediaChanges;

  VersionDiff({
    required this.oldVersion,
    required this.newVersion,
    required this.wordCountChange,
    required this.blocksAdded,
    required this.textChanges,
    required this.mediaChanges,
  });
}

/// Represents a text change
class TextChange {
  final TextChangeType type;
  final String oldText;
  final String newText;

  TextChange({
    required this.type,
    required this.oldText,
    required this.newText,
  });
}

enum TextChangeType { added, removed, modified }

/// Represents a media change
class MediaChange {
  final MediaChangeType type;
  final dynamic mediaAsset;

  MediaChange({
    required this.type,
    required this.mediaAsset,
  });
}

enum MediaChangeType { added, removed }
