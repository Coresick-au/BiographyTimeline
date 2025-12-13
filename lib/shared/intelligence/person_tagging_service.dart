import 'dart:async';
import 'dart:typed_data';
import 'package:uuid/uuid.dart';
import '../database/face_database_service.dart';
import '../database/models/face_models.dart';
import 'face_detection_service.dart';

/// Service for managing person tags and face clustering
/// Provides privacy-first local person identification and tagging
class PersonTaggingService {
  static PersonTaggingService? _instance;
  static PersonTaggingService get instance => _instance ??= PersonTaggingService._();
  
  PersonTaggingService._();

  final _faceDbService = FaceDatabaseService.instance;
  final _faceDetectionService = FaceDetectionService.instance;
  final _uuid = const Uuid();

  // =========================================================================
  // PERSON MANAGEMENT
  // =========================================================================

  /// Create a new person from face cluster
  Future<String> createPersonFromCluster(
    String clusterId,
    String name, {
    PersonType type = PersonType.unknown,
    String? displayName,
  }) async {
    final cluster = await _faceDbService.getCluster(clusterId);
    if (cluster == null) {
      throw PersonTaggingException('Cluster not found: $clusterId');
    }

    final faces = await _faceDbService.getFacesForCluster(clusterId);
    if (faces.isEmpty) {
      throw PersonTaggingException('No faces found in cluster: $clusterId');
    }

    // Generate reference embeddings from representative faces
    final referenceEmbeddings = <Uint8List>[];
    final sortedFaces = faces..sort((a, b) => b.confidence.compareTo(a.confidence));
    
    // Use top 5 faces as references
    for (int i = 0; i < sortedFaces.length && i < 5; i++) {
      final face = sortedFaces[i];
      if (face.embedding != null) {
        // Convert double list to bytes
        final embeddingBytes = _convertEmbeddingToBytes(face.embedding!);
        referenceEmbeddings.add(embeddingBytes);
      }
    }

    final person = PersonEntity(
      id: _uuid.v4(),
      name: name,
      displayName: displayName,
      photoCount: faces.length,
      clusterIds: [clusterId],
      referenceEmbeddings: referenceEmbeddings,
      type: type,
      status: PersonStatus.verified,
      createdAt: DateTime.now(),
      lastSeen: DateTime.now(),
    );

    final personId = await _faceDbService.insertPerson(person);

    // Assign all faces in cluster to this person
    for (final face in faces) {
      await _faceDbService.assignFaceToPerson(face.id, personId);
    }

    return personId;
  }

  /// Create a new person manually
  Future<String> createPerson({
    required String name,
    String? displayName,
    PersonType type = PersonType.unknown,
    List<String>? clusterIds,
    List<Uint8List>? referenceEmbeddings,
  }) async {
    final person = PersonEntity(
      id: _uuid.v4(),
      name: name,
      displayName: displayName,
      photoCount: 0,
      clusterIds: clusterIds ?? [],
      referenceEmbeddings: referenceEmbeddings ?? [],
      type: type,
      status: PersonStatus.unverified,
      createdAt: DateTime.now(),
    );

    return await _faceDbService.insertPerson(person);
  }

  /// Update person information
  Future<void> updatePerson(String personId, {
    String? name,
    String? displayName,
    PersonType? type,
    PersonStatus? status,
  }) async {
    final person = await _faceDbService.getPerson(personId);
    if (person == null) {
      throw PersonTaggingException('Person not found: $personId');
    }

    final updatedPerson = person.copyWith(
      name: name ?? person.name,
      displayName: displayName ?? person.displayName,
      type: type ?? person.type,
      status: status ?? person.status,
    );

    await _faceDbService.updatePerson(updatedPerson);
  }

