import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_quill_to_pdf/flutter_quill_to_pdf.dart';
import 'package:pdf/pdf.dart';
import 'package:archive/archive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:uuid/uuid.dart';
import '../database/database_service.dart';
import '../models/media_asset.dart';
import '../models/timeline_event.dart';
import '../security/encryption_service.dart';

/// Unified data export service for Timeline Biography App
/// Handles PDF, ZIP, and JSON exports with progress tracking
class DataExportService {
  static DataExportService? _instance;
  static DataExportService get instance => _instance ??= DataExportService._();
  
  DataExportService._();

  final _uuid = const Uuid();
  final _dbService = DatabaseService.instance;
  final _encryptionService = EncryptionService.instance;

  // Export progress tracking
  final Map<String, ExportProgress> _activeExports = {};
  final StreamController<ExportProgress> _progressController = 
      StreamController<ExportProgress>.broadcast();

  // Export configuration
  static const int _chunkSize = 100; // Items per chunk for large exports
  static const int _maxZipSize = 1024 * 1024 * 100; // 100MB per ZIP

  // =========================================================================
  // PUBLIC API
  // =========================================================================

  /// Export timeline as PDF book
  Future<String> exportToPDF({
    required List<String> eventIds,
    PDFExportOptions? options,
    ProgressCallback? onProgress,
  }) async {
    final exportId = _uuid.v4();
    final progress = ExportProgress(
      id: exportId,
      type: ExportType.pdf,
      status: ExportStatus.preparing,
      startTime: DateTime.now(),
    );
    
    _activeExports[exportId] = progress;
    _progressController.add(progress);

    try {
      // Update progress
      _updateProgress(exportId, status: ExportStatus.processing, progress: 0.1);
      
      // Get timeline events
      final events = await _getTimelineEvents(eventIds);
      _updateProgress(exportId, progress: 0.3);
      
      // Generate PDF
      final pdfPath = await _generatePDF(events, options ?? PDFExportOptions());
      _updateProgress(exportId, progress: 0.9);
      
      // Complete
      _updateProgress(exportId, 
        status: ExportStatus.completed, 
        progress: 1.0,
        outputPath: pdfPath,
      );
      
      return pdfPath;
    } catch (e) {
      _updateProgress(exportId, 
        status: ExportStatus.failed, 
        error: e.toString(),
      );
      rethrow;
    }
  }

  /// Export timeline as ZIP archive
  Future<String> exportToZIP({
    required List<String> eventIds,
    required List<String> mediaIds,
    ZIPExportOptions? options,
    ProgressCallback? onProgress,
  }) async {
    final exportId = _uuid.v4();
    final progress = ExportProgress(
      id: exportId,
      type: ExportType.zip,
      status: ExportStatus.preparing,
      startTime: DateTime.now(),
    );
    
    _activeExports[exportId] = progress;
    _progressController.add(progress);

    try {
      // Get data
      _updateProgress(exportId, status: ExportStatus.processing, progress: 0.05);
      final events = await _getTimelineEvents(eventIds);
      final media = await _getMediaAssets(mediaIds);
      
      // Create ZIP
      final zipPath = await _createZIPArchive(
        events, 
        media, 
        options ?? ZIPExportOptions(),
        (progress) => _updateProgress(exportId, progress: 0.1 + progress * 0.8),
      );
      
      // Complete
      _updateProgress(exportId, 
        status: ExportStatus.completed, 
        progress: 1.0,
        outputPath: zipPath,
      );
      
      return zipPath;
    } catch (e) {
      _updateProgress(exportId, 
        status: ExportStatus.failed, 
        error: e.toString(),
      );
      rethrow;
    }
  }

