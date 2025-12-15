import 'package:flutter/material.dart';
import '../../../shared/models/timeline_event.dart';
import '../../../shared/models/media_asset.dart';
import '../../../shared/widgets/modern/glassmorphism_card.dart';
import '../../../shared/widgets/modern/shimmer_loading.dart';
import '../../../shared/design_system/design_tokens.dart';
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
  bool _isHovered = false;
  bool _isPressed = false;
  
  void _setHover(bool isHovered) {
    if (mounted) {
      setState(() {
        _isHovered = isHovered;
      });
    }
  }

  void _setPressed(bool isPressed) {
    if (mounted) {
      setState(() {
        _isPressed = isPressed;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Note: isDark is kept for potential future use in responsive theming
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Scale down slightly when pressed, scale up slightly when hovered
    final scale = _isPressed ? 0.98 : (_isHovered ? 1.02 : 1.0);
    
    return MouseRegion(
      onEnter: (_) => _setHover(true),
      onExit: (_) => _setHover(false),
      child: GestureDetector(
        onTapDown: (_) => _setPressed(true),
        onTapUp: (_) => _setPressed(false),
        onTapCancel: () => _setPressed(false),
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: scale,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(
                ResponsiveLayout.getValue(
                  context: context,
                  mobile: DesignTokens.radiusLarge + 4,
                  tablet: DesignTokens.radiusLarge + 6,
                  desktop: DesignTokens.radiusLarge + 8,
                ),
              ),
              boxShadow: _isHovered ? [
                BoxShadow(
                  color: Theme.of(context).shadowColor.withOpacity(0.2),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                )
              ] : [],
            ),
            child: GlassmorphismCard(
              margin: ResponsiveLayout.getResponsiveMargin(context),
              borderRadius: ResponsiveLayout.getValue(
                context: context,
                mobile: DesignTokens.radiusLarge + 4, // 20px
                tablet: DesignTokens.radiusLarge + 6, // 22px
                desktop: DesignTokens.radiusLarge + 8, // 24px
              ),
              blur: 15,
              // allow defaults to take over for better glass effect
              padding: ResponsiveLayout.getResponsivePadding(context),
              child: Column(
              mainAxisSize: MainAxisSize.min, // Prevent overflow
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                  _buildHeader(context),
                  SizedBox(height: context.getResponsiveValue(
                    mobile: DesignTokens.space3,
                    tablet: DesignTokens.space4,
                    desktop: DesignTokens.space5,
                  )),
                  _buildMediaPreview(context),
                  if (widget.event.description != null) ...[
                    SizedBox(height: context.getResponsiveValue(
                      mobile: DesignTokens.space2,
                      tablet: DesignTokens.space3,
                      desktop: DesignTokens.space4,
                    )),
                    _buildDescription(context),
                  ],
                  // Add tags display
                  if (widget.event.tags.isNotEmpty) ...[
                    SizedBox(height: context.getResponsiveValue(
                      mobile: DesignTokens.space2,
                      tablet: DesignTokens.space3,
                      desktop: DesignTokens.space4,
                    )),
                    _buildTags(context),
                  ],
                  if (widget.showPhotoCount && widget.event.assets.length > 1) ...[
                    SizedBox(height: context.getResponsiveValue(
                      mobile: DesignTokens.space2,
                      tablet: DesignTokens.space3,
                      desktop: DesignTokens.space4,
                    )),
                    _buildPhotoCountIndicator(context),
                  ],
                  if (widget.isExpanded) ...[
                    SizedBox(height: context.getResponsiveValue(
                      mobile: DesignTokens.space3,
                      tablet: DesignTokens.space4,
                      desktop: DesignTokens.space5,
                    )),
                    _buildExpandedContent(context),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        _buildEventTypeIcon(context),
        SizedBox(width: context.getResponsiveValue(
          mobile: DesignTokens.space2,
          tablet: DesignTokens.space3,
          desktop: DesignTokens.space4,
        )),
        Flexible(
          fit: FlexFit.loose,
          child: Column(
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
            icon: Icon(widget.isExpanded ? Icons.expand_less : Icons.expand_more),
            onPressed: widget.onExpandToggle,
          ),
      ],
    );
  }

  Widget _buildEventTypeIcon(BuildContext context) {
    IconData iconData;
    Color? iconColor;
    
    switch (widget.event.eventType) {
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
      padding: EdgeInsets.all(context.getResponsiveValue(
        mobile: DesignTokens.space2,
        tablet: DesignTokens.space3,
        desktop: DesignTokens.space4,
      )),
      decoration: BoxDecoration(
        color: iconColor.withOpacity(widget.event.eventType == 'text' ? 0.2 : 0.1),
        borderRadius: BorderRadius.circular(context.getResponsiveValue(
          mobile: DesignTokens.radiusSmall,
          tablet: DesignTokens.radiusMedium,
          desktop: DesignTokens.radiusLarge,
        )),
        border: widget.event.eventType == 'text' 
            ? Border.all(color: iconColor.withOpacity(0.3))
            : Border.all(color: iconColor.withOpacity(0.1)),
      ),
      child: Icon(
        iconData,
        size: context.getResponsiveValue(
          mobile: DesignTokens.space4 + 4, // 20px
          tablet: DesignTokens.space5 + 4, // 24px
          desktop: DesignTokens.space6 + 4, // 28px
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
      borderRadius: BorderRadius.circular(context.getResponsiveValue(
        mobile: DesignTokens.radiusSmall,
        tablet: DesignTokens.radiusMedium,
        desktop: DesignTokens.radiusLarge,
      )),
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: Stack(
          fit: StackFit.expand,
          children: [
            _buildAssetPreview(keyAsset),
            if (widget.event.assets.length > 1)
              Positioned(
                top: context.getResponsiveValue(
                  mobile: DesignTokens.space2,
                  tablet: DesignTokens.space3,
                  desktop: DesignTokens.space4,
                ),
                right: context.getResponsiveValue(
                  mobile: DesignTokens.space2,
                  tablet: DesignTokens.space3,
                  desktop: DesignTokens.space4,
                ),
                child: _buildAssetCountBadge(context),
              ),
            if (widget.event.eventType == 'photo_burst')
              Positioned(
                bottom: context.getResponsiveValue(
                  mobile: DesignTokens.space2,
                  tablet: DesignTokens.space3,
                  desktop: DesignTokens.space4,
                ),
                left: context.getResponsiveValue(
                  mobile: DesignTokens.space2,
                  tablet: DesignTokens.space3,
                  desktop: DesignTokens.space4,
                ),
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
                      child: const Icon(
                        Icons.broken_image,
                        size: 48,
                      ),
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
                  size: 48, // Keep explicit size for video icon
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
              size: 48, // Keep explicit size for audio icon
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
              size: 48, // Keep explicit size for document icon
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
      spacing: 8,
      runSpacing: 8,
      children: widget.event.tags.map((tag) {
        // Color-code tags
        Color tagColor;
        switch (tag.toLowerCase()) {
          case 'family':
            tagColor = Colors.blue;
            break;
          case 'milestone':
            tagColor = Colors.purple;
            break;
          case 'work':
            tagColor = Colors.orange;
            break;
          case 'travel':
            tagColor = Colors.green;
            break;
          case 'celebration':
            tagColor = Colors.pink;
            break;
          default:
            tagColor = Theme.of(context).colorScheme.primary;
        }

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: tagColor.withOpacity(0.2),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: tagColor.withOpacity(0.5),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.label,
                size: 14,
                color: tagColor,
              ),
              const SizedBox(width: 4),
              Text(
                tag,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: tagColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPhotoCountIndicator(BuildContext context) {
    return Row(
      children: [
        Icon(
          Icons.photo_library,
          size: context.getResponsiveValue(
            mobile: DesignTokens.space4, // 16px
            tablet: DesignTokens.space5, // 20px
            desktop: DesignTokens.space6, // 24px
          ),
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        SizedBox(width: context.getResponsiveValue(
          mobile: DesignTokens.space1,
          tablet: DesignTokens.space2,
          desktop: DesignTokens.space2,
        )),
        Text(
          '${widget.event.assets.length} photos',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        if (widget.event.eventType == 'photo_burst') ...[
          SizedBox(width: context.getResponsiveValue(
            mobile: DesignTokens.space2,
            tablet: DesignTokens.space3,
            desktop: DesignTokens.space4,
          )),
          Icon(
            Icons.burst_mode,
            size: context.getResponsiveValue(
              mobile: DesignTokens.space4, // 16px
              tablet: DesignTokens.space5, // 20px
              desktop: DesignTokens.space6, // 24px
            ),
            color: Theme.of(context).colorScheme.primary,
          ),
          SizedBox(width: context.getResponsiveValue(
            mobile: DesignTokens.space1,
            tablet: DesignTokens.space2,
            desktop: DesignTokens.space2,
          )),
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
        if (widget.event.assets.length > 1) ...[
          Text(
            'All Photos (${widget.event.assets.length})',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: context.getResponsiveValue(
            mobile: DesignTokens.space2,
            tablet: DesignTokens.space3,
            desktop: DesignTokens.space4,
          )),
          _buildAssetGrid(context),
        ],
        if (widget.event.customAttributes.isNotEmpty) ...[
          SizedBox(height: context.getResponsiveValue(
            mobile: DesignTokens.space3,
            tablet: DesignTokens.space4,
            desktop: DesignTokens.space5,
          )),
          Text(
            'Details',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: context.getResponsiveValue(
            mobile: DesignTokens.space2,
            tablet: DesignTokens.space3,
            desktop: DesignTokens.space4,
          )),
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
        crossAxisCount: context.getResponsiveValue(
          mobile: 2,
          tablet: 3,
          desktop: 4,
        ),
        crossAxisSpacing: context.getResponsiveValue(
          mobile: DesignTokens.space1,
          tablet: DesignTokens.space2,
          desktop: DesignTokens.space3,
        ),
        mainAxisSpacing: context.getResponsiveValue(
          mobile: DesignTokens.space1,
          tablet: DesignTokens.space2,
          desktop: DesignTokens.space3,
        ),
        childAspectRatio: 1,
      ),
      itemCount: widget.event.assets.length,
      itemBuilder: (context, index) {
        final asset = widget.event.assets[index];
        return ClipRRect(
          borderRadius: BorderRadius.circular(context.getResponsiveValue(
            mobile: DesignTokens.radiusXSmall,
            tablet: DesignTokens.radiusSmall,
            desktop: DesignTokens.radiusMedium,
          )),
          child: Stack(
            fit: StackFit.expand,
            children: [
              _buildAssetPreview(asset),
              if (asset.isKeyAsset)
                Positioned(
                  top: context.getResponsiveValue(
                    mobile: DesignTokens.space2,
                    tablet: DesignTokens.space3,
                    desktop: DesignTokens.space4,
                  ),
                  right: context.getResponsiveValue(
                    mobile: DesignTokens.space2,
                    tablet: DesignTokens.space3,
                    desktop: DesignTokens.space4,
                  ),
                  child: Container(
                    padding: EdgeInsets.all(context.getResponsiveValue(
                      mobile: DesignTokens.space1,
                      tablet: DesignTokens.space2,
                      desktop: DesignTokens.space2,
                    )),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      borderRadius: BorderRadius.circular(context.getResponsiveValue(
                        mobile: DesignTokens.radiusSmall,
                        tablet: DesignTokens.radiusMedium,
                        desktop: DesignTokens.radiusLarge,
                      )),
                    ),
                    child: Icon(
                      Icons.star,
                      size: context.getResponsiveValue(
                        mobile: DesignTokens.labelSmall.fontSize ?? 11, // 11px
                        tablet: (DesignTokens.labelSmall.fontSize ?? 11) + 2, // 13px
                        desktop: (DesignTokens.labelSmall.fontSize ?? 11) + 4, // 15px
                      ),
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
      spacing: context.getResponsiveValue(
        mobile: DesignTokens.space2,
        tablet: DesignTokens.space3,
        desktop: DesignTokens.space4,
      ),
      runSpacing: context.getResponsiveValue(
        mobile: DesignTokens.space1,
        tablet: DesignTokens.space2,
        desktop: DesignTokens.space2,
      ),
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