import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:isolate';
import 'package:flutter/services.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;
import 'package:photo_manager/photo_manager.dart';
import '../database/database_service.dart';

/// Face detection service that handles on-device face detection and embedding generation
/// All processing is done locally for privacy
class FaceDetectionService {
  static FaceDetectionService? _instance;
  static FaceDetectionService get instance => _instance ??= FaceDetectionService._();
  
  FaceDetectionService._() {
    _initialize();
  }

  late final FaceDetector _faceDetector;
  Interpreter? _faceEmbeddingInterpreter;
  bool _isInitialized = false;

  // Face embedding model configuration
  static const String _modelPath = 'assets/models/mobile_facenet.tflite';
  static const int _embeddingSize = 192;
  static const int _inputSize = 112;
  static const double _similarityThreshold = 0.7;

  // =========================================================================
  // INITIALIZATION
  // =========================================================================

  Future<void> _initialize() async {
    if (_isInitialized) return;

    try {
      // Initialize face detector
      final options = FaceDetectorOptions(
        enableClassification: true,
        enableLandmarks: true,
        enableContours: false,
        enableTracking: false,
        minFaceSize: 0.1,
        performanceMode: FaceDetectorMode.accurate,
      );
      
      _faceDetector = FaceDetector(options: options);

      // Load face embedding model
      await _loadFaceEmbeddingModel();

      _isInitialized = true;
    } catch (e) {
      throw FaceDetectionException('Failed to initialize face detection: $e');
    }
  }

  Future<void> _loadFaceEmbeddingModel() async {
    try {
      _faceEmbeddingInterpreter = await Interpreter.fromAsset(_modelPath);
    } catch (e) {
      // Fallback: create dummy interpreter if model not found
      print('Warning: Face embedding model not found at $_modelPath');
      print('Face clustering will not be available');
    }
  }

  // =========================================================================
  // FACE DETECTION
  // =========================================================================

  /// Detect faces in an image file
  Future<List<DetectedFace>> detectFacesInFile(File imageFile) async {
    if (!_isInitialized) await _initialize();

    try {
      final inputImage = InputImage.fromFilePath(imageFile.path);
      final faces = await _faceDetector.processImage(inputImage);
      
      final detectedFaces = <DetectedFace>[];
      
      for (final face in faces) {
        // Generate face embedding if model is available
        List<double>? embedding;
        if (_faceEmbeddingInterpreter != null) {
          embedding = await _generateFaceEmbedding(imageFile, face);
        }
        
        detectedFaces.add(DetectedFace(
          id: face.id,
          boundingBox: face.boundingBox,
          landmarks: _convertLandmarks(face.landmarks),
          headEulerAngleY: face.headEulerAngleY,
          headEulerAngleZ: face.headEulerAngleZ,
          embedding: embedding,
          confidence: face.headEulerAngleY != null ? 1.0 : 0.8, // ML Kit doesn't provide confidence
        ));
      }
      
      return detectedFaces;
    } catch (e) {
      throw FaceDetectionException('Failed to detect faces: $e');
    }
  }

  /// Detect faces in a media asset
  Future<List<DetectedFace>> detectFacesInAsset(AssetEntity asset) async {
    final file = await asset.file;
    if (file == null) {
      throw FaceDetectionException('Could not access asset file');
    }
    return detectFacesInFile(file);
  }

  // =========================================================================
  // FACE EMBEDDING GENERATION
  // =========================================================================

  Future<List<double>?> _generateFaceEmbedding(File imageFile, Face face) async {
    if (_faceEmbeddingInterpreter == null) return null;

    try {
      // Load and preprocess image
      final imageBytes = await imageFile.readAsBytes();
      final originalImage = img.decodeImage(imageBytes);
      
      if (originalImage == null) return null;

      // Extract face region
      final faceRect = face.boundingBox;
      final faceImage = img.copyCrop(
        originalImage,
        x: faceRect.left.round(),
        y: faceRect.top.round(),
        width: faceRect.width.round(),
        height: faceRect.height.round(),
      );

      // Resize to model input size
      final resizedImage = img.copyResize(
        faceImage,
        width: _inputSize,
        height: _inputSize,
        interpolation: img.Interpolation.linear,
      );

      // Convert to normalized float array
      final input = _imageToInputArray(resizedImage);
      
      // Run inference
      final output = List.filled(_embeddingSize, 0.0).reshape([1, _embeddingSize]);
      await _faceEmbeddingInterpreter!.run(input, output);
      
      // Normalize embedding
      final embedding = output[0] as List<double>;
      return _normalizeEmbedding(embedding);
    } catch (e) {
      print('Failed to generate face embedding: $e');
      return null;
    }
  }