  /// Export timeline as JSON
  Future<String> exportToJSON({
    required List<String> eventIds,
    required List<String> mediaIds,
    JSONExportOptions? options,
    ProgressCallback? onProgress,
  }) async {
    final exportId = _uuid.v4();
    final progress = ExportProgress(
      id: exportId,
      type: ExportType.json,
      status: ExportStatus.preparing,
      startTime: DateTime.now(),
    );
    
    _activeExports[exportId] = progress;
    _progressController.add(progress);

    try {
      // Get data
      _updateProgress(exportId, status: ExportStatus.processing, progress: 0.1);
      final events = await _getTimelineEvents(eventIds);
      final media = await _getMediaAssets(mediaIds);
      
      // Generate JSON
      final jsonPath = await _generateJSON(
        events, 
        media, 
        options ?? JSONExportOptions(),
        (progress) => _updateProgress(exportId, progress: 0.2 + progress * 0.7),
      );
      
      // Complete
      _updateProgress(exportId, 
        status: ExportStatus.completed, 
        progress: 1.0,
        outputPath: jsonPath,
      );
      
      return jsonPath;
    } catch (e) {
      _updateProgress(exportId, 
        status: ExportStatus.failed, 
        error: e.toString(),
      );
      rethrow;
    }
  }

  /// Get export progress
  ExportProgress? getExportProgress(String exportId) {
    return _activeExports[exportId];
  }

  /// Stream of export progress updates
  Stream<ExportProgress> get exportProgressStream => _progressController.stream;

  /// Cancel active export
  Future<void> cancelExport(String exportId) async {
    final progress = _activeExports[exportId];
    if (progress != null && progress.status == ExportStatus.processing) {
      _updateProgress(exportId, status: ExportStatus.cancelled);
    }
  }

  /// Clean up completed exports
  void cleanupCompletedExports() {
    _activeExports.removeWhere((id, progress) => 
        progress.status == ExportStatus.completed ||
        progress.status == ExportStatus.failed ||
        progress.status == ExportStatus.cancelled);
  }

  // =========================================================================
  // PDF EXPORT
  // =========================================================================

  Future<String> _generatePDF(
    List<TimelineEvent> events,
    PDFExportOptions options,
  ) async {
    final pdf = PdfDocument(defOrientation: PdfPageOrientation.portrait);
    
    // Add title page
    if (options.includeTitlePage) {
      await _addTitlePage(pdf, options);
    }
    
    // Add table of contents
    if (options.includeTableOfContents) {
      await _addTableOfContents(pdf, events);
    }
    
    // Add events
    for (int i = 0; i < events.length; i++) {
      await _addEventToPDF(pdf, events[i], options);
      
      // Add page break between events
      if (i < events.length - 1 && options.pageBreakBetweenEvents) {
        pdf.addPage();
      }
    }
    
    // Save PDF
    final dir = await getTemporaryDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final filename = options.customFilename ?? 
        'timeline_export_$timestamp.pdf';
    final filePath = path.join(dir.path, filename);
    
    final file = File(filePath);
    await file.writeAsBytes(await pdf.save());
    
    return filePath;
  }

  Future<void> _addTitlePage(PdfDocument pdf, PDFExportOptions options) async {
    final page = PdfPage(
      pdf,
      margin: const PdfEdgeInsets.all(50),
    );
    
    // Add title
    page.drawText(
      options.title ?? 'Timeline Biography',
      fontSize: 32,
      font: PdfFont.helveticaBold(),
      alignment: PdfTextAlign.center,
    );
    
    // Add subtitle
    if (options.subtitle != null) {
      page.drawText(
        options.subtitle!,
        fontSize: 18,
        font: PdfFont.helvetica(),
        alignment: PdfTextAlign.center,
      );
    }
    
    // Add export date
    page.drawText(
      'Generated on ${DateTime.now().toString().split('.')[0]}',
      fontSize: 12,
      font: PdfFont.helvetica(),
      alignment: PdfTextAlign.center,
    );
  }

  Future<void> _addTableOfContents(PdfDocument pdf, List<TimelineEvent> events) async {
    final page = PdfPage(
      pdf,
      margin: const PdfEdgeInsets.all(50),
    );
    
    page.drawText(
      'Table of Contents',
      fontSize: 24,
      font: PdfFont.helveticaBold(),
    );
    
    double yPosition = 100;
    for (int i = 0; i < events.length; i++) {
      final event = events[i];
      
      page.drawText(
        '${i + 1}. ${event.title}',
        x: 50,
        y: yPosition,
        fontSize: 14,
        font: PdfFont.helvetica(),
      );
      
      if (event.startDate != null) {
        page.drawText(
          '   ${_formatDate(event.startDate!)}',
          x: 50,
          y: yPosition + 15,
          fontSize: 12,
          font: PdfFont.helveticaOblique(),
        );
      }
      
      yPosition += 35;
    }
  }

