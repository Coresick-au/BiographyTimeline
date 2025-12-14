import 'package:flutter/material.dart';
import '../../../shared/models/media_asset.dart';

/// Widget for displaying media assets in an event
class EventMediaGallery extends StatelessWidget {
  final List<MediaAsset> assets;

  const EventMediaGallery({
    super.key,
    required this.assets,
  });

  @override
  Widget build(BuildContext context) {
    if (assets.isEmpty) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      height: 200,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: assets.length,
        itemBuilder: (context, index) {
          final asset = assets[index];
          return Container(
            width: 150,
            margin: const EdgeInsets.only(right: 8),
            child: Card(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: _buildAssetWidget(asset),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildAssetWidget(MediaAsset asset) {
    switch (asset.type) {
      case 'photo':
        return Image.network(
          asset.cloudUrl ?? asset.localPath,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              color: Colors.grey[300],
              child: const Icon(Icons.broken_image),
            );
          },
        );
      case 'video':
        return Container(
          color: Colors.black,
          child: const Icon(
            Icons.play_circle_filled,
            color: Colors.white,
            size: 48,
          ),
        );
      case 'audio':
        return Container(
          color: Colors.grey[200],
          child: const Icon(
            Icons.audiotrack,
            size: 48,
          ),
        );
      default:
        return Container(
          color: Colors.grey[300],
          child: const Icon(Icons.insert_drive_file),
        );
    }
  }
}
