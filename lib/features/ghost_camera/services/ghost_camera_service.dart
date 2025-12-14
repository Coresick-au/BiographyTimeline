import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:camera/camera.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:uuid/uuid.dart';
import '../../../shared/database/database_service.dart';
import '../../../shared/models/media_asset.dart';
import '../../../shared/models/timeline_event.dart';

/// Ghost Camera service for progress comparison photography
/// Manages camera overlay with reference images and alignment controls
class GhostCameraService {
  static GhostCameraService? _instance;
  static GhostCameraService get instance => _instance ??= GhostCameraService._();
  
  GhostCameraService._();

  final _uuid = const Uuid();
  final _dbService = DatabaseService.instance;
  
  // Camera controller
  CameraController? _cameraController;
  List<CameraDescription> _cameras = [];
  int _currentCameraIndex = 0;
  
  // Ghost overlay state
  GhostOverlayState _overlayState = GhostOverlayState();
  
  // Stream controllers
  final _stateController = StreamController<GhostOverlayState>.broadcast();
  final _captureController = StreamController<String>.broadcast();
  
  // Alignment guides
  final List<AlignmentGuide> _guides = [
    AlignmentRuleOfThirds(),
    AlignmentGrid(),
    AlignmentCrosshair(),
  ];
  int _currentGuideIndex = 0;

  // =========================================================================
  // PUBLIC API
  // =========================================================================

  /// Initialize camera and ghost camera service
  Future<void> initialize() async {
    try {
      // Get available cameras
      _cameras = await availableCameras();
      
      if (_cameras.isEmpty) {
        throw GhostCameraException('No cameras available');
      }
      
      // Initialize default camera
      await _initializeCamera(_currentCameraIndex);
      
      // Load saved overlay state
      await _loadOverlayState();
    } catch (e) {
      throw GhostCameraException('Failed to initialize: $e');
    }
  }

  /// Set reference image for ghost overlay
  Future<void> setReferenceImage(MediaAsset asset) async {
    if (!await File(asset.localPath).exists()) {
      throw GhostCameraException('Reference image not found');
    }
    
    _overlayState.referenceImage = asset;
    _overlayState.isVisible = true;
    
    // Calculate initial fit
    await _calculateInitialFit();
    
    _notifyStateChange();
    await _saveOverlayState();
  }

  /// Clear reference image
  void clearReferenceImage() {
    _overlayState.referenceImage = null;
    _overlayState.isVisible = false;
    _notifyStateChange();
    _saveOverlayState();
  }

  /// Update overlay opacity
  void setOpacity(double opacity) {
    opacity = opacity.clamp(0.0, 1.0);
    _overlayState.opacity = opacity;
    _notifyStateChange();
  }

  /// Update overlay position
  void setPosition(Offset position) {
    _overlayState.position = position;
    _notifyStateChange();
  }

  /// Update overlay scale
  void setScale(double scale) {
    scale = scale.clamp(0.1, 3.0);
    _overlayState.scale = scale;
    _notifyStateChange();
  }

  /// Toggle overlay visibility
  void toggleOverlay() {
    _overlayState.isVisible = !_overlayState.isVisible;
    _notifyStateChange();
  }

  /// Switch camera
  Future<void> switchCamera() async {
    if (_cameras.length < 2) return;
    
    _currentCameraIndex = (_currentCameraIndex + 1) % _cameras.length;
    await _initializeCamera(_currentCameraIndex);
  }

  /// Toggle flash
  Future<void> toggleFlash() async {
    if (_cameraController == null) return;
    
    try {
      if (_cameraController!.value.flashMode == FlashMode.off) {
        await _cameraController!.setFlashMode(FlashMode.auto);
      } else {
        await _cameraController!.setFlashMode(FlashMode.off);
      }
    } catch (e) {
      // Flash not supported
    }
  }

