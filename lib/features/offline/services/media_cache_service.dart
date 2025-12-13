import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:uuid/uuid.dart';
import 'package:http/http.dart' as http;
import 'package:sqflite/sqflite.dart';
import 'offline_database_service.dart';
import '../models/offline_models.dart';

/// Provider for media cache service
final mediaCacheServiceProvider = Provider((ref) => MediaCacheService(
  databaseService: ref.read(offlineDatabaseServiceProvider),
));

/// Media cache service for offline media storage and management
class MediaCacheService {
  final OfflineDatabaseService _databaseService;
  final OfflineStorageConfig _config;
  
  Directory? _cacheDirectory;
  int _currentCacheSize = 0;

  MediaCacheService({
    required OfflineDatabaseService databaseService,
    OfflineStorageConfig? config,
  }) : _databaseService = databaseService,
       _config = config ?? const OfflineStorageConfig();

  /// Initialize the media cache service
  Future<void> initialize() async {
    _cacheDirectory = await getApplicationDocumentsDirectory();
    await _calculateCurrentCacheSize();
    await _cleanupExpiredEntries();
  }

  /// Cache media from URL for offline access
  Future<String> cacheMedia(
    String originalUrl, {
    bool isTemporary = false,
    Duration? expiration,
    Map<String, dynamic>? metadata,
  }) async {
    // Check if already cached
    final existingEntry = await _databaseService.getMediaCacheEntry(originalUrl);
    if (existingEntry != null && !existingEntry.isExpired) {
      return existingEntry.localPath;
    }

    try {
      // Download the media
      final response = await http.get(Uri.parse(originalUrl));
      if (response.statusCode != 200) {
        throw Exception('Failed to download media: ${response.statusCode}');
      }

      // Generate local file path
      final fileName = _generateFileName(originalUrl);
      final localPath = path.join(_cacheDirectory!.path, 'media', fileName);

      // Ensure directory exists
      await Directory(path.dirname(localPath)).create(recursive: true);

      // Save file to local storage
      final file = File(localPath);
      await file.writeAsBytes(response.bodyBytes);

      // Create cache entry
      final entry = MediaCacheEntry(
        id: const Uuid().v4(),
        originalUrl: originalUrl,
        localPath: localPath,
        mimeType: _getMimeTypeFromUrl(originalUrl),
        fileSize: response.bodyBytes.length,
        cachedAt: DateTime.now(),
        lastAccessed: DateTime.now(),
        accessCount: 1,
        isTemporary: isTemporary,
        expiresAt: expiration != null ? DateTime.now().add(expiration) : DateTime.now().add(_config.cacheExpiration),
        metadata: metadata,
      );

      // Save to database
      await _databaseService.saveMediaCacheEntry(entry);
      _currentCacheSize += entry.fileSize;

      // Check cache size limits
      await _enforceCacheSizeLimits();

      return localPath;

    } catch (e) {
      throw Exception('Failed to cache media: $e');
    }
  }

  /// Get cached media file path
  Future<String?> getCachedMedia(String originalUrl) async {
    final entry = await _databaseService.getMediaCacheEntry(originalUrl);
    
    if (entry == null) {
      return null;
    }

    // Check if file still exists
    final file = File(entry.localPath);
    if (!await file.exists()) {
      // File was deleted, remove from database
      await _removeCacheEntry(entry.id);
      return null;
    }

    // Check if expired
    if (entry.isExpired) {
      await _removeCacheEntry(entry.id);
      return null;
    }

    return entry.localPath;
  }

  /// Cache multiple media files in batch
  Future<Map<String, String>> cacheMediaBatch(
    List<String> urls, {
    bool isTemporary = false,
    Duration? expiration,
  }) async {
    final results = <String, String>{};
    
    for (final url in urls) {
      try {
        final localPath = await cacheMedia(
          url,
          isTemporary: isTemporary,
          expiration: expiration,
        );
        results[url] = localPath;
      } catch (e) {
        print('Failed to cache media $url: $e');
        results[url] = 'error: $e';
      }
    }
    
    return results;
  }

