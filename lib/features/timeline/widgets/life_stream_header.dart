import 'package:flutter/material.dart';
import 'package:users_timeline/shared/models/user.dart';
import '../services/timeline_renderer_interface.dart';
import 'filter_dialog.dart';

class LifeStreamHeader extends StatelessWidget {
  final int totalEvents;
  final int filteredCount;
  final FilterCriteria? currentFilter;
  final VoidCallback onClearFilter;
  final VoidCallback onFilterTap;
  final VoidCallback onSearchTap;

  const LifeStreamHeader({
    Key? key,
    required this.totalEvents,
    required this.filteredCount,
    this.currentFilter,
    required this.onClearFilter,
    required this.onFilterTap,
    required this.onSearchTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final hasFilters = currentFilter?.hasFilters == true;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(bottom: BorderSide(color: Theme.of(context).dividerColor)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$filteredCount of $totalEvents events',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (hasFilters)
                Text(
                  '${currentFilter!.filterCount} filter(s) active',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
            ],
          ),
          Row(
            children: [
              if (hasFilters)
                TextButton.icon(
                  onPressed: onClearFilter,
                  icon: const Icon(Icons.clear, size: 16),
                  label: const Text('Clear'),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  ),
                ),
              _buildFilterButton(context, hasFilters),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterButton(BuildContext context, bool hasFilters) {
    return Stack(
      children: [
        IconButton(
          icon: const Icon(Icons.filter_list),
          onPressed: onFilterTap,
          tooltip: 'Filter Events',
        ),
        if (hasFilters)
          Positioned(
            right: 8,
            top: 8,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                shape: BoxShape.circle,
              ),
              constraints: const BoxConstraints(
                minWidth: 16,
                minHeight: 16,
              ),
              child: Center(
                child: Text(
                  '${currentFilter!.filterCount}',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onPrimary,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
