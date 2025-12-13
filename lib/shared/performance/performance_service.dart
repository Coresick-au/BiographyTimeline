import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Performance monitoring and optimization service
/// Tracks frame rates, memory usage, and provides optimization recommendations
class PerformanceService {
  static PerformanceService? _instance;
  static PerformanceService get instance => _instance ??= PerformanceService._();
  
  PerformanceService._();

  static const String _performanceLogKey = 'performance_log';
  static const int _maxPerformanceLogs = 100;
  static const int _memoryWarningThresholdMB = 200;
  static const int _memoryCriticalThresholdMB = 400;
  static const double _frameRateWarningThreshold = 45.0;
  static const double _frameRateCriticalThreshold = 30.0;

  SharedPreferences? _prefs;
  final List<PerformanceMetric> _metrics = [];
  final StreamController<PerformanceMetric> _metricController = 
      StreamController<PerformanceMetric>.broadcast();
  final StreamController<PerformanceAlert> _alertController = 
      StreamController<PerformanceAlert>.broadcast();
  
  Timer? _monitoringTimer;
  bool _isMonitoring = false;
  
  // Performance tracking
  int _frameCount = 0;
  double _lastFrameTime = 0.0;
  double _averageFrameTime = 16.67; // 60 FPS
  List<double> _frameTimes = [];
  int _lastMemoryUsage = 0;
  
  // Image loading optimization
  final Map<String, ImageStreamCompleter> _imageStreams = {};
  final Map<String, ui.Image> _imageCache = {};
  final int _maxImageCacheSize = 50;

  // =========================================================================
  // PUBLIC API
  // =========================================================================

  /// Initialize performance monitoring
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    await _loadMetrics();
    
    // Set up frame timing callback
    WidgetsBinding.instance.addTimingsCallback(_onFrameTimed);
    
