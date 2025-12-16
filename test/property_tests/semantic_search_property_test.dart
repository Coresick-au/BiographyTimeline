import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../../lib/shared/intelligence/semantic_search_service.dart';
import '../../lib/shared/intelligence/text_embedding_service.dart';
import '../../lib/shared/models/media_asset.dart';

/// Property 37: Semantic Search Relevance
/// 
/// This test validates that the semantic search system works correctly:
/// 1. FTS5 virtual table is properly configured
/// 2. Text embeddings are generated with TF-IDF
/// 3. Semantic expansion improves search results
/// 4. Search results are ranked by relevance
/// 5. Filters and suggestions work correctly
/// 6. Performance is acceptable for large datasets

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  
  // Initialize FFI for testing
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;
  
  group('Property 37: Semantic Search Relevance', () {
    late SemanticSearchService searchService;
    late TextEmbeddingService embeddingService;

    setUp(() async {
      searchService = SemanticSearchService.instance;
      embeddingService = TextEmbeddingService.instance;
      await searchService.initialize();
    });

    tearDown(() async {
      await searchService.close();
    });

    // =========================================================================
    // SEARCH SERVICE TESTS
    // =========================================================================
    
    test('Semantic search service initializes correctly', () async {
      expect(searchService.isInitialized, isTrue);
      expect(searchService.searchDb, isNotNull);
    });

    test('FTS5 virtual table is created', () async {
      final db = searchService.searchDb!;
      final tables = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='content_search'"
      );
      expect(tables, isNotEmpty);
      
      // Verify it's a virtual table
      final tableInfo = await db.rawQuery(
        "SELECT sql FROM sqlite_master WHERE name='content_search'"
      );
      final sql = tableInfo.first['sql'] as String;
      expect(sql, contains('VIRTUAL TABLE'));
      expect(sql, contains('USING fts5'));
    });

    test('Media asset is indexed correctly', () async {
      final asset = MediaAsset(
        id: 'test_media_1',
        eventId: 'test_event_1',
        type: AssetType.photo,
        localPath: '/path/to/photo.jpg',
        createdAt: DateTime(2023, 7, 15),
        width: 1920,
        height: 1080,
        isKeyAsset: false,
        mimeType: 'image/jpeg',
      );

      await searchService.indexMediaAsset(
        asset,
        caption: 'Beautiful sunset at the beach',
        description: 'Family vacation photos',
        tags: ['beach', 'sunset', 'family'],
        peopleNames: ['John', 'Jane'],
      );

      // Verify it was indexed
      final results = await searchService.search('beach');
      expect(results, hasLength(1));
      expect(results.first.id, equals('test_media_1'));
    });

    test('Timeline event is indexed correctly', () async {
      final event = TimelineEvent(
        id: 'test_event_1',
        title: 'Birthday Party',
        description: 'Celebrating with friends',
        startDate: DateTime(2023, 5, 20),
        tags: ['birthday', 'party'],
      );

      await searchService.indexTimelineEvent(
        event,
        peopleNames: ['Alice', 'Bob'],
      );

      // Verify it was indexed
      final results = await searchService.search('birthday');
      expect(results, hasLength(1));
      expect(results.first.id, equals('test_event_1'));
    });

    test('Batch indexing works correctly', () async {
      final items = [
        SearchIndexItem(
          id: 'batch_1',
          type: 'media',
          title: 'Camping Trip',
          description: 'Outdoor adventure',
          tags: ['camping', 'nature'],
          locationName: 'Yellowstone',
          dateText: 'July 2023',
        ),
        SearchIndexItem(
          id: 'batch_2',
          type: 'event',
          title: 'Wedding Ceremony',
          description: 'Marriage celebration',
          tags: ['wedding', 'love'],
          locationName: 'Church',
          dateText: 'June 2023',
        ),
      ];

      await searchService.indexBatch(items);

      final campingResults = await searchService.search('camping');
      final weddingResults = await searchService.search('wedding');

      expect(campingResults, hasLength(1));
      expect(campingResults.first.id, equals('batch_1'));
      expect(weddingResults, hasLength(1));
      expect(weddingResults.first.id, equals('batch_2'));
    });

    // =========================================================================
    // SEMANTIC EXPANSION TESTS
    // =========================================================================
    
    test('Semantic expansion improves search results', () async {
      // Index content with related terms
      await searchService.indexMediaAsset(
        MediaAsset(
          id: 'expansion_1',
          eventId: 'expansion_event_1',
          type: AssetType.photo,
          localPath: '/path/to/beach.jpg',
          isKeyAsset: false,
          createdAt: DateTime.now(),
          width: 1920,
          height: 1080,
          mimeType: 'image/jpeg',
        ),
        caption: 'Playing in the ocean waves',
        tags: ['ocean', 'water'],
      );

      // Search for expanded term
      final results = await searchService.search('beach');
      expect(results, isNotEmpty);
    });

    test('Time-based semantic expansion works', () async {
      // Index recent photo
      await searchService.indexMediaAsset(
        MediaAsset(
          id: 'time_1',
          eventId: 'event_time_1',
          type: AssetType.photo,
          localPath: '/path/to/recent.jpg',
          isKeyAsset: false,
          createdAt: DateTime.now().subtract(Duration(days: 1)),
          width: 1920,
          height: 1080,
          mimeType: 'image/jpeg',
        ),
        caption: 'Yesterday\'s adventure',
      );

      // Search with time term
      final results = await searchService.search('recent');
      expect(results, isNotEmpty);
    });

    // =========================================================================
    // SEARCH RELEVANCE TESTS
    // =========================================================================
    
    test('Search results are ranked by relevance', () async {
      // Index multiple items
      await searchService.indexMediaAsset(
        MediaAsset(
          id: 'relevance_1',
          eventId: 'event_rel_1',
          type: AssetType.photo,
          localPath: '/path/to/exact.jpg',
          isKeyAsset: false,
          createdAt: DateTime.now(),
          width: 1920,
          height: 1080,
          mimeType: 'image/jpeg',
        ),
        caption: 'Beach sunset',
      );

      await searchService.indexMediaAsset(
        MediaAsset(
          id: 'relevance_2',
          eventId: 'event_rel_2',
          type: AssetType.photo,
          localPath: '/path/to/partial.jpg',
          isKeyAsset: false,
          createdAt: DateTime.now(),
          width: 1920,
          height: 1080,
          mimeType: 'image/jpeg',
        ),
        caption: 'Mountain view',
      );

      await searchService.indexMediaAsset(
        MediaAsset(
          id: 'relevance_3',
          eventId: 'event_rel_3',
          type: AssetType.photo,
          localPath: '/path/to/related.jpg',
          isKeyAsset: false,
          createdAt: DateTime.now(),
          width: 1920,
          height: 1080,
          mimeType: 'image/jpeg',
        ),
        caption: 'Ocean waves',
      );

      // Search for beach
      final results = await searchService.search('beach');
      
      // Exact match should be first
      expect(results.first.title, contains('Beach'));
      
      // Results should be ordered by score
      expect(results.first.score, greaterThanOrEqualTo(results.last.score));
    });

    test('Search with filters works correctly', () async {
      // Index different types
      await searchService.indexMediaAsset(
        MediaAsset(
          id: 'filter_1',
          eventId: 'event_fil_1',
          type: AssetType.photo,
          isKeyAsset: false,
          localPath: '/path/to/photo.jpg',
          createdAt: DateTime.now(),
          width: 1920,
          height: 1080,
          mimeType: 'image/jpeg',
        ),
        caption: 'Family photo',
      );

      await searchService.indexTimelineEvent(
        TimelineEvent(
          id: 'filter_2',
          title: 'Family Reunion',
          startDate: DateTime.now(),
          tags: ['family'],
        ),
      );

      // Search with type filter
      final mediaResults = await searchService.search(
        'family',
        type: SearchType.media,
      );
      final eventResults = await searchService.search(
        'family',
        type: SearchType.event,
      );

      expect(mediaResults.every((r) => r.type == SearchType.media), isTrue);
      expect(eventResults.every((r) => r.type == SearchType.event), isTrue);
    });

    test('Search suggestions are generated', () async {
      // Index some content
      await searchService.indexMediaAsset(
        MediaAsset(
          id: 'suggest_1',
          eventId: 'event_sug_1',
          type: AssetType.photo,
          isKeyAsset: false,
          localPath: '/path/to/beach.jpg',
          createdAt: DateTime.now(),
          width: 1920,
          height: 1080,
          mimeType: 'image/jpeg',
        ),
        caption: 'Beach vacation',
      );

      // Get suggestions
      final suggestions = await searchService.getSuggestions('bea');
      expect(suggestions, isNotEmpty);
    });

    test('Trending searches are tracked', () async {
      // Perform some searches
      await searchService.search('vacation');
      await searchService.search('vacation');
      await searchService.search('family');

      // Get trending
      final trending = await searchService.getTrendingSearches();
      expect(trending, contains('vacation'));
    });

    // =========================================================================
    // TEXT EMBEDDING TESTS
    // =========================================================================
    
    test('Text embedding generates keywords correctly', () async {
      final asset = MediaAsset(
          id: 'embed_1',
          eventId: 'event_emb_1',
          type: AssetType.photo,
          isKeyAsset: false,
          localPath: '/path/to/photo.jpg',
          createdAt: DateTime(2023, 7, 15),
          width: 1920,
          height: 1080,
          mimeType: 'image/jpeg',
      );

      final content = await embeddingService.generateFromMediaAsset(
        asset,
        caption: 'Beautiful beach sunset with family',
        description: 'Summer vacation at the ocean',
        tags: ['beach', 'sunset', 'summer'],
        peopleNames: ['John', 'Jane'],
      );

      expect(content.keywords, isNotEmpty);
      expect(content.keywords, contains('beach'));
      expect(content.keywords, contains('sunset'));
      expect(content.tfidfScores, isNotEmpty);
    });

    test('TF-IDF scores are calculated correctly', () async {
      embeddingService.clearCache();
      
      // Process multiple documents
      final items = [
        BatchProcessItem(
          type: 'media',
          mediaAsset: MediaAsset(
            id: 'tfidf_1',
            eventId: 'event_tfidf_1',
            type: AssetType.photo,
            isKeyAsset: false,
            localPath: '/path/to/photo1.jpg',
            createdAt: DateTime.now(),
            width: 1920,
            height: 1080,
            mimeType: 'image/jpeg',
          ),
          caption: 'Beach vacation',
        ),
        BatchProcessItem(
          type: 'media',
          mediaAsset: MediaAsset(
            id: 'tfidf_2',
            eventId: 'event_tfidf_2',
            type: AssetType.photo,
            isKeyAsset: false,
            localPath: '/path/to/photo2.jpg',
            createdAt: DateTime.now(),
            width: 1920,
            height: 1080,
            mimeType: 'image/jpeg',
          ),
          caption: 'Mountain hiking',
        ),
      ];

      await embeddingService.processBatch(items);
      
      // Verify TF-IDF was calculated
      expect(embeddingService._totalDocuments, equals(2));
      expect(embeddingService._documentFrequency, isNotEmpty);
    });

    test('Custom term weights are applied', () async {
      final content = await embeddingService.generateFromMediaAsset(
        MediaAsset(
          id: 'weight_1',
          eventId: 'event_wgh_1',
          type: AssetType.photo,
          isKeyAsset: false,
          localPath: '/path/to/photo.jpg',
          createdAt: DateTime.now(),
          width: 1920,
          height: 1080,
          mimeType: 'image/jpeg',
        ),
        caption: 'Birthday celebration',
      );

      // Birthday should have higher weight
      expect(content.tfidfScores['birthday'], greaterThan(1.0));
    });

    test('Stop words are filtered out', () async {
      final content = await embeddingService.generateFromMediaAsset(
        MediaAsset(
          id: 'stop_1',
          eventId: 'event_stop_1',
          type: AssetType.photo,
          isKeyAsset: false,
          localPath: '/path/to/photo.jpg',
          createdAt: DateTime.now(),
          width: 1920,
          height: 1080,
          mimeType: 'image/jpeg',
        ),
        caption: 'The beautiful beach and the ocean',
      );

      expect(content.tokens, isNot(contains('the')));
      expect(content.tokens, isNot(contains('and')));
      expect(content.tokens, contains('beautiful'));
      expect(content.tokens, contains('beach'));
    });

    // =========================================================================
    // PERFORMANCE TESTS
    // =========================================================================
    
    test('Search performance is acceptable', () async {
      final stopwatch = Stopwatch()..start();
      
      // Index 100 items
      for (int i = 0; i < 100; i++) {
        await searchService.indexMediaAsset(
          MediaAsset(
            id: 'perf_$i',
            eventId: 'event_perf_$i',
            type: AssetType.photo,
            isKeyAsset: false,
            localPath: '/path/to/photo$i.jpg',
            createdAt: DateTime.now(),
            width: 1920,
            height: 1080,
            mimeType: 'image/jpeg',
          ),
          caption: 'Test photo number $i',
        );
      }
      
      final indexTime = stopwatch.elapsedMilliseconds;
      stopwatch.reset();
      
      // Perform search
      await searchService.search('test');
      
      final searchTime = stopwatch.elapsedMilliseconds;
      
      // Both operations should be fast
      expect(indexTime, lessThan(5000)); // 5 seconds for 100 items
      expect(searchTime, lessThan(500)); // 500ms for search
    });

    // =========================================================================
    // EDGE CASE TESTS
    // =========================================================================
    
    test('Empty query returns no results', () async {
      final results = await searchService.search('');
      expect(results, isEmpty);
    });

    test('Special characters are handled correctly', () async {
      await searchService.indexMediaAsset(
        MediaAsset(
          id: 'special_1',
          eventId: 'event_spec_1',
          type: AssetType.photo,
          isKeyAsset: false,
          localPath: '/path/to/photo.jpg',
          createdAt: DateTime.now(),
          width: 1920,
          height: 1080,
          mimeType: 'image/jpeg',
        ),
        caption: 'Beach & Ocean! #vacation',
      );

      final results = await searchService.search('beach ocean');
      expect(results, isNotEmpty);
    });

    test('Unicode characters are supported', () async {
      await searchService.indexMediaAsset(
        MediaAsset(
          id: 'unicode_1',
          eventId: 'event_uni_1',
          type: AssetType.photo,
          isKeyAsset: false,
          localPath: '/path/to/photo.jpg',
          createdAt: DateTime.now(),
          width: 1920,
          height: 1080,
          mimeType: 'image/jpeg',
        ),
        caption: 'Café ☕️ in Paris 🗼',
      );

      final results = await searchService.search('café');
      expect(results, isNotEmpty);
    });

    // =========================================================================
    // INTEGRATION TESTS
    // =========================================================================
    
    test('Full search workflow works end-to-end', () async {
      // 1. Create and index content
      final asset = MediaAsset(
        id: 'workflow_1',
        eventId: 'event_work_1',
        type: AssetType.photo,
        isKeyAsset: false,
        localPath: '/path/to/vacation.jpg',
        createdAt: DateTime(2023, 7, 15),
        width: 1920,
        height: 1080,
        mimeType: 'image/jpeg',
      );

      // 2. Generate embeddings
      final content = await embeddingService.generateFromMediaAsset(
        asset,
        caption: 'Amazing beach sunset during summer vacation',
        tags: ['beach', 'sunset', 'vacation'],
      );

      // 3. Index for search
      await searchService.indexMediaAsset(
        asset,
        caption: content.originalText,
        tags: content.keywords,
      );

      // 4. Search with natural language
      final results = await searchService.search('beach vacation');
      
      // 5. Verify results
      expect(results, hasLength(1));
      expect(results.first.id, equals('workflow_1'));
      expect(results.first.highlights, isNotEmpty);
    });

    // =========================================================================
    // MAINTENANCE TESTS
    // =========================================================================
    
    test('Search history can be cleared', () async {
      // Perform search to create history
      await searchService.search('test');
      
      // Clear history
      await searchService.clearHistory();
      
      // Verify history is empty
      final trending = await searchService.getTrendingSearches();
      expect(trending, isEmpty);
    });

    test('Index can be rebuilt', () async {
      // Index some content
      await searchService.indexMediaAsset(
        MediaAsset(
          id: 'rebuild_1',
          eventId: 'event_reb_1',
          type: AssetType.photo,
          isKeyAsset: false,
          localPath: '/path/to/photo.jpg',
          createdAt: DateTime.now(),
          width: 1920,
          height: 1080,
          mimeType: 'image/jpeg',
        ),
        caption: 'Test content',
      );

      // Rebuild index
      await searchService.rebuildIndex();
      
      // Verify table still exists
      final db = searchService.searchDb!;
      final tables = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='content_search'"
      );
      expect(tables, isNotEmpty);
    });
  });
}

// Helper classes for testing
class TimelineEvent {
  final String id;
  final String title;
  final String? description;
  final DateTime startDate;
  final DateTime? endDate;
  final List<String> tags;

  TimelineEvent({
    required this.id,
    required this.title,
    this.description,
    required this.startDate,
    this.endDate,
    required this.tags,
  });
}

class LocationData {
  final double latitude;
  final double longitude;

  LocationData({required this.latitude, required this.longitude});
}
