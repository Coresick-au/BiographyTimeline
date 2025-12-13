import 'dart:async';
import 'dart:collection';
import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/media_asset.dart';
import '../models/timeline_event.dart';

/// Lightweight text embedding service for generating searchable content
/// Uses TF-IDF with custom weighting for mobile efficiency
class TextEmbeddingService {
  static TextEmbeddingService? _instance;
  static TextEmbeddingService get instance => _instance ??= TextEmbeddingService._();
  
  TextEmbeddingService._();

  // TF-IDF components
  final Map<String, int> _documentFrequency = {};
  final Map<String, double> _idfCache = {};
  int _totalDocuments = 0;

  // Custom word weights for timeline-specific terms
  static const Map<String, double> _termWeights = {
    // Event types
    'birthday': 2.0,
    'wedding': 2.0,
    'vacation': 1.8,
    'holiday': 1.8,
    'celebration': 1.6,
    'party': 1.5,
    'anniversary': 1.6,
    
    // Locations
    'beach': 1.7,
    'park': 1.5,
    'mountain': 1.5,
    'city': 1.3,
    'home': 1.4,
    'restaurant': 1.4,
    
    // Activities
    'camping': 1.8,
    'hiking': 1.7,
    'swimming': 1.6,
    'dancing': 1.5,
    'eating': 1.3,
    'traveling': 1.6,
    
    // Time indicators
    'summer': 1.5,
    'winter': 1.5,
    'spring': 1.4,
    'fall': 1.4,
    'christmas': 2.0,
    'new': 1.3,
    'year': 1.2,
    
    // People
    'family': 1.8,
    'friends': 1.7,
    'kids': 1.6,
    'children': 1.6,
    'parents': 1.5,
    'grandparents': 1.5,
    
    // Descriptors
    'beautiful': 1.3,
    'amazing': 1.3,
    'wonderful': 1.3,
    'fun': 1.4,
    'happy': 1.4,
    'love': 1.5,
  };

  // Stop words to exclude
  static const Set<String> _stopWords = {
    'the', 'a', 'an', 'and', 'or', 'but', 'in', 'on', 'at', 'to', 'for',
    'of', 'with', 'by', 'is', 'was', 'are', 'were', 'been', 'be', 'have',
    'has', 'had', 'do', 'does', 'did', 'will', 'would', 'could', 'should',
    'may', 'might', 'must', 'can', 'this', 'that', 'these', 'those', 'i',
    'you', 'he', 'she', 'it', 'we', 'they', 'what', 'which', 'who', 'when',
    'where', 'why', 'how', 'all', 'each', 'every', 'both', 'few', 'more',
    'most', 'other', 'some', 'such', 'no', 'nor', 'not', 'only', 'own',
    'same', 'so', 'than', 'too', 'very', 'just', 'now', 'here', 'there',
  };

  // =========================================================================
  // TEXT PROCESSING
  // =========================================================================

  /// Generate searchable content from media asset
  Future<SearchableContent> generateFromMediaAsset(
    MediaAsset asset, {
    String? caption,
    String? description,
    List<String>? tags,
    List<String>? peopleNames,
  }) async {
    final textParts = <String>[];
    
    // Add filename (cleaned)
    textParts.add(_cleanText(asset.fileName));
    
    // Add description
    if (description != null) {
      textParts.add(_cleanText(description));
    }
    
    // Add caption
    if (caption != null) {
      textParts.add(_cleanText(caption));
    }
    
    // Add tags
    if (tags != null) {
      textParts.addAll(tags.map(_cleanText));
    }
    
    // Add location context
    if (asset.location != null) {
      textParts.add(_getLocationContext(asset.location!));
    }
    
    // Add date context
    textParts.add(_getDateContext(asset.createdAt));
    
    // Add people
    if (peopleNames != null) {
      textParts.addAll(peopleNames);
    }
    
    // Generate tokens
    final tokens = _tokenize(textParts.join(' '));
    
    // Calculate TF-IDF scores
    final tfidfScores = _calculateTFIDF(tokens);
    
    // Generate keywords
    final keywords = _extractKeywords(tfidfScores);
    
    return SearchableContent(
      id: asset.id,
      type: 'media',
      originalText: textParts.join(' '),
      tokens: tokens,
      keywords: keywords,
      tfidfScores: tfidfScores,
      metadata: {
        'date': asset.createdAt.toIso8601String(),
        'location': asset.location?.toString(),
        'peopleCount': peopleNames?.length ?? 0,
      },
    );
  }

