import 'package:flutter/material.dart';
import '../../../shared/models/timeline_event.dart';
import '../models/timeline_view_state.dart';

/// Data model for a time bucket bubble
class BubbleData {
  final String id;
  final DateTime start;
  final DateTime end;
  final int eventCount;
  final String label;
  final Color color;
  final String dominantCategory;
  final Set<String> participantIds;
  final List<String> eventIds;
  final Map<String, int> personCounts;
  final ZoomTier tier;

  const BubbleData({
    required this.id,
    required this.start,
    required this.end,
    required this.eventCount,
    required this.label,
    required this.color,
    required this.dominantCategory,
    required this.participantIds,
    required this.eventIds,
    required this.personCounts,
    required this.tier,
  });

  /// Bubble size based on event count (normalized 0.5 - 1.5)
  double get sizeMultiplier {
    if (eventCount <= 1) return 0.6;
    if (eventCount <= 3) return 0.8;
    if (eventCount <= 5) return 1.0;
    if (eventCount <= 10) return 1.2;
    return 1.4;
  }
}

/// Service that aggregates timeline events into bubbles by time period
class BubbleAggregationService {
  /// Category to color mapping
  static const Map<String, Color> categoryColors = {
    'Family': Color(0xFF6366F1),    // Indigo
    'Travel': Color(0xFF10B981),    // Emerald
    'Work': Color(0xFFF59E0B),      // Amber
    'Career': Color(0xFFF59E0B),    // Amber
    'Milestone': Color(0xFFEC4899), // Pink
    'Birth': Color(0xFFEC4899),     // Pink
    'Personal': Color(0xFF8B5CF6),  // Violet
    'Home': Color(0xFF14B8A6),      // Teal
    'Holiday': Color(0xFFF43F5E),   // Rose
    'Education': Color(0xFF3B82F6), // Blue
  };

  /// Aggregate events into bubbles based on zoom tier
  List<BubbleData> aggregate({
    required List<TimelineEvent> events,
    required ZoomTier tier,
  }) {
    if (events.isEmpty) return [];

    // Group events by time bucket
    final Map<String, List<TimelineEvent>> buckets = {};

    for (final event in events) {
      final bucketKey = _getBucketKey(event.timestamp, tier);
      buckets.putIfAbsent(bucketKey, () => []).add(event);
    }

    // Convert buckets to bubbles
    final bubbles = <BubbleData>[];
    
    buckets.forEach((key, bucketEvents) {
      final (start, end, label) = _parseBucketKey(key, tier);
      final dominantCategory = _getDominantCategory(bucketEvents);
      final participantIds = bucketEvents.map((e) => e.ownerId).toSet();
      
      // Calculate person distribution
      final personCounts = <String, int>{};
      for (final e in bucketEvents) {
         final personId = e.ownerId;
         personCounts[personId] = (personCounts[personId] ?? 0) + 1;
      }

      bubbles.add(BubbleData(
        id: 'bubble_$key',
        start: start,
        end: end,
        eventCount: bucketEvents.length,
        label: label,
        color: categoryColors[dominantCategory] ?? const Color(0xFF64748B),
        dominantCategory: dominantCategory,
        participantIds: participantIds,
        eventIds: bucketEvents.map((e) => e.id).toList(),
        personCounts: personCounts,
        tier: tier,
      ));
    });

    // Sort by start date
    bubbles.sort((a, b) => a.start.compareTo(b.start));
    
    return bubbles;
  }

  /// Get bucket key for a timestamp at given tier
  String _getBucketKey(DateTime timestamp, ZoomTier tier) {
    switch (tier) {
      case ZoomTier.year:
        return '${timestamp.year}';
      case ZoomTier.month:
        return '${timestamp.year}-${timestamp.month.toString().padLeft(2, '0')}';
      case ZoomTier.week:
        // Week number calculation
        final firstDayOfYear = DateTime(timestamp.year, 1, 1);
        final weekNum = ((timestamp.difference(firstDayOfYear).inDays) / 7).floor() + 1;
        return '${timestamp.year}-W${weekNum.toString().padLeft(2, '0')}';
      case ZoomTier.day:
      case ZoomTier.focus:
        return '${timestamp.year}-${timestamp.month.toString().padLeft(2, '0')}-${timestamp.day.toString().padLeft(2, '0')}';
    }
  }

  /// Parse bucket key back to date range and label
  (DateTime, DateTime, String) _parseBucketKey(String key, ZoomTier tier) {
    switch (tier) {
      case ZoomTier.year:
        final year = int.parse(key);
        return (
          DateTime(year, 1, 1),
          DateTime(year, 12, 31),
          key,
        );
      case ZoomTier.month:
        final parts = key.split('-');
        final year = int.parse(parts[0]);
        final month = int.parse(parts[1]);
        final lastDay = DateTime(year, month + 1, 0).day;
        return (
          DateTime(year, month, 1),
          DateTime(year, month, lastDay),
          _getMonthName(month) + ' ' + parts[0],
        );
      case ZoomTier.week:
        final parts = key.split('-W');
        final year = int.parse(parts[0]);
        final week = int.parse(parts[1]);
        final firstDayOfYear = DateTime(year, 1, 1);
        final weekStart = firstDayOfYear.add(Duration(days: (week - 1) * 7));
        return (
          weekStart,
          weekStart.add(const Duration(days: 6)),
          'Week $week, $year',
        );
      case ZoomTier.day:
      case ZoomTier.focus:
        final parts = key.split('-');
        final year = int.parse(parts[0]);
        final month = int.parse(parts[1]);
        final day = int.parse(parts[2]);
        final date = DateTime(year, month, day);
        return (
          date,
          date,
          '${_getMonthName(month)} $day, $year',
        );
    }
  }

  /// Get dominant category from events
  String _getDominantCategory(List<TimelineEvent> events) {
    final tagCounts = <String, int>{};
    
    for (final event in events) {
      for (final tag in event.tags) {
        tagCounts[tag] = (tagCounts[tag] ?? 0) + 1;
      }
    }
    
    if (tagCounts.isEmpty) return 'Other';
    
    String dominant = 'Other';
    int maxCount = 0;
    
    tagCounts.forEach((tag, count) {
      if (count > maxCount && categoryColors.containsKey(tag)) {
        maxCount = count;
        dominant = tag;
      }
    });
    
    return dominant;
  }

  String _getMonthName(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 
                    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[month - 1];
  }
}
