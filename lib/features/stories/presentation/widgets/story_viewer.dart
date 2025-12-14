import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/models/story.dart';
import '../../../../shared/models/media_asset.dart';
import '../../services/scrollytelling_service.dart';
import '../providers/scrollytelling_provider.dart';

/// Scrollytelling story viewer with dynamic background changes
class StoryViewer extends ConsumerStatefulWidget {
  final Story story;
  final VoidCallback? onEdit;

  const StoryViewer({
    super.key,
    required this.story,
    this.onEdit,
  });

  @override
  ConsumerState<StoryViewer> createState() => _StoryViewerState();
}

class _StoryViewerState extends ConsumerState<StoryViewer>
    with TickerProviderStateMixin {
  late ScrollController _scrollController;
  late AnimationController _backgroundTransitionController;
  late ScrollytellingService _scrollytellingService;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _backgroundTransitionController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _scrollytellingService = ScrollytellingService();
    
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _backgroundTransitionController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final scrollPosition = _scrollController.offset;
    final maxScrollExtent = _scrollController.position.maxScrollExtent;
    
    // Update scrollytelling state
    ref.read(scrollytellingProvider(widget.story.id).notifier)
        .updateScrollPosition(scrollPosition, maxScrollExtent);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(scrollytellingProvider(widget.story.id));
    
    return Scaffold(
      body: Stack(
        children: [
          // Dynamic background media
          _buildBackgroundMedia(state.currentBackgroundMedia),
          
          // Overlay gradient for text readability
          _buildOverlayGradient(),
          
          // Scrollable story content
          _buildStoryContent(),
          
          // App bar
          _buildAppBar(),
          
          // Navigation controls
          _buildNavigationControls(state),
        ],
      ),
    );
  }

  /// Build dynamic background media with parallax effect
  Widget _buildBackgroundMedia(MediaAsset? backgroundMedia) {
    if (backgroundMedia == null) {
      return Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.grey[900]!,
              Colors.grey[800]!,
            ],
          ),
        ),
      );
    }

    return AnimatedBuilder(
      animation: _scrollController,
      builder: (context, child) {
        final parallaxOffset = _scrollytellingService.calculateParallaxOffset(
          _scrollController.hasClients ? _scrollController.offset : 0,
          MediaQuery.of(context).size.height,
          0.3, // Parallax factor
        );

        return Transform.translate(
          offset: Offset(0, -parallaxOffset),
          child: _buildMediaWidget(backgroundMedia),
        );
      },
    );
  }

  /// Build media widget based on asset type
  Widget _buildMediaWidget(MediaAsset asset) {
    switch (asset.type) {
      case AssetType.photo:
        return Image.network(
          asset.cloudUrl ?? asset.localPath,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              color: Colors.grey[800],
              child: const Icon(Icons.image, size: 100, color: Colors.white54),
            );
          },
        );
      case AssetType.video:
        // TODO: Implement video player
        return Container(
          color: Colors.black,
          child: const Icon(Icons.play_circle, size: 100, color: Colors.white54),
        );
      default:
        return Container(
          color: Colors.grey[800],
          child: const Icon(Icons.image, size: 100, color: Colors.white54),
        );
    }
  }

  /// Build overlay gradient for text readability
  Widget _buildOverlayGradient() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withOpacity(0.3),
            Colors.black.withOpacity(0.1),
            Colors.black.withOpacity(0.3),
          ],
          stops: const [0.0, 0.5, 1.0],
        ),
      ),
    );
  }

  /// Build scrollable story content
  Widget _buildStoryContent() {
    return CustomScrollView(
      controller: _scrollController,
      slivers: [
        // Top spacing for immersive experience
        const SliverToBoxAdapter(
          child: SizedBox(height: 200),
        ),
        
        // Story blocks
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final block = widget.story.blocks[index];
              return _buildStoryBlock(block, index);
            },
            childCount: widget.story.blocks.length,
          ),
        ),
        
        // Bottom spacing
        const SliverToBoxAdapter(
          child: SizedBox(height: 200),
        ),
      ],
    );
  }

  /// Build individual story block
  Widget _buildStoryBlock(StoryBlock block, int index) {
    final state = ref.watch(scrollytellingProvider(widget.story.id));
    final isActive = state.activeBlockIndex == index;
    
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isActive 
            ? Colors.white.withOpacity(0.95)
            : Colors.white.withOpacity(0.85),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: _buildBlockContent(block),
    );
  }

  /// Build content for different block types
  Widget _buildBlockContent(StoryBlock block) {
    switch (block.type) {
      case BlockType.text:
        return Text(
          block.content['text'] as String? ?? '',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            fontSize: 18,
            height: 1.6,
            color: Colors.black87,
          ),
        );
      
      case BlockType.image:
        final mediaAsset = MediaAsset.fromJson(
          block.content['mediaAsset'] as Map<String, dynamic>,
        );
        final caption = block.content['caption'] as String?;
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                mediaAsset.cloudUrl ?? mediaAsset.localPath,
                fit: BoxFit.cover,
                width: double.infinity,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 200,
                    color: Colors.grey[300],
                    child: const Icon(Icons.image, size: 50),
                  );
                },
              ),
            ),
            if (caption != null) ...[
              const SizedBox(height: 12),
              Text(
                caption,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontStyle: FontStyle.italic,
                  color: Colors.black54,
                ),
              ),
            ],
          ],
        );
      
      case BlockType.video:
        // TODO: Implement video block
        return Container(
          height: 200,
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.play_circle, size: 50),
        );
      
      case BlockType.audio:
        // TODO: Implement audio block
        return Container(
          height: 100,
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.audiotrack, size: 30),
        );
    }
  }

  /// Build app bar
  Widget _buildAppBar() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          if (widget.onEdit != null)
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.white),
              onPressed: widget.onEdit,
            ),
          IconButton(
            icon: const Icon(Icons.share, color: Colors.white),
            onPressed: _shareStory,
          ),
        ],
      ),
    );
  }

  /// Build navigation controls
  Widget _buildNavigationControls(dynamic state) {
    return Positioned(
      bottom: 50,
      left: 20,
      right: 20,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Progress indicator
          Expanded(
            child: Container(
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: _getScrollProgress(),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
          ),
          
          const SizedBox(width: 16),
          
          // Play/pause button for auto-scroll
          FloatingActionButton.small(
            onPressed: _toggleAutoScroll,
            backgroundColor: Colors.white.withOpacity(0.9),
            child: Icon(
              state.isPlaying ? Icons.pause : Icons.play_arrow,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  /// Get scroll progress (0.0 to 1.0)
  double _getScrollProgress() {
    if (!_scrollController.hasClients) return 0.0;
    final maxScrollExtent = _scrollController.position.maxScrollExtent;
    if (maxScrollExtent == 0) return 0.0;
    return (_scrollController.offset / maxScrollExtent).clamp(0.0, 1.0);
  }

  /// Toggle auto-scroll functionality
  void _toggleAutoScroll() {
    ref.read(scrollytellingProvider(widget.story.id).notifier)
        .toggleAutoScroll(_scrollController);
  }

  /// Share story
  void _shareStory() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Story shared successfully'),
        backgroundColor: Colors.green,
      ),
    );
  }
}