  Future<void> _addEventToPDF(
    PdfDocument pdf,
    TimelineEvent event,
    PDFExportOptions options,
  ) async {
    final page = PdfPage(
      pdf,
      margin: const PdfEdgeInsets.all(50),
    );
    
    double yPosition = 50;
    
    // Add title
    page.drawText(
      event.title,
      x: 50,
      y: yPosition,
      fontSize: 20,
      font: PdfFont.helveticaBold(),
    );
    yPosition += 30;
    
    // Add date
    if (event.startDate != null) {
      page.drawText(
        _formatDate(event.startDate!),
        x: 50,
        y: yPosition,
        fontSize: 14,
        font: PdfFont.helvetica(),
      );
      yPosition += 20;
    }
    
    // Add location
    if (event.location != null) {
      page.drawText(
        '📍 ${event.location!.name}',
        x: 50,
        y: yPosition,
        fontSize: 12,
        font: PdfFont.helvetica(),
      );
      yPosition += 20;
    }
    
    // Add description
    if (event.description != null && event.description!.isNotEmpty) {
      // Convert Quill delta to plain text for PDF
      final plainText = _quillDeltaToPlainText(event.description!);
      
      // Handle multi-line text
      final lines = plainText.split('\n');
      for (final line in lines) {
        page.drawText(
          line,
          x: 50,
          y: yPosition,
          fontSize: 12,
          font: PdfFont.helvetica(),
        );
        yPosition += 15;
      }
    }
    
    // Add tags
    if (event.tags.isNotEmpty) {
      page.drawText(
        'Tags: ${event.tags.join(', ')}',
        x: 50,
        y: yPosition,
        fontSize: 10,
        font: PdfFont.helveticaOblique(),
      );
    }
  }

  // =========================================================================
  // ZIP EXPORT
  // =========================================================================

  Future<String> _createZIPArchive(
    List<TimelineEvent> events,
    List<MediaAsset> media,
    ZIPExportOptions options,
    ProgressCallback onProgress,
  ) async {
    final archive = Archive();
    
    // Add metadata
    if (options.includeMetadata) {
      _addMetadataToArchive(archive, events, media);
    }
    
    // Add events
    if (options.includeEvents) {
      await _addEventsToArchive(archive, events, options);
    }
    
    // Add media files
    if (options.includeMedia) {
      await _addMediaToArchive(archive, media, options, onProgress);
    }
    
    // Save ZIP
    final dir = await getTemporaryDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final filename = options.customFilename ?? 
        'timeline_archive_$timestamp.zip';
    final filePath = path.join(dir.path, filename);
    
    final zipFile = File(filePath);
    await zipFile.writeAsBytes(ZipEncoder().encode(archive)!);
    
    return filePath;
  }

  void _addMetadataToArchive(
    Archive archive,
    List<TimelineEvent> events,
    List<MediaAsset> media,
  ) {
    final metadata = {
      'exportDate': DateTime.now().toIso8601String(),
      'version': '1.0.0',
      'eventCount': events.length,
      'mediaCount': media.length,
      'app': 'Timeline Biography',
    };
    
    final metadataBytes = utf8.encode(jsonEncode(metadata));
    archive.addFile(ArchiveFile('metadata.json', metadataBytes.length, metadataBytes));
  }

  Future<void> _addEventsToArchive(
    Archive archive,
    List<TimelineEvent> events,
    ZIPExportOptions options,
  ) async {
    final eventsData = events.map((e) => e.toJson()).toList();
    final eventsBytes = utf8.encode(jsonEncode(eventsData));
    
    archive.addFile(
      ArchiveFile('events/events.json', eventsBytes.length, eventsBytes)
    );
    
    // Add individual event files if requested
    if (options.includeIndividualFiles) {
      for (final event in events) {
        final eventJson = jsonEncode(event.toJson());
        final eventBytes = utf8.encode(eventJson);
        final filename = 'events/${event.id}.json';
        
        archive.addFile(ArchiveFile(filename, eventBytes.length, eventBytes));
      }
    }
  }

