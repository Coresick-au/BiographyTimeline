import 'dart:async';
import 'dart:collection';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'event_correlation_service.dart';
import '../database/database_service.dart';
import '../models/timeline_event.dart';
import '../models/media_asset.dart';

/// Service for managing smart event suggestions
/// Provides intelligent suggestions based on user patterns and feedback
class SmartEventSuggestionsService {
  static SmartEventSuggestionsService? _instance;
  static SmartEventSuggestionsService get instance => _instance ??= SmartEventSuggestionsService._();
  
  SmartEventSuggestionsService._();

  final _uuid = const Uuid();
  final _eventCorrelation = EventCorrelationService.instance;
  final _dbService = DatabaseService.instance;

  // Suggestion cache
  final Map<String, List<EventSuggestion>> _suggestionCache = {};
  final Map<String, DateTime> _cacheTimestamps = {};
  static const Duration _cacheTimeout = Duration(hours: 1);

  // User preference tracking
  final Map<String, UserPreference> _userPreferences = {};

  // =========================================================================
  // SUGGESTION GENERATION
  // =========================================================================

  /// Get smart event suggestions for a specific time period
  Future<List<EventSuggestion>> getSuggestions({
    DateTime? startDate,
    DateTime? endDate,
    String? albumId,
    bool forceRefresh = false,
  }) async {
    final cacheKey = _generateCacheKey(startDate, endDate, albumId);
    
    // Check cache first
    if (!forceRefresh && _isCacheValid(cacheKey)) {
      return _suggestionCache[cacheKey] ?? [];
    }

    // Generate new suggestions
    final suggestions = await _generateSmartSuggestions(
      startDate,
      endDate,
      albumId,
    );

    // Cache results
    _suggestionCache[cacheKey] = suggestions;
    _cacheTimestamps[cacheKey] = DateTime.now();

    return suggestions;
  }

  /// Generate smart suggestions with personalization
  Future<List<EventSuggestion>> _generateSmartSuggestions(
    DateTime? startDate,
    DateTime? endDate,
    String? albumId,
  ) async {
    // Get base suggestions from correlation service
    final baseSuggestions = await _eventCorrelation.analyzeAndSuggestEvents(
      startDate: startDate,
      endDate: endDate,
      albumId: albumId,
    );

    // Apply user preferences and personalization
    final personalizedSuggestions = await _applyPersonalization(baseSuggestions);

    // Filter and rank based on user patterns
    final filteredSuggestions = _filterByUserPatterns(personalizedSuggestions);

    // Add contextual suggestions
    final contextualSuggestions = await _addContextualSuggestions(
      filteredSuggestions,
      startDate,
      endDate,
    );

    return contextualSuggestions;
  }

  /// Apply user preferences to suggestions
  Future<List<EventSuggestion>> _applyPersonalization(
    List<EventSuggestion> suggestions,
  ) async {
    final personalized = <EventSuggestion>[];

    for (final suggestion in suggestions) {
      // Adjust confidence based on user preferences
      var adjustedConfidence = suggestion.confidence;
      
      // Check user preference for event type
      final typePreference = _userPreferences[suggestion.type.name];
      if (typePreference != null) {
        adjustedConfidence *= typePreference.weight;
      }

      // Check location preference
      if (suggestion.location != null) {
        final locationPreference = _getLocationPreference(suggestion.location!);
        adjustedConfidence *= locationPreference;
      }

      // Check people preference
      if (suggestion.peopleIds.isNotEmpty) {
        final peoplePreference = await _getPeoplePreference(suggestion.peopleIds);
        adjustedConfidence *= peoplePreference;
      }

      // Create adjusted suggestion
      personalized.add(suggestion.copyWith(
        confidence: adjustedConfidence,
      ));
    }

    return personalized;
  }

  /// Filter suggestions based on user patterns
  List<EventSuggestion> _filterByUserPatterns(List<EventSuggestion> suggestions) {
    // Remove suggestions that don't match user patterns
    final filtered = <EventSuggestion>[];

    for (final suggestion in suggestions) {
      // Check if user typically creates events of this type
      if (_shouldSuggestEventType(suggestion.type)) {
        filtered.add(suggestion);
      }
    }

    // Sort by adjusted confidence
    filtered.sort((a, b) => b.confidence.compareTo(a.confidence));

    return filtered;
  }

