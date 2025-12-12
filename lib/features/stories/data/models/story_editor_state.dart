import 'package:flutter_quill/flutter_quill.dart';
import '../../../../shared/models/story.dart';
import '../../../../shared/models/media_asset.dart';

/// State model for the story editor
class StoryEditorState {
  final Story story;
  final QuillController quillController;
  final List<MediaAsset> availableMedia;
  final bool isAutoSaving;
  final DateTime? lastSaved;
  final bool hasUnsavedChanges;
  final String? errorMessage;

  const StoryEditorState({
    required this.story,
    required this.quillController,
    required this.availableMedia,
    this.isAutoSaving = false,
    this.lastSaved,
    this.hasUnsavedChanges = false,
    this.errorMessage,
  });

  StoryEditorState copyWith({
    Story? story,
    QuillController? quillController,
    List<MediaAsset>? availableMedia,
    bool? isAutoSaving,
    DateTime? lastSaved,
    bool? hasUnsavedChanges,
    String? errorMessage,
  }) {
    return StoryEditorState(
      story: story ?? this.story,
      quillController: quillController ?? this.quillController,
      availableMedia: availableMedia ?? this.availableMedia,
      isAutoSaving: isAutoSaving ?? this.isAutoSaving,
      lastSaved: lastSaved ?? this.lastSaved,
      hasUnsavedChanges: hasUnsavedChanges ?? this.hasUnsavedChanges,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

/// State model for the scrollytelling viewer
class ScrollytellingState {
  final Story story;
  final double scrollPosition;
  final MediaAsset? currentBackgroundMedia;
  final int activeBlockIndex;
  final bool isPlaying;

  const ScrollytellingState({
    required this.story,
    this.scrollPosition = 0.0,
    this.currentBackgroundMedia,
    this.activeBlockIndex = 0,
    this.isPlaying = false,
  });

  ScrollytellingState copyWith({
    Story? story,
    double? scrollPosition,
    MediaAsset? currentBackgroundMedia,
    int? activeBlockIndex,
    bool? isPlaying,
  }) {
    return ScrollytellingState(
      story: story ?? this.story,
      scrollPosition: scrollPosition ?? this.scrollPosition,
      currentBackgroundMedia: currentBackgroundMedia ?? this.currentBackgroundMedia,
      activeBlockIndex: activeBlockIndex ?? this.activeBlockIndex,
      isPlaying: isPlaying ?? this.isPlaying,
    );
  }
}