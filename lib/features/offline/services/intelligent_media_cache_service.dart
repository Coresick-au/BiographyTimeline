import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import 'media_cache_service.dart';
import '../models/offline_models.dart';

/// Provider for intelligent media cache service
final intelligentMediaCacheServiceProvider = Provider((ref) => IntelligentMediaCacheService(
  mediaCacheService: ref.read(mediaCacheServiceProvider),
));

/// Configuration for intelligent media caching
class MediaCacheConfig {
  final int maxCacheSizeMB;
  final int maxFileSizeMB;
  final Duration cacheExpiration;
  final bool enableSelectiveSync;
  final List<String> priorityFileTypes;
  final List<String> lowPriorityFileTypes;
  final bool enableOnDemandLoading;
  final bool enableCompression;

  const MediaCacheConfig({
    this.maxCacheSizeMB = 1000,
    this.maxFileSizeMB = 50,
    this.cacheExpiration = const Duration(days: 30),
    this.enableSelectiveSync = true,
    this.priorityFileTypes = const ['jpg', 'jpeg', 'png', 'webp'],
    this.lowPriorityFileTypes = const ['gif', 'bmp', 'tiff'],
    this.enableOnDemandLoading = true,
    this.enableCompression = true,
  });
}

/// Cache priority levels
enum CachePriority {
  high,
  medium,
  low,
}

/// Media file metadata for intelligent caching
class MediaFileMetadata {
  final String url;
  final String fileType;
  final int fileSize;
  final CachePriority priority;
  final DateTime lastAccessed;
  final int accessCount;
  final bool isEssential;

  MediaFileMetadata({
    required this.url,
    required this.fileType,
    required this.fileSize,
    required this.priority,
    required this.lastAccessed,
    required this.accessCount,
    this.isEssential = false,
  });

  double get priorityScore {
    double score = 0.0;
    
    // Priority level score
    switch (priority) {
      case CachePriority.high:
        score += 100;
        break;
      case CachePriority.medium:
        score += 50;
        break;
      case CachePriority.low:
        score += 10;
        break;
    }
    
    // Access frequency score
    score += accessCount * 5;
    
    // Recency score
    final daysSinceAccess = DateTime.now().difference(lastAccessed).inDays;
    score += (30 - daysSinceAccess).clamp(0, 30);
    
    // Essential files get bonus
    if (isEssential) score += 200;
    
    return score;
  }
}

/// Intelligent media cache service with on-demand loading and selective sync
class IntelligentMediaCacheService {
  final MediaCacheService _mediaCacheService;
  final MediaCacheConfig _config;
  final Map<String, MediaFileMetadata> _metadataCache = {};
  Timer? _cleanupTimer;
  
  IntelligentMediaCacheService({
    required MediaCacheService mediaCacheService,
    MediaCacheConfig? config,
  }) : _mediaCacheService = mediaCacheService,
       _config = config ?? const MediaCacheConfig() {
    _startPeriodicCleanup();
  }

  /// Initialize the intelligent cache service
  Future<void> initialize() async {
    await _loadMetadataCache();
    await _performInitialCleanup();
  }

  /// Get a media file with intelligent caching
  Future<File?> getMediaFile(
    String url, {
    CachePriority? priority,
    bool forceDownload = false,
  }) async {
    // Check if already cached
    if (!forceDownload) {
      final cachedFile = await _mediaCacheService.getMediaFile(url);
      if (cachedFile != null) {
        await _updateAccessMetadata(url);
        return cachedFile;
      }
    }

    // Check if on-demand loading is enabled
    if (!_config.enableOnDemandLoading && !forceDownload) {
      return null;
    }

    // Check file size limits
    final fileSize = await _getFileSize(url);
    if (fileSize > _config.maxFileSizeMB * 1024 * 1024) {
      throw Exception('File size exceeds maximum limit');
    }

    // Check cache space
    await _ensureCacheSpace(fileSize);

    // Download and cache the file
    return await _downloadAndCache(url, priority ?? _determinePriority(url));
  }

  /// Preload essential media files
  Future<void> preloadEssentialFiles(List<String> urls) async {
    final essentialUrls = urls.where(_isEssentialFile).toList();
    
    for (final url in essentialUrls) {
      try {
        await getMediaFile(url, priority: CachePriority.high);
      } catch (e) {
        // Log error but continue with other files
        print('Failed to preload $url: $e');
      }
    }
  }

