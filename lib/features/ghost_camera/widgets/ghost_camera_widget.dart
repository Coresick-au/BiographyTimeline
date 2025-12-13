import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:camera/camera.dart';
import '../../../shared/design_system/app_theme.dart';
import '../../../shared/design_system/app_icons.dart';
import '../../../shared/design_system/interaction_feedback.dart';
import '../services/ghost_camera_service.dart';

/// Ghost Camera widget with overlay for progress comparison
/// Shows camera view with semi-transparent reference image overlay
class GhostCameraWidget extends ConsumerStatefulWidget {
  const GhostCameraWidget({
    super.key,
    this.onPhotoCaptured,
    this.onReferenceSelected,
    this.context = GhostCameraContext.general,
  });

  final Function(String path)? onPhotoCaptured;
  final Function(MediaAsset asset)? onReferenceSelected;
  final GhostCameraContext context;

  @override
  ConsumerState<GhostCameraWidget> createState() => _GhostCameraWidgetState();
}

class _GhostCameraWidgetState extends ConsumerState<GhostCameraWidget>
    with TickerProviderStateMixin {
  final GlobalKey _cameraKey = GlobalKey();
  bool _isInitialized = false;
  bool _isCapturing = false;
  bool _showControls = true;
  
  late AnimationController _controlsController;
  late Animation<double> _controlsAnimation;
  
  Timer? _controlsTimer;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeCamera();
  }

  @override
  void dispose() {
    _controlsTimer?.cancel();
    _controlsController.dispose();
    super.dispose();
  }

  void _initializeAnimations() {
    _controlsController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _controlsAnimation = CurvedAnimation(
      parent: _controlsController,
      curve: Curves.easeInOut,
    );
    _controlsController.forward();
  }

  Future<void> _initializeCamera() async {
    try {
      final service = ref.read(ghostCameraProvider);
      await service.initialize();
      setState(() {
        _isInitialized = true;
      });
    } catch (e) {
      _showError('Failed to initialize camera: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final overlayState = ref.watch(ghostCameraStateProvider).value ?? GhostOverlayState();
    
    if (!_isInitialized) {
      return Scaffold(
        backgroundColor: theme.colors.background,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                color: theme.colors.primary,
              ),
              const SizedBox(height: 16),
              Text(
                'Initializing camera...',
                style: theme.textStyles.bodyMedium,
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Camera preview
          _buildCameraPreview(),
          
          // Ghost overlay
          if (overlayState.referenceImage != null)
            _buildGhostOverlay(overlayState),
          
          // Alignment guides
          _buildAlignmentGuides(overlayState),
          
          // Top controls
          _buildTopControls(overlayState),
          
          // Bottom controls
          _buildBottomControls(overlayState),
          
          // Side controls
          if (overlayState.referenceImage != null)
            _buildSideControls(overlayState),
        ],
      ),
    );
  }

  Widget _buildCameraPreview() {
    final service = ref.read(ghostCameraProvider);
    final controller = service.cameraController;
    
    if (controller == null || !controller.value.isInitialized) {
      return Container(color: Colors.black);
    }
    
    return GestureDetector(
      onTap: () => _toggleControls(),
      onPanStart: (_) => _hideControlsTemporarily(),
      onPanUpdate: (details) => _updateOverlayPosition(details),
      child: CameraPreview(
        controller,
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Calculate preview size for overlay positioning
            final size = controller.value.previewSize;
            if (size == null) return const SizedBox.shrink();
            
            return Container();
          },
        ),
      ),
    );
  }

  Widget _buildGhostOverlay(GhostOverlayState state) {
    if (!state.isVisible) return const SizedBox.shrink();
    
    return Positioned.fill(
      child: IgnorePointer(
        child: Transform.translate(
          offset: state.position,
          child: Transform.scale(
            scale: state.scale,
            child: Opacity(
              opacity: state.opacity,
              child: Image.file(
                File(state.referenceImage!.localPath),
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAlignmentGuides(GhostOverlayState state) {
    final guide = state.currentGuide;
    final theme = AppTheme.of(context);
    
    return Positioned.fill(
      child: IgnorePointer(
        child: CustomPaint(
          painter: AlignmentGuidePainter(
            guide.lines,
            color: theme.colors.primary.withOpacity(0.5),
            strokeWidth: 1.0,
          ),
        ),
      ),
    );
  }

  Widget _buildTopControls(GhostOverlayState state) {
    final theme = AppTheme.of(context);
    
    return AnimatedBuilder(
      animation: _controlsAnimation,
      builder: (context, child) {
        return Positioned(
          top: MediaQuery.of(context).padding.top + 16,
          left: 16,
          right: 16,
          child: Opacity(
            opacity: _showControls ? _controlsAnimation.value : 0.0,
            child: Row(
              children: [
                // Reference image selector
                if (widget.context != GhostCameraContext.personal)
                  IconButton(
                    onPressed: _selectReferenceImage,
                    icon: Icon(
                      AppIcons.photoLibrary,
                      color: theme.colors.onSurface,
                    ),
                    style: IconButton.styleFrom(
                      backgroundColor: theme.colors.surfaceVariant,
                    ),
                  ),
                
                const Spacer(),
                
                // Flash toggle
                IconButton(
                  onPressed: _toggleFlash,
                  icon: Icon(
                    _getFlashIcon(),
                    color: theme.colors.onSurface,
                  ),
                  style: IconButton.styleFrom(
                    backgroundColor: theme.colors.surfaceVariant,
                  ),
                ),
                
                const SizedBox(width: 8),
                
                // Camera switch
                if (ref.read(ghostCameraProvider).cameras.length > 1)
                  IconButton(
                    onPressed: _switchCamera,
                    icon: Icon(
                      AppIcons.cameraFlip,
                      color: theme.colors.onSurface,
                    ),
                    style: IconButton.styleFrom(
                      backgroundColor: theme.colors.surfaceVariant,
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBottomControls(GhostOverlayState state) {
    final theme = AppTheme.of(context);
    
    return AnimatedBuilder(
      animation: _controlsAnimation,
      builder: (context, child) {
        return Positioned(
          bottom: MediaQuery.of(context).padding.bottom + 32,
          left: 16,
          right: 16,
          child: Opacity(
            opacity: _showControls ? _controlsAnimation.value : 0.0,
            child: Row(
              children: [
                // Gallery button
                IconButton(
                  onPressed: _openGallery,
                  icon: Icon(
                    AppIcons.image,
                    color: theme.colors.onSurface,
                  ),
                  style: IconButton.styleFrom(
                    backgroundColor: theme.colors.surfaceVariant,
                  ),
                ),
                
                const Spacer(),
                
                // Capture button
                GestureDetector(
                  onTap: _isCapturing ? null : _capturePhoto,
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: theme.colors.onSurface,
                        width: 4,
                      ),
                      color: _isCapturing 
                          ? theme.colors.surfaceVariant 
                          : Colors.transparent,
                    ),
                    child: _isCapturing
                        ? Center(
                            child: SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                color: theme.colors.primary,
                                strokeWidth: 2,
                              ),
                            ),
                          )
                        : null,
                  ),
                ),
                
                const Spacer(),
                
                // Alignment guide toggle
                IconButton(
                  onPressed: _cycleAlignmentGuide,
                  icon: Icon(
                    AppIcons.grid,
                    color: theme.colors.onSurface,
                  ),
                  style: IconButton.styleFrom(
                    backgroundColor: theme.colors.surfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSideControls(GhostOverlayState state) {
    final theme = AppTheme.of(context);
    
    return AnimatedBuilder(
      animation: _controlsAnimation,
      builder: (context, child) {
        return Positioned(
          right: 16,
          top: 120,
          bottom: 150,
          child: Opacity(
            opacity: _showControls ? _controlsAnimation.value : 0.0,
            child: Column(
              children: [
                // Opacity slider
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colors.surfaceVariant,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: RotatedBox(
                    quarterTurns: 3,
                    child: SizedBox(
                      width: 200,
                      child: Slider(
                        value: state.opacity,
                        onChanged: _setOpacity,
                        min: 0.0,
                        max: 1.0,
                        activeColor: theme.colors.primary,
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Scale slider
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colors.surfaceVariant,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: RotatedBox(
                    quarterTurns: 3,
                    child: SizedBox(
                      width: 200,
                      child: Slider(
                        value: state.scale,
                        onChanged: _setScale,
                        min: 0.1,
                        max: 3.0,
                        activeColor: theme.colors.primary,
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Overlay toggle
                IconButton(
                  onPressed: _toggleOverlay,
                  icon: Icon(
                    state.isVisible ? AppIcons.eye : AppIcons.eyeOff,
                    color: state.isVisible 
                        ? theme.colors.primary 
                        : theme.colors.onSurfaceVariant,
                  ),
                  style: IconButton.styleFrom(
                    backgroundColor: theme.colors.surfaceVariant,
                  ),
                ),
                
                const SizedBox(height: 8),
                
                // Reset overlay
                IconButton(
                  onPressed: _resetOverlay,
                  icon: Icon(
                    AppIcons.refresh,
                    color: theme.colors.onSurfaceVariant,
                  ),
                  style: IconButton.styleFrom(
                    backgroundColor: theme.colors.surfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // =========================================================================
  // CONTROL ACTIONS
  // =========================================================================

  void _toggleControls() {
    setState(() {
      _showControls = !_showControls;
    });
    
    if (_showControls) {
      _controlsController.forward();
      _hideControlsAfterDelay();
    } else {
      _controlsController.reverse();
      _controlsTimer?.cancel();
    }
  }

  void _hideControlsTemporarily() {
    if (_showControls) {
      setState(() {
        _showControls = false;
      });
      _controlsController.reverse();
    }
  }

  void _hideControlsAfterDelay() {
    _controlsTimer?.cancel();
    _controlsTimer = Timer(const Duration(seconds: 3), () {
      if (mounted && _showControls) {
        setState(() {
          _showControls = false;
        });
        _controlsController.reverse();
      }
    });
  }

  void _updateOverlayPosition(DragUpdateDetails details) {
    final service = ref.read(ghostCameraProvider);
    final currentPos = service.overlayState.position;
    service.setPosition(currentPos + details.delta);
  }

  void _selectReferenceImage() async {
    // Implementation would open photo selector
    // For now, just a placeholder
    InteractionFeedback.trigger();
  }

  void _toggleFlash() async {
    final service = ref.read(ghostCameraProvider);
    await service.toggleFlash();
  }

  void _switchCamera() async {
    final service = ref.read(ghostCameraProvider);
    await service.switchCamera();
  }

  void _capturePhoto() async {
    if (_isCapturing) return;
    
    setState(() {
      _isCapturing = true;
    });
    
    InteractionFeedback.trigger();
    
    try {
      final service = ref.read(ghostCameraProvider);
      final path = await service.capturePhoto();
      
      // Flash animation
      _flashAnimation();
      
      widget.onPhotoCaptured?.call(path);
    } catch (e) {
      _showError('Failed to capture photo: $e');
    } finally {
      setState(() {
        _isCapturing = false;
      });
    }
  }

  void _openGallery() {
    // Implementation would open gallery
    InteractionFeedback.trigger();
  }

  void _cycleAlignmentGuide() {
    final service = ref.read(ghostCameraProvider);
    service.cycleAlignmentGuide();
  }

  void _setOpacity(double value) {
    final service = ref.read(ghostCameraProvider);
    service.setOpacity(value);
  }

  void _setScale(double value) {
    final service = ref.read(ghostCameraProvider);
    service.setScale(value);
  }

  void _toggleOverlay() {
    final service = ref.read(ghostCameraProvider);
    service.toggleOverlay();
  }

  void _resetOverlay() async {
    final service = ref.read(ghostCameraProvider);
    await service.resetOverlay();
  }

  void _flashAnimation() {
    // Simple flash animation
    setState(() {});
    Future.delayed(const Duration(milliseconds: 100), () {
      setState(() {});
    });
  }

  IconData _getFlashIcon() {
    final service = ref.read(ghostCameraProvider);
    final controller = service.cameraController;
    
    if (controller?.value.flashMode == FlashMode.off) {
      return AppIcons.flashOff;
    } else {
      return AppIcons.flashOn;
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.of(context).colors.error,
      ),
    );
  }
}

// =========================================================================
// CUSTOM PAINTER FOR ALIGNMENT GUIDES
// =========================================================================

class AlignmentGuidePainter extends CustomPainter {
  final List<Line> lines;
  final Color color;
  final double strokeWidth;

  AlignmentGuidePainter(
    this.lines, {
    required this.color,
    this.strokeWidth = 1.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    for (final line in lines) {
      final start = Offset(line.start.dx * size.width, line.start.dy * size.height);
      final end = Offset(line.end.dx * size.width, line.end.dy * size.height);
      
      canvas.drawLine(start, end, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// =========================================================================
// CONTEXT ENUM
// =========================================================================

enum GhostCameraContext {
  general,
  renovation,
  pet,
  personal,
}

// =========================================================================
// EXTENSIONS
// =========================================================================

extension GhostCameraContextExtension on GhostCameraContext {
  bool get showGhostCamera {
    switch (this) {
      case GhostCameraContext.renovation:
      case GhostCameraContext.pet:
        return true;
      case GhostCameraContext.general:
      case GhostCameraContext.personal:
        return false;
    }
  }
}
