import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'dart:math';

/// Database model for storing detected faces
class FaceEntity {
  final String id;
  final String photoId;
  final int faceIndex;
  final Rect boundingBox;
  final Map<String, Point<double>> landmarks;
  final double confidence;
  final Uint8List? embedding;
  final String? clusterId;
  final String? personId;
  final DateTime createdAt;

  const FaceEntity({
    required this.id,
    required this.photoId,
    required this.faceIndex,
    required this.boundingBox,
    required this.landmarks,
    required this.confidence,
    this.embedding,
    this.clusterId,
    this.personId,
    required this.createdAt,
  });

  FaceEntity copyWith({
    String? id,
    String? photoId,
    int? faceIndex,
    Rect? boundingBox,
    Map<String, Point<double>>? landmarks,
    double? confidence,
    Uint8List? embedding,
    String? clusterId,
    String? personId,
    DateTime? createdAt,
  }) {
    return FaceEntity(
      id: id ?? this.id,
      photoId: photoId ?? this.photoId,
      faceIndex: faceIndex ?? this.faceIndex,
      boundingBox: boundingBox ?? this.boundingBox,
      landmarks: landmarks ?? this.landmarks,
      confidence: confidence ?? this.confidence,
      embedding: embedding ?? this.embedding,
      clusterId: clusterId ?? this.clusterId,
      personId: personId ?? this.personId,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'photo_id': photoId,
      'face_index': faceIndex,
      'bounding_box': _rectToMap(boundingBox),
      'landmarks': landmarks.map((k, v) => MapEntry(k, _pointToMap(v))),
      'confidence': confidence,
      'embedding': embedding?.toList(),
      'cluster_id': clusterId,
      'person_id': personId,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory FaceEntity.fromMap(Map<String, dynamic> map) {
    return FaceEntity(
      id: map['id'],
      photoId: map['photo_id'],
      faceIndex: map['face_index'],
      boundingBox: _mapToRect(map['bounding_box']),
      landmarks: Map<String, Point<double>>.from(
        map['landmarks'].map((k, v) => MapEntry(k, _mapToPoint(v))),
      ),
      confidence: map['confidence'].toDouble(),
      embedding: map['embedding'] != null 
          ? Uint8List.fromList(List<int>.from(map['embedding']))
          : null,
      clusterId: map['cluster_id'],
      personId: map['person_id'],
      createdAt: DateTime.parse(map['created_at']),
    );
  }

  static Map<String, dynamic> _rectToMap(Rect rect) {
    return {
      'left': rect.left,
      'top': rect.top,
      'right': rect.right,
      'bottom': rect.bottom,
    };
  }

  static Rect _mapToRect(Map<String, dynamic> map) {
    return Rect.fromLTRB(
      map['left'].toDouble(),
      map['top'].toDouble(),
      map['right'].toDouble(),
      map['bottom'].toDouble(),
    );
  }

  static Map<String, dynamic> _pointToMap(Point<double> point) {
    return {
      'x': point.x,
      'y': point.y,
    };
  }

  static Point<double> _mapToPoint(Map<String, dynamic> map) {
    return Point(map['x'].toDouble(), map['y'].toDouble());
  }
}

/// Database model for face clusters
class FaceClusterEntity {
  final String id;
  final String name;
  final int faceCount;
  final double confidence;
  final String? representativeFaceId;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const FaceClusterEntity({
    required this.id,
    required this.name,
    required this.faceCount,
    required this.confidence,
    this.representativeFaceId,
    required this.createdAt,
    this.updatedAt,
  });

  FaceClusterEntity copyWith({
    String? id,
    String? name,
    int? faceCount,
    double? confidence,
    String? representativeFaceId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return FaceClusterEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      faceCount: faceCount ?? this.faceCount,
      confidence: confidence ?? this.confidence,
      representativeFaceId: representativeFaceId ?? this.representativeFaceId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'face_count': faceCount,
      'confidence': confidence,
      'representative_face_id': representativeFaceId,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  factory FaceClusterEntity.fromMap(Map<String, dynamic> map) {
    return FaceClusterEntity(
      id: map['id'],
      name: map['name'],
      faceCount: map['face_count'],
      confidence: map['confidence'].toDouble(),
      representativeFaceId: map['representative_face_id'],
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: map['updated_at'] != null 
          ? DateTime.parse(map['updated_at'])
          : null,
    );
  }
}

/// Database model for persons
class PersonEntity {
  final String id;
  final String name;
  final String? displayName;
  final String? avatarPhotoId;
  final int photoCount;
  final List<String> clusterIds;
  final List<Uint8List> referenceEmbeddings;
  final PersonType type;
  final PersonStatus status;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? lastSeen;

  const PersonEntity({
    required this.id,
    required this.name,
    this.displayName,
    this.avatarPhotoId,
    required this.photoCount,
    required this.clusterIds,
    required this.referenceEmbeddings,
    required this.type,
    required this.status,
    required this.createdAt,
    this.updatedAt,
    this.lastSeen,
  });

  PersonEntity copyWith({
    String? id,
    String? name,
    String? displayName,
    String? avatarPhotoId,
    int? photoCount,
    List<String>? clusterIds,
    List<Uint8List>? referenceEmbeddings,
    PersonType? type,
    PersonStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? lastSeen,
  }) {
    return PersonEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      displayName: displayName ?? this.displayName,
      avatarPhotoId: avatarPhotoId ?? this.avatarPhotoId,
      photoCount: photoCount ?? this.photoCount,
      clusterIds: clusterIds ?? this.clusterIds,
      referenceEmbeddings: referenceEmbeddings ?? this.referenceEmbeddings,
      type: type ?? this.type,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastSeen: lastSeen ?? this.lastSeen,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'display_name': displayName,
      'avatar_photo_id': avatarPhotoId,
      'photo_count': photoCount,
      'cluster_ids': jsonEncode(clusterIds),
      'reference_embeddings': jsonEncode(
        referenceEmbeddings.map((e) => e.toList()).toList(),
      ),
      'type': type.index,
      'status': status.index,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'last_seen': lastSeen?.toIso8601String(),
    };
  }

  factory PersonEntity.fromMap(Map<String, dynamic> map) {
    return PersonEntity(
      id: map['id'],
      name: map['name'],
      displayName: map['display_name'],
      avatarPhotoId: map['avatar_photo_id'],
      photoCount: map['photo_count'],
      clusterIds: List<String>.from(jsonDecode(map['cluster_ids'])),
      referenceEmbeddings: (jsonDecode(map['reference_embeddings']) as List)
          .map((e) => Uint8List.fromList(List<int>.from(e)))
          .toList(),
      type: PersonType.values[map['type']],
      status: PersonStatus.values[map['status']],
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: map['updated_at'] != null 
          ? DateTime.parse(map['updated_at'])
          : null,
      lastSeen: map['last_seen'] != null
          ? DateTime.parse(map['last_seen'])
          : null,
    );
  }
}

/// Database model for photo-face relationships
class PhotoFaceEntity {
  final String id;
  final String photoId;
  final String faceId;
  final int faceIndex;
  final DateTime createdAt;

  const PhotoFaceEntity({
    required this.id,
    required this.photoId,
    required this.faceId,
    required this.faceIndex,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'photo_id': photoId,
      'face_id': faceId,
      'face_index': faceIndex,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory PhotoFaceEntity.fromMap(Map<String, dynamic> map) {
    return PhotoFaceEntity(
      id: map['id'],
      photoId: map['photo_id'],
      faceId: map['face_id'],
      faceIndex: map['face_index'],
      createdAt: DateTime.parse(map['created_at']),
    );
  }
}

/// Person type enumeration
enum PersonType {
  unknown,
  family,
  friend,
  colleague,
  partner,
  child,
  parent,
  sibling,
  other,
}

/// Person status enumeration
enum PersonStatus {
  unverified,
  verified,
  hidden,
  merged,
}

/// Face processing job for background processing
class FaceProcessingJob {
  final String id;
  final String photoId;
  final String? albumId;
  final ProcessingStatus status;
  final DateTime createdAt;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final String? errorMessage;
  final int? faceCount;

  const FaceProcessingJob({
    required this.id,
    required this.photoId,
    this.albumId,
    required this.status,
    required this.createdAt,
    this.startedAt,
    this.completedAt,
    this.errorMessage,
    this.faceCount,
  });

  FaceProcessingJob copyWith({
    String? id,
    String? photoId,
    String? albumId,
    ProcessingStatus? status,
    DateTime? createdAt,
    DateTime? startedAt,
    DateTime? completedAt,
    String? errorMessage,
    int? faceCount,
  }) {
    return FaceProcessingJob(
      id: id ?? this.id,
      photoId: photoId ?? this.photoId,
      albumId: albumId ?? this.albumId,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      errorMessage: errorMessage ?? this.errorMessage,
      faceCount: faceCount ?? this.faceCount,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'photo_id': photoId,
      'album_id': albumId,
      'status': status.index,
      'created_at': createdAt.toIso8601String(),
      'started_at': startedAt?.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
      'error_message': errorMessage,
      'face_count': faceCount,
    };
  }

  factory FaceProcessingJob.fromMap(Map<String, dynamic> map) {
    return FaceProcessingJob(
      id: map['id'],
      photoId: map['photo_id'],
      albumId: map['album_id'],
      status: ProcessingStatus.values[map['status']],
      createdAt: DateTime.parse(map['created_at']),
      startedAt: map['started_at'] != null 
          ? DateTime.parse(map['started_at'])
          : null,
      completedAt: map['completed_at'] != null
          ? DateTime.parse(map['completed_at'])
          : null,
      errorMessage: map['error_message'],
      faceCount: map['face_count'],
    );
  }
}

/// Processing status enumeration
enum ProcessingStatus {
  pending,
  processing,
  completed,
  failed,
  cancelled,
}
