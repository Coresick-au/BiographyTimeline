import 'dart:async';
import 'dart:convert';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:uuid/uuid.dart';
import '../../../shared/models/story.dart';
import '../../../shared/models/media_asset.dart';
import '../data/repositories/story_repository.dart';

/// Service for managing story editing operations
class StoryEditorService {
  final StoryRepository _repository;
  final _uuid = const Uuid();
  
  // Auto-save timer
  Timer? _autoSaveTimer;
  static const Duration _autoSaveInterval = Duration(seconds: 30);

  StoryEditorService(this._repository);

  /// Create a new empty story
  Story createNewStory({
    required String eventId,
    required String authorId,
  }) {
    return Story.empty(
      id: _uuid.v4(),
      eventId: eventId,
      authorId: authorId,
    );
  }

  /// Convert QuillController content to StoryBlocks
  List<StoryBlock> convertQuillToBlocks(QuillController controller) {
    final blocks = <StoryBlock>[];
    final document = controller.document;
    
    // Parse the Quill document and convert to StoryBlocks
    for (int i = 0; i < document.root.children.length; i++) {
      final node = document.root.children.elementAt(i);
      
      if (node.toPlainText().trim().isNotEmpty) {
        blocks.add(StoryBlock.text(
          id: _uuid.v4(),
          text: node.toPlainText(),
          styling: _extractStyling(node),
        ));
      }
    }
    
    return blocks;
  }

  /// Convert StoryBlocks to QuillController content
  QuillController convertBlocksToQuill(List<StoryBlock> blocks) {
    final controller = QuillController.basic();
    
    for (final block in blocks) {
      if (block.type == BlockType.text) {
        final text = block.content['text'] as String? ?? '';
        controller.document.insert(controller.document.length, text);
        controller.document.insert(controller.document.length, '\n');
      }
    }
    
    return controller;
  }

  /// Insert media into story at current cursor position
  void insertMedia(
    QuillController controller,
    MediaAsset mediaAsset,
    {String? caption}
  ) {
    final index = controller.selection.baseOffset;
    
    // Insert media embed
    controller.document.insert(
      index,
      BlockEmbed.custom(MediaEmbedData(
        mediaAsset: mediaAsset,
        caption: caption,
      )),
    );
  }

  /// Start auto-save for a story
  void startAutoSave(
    Story story,
    QuillController controller,
    Function(Story) onSave,
  ) {
    _autoSaveTimer?.cancel();
    _autoSaveTimer = Timer.periodic(_autoSaveInterval, (timer) {
      final updatedStory = story.copyWith(
        blocks: convertQuillToBlocks(controller),
        updatedAt: DateTime.now(),
        version: story.version + 1,
      );
      onSave(updatedStory);
    });
  }

  /// Stop auto-save
  void stopAutoSave() {
    _autoSaveTimer?.cancel();
    _autoSaveTimer = null;
  }

  /// Save story manually
  Future<Story> saveStory(Story story, QuillController controller) async {
    final updatedStory = story.copyWith(
      blocks: convertQuillToBlocks(controller),
      updatedAt: DateTime.now(),
      version: story.version + 1,
    );
    
    await _repository.saveStory(updatedStory);
    return updatedStory;
  }

  /// Get story version history
  Future<List<Story>> getVersionHistory(String storyId) async {
    return await _repository.getStoryVersions(storyId);
  }

  /// Extract styling information from Quill node
  Map<String, dynamic>? _extractStyling(dynamic node) {
    // TODO: Extract text formatting (bold, italic, etc.)
    return null;
  }

  void dispose() {
    stopAutoSave();
  }
}

/// Custom embed data for media assets
class MediaEmbedData extends CustomBlockEmbed {
  final MediaAsset mediaAsset;
  final String? caption;

  MediaEmbedData({
    required this.mediaAsset,
    this.caption,
  }) : super('media_embed', _encodePayload(mediaAsset, caption));

  static String _encodePayload(MediaAsset mediaAsset, String? caption) {
    return jsonEncode({
      'mediaAsset': mediaAsset.toJson(),
      if (caption != null) 'caption': caption,
    });
  }

  Map<String, dynamic> toJson() => {
        'mediaAsset': mediaAsset.toJson(),
        if (caption != null) 'caption': caption,
      };
}