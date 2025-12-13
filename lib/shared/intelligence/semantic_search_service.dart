import 'dart:async';
import 'dart:collection';
import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqlite3_flutter_libs/sqlite3_flutter_libs.dart';
import 'package:path/path.dart';
import '../database/database_service.dart';
import '../models/media_asset.dart';
import '../models/timeline_event.dart';

/// Semantic search service using SQLite FTS5 with TF-IDF and semantic expansion
/// Provides offline natural language search for timeline content
class SemanticSearchService {
  static SemanticSearchService? _instance;
  static SemanticSearchService get instance => _instance ??= SemanticSearchService._();
  
  SemanticSearchService._();

  Database? _searchDb;
  bool _isInitialized = false;

  // Semantic expansion mappings
  static const Map<String, List<String>> _semanticMap = {
    'beach': ['ocean', 'sea', 'sand', 'shore', 'waves', 'coast', 'waterfront'],
    'sunset': ['dusk', 'golden', 'evening', 'twilight', 'sunrise', 'dawn'],
    'camping': ['tent', 'outdoors', 'nature', 'wilderness', 'hiking', 'forest'],
    'birthday': ['party', 'celebration', 'cake', 'presents', 'festive'],
    'wedding': ['marriage', 'bride', 'groom', 'ceremony', 'reception'],
    'vacation': ['holiday', 'trip', 'travel', 'journey', 'getaway'],
    'family': ['parents', 'children', 'relatives', 'together', 'home'],
    'friends': ['buddies', 'companions', 'social', 'gather', 'group'],
    'food': ['dining', 'meal', 'restaurant', 'cooking', 'eat'],
    'sports': ['game', 'match', 'play', 'athletic', 'competition'],
    'music': ['concert', 'song', 'dance', 'performance', 'show'],
    'winter': ['snow', 'cold', 'ice', 'frost', 'chilly'],
    'summer': ['hot', 'warm', 'sunny', 'heat', 'bright'],
    'christmas': ['xmas', 'holiday', 'festive', 'gifts', 'decorations'],
    'park': ['nature', 'trees', 'grass', 'outdoors', 'recreation'],
  };

  static const Map<String, List<String>> _timeMap = {
    'recent': ['today', 'yesterday', 'this week', 'last week'],
    'old': ['years ago', 'long ago', 'childhood', 'back then'],
    'season': ['spring', 'summer', 'fall', 'autumn', 'winter'],
    'year': ['2020', '2021', '2022', '2023', '2024'],
  };

  // =========================================================================
  // INITIALIZATION
  // =========================================================================

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      final dbPath = await getDatabasesPath();
      final path = join(dbPath, 'semantic_search.db');

      // Initialize with FTS5 support
      _searchDb = await openDatabase(
        path,
        version: 1,
        onCreate: _createSearchTables,
        onConfigure: _configureDatabase,
      );

