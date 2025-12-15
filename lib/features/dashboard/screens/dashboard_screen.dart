import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import '../../timeline/services/timeline_data_service.dart';
import '../../timeline/models/timeline_state.dart';
import '../../../shared/models/timeline_event.dart';
import '../providers/dashboard_filter_state.dart';
import '../widgets/dashboard_card.dart';
import '../widgets/time_distribution_chart.dart';
import '../widgets/event_type_donut.dart';
import '../widgets/activity_heatmap.dart';
import '../widgets/data_quality_stats.dart';
import '../../../shared/widgets/modern/dark_theme.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timelineState = ref.watch(timelineDataProvider);
    final filters = ref.watch(dashboardFilterProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.refresh(timelineDataProvider),
          ),
        ],
      ),
      body: timelineState.when(
        data: (state) => _buildDashboardContent(context, state, filters),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }

  Widget _buildDashboardContent(
    BuildContext context, 
    TimelineState state,
    DashboardFilters filters,
  ) {
    // 1. Filter Data
    final events = state.allEvents.where((e) {
      if (filters.startDate != null && e.timestamp.isBefore(filters.startDate!)) return false;
      if (filters.endDate != null && e.timestamp.isAfter(filters.endDate!)) return false;
      // Add more filters if needed
      return true;
    }).toList();

    if (events.isEmpty) {
      return const Center(child: Text('No events found for current filters'));
    }

    // 2. Aggregate Data
    final totalEvents = events.length;
    final yearsSpan = events.isNotEmpty 
        ? events.last.timestamp.year - events.first.timestamp.year + 1 
        : 0;
    
    // Time Dist
    final timeDist = <DateTime, int>{};
    for (final e in events) {
      final key = DateTime(e.timestamp.year); // By year
      timeDist[key] = (timeDist[key] ?? 0) + 1;
    }
    
    // Type Breakdown
    final typeBreakdown = <String, int>{};
    for (final e in events) {
      for (final tag in e.tags) {
        typeBreakdown[tag] = (typeBreakdown[tag] ?? 0) + 1;
      }
    }
    
    // Heatmap (Daily)
    final dailyActivity = <DateTime, int>{};
    for (final e in events) {
      dailyActivity[e.timestamp] = (dailyActivity[e.timestamp] ?? 0) + 1;
    }
    
    // Data Quality
    int withLoc = 0, withTags = 0, withPhotos = 0;
    for (final e in events) {
      if (e.location != null) withLoc++;
      if (e.tags.isNotEmpty) withTags++;
      // Photos check needs media assets
      // Assuming naive check if we don't have media count in event model directly
      // Checking e.assets if it exists or we skip for now?
      // TimelineEvent doesn't have media directly in this simplified model view.
      // Let's assume tags/location for now.
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // KPI Row
          StaggeredGrid.count(
            crossAxisCount: 4,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            children: [
              StaggeredGridTile.count(
                crossAxisCellCount: 1,
                mainAxisCellCount: 0.8,
                child: _buildKPICard(context, 'Total Events', totalEvents.toString()),
              ),
              StaggeredGridTile.count(
                crossAxisCellCount: 1,
                mainAxisCellCount: 0.8,
                child: _buildKPICard(context, 'Years Span', yearsSpan.toString()),
              ),
              StaggeredGridTile.count(
                crossAxisCellCount: 1,
                mainAxisCellCount: 0.8,
                child: _buildKPICard(context, 'Avg / Year', (totalEvents / (yearsSpan > 0 ? yearsSpan : 1)).toStringAsFixed(1)),
              ),
              StaggeredGridTile.count(
                crossAxisCellCount: 1,
                mainAxisCellCount: 0.8,
                child: _buildKPICard(context, 'Contexts', state.contexts.length.toString()),
              ),
              
              // Charts
              StaggeredGridTile.count(
                crossAxisCellCount: 4,
                mainAxisCellCount: 2,
                child: DashboardCard(
                  title: 'Events over Time',
                  child: TimeDistributionChart(data: timeDist),
                ),
              ),
              
              StaggeredGridTile.count(
                crossAxisCellCount: 2,
                mainAxisCellCount: 2,
                child: DashboardCard(
                  title: 'Top Tags',
                  child: EventTypeDonut(data: typeBreakdown),
                ),
              ),
              
              StaggeredGridTile.count(
                crossAxisCellCount: 2,
                mainAxisCellCount: 2,
                child: DashboardCard(
                  title: 'Data Quality',
                  child: DataQualityStats(
                    totalEvents: totalEvents,
                    withLocation: withLoc,
                    withTags: withTags,
                    withPhotos: 0, // Placeholder
                  ),
                ),
              ),
              
              StaggeredGridTile.count(
                crossAxisCellCount: 4,
                mainAxisCellCount: 2,
                child: DashboardCard(
                  title: 'Activity Heatmap (Last Year)',
                  child: ActivityHeatmap(data: dailyActivity),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildKPICard(BuildContext context, String label, String value) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).colorScheme.primary.withOpacity(0.2)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            value,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
