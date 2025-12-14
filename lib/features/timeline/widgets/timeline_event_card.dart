import 'package:flutter/material.dart';
import '../../../shared/models/timeline_event.dart';
import '../../../shared/models/media_asset.dart';
import '../../../shared/widgets/modern/glassmorphism_card.dart';
import '../../../shared/widgets/modern/shimmer_loading.dart';

/// Widget that displays a timeline event with photo count indicators
class TimelineEventCard extends StatelessWidget {
  final TimelineEvent event;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool showPhotoCount;
  final bool isExpanded;
  final VoidCallback? onExpandToggle;

  const TimelineEventCard({
    Key? key,
    required this.event,
    this.onTap,
    this.onLongPress,
    this.showPhotoCount = true,
    this.isExpanded = false,
    this.onExpandToggle,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return GlassmorphismCard(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      borderRadius: 20,
      blur: 15,
      opacity: isDark ? 0.05 : 0.1,
      backgroundColor: isDark ? Colors.white : Colors.black,
      padding: const EdgeInsets.all(20),
      onTap: onTap,
      boxShadow: [
        BoxShadow(
          color: isDark 
              ? Colors.black.withOpacity(0.3)
              : Colors.black.withOpacity(0.1),
          blurRadius: 20,
          spreadRadius: 0,
          offset: const Offset(0, 10),
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context),
          const SizedBox(height: 12),
          _buildMediaPreview(context),
          if (event.description != null) ...[
            const SizedBox(height: 8),
            _buildDescription(context),
          ],
          if (showPhotoCount && event.assets.length > 1) ...[
            const SizedBox(height: 8),
            _buildPhotoCountIndicator(context),
          ],
          if (isExpanded) ...[
            const SizedBox(height: 12),
            _buildExpandedContent(context),
          ],
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        _buildEventTypeIcon(context),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (event.title != null)
                Text(
                  event.title!,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              Text(
                _formatTimestamp(event.timestamp),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              if (event.location != null)
                Text(
                  event.location.toString(),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
            ],
          ),
        ),
        if (event.assets.length > 1 && onExpandToggle != null)
          IconButton(
            icon: Icon(isExpanded ? Icons.expand_less : Icons.expand_more),
            onPressed: onExpandToggle,
          ),
      ],
    );
  }

  Widget _buildEventTypeIcon(BuildContext context) {
    IconData iconData;
    Color? iconColor;
    
    switch (event.eventType) {
      case 'photo_burst':
        iconData = Icons.burst_mode;
        iconColor = Theme.of(context).colorScheme.primary;
        break;
      case 'photo_collection':
        iconData = Icons.collections;
        iconColor = Theme.of(context).colorScheme.secondary;
        break;
      case 'renovation_progress':
        iconData = Icons.construction;
        iconColor = Colors.orange;
        break;
      case 'pet_milestone':
        iconData = Icons.pets;
        iconColor = Colors.green;
        break;
      case 'business_milestone':
        iconData = Icons.business;
        iconColor = Colors.blue;
        break;
      case 'text':
        iconData = Icons.edit_note;
        iconColor = Theme.of(context).colorScheme.tertiary;
        break;
      default:
        iconData = Icons.photo;
        iconColor = Theme.of(context).colorScheme.onSurfaceVariant;
    }
    
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: iconColor?.withOpacity(event.eventType == 'text' ? 0.2 : 0.1),
        borderRadius: BorderRadius.circular(8),
        border: event.eventType == 'text' 
            ? Border.all(color: iconColor?.withOpacity(0.3) ?? Colors.transparent)
            : null,
      ),
      child: Icon(
        iconData,
        size: 20,
        color: iconColor,
      ),
    );
  }

  Widget _buildMediaPreview(BuildContext context) {
    if (event.assets.isEmpty) {
      // Enhanced text-only event visualization
      return _buildTextOnlyPreview(context);
    }

    final keyAsset = event.assets.firstWhere(
      (asset) => asset.isKeyAsset,
      orElse: () => event.assets.first,
    );

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: Stack(
          fit: StackFit.expand,
          children: [
            _buildAssetPreview(keyAsset),
            if (event.assets.length > 1)
              Positioned(
                top: 8,
                right: 8,
                child: _buildAssetCountBadge(context),
              ),
            if (event.eventType == 'photo_burst')
              Positioned(
                bottom: 8,
                left: 8,
                child: _buildBurstIndicator(context),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAssetPreview(MediaAsset asset) {
    switch (asset.type) {
      case AssetType.photo:
        return ShimmerLoading(
          isLoading: false, // Image.asset loads synchronously
          child: Image.asset(
            asset.localPath,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                color: Colors.grey[300],
                child: const Icon(Icons.broken_image, size: 48),
              );
            },
          ),
        );
      case AssetType.video:
        return Container(
          color: Colors.black87,
          child: const Stack(
            children: [
              Center(
                child: Icon(
                  Icons.play_circle_outline,
                  size: 48,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        );
      case AssetType.audio:
        return Container(
          color: Colors.blue[100],
          child: const Center(
            child: Icon(
              Icons.audiotrack,
              size: 48,
              color: Colors.blue,
            ),
          ),
        );
      case AssetType.document:
        return Container(
          color: Colors.grey[100],
          child: const Center(
            child: Icon(
              Icons.description,
              size: 48,
              color: Colors.grey,
            ),
          ),
        );
    }
  }

  Widget _buildAssetCountBadge(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black87,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '${event.assets.length}',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildBurstIndicator(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.burst_mode,
            size: 12,
            color: Theme.of(context).colorScheme.onPrimary,
          ),
          const SizedBox(width: 4),
          Text(
            'BURST',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onPrimary,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDescription(BuildContext context) {
    return Text(
      event.description!,
      style: Theme.of(context).textTheme.bodyMedium,
      maxLines: isExpanded ? null : 2,
      overflow: isExpanded ? null : TextOverflow.ellipsis,
    );
  }

  Widget _buildPhotoCountIndicator(BuildContext context) {
    return Row(
      children: [
        Icon(
          Icons.photo_library,
          size: 16,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 4),
        Text(
          '${event.assets.length} photos',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        if (event.eventType == 'photo_burst') ...[
          const SizedBox(width: 8),
          Icon(
            Icons.burst_mode,
            size: 16,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 4),
          Text(
            'Burst',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildExpandedContent(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (event.assets.length > 1) ...[
          Text(
            'All Photos (${event.assets.length})',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          _buildAssetGrid(context),
        ],
        if (event.customAttributes.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(
            'Details',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          _buildCustomAttributes(context),
        ],
      ],
    );
  }

  Widget _buildAssetGrid(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 4,
        mainAxisSpacing: 4,
        childAspectRatio: 1,
      ),
      itemCount: event.assets.length,
      itemBuilder: (context, index) {
        final asset = event.assets[index];
        return ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: Stack(
            fit: StackFit.expand,
            children: [
              _buildAssetPreview(asset),
              if (asset.isKeyAsset)
                Positioned(
                  top: 2,
                  right: 2,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.star,
                      size: 12,
                      color: Theme.of(context).colorScheme.onPrimary,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCustomAttributes(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: event.customAttributes.entries
          .where((entry) => entry.value != null && entry.value.toString().isNotEmpty)
          .map((entry) => _buildAttributeChip(context, entry.key, entry.value))
          .toList(),
    );
  }

  /// Enhanced preview for text-only timeline events
  Widget _buildTextOnlyPreview(BuildContext context) {
    return Container(
      height: 120,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).colorScheme.primaryContainer,
            Theme.of(context).colorScheme.secondaryContainer,
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Stack(
        children: [
          // Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Event icon
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    _getEventIcon(),
                    size: 24,
                    color: Theme.of(context).colorScheme.onPrimary,
                  ),
                ),
                
                const SizedBox(height: 8),
                
                // Event Type label
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                    ),
                  ),
                  child: Text(
                    _getEventLabel(),
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Corner indicator only for pure text events
          if (event.eventType == 'text')
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.tertiary,
                  shape: BoxShape.circle,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAttributeChip(BuildContext context, String key, dynamic value) {
    return Chip(
      label: Text(
        '$key: $value',
        style: Theme.of(context).textTheme.bodySmall,
      ),
      backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
      side: BorderSide.none,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }

  IconData _getEventIcon() {
    // Prioritize event type over asset presence
    switch (event.eventType) {
      case 'text':
        return Icons.edit_note;
      case 'milestone':
        return Icons.flag;
      case 'location':
        return Icons.place;
      case 'photo_burst':
        return Icons.burst_mode;
      case 'photo_collection':
        return Icons.collections;
      case 'renovation_progress':
        return Icons.construction;
      case 'pet_milestone':
        return Icons.pets;
      case 'business_milestone':
        return Icons.business;
      case 'photo':
      default:
        // Only check assets for generic photo type
        if (event.assets.isEmpty) {
          return Icons.image_not_supported;
        }
        return Icons.photo;
    }
  }

  String _getEventLabel() {
    switch (event.eventType) {
      case 'text':
        return 'Text Entry';
      case 'milestone':
        return 'Milestone';
      case 'location':
        return 'Location';
      case 'photo_burst':
        return event.assets.isEmpty ? 'Empty Burst' : 'Photo Burst';
      case 'photo_collection':
        return event.assets.isEmpty ? 'Empty Collection' : 'Collection';
      case 'photo':
      default:
        if (event.assets.isEmpty) {
          return 'No Photos';
        }
        return 'Photo';
    }
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    
    if (difference.inDays == 0) {
      return 'Today ${_formatTime(timestamp)}';
    } else if (difference.inDays == 1) {
      return 'Yesterday ${_formatTime(timestamp)}';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    }
  }

  String _formatTime(DateTime timestamp) {
    final hour = timestamp.hour;
    final minute = timestamp.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    
    return '$displayHour:$minute $period';
  }
}

/// Custom painter for text event background pattern
class _TextEventPatternPainter extends CustomPainter {
  final Color color;

  _TextEventPatternPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    // Draw subtle line pattern to distinguish text events
    const spacing = 20.0;
    
    // Diagonal lines
    for (double i = -size.height; i < size.width + size.height; i += spacing) {
      canvas.drawLine(
        Offset(i, 0),
        Offset(i + size.height, size.height),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}