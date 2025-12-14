import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../loading/loading_service.dart';

/// Loading overlay widget for global loading states
class LoadingOverlay extends ConsumerWidget {
  final Widget child;
  final bool barrierDismissible;

  const LoadingOverlay({
    super.key,
    required this.child,
    this.barrierDismissible = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loadingOperations = ref.watch(loadingStreamProvider);
    
    return Stack(
      children: [
        child,
        if (loadingOperations.value?.isNotEmpty == true)
          _LoadingBarrier(
            operations: loadingOperations.value!,
            barrierDismissible: barrierDismissible,
          ),
      ],
    );
  }
}

/// Loading barrier with operation details
class _LoadingBarrier extends StatelessWidget {
  final Map<String, LoadingOperation> operations;
  final bool barrierDismissible;

  const _LoadingBarrier({
    required this.operations,
    required this.barrierDismissible,
  });

  @override
  Widget build(BuildContext context) {
    return AbsorbPointer(
      absorbing: !barrierDismissible,
      child: Container(
        color: Colors.black54,
        child: Center(
          child: Card(
            margin: const EdgeInsets.all(16),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  ...operations.values.map((op) => _LoadingItem(operation: op)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Individual loading item widget
class _LoadingItem extends StatelessWidget {
  final LoadingOperation operation;

  const _LoadingItem({required this.operation});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(
                _getColorForType(operation.type),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              operation.message,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          if (operation.canCancel) ...[
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.close, size: 16),
              onPressed: () => LoadingService().cancelLoading(operation.id),
              tooltip: 'Cancel',
            ),
          ],
        ],
      ),
    );
  }

  Color _getColorForType(LoadingType type) {
    switch (type) {
      case LoadingType.save:
        return Colors.green;
      case LoadingType.delete:
        return Colors.red;
      case LoadingType.export:
      case LoadingType.import:
        return Colors.blue;
      case LoadingType.sync:
        return Colors.purple;
      case LoadingType.processing:
        return Colors.orange;
      case LoadingType.custom:
      default:
        return Colors.grey;
    }
  }
}

/// Loading indicator widget for inline use
class LoadingIndicator extends ConsumerWidget {
  final String? message;
  final LoadingType? type;
  final double size;
  final bool showBackground;

  const LoadingIndicator({
    super.key,
    this.message,
    this.type,
    this.size = 24,
    this.showBackground = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLoading = ref.watch(isLoadingProvider);
    
    if (!isLoading) return const SizedBox.shrink();
    
    final content = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: size,
          height: size,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(
              type != null ? _getColorForType(type!) : Theme.of(context).primaryColor,
            ),
          ),
        ),
        if (message != null) ...[
          const SizedBox(height: 8),
          Text(
            message!,
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );

    if (showBackground) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: content,
      );
    }

    return content;
  }

  Color _getColorForType(LoadingType type) {
    switch (type) {
      case LoadingType.save:
        return Colors.green;
      case LoadingType.delete:
        return Colors.red;
      case LoadingType.export:
      case LoadingType.import:
        return Colors.blue;
      case LoadingType.sync:
        return Colors.purple;
      case LoadingType.processing:
        return Colors.orange;
      case LoadingType.custom:
      default:
        return Colors.grey;
    }
  }
}

/// Async value widget that handles loading, error, and data states
class AsyncValueWidget<T> extends StatelessWidget {
  final AsyncValue<T> value;
  final Widget Function(T data) data;
  final Widget Function(Object error, StackTrace? stackTrace)? error;
  final Widget Function()? loading;

  const AsyncValueWidget({
    super.key,
    required this.value,
    required this.data,
    this.error,
    this.loading,
  });

  @override
  Widget build(BuildContext context) {
    return value.when(
      data: data,
      error: error ?? (error, stackTrace) => _ErrorWidget(error: error),
      loading: loading ?? () => const _LoadingWidget(),
    );
  }
}

/// Default loading widget
class _LoadingWidget extends StatelessWidget {
  const _LoadingWidget();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: CircularProgressIndicator(),
      ),
    );
  }
}

/// Default error widget
class _ErrorWidget extends StatelessWidget {
  final Object error;

  const _ErrorWidget({required this.error});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Something went wrong',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              error.toString(),
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// Sliver version of AsyncValueWidget
class AsyncValueSliver<T> extends StatelessWidget {
  final AsyncValue<T> value;
  final Widget Function(T data) data;
  final Widget Function(Object error, StackTrace? stackTrace)? error;
  final Widget Function()? loading;

  const AsyncValueSliver({
    super.key,
    required this.value,
    required this.data,
    this.error,
    this.loading,
  });

  @override
  Widget build(BuildContext context) {
    return value.when(
      data: data,
      error: error ?? (error, stackTrace) => SliverToBoxAdapter(child: _ErrorWidget(error: error)),
      loading: loading ?? () => const SliverToBoxAdapter(child: _LoadingWidget()),
    );
  }
}
