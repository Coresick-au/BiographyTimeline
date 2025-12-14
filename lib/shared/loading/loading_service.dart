import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Loading operation types
enum LoadingType {
  save,
  delete,
  export,
  import,
  sync,
  processing,
  custom,
}

/// Loading operation model
class LoadingOperation {
  final String id;
  final String message;
  final LoadingType type;
  final DateTime startTime;
  final bool canCancel;
  final VoidCallback? onCancel;

  LoadingOperation({
    required this.id,
    required this.message,
    required this.type,
    this.canCancel = false,
    this.onCancel,
  }) : startTime = DateTime.now();

  Duration get duration => DateTime.now().difference(startTime);
}

/// Global loading service for managing loading states
class LoadingService {
  static final LoadingService _instance = LoadingService._internal();
  factory LoadingService() => _instance;
  LoadingService._internal();

  final Map<String, LoadingOperation> _operations = {};
  final StreamController<Map<String, LoadingOperation>> _controller = 
      StreamController<Map<String, LoadingOperation>>.broadcast();

  /// Stream of all active loading operations
  Stream<Map<String, LoadingOperation>> get operationsStream => _controller.stream;

  /// All active loading operations
  Map<String, LoadingOperation> get operations => Map.unmodifiable(_operations);

  /// Whether any loading operation is active
  bool get isLoading => _operations.isNotEmpty;

  /// Start a loading operation
  String startLoading({
    required String message,
    required LoadingType type,
    bool canCancel = false,
    VoidCallback? onCancel,
  }) {
    final id = _generateId();
    final operation = LoadingOperation(
      id: id,
      message: message,
      type: type,
      canCancel: canCancel,
      onCancel: onCancel,
    );

    _operations[id] = operation;
    _controller.add(Map.from(_operations));

    if (kDebugMode) {
      debugPrint('Loading started: $message');
    }

    return id;
  }

  /// Update a loading operation message
  void updateLoading(String id, String message) {
    final operation = _operations[id];
    if (operation != null) {
      _operations[id] = LoadingOperation(
        id: operation.id,
        message: message,
        type: operation.type,
        canCancel: operation.canCancel,
        onCancel: operation.onCancel,
      );
      _controller.add(Map.from(_operations));
    }
  }

  /// Stop a loading operation
  void stopLoading(String id) {
    final operation = _operations.remove(id);
    if (operation != null) {
      _controller.add(Map.from(_operations));

      if (kDebugMode) {
        debugPrint('Loading stopped: ${operation.message} (took ${operation.duration.inMilliseconds}ms)');
      }
    }
  }

  /// Cancel a loading operation
  void cancelLoading(String id) {
    final operation = _operations[id];
    if (operation?.canCancel == true) {
      operation?.onCancel?.call();
      stopLoading(id);
    }
  }

  /// Stop all loading operations
  void stopAllLoading() {
    final ids = _operations.keys.toList();
    for (final id in ids) {
      stopLoading(id);
    }
  }

  /// Get operations by type
  List<LoadingOperation> getOperationsByType(LoadingType type) {
    return _operations.values.where((op) => op.type == type).toList();
  }

  /// Check if specific type is loading
  bool isTypeLoading(LoadingType type) {
    return _operations.values.any((op) => op.type == type);
  }

  String _generateId() {
    return 'loading_${DateTime.now().millisecondsSinceEpoch}_${DateTime.now().microsecond}';
  }

  /// Dispose resources
  void dispose() {
    _controller.close();
  }
}

/// Provider for loading service
final loadingServiceProvider = Provider<LoadingService>((ref) {
  return LoadingService();
});

/// Provider for loading stream
final loadingStreamProvider = StreamProvider<Map<String, LoadingOperation>>((ref) {
  final loadingService = ref.watch(loadingServiceProvider);
  return loadingService.operationsStream;
});

/// Provider for loading state
final isLoadingProvider = Provider<bool>((ref) {
  final loadingService = ref.watch(loadingServiceProvider);
  return loadingService.isLoading;
});

/// Helper extension for common loading operations
extension LoadingServiceExtensions on LoadingService {
  /// Start a save operation
  String startSave({String? item, VoidCallback? onCancel}) {
    return startLoading(
      message: item != null ? 'Saving $item...' : 'Saving...',
      type: LoadingType.save,
      canCancel: true,
      onCancel: onCancel,
    );
  }

  /// Start a delete operation
  String startDelete({String? item, VoidCallback? onCancel}) {
    return startLoading(
      message: item != null ? 'Deleting $item...' : 'Deleting...',
      type: LoadingType.delete,
      canCancel: true,
      onCancel: onCancel,
    );
  }

  /// Start an export operation
  String startExport({String? format, VoidCallback? onCancel}) {
    return startLoading(
      message: format != null ? 'Exporting as $format...' : 'Exporting...',
      type: LoadingType.export,
      canCancel: true,
      onCancel: onCancel,
    );
  }

  /// Start an import operation
  String startImport({String? source, VoidCallback? onCancel}) {
    return startLoading(
      message: source != null ? 'Importing from $source...' : 'Importing...',
      type: LoadingType.import,
      canCancel: true,
      onCancel: onCancel,
    );
  }

  /// Start a sync operation
  String startSync({VoidCallback? onCancel}) {
    return startLoading(
      message: 'Syncing data...',
      type: LoadingType.sync,
      canCancel: true,
      onCancel: onCancel,
    );
  }

  /// Start a processing operation
  String startProcessing({String? item, VoidCallback? onCancel}) {
    return startLoading(
      message: item != null ? 'Processing $item...' : 'Processing...',
      type: LoadingType.processing,
      canCancel: false,
      onCancel: onCancel,
    );
  }
}
