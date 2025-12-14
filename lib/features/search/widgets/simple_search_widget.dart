import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/models/timeline_event.dart';
import '../../timeline/services/timeline_data_service.dart';

/// Simple search widget that works without complex dependencies
class SimpleSearchWidget extends ConsumerStatefulWidget {
  const SimpleSearchWidget({
    super.key,
    this.onResultSelected,
    this.placeholder = 'Search your timeline...',
  });

  final Function(TimelineEvent)? onResultSelected;
  final String placeholder;

  @override
  ConsumerState<SimpleSearchWidget> createState() => _SimpleSearchWidgetState();
}

class _SimpleSearchWidgetState extends ConsumerState<SimpleSearchWidget> {
  final _searchController = TextEditingController();
  List<TimelineEvent> _results = [];
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase().trim();
    
    if (query.isEmpty) {
      setState(() {
        _results = [];
      });
      return;
    }

    setState(() {
      _isSearching = true;
    });

    // Simulate search delay
    Future.delayed(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      
      final asyncState = ref.read(timelineDataProvider);
      final allEvents = asyncState.value?.allEvents ?? [];
      
      final filtered = allEvents.where((event) {
        return event.title?.toLowerCase().contains(query) == true ||
               event.description?.toLowerCase().contains(query) == true ||
               event.eventType.toLowerCase().contains(query);
      }).toList();

      setState(() {
        _results = filtered;
        _isSearching = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Search input
        TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: widget.placeholder,
            prefixIcon: const Icon(Icons.search),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _searchController.clear();
                    },
                  )
                : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            filled: true,
            fillColor: Theme.of(context).colorScheme.surface,
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Results
        Expanded(
          child: _isSearching
              ? const Center(
                  child: CircularProgressIndicator(),
                )
              : _results.isEmpty && _searchController.text.isNotEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.search_off,
                            size: 64,
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No results found',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                            ),
                          ),
                        ],
                      ),
                    )
                  : _searchController.text.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.search,
                                size: 64,
                                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Start typing to search',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Search by title, description, or event type',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          itemCount: _results.length,
                          itemBuilder: (context, index) {
                            final event = _results[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: Theme.of(context).colorScheme.primary,
                                  child: Icon(
                                    _getEventIcon(event.eventType),
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                                title: Text(
                                  event.title ?? 'Untitled Event',
                                  style: Theme.of(context).textTheme.titleMedium,
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (event.description != null) ...[
                                      Text(
                                        event.description!,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: Theme.of(context).textTheme.bodyMedium,
                                      ),
                                      const SizedBox(height: 4),
                                    ],
                                    Text(
                                      '${_formatDate(event.timestamp)} • ${event.eventType}',
                                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        color: Theme.of(context).colorScheme.primary,
                                      ),
                                    ),
                                  ],
                                ),
                                onTap: () {
                                  widget.onResultSelected?.call(event);
                                },
                              ),
                            );
                          },
                        ),
        ),
      ],
    );
  }

  IconData _getEventIcon(String eventType) {
    switch (eventType.toLowerCase()) {
      case 'text':
        return Icons.text_fields;
      case 'image':
        return Icons.image;
      case 'video':
        return Icons.videocam;
      case 'audio':
        return Icons.audiotrack;
      case 'location':
        return Icons.location_on;
      case 'milestone':
        return Icons.star;
      default:
        return Icons.event;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else if (difference.inDays < 30) {
      return '${(difference.inDays / 7).floor()} weeks ago';
    } else if (difference.inDays < 365) {
      return '${(difference.inDays / 30).floor()} months ago';
    } else {
      return '${(difference.inDays / 365).floor()} years ago';
    }
  }
}
