import 'dart:async';
import 'dart:isolate';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../database/face_database_service.dart';
import '../database/models/face_models.dart';
import 'face_detection_service.dart';
import 'person_tagging_service.dart';

/// Background service for processing face detection jobs
/// Runs in isolates to avoid blocking the UI
class FaceProcessingService {
  static FaceProcessingService? _instance;
  static FaceProcessingService get instance => _instance ??= FaceProcessingService._();
  
  FaceProcessingService._();

  final _faceDbService = FaceDatabaseService.instance;
  final _faceDetectionService = FaceDetectionService.instance;
  final _personTaggingService = PersonTaggingService.instance;
  final _uuid = const Uuid();

  bool _isProcessing = false;
  Timer? _processingTimer;

  // =========================================================================
  // JOB MANAGEMENT
  // =========================================================================

  /// Queue a photo for face processing
  Future<String> queuePhotoForProcessing(String photoId, {String? albumId}) async {
    final job = FaceProcessingJob(
      id: _uuid.v4(),
      photoId: photoId,
      albumId: albumId,
      status: ProcessingStatus.pending,
      createdAt: DateTime.now(),
    );

    await _faceDbService.insertProcessingJob(job);
    
    // Trigger processing if not already running
    _scheduleProcessing();
    
    return job.id;
  }

  /// Queue multiple photos for processing
  Future<List<String>> queuePhotosForProcessing(List<String> photoIds, {String? albumId}) async {
    final jobIds = <String>[];
    
    for (final photoId in photoIds) {
      final jobId = await queuePhotoForProcessing(photoId, albumId: albumId);
      jobIds.add(jobId);
    }
    
    return jobIds;
  }

  /// Get processing status for a job
  Future<FaceProcessingJob?> getJobStatus(String jobId) async {
    return await _faceDbService.getProcessingJob(jobId);
  }

  /// Cancel a processing job
  Future<void> cancelJob(String jobId) async {
    final job = await _faceDbService.getProcessingJob(jobId);
    if (job != null && job.status == ProcessingStatus.pending) {
      await _faceDbService.updateProcessingJob(
        job.copyWith(status: ProcessingStatus.cancelled),
      );
    }
  }

  // =========================================================================
  // BACKGROUND PROCESSING
  // =========================================================================

  void _scheduleProcessing() {
    if (_isProcessing) return;
    
    _processingTimer = Timer(Duration(milliseconds: 100), () {
      _processPendingJobs();
    });
  }

  Future<void> _processPendingJobs() async {
    if (_isProcessing) return;
    
    _isProcessing = true;
    
    try {
      while (true) {
        final jobs = await _faceDbService.getPendingJobs(limit: 1);
        if (jobs.isEmpty) break;
        
        final job = jobs.first;
        await _processJob(job);
      }
    } finally {
      _isProcessing = false;
    }
  }

  Future<void> _processJob(FaceProcessingJob job) async {
    // Update job status to processing
    await _faceDbService.updateProcessingJob(
      job.copyWith(
        status: ProcessingStatus.processing,
        startedAt: DateTime.now(),
      ),
    );

    try {
      // Process faces in isolate
      final result = await _processPhotoInIsolate(job.photoId);
      
      // Save results
      await _saveProcessingResult(job.photoId, result);
      
      // Update job as completed
      await _faceDbService.updateProcessingJob(
        job.copyWith(
          status: ProcessingStatus.completed,
          completedAt: DateTime.now(),
          faceCount: result.faces.length,
        ),
      );
      
      // Trigger clustering if enough unclustered faces
      await _checkAndRunClustering();
      
    } catch (e) {
      // Update job as failed
      await _faceDbService.updateProcessingJob(
        job.copyWith(
          status: ProcessingStatus.failed,
          completedAt: DateTime.now(),
          errorMessage: e.toString(),
        ),
      );
    }
  }

  Future<FaceProcessingResult> _processPhotoInIsolate(String photoId) async {
    // In a real implementation, this would run in a separate isolate
    // For simplicity, we're running it directly here
    return await _computeFaceProcessing(photoId);
  }

  Future<FaceProcessingResult> _computeFaceProcessing(String photoId) async {
    // This would be the isolate entry point
    final receivePort = ReceivePort();
    
    // Send processing request
    // Isolate.spawn(_faceProcessingIsolate, {
    //   'sendPort': receivePort.sendPort,
    //   'photoId': photoId,
    // });
    
    // For now, process directly
    final faces = await _faceDetectionService.detectFacesInFile(
      // File(photoPath)
      // Would need to get file path from photoId
      File(''), // Placeholder
    );
    
    return FaceProcessingResult(
      photoId: photoId,
      faces: faces,
    );
  }

  Future<void> _saveProcessingResult(String photoId, FaceProcessingResult result) async {
    // Convert and save faces
    final faceEntities = result.faces.map((face) => FaceEntity(
      id: _uuid.v4(),
      photoId: photoId,
      faceIndex: result.faces.indexOf(face),
      boundingBox: face.boundingBox,
      landmarks: face.landmarks.map((k, v) => MapEntry(k.toString(), v)).cast(),
      confidence: face.confidence,
      embedding: face.embedding != null 
          ? Uint8List.fromList(face.embedding!.map((e) => e * 1000).toList())
          : null,
      createdAt: DateTime.now(),
    )).toList();

    await _faceDbService.insertFaces(faceEntities);

    // Create photo-face relationships
    for (int i = 0; i < faceEntities.length; i++) {
      final photoFace = PhotoFaceEntity(
        id: _uuid.v4(),
        photoId: photoId,
        faceId: faceEntities[i].id,
        faceIndex: i,
        createdAt: DateTime.now(),
      );
      await _faceDbService.insertPhotoFace(photoFace);
    }
  }