  /// Merge two persons
  Future<String> mergePersons(String personId1, String personId2) async {
    final person1 = await _faceDbService.getPerson(personId1);
    final person2 = await _faceDbService.getPerson(personId2);

    if (person1 == null || person2 == null) {
      throw PersonTaggingException('One or both persons not found');
    }

    // Keep the person with more photos as primary
    final (primary, secondary) = person1.photoCount >= person2.photoCount
        ? (person1, person2)
        : (person2, person1);

    // Merge clusters and embeddings
    final mergedClusters = {...primary.clusterIds, ...secondary.clusterIds}.toList();
    final mergedEmbeddings = [...primary.referenceEmbeddings, ...secondary.referenceEmbeddings];

    final mergedPerson = primary.copyWith(
      clusterIds: mergedClusters,
      referenceEmbeddings: mergedEmbeddings,
      updatedAt: DateTime.now(),
    );

    // Update primary person
    await _faceDbService.updatePerson(mergedPerson);

    // Reassign all faces from secondary to primary
    final secondaryFaces = await _faceDbService.getFacesForPerson(secondary.id);
    for (final face in secondaryFaces) {
      await _faceDbService.assignFaceToPerson(face.id, primary.id);
    }

    // Delete secondary person
    await _faceDbService.deletePerson(secondary.id);

    return primary.id;
  }

  /// Delete a person
  Future<void> deletePerson(String personId) async {
    final person = await _faceDbService.getPerson(personId);
    if (person == null) return;

    // Unassign all faces
    final faces = await _faceDbService.getFacesForPerson(personId);
    for (final face in faces) {
      await _faceDbService.updateFace(face.copyWith(personId: null));
    }

    // Delete person
    await _faceDbService.deletePerson(personId);
  }

  // =========================================================================
  // FACE TAGGING
  // =========================================================================

  /// Tag faces in a photo with persons
  Future<List<PersonTag>> tagFacesInPhoto(String photoId) async {
    final faces = await _faceDbService.getFacesForPhoto(photoId);
    final persons = await _faceDbService.getAllPersons();
    
    final tags = <PersonTag>[];

    for (final face in faces) {
      if (face.embedding == null) continue;

      final match = await _findBestPersonMatch(face, persons);
      if (match != null) {
        await _faceDbService.assignFaceToPerson(face.id, match.person.id);
        tags.add(PersonTag(
          faceId: face.id,
          personId: match.person.id,
          confidence: match.confidence,
          boundingBox: face.boundingBox,
        ));
      }
    }

    return tags;
  }

  /// Find best person match for a face
  Future<PersonMatch?> _findBestPersonMatch(
    DetectedFace face,
    List<PersonEntity> persons,
  ) async {
    PersonEntity? bestMatch;
    double bestScore = 0.0;

    for (final person in persons) {
      if (person.referenceEmbeddings.isEmpty) continue;

      for (final embeddingBytes in person.referenceEmbeddings) {
        final embedding = _convertBytesToEmbedding(embeddingBytes);
        final score = _calculateCosineSimilarity(face.embedding!, embedding);
        
        if (score > bestScore && score > 0.7) { // Threshold for matching
          bestScore = score;
          bestMatch = person;
        }
      }
    }

    if (bestMatch != null) {
      return PersonMatch(
        face: face,
        person: _convertToPerson(bestMatch),
        confidence: bestScore,
      );
    }

    return null;
  }

  // =========================================================================
  // CLUSTER MANAGEMENT
  // =========================================================================

  /// Process unclustered faces and create new clusters
  Future<int> processUnclusteredFaces() async {
    final unclusteredFaces = await _faceDbService.getUnclusteredFaces(limit: 100);
    if (unclusteredFaces.length < 3) return 0; // Need at least 3 faces to cluster

    // Convert to DetectedFace objects
    final detectedFaces = unclusteredFaces.map((f) => _convertToDetectedFace(f)).toList();

    // Run clustering
    final clusters = await _faceDetectionService.clusterFaces(detectedFaces);

    int createdClusters = 0;
    for (final cluster in clusters) {
      // Create cluster entity
      final clusterEntity = FaceClusterEntity(
        id: _uuid.v4(),
        name: 'Cluster ${createdClusters + 1}',
        faceCount: cluster.faces.length,
        confidence: cluster.confidence,
        createdAt: DateTime.now(),
      );

      final clusterId = await _faceDbService.insertCluster(clusterEntity);

      // Assign faces to cluster
      for (final face in cluster.faces) {
        await _faceDbService.assignFaceToCluster(face.id, clusterId);
      }

      createdClusters++;
    }

    return createdClusters;
  }