  /// Selectively sync files based on device constraints
  Future<void> performSelectiveSync({
    int? availableSpaceMB,
    bool? isWifiConnected,
  }) async {
    if (!_config.enableSelectiveSync) return;

    final availableSpace = availableSpaceMB ?? await _getAvailableSpace();
    final wifi = isWifiConnected ?? await _isWifiConnected();

    // Get all cached files with metadata
    final cachedFiles = await _getCachedFilesWithMetadata();
    
    // Sort by priority score
    cachedFiles.sort((a, b) => b.priorityScore.compareTo(a.priorityScore));

    // Keep files based on available space and connection
    int usedSpace = 0;
    final filesToKeep = <String>[];

    for (final file in cachedFiles) {
      // Always keep essential files
      if (file.isEssential) {
        filesToKeep.add(file.url);
        usedSpace += file.fileSize;
        continue;
      }

      // Check space constraints
      if (usedSpace + file.fileSize > availableSpace * 1024 * 1024) {
        continue;
      }

      // Check connection type for large files
      if (!wifi && file.fileSize > 10 * 1024 * 1024) {
        continue;
      }

      filesToKeep.add(file.url);
      usedSpace += file.fileSize;
    }

    // Remove files not in the keep list
    await _removeFilesExcept(urls: filesToKeep);
  }

  /// Optimize cache by compressing large files
  Future<void> optimizeCache() async {
    if (!_config.enableCompression) return;

    final cachedFiles = await _mediaCacheService.getAllCachedFiles();
    
    for (final file in cachedFiles) {
      if (file.fileSize > 5 * 1024 * 1024) { // Files larger than 5MB
        await _compressFile(file);
      }
    }
  }

  /// Get cache statistics
  Future<Map<String, dynamic>> getCacheStats() async {
    final stats = await _mediaCacheService.getCacheStatistics();
    final metadata = _getMetadataStats();
    
    return {
      ...stats,
      'intelligentCache': {
        'totalFiles': _metadataCache.length,
        'priorityDistribution': metadata['priorityDistribution'],
        'averageAccessCount': metadata['averageAccessCount'],
        'oldestAccess': metadata['oldestAccess'],
        'newestAccess': metadata['newestAccess'],
      },
    };
  }

  /// Clear cache with intelligent cleanup
  Future<void> clearCache({bool keepEssential = true}) async {
    if (keepEssential) {
      final essentialFiles = _metadataCache.entries
          .where((e) => e.value.isEssential)
          .map((e) => e.key)
          .toList();
      
      await _removeFilesExcept(urls: essentialFiles);
    } else {
      await _mediaCacheService.clearCache();
      _metadataCache.clear();
    }
  }

  /// Dispose the service
  void dispose() {
    _cleanupTimer?.cancel();
  }

  // Private methods

  void _startPeriodicCleanup() {
    _cleanupTimer = Timer.periodic(
      const Duration(hours: 6),
      (_) => _performPeriodicCleanup(),
    );
  }

  Future<void> _performPeriodicCleanup() async {
    await _removeExpiredFiles();
    await _enforceCacheSizeLimit();
  }

  Future<void> _performInitialCleanup() async {
    await _removeExpiredFiles();
    await _enforceCacheSizeLimit();
  }

  Future<void> _loadMetadataCache() async {
    // Load metadata from persistent storage
    // For now, initialize empty cache
    _metadataCache.clear();
  }

  Future<void> _saveMetadataCache() async {
    // Save metadata to persistent storage
    // Implementation depends on storage choice
  }

  CachePriority _determinePriority(String url) {
    final extension = path.extension(url).toLowerCase().substring(1);
    
    if (_config.priorityFileTypes.contains(extension)) {
      return CachePriority.high;
    } else if (_config.lowPriorityFileTypes.contains(extension)) {
      return CachePriority.low;
    }
    
    return CachePriority.medium;
  }

  bool _isEssentialFile(String url) {
    // Determine if file is essential based on URL pattern or metadata
    // For example: profile pictures, timeline cover images, etc.
    return url.contains('/profile/') || url.contains('/cover/');
  }

  Future<int> _getFileSize(String url) async {
    try {
      final response = await http.head(Uri.parse(url));
      return int.parse(response.headers['content-length'] ?? '0');
    } catch (e) {
      return 0;
    }
  }

  Future<void> _ensureCacheSpace(int requiredBytes) async {
    final stats = await _mediaCacheService.getCacheStatistics();
    final currentSize = int.parse(stats['totalSizeBytes'].toString());
    final maxSize = _config.maxCacheSizeMB * 1024 * 1024;
    
    if (currentSize + requiredBytes <= maxSize) {
      return;
    }
    
    // Need to free up space
    await _freeUpSpace(requiredBytes);
  }

  Future<void> _freeUpSpace(int requiredBytes) async {
    final cachedFiles = await _getCachedFilesWithMetadata();
    
    // Sort by priority score (lowest first)
    cachedFiles.sort((a, b) => a.priorityScore.compareTo(b.priorityScore));
    
    int freedSpace = 0;
    
    for (final file in cachedFiles) {
      if (file.isEssential) continue;
      
      await _mediaCacheService.removeCachedFile(file.url);
      _metadataCache.remove(file.url);
      freedSpace += file.fileSize;
      
      if (freedSpace >= requiredBytes) break;
    }
    
    await _saveMetadataCache();
  }