  /// Capture photo with ghost overlay
  Future<String> capturePhoto() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      throw GhostCameraException('Camera not initialized');
    }
    
    try {
      final XFile photo = await _cameraController!.takePicture();
      
      // Save to app directory
      final appDir = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final filename = 'ghost_capture_$timestamp.jpg';
      final savedPath = path.join(appDir.path, 'photos', filename);
      
      await Directory(path.dirname(savedPath)).create(recursive: true);
      await File(photo.path).copy(savedPath);
      
      // Notify capture
      _captureController.add(savedPath);
      
      return savedPath;
    } catch (e) {
      throw GhostCameraException('Failed to capture photo: $e');
    }
  }

  /// Cycle through alignment guides
  void cycleAlignmentGuide() {
    _currentGuideIndex = (_currentGuideIndex + 1) % _guides.length;
    _overlayState.currentGuide = _guides[_currentGuideIndex];
    _notifyStateChange();
  }

  /// Reset overlay to initial position
  void resetOverlay() async {
    if (_overlayState.referenceImage != null) {
      await _calculateInitialFit();
      _overlayState.opacity = 0.5;
      _notifyStateChange();
    }
  }

  // =========================================================================
  // GETTERS
  // =========================================================================

  CameraController? get cameraController => _cameraController;
  bool get isInitialized => _cameraController?.value.isInitialized ?? false;
  GhostOverlayState get overlayState => _overlayState;
  Stream<GhostOverlayState> get overlayStateStream => _stateController.stream;
  Stream<String> get captureStream => _captureController.stream;
  List<CameraDescription> get cameras => _cameras;
  int get currentCameraIndex => _currentCameraIndex;

  // =========================================================================
  // PRIVATE METHODS
  // =========================================================================

  Future<void> _initializeCamera(int index) async {
    if (index >= _cameras.length) return;
    
    await _cameraController?.dispose();
    
    _cameraController = CameraController(
      _cameras[index],
      ResolutionPreset.high,
      enableAudio: false,
    );
    
    await _cameraController!.initialize();
    _notifyStateChange();
  }

  Future<void> _calculateInitialFit() async {
    if (_overlayState.referenceImage == null) return;
    
    // Get reference image dimensions
    final file = File(_overlayState.referenceImage!.localPath);
    final bytes = await file.readAsBytes();
    final codec = await instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    final image = frame.image;
    
    final refWidth = image.width.toDouble();
    final refHeight = image.height.toDouble();
    image.dispose();
    
    // Get camera preview dimensions
    final previewSize = _cameraController?.value.previewSize;
    if (previewSize == null) return;
    
    final camWidth = previewSize.height.toDouble(); // Rotated
    final camHeight = previewSize.width.toDouble();
    
    // Calculate scale to fit
    final scaleX = camWidth / refWidth;
    final scaleY = camHeight / refHeight;
    final scale = scaleX < scaleY ? scaleX : scaleY;
    
    // Center the image
    final scaledWidth = refWidth * scale;
    final scaledHeight = refHeight * scale;
    final offsetX = (camWidth - scaledWidth) / 2;
    final offsetY = (camHeight - scaledHeight) / 2;
    
    _overlayState.scale = scale;
    _overlayState.position = Offset(offsetX, offsetY);
  }

  void _notifyStateChange() {
    _stateController.add(_overlayState);
  }

  Future<void> _saveOverlayState() async {
    // Implementation would save to preferences
    // For now, just a placeholder
  }

  Future<void> _loadOverlayState() async {
    // Implementation would load from preferences
    // For now, just set defaults
    _overlayState.opacity = 0.5;
    _overlayState.currentGuide = _guides[0];
  }

  // =========================================================================
  // DISPOSE
  // =========================================================================

  Future<void> dispose() async {
    await _cameraController?.dispose();
    await _stateController.close();
    await _captureController.close();
  }
}

// =========================================================================
// DATA MODELS
// =========================================================================

class GhostOverlayState {
  MediaAsset? referenceImage;
  bool isVisible = false;
  double opacity = 0.5;
  Offset position = Offset.zero;
  double scale = 1.0;
  AlignmentGuide currentGuide = AlignmentRuleOfThirds();
  
  GhostOverlayState({
    this.referenceImage,
    this.isVisible = false,
    this.opacity = 0.5,
    this.position = Offset.zero,
    this.scale = 1.0,
    this.currentGuide = const AlignmentRuleOfThirds(),
  });
  
  GhostOverlayState copyWith({
    MediaAsset? referenceImage,
    bool? isVisible,
    double? opacity,
    Offset? position,
    double? scale,
    AlignmentGuide? currentGuide,
  }) {
    return GhostOverlayState(
      referenceImage: referenceImage ?? this.referenceImage,
      isVisible: isVisible ?? this.isVisible,
      opacity: opacity ?? this.opacity,
      position: position ?? this.position,
      scale: scale ?? this.scale,
      currentGuide: currentGuide ?? this.currentGuide,
    );
  }
}

abstract class AlignmentGuide {
  const AlignmentGuide();
  String get name;
  List<Line> get getLines;
}

class AlignmentRuleOfThirds extends AlignmentGuide {
  const AlignmentRuleOfThirds();
  
  @override
  String get name => 'Rule of Thirds';
  
  @override
  List<Line> get getLines => [
    Line(Offset(0.33, 0), Offset(0.33, 1)),   // Vertical left
    Line(Offset(0.67, 0), Offset(0.67, 1)),   // Vertical right
    Line(Offset(0, 0.33), Offset(1, 0.33)),   // Horizontal top
    Line(Offset(0, 0.67), Offset(1, 0.67)),   // Horizontal bottom
  ];
}

class AlignmentGrid extends AlignmentGuide {
  const AlignmentGrid();
  
  @override
  String get name => 'Grid';
  
  @override
  List<Line> get getLines {
    final lines = <Line>[];
    
    // Vertical lines
    for (double i = 0.1; i < 1.0; i += 0.1) {
      lines.add(Line(Offset(i, 0), Offset(i, 1)));
    }
    
    // Horizontal lines
    for (double i = 0.1; i < 1.0; i += 0.1) {
      lines.add(Line(Offset(0, i), Offset(1, i)));
    }
    
    return lines;
  }
}

class AlignmentCrosshair extends AlignmentGuide {
  const AlignmentCrosshair();
  
  @override
  String get name => 'Crosshair';
  
  @override
  List<Line> get getLines => [
    Line(Offset(0.5, 0), Offset(0.5, 1)),   // Vertical center
    Line(Offset(0, 0.5), Offset(1, 0.5)),   // Horizontal center
  ];
}

class Line {
  final Offset start;
  final Offset end;
  
  const Line(this.start, this.end);
}

// =========================================================================
// PROVIDERS
// =========================================================================

final ghostCameraProvider = Provider<GhostCameraService>((ref) {
  return GhostCameraService.instance;
});

final ghostCameraStateProvider = StreamProvider<GhostOverlayState>((ref) {
  final service = ref.watch(ghostCameraProvider);
  return service.overlayStateStream;
});

// =========================================================================
// EXCEPTIONS
// =========================================================================

class GhostCameraException implements Exception {
  final String message;
  GhostCameraException(this.message);
  
  @override
  String toString() => 'GhostCameraException: $message';
}