  /// Suggest person types for clusters based on frequency
  Future<Map<String, PersonType>> suggestPersonTypes() async {
    final clusters = await _faceDbService.getAllClusters();
    final suggestions = <String, PersonType>{};

    for (final cluster in clusters) {
      final faces = await _faceDbService.getFacesForCluster(cluster.id);
      
      // Simple heuristic based on cluster size
      if (faces.length > 50) {
        suggestions[cluster.id] = PersonType.family;
      } else if (faces.length > 20) {
        suggestions[cluster.id] = PersonType.friend;
      } else if (faces.length > 10) {
        suggestions[cluster.id] = PersonType.colleague;
      } else {
        suggestions[cluster.id] = PersonType.unknown;
      }
    }

    return suggestions;
  }

  // =========================================================================
  // SEARCH AND FILTERING
  // =========================================================================

  /// Search for persons by name
  Future<List<PersonEntity>> searchPersons(String query) async {
    return await _faceDbService.searchPersons(query);
  }

  /// Get persons by type
  Future<List<PersonEntity>> getPersonsByType(PersonType type) async {
    return await _faceDbService.getPersonsByType(type);
  }

  /// Get all persons with their statistics
  Future<List<PersonWithStats>> getAllPersonsWithStats() async {
    final persons = await _faceDbService.getAllPersons();
    final personStats = <PersonWithStats>[];

    for (final person in persons) {
      final faces = await _faceDbService.getFacesForPerson(person.id);
      final clusters = <FaceClusterEntity>[];
      
      for (final clusterId in person.clusterIds) {
        final cluster = await _faceDbService.getCluster(clusterId);
        if (cluster != null) clusters.add(cluster);
      }

      personStats.add(PersonWithStats(
        person: person,
        faceCount: faces.length,
        clusters: clusters,
        lastSeen: faces.isNotEmpty 
            ? faces.map((f) => f.createdAt).reduce((a, b) => a.isAfter(b) ? a : b)
            : null,
      ));
    }

    return personStats;
  }

  // =========================================================================
  // UTILITIES
  // =========================================================================

  double _calculateCosineSimilarity(List<double> a, List<double> b) {
    double dotProduct = 0.0;
    double normA = 0.0;
    double normB = 0.0;

    for (int i = 0; i < a.length; i++) {
      dotProduct += a[i] * b[i];
      normA += a[i] * a[i];
      normB += b[i] * b[i];
    }

    return dotProduct / (normA.sqrt() * normB.sqrt());
  }

  Uint8List _convertEmbeddingToBytes(List<double> embedding) {
    final byteData = ByteData(embedding.length * 8);
    for (int i = 0; i < embedding.length; i++) {
      byteData.setFloat64(i * 8, embedding[i]);
    }
    return byteData.buffer.asUint8List();
  }

  List<double> _convertBytesToEmbedding(Uint8List bytes) {
    final byteData = ByteData.view(bytes.buffer);
    final embedding = <double>[];
    
    for (int i = 0; i < bytes.length; i += 8) {
      embedding.add(byteData.getFloat64(i));
    }
    
    return embedding;
  }

  DetectedFace _convertToDetectedFace(FaceEntity entity) {
    return DetectedFace(
      id: int.parse(entity.id),
      boundingBox: entity.boundingBox,
      landmarks: {},
      embedding: entity.embedding != null 
          ? _convertBytesToEmbedding(entity.embedding!)
          : null,
      confidence: entity.confidence,
    );
  }

  Person _convertToPerson(PersonEntity entity) {
    return Person(
      id: entity.id,
      name: entity.name,
      photoIds: [], // Would need to fetch separately
      referenceEmbeddings: entity.referenceEmbeddings
          .map((e) => _convertBytesToEmbedding(e))
          .toList(),
      createdAt: entity.createdAt,
      lastSeen: entity.lastSeen,
    );
  }
}

// =========================================================================
// DATA MODELS
// =========================================================================

class PersonTag {
  final String faceId;
  final String personId;
  final double confidence;
  final Rect boundingBox;

  PersonTag({
    required this.faceId,
    required this.personId,
    required this.confidence,
    required this.boundingBox,
  });
}

class PersonWithStats {
  final PersonEntity person;
  final int faceCount;
  final List<FaceClusterEntity> clusters;
  final DateTime? lastSeen;

  PersonWithStats({
    required this.person,
    required this.faceCount,
    required this.clusters,
    this.lastSeen,
  });
}

// =========================================================================
// EXCEPTIONS
// =========================================================================

class PersonTaggingException implements Exception {
  final String message;
  PersonTaggingException(this.message);
  
  @override
  String toString() => 'PersonTaggingException: $message';
}
