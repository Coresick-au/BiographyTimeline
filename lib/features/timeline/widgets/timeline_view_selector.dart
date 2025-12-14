import 'package:flutter/material.dart';
import '../services/timeline_renderer_interface.dart';

class TimelineViewSelector extends StatelessWidget {
  final TabController tabController;
  final List<TimelineViewMode> availableModes;
  final ValueChanged<TimelineViewMode> onModeChanged;

  const TimelineViewSelector({
    Key? key,
    required this.tabController,
    required this.availableModes,
    required this.onModeChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: TabBar(
        controller: tabController,
        isScrollable: true,
        tabs: availableModes.map((mode) {
          return Tab(
            text: _getViewModeTitle(mode),
            icon: Icon(_getViewModeIcon(mode)),
          );
        }).toList(),
        labelColor: const Color(0xFF667EEA),
        unselectedLabelColor: Colors.grey,
        indicatorColor: const Color(0xFF667EEA),
        indicatorWeight: 3,
        onTap: (index) {
          onModeChanged(availableModes[index]);
        },
      ),
    );
  }

  String _getViewModeTitle(TimelineViewMode mode) {
    switch (mode) {
      case TimelineViewMode.chronological:
        return 'Chronological';
      case TimelineViewMode.lifeStream:
        return 'Life Stream';
      case TimelineViewMode.bentoGrid:
        return 'Grid';
      case TimelineViewMode.story:
        return 'Story';
      case TimelineViewMode.mapView:
        return 'Map';
      case TimelineViewMode.clustered:
        return 'Clustered';
      case TimelineViewMode.river:
        return 'River';
    }
  }

  IconData _getViewModeIcon(TimelineViewMode mode) {
    switch (mode) {
      case TimelineViewMode.chronological:
        return Icons.timeline;
      case TimelineViewMode.lifeStream:
        return Icons.waves;
      case TimelineViewMode.bentoGrid:
        return Icons.grid_view;
      case TimelineViewMode.story:
        return Icons.book;
      case TimelineViewMode.mapView:
        return Icons.map;
      case TimelineViewMode.clustered:
        return Icons.scatter_plot;
      case TimelineViewMode.river:
        return Icons.water;
    }
  }
}