  /// Generate searchable content from timeline event
  Future<SearchableContent> generateFromTimelineEvent(
    TimelineEvent event, {
    List<String>? peopleNames,
  }) async {
    final textParts = <String>[];
    
    // Add title
    textParts.add(_cleanText(event.title));
    
    // Add description
    if (event.description != null) {
      textParts.add(_cleanText(event.description!));
    }
    
    // Add tags
    textParts.addAll(event.tags.map(_cleanText));
    
    // Add event type context
    textParts.add(_getEventTypeContext(event.type));
    
    // Add location context
    if (event.location != null) {
      textParts.add(event.location!.name ?? '');
    }
    
    // Add date context
    textParts.add(_getDateContext(event.startDate));
    
    // Add duration context
    if (event.endDate != null) {
      textParts.add(_getDurationContext(event.startDate, event.endDate!));
    }
    
    // Add people
    if (peopleNames != null) {
      textParts.addAll(peopleNames);
    }
    
    // Generate tokens
    final tokens = _tokenize(textParts.join(' '));
    
    // Calculate TF-IDF scores
    final tfidfScores = _calculateTFIDF(tokens);
    
    // Generate keywords
    final keywords = _extractKeywords(tfidfScores);
    
    return SearchableContent(
      id: event.id,
      type: 'event',
      originalText: textParts.join(' '),
      tokens: tokens,
      keywords: keywords,
      tfidfScores: tfidfScores,
      metadata: {
        'eventType': event.type.toString(),
        'date': event.startDate.toIso8601String(),
        'duration': event.endDate?.difference(event.startDate).inHours,
        'peopleCount': peopleNames?.length ?? 0,
      },
    );
  }

  // =========================================================================
  // TOKENIZATION AND PROCESSING
  // =========================================================================

  List<String> _tokenize(String text) {
    // Convert to lowercase and split into words
    final words = text.toLowerCase().replaceAll(RegExp(r'[^\w\s]'), '').split(' ');
    
    // Filter stop words and short words
    final tokens = <String>[];
    for (final word in words) {
      if (word.length > 2 && !_stopWords.contains(word)) {
        tokens.add(word);
      }
    }
    
    // Apply stemming (simple rule-based)
    return tokens.map(_applyStemming).toList();
  }

  String _applyStemming(String word) {
    // Simple stemming rules
    if (word.endsWith('ing')) {
      return word.substring(0, word.length - 3);
    } else if (word.endsWith('ed')) {
      return word.substring(0, word.length - 2);
    } else if (word.endsWith('ly')) {
      return word.substring(0, word.length - 2);
    } else if (word.endsWith('s') && word.length > 3) {
      return word.substring(0, word.length - 1);
    }
    return word;
  }