  List<List<double>> _imageToInputArray(img.Image image) {
    final input = List.generate(
      _inputSize,
      (y) => List.generate(
        _inputSize,
        (x) {
          final pixel = image.getPixel(x, y);
          // Normalize to [-1, 1] range
          return [
            (pixel.r - 127.5) / 127.5,
            (pixel.g - 127.5) / 127.5,
            (pixel.b - 127.5) / 127.5,
          ];
        },
      ),
    );
    
    // Reshape to [1, 112, 112, 3]
    return [input.expand((row) => row).expand((pixel) => pixel).toList()];
  }

  List<double> _normalizeEmbedding(List<double> embedding) {
    double sum = 0.0;
    for (final value in embedding) {
      sum += value * value;
    }
    final norm = sum.sqrt();
    
    return embedding.map((value) => value / norm).toList();
  }

  // =========================================================================
  // FACE CLUSTERING
  // =========================================================================

  /// Cluster faces using DBSCAN algorithm
  Future<List<FaceCluster>> clusterFaces(List<DetectedFace> faces) async {
    final facesWithEmbeddings = faces.where((f) => f.embedding != null).toList();
    if (facesWithEmbeddings.isEmpty) return [];

    try {
      // Calculate similarity matrix
      final similarityMatrix = _calculateSimilarityMatrix(facesWithEmbeddings);
      
      // Run DBSCAN clustering
      final clusters = _runDBSCAN(similarityMatrix, facesWithEmbeddings);
      
      // Create cluster objects
      final faceClusters = <FaceCluster>[];
      for (int i = 0; i < clusters.length; i++) {
        final clusterFaces = clusters[i]
            .map((index) => facesWithEmbeddings[index])
            .toList();
        
        faceClusters.add(FaceCluster(
          id: 'cluster_$i',
          faces: clusterFaces,
          representativeFace: _findRepresentativeFace(clusterFaces),
          confidence: _calculateClusterConfidence(clusterFaces),
        ));
      }
      
      return faceClusters;
    } catch (e) {
      throw FaceDetectionException('Failed to cluster faces: $e');
    }
  }

  List<List<double>> _calculateSimilarityMatrix(List<DetectedFace> faces) {
    final matrix = List.generate(
      faces.length,
      (i) => List.filled(faces.length, 0.0),
    );

    for (int i = 0; i < faces.length; i++) {
      for (int j = i; j < faces.length; j++) {
        final similarity = _calculateCosineSimilarity(
          faces[i].embedding!,
          faces[j].embedding!,
        );
        matrix[i][j] = similarity;
        matrix[j][i] = similarity;
      }
    }

    return matrix;
  }

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

  List<List<int>> _runDBSCAN(List<List<double>> similarityMatrix, List<DetectedFace> faces) {
    final visited = List.filled(faces.length, false);
    final clusters = <List<int>>[];
    final noise = <int>[];

    for (int i = 0; i < faces.length; i++) {
      if (visited[i]) continue;

      visited[i] = true;
      final neighbors = _getNeighbors(similarityMatrix, i);

      if (neighbors.length < 2) {
        noise.add(i);
      } else {
        final cluster = <int>[i];
        clusters.add(cluster);
        _expandCluster(similarityMatrix, neighbors, cluster, visited);
      }
    }

    return clusters;
  }

  List<int> _getNeighbors(List<List<double>> similarityMatrix, int pointIndex) {
    final neighbors = <int>[];
    for (int i = 0; i < similarityMatrix.length; i++) {
      if (similarityMatrix[pointIndex][i] >= _similarityThreshold) {
        neighbors.add(i);
      }
    }
    return neighbors;
  }