  /// Add contextual suggestions based on current date/time
  Future<List<EventSuggestion>> _addContextualSuggestions(
    List<EventSuggestion> existing,
    DateTime? startDate,
    DateTime? endDate,
  ) async {
    final contextual = <EventSuggestion>[];

    // Check for upcoming events
    final upcoming = await _suggestUpcomingEvents();
    contextual.addAll(upcoming);

    // Check for anniversary events
    final anniversaries = await _suggestAnniversaryEvents();
    contextual.addAll(anniversaries);

    // Check for seasonal events
    final seasonal = await _suggestSeasonalEvents();
    contextual.addAll(seasonal);

    // Combine with existing suggestions
    final all = [...existing, ...contextual];
    
    // Remove duplicates and sort
    final unique = _removeDuplicateSuggestions(all);
    unique.sort((a, b) => b.confidence.compareTo(a.confidence));

    return unique;
  }

  Future<List<EventSuggestion>> _suggestUpcomingEvents() async {
    final suggestions = <EventSuggestion>[];
    final now = DateTime.now();

    // Check for holidays in next 30 days
    final upcomingHolidays = _getUpcomingHolidays(now);
    for (final holiday in upcomingHolidays) {
      // Look for photos from last year's holiday
      final lastYear = DateTime(now.year - 1, holiday.month, holiday.day);
      final lastYearPhotos = await _getPhotosAroundDate(lastYear, days: 3);

      if (lastYearPhotos.isNotEmpty) {
        suggestions.add(EventSuggestion(
          id: _uuid.v4(),
          title: '${holiday.name} ${now.year}',
          type: EventType.holiday,
          startDate: DateTime(now.year, holiday.month, holiday.day),
          endDate: DateTime(now.year, holiday.month, holiday.day + 1),
          photoIds: lastYearPhotos.map((p) => p.id).toList(),
          peopleIds: [],
          confidence: 0.7,
          metadata: {
            'suggestionType': 'upcoming_holiday',
            'basedOnYear': now.year - 1,
          },
        ));
      }
    }

    return suggestions;
  }

  Future<List<EventSuggestion>> _suggestAnniversaryEvents() async {
    final suggestions = <EventSuggestion>[];
    final now = DateTime.now();

    // Get past events from same month
    final pastEvents = await _getPastEventsInMonth(now.month);
    
    for (final event in pastEvents) {
      final yearsSince = now.year - event.startDate.year;
      if (yearsSince > 0) {
        suggestions.add(EventSuggestion(
          id: _uuid.v4(),
          title: '${event.title} - ${yearsSince} Year${yearsSince > 1 ? 's' : ''} Anniversary',
          type: event.type,
          startDate: DateTime(now.year, event.startDate.month, event.startDate.day),
          endDate: DateTime(now.year, event.endDate.month, event.endDate.day),
          photoIds: [],
          peopleIds: [],
          confidence: 0.6,
          metadata: {
            'suggestionType': 'anniversary',
            'originalEventId': event.id,
            'yearsSince': yearsSince,
          },
        ));
      }
    }

    return suggestions;
  }

  Future<List<EventSuggestion>> _suggestSeasonalEvents() async {
    final suggestions = <EventSuggestion>[];
    final now = DateTime.now();
    final season = _getSeason(now);

    // Get photos from last year's same season
    final lastYearSeason = _getSeasonStartEnd(now.year - 1, season);
    final seasonalPhotos = await _getPhotosInRange(
      lastYearSeason.start,
      lastYearSeason.end,
    );

    if (seasonalPhotos.length >= 5) {
      suggestions.add(EventSuggestion(
        id: _uuid.v4(),
        title: '${season.name} ${now.year}',
        type: EventType.general,
        startDate: _getSeasonStartEnd(now.year, season).start,
        endDate: _getSeasonStartEnd(now.year, season).end,
        photoIds: seasonalPhotos.map((p) => p.id).toList(),
        peopleIds: [],
        confidence: 0.5,
        metadata: {
          'suggestionType': 'seasonal',
          'season': season.name,
          'photoCount': seasonalPhotos.length,
        },
      ));
    }

    return suggestions;
  }