  String _cleanText(String text) {
    // Remove special characters but keep spaces
    return text.replaceAll(RegExp(r'[^\w\s]'), ' ').replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  // =========================================================================
  // TF-IDF CALCULATION
  // =========================================================================

  Map<String, double> _calculateTFIDF(List<String> tokens) {
    final tfidf = <String, double>{};
    final tokenCounts = <String, int>{};
    
    // Calculate term frequency
    for (final token in tokens) {
      tokenCounts[token] = (tokenCounts[token] ?? 0) + 1;
    }
    
    // Calculate TF-IDF for each token
    for (final entry in tokenCounts.entries) {
      final token = entry.key;
      final tf = entry.value / tokens.length;
      final idf = _getIDF(token);
      final weight = _termWeights[token] ?? 1.0;
      
      tfidf[token] = tf * idf * weight;
    }
    
    return tfidf;
  }

  double _getIDF(String term) {
    // Use cache if available
    if (_idfCache.containsKey(term)) {
      return _idfCache[term]!;
    }
    
    // Calculate IDF
    final df = _documentFrequency[term] ?? 1;
    final idf = log(_totalDocuments / df);
    
    // Cache result
    _idfCache[term] = idf;
    
    return idf;
  }

  List<String> _extractKeywords(Map<String, double> tfidfScores) {
    // Sort by score and return top keywords
    final sortedEntries = tfidfScores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    return sortedEntries
        .take(10) // Top 10 keywords
        .map((e) => e.key)
        .toList();
  }

  // =========================================================================
  // CONTEXT GENERATION
  // =========================================================================

  String _getLocationContext(LocationData location) {
    // Generate location-based keywords
    final context = <String>[];
    
    // Check for common location types
    if (_isBeachLocation(location)) {
      context.addAll(['beach', 'ocean', 'sea', 'sand', 'shore']);
    } else if (_isMountainLocation(location)) {
      context.addAll(['mountain', 'hiking', 'nature', 'trail']);
    } else if (_isCityLocation(location)) {
      context.addAll(['city', 'urban', 'downtown', 'street']);
    } else if (_isParkLocation(location)) {
      context.addAll(['park', 'green', 'trees', 'outdoors']);
    }
    
    return context.join(' ');
  }

  String _getDateContext(DateTime date) {
    final context = <String>[];
    
    // Add season
    context.add(_getSeason(date));
    
    // Add time of day
    context.add(_getTimeOfDay(date));
    
    // Add year
    context.add(date.year.toString());
    
    // Add month
    context.add(_getMonthName(date.month));
    
    // Add day context
    if (date.day == 25 && date.month == 12) {
      context.add('christmas');
    } else if (date.month == 7 && date.day == 4) {
      context.add('independence');
    }
    
    return context.join(' ');
  }

  String _getEventTypeContext(EventType type) {
    switch (type) {
      case EventType.birthday:
        return 'birthday party celebration cake gifts';
      case EventType.wedding:
        return 'wedding marriage bride groom ceremony reception';
      case EventType.vacation:
        return 'vacation travel trip holiday getaway';
      case eventType.holiday:
        return 'holiday festive celebration seasonal';
      case eventType.celebration:
        return 'celebration party festive happy joy';
      case eventType.travel:
        return 'travel journey trip adventure explore';
      default:
        return '';
    }
  }

  String _getDurationContext(DateTime start, DateTime end) {
    final duration = end.difference(start);
    
    if (duration.inDays > 0) {
      if (duration.inDays > 7) {
        return 'week-long extended';
      } else {
        return 'multi-day several days';
      }
    } else if (duration.inHours > 4) {
      return 'half-day long';
    } else {
      return 'brief short quick';
    }
  }

  // =========================================================================
  // LOCATION HELPERS
  // =========================================================================

  bool _isBeachLocation(LocationData location) {
    // Simple heuristic based on coordinates
    // In real implementation, would use reverse geocoding
    return false;
  }

  bool _isMountainLocation(LocationData location) {
    // Check elevation (would need elevation data)
    return false;
  }

  bool _isCityLocation(LocationData location) {
    // Check population density (would need external data)
    return false;
  }

  bool _isParkLocation(LocationData location) {
    // Check for park keywords in reverse geocoded name
    return false;
  }

  String _getSeason(DateTime date) {
    final month = date.month;
    if (month >= 3 && month <= 5) return 'spring';
    if (month >= 6 && month <= 8) return 'summer';
    if (month >= 9 && month <= 11) return 'fall';
    return 'winter';
  }

  String _getTimeOfDay(DateTime date) {
    final hour = date.hour;
    if (hour >= 6 && hour < 12) return 'morning';
    if (hour >= 12 && hour < 17) return 'afternoon';
    if (hour >= 17 && hour < 21) return 'evening';
    return 'night';
  }

  String _getMonthName(int month) {
    const months = [
      '', 'january', 'february', 'march', 'april', 'may', 'june',
      'july', 'august', 'september', 'october', 'november', 'december'
    ];
    return months[month];
  }

  // =========================================================================
  // BATCH PROCESSING
  // =========================================================================

  /// Process multiple items for batch indexing
  Future<List<SearchableContent>> processBatch(List<BatchProcessItem> items) async {
    final results = <SearchableContent>[];
    
    // Update document frequency for TF-IDF
    _totalDocuments += items.length;
    
    for (final item in items) {
      SearchableContent content;
      
      if (item.type == 'media' && item.mediaAsset != null) {
        content = await generateFromMediaAsset(
          item.mediaAsset!,
          caption: item.caption,
          description: item.description,
          tags: item.tags,
          peopleNames: item.peopleNames,
        );
      } else if (item.type == 'event' && item.timelineEvent != null) {
        content = await generateFromTimelineEvent(
          item.timelineEvent!,
          peopleNames: item.peopleNames,
        );
      } else {
        continue;
      }
      
      results.add(content);
      
      // Update document frequency
      for (final token in content.tokens) {
        _documentFrequency[token] = (_documentFrequency[token] ?? 0) + 1;
      }
    }
    
    return results;
  }

  // =========================================================================
  // MAINTENANCE
  // =========================================================================

  /// Clear all cached data
  void clearCache() {
    _documentFrequency.clear();
    _idfCache.clear();
    _totalDocuments = 0;
  }

  /// Save/load TF-IDF data (for persistence)
  Map<String, dynamic> exportData() {
    return {
      'documentFrequency': _documentFrequency,
      'totalDocuments': _totalDocuments,
    };
  }

  void importData(Map<String, dynamic> data) {
    _documentFrequency.clear();
    _documentFrequency.addAll(
      (data['documentFrequency'] as Map).cast<String, int>()
    );
    _totalDocuments = data['totalDocuments'] ?? 0;
    _idfCache.clear();
  }
}

// =========================================================================
// DATA MODELS
// =========================================================================

class SearchableContent {
  final String id;
  final String type;
  final String originalText;
  final List<String> tokens;
  final List<String> keywords;
  final Map<String, double> tfidfScores;
  final Map<String, dynamic> metadata;

  SearchableContent({
    required this.id,
    required this.type,
    required this.originalText,
    required this.tokens,
    required this.keywords,
    required this.tfidfScores,
    required this.metadata,
  });
}

class BatchProcessItem {
  final String type;
  final MediaAsset? mediaAsset;
  final TimelineEvent? timelineEvent;
  final String? caption;
  final String? description;
  final List<String>? tags;
  final List<String>? peopleNames;

  BatchProcessItem({
    required this.type,
    this.mediaAsset,
    this.timelineEvent,
    this.caption,
    this.description,
    this.tags,
    this.peopleNames,
  });
}

class LocationData {
  final double latitude;
  final double longitude;

  LocationData({required this.latitude, required this.longitude});
}

enum EventType {
  birthday,
  wedding,
  vacation,
  holiday,
  celebration,
  travel,
  general,
}

// =========================================================================
// PROVIDERS
// =========================================================================

final textEmbeddingProvider = Provider<TextEmbeddingService>((ref) {
  return TextEmbeddingService.instance;
});

// =========================================================================
// EXCEPTIONS
// =========================================================================

class TextEmbeddingException implements Exception {
  final String message;
  TextEmbeddingException(this.message);
  
  @override
  String toString() => 'TextEmbeddingException: $message';
}
