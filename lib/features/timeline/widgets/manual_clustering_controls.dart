import 'package:flutter/material.dart';
import '../../../shared/models/timeline_event.dart';
import '../../../shared/models/media_asset.dart';
import '../services/event_management_service.dart';

/// Widget that provides manual clustering controls for timeline events
class ManualClusteringControls extends StatefulWidget {
  final List<TimelineEvent> selectedEvents;
  final Function(List<TimelineEvent> updatedEvents) onEventsUpdated;
  final VoidCallback onCancel;

  const ManualClusteringControls({
    Key? key,
    required this.selectedEvents,
    required this.onEventsUpdated,
    required this.onCancel,
  }) : super(key: key);

  @override
  State<ManualClusteringControls> createState() => _ManualClusteringControlsState();
}

class _ManualClusteringControlsState extends State<ManualClusteringControls> {
  final EventManagementService _eventManagementService = EventManagementService();
  bool _isProcessing = false;
  String? _errorMessage;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeader(context),
          const SizedBox(height: 16),
          if (_errorMessage != null) ...[
            _buildErrorMessage(context),
            const SizedBox(height: 16),
          ],
          _buildEventSummary(context),
          const SizedBox(height: 16),
          _buildActionButtons(context),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        Icon(
          Icons.tune,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(width: 8),
        Text(
          'Manual Clustering',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const Spacer(),
        IconButton(
          icon: const Icon(Icons.close),
          onPressed: widget.onCancel,
        ),
      ],
    );
  }

  Widget _buildErrorMessage(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            Icons.error_outline,
            color: Theme.of(context).colorScheme.onErrorContainer,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _errorMessage!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onErrorContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventSummary(BuildContext context) {
    final totalAssets = widget.selectedEvents.fold<int>(
      0,
      (sum, event) => sum + event.assets.length,
    );

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Selected Events',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${widget.selectedEvents.length} events • $totalAssets photos',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 60,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: widget.selectedEvents.length,
              itemBuilder: (context, index) {
                final event = widget.selectedEvents[index];
                return _buildEventPreview(context, event);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventPreview(BuildContext context, TimelineEvent event) {
    final keyAsset = event.assets.firstWhere(
      (asset) => asset.isKeyAsset,
      orElse: () => event.assets.first,
    );

    return Container(
      width: 60,
      margin: const EdgeInsets.only(right: 8),
      child: Column(
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: Container(
                color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    _buildAssetPreview(keyAsset),
                    if (event.assets.length > 1)
                      Positioned(
                        top: 2,
                        right: 2,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.black87,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${event.assets.length}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _formatEventTime(event.timestamp),
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildAssetPreview(MediaAsset asset) {
    switch (asset.type) {
      case AssetType.photo:
        return Image.asset(
          asset.localPath,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return const Icon(Icons.broken_image, size: 24);
          },
        );
      case AssetType.video:
        return const Icon(Icons.play_circle_outline, size: 24);
      case AssetType.audio:
        return const Icon(Icons.audiotrack, size: 24);
      case AssetType.document:
        return const Icon(Icons.description, size: 24);
    }
  }

  Widget _buildActionButtons(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.selectedEvents.length > 1) ...[
          ElevatedButton.icon(
            onPressed: _isProcessing ? null : _mergeEvents,
            icon: const Icon(Icons.merge),
            label: const Text('Merge Events'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
            ),
          ),
          const SizedBox(height: 8),
        ],
        if (widget.selectedEvents.length == 1 && widget.selectedEvents.first.assets.length > 1) ...[
          ElevatedButton.icon(
            onPressed: _isProcessing ? null : () => _showSplitDialog(context),
            icon: const Icon(Icons.call_split),
            label: const Text('Split Event'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.secondary,
              foregroundColor: Theme.of(context).colorScheme.onSecondary,
            ),
          ),
          const SizedBox(height: 8),
        ],
        if (widget.selectedEvents.length == 1) ...[
          OutlinedButton.icon(
            onPressed: _isProcessing ? null : () => _showKeyAssetDialog(context),
            icon: const Icon(Icons.star_outline),
            label: const Text('Change Key Photo'),
          ),
          const SizedBox(height: 8),
        ],
        OutlinedButton(
          onPressed: widget.onCancel,
          child: const Text('Cancel'),
        ),
        if (_isProcessing) ...[
          const SizedBox(height: 16),
          const Center(
            child: CircularProgressIndicator(),
          ),
        ],
      ],
    );
  }

  Future<void> _mergeEvents() async {
    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });

    try {
      final result = await _eventManagementService.mergeEvents(widget.selectedEvents);
      
      if (result.success && result.updatedEvents != null) {
        widget.onEventsUpdated(result.updatedEvents!);
      } else {
        setState(() {
          _errorMessage = result.errorMessage ?? 'Failed to merge events';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'An error occurred while merging events: $e';
      });
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  void _showSplitDialog(BuildContext context) {
    final event = widget.selectedEvents.first;
    
    showDialog(
      context: context,
      builder: (context) => SplitEventDialog(
        event: event,
        onSplit: (assetGroups) async {
          Navigator.of(context).pop();
          await _splitEvent(assetGroups);
        },
      ),
    );
  }

  Future<void> _splitEvent(List<List<MediaAsset>> assetGroups) async {
    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });

    try {
      final event = widget.selectedEvents.first;
      final result = await _eventManagementService.splitEvent(event, assetGroups);
      
      if (result.success && result.updatedEvents != null) {
        widget.onEventsUpdated(result.updatedEvents!);
      } else {
        setState(() {
          _errorMessage = result.errorMessage ?? 'Failed to split event';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'An error occurred while splitting event: $e';
      });
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  void _showKeyAssetDialog(BuildContext context) {
    final event = widget.selectedEvents.first;
    
    showDialog(
      context: context,
      builder: (context) => KeyAssetSelectionDialog(
        event: event,
        onKeyAssetSelected: (newKeyAsset) async {
          Navigator.of(context).pop();
          await _updateKeyAsset(newKeyAsset);
        },
      ),
    );
  }

  Future<void> _updateKeyAsset(MediaAsset newKeyAsset) async {
    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });

    try {
      final event = widget.selectedEvents.first;
      final result = await _eventManagementService.updateKeyAsset(event, newKeyAsset);
      
      if (result.success && result.updatedEvents != null) {
        widget.onEventsUpdated(result.updatedEvents!);
      } else {
        setState(() {
          _errorMessage = result.errorMessage ?? 'Failed to update key photo';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'An error occurred while updating key photo: $e';
      });
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  String _formatEventTime(DateTime timestamp) {
    return '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
  }
}

/// Dialog for splitting an event into multiple events
class SplitEventDialog extends StatefulWidget {
  final TimelineEvent event;
  final Function(List<List<MediaAsset>>) onSplit;

  const SplitEventDialog({
    Key? key,
    required this.event,
    required this.onSplit,
  }) : super(key: key);

  @override
  State<SplitEventDialog> createState() => _SplitEventDialogState();
}

class _SplitEventDialogState extends State<SplitEventDialog> {
  late List<List<MediaAsset>> _assetGroups;
  late List<bool> _selectedAssets;

  @override
  void initState() {
    super.initState();
    _selectedAssets = List.filled(widget.event.assets.length, false);
    _assetGroups = [List.from(widget.event.assets)]; // Start with all assets in one group
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Split Event'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Select photos to create a new event. Remaining photos will stay in the original event.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            Flexible(
              child: GridView.builder(
                shrinkWrap: true,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  childAspectRatio: 1,
                ),
                itemCount: widget.event.assets.length,
                itemBuilder: (context, index) {
                  final asset = widget.event.assets[index];
                  final isSelected = _selectedAssets[index];
                  
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedAssets[index] = !_selectedAssets[index];
                      });
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: isSelected 
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.outline,
                          width: isSelected ? 3 : 1,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(7),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            _buildAssetPreview(asset),
                            if (isSelected)
                              Container(
                                color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                                child: Center(
                                  child: Icon(
                                    Icons.check_circle,
                                    color: Theme.of(context).colorScheme.primary,
                                    size: 24,
                                  ),
                                ),
                              ),
                            if (asset.isKeyAsset)
                              Positioned(
                                top: 4,
                                right: 4,
                                child: Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: BoxDecoration(
                                    color: Colors.amber,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    Icons.star,
                                    size: 12,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _canSplit() ? _performSplit : null,
          child: const Text('Split'),
        ),
      ],
    );
  }

  Widget _buildAssetPreview(MediaAsset asset) {
    switch (asset.type) {
      case AssetType.photo:
        return Image.asset(
          asset.localPath,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              color: Colors.grey[300],
              child: const Icon(Icons.broken_image, size: 24),
            );
          },
        );
      case AssetType.video:
        return Container(
          color: Colors.black87,
          child: const Icon(Icons.play_circle_outline, size: 24, color: Colors.white),
        );
      case AssetType.audio:
        return Container(
          color: Colors.blue[100],
          child: const Icon(Icons.audiotrack, size: 24, color: Colors.blue),
        );
      case AssetType.document:
        return Container(
          color: Colors.grey[100],
          child: const Icon(Icons.description, size: 24, color: Colors.grey),
        );
    }
  }

  bool _canSplit() {
    final selectedCount = _selectedAssets.where((selected) => selected).length;
    final unselectedCount = _selectedAssets.length - selectedCount;
    
    // Both groups must have at least one asset
    return selectedCount > 0 && unselectedCount > 0;
  }

  void _performSplit() {
    final selectedAssets = <MediaAsset>[];
    final unselectedAssets = <MediaAsset>[];
    
    for (int i = 0; i < widget.event.assets.length; i++) {
      if (_selectedAssets[i]) {
        selectedAssets.add(widget.event.assets[i]);
      } else {
        unselectedAssets.add(widget.event.assets[i]);
      }
    }
    
    widget.onSplit([unselectedAssets, selectedAssets]);
  }
}

/// Dialog for selecting a new key asset
class KeyAssetSelectionDialog extends StatelessWidget {
  final TimelineEvent event;
  final Function(MediaAsset) onKeyAssetSelected;

  const KeyAssetSelectionDialog({
    Key? key,
    required this.event,
    required this.onKeyAssetSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Select Key Photo'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Choose which photo should represent this event.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            Flexible(
              child: GridView.builder(
                shrinkWrap: true,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  childAspectRatio: 1,
                ),
                itemCount: event.assets.length,
                itemBuilder: (context, index) {
                  final asset = event.assets[index];
                  
                  return GestureDetector(
                    onTap: () => onKeyAssetSelected(asset),
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: asset.isKeyAsset 
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.outline,
                          width: asset.isKeyAsset ? 3 : 1,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(7),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            _buildAssetPreview(asset),
                            if (asset.isKeyAsset)
                              Container(
                                color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                                child: Center(
                                  child: Icon(
                                    Icons.star,
                                    color: Theme.of(context).colorScheme.primary,
                                    size: 24,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
      ],
    );
  }

  Widget _buildAssetPreview(MediaAsset asset) {
    switch (asset.type) {
      case AssetType.photo:
        return Image.asset(
          asset.localPath,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              color: Colors.grey[300],
              child: const Icon(Icons.broken_image, size: 24),
            );
          },
        );
      case AssetType.video:
        return Container(
          color: Colors.black87,
          child: const Icon(Icons.play_circle_outline, size: 24, color: Colors.white),
        );
      case AssetType.audio:
        return Container(
          color: Colors.blue[100],
          child: const Icon(Icons.audiotrack, size: 24, color: Colors.blue),
        );
      case AssetType.document:
        return Container(
          color: Colors.grey[100],
          child: const Icon(Icons.description, size: 24, color: Colors.grey),
        );
    }
  }
}