  // =========================================================================
  // USER FEEDBACK HANDLING
  // =========================================================================

  /// User accepted a suggestion
  Future<void> acceptSuggestion(String suggestionId) async {
    // Update user preferences
    await _updatePreferencesFromAcceptance(suggestionId);

    // Record feedback
    await _eventCorrelation.recordAcceptance(suggestionId);

    // Clear cache to force refresh
    _clearCache();
  }

  /// User rejected a suggestion
  Future<void> rejectSuggestion(String suggestionId) async {
    // Update user preferences
    await _updatePreferencesFromRejection(suggestionId);

    // Record feedback
    await _eventCorrelation.recordRejection(suggestionId);

    // Clear cache to force refresh
    _clearCache();
  }

  /// User edited a suggestion
  Future<void> editSuggestion(
    String suggestionId,
    EventSuggestion edited,
  ) async {
    // Update user preferences based on changes
    await _updatePreferencesFromEdit(suggestionId, edited);

    // Record feedback
    await _eventCorrelation.recordEdit(suggestionId, edited);

    // Clear cache to force refresh
    _clearCache();
  }

  Future<void> _updatePreferencesFromAcceptance(String suggestionId) async {
    // Find the suggestion in cache
    final suggestion = _findSuggestionInCache(suggestionId);
    if (suggestion == null) return;

    // Increase preference weight for this event type
    final typePref = _userPreferences[suggestion.type.name] ?? 
        UserPreference(weight: 1.0, accepts: 0, rejects: 0);
    
    typePref.accepts++;
    typePref.weight = min(2.0, typePref.weight * 1.1);
    _userPreferences[suggestion.type.name] = typePref;

    // Update location preference
    if (suggestion.location != null) {
      _updateLocationPreference(suggestion.location!, increase: true);
    }

    // Save preferences
    await _saveUserPreferences();
  }

  Future<void> _updatePreferencesFromRejection(String suggestionId) async {
    final suggestion = _findSuggestionInCache(suggestionId);
    if (suggestion == null) return;

    // Decrease preference weight for this event type
    final typePref = _userPreferences[suggestion.type.name] ?? 
        UserPreference(weight: 1.0, accepts: 0, rejects: 0);
    
    typePref.rejects++;
    typePref.weight = max(0.1, typePref.weight * 0.9);
    _userPreferences[suggestion.type.name] = typePref;

    // Update location preference
    if (suggestion.location != null) {
      _updateLocationPreference(suggestion.location!, increase: false);
    }

    // Save preferences
    await _saveUserPreferences();
  }

  Future<void> _updatePreferencesFromEdit(
    String suggestionId,
    EventSuggestion edited,
  ) async {
    final original = _findSuggestionInCache(suggestionId);
    if (original == null) return;

    // Analyze what changed
    if (original.type != edited.type) {
      // User prefers different type
      final typePref = _userPreferences[edited.type.name] ?? 
          UserPreference(weight: 1.0, accepts: 0, rejects: 0);
      typePref.accepts++;
      typePref.weight = min(2.0, typePref.weight * 1.05);
      _userPreferences[edited.type.name] = typePref;
    }

    // Save preferences
    await _saveUserPreferences();
  }

  // =========================================================================
  // UTILITY METHODS
  // =========================================================================

  String _generateCacheKey(DateTime? startDate, DateTime? endDate, String? albumId) {
    return '${startDate?.millisecondsSinceEpoch ?? 'null'}-'
           '${endDate?.millisecondsSinceEpoch ?? 'null'}-'
           '${albumId ?? 'all'}';
  }

  bool _isCacheValid(String key) {
    final timestamp = _cacheTimestamps[key];
    if (timestamp == null) return false;
    
    return DateTime.now().difference(timestamp) < _cacheTimeout;
  }

  void _clearCache() {
    _suggestionCache.clear();
    _cacheTimestamps.clear();
  }

  EventSuggestion? _findSuggestionInCache(String suggestionId) {
    for (final suggestions in _suggestionCache.values) {
      for (final suggestion in suggestions) {
        if (suggestion.id == suggestionId) {
          return suggestion;
        }
      }
    }
    return null;
  }