    // Start monitoring
    startMonitoring();
  }

  /// Start performance monitoring
  void startMonitoring() {
    if (_isMonitoring) return;
    
    _isMonitoring = true;
    _monitoringTimer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => _collectMetrics(),
    );
  }

  /// Stop performance monitoring
  void stopMonitoring() {
    _isMonitoring = false;
    _monitoringTimer?.cancel();
    _monitoringTimer = null;
  }

  /// Record a custom performance metric
  void recordMetric(
    String name,
    double value, {
    String? unit,
    Map<String, dynamic>? metadata,
  }) {
    final metric = PerformanceMetric(
      id: _generateId(),
      timestamp: DateTime.now(),
      name: name,
      value: value,
      unit: unit,
      metadata: metadata,
    );
    
    _metrics.insert(0, metric);
    if (_metrics.length > _maxPerformanceLogs) {
      _metrics.removeLast();
    }
    
    _metricController.add(metric);
    _saveMetrics();
  }

  /// Monitor timeline scrolling performance
  void monitorTimelineScroll(ScrollNotification notification) {
    if (notification is ScrollStartNotification) {
      recordMetric('timeline_scroll_start', 0.0);
    } else if (notification is ScrollUpdateNotification) {
      recordMetric(
        'timeline_scroll_velocity',
        notification.metrics.pixelsPerSecond,
        unit: 'px/s',
      );
    } else if (notification is ScrollEndNotification) {
      recordMetric('timeline_scroll_end', 0.0);
    }
  }

  /// Optimize image loading for timeline items
  Future<ui.Image?> loadOptimizedImage(
    String imageUrl,
    Size targetSize, {
    bool useCache = true,
  }) async {
    // Check cache first
    if (useCache && _imageCache.containsKey(imageUrl)) {
      return _imageCache[imageUrl];
    }
    
    try {
      // Load with resize optimization
      final imageStream = _imageStreams.putIfAbsent(
        imageUrl,
        () => _loadImageWithResize(imageUrl, targetSize),
      );
      
      final completer = Completer<ui.Image?>();
      imageStream.addListener(
        ImageStreamListener(
          (info, _) => completer.complete(info.image),
          onError: (error, _) => completer.complete(null),
        ),
      );
      
      final image = await completer.future;
      
      // Cache the result
      if (image != null && useCache) {
        _cacheImage(imageUrl, image);
      }
      
      return image;
    } catch (e) {
      debugPrint('Failed to load optimized image: $e');
      return null;
    }
  }

  /// Clear image cache to free memory
  void clearImageCache() {
    _imageCache.clear();
    _imageStreams.clear();
    
    // Force garbage collection
    if (!kReleaseMode) {
      SystemChannels.platform.invokeMethod('System.gc');
    }
  }

  /// Get performance recommendations
  List<PerformanceRecommendation> getRecommendations() {
    final recommendations = <PerformanceRecommendation>[];
    
    // Check memory usage
    if (_lastMemoryUsage > _memoryCriticalThresholdMB * 1024 * 1024) {
      recommendations.add(PerformanceRecommendation(
        id: 'high_memory',
        title: 'High Memory Usage',
        description: 'Memory usage is critically high. Consider clearing image cache.',
        priority: RecommendationPriority.critical,
        action: 'Clear Cache',
        onExecute: clearImageCache,
      ));
    } else if (_lastMemoryUsage > _memoryWarningThresholdMB * 1024 * 1024) {
      recommendations.add(PerformanceRecommendation(
        id: 'moderate_memory',
        title: 'Moderate Memory Usage',
        description: 'Memory usage is elevated. Monitor for further increases.',
        priority: RecommendationPriority.warning,
        action: 'Monitor',
      ));
    }
    
    // Check frame rate
    final currentFPS = 1000.0 / _averageFrameTime;
    if (currentFPS < _frameRateCriticalThreshold) {
      recommendations.add(PerformanceRecommendation(
        id: 'low_fps',
        title: 'Low Frame Rate',
        description: 'Frame rate is critically low. UI may appear sluggish.',
        priority: RecommendationPriority.critical,
        action: 'Optimize',
      ));
    } else if (currentFPS < _frameRateWarningThreshold) {
      recommendations.add(PerformanceRecommendation(
        id: 'moderate_fps',
        title: 'Reduced Frame Rate',
        description: 'Frame rate is below optimal. Consider reducing animations.',
        priority: RecommendationPriority.warning,
        action: 'Reduce Effects',
      ));
    }
    
    return recommendations;
  }

  /// Export performance metrics for analysis
  Future<String> exportMetrics() async {
    final buffer = StringBuffer();
    buffer.writeln('=== Timeline Biography Performance Report ===');
    buffer.writeln('Generated: ${DateTime.now().toIso8601String()}\n');
    
    // Summary statistics
    final avgFPS = 1000.0 / _averageFrameTime;
    final avgMemoryMB = _metrics
        .where((m) => m.name == 'memory_usage')
        .map((m) => m.value)
        .fold<double>(0.0, (a, b) => a + b) /
        _metrics.where((m) => m.name == 'memory_usage').length;
    
    buffer.writeln('--- Summary ---');
    buffer.writeln('Average FPS: ${avgFPS.toStringAsFixed(2)}');
    buffer.writeln('Average Memory: ${(avgMemoryMB / 1024 / 1024).toStringAsFixed(2)} MB');
    buffer.writeln('Total Metrics: ${_metrics.length}\n');
    
    // Detailed metrics
    buffer.writeln('--- Detailed Metrics ---');
    for (final metric in _metrics.take(50)) {
      buffer.writeln('${metric.timestamp.toIso8601String()} - '
          '${metric.name}: ${metric.value.toStringAsFixed(2)} ${metric.unit ?? ''}');
    }
    
    return buffer.toString();
  }

  // =========================================================================
  // GETTERS
  // =========================================================================

  List<PerformanceMetric> get metrics => List.unmodifiable(_metrics);
  Stream<PerformanceMetric> get metricStream => _metricController.stream;
  Stream<PerformanceAlert> get alertStream => _alertController.stream;
  bool get isMonitoring => _isMonitoring;
  double get currentFPS => 1000.0 / _averageFrameTime;
  int get memoryUsageMB => (_lastMemoryUsage / 1024 / 1024).round();

  // =========================================================================
  // PRIVATE METHODS
  // =========================================================================

  void _onFrameTimed(List<FrameTiming> timings) {
    for (final timing in timings) {
      _frameCount++;
      
      // Calculate frame duration
      final frameDuration = timing.duration.inMicroseconds.toDouble() / 1000.0;
      _frameTimes.add(frameDuration);
      
      // Keep only last 60 frames (1 second at 60fps)
      if (_frameTimes.length > 60) {
        _frameTimes.removeAt(0);
      }
      
      // Update average
      _averageFrameTime = _frameTimes.fold<double>(0.0, (a, b) => a + b) / _frameTimes.length;
    }
  }

  Future<void> _collectMetrics() async {
    if (!_isMonitoring) return;
    
    // Collect memory usage
    try {
      final memoryUsage = await _getCurrentMemoryUsage();
      _lastMemoryUsage = memoryUsage;
      
      recordMetric(
        'memory_usage',
        memoryUsage.toDouble(),
        unit: 'bytes',
      );
      
      // Check for memory warnings
      if (memoryUsage > _memoryCriticalThresholdMB * 1024 * 1024) {
        _alertController.add(
          PerformanceAlert(
            type: AlertType.criticalMemory,
            message: 'Critical memory usage: ${memoryUsage ~/ 1024 ~/ 1024} MB',
          ),
        );
      }
    } catch (e) {
      debugPrint('Failed to collect memory usage: $e');
    }
    
    // Collect frame rate
    final fps = 1000.0 / _averageFrameTime;
    recordMetric(
      'frame_rate',
      fps,
      unit: 'fps',
    );
    
    // Check for frame rate warnings
    if (fps < _frameRateCriticalThreshold) {
      _alertController.add(
        PerformanceAlert(
          type: AlertType.lowFrameRate,
          message: 'Low frame rate: ${fps.toStringAsFixed(1)} FPS',
        ),
      );
    }
  }

  Future<int> _getCurrentMemoryUsage() async {
    if (Platform.isAndroid || Platform.isIOS) {
      // Use platform-specific method
      try {
        final info = await ProcessInfo.currentRss;
        return info;
      } catch (e) {
        return 0;
      }
    }
    return 0;
  }

  ImageStreamCompleter _loadImageWithResize(String imageUrl, Size targetSize) {
    // Implementation would decode image at target size
    // For now, return a placeholder
    return const ImageStreamCompleter();
  }

  void _cacheImage(String url, ui.Image image) {
    // Remove oldest if cache is full
    if (_imageCache.length >= _maxImageCacheSize) {
      final firstKey = _imageCache.keys.first;
      _imageCache.remove(firstKey);
    }
    
    _imageCache[url] = image;
  }

  Future<void> _loadMetrics() async {
    final metricsJson = _prefs?.getStringList(_performanceLogKey) ?? [];
    _metrics.clear();
    
    for (final metricJson in metricsJson) {
      try {
        // Parse and add to metrics
        // Implementation would deserialize JSON
      } catch (e) {
        debugPrint('Failed to parse performance metric: $e');
      }
    }
  }

  Future<void> _saveMetrics() async {
    final metricsJson = _metrics.map((m) => m.toJson()).toList();
    await _prefs?.setStringList(_performanceLogKey, metricsJson);
  }

  String _generateId() {
    return DateTime.now().millisecondsSinceEpoch.toString();
  }

  // =========================================================================
  // DISPOSE
  // =========================================================================

  Future<void> dispose() async {
    stopMonitoring();
    await _metricController.close();
    await _alertController.close();
    clearImageCache();
  }
}

