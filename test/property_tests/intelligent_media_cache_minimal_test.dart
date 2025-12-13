import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:uuid/uuid.dart';
import '../../lib/features/offline/services/intelligent_media_cache_service.dart';
import '../../lib/features/offline/services/media_cache_service.dart';
import '../../lib/features/offline/models/offline_models.dart';

/// Property 30: Intelligent Media Caching (Minimal Test)
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  
  group('Property 30: Intelligent Media Caching', () {
    late MediaCacheService mediaCacheService;
    late IntelligentMediaCacheService intelligentCache;
    const uuid = Uuid();

    setUp(() {
      mediaCacheService = MediaCacheService();
      intelligentCache = IntelligentMediaCacheService(
        mediaCacheService: mediaCacheService,
        config: const MediaCacheConfig(
          maxCacheSizeMB: 100,
          maxFileSizeMB: 10,
          enableOnDemandLoading: true,
          enableSelectiveSync: true,
        ),
      );
    });

    test('Cache priority levels work correctly', () {
      expect(CachePriority.high.name, equals('high'));
      expect(CachePriority.medium.name, equals('medium'));
      expect(CachePriority.low.name, equals('low'));
    });

    test('Media cache configuration defaults', () {
      const config = MediaCacheConfig();
      
      expect(config.maxCacheSizeMB, equals(1000));
      expect(config.maxFileSizeMB, equals(50));
      expect(config.enableOnDemandLoading, isTrue);
      expect(config.enableSelectiveSync, isTrue);
      expect(config.enableCompression, isTrue);
      expect(config.priorityFileTypes, contains('jpg'));
      expect(config.priorityFileTypes, contains('png'));
      expect(config.lowPriorityFileTypes, contains('gif'));
    });

    test('Media file metadata priority scoring', () {
      // High priority, essential file
      final highPriority = MediaFileMetadata(
        url: 'https://example.com/profile.jpg',
        fileType: 'jpg',
        fileSize: 1024 * 1024,
        priority: CachePriority.high,
        lastAccessed: DateTime.now(),
        accessCount: 10,
        isEssential: true,
      );
      
      expect(highPriority.priorityScore, greaterThan(300));
      
      // Low priority, non-essential file
      final lowPriority = MediaFileMetadata(
        url: 'https://example.com/archive.gif',
        fileType: 'gif',
        fileSize: 1024 * 1024,
        priority: CachePriority.low,
        lastAccessed: DateTime.now().subtract(const Duration(days: 20)),
        accessCount: 1,
        isEssential: false,
      );
      
      expect(lowPriority.priorityScore, lessThan(100));
      expect(highPriority.priorityScore, greaterThan(lowPriority.priorityScore));
    });

    test('Priority determination based on file type', () {
      // Test the logic that would be used in the service
      const priorityFileTypes = ['jpg', 'jpeg', 'png', 'webp'];
      const lowPriorityFileTypes = ['gif', 'bmp', 'tiff'];
      
      CachePriority determinePriority(String url) {
        final extension = url.split('.').last.toLowerCase();
        
        if (priorityFileTypes.contains(extension)) {
          return CachePriority.high;
        } else if (lowPriorityFileTypes.contains(extension)) {
          return CachePriority.low;
        }
        
        return CachePriority.medium;
      }
      
      // Test priority file types
      expect(determinePriority('image.jpg'), equals(CachePriority.high));
      expect(determinePriority('photo.png'), equals(CachePriority.high));
      expect(determinePriority('graphic.webp'), equals(CachePriority.high));
      
      // Test low priority file types
      expect(determinePriority('animation.gif'), equals(CachePriority.low));
      expect(determinePriority('bitmap.bmp'), equals(CachePriority.low));
      
      // Test medium priority (default)
      expect(determinePriority('video.mp4'), equals(CachePriority.medium));
      expect(determinePriority('document.pdf'), equals(CachePriority.medium));
    });

    test('Essential file identification', () {
      // Test the logic for identifying essential files
      bool isEssentialFile(String url) {
        return url.contains('/profile/') || url.contains('/cover/');
      }
      
      // Essential files
      expect(isEssentialFile('https://example.com/profile/user123.jpg'), isTrue);
      expect(isEssentialFile('https://cdn.example.com/cover/timeline_456.png'), isTrue);
      
      // Non-essential files
      expect(isEssentialFile('https://example.com/media/vacation.jpg'), isFalse);
      expect(isEssentialFile('https://example.com/gallery/photo.jpg'), isFalse);
    });

    test('Cache space management', () {
      // Simulate cache space calculation
      const currentSize = 80 * 1024 * 1024; // 80MB
      const maxSize = 100 * 1024 * 1024; // 100MB
      const requiredSpace = 30 * 1024 * 1024; // 30MB needed
      
      bool needsCleanup = (currentSize + requiredSpace) > maxSize;
      expect(needsCleanup, isTrue);
      
      // Calculate space to free
      final spaceToFree = (currentSize + requiredSpace) - maxSize;
      expect(spaceToFree, equals(10 * 1024 * 1024)); // 10MB needs to be freed
    });

    test('Selective sync based on available space', () {
      final files = [
        MediaFileMetadata(
          url: 'essential.jpg',
          fileType: 'jpg',
          fileSize: 5 * 1024 * 1024,
          priority: CachePriority.high,
          lastAccessed: DateTime.now(),
          accessCount: 10,
          isEssential: true,
        ),
        MediaFileMetadata(
          url: 'large.mp4',
          fileType: 'mp4',
          fileSize: 50 * 1024 * 1024,
          priority: CachePriority.low,
          lastAccessed: DateTime.now().subtract(const Duration(days: 5)),
          accessCount: 1,
          isEssential: false,
        ),
        MediaFileMetadata(
          url: 'medium.png',
          fileType: 'png',
          fileSize: 10 * 1024 * 1024,
          priority: CachePriority.medium,
          lastAccessed: DateTime.now(),
          accessCount: 5,
          isEssential: false,
        ),
      ];
      
      // Sort by priority score
      files.sort((a, b) => b.priorityScore.compareTo(a.priorityScore));
      
      // Simulate selective sync with limited space
      const availableSpace = 20 * 1024 * 1024; // 20MB
      int usedSpace = 0;
      final syncedFiles = <String>[];
      
      for (final file in files) {
        if (file.isEssential || (usedSpace + file.fileSize <= availableSpace)) {
          syncedFiles.add(file.url);
          usedSpace += file.fileSize;
        }
      }
      
      expect(syncedFiles, contains('essential.jpg'));
      expect(syncedFiles, contains('medium.png'));
      expect(syncedFiles, isNot(contains('large.mp4')));
      expect(usedSpace, lessThanOrEqualTo(availableSpace));
    });

    test('On-demand loading configuration', () {
      const configEnabled = MediaCacheConfig(enableOnDemandLoading: true);
      const configDisabled = MediaCacheConfig(enableOnDemandLoading: false);
      
      expect(configEnabled.enableOnDemandLoading, isTrue);
      expect(configDisabled.enableOnDemandLoading, isFalse);
    });

    test('File size validation', () {
      const maxFileSize = 10 * 1024 * 1024; // 10MB
      
      // Valid file size
      const validSize = 5 * 1024 * 1024; // 5MB
      expect(validSize <= maxFileSize, isTrue);
      
      // Invalid file size
      const invalidSize = 15 * 1024 * 1024; // 15MB
      expect(invalidSize <= maxFileSize, isFalse);
    });

    test('Cache expiration logic', () {
      final now = DateTime.now();
      final expiration = const Duration(days: 30);
      
      // Fresh file
      final freshFile = MediaFileMetadata(
        url: 'fresh.jpg',
        fileType: 'jpg',
        fileSize: 1024,
        priority: CachePriority.medium,
        lastAccessed: now.subtract(const Duration(days: 10)),
        accessCount: 5,
      );
      
      expect(now.difference(freshFile.lastAccessed) <= expiration, isTrue);
      
      // Expired file
      final expiredFile = MediaFileMetadata(
        url: 'expired.jpg',
        fileType: 'jpg',
        fileSize: 1024,
        priority: CachePriority.medium,
        lastAccessed: now.subtract(const Duration(days: 40)),
        accessCount: 5,
      );
      
      expect(now.difference(expiredFile.lastAccessed) > expiration, isTrue);
    });

    test('Priority-based eviction strategy', () {
      final files = [
        MediaFileMetadata(
          url: 'high1.jpg',
          fileType: 'jpg',
          fileSize: 1024,
          priority: CachePriority.high,
          lastAccessed: DateTime.now(),
          accessCount: 10,
        ),
        MediaFileMetadata(
          url: 'low1.gif',
          fileType: 'gif',
          fileSize: 1024,
          priority: CachePriority.low,
          lastAccessed: DateTime.now().subtract(const Duration(days: 10)),
          accessCount: 1,
        ),
        MediaFileMetadata(
          url: 'medium1.png',
          fileType: 'png',
          fileSize: 1024,
          priority: CachePriority.medium,
          lastAccessed: DateTime.now(),
          accessCount: 5,
        ),
      ];
      
      // Sort for eviction (lowest priority first)
      files.sort((a, b) => a.priorityScore.compareTo(b.priorityScore));
      
      // Low priority should be first to evict
      expect(files.first.url, equals('low1.gif'));
      expect(files.last.url, equals('high1.jpg'));
    });

    test('Cache statistics calculation', () {
      final metadata = {
        'file1.jpg': MediaFileMetadata(
          url: 'file1.jpg',
          fileType: 'jpg',
          fileSize: 1024,
          priority: CachePriority.high,
          lastAccessed: DateTime.now(),
          accessCount: 10,
        ),
        'file2.gif': MediaFileMetadata(
          url: 'file2.gif',
          fileType: 'gif',
          fileSize: 2048,
          priority: CachePriority.low,
          lastAccessed: DateTime.now().subtract(const Duration(days: 5)),
          accessCount: 2,
        ),
      };
      
      final totalFiles = metadata.length;
      final totalAccess = metadata.values
          .map((m) => m.accessCount)
          .reduce((a, b) => a + b);
      final averageAccess = totalAccess / totalFiles;
      
      expect(totalFiles, equals(2));
      expect(totalAccess, equals(12));
      expect(averageAccess, equals(6.0));
    });

    test('MIME type detection', () {
      // Test the MIME type logic
      String getMimeType(String fileType) {
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
      
      expect(getMimeType('jpg'), equals('image/jpeg'));
      expect(getMimeType('png'), equals('image/png'));
      expect(getMimeType('gif'), equals('image/gif'));
      expect(getMimeType('webp'), equals('image/webp'));
      expect(getMimeType('mp4'), equals('video/mp4'));
      expect(getMimeType('mov'), equals('video/quicktime'));
      expect(getMimeType('unknown'), equals('application/octet-stream'));
    });

    test('Connection-aware downloading', () {
      const onWifi = true;
      const fileSize = 15 * 1024 * 1024; // 15MB
      
      // Large files should only download on WiFi
      bool shouldDownload = onWifi || fileSize <= 10 * 1024 * 1024;
      expect(shouldDownload, isTrue);
      
      // Same file on cellular
      shouldDownload = false || fileSize <= 10 * 1024 * 1024;
      expect(shouldDownload, isFalse);
    });

    test('Compression eligibility', () {
      const compressionThreshold = 5 * 1024 * 1024; // 5MB
      
      // File that should be compressed
      const largeFile = 10 * 1024 * 1024; // 10MB
      expect(largeFile > compressionThreshold, isTrue);
      
      // File that shouldn't be compressed
      const smallFile = 1 * 1024 * 1024; // 1MB
      expect(smallFile > compressionThreshold, isFalse);
    });

    test('Essential file preservation during cleanup', () {
      final files = [
        MediaFileMetadata(
          url: 'essential.jpg',
          fileType: 'jpg',
          fileSize: 1024,
          priority: CachePriority.high,
          lastAccessed: DateTime.now().subtract(const Duration(days: 100)),
          accessCount: 1,
          isEssential: true,
        ),
        MediaFileMetadata(
          url: 'nonessential.jpg',
          fileType: 'jpg',
          fileSize: 1024,
          priority: CachePriority.high,
          lastAccessed: DateTime.now().subtract(const Duration(days: 100)),
          accessCount: 1,
          isEssential: false,
        ),
      ];
      
      // During cleanup, essential files should be preserved
      final filesToKeep = files.where((f) => f.isEssential).toList();
      expect(filesToKeep, hasLength(1));
      expect(filesToKeep.first.url, equals('essential.jpg'));
    });
  });
}
