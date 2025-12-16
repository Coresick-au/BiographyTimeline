import 'package:flutter/material.dart';
import '../../../shared/models/timeline_event.dart';
import '../../../shared/models/media_asset.dart';
import '../../../shared/widgets/core/core.dart';
import '../../../shared/widgets/modern/shimmer_loading.dart';
import '../../../shared/design_system/design_system.dart';
import '../../../shared/design_system/responsive_layout.dart';

/// Widget that displays a timeline event with photo count indicators
class TimelineEventCard extends StatefulWidget {
  final TimelineEvent event;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool showPhotoCount;
  final bool isExpanded;
  final VoidCallback? onExpandToggle;

  const TimelineEventCard({
    super.key,
    required this.event,
    this.onTap,
    this.onLongPress,
    this.showPhotoCount = true,
    this.isExpanded = false,
    this.onExpandToggle,
  });

  @override
  State<TimelineEventCard> createState() => _TimelineEventCardState();
}

class _TimelineEventCardState extends State<TimelineEventCard> {
  // Logic for hover/press states is now handled by AppCard or InkWell internally
  // but we might want to keep some state if we do custom expansion animation inside

  @override
  Widget build(BuildContext context) {
    // Determine card variant based on event type or context if needed
    // For now using Glass variant for that premium feel as per original design
    
    // Constrain max width on large displays for better readability
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: ResponsiveLayout.getValue(
            context: context,
            mobile: double.infinity,
            tablet: 560.0,
            desktop: 600.0,
          ),
        ),
        child: AppCard(
          variant: AppCardVariant.glass,
          onTap: widget.onTap,
          padding: EdgeInsets.all(ResponsiveLayout.getValue(
            context: context,
            mobile: AppSpacing.md,
            tablet: AppSpacing.lg,
            desktop: AppSpacing.lg,
          )),
          margin: ResponsiveLayout.getResponsiveMargin(context),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context),
              SizedBox(height: AppSpacing.md),
              _buildMediaPreview(context),
              
              if (widget.event.description != null) ...[
                SizedBox(height: AppSpacing.sm),
                _buildDescription(context),
              ],
              
              if (widget.event.tags.isNotEmpty) ...[
                SizedBox(height: AppSpacing.sm),
                _buildTags(context),
              ],
              
              if (widget.showPhotoCount && widget.event.assets.length > 1) ...[
                SizedBox(height: AppSpacing.sm),
                _buildPhotoCountIndicator(context),
              ],
              
