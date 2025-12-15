import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../shared/models/timeline_event.dart';
import '../../../shared/models/context.dart';

/// Search dialog for finding and navigating to events
class SearchDialog extends StatefulWidget {
  final List<TimelineEvent> events;
  final List<Context> contexts;
  final Function(TimelineEvent) onEventSelected;

  const SearchDialog({
    super.key,
    required this.events,
    required this.contexts,
    required this.onEventSelected,
  });

  @override
  State<SearchDialog> createState() => _SearchDialogState();
}

class _SearchDialogState extends State<SearchDialog> {
  final TextEditingController _searchController = TextEditingController();
  List<TimelineEvent> _filteredEvents = [];
  String? _selectedEventType;
  DateTimeRange? _dateRange;

  @override
  void initState() {
    super.initState();
    _filteredEvents = widget.events;
    _searchController.addListener(_filterEvents);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterEvents() {
    setState(() {
      _filteredEvents = widget.events.where((event) {
        // Text search
        final searchText = _searchController.text.toLowerCase();
        final matchesText = searchText.isEmpty ||
            (event.title?.toLowerCase().contains(searchText) ?? false) ||
            (event.description?.toLowerCase().contains(searchText) ?? false) ||
            (event.location?.locationName?.toLowerCase().contains(searchText) ?? false);

        // Event type filter
        final matchesType = _selectedEventType == null || event.eventType == _selectedEventType;

        // Date range filter
        final matchesDate = _dateRange == null ||
            (event.timestamp.isAfter(_dateRange!.start) &&
                event.timestamp.isBefore(_dateRange!.end.add(const Duration(days: 1))));

        return matchesText && matchesType && matchesDate;
      }).toList();

      // Sort by date (most recent first)
      _filteredEvents.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Dialog(
      backgroundColor: Colors.transparent, // Important for glass effect
      insetPadding: const EdgeInsets.all(16),
      child: Container( // Container for blur
        width: MediaQuery.of(context).size.width * 0.9,
        constraints: const BoxConstraints(maxWidth: 600), // Max width for tablet/desktop
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          // Glass effect background
          color: theme.scaffoldBackgroundColor.withOpacity(0.85),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: theme.dividerColor.withOpacity(0.1),
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.search, size: 28, color: theme.colorScheme.primary),
                      const SizedBox(width: 12),
                      Text(
                        'Search Timeline',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close),
                        style: IconButton.styleFrom(
                          backgroundColor: theme.colorScheme.surface.withOpacity(0.5),
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Search & Filter Section
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      TextField(
                        controller: _searchController,
                        autofocus: true,
                        style: theme.textTheme.bodyLarge,
                        decoration: InputDecoration(
                          hintText: 'Search memories, places...',
                          prefixIcon: Icon(Icons.search, color: theme.colorScheme.onSurfaceVariant),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear),
                                  onPressed: () => _searchController.clear(),
                                )
                              : null,
                          filled: true,
                          fillColor: theme.colorScheme.surface,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(color: theme.colorScheme.primary, width: 2),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        ),
                      ),
                      const SizedBox(height: 16),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _buildFilterChip(
                              label: _selectedEventType ?? 'All Types',
                              isSelected: _selectedEventType != null,
                              icon: Icons.category,
                              onTap: _showEventTypeFilter,
                              onClear: _selectedEventType != null ? () {
                                setState(() {
                                  _selectedEventType = null;
                                  _filterEvents();
                                });
                              } : null,
                            ),
                            const SizedBox(width: 8),
                            _buildFilterChip(
                              label: _dateRange != null
                                  ? '${_formatShortDate(_dateRange!.start)} - ${_formatShortDate(_dateRange!.end)}'
                                  : 'All Dates',
                              isSelected: _dateRange != null,
                              icon: Icons.calendar_today,
                              onTap: _showDateRangeFilter,
                              onClear: _dateRange != null ? () {
                                setState(() {
                                  _dateRange = null;
                                  _filterEvents();
                                });
                              } : null,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Results Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
                  child: Text(
                    '${_filteredEvents.length} RESULTS',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      letterSpacing: 1.2,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                // Results
                Expanded(
                  child: _filteredEvents.isEmpty
                      ? _buildEmptyState(context)
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          itemCount: _filteredEvents.length,
                          itemBuilder: (context, index) {
                            return _buildResultItem(context, _filteredEvents[index]);
                          },
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required IconData icon,
    required VoidCallback onTap,
    VoidCallback? onClear,
  }) {
    final theme = Theme.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: EdgeInsets.fromLTRB(12, 8, onClear != null ? 8 : 12, 8),
          decoration: BoxDecoration(
            color: isSelected 
                ? theme.colorScheme.primaryContainer 
                : theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected 
                  ? theme.colorScheme.primary 
                  : theme.dividerColor.withOpacity(0.2),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon, 
                size: 16, 
                color: isSelected 
                    ? theme.colorScheme.onPrimaryContainer 
                    : theme.colorScheme.onSurfaceVariant
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: isSelected 
                      ? theme.colorScheme.onPrimaryContainer 
                      : theme.colorScheme.onSurface,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
              if (onClear != null) ...[
                const SizedBox(width: 4),
                InkWell(
                  onTap: onClear,
                  borderRadius: BorderRadius.circular(10),
                  child: Icon(
                    Icons.close,
                    size: 16,
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off_rounded,
            size: 64,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.2),
          ),
          const SizedBox(height: 16),
          Text(
            'No events found',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultItem(BuildContext context, TimelineEvent event) {
    final theme = Theme.of(context);
    final contextEntity = widget.contexts.isNotEmpty ? widget.contexts.first : null;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.dividerColor.withOpacity(0.1),
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: _getEventTypeColor(event.eventType).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            _getEventTypeIcon(event.eventType),
            color: _getEventTypeColor(event.eventType),
            size: 24,
          ),
        ),
        title: Text(
          event.title ?? 'Untitled Event',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                Text(
                  _formatDate(event.timestamp),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (contextEntity != null) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: CircleAvatar(radius: 2, backgroundColor: theme.dividerColor),
                  ),
                  Text(
                    contextEntity.name,
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ],
            ),
            if (event.location != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.location_on_outlined, 
                    size: 14, 
                    color: theme.colorScheme.onSurfaceVariant
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      event.location!.locationName ?? 'Unknown location',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
        trailing: Icon(
          Icons.chevron_right,
          color: theme.colorScheme.onSurface.withOpacity(0.3),
        ),
        onTap: () => widget.onEventSelected(event),
      ),
    );
  }

  void _showEventTypeFilter() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter by Event Type'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('All Types'),
              leading: Radio<String?>(
                value: null,
                groupValue: _selectedEventType,
                onChanged: (value) {
                  setState(() => _selectedEventType = value);
                  Navigator.of(context).pop();
                  _filterEvents();
                },
              ),
            ),
            ...['photo', 'milestone', 'text', 'location', 'video'].map((type) {
              return ListTile(
                title: Text(type[0].toUpperCase() + type.substring(1)),
                leading: Radio<String?>(
                  value: type,
                  groupValue: _selectedEventType,
                  onChanged: (value) {
                    setState(() => _selectedEventType = value);
                    Navigator.of(context).pop();
                    _filterEvents();
                  },
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  void _showDateRangeFilter() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: _dateRange,
    );

    if (picked != null) {
      setState(() {
        _dateRange = picked;
        _filterEvents();
      });
    }
  }

  Color _getEventTypeColor(String eventType) {
    switch (eventType.toLowerCase()) {
      case 'photo':
        return Colors.blue;
      case 'video':
        return Colors.red;
      case 'milestone':
        return Colors.green;
      case 'text':
        return Colors.purple;
      case 'location':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  IconData _getEventTypeIcon(String eventType) {
    switch (eventType.toLowerCase()) {
      case 'photo':
        return Icons.photo;
      case 'video':
        return Icons.videocam;
      case 'milestone':
        return Icons.star;
      case 'text':
        return Icons.text_fields;
      case 'location':
        return Icons.location_on;
      default:
        return Icons.event;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _formatShortDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
