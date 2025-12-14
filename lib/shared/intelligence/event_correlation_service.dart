import 'dart:async';
import 'dart:collection';
import 'dart:math';
import 'package:latlong2/latlong.dart';
import 'package:uuid/uuid.dart';
import '../database/database_service.dart';
import '../models/media_asset.dart';
import '../models/timeline_event.dart';
import '../intelligence/face_detection_service.dart';

/// Service for correlating photos into meaningful events
/// Uses rule-based approach with weighted scoring
class EventCorrelationService {
  static EventCorrelationService? _instance;
  static EventCorrelationService get instance => _instance ??= EventCorrelationService._();
  
  EventCorrelationService._();

  final _uuid = const Uuid();
  final _dbService = DatabaseService.instance;

  // Weight configuration for correlation factors
  static const double _timeWeight = 0.5;
  static const double _locationWeight = 0.3;
  static const double _peopleWeight = 0.15;
  static const double _densityWeight = 0.05;

  // Thresholds
  static const Duration _maxTimeGap = Duration(hours: 6);
  static const double _maxLocationDistance = 500.0; // meters
  static const int _minPhotosForEvent = 3;
  static const int _maxPhotosPerSuggestion = 50;

  // User learning data
  final Map<String, double> _userWeights = {};

  // =========================================================================
  // EVENT CORRELATION
  // =========================================================================

  /// Analyze photos and suggest potential events
  Future<List<EventSuggestion>> analyzeAndSuggestEvents({
    DateTime? startDate,
    DateTime? endDate,
    String? albumId,
    int limit = 20,
  }) async {
    // Get photos within date range
    final photos = await _getPhotosForAnalysis(startDate, endDate, albumId);
    if (photos.length < _minPhotosForEvent) return [];

    // Sort photos by date
    photos.sort((a, b) => a.createdAt.compareTo(b.createdAt));

    // Group photos into potential events
    final eventGroups = await _groupPhotosIntoEvents(photos);

    // Calculate scores and create suggestions
    final suggestions = <EventSuggestion>[];
    for (final group in eventGroups) {
      final suggestion = await _createEventSuggestion(group);
      if (suggestion != null) {
        suggestions.add(suggestion);
      }
    }

    // Sort by confidence and limit results
    suggestions.sort((a, b) => b.confidence.compareTo(a.confidence));
    return suggestions.take(limit).toList();
  }

  Future<List<MediaAsset>> _getPhotosForAnalysis(
    DateTime? startDate,
    DateTime? endDate,
    String? albumId,
  ) async {
    // Implementation would query database for photos
    // For now, return empty list
    return [];
  }

  Future<List<PhotoGroup>> _groupPhotosIntoEvents(List<MediaAsset> photos) async {
    final groups = <PhotoGroup>[];
    PhotoGroup? currentGroup;

    for (final photo in photos) {
      if (currentGroup == null) {
        // Start new group
        currentGroup = PhotoGroup(photos: [photo]);
      } else {
        // Check if photo belongs to current group
        final lastPhoto = currentGroup.photos.last;
        final timeGap = photo.createdAt.difference(lastPhoto.createdAt);
        final locationDistance = _calculateDistance(lastPhoto, photo);

        if (timeGap <= _maxTimeGap && 
            locationDistance <= _maxLocationDistance) {
          // Add to current group
          currentGroup.photos.add(photo);
        } else {
          // Save current group and start new one
          if (currentGroup.photos.length >= _minPhotosForEvent) {
            groups.add(currentGroup);
          }
          currentGroup = PhotoGroup(photos: [photo]);
        }
      }
    }

    // Add final group
    if (currentGroup != null && 
        currentGroup.photos.length >= _minPhotosForEvent) {
      groups.add(currentGroup);
    }

    // Merge nearby groups based on people co-occurrence
    return await _mergeGroupsByPeople(groups);
  }

  double _calculateDistance(MediaAsset photo1, MediaAsset photo2) {
    if (photo1.location == null || photo2.location == null) {
      return double.infinity;
    }

    final p1 = LatLng(photo1.location!.latitude, photo1.location!.longitude);
    final p2 = LatLng(photo2.location!.latitude, photo2.location!.longitude);
    
    final DistanceCalculator calculator = const DistanceCalculator();
    return calculator.distance(p1, p2);
  }