  /// Preload media for offline access
  Future<void> preloadMediaForContext(
    String contextId,
    List<String> mediaUrls,
  ) async {
    final metadata = {
      'context_id': contextId,
      'preloaded_at': DateTime.now().toIso8601String(),
    };

    await cacheMediaBatch(
      mediaUrls,
      isTemporary: false,
      expiration: Duration(days: 90), // Longer expiration for preloaded media
    );
  }

  /// Remove cached media
  Future<void> removeCachedMedia(String originalUrl) async {
    final entry = await _databaseService.getMediaCacheEntry(originalUrl);
    if (entry != null) {
      await _removeCacheEntry(entry.id);
    }
  }

  /// Clear all cached media
  Future<void> clearCache() async {
    final db = await _databaseService.database;
    
    // Get all cache entries
    final List<Map<String, dynamic>> maps = await db.query('media_cache');
    
    // Delete all files
    for (final map in maps) {
      final entry = _mapToMediaCacheEntry(map);
      await _deleteCacheFile(entry.localPath);
    }
    
    // Clear database table
    await db.delete('media_cache');
    _currentCacheSize = 0;
  }

  /// Clear temporary cache only
  Future<void> clearTemporaryCache() async {
    final db = await _databaseService.database;
    
    // Get temporary entries
    final List<Map<String, dynamic>> maps = await db.query(
      'media_cache',
      where: 'is_temporary = ?',
      whereArgs: [1],
    );
    
    // Delete temporary files
    for (final map in maps) {
      final entry = _mapToMediaCacheEntry(map);
      await _deleteCacheFile(entry.localPath);
    }
    
    // Remove from database
    await db.delete('media_cache', where: 'is_temporary = ?', whereArgs: [1]);
    await _calculateCurrentCacheSize();
  }

  /// Get cache statistics
  Future<Map<String, dynamic>> getCacheStats() async {
    final db = await _databaseService.database;
    
    final totalEntries = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM media_cache')
    ) ?? 0;
    
