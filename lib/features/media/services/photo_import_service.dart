import 'dart:io';
import 'package:photo_manager/photo_manager.dart';
import 'package:path/path.dart' as path;
import 'package:image/image.dart' as img;
import '../../../shared/models/exif_data.dart';
import '../../../shared/models/media_asset.dart';
import '../../../shared/models/geo_location.dart';
import 'exif_processor.dart';
import 'geocoding_service.dart';

/// Service responsible for importing photos and processing their metadata
class PhotoImportService {
  final ExifProcessor _exifProcessor;
  final GeocodingService _geocodingService;

  PhotoImportService({
    ExifProcessor? exifProcessor,
    GeocodingService? geocodingService,
  }) : _exifProcessor = exifProcessor ?? ExifProcessor(),
       _geocodingService = geocodingService ?? GeocodingService();

  /// Requests permission to access photo library
  Future<bool> requestPhotoLibraryPermission() async {
    final PermissionState permission = await PhotoManager.requestPermissionExtend();
    return permission == PermissionState.authorized || permission == PermissionState.limited;
  }

  /// Gets all photo assets from the device
  Future<List<AssetEntity>> getAllPhotos() async {
    final bool hasPermission = await requestPhotoLibraryPermission();
    if (!hasPermission) {
      throw Exception('Photo library access denied');
    }

    // Get all albums
    final List<AssetPathEntity> albums = await PhotoManager.getAssetPathList(
      type: RequestType.image,
      onlyAll: true, // Only get the "All Photos" album for now
    );

    if (albums.isEmpty) {
      return [];
    }

    // Get all photos from the main album
    final AssetPathEntity mainAlbum = albums.first;
    final List<AssetEntity> assets = await mainAlbum.getAssetListRange(
      start: 0,
      end: await mainAlbum.assetCountAsync,
    );

    return assets;
  }

  /// Processes a single photo asset and extracts its metadata
  Future<MediaAsset?> processPhotoAsset(AssetEntity asset) async {
    try {
      // Extract EXIF data
      final ExifData? exifData = await _exifProcessor.extractExifData(asset);
      
      // Enhance location data with reverse geocoding if GPS coordinates exist
      ExifData? enhancedExifData = exifData;
      if (exifData?.gpsLocation != null) {
        final GeoLocation? enhancedLocation = await _geocodingService.reverseGeocode(exifData!.gpsLocation!);
        if (enhancedLocation != null) {
          enhancedExifData = exifData.copyWith(gpsLocation: enhancedLocation);
        }
      }

      // Get file path and metadata
      final file = await asset.file;
      final String? localPath = file?.path;
      
      if (localPath == null) {
        throw Exception('Unable to get file path for asset ${asset.id}');
      }

      // Extract image dimensions and file size
      final imageMetadata = await _extractImageMetadata(file!);
      
      // Determine MIME type from file extension
      final mimeType = _getMimeType(localPath);

      // Create MediaAsset with complete metadata
      return MediaAsset(
        id: asset.id,
        eventId: '', // Will be set during event clustering
        type: AssetType.photo,
        localPath: localPath,
        cloudUrl: null, // Will be set during cloud sync
        exifData: enhancedExifData,
        caption: asset.title, // Use asset title as initial caption
        createdAt: asset.createDateTime,
        isKeyAsset: false, // Will be determined during clustering
        width: imageMetadata['width'],
        height: imageMetadata['height'],
        fileSizeBytes: imageMetadata['fileSize'],
        mimeType: mimeType,
      );
    } catch (e) {
      // Handle errors gracefully - return null for failed processing
      print('Error processing photo asset ${asset.id}: $e');
      return null;
    }
  }

  /// Extracts image metadata (dimensions, file size)
  Future<Map<String, int>> _extractImageMetadata(File file) async {
    final metadata = <String, int>{};
    
    try {
      // Get file size
      final fileSize = await file.length();
      metadata['fileSize'] = fileSize;
      
      // Read image to get dimensions
      final bytes = await file.readAsBytes();
      final image = img.decodeImage(bytes);
      
      if (image != null) {
        metadata['width'] = image.width;
        metadata['height'] = image.height;
      }
    } catch (e) {
      print('Error extracting image metadata: $e');
      // Return empty metadata on error
    }
    
    return metadata;
  }