      _isInitialized = true;
    } catch (e) {
      throw SemanticSearchException('Failed to initialize semantic search: $e');
    }
  }

  Future<void> _configureDatabase(Database db) async {
    // Enable FTS5
    await db.execute('PRAGMA journal_mode = WAL');
    await db.execute('PRAGMA synchronous = NORMAL');
    await db.execute('PRAGMA cache_size = 10000');
  }

  Future<void> _createSearchTables(Database db, int version) async {
    // Create FTS5 virtual table for content search
    await db.execute('''
      CREATE VIRTUAL TABLE content_search USING fts5(
        id UNINDEXED,
        type UNINDEXED,
        title,
        description,
        caption,
        tags,
        location_name,
        event_type,
        date_text,
        people_names,
        content,
        tokenize = 'porter unicode61'
      )
    ''');

    // Create index for quick lookups
    await db.execute('CREATE INDEX idx_content_search_id ON content_search(id)');
    await db.execute('CREATE INDEX idx_content_search_type ON content_search(type)');

    // Create semantic expansion table
    await db.execute('''
      CREATE TABLE semantic_expansions (
        term TEXT PRIMARY KEY,
        expansions TEXT,
        weight REAL DEFAULT 1.0
      )
    ''');

    // Create search history table
    await db.execute('''
      CREATE TABLE search_history (
        id TEXT PRIMARY KEY,
        query TEXT,
        results_count INTEGER,
        timestamp INTEGER,
        selected_result_id TEXT
      )
    ''');

    // Populate semantic expansions
    await _populateSemanticExpansions(db);
  }

  Future<void> _populateSemanticExpansions(Database db) async {
    final batch = db.batch();
    
    for (final entry in _semanticMap.entries) {
      batch.insert('semantic_expansions', {
        'term': entry.key,
        'expansions': entry.value.join(','),
        'weight': 0.8,
      });
    }
    
    for (final entry in _timeMap.entries) {
      batch.insert('semantic_expansions', {
        'term': entry.key,
        'expansions': entry.value.join(','),
        'weight': 0.9,
      });
    }
    
    await batch.commit();
  }

  // =========================================================================
  // INDEXING
  // =========================================================================

  /// Index a media asset for search
  Future<void> indexMediaAsset(MediaAsset asset, {
    String? caption,
    String? description,
    List<String>? tags,
    List<String>? peopleNames,
  }) async {
    await ensureInitialized();

    final content = _buildSearchContent(
      title: asset.fileName,
      description: description,
      caption: caption,
      tags: tags,
      locationName: _getLocationName(asset.location),
      eventType: null,
      dateText: _formatDateForSearch(asset.createdAt),
      peopleNames: peopleNames,
    );

    await _searchDb!.insert(
      'content_search',
      {
        'id': asset.id,
        'type': 'media',
        'title': asset.fileName,
        'description': description ?? '',
        'caption': caption ?? '',
        'tags': tags?.join(' ') ?? '',
        'location_name': _getLocationName(asset.location),
        'event_type': '',
        'date_text': _formatDateForSearch(asset.createdAt),
        'people_names': peopleNames?.join(' ') ?? '',
        'content': content,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Index a timeline event for search
  Future<void> indexTimelineEvent(TimelineEvent event, {
    List<String>? peopleNames,
  }) async {
    await ensureInitialized();

    final content = _buildSearchContent(
      title: event.title,
      description: event.description,
      caption: null,
      tags: event.tags,
      locationName: event.location?.name,
      eventType: event.type.toString(),
      dateText: _formatDateForSearch(event.startDate),
      peopleNames: peopleNames,
    );

    await _searchDb!.insert(
      'content_search',
      {
        'id': event.id,
        'type': 'event',
        'title': event.title,
        'description': event.description ?? '',
        'caption': '',
        'tags': event.tags.join(' '),
        'location_name': event.location?.name ?? '',
        'event_type': event.type.toString(),
        'date_text': _formatDateForSearch(event.startDate),
        'people_names': peopleNames?.join(' ') ?? '',
        'content': content,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Batch index multiple items
  Future<void> indexBatch(List<SearchIndexItem> items) async {
    await ensureInitialized();

    final batch = _searchDb!.batch();
    
    for (final item in items) {
      final content = _buildSearchContent(
        title: item.title,
        description: item.description,
        caption: item.caption,
        tags: item.tags,
        locationName: item.locationName,
        eventType: item.eventType,
        dateText: item.dateText,
        peopleNames: item.peopleNames,
      );

      batch.insert(
        'content_search',
        {
          'id': item.id,
          'type': item.type,
          'title': item.title,
          'description': item.description ?? '',
          'caption': item.caption ?? '',
          'tags': item.tags.join(' '),
          'location_name': item.locationName ?? '',
          'event_type': item.eventType ?? '',
          'date_text': item.dateText,
          'people_names': item.peopleNames?.join(' ') ?? '',
          'content': content,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    
    await batch.commit();
  }

  // =========================================================================
  // SEARCH
  // =========================================================================

  /// Perform semantic search
  Future<List<SearchResult>> search(String query, {
    int limit = 20,
    SearchType type = SearchType.all,
    List<String>? filters,
  }) async {
    await ensureInitialized();

    // Expand query with semantic terms
    final expandedQuery = await _expandQuery(query);
    
    // Build FTS5 query
    final ftsQuery = _buildFTSQuery(expandedQuery, filters);
    
    // Execute search
    final results = await _searchDb!.rawQuery('''
      SELECT 
        id,
        type,
        title,
        description,
        caption,
        tags,
        location_name,
        event_type,
        date_text,
        people_names,
        rank
      FROM content_search 
      WHERE content MATCH ? 
      ${type != SearchType.all ? 'AND type = ?' : ''}
      ORDER BY rank
      LIMIT ?
    ''', type != SearchType.all ? [ftsQuery, type.name, limit] : [ftsQuery, limit]);

    // Convert to SearchResult objects
    final searchResults = <SearchResult>[];
    for (final row in results) {
      searchResults.add(SearchResult(
        id: row['id'] as String,
        type: _parseSearchType(row['type'] as String),
        title: row['title'] as String,
        description: row['description'] as String?,
        caption: row['caption'] as String?,
        tags: (row['tags'] as String).split(' ').where((t) => t.isNotEmpty).toList(),
        locationName: row['location_name'] as String?,
        eventType: row['event_type'] as String?,
        dateText: row['date_text'] as String?,
        peopleNames: (row['people_names'] as String).split(' ').where((n) => n.isNotEmpty).toList(),
        score: (row['rank'] as num).toDouble(),
        highlights: _extractHighlights(query, row),
      ));
    }

    // Save to search history
    await _saveSearchHistory(query, searchResults.length);

    return searchResults;
  }

  /// Get search suggestions
  Future<List<String>> getSuggestions(String partialQuery) async {
    await ensureInitialized();

    if (partialQuery.length < 2) return [];

    final results = await _searchDb!.rawQuery('''
      SELECT DISTINCT title 
      FROM content_search 
      WHERE title MATCH ?*
      LIMIT 10
    ''', [partialQuery]);

    return results.map((row) => row['title'] as String).toList();
  }

  /// Get trending searches
  Future<List<String>> getTrendingSearches({int limit = 10}) async {
    await ensureInitialized();

    final results = await _searchDb!.rawQuery('''
      SELECT query, COUNT(*) as count
      FROM search_history
      WHERE timestamp > ?
      GROUP BY query
      ORDER BY count DESC
      LIMIT ?
    ''', [DateTime.now().subtract(Duration(days: 7)).millisecondsSinceEpoch, limit]);

    return results.map((row) => row['query'] as String).toList();
  }

  // =========================================================================
  // SEMANTIC EXPANSION
  // =========================================================================

  Future<String> _expandQuery(String query) async {
    final words = query.toLowerCase().split(' ');
    final expandedWords = <String>[];

    for (final word in words) {
      expandedWords.add(word);
      
      // Get semantic expansions
      final expansions = await _searchDb!.query(
        'semantic_expansions',
        where: 'term = ?',
        whereArgs: [word],
      );

      if (expansions.isNotEmpty) {
        final expansionList = (expansions.first['expansions'] as String).split(',');
        final weight = expansions.first['weight'] as double;
        
        // Add expansions with weight
        for (final expansion in expansionList) {
          if (weight > 0.7) {
            expandedWords.add(expansion.trim());
          }
        }
      }
    }

    return expandedWords.join(' OR ');
  }

  String _buildFTSQuery(String expandedQuery, List<String>? filters) {
    var query = expandedQuery;
    
    if (filters != null && filters.isNotEmpty) {
      final filterQuery = filters.map((f) => '$f:*').join(' OR ');
      query = '($query) AND ($filterQuery)';
    }
    
    return query;
  }

  // =========================================================================
  // UTILITY METHODS
  // =========================================================================

  String _buildSearchContent({
    required String title,
    String? description,
    String? caption,
    List<String>? tags,
    String? locationName,
    String? eventType,
    required String dateText,
    List<String>? peopleNames,
  }) {
    final parts = <String>[
      title,
      description ?? '',
      caption ?? '',
      tags?.join(' ') ?? '',
      locationName ?? '',
      eventType ?? '',
      dateText,
      peopleNames?.join(' ') ?? '',
    ];
    
    return parts.where((p) => p.isNotEmpty).join(' ');
  }

  String? _getLocationName(LocationData? location) {
    if (location == null) return null;
    // Would use reverse geocoding in real implementation
    return '${location.latitude.toStringAsFixed(2)}, ${location.longitude.toStringAsFixed(2)}';
  }

  String _formatDateForSearch(DateTime date) {
    return '${date.year} ${_monthName(date.month)} ${date.day}';
  }

  String _monthName(int month) {
    const months = [
      '', 'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return months[month];
  }

  SearchType _parseSearchType(String type) {
    switch (type.toLowerCase()) {
      case 'media':
        return SearchType.media;
      case 'event':
        return SearchType.event;
      default:
        return SearchType.all;
    }
  }

  List<String> _extractHighlights(String query, Map<String, dynamic> row) {
    final highlights = <String>[];
    final queryWords = query.toLowerCase().split(' ');
    
    for (final field in ['title', 'description', 'caption']) {
      final text = row[field] as String?;
      if (text != null) {
        for (final word in queryWords) {
          if (text.toLowerCase().contains(word)) {
            highlights.add(text);
            break;
          }
        }
      }
    }
    
    return highlights;
  }

  Future<void> _saveSearchHistory(String query, int resultsCount) async {
    await _searchDb!.insert('search_history', {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'query': query,
      'results_count': resultsCount,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
  }

  Future<void> ensureInitialized() async {
    if (!_isInitialized) {
      await initialize();
    }
  }

  // =========================================================================
  // MAINTENANCE
  // =========================================================================

  /// Rebuild search index
  Future<void> rebuildIndex() async {
    await ensureInitialized();
    
    // Drop and recreate tables
    await _searchDb!.execute('DROP TABLE IF EXISTS content_search');
    await _createSearchTables(_searchDb!, 1);
  }

  /// Clear search history
  Future<void> clearHistory() async {
    await ensureInitialized();
    await _searchDb!.delete('search_history');
  }

  /// Optimize search database
  Future<void> optimize() async {
    await ensureInitialized();
    await _searchDb!.execute('INSERT INTO content_search(content_search) VALUES(\'optimize\')');
  }

  Future<void> close() async {
    final db = _searchDb;
    if (db != null) {
      await db.close();
      _searchDb = null;
    }
  }
}

// =========================================================================
// DATA MODELS
// =========================================================================

class SearchResult {
  final String id;
  final SearchType type;
  final String title;
  final String? description;
  final String? caption;
  final List<String> tags;
  final String? locationName;
  final String? eventType;
  final String? dateText;
  final List<String> peopleNames;
  final double score;
  final List<String> highlights;

  SearchResult({
    required this.id,
    required this.type,
    required this.title,
    this.description,
    this.caption,
    required this.tags,
    this.locationName,
    this.eventType,
    this.dateText,
    required this.peopleNames,
    required this.score,
    required this.highlights,
  });
}

class SearchIndexItem {
  final String id;
  final String type;
  final String title;
  final String? description;
  final String? caption;
  final List<String> tags;
  final String? locationName;
  final String? eventType;
  final String dateText;
  final List<String>? peopleNames;

  SearchIndexItem({
    required this.id,
    required this.type,
    required this.title,
    this.description,
    this.caption,
    required this.tags,
    this.locationName,
    this.eventType,
    required this.dateText,
    this.peopleNames,
  });
}

enum SearchType {
  all,
  media,
  event,
}

class LocationData {
  final double latitude;
  final double longitude;

  LocationData({required this.latitude, required this.longitude});
}

// =========================================================================
// PROVIDERS
// =========================================================================

final semanticSearchProvider = Provider<SemanticSearchService>((ref) {
  return SemanticSearchService.instance;
});

final searchResultsProvider = FutureProvider.family<List<SearchResult>, String>((ref, query) async {
  return await SemanticSearchService.instance.search(query);
});

// =========================================================================
// EXCEPTIONS
// =========================================================================

class SemanticSearchException implements Exception {
  final String message;
  SemanticSearchException(this.message);
  
  @override
  String toString() => 'SemanticSearchException: $message';
}