  Future<void> _addMediaToArchive(
    Archive archive,
    List<MediaAsset> media,
    ZIPExportOptions options,
    ProgressCallback onProgress,
  ) async {
    for (int i = 0; i < media.length; i++) {
      final asset = media[i];
      
      // Add original file
      if (options.includeOriginalFiles) {
        final file = File(asset.localPath);
        if (await file.exists()) {
          final fileBytes = await file.readAsBytes();
          final filename = 'media/original/${asset.fileName}';
          
          archive.addFile(ArchiveFile(filename, fileBytes.length, fileBytes));
        }
      }
      
      // Add thumbnail if available
      if (options.includeThumbnails && asset.thumbnailPath != null) {
        final thumbFile = File(asset.thumbnailPath!);
        if (await thumbFile.exists()) {
          final thumbBytes = await thumbFile.readAsBytes();
          final filename = 'media/thumbnails/${asset.fileName}';
          
          archive.addFile(ArchiveFile(filename, thumbBytes.length, thumbBytes));
        }
      }
      
      // Add metadata
      if (options.includeMediaMetadata) {
        final metadata = asset.toJson();
        final metadataBytes = utf8.encode(jsonEncode(metadata));
        final filename = 'media/metadata/${asset.id}.json';
        
        archive.addFile(ArchiveFile(filename, metadataBytes.length, metadataBytes));
      }
      
      // Update progress
      onProgress(i / media.length);
    }
  }

  // =========================================================================
  // JSON EXPORT
  // =========================================================================

  Future<String> _generateJSON(
    List<TimelineEvent> events,
    List<MediaAsset> media,
    JSONExportOptions options,
    ProgressCallback onProgress,
  ) async {
    final exportData = <String, dynamic>{
      'metadata': {
        'exportDate': DateTime.now().toIso8601String(),
        'version': '1.0.0',
        'format': 'timeline-biography-json',
      },
      'events': [],
      'media': [],
      'relationships': [],
    };
    
    // Process events
    for (int i = 0; i < events.length; i++) {
      final event = events[i];
      final eventData = event.toJson();
      
      // Add media references
      if (options.includeMediaReferences) {
        final eventMedia = media.where((m) => m.eventId == event.id).toList();
        eventData['mediaIds'] = eventMedia.map((m) => m.id).toList();
      }
      
      // Encrypt sensitive data if requested
      if (options.encryptSensitiveData) {
        eventData = await _encryptSensitiveFields(eventData);
      }
      
      exportData['events'].add(eventData);
      onProgress(i / (events.length + media.length));
    }
    
    // Process media
    for (int i = 0; i < media.length; i++) {
      final asset = media[i];
      var assetData = asset.toJson();
      
      // Include base64 if requested
      if (options.includeBase64Media && asset.fileSize < 10 * 1024 * 1024) {
        final file = File(asset.localPath);
        if (await file.exists()) {
          final bytes = await file.readAsBytes();
          assetData['base64'] = base64Encode(bytes);
        }
      }
      
      // Encrypt sensitive data if requested
      if (options.encryptSensitiveData) {
        assetData = await _encryptSensitiveFields(assetData);
      }
      
      exportData['media'].add(assetData);
      onProgress((events.length + i) / (events.length + media.length));
    }
    
    // Save JSON
    final dir = await getTemporaryDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final filename = options.customFilename ?? 
        'timeline_export_$timestamp.json';
    final filePath = path.join(dir.path, filename);
    
    final jsonString = const JsonEncoder.withIndent('  ').convert(exportData);
    final file = File(filePath);
    await file.writeAsString(jsonString);
    
    return filePath;
  }

  // =========================================================================
  // HELPER METHODS
  // =========================================================================

  Future<List<TimelineEvent>> _getTimelineEvents(List<String> ids) async {
    // Implementation would query database
    // For now, return empty list
    return [];
  }

