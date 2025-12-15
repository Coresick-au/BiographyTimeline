import 'package:users_timeline/shared/models/timeline_event.dart';

/// Simple tag management service to replace complex context system.
/// Provides predefined tags and custom tag management for timeline events.
class TagService {
  /// Predefined tags for common event categories
  static const List<String> defaultTags = [
    'Family',
    'Vacation',
    'School',
    'Work',
    'Birthday',
    'Holiday',
    'Sports',
    'Hobbies',
    'Friends',
    'Celebration',
    'Milestone',
    'Travel',
    'Home',
    'Health',
    'Learning',
    'Entertainment',
  ];

  final Set<String> _customTags = {};

  /// Get all available tags (default + custom)
  List<String> getAvailableTags() {
    final allTags = <String>[...defaultTags, ..._customTags];
    allTags.sort();
    return allTags;
  }

  /// Add a custom tag
  Future<void> addCustomTag(String tag) async {
    if (tag.trim().isEmpty) return;
    _customTags.add(tag.trim());
  }

  /// Remove a custom tag
  Future<void> removeCustomTag(String tag) async {
    _customTags.remove(tag);
  }

  /// Get all custom tags
  List<String> getCustomTags() {
    return _customTags.toList()..sort();
  }

  /// Filter events by tags (events must have at least one matching tag)
  List<TimelineEvent> filterByTags(
    List<TimelineEvent> events,
    List<String> filterTags,
  ) {
    if (filterTags.isEmpty) return events;

    return events.where((event) {
      return event.tags.any((tag) => filterTags.contains(tag));
    }).toList();
  }

  /// Filter events by multiple tags (events must have ALL specified tags)
  List<TimelineEvent> filterByAllTags(
    List<TimelineEvent> events,
    List<String> filterTags,
  ) {
    if (filterTags.isEmpty) return events;

    return events.where((event) {
      return filterTags.every((tag) => event.tags.contains(tag));
    }).toList();
  }

  /// Get all unique tags from a list of events
  Set<String> getTagsFromEvents(List<TimelineEvent> events) {
    final tags = <String>{};
    for (final event in events) {
      tags.addAll(event.tags);
    }
    return tags;
  }

  /// Get tag usage count from events
  Map<String, int> getTagUsageCount(List<TimelineEvent> events) {
    final tagCount = <String, int>{};
    for (final event in events) {
      for (final tag in event.tags) {
        tagCount[tag] = (tagCount[tag] ?? 0) + 1;
      }
    }
    return tagCount;
  }

  /// Suggest tags based on event type or title
  List<String> suggestTags({String? eventType, String? title}) {
    final suggestions = <String>[];

    if (eventType != null) {
      switch (eventType.toLowerCase()) {
        case 'birthday':
        case 'celebration':
          suggestions.addAll(['Birthday', 'Celebration', 'Family']);
          break;
        case 'vacation':
        case 'travel':
          suggestions.addAll(['Vacation', 'Travel']);
          break;
        case 'school':
        case 'education':
          suggestions.addAll(['School', 'Learning']);
          break;
        case 'work':
          suggestions.addAll(['Work']);
          break;
        case 'sports':
        case 'exercise':
          suggestions.addAll(['Sports', 'Health']);
          break;
        default:
          suggestions.add('Family');
      }
    }

    if (title != null) {
      final lowerTitle = title.toLowerCase();
      if (lowerTitle.contains('birthday')) suggestions.add('Birthday');
      if (lowerTitle.contains('vacation') || lowerTitle.contains('trip')) {
        suggestions.add('Vacation');
      }
      if (lowerTitle.contains('school')) suggestions.add('School');
      if (lowerTitle.contains('work')) suggestions.add('Work');
      if (lowerTitle.contains('family')) suggestions.add('Family');
    }

    return suggestions.toSet().toList();
  }
}