              if (widget.isExpanded) ...[
                SizedBox(height: AppSpacing.lg),
                _buildExpandedContent(context),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        _buildEventTypeIcon(context),
        SizedBox(width: AppSpacing.md),
        Flexible(
          fit: FlexFit.loose,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.event.title != null)
                Text(
                  widget.event.title!,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              Text(
                _formatTimestamp(widget.event.timestamp),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
              if (widget.event.location != null)
                Text(
                  widget.event.location.toString(),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
            ],
          ),
        ),
        if (widget.event.assets.length > 1 && widget.onExpandToggle != null)
          IconButton(
            icon: Icon(widget.isExpanded ? AppIcons.expandLess : AppIcons.expandMore),
            onPressed: widget.onExpandToggle,
          ),
      ],
    );
  }

  Widget _buildEventTypeIcon(BuildContext context) {
    IconData iconData;
    Color iconColor;
    
    switch (widget.event.eventType) {
      case 'photo_burst':
        iconData = AppIcons.burstMode;
        iconColor = Theme.of(context).colorScheme.primary;
        break;
      case 'photo_collection':
        iconData = AppIcons.collections;
        iconColor = Theme.of(context).colorScheme.secondary;
        break;
      case 'renovation_progress':
        iconData = AppIcons.construction;
        iconColor = Colors.orange; // warning color fallback
        break;
      case 'pet_milestone':
        iconData = AppIcons.pets;
        iconColor = Theme.of(context).colorScheme.tertiary; // Was green
        break;
      case 'business_milestone':
        iconData = AppIcons.business;
        iconColor = Theme.of(context).colorScheme.secondary; // Was blue
        break;
      case 'text':
        iconData = AppIcons.editNote;
        iconColor = Theme.of(context).colorScheme.tertiary;
        break;
      default:
        iconData = AppIcons.photo;
        iconColor = Theme.of(context).colorScheme.onSurfaceVariant;
    }
    
    return Container(
      padding: EdgeInsets.all(ResponsiveLayout.getValue(
        context: context,
        mobile: AppSpacing.sm,
        tablet: AppSpacing.md,
        desktop: AppSpacing.lg,
      )),
      decoration: BoxDecoration(
        color: iconColor.withOpacity(widget.event.eventType == 'text' ? 0.2 : 0.1),
        borderRadius: BorderRadius.circular(ResponsiveLayout.getValue(
          context: context,
          mobile: AppRadii.sm,
          tablet: AppRadii.md,
          desktop: AppRadii.lg,
        )),
        border: widget.event.eventType == 'text' 
            ? Border.all(color: iconColor.withOpacity(0.3))
            : Border.all(color: iconColor.withOpacity(0.1)),
      ),
      child: Icon(
        iconData,
        size: ResponsiveLayout.getValue(
          context: context,
          mobile: 20.0,
          tablet: 24.0,
          desktop: 28.0,
        ),
        color: iconColor,
      ),
    );
  }

  Widget _buildMediaPreview(BuildContext context) {
    if (widget.event.assets.isEmpty) {
      // Enhanced text-only event visualization
      return _buildTextOnlyPreview(context);
    }

    final keyAsset = widget.event.assets.firstWhere(
      (asset) => asset.isKeyAsset,
      orElse: () => widget.event.assets.first,
    );

    return ClipRRect(
      borderRadius: BorderRadius.circular(ResponsiveLayout.getValue(
        context: context,
        mobile: AppRadii.sm,
        tablet: AppRadii.md,
        desktop: AppRadii.lg,
      )),
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: Stack(
          fit: StackFit.expand,
          children: [
            _buildAssetPreview(keyAsset),
            if (widget.event.assets.length > 1)
              Positioned(
                top: AppSpacing.sm,
                right: AppSpacing.sm,
                child: _buildAssetCountBadge(context),
              ),
            if (widget.event.eventType == 'photo_burst')
              Positioned(
                bottom: AppSpacing.sm,
                left: AppSpacing.sm,
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
        // Check if it's a network URL or local asset
        final isNetworkImage = asset.localPath.startsWith('http://') || 
                               asset.localPath.startsWith('https://');
        
        return ShimmerLoading(
          child: isNetworkImage
              ? Image.network(
                  asset.localPath,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.grey[300],
                      child: const Icon(
                        Icons.broken_image,
                        size: 48,
                      ),
                    );
                  },
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      color: Colors.grey[200],
                      child: Center(
                        child: CircularProgressIndicator(
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded /
                                  loadingProgress.expectedTotalBytes!
                              : null,
                        ),
                      ),
                    );
                  },
                )
              : Image.asset(
                  asset.localPath,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.grey[300],
                      child: Icon(
                        AppIcons.brokenImage,
                        size: 48,
                      ),
                    );
                  },
                ),
        );
      case AssetType.video:
        return Container(
          color: Colors.black87,
          child: Stack(
            children: [
              Center(
                child: Icon(
                  AppIcons.playCircle,
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
          child: Center(
            child: Icon(
              AppIcons.audiotrack,
              size: 48,
              color: Colors.blue,
            ),
          ),
        );
      case AssetType.document:
        return Container(
          color: Colors.grey[100],
          child: Center(
            child: Icon(
              AppIcons.description,
              size: 48,
              color: Colors.grey,
            ),
          ),
        );
    }
  }

  Widget _buildAssetCountBadge(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: context.getResponsiveValue(
          mobile: DesignTokens.space2,
          tablet: DesignTokens.space3,
          desktop: DesignTokens.space4,
        ),
        vertical: context.getResponsiveValue(
          mobile: DesignTokens.space1,
          tablet: DesignTokens.space2,
          desktop: DesignTokens.space2,
        ),
      ),
      decoration: BoxDecoration(
        color: Colors.black87,
        borderRadius: BorderRadius.circular(context.getResponsiveValue(
          mobile: DesignTokens.radiusSmall,
          tablet: DesignTokens.radiusMedium,
          desktop: DesignTokens.radiusLarge,
        )),
      ),
      child: Text(
        '${widget.event.assets.length}',
        style: TextStyle(
          color: Colors.white,
          fontSize: context.getResponsiveValue(
            mobile: DesignTokens.labelLarge.fontSize ?? 14, // 14px
            tablet: (DesignTokens.labelLarge.fontSize ?? 14) + 2, // 16px
            desktop: (DesignTokens.labelLarge.fontSize ?? 14) + 4, // 18px
          ),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildBurstIndicator(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: context.getResponsiveValue(
          mobile: DesignTokens.space2,
          tablet: DesignTokens.space3,
          desktop: DesignTokens.space4,
        ),
        vertical: context.getResponsiveValue(
          mobile: DesignTokens.space1,
          tablet: DesignTokens.space2,
          desktop: DesignTokens.space2,
        ),
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary,
        borderRadius: BorderRadius.circular(context.getResponsiveValue(
          mobile: DesignTokens.radiusSmall,
          tablet: DesignTokens.radiusMedium,
          desktop: DesignTokens.radiusLarge,
        )),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.burst_mode,
            size: context.getResponsiveValue(
              mobile: DesignTokens.labelSmall.fontSize ?? 11, // 11px
              tablet: (DesignTokens.labelSmall.fontSize ?? 11) + 2, // 13px
              desktop: (DesignTokens.labelSmall.fontSize ?? 11) + 4, // 15px
            ),
            color: Theme.of(context).colorScheme.onPrimary,
          ),
          SizedBox(width: context.getResponsiveValue(
            mobile: DesignTokens.space1,
            tablet: DesignTokens.space2,
            desktop: DesignTokens.space2,
          )),
          Text(
            'BURST',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onPrimary,
              fontSize: context.getResponsiveValue(
                mobile: DesignTokens.labelSmall.fontSize ?? 11, // 11px
                tablet: (DesignTokens.labelSmall.fontSize ?? 11) + 2, // 13px
                desktop: (DesignTokens.labelSmall.fontSize ?? 11) + 4, // 15px
              ),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDescription(BuildContext context) {
    return Text(
      widget.event.description!,
      style: Theme.of(context).textTheme.bodyMedium,
      maxLines: widget.isExpanded ? null : 2,
      overflow: widget.isExpanded ? null : TextOverflow.ellipsis,
    );
  }

  Widget _buildTags(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.xs,
      children: widget.event.tags.map((tag) {
        // Simple color mapping based on tag content
        Color tagColor;
        switch (tag.toLowerCase()) {
          case 'family': tagColor = Theme.of(context).colorScheme.primary; break;
          case 'milestone': tagColor = Theme.of(context).colorScheme.tertiary; break;
          case 'work': tagColor = Theme.of(context).colorScheme.secondary; break;
          case 'travel': tagColor = Theme.of(context).colorScheme.error; break; // Use error for vibrant pop, or add a custom semantic
          case 'celebration': tagColor = Theme.of(context).colorScheme.primary; break;
          default: tagColor = Theme.of(context).colorScheme.outline;
        }

        return AppTag(
          label: tag,
          color: tagColor,
          icon: Icons.label_outline,
        );
      }).toList(),
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
        SizedBox(width: AppSpacing.xs),
        Text(
          '${widget.event.assets.length} photos',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        if (widget.event.eventType == 'photo_burst') ...[
          SizedBox(width: AppSpacing.md),
          Icon(
            Icons.burst_mode,
            size: 16,
            color: Theme.of(context).colorScheme.primary,
          ),
          SizedBox(width: AppSpacing.xs),
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
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.event.assets.length > 1) ...[
          Text(
            'All Photos (${widget.event.assets.length})',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: AppSpacing.sm),
          _buildAssetGrid(context),
        ],
        if (widget.event.customAttributes.isNotEmpty) ...[
          SizedBox(height: AppSpacing.md),
          Text(
            'Details',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: AppSpacing.sm),
          _buildCustomAttributes(context),
        ],
      ],
    );
  }

  Widget _buildAssetGrid(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: ResponsiveLayout.getValue(
          context: context,
          mobile: 2,
          tablet: 3,
          desktop: 4,
        ),
        crossAxisSpacing: AppSpacing.xs,
        mainAxisSpacing: AppSpacing.xs,
        childAspectRatio: 1,
      ),
      itemCount: widget.event.assets.length,
      itemBuilder: (context, index) {
        final asset = widget.event.assets[index];
        return ClipRRect(
          borderRadius: BorderRadius.circular(AppRadii.sm),
          child: Stack(
            fit: StackFit.expand,
            children: [
              _buildAssetPreview(asset),
              if (asset.isKeyAsset)
                Positioned(
                  top: AppSpacing.xs,
                  right: AppSpacing.xs,
                  child: Container(
                    padding: const EdgeInsets.all(AppSpacing.xs),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      borderRadius: BorderRadius.circular(AppRadii.sm),
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
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.xs,
      children: widget.event.customAttributes.entries
          .where((entry) => entry.value != null && entry.value.toString().isNotEmpty)
          .map((entry) => _buildAttributeChip(context, entry.key, entry.value))
          .toList(),
    );
  }

  /// Enhanced preview for text-only timeline events
  Widget _buildTextOnlyPreview(BuildContext context) {
    return Container(
      height: context.getResponsiveValue(
        mobile: 130, // Increased from 120 to prevent overflow
        tablet: 140,
        desktop: 160,
      ), // Responsive height for text preview
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).colorScheme.primaryContainer,
            Theme.of(context).colorScheme.secondaryContainer,
          ],
        ),
        borderRadius: BorderRadius.circular(context.getResponsiveValue(
          mobile: DesignTokens.radiusSmall * 1.5,
          tablet: DesignTokens.radiusMedium * 1.5,
          desktop: DesignTokens.radiusLarge * 1.5,
        )),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Stack(
        children: [
          // Content
          Padding(
            padding: EdgeInsets.all(context.getResponsiveValue(
              mobile: DesignTokens.space2, // Reduced from space3 (12->8) to fix overflow
              tablet: DesignTokens.space5,
              desktop: DesignTokens.space6,
            )),
            child: Column(
              mainAxisSize: MainAxisSize.min, // Changed from max to prevent overflow
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Event icon
                Container(
                  padding: EdgeInsets.all(context.getResponsiveValue(
                    mobile: DesignTokens.space3,
                    tablet: DesignTokens.space4,
                    desktop: DesignTokens.space5,
                  )),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    borderRadius: BorderRadius.circular(context.getResponsiveValue(
                      mobile: DesignTokens.radiusSmall,
                      tablet: DesignTokens.radiusMedium,
                      desktop: DesignTokens.radiusLarge,
                    )),
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
                    size: 24, // Fixed size for event icon
                    color: Theme.of(context).colorScheme.onPrimary,
                  ),
                ),
                
                SizedBox(height: context.getResponsiveValue(
                  mobile: DesignTokens.space2,
                  tablet: DesignTokens.space3,
                  desktop: DesignTokens.space4,
                )),
                
                // Event Type label
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: context.getResponsiveValue(
                      mobile: DesignTokens.space3,
                      tablet: DesignTokens.space4,
                      desktop: DesignTokens.space5,
                    ),
                    vertical: context.getResponsiveValue(
                      mobile: DesignTokens.space1,
                      tablet: DesignTokens.space2,
                      desktop: DesignTokens.space2,
                    ),
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(context.getResponsiveValue(
                      mobile: DesignTokens.radiusSmall * 2,
                      tablet: DesignTokens.radiusMedium * 2,
                      desktop: DesignTokens.radiusLarge * 2,
                    )),
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
          if (widget.event.eventType == 'text')
            Positioned(
              top: DesignTokens.space1,
              right: DesignTokens.space1,
              child: Container(
                width: context.getResponsiveValue(
                  mobile: DesignTokens.space2,
                  tablet: DesignTokens.space3,
                  desktop: DesignTokens.space3,
                ),
                height: context.getResponsiveValue(
                  mobile: DesignTokens.space2,
                  tablet: DesignTokens.space3,
                  desktop: DesignTokens.space3,
                ),
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
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
      side: BorderSide.none,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }

  IconData _getEventIcon() {
    // Prioritize feature over specific assets
    switch (widget.event.eventType) {
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
        if (widget.event.assets.isEmpty) {
          return Icons.image_not_supported;
        }
        return Icons.photo;
    }
  }

  String _getEventLabel() {
    switch (widget.event.eventType) {
      case 'text':
        return 'Text Entry';
      case 'milestone':
        return 'Milestone';
      case 'location':
        return 'Location';
      case 'photo_burst':
        return widget.event.assets.isEmpty ? 'Empty Burst' : 'Photo Burst';
      case 'photo_collection':
        return widget.event.assets.isEmpty ? 'Empty Collection' : 'Collection';
      case 'photo':
      default:
        if (widget.event.assets.isEmpty) {
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
    const spacing = 20.0; // Fixed spacing for pattern
    
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
