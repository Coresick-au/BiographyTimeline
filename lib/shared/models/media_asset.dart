import 'package:json_annotation/json_annotation.dart';
import 'exif_data.dart';

part 'media_asset.g.dart';

@JsonSerializable()
class MediaAsset {
  final String id;
  final String eventId;
  final AssetType type;
  final String localPath;
  final String? cloudUrl;
  final ExifData? exifData;
  final String? caption;
  final DateTime createdAt;
  final bool isKeyAsset;
  final int? width;
  final int? height;
  final int? fileSizeBytes;
  final String? mimeType;

  const MediaAsset({
    required this.id,
    required this.eventId,
    required this.type,
    required this.localPath,
    this.cloudUrl,
    this.exifData,
    this.caption,
    required this.createdAt,
    required this.isKeyAsset,
    this.width,
    this.height,
    this.fileSizeBytes,
    this.mimeType,
  });

  factory MediaAsset.fromJson(Map<String, dynamic> json) =>
      _$MediaAssetFromJson(json);
  Map<String, dynamic> toJson() => _$MediaAssetToJson(this);

  /// Creates a photo asset
  factory MediaAsset.photo({
    required String id,
    required String eventId,
    required String localPath,
    String? cloudUrl,
    ExifData? exifData,
    String? caption,
    required DateTime createdAt,
    bool isKeyAsset = false,
    int? width,
    int? height,
    int? fileSizeBytes,
  }) {
    return MediaAsset(
      id: id,
      eventId: eventId,
      type: AssetType.photo,
      localPath: localPath,
      cloudUrl: cloudUrl,
      exifData: exifData,
      caption: caption,
      createdAt: createdAt,
      isKeyAsset: isKeyAsset,
      width: width,
      height: height,
      fileSizeBytes: fileSizeBytes,
      mimeType: 'image/jpeg',
    );
  }

  /// Creates a video asset
  factory MediaAsset.video({
    required String id,
    required String eventId,
    required String localPath,
    String? cloudUrl,
    String? caption,
    required DateTime createdAt,
    bool isKeyAsset = false,
    int? width,
    int? height,
    int? fileSizeBytes,
  }) {
    return MediaAsset(
      id: id,
      eventId: eventId,
      type: AssetType.video,
      localPath: localPath,
      cloudUrl: cloudUrl,
      caption: caption,
      createdAt: createdAt,
      isKeyAsset: isKeyAsset,
      width: width,
      height: height,
      fileSizeBytes: fileSizeBytes,
      mimeType: 'video/mp4',
    );
  }

  /// Creates an audio asset
  factory MediaAsset.audio({
    required String id,
    required String eventId,
    required String localPath,
    String? cloudUrl,
    String? caption,
    required DateTime createdAt,
    bool isKeyAsset = false,
    int? fileSizeBytes,
  }) {
    return MediaAsset(
      id: id,
      eventId: eventId,
      type: AssetType.audio,
      localPath: localPath,
      cloudUrl: cloudUrl,
      caption: caption,
      createdAt: createdAt,
      isKeyAsset: isKeyAsset,
      fileSizeBytes: fileSizeBytes,
      mimeType: 'audio/mp3',
    );
  }

  /// Creates a document asset
  factory MediaAsset.document({
    required String id,
    required String eventId,
    required String localPath,
    String? cloudUrl,
    String? caption,
    required DateTime createdAt,
    bool isKeyAsset = false,
    int? fileSizeBytes,
    String? mimeType,
  }) {
    return MediaAsset(
      id: id,
      eventId: eventId,
      type: AssetType.document,
      localPath: localPath,
      cloudUrl: cloudUrl,
      caption: caption,
      createdAt: createdAt,
      isKeyAsset: isKeyAsset,
      fileSizeBytes: fileSizeBytes,
      mimeType: mimeType ?? 'application/pdf',
    );
  }

  MediaAsset copyWith({
    String? id,
    String? eventId,
    AssetType? type,
    String? localPath,
    String? cloudUrl,
    ExifData? exifData,
    String? caption,
    DateTime? createdAt,
    bool? isKeyAsset,
    int? width,
    int? height,
    int? fileSizeBytes,
    String? mimeType,
  }) {
    return MediaAsset(
      id: id ?? this.id,
      eventId: eventId ?? this.eventId,
      type: type ?? this.type,
      localPath: localPath ?? this.localPath,
      cloudUrl: cloudUrl ?? this.cloudUrl,
      exifData: exifData ?? this.exifData,
      caption: caption ?? this.caption,
      createdAt: createdAt ?? this.createdAt,
      isKeyAsset: isKeyAsset ?? this.isKeyAsset,
      width: width ?? this.width,
      height: height ?? this.height,
      fileSizeBytes: fileSizeBytes ?? this.fileSizeBytes,
      mimeType: mimeType ?? this.mimeType,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MediaAsset &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          eventId == other.eventId &&
          type == other.type &&
          localPath == other.localPath &&
          cloudUrl == other.cloudUrl &&
          exifData == other.exifData &&
          caption == other.caption &&
          createdAt == other.createdAt &&
          isKeyAsset == other.isKeyAsset &&
          width == other.width &&
          height == other.height &&
          fileSizeBytes == other.fileSizeBytes &&
          mimeType == other.mimeType;

  @override
  int get hashCode =>
      id.hashCode ^
      eventId.hashCode ^
      type.hashCode ^
      localPath.hashCode ^
      cloudUrl.hashCode ^
      exifData.hashCode ^
      caption.hashCode ^
      createdAt.hashCode ^
      isKeyAsset.hashCode ^
      width.hashCode ^
      height.hashCode ^
      fileSizeBytes.hashCode ^
      mimeType.hashCode;
}

enum AssetType {
  @JsonValue('photo')
  photo,
  @JsonValue('video')
  video,
  @JsonValue('audio')
  audio,
  @JsonValue('document')
  document,
}