  /// Determines MIME type from file extension
  String _getMimeType(String filePath) {
    final extension = path.extension(filePath).toLowerCase();
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
      case '.heic':
        return 'image/heic';
      case '.heif':
        return 'image/heif';
      default:
        return 'image/jpeg'; // Default to JPEG
    }
  }

  /// Creates a copy of the photo in the app's directory
  Future<String?> copyPhotoToAppDirectory(String sourcePath, String assetId) async {
    try {
      final sourceFile = File(sourcePath);
      if (!await sourceFile.exists()) {
        return null;
      }

      // Create app's media directory if it doesn't exist
      final appDir = Directory.systemTemp.parent.parent.parent.parent;
      final mediaDir = Directory(path.join(appDir.path, 'media', 'photos'));
      if (!await mediaDir.exists()) {
        await mediaDir.create(recursive: true);
      }

      // Copy file with unique name
      final extension = path.extension(sourcePath);
      final newPath = path.join(mediaDir.path, '${assetId}$extension');
      await sourceFile.copy(newPath);
      
      return newPath;
    } catch (e) {
      print('Error copying photo to app directory: $e');
      return null;
    }
  }

  /// Validates if a photo file is accessible and not corrupted
  Future<bool> validatePhotoFile(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        return false;
      }

      // Try to read the file header to check for corruption
      final bytes = await file.openRead(0, 1024).first;
      if (bytes.isEmpty) {
        return false;
      }

      // Check for common image file signatures
      final signature = bytes.take(4).toList();
      return _isValidImageSignature(signature);
    } catch (e) {
      return false;
    }
  }

  /// Checks if the file signature matches common image formats
  bool _isValidImageSignature(List<int> signature) {
    // JPEG: FF D8 FF
    if (signature.length >= 3 &&
        signature[0] == 0xFF &&
        signature[1] == 0xD8 &&
        signature[2] == 0xFF) {
      return true;
    }

    // PNG: 89 50 4E 47
    if (signature.length >= 4 &&
        signature[0] == 0x89 &&
        signature[1] == 0x50 &&
        signature[2] == 0x4E &&
        signature[3] == 0x47) {
      return true;
    }

    // GIF: 47 49 46 38
    if (signature.length >= 4 &&
        signature[0] == 0x47 &&
        signature[1] == 0x49 &&
        signature[2] == 0x46 &&
        signature[3] == 0x38) {
      return true;
    }

    // WebP: 52 49 46 46 ... 57 45 42 50
    if (signature.length >= 12 &&
        signature[0] == 0x52 &&
        signature[1] == 0x49 &&
        signature[2] == 0x46 &&
        signature[3] == 0x46 &&
        signature[8] == 0x57 &&
        signature[9] == 0x45 &&
        signature[10] == 0x42 &&
        signature[11] == 0x50) {
      return true;
    }

    return false;
  }

  /// Processes multiple photo assets in batches
  Future<List<MediaAsset>> processPhotoAssets(
    List<AssetEntity> assets, {
    int batchSize = 10,
    Function(int processed, int total)? onProgress,
  }) async {
    final List<MediaAsset> processedAssets = [];
    
    for (int i = 0; i < assets.length; i += batchSize) {
      final int end = (i + batchSize < assets.length) ? i + batchSize : assets.length;
      final List<AssetEntity> batch = assets.sublist(i, end);
      
      // Process batch concurrently
      final List<Future<MediaAsset?>> futures = batch.map(processPhotoAsset).toList();
      final List<MediaAsset?> batchResults = await Future.wait(futures);
      
      // Add non-null results
      for (final result in batchResults) {
        if (result != null) {
          processedAssets.add(result);
        }
      }
      
      // Report progress
      onProgress?.call(i + batch.length, assets.length);
    }
    
    return processedAssets;
  }

  /// Imports all photos from the device with progress tracking
  Future<List<MediaAsset>> importAllPhotos({
    Function(int processed, int total)? onProgress,
  }) async {
    // Get all photo assets
    final List<AssetEntity> assets = await getAllPhotos();
    
    if (assets.isEmpty) {
      return [];
    }
    
    // Process all assets
    return await processPhotoAssets(
      assets,
      onProgress: onProgress,
    );
  }

  /// Filters assets that have complete EXIF data
  List<MediaAsset> getAssetsWithCompleteExif(List<MediaAsset> assets) {
    return assets.where((asset) => 
      asset.exifData != null && asset.exifData!.isComplete
    ).toList();
  }

  /// Filters assets that need fuzzy date fallback
  List<MediaAsset> getAssetsNeedingFuzzyDate(List<MediaAsset> assets) {
    return assets.where((asset) => 
      asset.exifData == null || !asset.exifData!.hasCompleteTimestampData
    ).toList();
  }

  /// Gets assets with GPS coordinates
  List<MediaAsset> getAssetsWithGpsData(List<MediaAsset> assets) {
    return assets.where((asset) => 
      asset.exifData?.gpsLocation != null
    ).toList();
  }
}
