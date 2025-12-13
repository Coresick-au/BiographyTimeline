import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/design_system/app_theme.dart';
import '../../../shared/models/timeline_event.dart';
import '../../../shared/models/media_asset.dart';
import '../../../shared/performance/performance_service.dart';

/// Optimized timeline widget for handling large datasets efficiently
/// Uses virtual scrolling, lazy loading, and memory optimization
class OptimizedTimelineWidget extends ConsumerStatefulWidget {
  const OptimizedTimelineWidget({
    super.key,
    required this.events,
    this.onEventTap,
    this.onEventLongPress,
    this.controller,
    this.padding = EdgeInsets.zero,
  });

  final List<TimelineEvent> events;
  final Function(TimelineEvent)? onEventTap;
  final Function(TimelineEvent)? onEventLongPress;
  final ScrollController? controller;
  final EdgeInsets padding;

  @override
  ConsumerState<OptimizedTimelineWidget> createState() => _OptimizedTimelineWidgetState();
}

class _OptimizedTimelineWidgetState extends ConsumerState<OptimizedTimelineWidget>
    with AutomaticKeepAliveClientMixin {
  
  late ScrollController _scrollController;
  late PerformanceService _performanceService;
  
  // Virtual scrolling optimization
  final Map<int, TimelineEvent> _visibleEvents = {};
  final Map<int, Widget> _cachedWidgets = {};
  final int _cacheSize = 20;
  
  // Performance tracking
  DateTime _lastScrollTime = DateTime.now();
  bool _isScrollingFast = false;
  
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _scrollController = widget.controller ?? ScrollController();
    _performanceService = ref.read(performanceServiceProvider);
    
    // Add scroll listener for performance monitoring
    _scrollController.addListener(_handleScrollChange);
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _scrollController.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    
    return NotificationListener<ScrollNotification>(
      onNotification: _handleScrollNotification,
      child: ListView.builder(
        controller: _scrollController,
        padding: widget.padding,
        cacheExtent: 500.0, // Extended cache for smoother scrolling
        itemCount: widget.events.length,
        itemExtent: _getItemExtent,
        itemBuilder: (context, index) {
          return _buildOptimizedItem(index);
        },
      ),
    );
  }

  double get _getItemExtent {
    // Calculate based on device size and orientation
    final screenHeight = MediaQuery.of(context).size.height;
    return screenHeight < 600 ? 120.0 : 150.0;
  }

  Widget _buildOptimizedItem(int index) {
    // Check cache first
    if (_cachedWidgets.containsKey(index)) {
      return _cachedWidgets[index]!;
    }
    
    final event = widget.events[index];
    
    // Build optimized widget based on scroll speed
    final widget = _isScrollingFast
        ? _buildFastScrollItem(event, index)
        : _buildNormalItem(event, index);
    
    // Cache the widget
    _cachedWidgets[index] = widget;
    
    // Limit cache size
    if (_cachedWidgets.length > _cacheSize) {
      _cachedWidgets.remove(_cachedWidgets.keys.first);
    }
    
    return widget;
  }

  Widget _buildNormalItem(TimelineEvent event, int index) {
    final theme = AppTheme.of(context);
    
    return TimelineEventCard(
      event: event,
      onTap: () => widget.onEventTap?.call(event),
      onLongPress: () => widget.onEventLongPress?.call(event),
      useFullQuality: true,
      performanceService: _performanceService,
    );
  }

  Widget _buildFastScrollItem(TimelineEvent event, int index) {
    final theme = AppTheme.of(context);
    
    // Simplified widget for fast scrolling
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colors.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          // Placeholder for image
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: theme.colors.surface,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.event,
              color: theme.colors.textSecondary,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.title,
                  style: theme.textStyles.titleMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  _formatDate(event.startDate),
                  style: theme.textStyles.bodySmall.copyWith(
                    color: theme.colors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  bool _handleScrollNotification(ScrollNotification notification) {
    _performanceService.monitorTimelineScroll(notification);
    return false;
  }

  void _handleScrollChange() {
    final now = DateTime.now();
    final timeDiff = now.difference(_lastScrollTime);
    
    // Calculate scroll velocity
    if (timeDiff.inMilliseconds < 100) {
      _isScrollingFast = true;
    } else {
      _isScrollingFast = false;
    }
    
    _lastScrollTime = now;
    
    // Clear cache if scrolling fast
    if (_isScrollingFast && _cachedWidgets.length > 10) {
      _cachedWidgets.clear();
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    return '${date.day}/${date.month}/${date.year}';
  }
}

/// Optimized timeline event card with lazy image loading
class TimelineEventCard extends StatefulWidget {
  const TimelineEventCard({
    super.key,
    required this.event,
    required this.onTap,
    required this.onLongPress,
    required this.useFullQuality,
    required this.performanceService,
  });

  final TimelineEvent event;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool useFullQuality;
  final PerformanceService performanceService;

  @override
  State<TimelineEventCard> createState() => _TimelineEventCardState();
}

class _TimelineEventCardState extends State<TimelineEventCard>
    with AutomaticKeepAliveClientMixin {
  
  bool _isImageLoading = false;
  ImageProvider? _imageProvider;
  
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  @override
  void didUpdateWidget(TimelineEventCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.event.id != widget.event.id) {
      _loadImage();
    }
  }

  void _loadImage() async {
    if (widget.event.mediaAssets.isEmpty) return;
    
    setState(() {
      _isImageLoading = true;
    });
    
    try {
      // Load first image with optimization
      final asset = widget.event.mediaAssets.first;
      
      if (widget.useFullQuality) {
        _imageProvider = ResizeImage(
          FileImage(File(asset.localPath)),
          width: 200,
          height: 200,
        );
      } else {
        // Use thumbnail for fast scrolling
        _imageProvider = ResizeImage(
          FileImage(File(asset.localPath)),
          width: 60,
          height: 60,
        );
      }
      
      setState(() {
        _isImageLoading = false;
      });
    } catch (e) {
      setState(() {
        _isImageLoading = false;
        _imageProvider = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = AppTheme.of(context);
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Material(
        color: theme.colors.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
        elevation: 2,
        child: InkWell(
          onTap: widget.onTap,
          onLongPress: widget.onLongPress,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image or placeholder
                _buildImageSection(),
                const SizedBox(width: 16),
                
                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title
                      Text(
                        widget.event.title,
                        style: theme.textStyles.titleMedium,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      
                      const SizedBox(height: 8),
                      
                      // Date and location
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today,
                            size: 16,
                            color: theme.colors.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _formatDate(widget.event.startDate),
                            style: theme.textStyles.bodySmall.copyWith(
                              color: theme.colors.textSecondary,
                            ),
                          ),
                          
                          if (widget.event.location != null) ...[
                            const SizedBox(width: 16),
                            Icon(
                              Icons.location_on,
                              size: 16,
                              color: theme.colors.textSecondary,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                widget.event.location!.name,
                                style: theme.textStyles.bodySmall.copyWith(
                                  color: theme.colors.textSecondary,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ],
                      ),
                      
                      // Description preview
                      if (widget.event.description != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          _getDescriptionPreview(widget.event.description!),
                          style: theme.textStyles.bodyMedium.copyWith(
                            color: theme.colors.textSecondary,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      
                      // Tags
                      if (widget.event.tags.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          children: widget.event.tags.take(3).map((tag) {
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: theme.colors.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                tag,
                                style: theme.textStyles.labelSmall.copyWith(
                                  color: theme.colors.primary,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImageSection() {
    final theme = AppTheme.of(context);
    
    if (widget.event.mediaAssets.isEmpty) {
      // Placeholder
      return Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          color: theme.colors.surface,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          Icons.event,
          color: theme.colors.textSecondary,
          size: 32,
        ),
      );
    }
    
    if (_isImageLoading) {
      // Loading placeholder
      return Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          color: theme.colors.surface,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: theme.colors.primary,
          ),
        ),
      );
    }
    
    if (_imageProvider != null) {
      // Optimized image
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image(
          image: _imageProvider!,
          width: 80,
          height: 80,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: theme.colors.errorContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.broken_image,
                color: theme.colors.error,
              ),
            );
          },
        ),
      );
    }
    
    // Fallback
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: theme.colors.surface,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        Icons.image,
        color: theme.colors.textSecondary,
      ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    return '${date.day}/${date.month}/${date.year}';
  }

  String _getDescriptionPreview(String description) {
    // Strip HTML tags for preview
    final plainText = description
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .trim();
    
    if (plainText.length <= 100) return plainText;
    return '${plainText.substring(0, 100)}...';
  }
}

/// Performance overlay for debugging
class PerformanceOverlay extends ConsumerWidget {
  const PerformanceOverlay({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final performanceService = ref.watch(performanceServiceProvider);
    final metrics = ref.watch(performanceMetricsProvider).value ?? [];
    
    return Positioned(
      top: 50,
      right: 16,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.8),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'FPS: ${performanceService.currentFPS.toStringAsFixed(1)}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontFamily: 'monospace',
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Memory: ${performanceService.memoryUsageMB} MB',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontFamily: 'monospace',
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Cached: ${metrics.length}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontFamily: 'monospace',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