  Future<List<PhotoGroup>> _mergeGroupsByPeople(List<PhotoGroup> groups) async {
    if (groups.length < 2) return groups;

    // Get people in each group
    final groupPeople = <PhotoGroup, Set<String>>{};
    for (final group in groups) {
      final people = await _getPeopleInPhotos(group.photos);
      groupPeople[group] = people;
    }

    // Merge groups with significant people overlap
    final merged = <PhotoGroup>[];
    final processed = <int>{};

    for (int i = 0; i < groups.length; i++) {
      if (processed.contains(i)) continue;

      final currentGroup = groups[i];
      final currentPeople = groupPeople[currentGroup] ?? <String>{};
      var mergedGroup = currentGroup;

      // Check for mergeable groups
      for (int j = i + 1; j < groups.length; j++) {
        if (processed.contains(j)) continue;

        final otherGroup = groups[j];
        final otherPeople = groupPeople[otherGroup] ?? <String>{};

        // Calculate people overlap
        final overlap = _calculatePeopleOverlap(currentPeople, otherPeople);
        if (overlap > 0.7) { // 70% overlap threshold
          mergedGroup = PhotoGroup(
            photos: [...mergedGroup.photos, ...otherGroup.photos],
          );
          processed.add(j);
        }
      }

      merged.add(mergedGroup);
      processed.add(i);
    }

    return merged;
  }

  Future<Set<String>> _getPeopleInPhotos(List<MediaAsset> photos) async {
    final people = <String>{};
    
    for (final photo in photos) {
      // Get faces/people for this photo
      // final faces = await _faceDbService.getFacesForPhoto(photo.id);
      // for (final face in faces) {
      //   if (face.personId != null) {
      //     people.add(face.personId!);
      //   }
      // }
    }
    
    return people;
  }

  double _calculatePeopleOverlap(Set<String> people1, Set<String> people2) {
    if (people1.isEmpty || people2.isEmpty) return 0.0;
    
    final intersection = people1.intersection(people2);
    final union = people1.union(people2);
    
    return intersection.length / union.length;
  }

  Future<EventSuggestion?> _createEventSuggestion(PhotoGroup group) async {
    if (group.photos.length < _minPhotosForEvent) return null;

    // Calculate event characteristics
    final timeSpan = _calculateTimeSpan(group.photos);
    final location = _calculateRepresentativeLocation(group.photos);
    final people = await _getPeopleInPhotos(group.photos);
    final density = _calculatePhotoDensity(group.photos);

    // Generate event type and title
    final eventType = _determineEventType(group.photos, timeSpan, people);
    final title = _generateEventTitle(eventType, group.photos, location);

    // Calculate confidence score
    final confidence = _calculateConfidenceScore(
      timeSpan,
      location,
      people,
      density,
      group.photos.length,
    );

    return EventSuggestion(
      id: _uuid.v4(),
      title: title,
      type: eventType,
      startDate: group.photos.first.createdAt,
      endDate: group.photos.last.createdAt,
      location: location,
      photoIds: group.photos.map((p) => p.id).toList(),
      peopleIds: people.toList(),
      confidence: confidence,
      metadata: {
        'photoCount': group.photos.length,
        'timeSpanHours': timeSpan.inHours,
        'peopleCount': people.length,
        'density': density,
      },
    );
  }

  Duration _calculateTimeSpan(List<MediaModel> photos) {
    if (photos.length < 2) return Duration.zero;
    
    final start = photos.first.createdAt;
    final end = photos.last.createdAt;
    return end.difference(start);
  }

  LocationData? _calculateRepresentativeLocation(List<MediaModel> photos) {
    final locations = photos
        .map((p) => p.location)
        .where((l) => l != null)
        .cast<LocationData>()
        .toList();
    
    if (locations.isEmpty) return null;
    
    // Calculate median location
    final latitudes = locations.map((l) => l.latitude).toList()..sort();
    final longitudes = locations.map((l) => l.longitude).toList()..sort();
    
    final medianLat = latitudes[latitudes.length ~/ 2];
    final medianLng = longitudes[longitudes.length ~/ 2];
    
    return LocationData(
      latitude: medianLat,
      longitude: medianLng,
      accuracy: locations
          .map((l) => l.accuracy ?? 0.0)
          .reduce((a, b) => (a + b) / locations.length),
    );
  }

  double _calculatePhotoDensity(List<MediaModel> photos) {
    if (photos.length < 2) return 0.0;
    
    final timeSpan = _calculateTimeSpan(photos);
    if (timeSpan.inMinutes == 0) return photos.length.toDouble();
    
    return photos.length / timeSpan.inHours;
  }