  Future<void> _checkAndRunClustering() async {
    final unclusteredCount = await _getUnclusteredFaceCount();
    if (unclusteredCount >= 10) {
      await _personTaggingService.processUnclusteredFaces();
    }
  }

  Future<int> _getUnclusteredFaceCount() async {
    // Would need to implement this method in FaceDatabaseService
    return 0; // Placeholder
  }

  // =========================================================================
  // BATCH OPERATIONS
  // =========================================================================

  /// Process all unprocessed photos in an album
  Future<BatchProcessingResult> processAlbum(String albumId) async {
    // Get all photos in album
    // final photos = await getPhotosInAlbum(albumId);
    final photoIds = <String>[]; // Placeholder
    
    // Queue all photos
    final jobIds = await queuePhotosForProcessing(photoIds, albumId: albumId);
    
    return BatchProcessingResult(
      albumId: albumId,
      totalPhotos: photoIds.length,
      queuedJobs: jobIds,
    );
  }

  /// Process entire library
  Future<void> processLibrary({int batchSize = 50}) async {
    // Get all unprocessed photos
    // final photoIds = await getUnprocessedPhotoIds();
    final photoIds = <String>[]; // Placeholder
    
    // Process in batches
    for (int i = 0; i < photoIds.length; i += batchSize) {
      final batch = photoIds.skip(i).take(batchSize).toList();
      await queuePhotosForProcessing(batch);
      
      // Wait a bit between batches to avoid overwhelming the system
      await Future.delayed(Duration(milliseconds: 100));
    }
  }

  // =========================================================================
  // STATISTICS AND MONITORING
  // =========================================================================

  Future<ProcessingStatistics> getStatistics() async {
    final totalJobs = await _getTotalJobCount();
    final pendingJobs = await _getPendingJobCount();
    final processingJobs = await _getProcessingJobCount();
    final completedJobs = await _getCompletedJobCount();
    final failedJobs = await _getFailedJobCount();
    
    return ProcessingStatistics(
      totalJobs: totalJobs,
      pendingJobs: pendingJobs,
      processingJobs: processingJobs,
      completedJobs: completedJobs,
      failedJobs: failedJobs,
      isCurrentlyProcessing: _isProcessing,
    );
  }

  Future<int> _getTotalJobCount() async {
    // Implementation needed
    return 0;
  }

  Future<int> _getPendingJobCount() async {
    // Implementation needed
    return 0;
  }

  Future<int> _getProcessingJobCount() async {
    // Implementation needed
    return 0;
  }

  Future<int> _getCompletedJobCount() async {
    // Implementation needed
    return 0;
  }

  Future<int> _getFailedJobCount() async {
    // Implementation needed
    return 0;
  }

  // =========================================================================
  // CLEANUP
  // =========================================================================

  Future<void> cleanup() async {
    _processingTimer?.cancel();
    await _faceDbService.cleanupOldJobs();
  }

  void dispose() {
    _processingTimer?.cancel();
  }
}

// =========================================================================
// ISOLATE PROCESSING
// =========================================================================

void _faceProcessingIsolate(Map<String, dynamic> params) async {
  final sendPort = params['sendPort'] as SendPort;
  final photoId = params['photoId'] as String;
  
  try {
    // Initialize services in isolate
    // final faceService = FaceDetectionService();
    
    // Process photo
    // final faces = await faceService.detectFacesInFile(File(photoPath));
    
    // Send result back
    sendPort.send(FaceProcessingResult(
      photoId: photoId,
      faces: [], // Placeholder
    ));
  } catch (e) {
    sendPort.send({
      'error': e.toString(),
      'photoId': photoId,
    });
  }
}

// =========================================================================
// DATA MODELS
// =========================================================================

class FaceProcessingResult {
  final String photoId;
  final List<DetectedFace> faces;

  FaceProcessingResult({
    required this.photoId,
    required this.faces,
  });
}

class BatchProcessingResult {
  final String albumId;
  final int totalPhotos;
  final List<String> queuedJobs;

  BatchProcessingResult({
    required this.albumId,
    required this.totalPhotos,
    required this.queuedJobs,
  });
}

class ProcessingStatistics {
  final int totalJobs;
  final int pendingJobs;
  final int processingJobs;
  final int completedJobs;
  final int failedJobs;
  final bool isCurrentlyProcessing;

  ProcessingStatistics({
    required this.totalJobs,
    required this.pendingJobs,
    required this.processingJobs,
    required this.completedJobs,
    required this.failedJobs,
    required this.isCurrentlyProcessing,
  });
}

// =========================================================================
// PROVIDERS
// =========================================================================

final faceProcessingServiceProvider = Provider<FaceProcessingService>((ref) {
  return FaceProcessingService.instance;
});

final processingStatisticsProvider = FutureProvider<ProcessingStatistics>((ref) async {
  return await FaceProcessingService.instance.getStatistics();
});

final processingQueueProvider = StreamProvider<List<FaceProcessingJob>>((ref) async* {
  // Stream of pending/processing jobs
  // Implementation needed
  yield [];
});

// =========================================================================
// EXCEPTIONS
// =========================================================================

class FaceProcessingException implements Exception {
  final String message;
  FaceProcessingException(this.message);
  
  @override
  String toString() => 'FaceProcessingException: $message';
}