    final temporaryEntries = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM media_cache WHERE is_temporary = 1')
    ) ?? 0;
    
    final expiredEntries = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM media_cache WHERE expires_at < ?', 
        [DateTime.now().millisecondsSinceEpoch])
    ) ?? 0;

    return {
      'totalEntries': totalEntries,
      'temporaryEntries': temporaryEntries,
      'expiredEntries': expiredEntries,
      'currentSizeBytes': _currentCacheSize,
      'currentSizeMB': (_currentCacheSize / (1024 * 1024)).toStringAsFixed(2),
      'maxSizeMB': _config.maxCacheSizeMB,
      'usagePercentage': ((_currentCacheSize / (1024 * 1024)) / _config.maxCacheSizeMB * 100).toStringAsFixed(1),
    };
  }

  /// Get cached media entries for a context
  Future<List<MediaCacheEntry>> getMediaForContext(String contextId) async {
    final db = await _databaseService.database;
    
    final List<Map<String, dynamic>> maps = await db.query(
      'media_cache',
      where: 'metadata LIKE ?',
      whereArgs: ['%"context_id":"$contextId"%'],
      orderBy: 'cached_at DESC',
    );

    return maps.map((map) => _mapToMediaCacheEntry(map)).toList();
  }

  /// Optimize cache by removing least recently used items
  Future<void> optimizeCache({double targetUsagePercentage = 0.8}) async {
    final targetSizeBytes = (_config.maxCacheSizeMB * 1024 * 1024 * targetUsagePercentage).round();
    
    if (_currentCacheSize <= targetSizeBytes) {
      return; // Cache is already within target
    }

    final db = await _databaseService.database;
    
    // Get entries ordered by last accessed (LRU)
    final List<Map<String, dynamic>> maps = await db.query(
      'media_cache',
      where: 'is_temporary = 0',
      orderBy: 'last_accessed ASC',
    );

    int removedSize = 0;
    for (final map in maps) {
      if (_currentCacheSize - removedSize <= targetSizeBytes) {
        break;
      }
      
      final entry = _mapToMediaCacheEntry(map);
      await _removeCacheEntry(entry.id);
      removedSize += entry.fileSize;
    }
  }

  /// Check if media is cached and valid
  Future<bool> isMediaCached(String originalUrl) async {
    final localPath = await getCachedMedia(originalUrl);
    return localPath != null;
  }

  /// Get local file for media (cache if needed)
  Future<File> getMediaFile(String originalUrl) async {
    // Try to get cached version
    final cachedPath = await getCachedMedia(originalUrl);
    
    if (cachedPath != null) {
      return File(cachedPath);
    }

    // Cache and return
    final newPath = await cacheMedia(originalUrl);
    return File(newPath);
  }

  // Private helper methods

  String _generateFileName(String url) {
    final extension = path.extension(url);
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final uuid = const Uuid().v4().substring(0, 8);
    return '${timestamp}_$uuid$extension';
  }

  String _getMimeTypeFromUrl(String url) {
    final extension = path.extension(url).toLowerCase();
    switch (extension) {
      case '.jpg':
      case '.jpeg':
        return 'image/jpeg';
      case '.png':
        return 'image/png';
      case '.gif':
        return 'image/gif';
      case '.webp':
        return 'image/webp';
      case '.mp4':
        return 'video/mp4';
      case '.mov':
        return 'video/quicktime';
      case '.avi':
        return 'video/x-msvideo';
      case '.mp3':
        return 'audio/mpeg';
      case '.wav':
        return 'audio/wav';
      case '.pdf':
        return 'application/pdf';
      default:
        return 'application/octet-stream';
    }
  }

  Future<void> _calculateCurrentCacheSize() async {
    final db = await _databaseService.database;
    
    final result = await db.rawQuery('SELECT SUM(file_size) as total_size FROM media_cache');
    _currentCacheSize = Sqflite.firstIntValue(result) ?? 0;
  }

  Future<void> _enforceCacheSizeLimits() async {
    final maxSizeBytes = _config.maxCacheSizeMB * 1024 * 1024;
    
    while (_currentCacheSize > maxSizeBytes) {
      await _removeOldestEntry();
    }
  }

  Future<void> _removeOldestEntry() async {
    final db = await _databaseService.database;
    
    // Get oldest entry (by last accessed)
    final List<Map<String, dynamic>> maps = await db.query(
      'media_cache',
      orderBy: 'last_accessed ASC',
      limit: 1,
    );

    if (maps.isNotEmpty) {
      final entry = _mapToMediaCacheEntry(maps.first);
      await _removeCacheEntry(entry.id);
    }
  }

  Future<void> _removeCacheEntry(String entryId) async {
    final db = await _databaseService.database;
    
    // Get entry details
    final List<Map<String, dynamic>> maps = await db.query(
      'media_cache',
      where: 'id = ?',
      whereArgs: [entryId],
    );

    if (maps.isNotEmpty) {
      final entry = _mapToMediaCacheEntry(maps.first);
      
      // Delete file
      await _deleteCacheFile(entry.localPath);
      
      // Remove from database
      await db.delete('media_cache', where: 'id = ?', whereArgs: [entryId]);
      
      // Update size
      _currentCacheSize -= entry.fileSize;
    }
  }

  Future<void> _deleteCacheFile(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      print('Failed to delete cache file $filePath: $e');
    }
  }

  Future<void> _cleanupExpiredEntries() async {
    await _databaseService.cleanupExpiredCache();
    await _calculateCurrentCacheSize();
  }

  MediaCacheEntry _mapToMediaCacheEntry(Map<String, dynamic> map) {
    return MediaCacheEntry(
      id: map['id'],
      originalUrl: map['original_url'],
      localPath: map['local_path'],
      mimeType: map['mime_type'],
      fileSize: map['file_size'],
      cachedAt: DateTime.fromMillisecondsSinceEpoch(map['cached_at']),
      lastAccessed: DateTime.fromMillisecondsSinceEpoch(map['last_accessed']),
      accessCount: map['access_count'] ?? 0,
      isTemporary: (map['is_temporary'] ?? 0) == 1,
      expiresAt: map['expires_at'] != null ? 
        DateTime.fromMillisecondsSinceEpoch(map['expires_at']) : null,
      metadata: map['metadata'] != null ? json.decode(map['metadata']) : null,
    );
  }

  /// Dispose the media cache service
  void dispose() {
    // Clean up any resources
  }
}