  EventType _determineEventType(
    List<MediaModel> photos,
    Duration timeSpan,
    Set<String> people,
  ) {
    // Check for holiday patterns
    if (_isHolidayPeriod(photos.first.createdAt)) {
      return EventType.holiday;
    }
    
    // Check for weekend patterns
    if (_isWeekendEvent(photos)) {
      return EventType.weekend;
    }
    
    // Check for celebration patterns
    if (_isCelebration(photos, people)) {
      return EventType.celebration;
    }
    
    // Check for travel patterns
    if (_isTravelEvent(photos, timeSpan)) {
      return EventType.travel;
    }
    
    // Check for gathering patterns
    if (people.length >= 5) {
      return EventType.gathering;
    }
    
    return EventType.general;
  }

  bool _isHolidayPeriod(DateTime date) {
    // Simple holiday detection
    final month = date.month;
    final day = date.day;
    
    // Christmas
    if (month == 12 && (day >= 20 && day <= 31)) return true;
    
    // New Year
    if (month == 1 && (day >= 1 && day <= 3)) return true;
    
    // Add more holidays as needed
    return false;
  }

  bool _isWeekendEvent(List<MediaModel> photos) {
    return photos.every((p) => 
        p.createdAt.weekday == DateTime.saturday || 
        p.createdAt.weekday == DateTime.sunday);
  }

  bool _isCelebration(List<MediaModel> photos, Set<String> people) {
    // High photo density indicates celebration
    final density = _calculatePhotoDensity(photos);
    return density > 20.0; // More than 20 photos per hour
  }

  bool _isTravelEvent(List<MediaModel> photos, Duration timeSpan) {
    if (timeSpan.inDays < 2) return false;
    
    // Check for location changes
    final locations = photos
        .map((p) => p.location)
        .where((l) => l != null)
        .cast<LocationData>()
        .toList();
    
    if (locations.length < 2) return false;
    
    // Calculate total distance traveled
    double totalDistance = 0.0;
    for (int i = 1; i < locations.length; i++) {
      totalDistance += _calculateDistance(
        MediaModel(id: '', createdAt: DateTime.now(), location: locations[i-1]),
        MediaModel(id: '', createdAt: DateTime.now(), location: locations[i]),
      );
    }
    
    return totalDistance > 10000; // More than 10km traveled
  }

  String _generateEventTitle(
    EventType type,
    List<MediaModel> photos,
    LocationData? location,
  ) {
    switch (type) {
      case EventType.holiday:
        final month = photos.first.createdAt.month;
        if (month == 12) return 'Christmas ${photos.first.createdAt.year}';
        if (month == 1) return 'New Year ${photos.first.createdAt.year}';
        return 'Holiday ${photos.first.createdAt.year}';
        
      case EventType.weekend:
        return 'Weekend Getaway';
        
      case EventType.celebration:
        return 'Celebration';
        
      case EventType.travel:
        if (location != null) {
          return 'Trip to ${_getLocationName(location)}';
        }
        return 'Travel';
        
      case EventType.gathering:
        return 'Gathering with Friends';
        
      case EventType.general:
        if (location != null) {
          return 'Day at ${_getLocationName(location)}';
        }
        return 'Photo Collection';
    }
  }

  String _getLocationName(LocationData location) {
    // Would use reverse geocoding to get location name
    // For now, return coordinates
    return '${location.latitude.toStringAsFixed(2)}, ${location.longitude.toStringAsFixed(2)}';
  }

  double _calculateConfidenceScore(
    Duration timeSpan,
    LocationData? location,
    Set<String> people,
    double density,
    int photoCount,
  ) {
    double score = 0.0;
    
    // Time score (shorter time span is better)
    final timeScore = max(0.0, 1.0 - (timeSpan.inHours / 24.0));
    score += timeScore * _timeWeight;
    
    // Location score (specific location is better)
    final locationScore = location != null ? 1.0 : 0.5;
    score += locationScore * _locationWeight;
    
    // People score (more people is better up to a point)
    final peopleScore = min(1.0, people.length / 10.0);
    score += peopleScore * _peopleWeight;
    
    // Density score (higher density is better)
    final densityScore = min(1.0, density / 30.0);
    score += densityScore * _densityWeight;
    
    // Photo count bonus
    if (photoCount >= 10) score += 0.1;
    if (photoCount >= 20) score += 0.1;
    
    return min(1.0, score);
  }

  // =========================================================================
  // USER FEEDBACK
  // =========================================================================

