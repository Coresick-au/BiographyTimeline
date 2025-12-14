import 'dart:io';
import 'dart:typed_data';
import 'package:image/image.dart' as img;
import '../../../shared/models/media_asset.dart';
import '../../../shared/models/person.dart';

/// Result of face detection in an image
class FaceDetectionResult {
  final List<DetectedFace> faces;
  final String imagePath;
  final DateTime processedAt;

  const FaceDetectionResult({
    required this.faces,
    required this.imagePath,
    required this.processedAt,
  });
}

/// Information about a detected face
class DetectedFace {
  final Rect boundingBox;
  final double confidence;
  final Person? matchedPerson;
  final Map<String, dynamic> landmarks;

  const DetectedFace({
    required this.boundingBox,
    required this.confidence,
    this.matchedPerson,
    required this.landmarks,
  });
}

/// Service for detecting faces in photos and matching them to known people
class FaceDetectionService {
  static const double _confidenceThreshold = 0.7;
  static const int _maxImageSize = 800;

  /// Detect faces in a media asset
  Future<FaceDetectionResult?> detectFacesInAsset(MediaAsset asset) async {
    if (asset.type != AssetType.photo) {
      return null;
    }

    try {
      final file = File(asset.localPath);
      if (!await file.exists()) {
        return null;
      }

      // Read and preprocess image
      final imageBytes = await file.readAsBytes();
      final image = img.decodeImage(imageBytes);
      
      if (image == null) {
        return null;
      }

      // Resize image if too large for processing
      final processedImage = _preprocessImage(image);
      
      // Detect faces (simplified implementation)
      final faces = await _detectFaces(processedImage);
      
      return FaceDetectionResult(
        faces: faces,
        imagePath: asset.localPath,
        processedAt: DateTime.now(),
      );
    } catch (e) {
      print('Error detecting faces in asset ${asset.id}: $e');
      return null;
    }
  }

  /// Preprocess image for face detection
  img.Image _preprocessImage(img.Image image) {
    // Resize if image is too large
    if (image.width > _maxImageSize || image.height > _maxImageSize) {
      final aspectRatio = image.width / image.height;
      int newWidth, newHeight;
      
      if (image.width > image.height) {
        newWidth = _maxImageSize;
        newHeight = (_maxImageSize / aspectRatio).round();
      } else {
        newHeight = _maxImageSize;
        newWidth = (_maxImageSize * aspectRatio).round();
      }
      
      return img.copyResize(image, width: newWidth, height: newHeight);
    }
    
    return image;
  }

  /// Detect faces in an image (simplified placeholder implementation)
  Future<List<DetectedFace>> _detectFaces(img.Image image) async {
    // This is a simplified implementation
    // In a real app, you would use ML Kit or another face detection library
    
    final faces = <DetectedFace>[];
    
    // Simulate face detection with random positions
    // Replace this with actual ML Kit integration
    final numFaces = (image.width * image.height) > 50000 ? 2 : 1;
    
    for (int i = 0; i < numFaces; i++) {
      final face = DetectedFace(
        boundingBox: Rect.fromLTWH(
          (image.width * 0.3 + i * 100).toDouble(),
          (image.height * 0.2).toDouble(),
          100.0,
          120.0,
        ),
        confidence: 0.85 + (i * 0.05),
        landmarks: _generateMockLandmarks(),
      );
      faces.add(face);
    }
    
    return faces.where((f) => f.confidence >= _confidenceThreshold).toList();
  }

  /// Generate mock face landmarks (placeholder)
  Map<String, dynamic> _generateMockLandmarks() {
    return {
      'leftEye': const Point(30, 40),
      'rightEye': const Point(70, 40),
      'nose': const Point(50, 60),
      'mouth': const Point(50, 80),
    };
  }

  /// Match detected faces to known people
  Future<List<DetectedFace>> matchFacesToPeople(
    List<DetectedFace> faces,
    List<Person> knownPeople,
  ) async {
    // Simplified matching logic
    // In a real app, use face recognition or embeddings
    
    final matchedFaces = <DetectedFace>[];
    
    for (final face in faces) {
      Person? matchedPerson;
      
      // Simple mock matching based on position
      if (knownPeople.isNotEmpty && face.boundingBox.left < 200) {
        matchedPerson = knownPeople.first;
      }
      
      matchedFaces.add(face.copyWith(matchedPerson: matchedPerson));
    }
    
    return matchedFaces;
  }

  /// Batch process multiple assets
  Future<List<FaceDetectionResult>> processBatch(
    List<MediaAsset> assets, {
    Function(int processed, int total)? onProgress,
  }) async {
    final results = <FaceDetectionResult>[];
    
    for (int i = 0; i < assets.length; i++) {
      final asset = assets[i];
      final result = await detectFacesInAsset(asset);
      
      if (result != null) {
        results.add(result);
      }
      
      onProgress?.call(i + 1, assets.length);
    }
    
    return results;
  }

  /// Extract face thumbnail for identification
  Future<Uint8List?> extractFaceThumbnail(
    String imagePath,
    Rect boundingBox,
  ) async {
    try {
      final file = File(imagePath);
      final imageBytes = await file.readAsBytes();
      final image = img.decodeImage(imageBytes);
      
      if (image == null) {
        return null;
      }
      
      // Extract face region with padding
      final padding = 20;
      final faceX = (boundingBox.left - padding).clamp(0.0, image.width.toDouble()).toInt();
      final faceY = (boundingBox.top - padding).clamp(0.0, image.height.toDouble()).toInt();
      final faceWidth = (boundingBox.width + padding * 2).clamp(0.0, image.width - faceX.toDouble()).toInt();
      final faceHeight = (boundingBox.height + padding * 2).clamp(0.0, image.height - faceY.toDouble()).toInt();
      
      final faceImage = img.copyCrop(
        image,
        x: faceX,
        y: faceY,
        width: faceWidth,
        height: faceHeight,
      );
      
      // Resize to standard thumbnail size
      final thumbnail = img.copyResize(faceImage, width: 100, height: 100);
      
      return Uint8List.fromList(img.encodeJpg(thumbnail));
    } catch (e) {
      print('Error extracting face thumbnail: $e');
      return null;
    }
  }

  /// Save face detection results to database
  Future<void> saveFaceDetectionResults(
    String assetId,
    FaceDetectionResult result,
  ) async {
    // TODO: Implement database storage
    // This would store the face detection results in a separate table
    // for quick retrieval and face matching
  }

  /// Get stored face detection results for an asset
  Future<FaceDetectionResult?> getStoredResults(String assetId) async {
    // TODO: Implement database retrieval
    // This would fetch previously computed face detection results
    return null;
  }
}

/// Extension to add copyWith to DetectedFace
extension DetectedFaceCopyWith on DetectedFace {
  DetectedFace copyWith({
    Rect? boundingBox,
    double? confidence,
    Person? matchedPerson,
    Map<String, dynamic>? landmarks,
  }) {
    return DetectedFace(
      boundingBox: boundingBox ?? this.boundingBox,
      confidence: confidence ?? this.confidence,
      matchedPerson: matchedPerson ?? this.matchedPerson,
      landmarks: landmarks ?? this.landmarks,
    );
  }
}
