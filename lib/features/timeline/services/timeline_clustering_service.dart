import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/models/timeline_event.dart';

/// Service responsible for clustering timeline events.
class TimelineClusteringService {
  
  /// Groups events into clusters based on time proximity (within 7 days).
  /// 
  /// Returns a map where keys are cluster IDs and values are lists of events in that cluster.
  Map<String, List<TimelineEvent>> generateClusters(List<TimelineEvent> events) {
    final clusteredEvents = <String, List<TimelineEvent>>{};
    
    if (events.isEmpty) return clusteredEvents;

    // Sort events by timestamp
    final sortedEvents = List<TimelineEvent>.from(events)
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    List<TimelineEvent> currentCluster = [sortedEvents.first];
    
    for (int i = 1; i < sortedEvents.length; i++) {
      final currentEvent = sortedEvents[i];
      final previousEvent = sortedEvents[i - 1];
      
      final timeDifference = currentEvent.timestamp.difference(previousEvent.timestamp);
      
      if (timeDifference.inDays <= 7) {
        currentCluster.add(currentEvent);
      } else {
        // Save current cluster and start a new one
        if (currentCluster.isNotEmpty) {
          clusteredEvents['cluster-${clusteredEvents.length}'] = List.from(currentCluster);
        }
        currentCluster = [currentEvent];
      }
    }
    
    // Save the last cluster
    if (currentCluster.isNotEmpty) {
      clusteredEvents['cluster-${clusteredEvents.length}'] = List.from(currentCluster);
    }

    return clusteredEvents;
  }
}

/// Provider for TimelineClusteringService
final timelineClusteringServiceProvider = Provider<TimelineClusteringService>((ref) {
  return TimelineClusteringService();
});
