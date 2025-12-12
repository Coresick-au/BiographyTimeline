import 'package:json_annotation/json_annotation.dart';
import 'media_asset.dart';

part 'story.g.dart';

@JsonSerializable()
class Story {
  final String id;
  final String eventId;
  final String authorId;
  final List<StoryBlock> blocks;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int version;
  final List<String>? collaboratorIds;

  const Story({
    required this.id,
    required this.eventId,
    required this.authorId,
    required this.blocks,
    required this.createdAt,
    required this.updatedAt,
    required this.version,
    this.collaboratorIds,
  });

  factory Story.fromJson(Map<String, dynamic> json) => _$StoryFromJson(json);
  Map<String, dynamic> toJson() => _$StoryToJson(this);

  /// Creates a new empty story
  factory Story.empty({
    required String id,
    required String eventId,
    required String authorId,
  }) {
    final now = DateTime.now();
    return Story(
      id: id,
      eventId: eventId,
      authorId: authorId,
      blocks: [],
      createdAt: now,
      updatedAt: now,
      version: 1,
    );
  }

  /// Gets the total word count of all text blocks
  int get wordCount {
    return blocks
        .where((block) => block.type == BlockType.text)
        .map((block) => block.content['text'] as String? ?? '')
        .map((text) => text.split(RegExp(r'\s+')).where((word) => word.isNotEmpty).length)
        .fold(0, (sum, count) => sum + count);
  }

  /// Gets all media assets referenced in the story
  List<MediaAsset> get referencedMedia {
    return blocks
        .where((block) => block.backgroundMedia != null)
        .map((block) => block.backgroundMedia!)
        .toList();
  }

  /// Checks if the story has any content
  bool get hasContent {
    return blocks.isNotEmpty;
  }

  Story copyWith({
    String? id,
    String? eventId,
    String? authorId,
    List<StoryBlock>? blocks,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? version,
    List<String>? collaboratorIds,
  }) {
    return Story(
      id: id ?? this.id,
      eventId: eventId ?? this.eventId,
      authorId: authorId ?? this.authorId,
      blocks: blocks ?? this.blocks,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      version: version ?? this.version,
      collaboratorIds: collaboratorIds ?? this.collaboratorIds,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Story &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          eventId == other.eventId &&
          authorId == other.authorId &&
          _listEquals(blocks, other.blocks) &&
          createdAt == other.createdAt &&
          updatedAt == other.updatedAt &&
          version == other.version &&
          _listEquals(collaboratorIds, other.collaboratorIds);

  @override
  int get hashCode =>
      id.hashCode ^
      eventId.hashCode ^
      authorId.hashCode ^
      blocks.hashCode ^
      createdAt.hashCode ^
      updatedAt.hashCode ^
      version.hashCode ^
      collaboratorIds.hashCode;

  bool _listEquals<T>(List<T>? a, List<T>? b) {
    if (a == null) return b == null;
    if (b == null || a.length != b.length) return false;
    for (int index = 0; index < a.length; index += 1) {
      if (a[index] != b[index]) return false;
    }
    return true;
  }
}

@JsonSerializable()
class StoryBlock {
  final String id;
  final BlockType type;
  final Map<String, dynamic> content;
  final Map<String, dynamic>? styling;
  final MediaAsset? backgroundMedia;
  final double? scrollTriggerPosition;

  const StoryBlock({
    required this.id,
    required this.type,
    required this.content,
    this.styling,
    this.backgroundMedia,
    this.scrollTriggerPosition,
  });

  factory StoryBlock.fromJson(Map<String, dynamic> json) =>
      _$StoryBlockFromJson(json);
  Map<String, dynamic> toJson() => _$StoryBlockToJson(this);

  /// Creates a text block
  factory StoryBlock.text({
    required String id,
    required String text,
    Map<String, dynamic>? styling,
    MediaAsset? backgroundMedia,
    double? scrollTriggerPosition,
  }) {
    return StoryBlock(
      id: id,
      type: BlockType.text,
      content: {'text': text},
      styling: styling,
      backgroundMedia: backgroundMedia,
      scrollTriggerPosition: scrollTriggerPosition,
    );
  }

  /// Creates an image block
  factory StoryBlock.image({
    required String id,
    required MediaAsset image,
    String? caption,
    Map<String, dynamic>? styling,
    double? scrollTriggerPosition,
  }) {
    return StoryBlock(
      id: id,
      type: BlockType.image,
      content: {
        'mediaAsset': image.toJson(),
        if (caption != null) 'caption': caption,
      },
      styling: styling,
      scrollTriggerPosition: scrollTriggerPosition,
    );
  }

  /// Creates a video block
  factory StoryBlock.video({
    required String id,
    required MediaAsset video,
    String? caption,
    Map<String, dynamic>? styling,
    double? scrollTriggerPosition,
  }) {
    return StoryBlock(
      id: id,
      type: BlockType.video,
      content: {
        'mediaAsset': video.toJson(),
        if (caption != null) 'caption': caption,
      },
      styling: styling,
      scrollTriggerPosition: scrollTriggerPosition,
    );
  }

  StoryBlock copyWith({
    String? id,
    BlockType? type,
    Map<String, dynamic>? content,
    Map<String, dynamic>? styling,
    MediaAsset? backgroundMedia,
    double? scrollTriggerPosition,
  }) {
    return StoryBlock(
      id: id ?? this.id,
      type: type ?? this.type,
      content: content ?? this.content,
      styling: styling ?? this.styling,
      backgroundMedia: backgroundMedia ?? this.backgroundMedia,
      scrollTriggerPosition: scrollTriggerPosition ?? this.scrollTriggerPosition,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StoryBlock &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          type == other.type &&
          _mapEquals(content, other.content) &&
          _mapEquals(styling, other.styling) &&
          backgroundMedia == other.backgroundMedia &&
          scrollTriggerPosition == other.scrollTriggerPosition;

  @override
  int get hashCode =>
      id.hashCode ^
      type.hashCode ^
      content.hashCode ^
      styling.hashCode ^
      backgroundMedia.hashCode ^
      scrollTriggerPosition.hashCode;

  bool _mapEquals<K, V>(Map<K, V>? a, Map<K, V>? b) {
    if (a == null) return b == null;
    if (b == null || a.length != b.length) return false;
    for (final K key in a.keys) {
      if (!b.containsKey(key) || b[key] != a[key]) return false;
    }
    return true;
  }
}

enum BlockType {
  @JsonValue('text')
  text,
  @JsonValue('image')
  image,
  @JsonValue('video')
  video,
  @JsonValue('audio')
  audio,
}