  void _expandCluster(
    List<List<double>> similarityMatrix,
    List<int> neighbors,
    List<int> cluster,
    List<bool> visited,
  ) {
    int i = 0;
    while (i < neighbors.length) {
      final neighborIndex = neighbors[i];
      
      if (!visited[neighborIndex]) {
        visited[neighborIndex] = true;
        final newNeighbors = _getNeighbors(similarityMatrix, neighborIndex);
        if (newNeighbors.length >= 2) {
          neighbors.addAll(newNeighbors.where((n) => !neighbors.contains(n)));
        }
      }
      
      if (!cluster.contains(neighborIndex)) {
        cluster.add(neighborIndex);
      }
      
      i++;
    }
  }

  DetectedFace _findRepresentativeFace(List<DetectedFace> faces) {
    // Find the face with highest confidence
    return faces.reduce((a, b) => a.confidence > b.confidence ? a : b);
  }

  double _calculateClusterConfidence(List<DetectedFace> faces) {
    if (faces.isEmpty) return 0.0;
    
    final totalConfidence = faces.fold<double>(
      0.0,
      (sum, face) => sum + face.confidence,
    );
    
    return totalConfidence / faces.length;
  }

  // =========================================================================
  // PERSON MATCHING
  // =========================================================================

  /// Match detected faces to known persons
  Future<List<PersonMatch>> matchFacesToPersons(
    List<DetectedFace> faces,
    List<Person> knownPersons,
  ) async {
    final matches = <PersonMatch>[];

    for (final face in faces) {
      if (face.embedding == null) continue;

      Person? bestMatch;
      double bestScore = 0.0;

      for (final person in knownPersons) {
        for (final referenceEmbedding in person.referenceEmbeddings) {
          final score = _calculateCosineSimilarity(face.embedding!, referenceEmbedding);
          if (score > bestScore && score > _similarityThreshold) {
            bestScore = score;
            bestMatch = person;
          }
        }
      }

      if (bestMatch != null) {
        matches.add(PersonMatch(
          face: face,
          person: bestMatch,
          confidence: bestScore,
        ));
      }
    }

    return matches;
  }

  // =========================================================================
  // UTILITIES
  // =========================================================================

  Map<FaceLandmarkType, FaceLandmark> _convertLandmarks(
    Map<FaceLandmarkType, FaceLandmark>? landmarks,
  ) {
    if (landmarks == null) return {};
    return landmarks;
  }

  /// Dispose resources
  void dispose() {
    _faceDetector.close();
    _faceEmbeddingInterpreter?.close();
  }
}

// =========================================================================
// DATA MODELS
// =========================================================================

class DetectedFace {
  final int id;
  final Rect boundingBox;
  final Map<FaceLandmarkType, FaceLandmark> landmarks;
  final double? headEulerAngleY;
  final double? headEulerAngleZ;
  final List<double>? embedding;
  final double confidence;

  DetectedFace({
    required this.id,
    required this.boundingBox,
    required this.landmarks,
    this.headEulerAngleY,
    this.headEulerAngleZ,
    this.embedding,
    required this.confidence,
  });
}

class FaceCluster {
  final String id;
  final List<DetectedFace> faces;
  final DetectedFace representativeFace;
  final double confidence;

  FaceCluster({
    required this.id,
    required this.faces,
    required this.representativeFace,
    required this.confidence,
  });
}

class Person {
  final String id;
  final String name;
  final List<String> photoIds;
  final List<List<double>> referenceEmbeddings;
  final DateTime createdAt;
  final DateTime? lastSeen;

  Person({
    required this.id,
    required this.name,
    required this.photoIds,
    required this.referenceEmbeddings,
    required this.createdAt,
    this.lastSeen,
  });
}

class PersonMatch {
  final DetectedFace face;
  final Person person;
  final double confidence;

  PersonMatch({
    required this.face,
    required this.person,
    required this.confidence,
  });
}

// =========================================================================
// EXCEPTIONS
// =========================================================================

class FaceDetectionException implements Exception {
  final String message;
  FaceDetectionException(this.message);
  
  @override
  String toString() => 'FaceDetectionException: $message';
}