  List<EventSuggestion> _removeDuplicateSuggestions(List<EventSuggestion> suggestions) {
    final seen = <String>{};
    final unique = <EventSuggestion>[];

    for (final suggestion in suggestions) {
      final key = '${suggestion.type}-${suggestion.startDate.millisecondsSinceEpoch}';
      if (!seen.contains(key)) {
        seen.add(key);
        unique.add(suggestion);
      }
    }

    return unique;
  }

  bool _shouldSuggestEventType(EventType type) {
    final preference = _userPreferences[type.name];
    if (preference == null) return true;
    
    // Don't suggest if user has rejected many times
    if (preference.rejects > preference.accepts * 2) {
      return false;
    }
    
    return true;
  }

  double _getLocationPreference(LocationData location) {
    // Simple location preference based on past events
    // In a real implementation, would use geohashing or clustering
    return 1.0;
  }

  Future<double> _getPeoplePreference(List<String> peopleIds) async {
    // Calculate preference based on how often user creates events with these people
    return 1.0;
  }

  void _updateLocationPreference(LocationData location, {required bool increase}) {
    // Update location preference score
    // Implementation would use geohashing for efficiency
  }

  Future<void> _saveUserPreferences() async {
    // Save to SharedPreferences
    // Implementation needed
  }

  Future<void> _loadUserPreferences() async {
    // Load from SharedPreferences
    // Implementation needed
  }

  // Helper methods (would need actual implementation)
  List<Holiday> _getUpcomingHolidays(DateTime date) => [];
  Future<List<MediaAsset>> _getPhotosAroundDate(DateTime date, {int days = 1}) async => [];
  Future<List<TimelineEventModel>> _getPastEventsInMonth(int month) async => [];
  Season _getSeason(DateTime date) => Season.winter;
  DateTimeRange _getSeasonStartEnd(int year, Season season) => 
      DateTimeRange(start: DateTime.now(), end: DateTime.now());
  Future<List<MediaAsset>> _getPhotosInRange(DateTime start, DateTime end) async => [];
  Future<List<MediaAsset>> _getPhotosForAnalysis(
    DateTime? startDate,
    DateTime? endDate,
    String? albumId,
  ) async => [];
}

// =========================================================================
// DATA MODELS
// =========================================================================

class UserPreference {
  double weight;
  int accepts;
  int rejects;

  UserPreference({
    required this.weight,
    required this.accepts,
    required this.rejects,
  });
}

class Holiday {
  final String name;
  final int month;
  final int day;

  Holiday({required this.name, required this.month, required this.day});
}

class Season {
  final String name;
  final int startMonth;
  final int startDay;
  final int endMonth;
  final int endDay;

  Season({
    required this.name,
    required this.startMonth,
    required this.startDay,
    required this.endMonth,
    required this.endDay,
  });

  static final Season winter = Season(
    name: 'Winter',
    startMonth: 12,
    startDay: 21,
    endMonth: 3,
    endDay: 20,
  );

  static final Season spring = Season(
    name: 'Spring',
    startMonth: 3,
    startDay: 21,
    endMonth: 6,
    endDay: 20,
  );

  static final Season summer = Season(
    name: 'Summer',
    startMonth: 6,
    startDay: 21,
    endMonth: 9,
    endDay: 20,
  );

  static final Season fall = Season(
    name: 'Fall',
    startMonth: 9,
    startDay: 21,
    endMonth: 12,
    endDay: 20,
  );
}

class DateTimeRange {
  final DateTime start;
  final DateTime end;

  DateTimeRange({required this.start, required this.end});
}

// =========================================================================
// PROVIDERS
// =========================================================================

final smartSuggestionsProvider = FutureProvider<List<EventSuggestion>>((ref) async {
  return await SmartEventSuggestionsService.instance.getSuggestions();
});

final suggestionsProvider = Provider<SmartEventSuggestionsService>((ref) {
  return SmartEventSuggestionsService.instance;
});

// =========================================================================
// EXCEPTIONS
// =========================================================================

class SmartSuggestionsException implements Exception {
  final String message;
  SmartSuggestionsException(this.message);
  
  @override
  String toString() => 'SmartSuggestionsException: $message';
}
