import 'package:flutter/material.dart';
import '../../../shared/models/timeline_event.dart';
import '../../../shared/models/context.dart';
import 'timeline_event_card.dart';
import 'quick_entry_button.dart';
import 'quick_entry_dialog.dart';

/// Main timeline view that displays both photo and text events seamlessly
class TimelineView extends StatefulWidget {
  final List<TimelineEvent> events;
  final ContextType contextType;
  final String contextId;
  final String ownerId;
  final Function(TimelineEvent) onEventCreated;
  final Function(TimelineEvent)? onEventTap;

  const TimelineView({
    super.key,
    required this.events,
    required this.contextType,
    required this.contextId,
    required this.ownerId,
    required this.onEventCreated,
    this.onEventTap,
  });

  @override
  State<TimelineView> createState() => _TimelineViewState();
}

class _TimelineViewState extends State<TimelineView> {
  final ScrollController _scrollController = ScrollController();
  String _selectedFilter = 'all';

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filteredEvents = _getFilteredEvents();
    
    return Column(
      children: [
        _buildFilterBar(context),
        Expanded(
          child: _buildTimelineList(context, filteredEvents),
        ),
      ],
    );
  }

  Widget _buildFilterBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Text(
            'Filter:',
            style: Theme.of(context).textTheme.labelLarge,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip('all', 'All Events', Icons.timeline),
                  const SizedBox(width: 8),
                  _buildFilterChip('text', 'Text Only', Icons.edit_note),
                  const SizedBox(width: 8),
                  _buildFilterChip('photo', 'Photos Only', Icons.photo),
                  const SizedBox(width: 8),
                  _buildFilterChip('mixed', 'Mixed', Icons.collections),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String filter, String label, IconData icon) {
    final isSelected = _selectedFilter == filter;
    return FilterChip(
      selected: isSelected,
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: isSelected 
                ? Theme.of(context).colorScheme.onSecondaryContainer
                : Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 4),
          Text(label),
        ],
      ),
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _selectedFilter = filter;
          });
        }
      },
      backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
      selectedColor: Theme.of(context).colorScheme.secondaryContainer,
    );
  }

  Widget _buildTimelineList(BuildContext context, List<TimelineEvent> events) {
    if (events.isEmpty) {
      return _buildEmptyState(context);
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: events.length,
      itemBuilder: (context, index) {
        final event = events[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: TimelineEventCard(
            event: event,
            onTap: () => widget.onEventTap?.call(event),
            showPhotoCount: true,
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    String message;
    IconData icon;
    
    switch (_selectedFilter) {
      case 'text':
        message = 'No text entries yet.\nTap the Quick Entry button to create your first story!';
        icon = Icons.edit_note;
        break;
      case 'photo':
        message = 'No photo events yet.\nImport photos to see them here.';
        icon = Icons.photo;
        break;
      case 'mixed':
        message = 'No mixed events yet.\nEvents with both photos and text will appear here.';
        icon = Icons.collections;
        break;
      default:
        message = 'No timeline events yet.\nStart by creating a quick entry or importing photos!';
        icon = Icons.timeline;
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceVariant,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 48,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            if (_selectedFilter == 'text' || _selectedFilter == 'all') ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => _showQuickEntry(context),
                icon: const Icon(Icons.edit_note),
                label: const Text('Create Quick Entry'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  List<TimelineEvent> _getFilteredEvents() {
    switch (_selectedFilter) {
      case 'text':
        return widget.events.where((event) => 
          event.eventType == 'text' && event.assets.isEmpty
        ).toList();
      case 'photo':
        return widget.events.where((event) => 
          event.assets.isNotEmpty && event.eventType != 'text'
        ).toList();
      case 'mixed':
        return widget.events.where((event) => 
          event.assets.isNotEmpty && event.description != null && event.description!.isNotEmpty
        ).toList();
      default:
        return List.from(widget.events)
          ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    }
  }

  void _showQuickEntry(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => QuickEntryDialog(
        contextType: widget.contextType,
        contextId: widget.contextId,
        ownerId: widget.ownerId,
        onEventCreated: widget.onEventCreated,
      ),
    );
  }
}

/// Statistics widget showing event type distribution
class TimelineStats extends StatelessWidget {
  final List<TimelineEvent> events;

  const TimelineStats({
    super.key,
    required this.events,
  });

  @override
  Widget build(BuildContext context) {
    final textEvents = events.where((e) => e.eventType == 'text' && e.assets.isEmpty).length;
    final photoEvents = events.where((e) => e.assets.isNotEmpty && e.eventType != 'text').length;
    final mixedEvents = events.where((e) => e.assets.isNotEmpty && e.description != null && e.description!.isNotEmpty).length;

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Timeline Overview',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(
                  context,
                  'Text Entries',
                  textEvents,
                  Icons.edit_note,
                  Theme.of(context).colorScheme.tertiary,
                ),
                _buildStatItem(
                  context,
                  'Photo Events',
                  photoEvents,
                  Icons.photo,
                  Theme.of(context).colorScheme.primary,
                ),
                _buildStatItem(
                  context,
                  'Mixed Events',
                  mixedEvents,
                  Icons.collections,
                  Theme.of(context).colorScheme.secondary,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(BuildContext context, String label, int count, IconData icon, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: color,
            size: 24,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          count.toString(),
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}