// =========================================================================
// DATA MODELS
// =========================================================================

class PerformanceMetric {
  final String id;
  final DateTime timestamp;
  final String name;
  final double value;
  final String? unit;
  final Map<String, dynamic>? metadata;

  PerformanceMetric({
    required this.id,
    required this.timestamp,
    required this.name,
    required this.value,
    this.unit,
    this.metadata,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'timestamp': timestamp.toIso8601String(),
      'name': name,
      'value': value,
      'unit': unit,
      'metadata': metadata,
    };
  }
}

class PerformanceAlert {
  final AlertType type;
  final String message;
  final DateTime timestamp;

  PerformanceAlert({
    required this.type,
    required this.message,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}

enum AlertType {
  criticalMemory,
  lowFrameRate,
  highCpu,
  networkSlow,
}

class PerformanceRecommendation {
  final String id;
  final String title;
  final String description;
  final RecommendationPriority priority;
  final String action;
  final VoidCallback? onExecute;

  PerformanceRecommendation({
    required this.id,
    required this.title,
    required this.description,
    required this.priority,
    required this.action,
    this.onExecute,
  });
}

enum RecommendationPriority {
  info,
  warning,
  critical,
}

// =========================================================================
// PROVIDERS
// =========================================================================

final performanceServiceProvider = Provider<PerformanceService>((ref) {
  return PerformanceService.instance;
});

final performanceMetricsProvider = StreamProvider<List<PerformanceMetric>>((ref) {
  final service = ref.watch(performanceServiceProvider);
  return service.metricStream.map((metric) {
    return service.metrics.take(50).toList();
  });
});

final performanceAlertsProvider = StreamProvider<PerformanceAlert>((ref) {
  final service = ref.watch(performanceServiceProvider);
  return service.alertStream;
});