  /// Record user acceptance of suggestion
  Future<void> recordAcceptance(String suggestionId) async {
    // Update weights based on acceptance
    _updateWeights(suggestionId, true);
    
    // Save to user preferences
    await _saveUserWeights();
  }

  /// Record user rejection of suggestion
  Future<void> recordRejection(String suggestionId) async {
    // Update weights based on rejection
    _updateWeights(suggestionId, false);
    
    // Save to user preferences
    await _saveUserWeights();
  }

  /// Record user edit of suggestion
  Future<void> recordEdit(String suggestionId, EventSuggestion edited) async {
    // Analyze changes and adjust weights
    _analyzeEdit(suggestionId, edited);
    
    // Save to user preferences
    await _saveUserWeights();
  }

  void _updateWeights(String suggestionId, bool accepted) {
    // Simple weight adjustment
    final adjustment = accepted ? 0.01 : -0.01;
    
    _userWeights['time'] = (_userWeights['time'] ?? _timeWeight) + adjustment;
    _userWeights['location'] = (_userWeights['location'] ?? _locationWeight) + adjustment;
    _userWeights['people'] = (_userWeights['people'] ?? _peopleWeight) + adjustment;
    _userWeights['density'] = (_userWeights['density'] ?? _densityWeight) + adjustment;
    
    // Normalize weights
    _normalizeWeights();
  }

  void _analyzeEdit(String suggestionId, EventSuggestion edited) {
    // Analyze what user changed and adjust weights accordingly
    // Implementation would depend on what was edited
  }

  void _normalizeWeights() {
    final total = _userWeights.values.fold(0.0, (a, b) => a + b);
    if (total > 0) {
      for (final key in _userWeights.keys) {
        _userWeights[key] = _userWeights[key]! / total;
      }
    }
  }

  Future<void> _saveUserWeights() async {
    // Save to SharedPreferences
    // Implementation needed
  }

  Future<void> _loadUserWeights() async {
    // Load from SharedPreferences
    // Implementation needed
  }

  // =========================================================================
  // BATCH OPERATIONS
  // =========================================================================

  /// Process entire photo library for event suggestions
  Future<List<EventSuggestion>> processEntireLibrary() async {
    final allPhotos = await _getAllPhotos();
    
    // Process in chunks to avoid memory issues
    const chunkSize = 500;
    final allSuggestions = <EventSuggestion>[];
    
    for (int i = 0; i < allPhotos.length; i += chunkSize) {
      final chunk = allPhotos.skip(i).take(chunkSize).toList();
      final suggestions = await analyzeAndSuggestEvents(
        startDate: chunk.first.createdAt,
        endDate: chunk.last.createdAt,
      );
      
      allSuggestions.addAll(suggestions);
    }
    
    return allSuggestions;
  }

  Future<List<MediaModel>> _getAllPhotos() async {
    // Implementation would get all photos from database
    return [];
  }
}

// =========================================================================
// DATA MODELS
// =========================================================================

class PhotoGroup {
  final List<MediaAsset> photos;
  
  PhotoGroup({required this.photos});
}

class EventSuggestion {
  final String id;
  final String title;
  final EventType type;
  final DateTime startDate;
  final DateTime endDate;
  final LocationData? location;
  final List<String> photoIds;
  final List<String> peopleIds;
  final double confidence;
  final Map<String, dynamic> metadata;

  EventSuggestion({
    required this.id,
    required this.title,
    required this.type,
    required this.startDate,
    required this.endDate,
    this.location,
    required this.photoIds,
    required this.peopleIds,
    required this.confidence,
    required this.metadata,
  });

  EventSuggestion copyWith({
    String? id,
    String? title,
    EventType? type,
    DateTime? startDate,
    DateTime? endDate,
    LocationData? location,
    List<String>? photoIds,
    List<String>? peopleIds,
    double? confidence,
    Map<String, dynamic>? metadata,
  }) {
    return EventSuggestion(
      id: id ?? this.id,
      title: title ?? this.title,
      type: type ?? this.type,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      location: location ?? this.location,
      photoIds: photoIds ?? this.photoIds,
      peopleIds: peopleIds ?? this.peopleIds,
      confidence: confidence ?? this.confidence,
      metadata: metadata ?? this.metadata,
    );
  }
}

enum EventType {
  general,
  holiday,
  weekend,
  celebration,
  travel,
  gathering,
}

class LocationData {
  final double latitude;
  final double longitude;
  final double? accuracy;

  LocationData({
    required this.latitude,
    required this.longitude,
    this.accuracy,
  });
}
