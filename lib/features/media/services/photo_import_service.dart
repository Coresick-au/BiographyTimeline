import 'package:photo_manager/photo_manager.dart';
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

      // Get file path for local storage
      final file = await asset.file;
      final String? localPath = file?.path;

      // Create MediaAsset
      return MediaAsset(
        id: asset.id,
        eventId: '', // Will be set during event clustering
        type: AssetType.photo,
        localPath: localPath ?? '',
        cloudUrl: null, // Will be set during cloud sync
        exifData: enhancedExifData,
        caption: asset.title, // Use asset title as initial caption
        createdAt: asset.createDateTime,
        isKeyAsset: false, // Will be determined during clustering
      );
    } catch (e) {
      // Handle errors gracefully - return null for failed processing
      return null;
    }
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