  Future<List<MediaAsset>> _getMediaAssets(List<String> ids) async {
    // Implementation would query database
    // For now, return empty list
    return [];
  }

  void _updateProgress(
    String exportId, {
    ExportStatus? status,
    double? progress,
    String? outputPath,
    String? error,
  }) {
    final current = _activeExports[exportId];
    if (current != null) {
      if (status != null) current.status = status;
      if (progress != null) current.progress = progress;
      if (outputPath != null) current.outputPath = outputPath;
      if (error != null) current.error = error;
      if (status == ExportStatus.completed) {
        current.endTime = DateTime.now();
      }
      
      _progressController.add(current);
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day} ${_monthName(date.month)} ${date.year}';
  }

  String _monthName(int month) {
    const months = [
      '', 'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return months[month];
  }

  String _quillDeltaToPlainText(String deltaJson) {
    // Simple delta to plain text conversion
    // In real implementation, would use flutter_quill parser
    try {
      final delta = jsonDecode(deltaJson);
      final buffer = StringBuffer();
      
      if (delta['ops'] != null) {
        for (final op in delta['ops']) {
          if (op['insert'] is String) {
            buffer.write(op['insert']);
          }
        }
      }
      
      return buffer.toString();
    } catch (e) {
      return deltaJson;
    }
  }

  Future<Map<String, dynamic>> _encryptSensitiveFields(
    Map<String, dynamic> data,
  ) async {
    // Implementation would encrypt sensitive fields
    // For now, return data as-is
    return data;
  }
}

// =========================================================================
// DATA MODELS
// =========================================================================

class ExportProgress {
  final String id;
  final ExportType type;
  ExportStatus status;
  double progress;
  final DateTime startTime;
  DateTime? endTime;
  String? outputPath;
  String? error;

  ExportProgress({
    required this.id,
    required this.type,
    required this.status,
    required this.progress,
    required this.startTime,
    this.endTime,
    this.outputPath,
    this.error,
  });
}

enum ExportType {
  pdf,
  zip,
  json,
}

enum ExportStatus {
  preparing,
  processing,
  completed,
  failed,
  cancelled,
}

class PDFExportOptions {
  final String? title;
  final String? subtitle;
  final String? customFilename;
  final bool includeTitlePage;
  final bool includeTableOfContents;
  final bool pageBreakBetweenEvents;

  const PDFExportOptions({
    this.title,
    this.subtitle,
    this.customFilename,
    this.includeTitlePage = true,
    this.includeTableOfContents = true,
    this.pageBreakBetweenEvents = true,
  });
}

class ZIPExportOptions {
  final String? customFilename;
  final bool includeMetadata;
  final bool includeEvents;
  final bool includeMedia;
  final bool includeOriginalFiles;
  final bool includeThumbnails;
  final bool includeMediaMetadata;
  final bool includeIndividualFiles;

  const ZIPExportOptions({
    this.customFilename,
    this.includeMetadata = true,
    this.includeEvents = true,
    this.includeMedia = true,
    this.includeOriginalFiles = true,
    this.includeThumbnails = true,
    this.includeMediaMetadata = true,
    this.includeIndividualFiles = false,
  });
}

class JSONExportOptions {
  final String? customFilename;
  final bool includeMediaReferences;
  final bool includeBase64Media;
  final bool encryptSensitiveData;
  final bool prettyPrint;

  const JSONExportOptions({
    this.customFilename,
    this.includeMediaReferences = true,
    this.includeBase64Media = false,
    this.encryptSensitiveData = false,
    this.prettyPrint = true,
  });
}

typedef ProgressCallback = void Function(double progress);

// =========================================================================
// PROVIDERS
// =========================================================================

final dataExportProvider = Provider<DataExportService>((ref) {
  return DataExportService.instance;
});

final exportProgressProvider = StreamProvider<Map<String, ExportProgress>>((ref) {
  final service = ref.watch(dataExportProvider);
  return service.exportProgressStream.map((progress) => {progress.id: progress});
});

// =========================================================================
// EXCEPTIONS
// =========================================================================

class DataExportException implements Exception {
  final String message;
  DataExportException(this.message);
  
  @override
  String toString() => 'DataExportException: $message';
}