  Future<File> _downloadAndCache(String url, CachePriority priority) async {
    final response = await http.get(Uri.parse(url));
    if (response.statusCode != 200) {
      throw Exception('Failed to download file: ${response.statusCode}');
    }

    final bytes = response.bodyBytes;
    final fileType = path.extension(url).toLowerCase().substring(1);
    
    // Cache the file
    final cachedFile = await _mediaCacheService.cacheMediaFile(
      url,
      bytes,
      mimeType: _getMimeType(fileType),
    );

    // Update metadata
    _metadataCache[url] = MediaFileMetadata(
      url: url,
      fileType: fileType,
      fileSize: bytes.length,
      priority: priority,
      lastAccessed: DateTime.now(),
      accessCount: 1,
      isEssential: _isEssentialFile(url),
    );

    await _saveMetadataCache();
    
    return cachedFile;
  }

  Future<void> _updateAccessMetadata(String url) async {
    final metadata = _metadataCache[url];
    if (metadata != null) {
      _metadataCache[url] = MediaFileMetadata(
        url: url,
        fileType: metadata.fileType,
        fileSize: metadata.fileSize,
        priority: metadata.priority,
        lastAccessed: DateTime.now(),
        accessCount: metadata.accessCount + 1,
        isEssential: metadata.isEssential,
      );
      await _saveMetadataCache();
    }
  }

  Future<List<MediaFileMetadata>> _getCachedFilesWithMetadata() async {
    final cachedFiles = await _mediaCacheService.getAllCachedFiles();
    final metadata = <MediaFileMetadata>[];
    
    for (final file in cachedFiles) {
      final fileMetadata = _metadataCache[file.originalUrl];
      if (fileMetadata != null) {
        metadata.add(fileMetadata);
      }
    }
    
    return metadata;
  }

  Future<void> _removeExpiredFiles() async {
    final now = DateTime.now();
    final expiredUrls = <String>[];
    
    for (final entry in _metadataCache.entries) {
      if (now.difference(entry.value.lastAccessed) > _config.cacheExpiration) {
        expiredUrls.add(entry.key);
      }
    }
    
    for (final url in expiredUrls) {
      await _mediaCacheService.removeCachedFile(url);
      _metadataCache.remove(url);
    }
    
    if (expiredUrls.isNotEmpty) {
      await _saveMetadataCache();
    }
  }

  Future<void> _enforceCacheSizeLimit() async {
    final stats = await _mediaCacheService.getCacheStatistics();
    final currentSize = int.parse(stats['totalSizeBytes'].toString());
    final maxSize = _config.maxCacheSizeMB * 1024 * 1024;
    
    if (currentSize <= maxSize) return;
    
    await _freeUpSpace(currentSize - maxSize);
  }

  Future<void> _removeFilesExcept({required List<String> urls}) async {
    final cachedFiles = await _mediaCacheService.getAllCachedFiles();
    
    for (final file in cachedFiles) {
      if (!urls.contains(file.originalUrl)) {
        await _mediaCacheService.removeCachedFile(file.originalUrl);
        _metadataCache.remove(file.originalUrl);
      }
    }
    
    await _saveMetadataCache();
  }

  Future<void> _compressFile(MediaCacheEntry file) async {
    // Implement file compression
    // This could use image compression libraries for images
    // or video transcoding for video files
    // For now, just a placeholder
  }

  Future<int> _getAvailableSpace() async {
    final directory = await getApplicationDocumentsDirectory();
    final stat = await directory.stat();
    // This is a simplified calculation
    return 500; // Assume 500MB available
  }

  Future<bool> _isWifiConnected() async {
    // Check connectivity type
    // Implementation would use connectivity_plus package
    return true; // Assume WiFi for now
  }

  Map<String, dynamic> _getMetadataStats() {
    if (_metadataCache.isEmpty) {
      return {
        'priorityDistribution': {},
        'averageAccessCount': 0,
        'oldestAccess': null,
        'newestAccess': null,
      };
    }

    final priorityCount = <CachePriority, int>{};
    int totalAccess = 0;
    DateTime? oldest;
    DateTime? newest;

    for (final metadata in _metadataCache.values) {
      // Count by priority
      priorityCount[metadata.priority] = (priorityCount[metadata.priority] ?? 0) + 1;
      
      // Track access
      totalAccess += metadata.accessCount;
      
      // Track dates
      if (oldest == null || metadata.lastAccessed.isBefore(oldest)) {
        oldest = metadata.lastAccessed;
      }
      if (newest == null || metadata.lastAccessed.isAfter(newest)) {
        newest = metadata.lastAccessed;
      }
    }

    return {
      'priorityDistribution': priorityCount.map((k, v) => MapEntry(k.name, v)),
      'averageAccessCount': totalAccess / _metadataCache.length,
      'oldestAccess': oldest?.toIso8601String(),
      'newestAccess': newest?.toIso8601String(),
    };
  }

  String _getMimeType(String fileType) {
    switch (fileType) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'webp':
        return 'image/webp';
      case 'mp4':
        return 'video/mp4';
      case 'mov':
        return 'video/quicktime';
      case 'avi':
        return 'video/x-msvideo';
      default:
        return 'application/octet-stream';
    }
  }
}
