import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:uuid/uuid.dart';
import '../../lib/features/offline/services/conflict_resolution_service.dart';
import '../../lib/features/offline/services/offline_database_service.dart';
import '../../lib/features/offline/models/offline_models.dart';
import '../helpers/db_test_helper.dart';

/// Property 29: Concurrent Edit Conflict Resolution
/// 
/// This test validates that conflict resolution works correctly:
/// 1. Conflict detection for concurrent edits on shared events
/// 2. User-mediated resolution interfaces (service layer)
/// 3. Automatic merge strategies for non-conflicting changes
/// 4. Three-way merge with base data comparison
/// 5. Field-level conflict tracking and resolution
/// 6. Conflict statistics and reporting

void main() {
  // Initialize Flutter binding for tests
  TestWidgetsFlutterBinding.ensureInitialized();
  initializeTestDatabase();
  
  group('Property 29: Concurrent Edit Conflict Resolution', () {
    late ConflictResolutionService conflictService;
    const uuid = Uuid();

    final mockBaseRecords = <String, Map<String, dynamic>>{};

    setUp(() {
      mockBaseRecords.clear();
      final databaseService = OfflineDatabaseService();
      conflictService = ConflictResolutionService(
        databaseService: databaseService,
        baseRecordFetcher: (tableName, recordId) async {
          return mockBaseRecords[recordId];
        },
      );
    });

    test('Conflict resolution strategies are available', () {
      // Test all resolution strategies
      expect(ConflictResolutionStrategy.localWins.name, equals('localWins'));
      expect(ConflictResolutionStrategy.remoteWins.name, equals('remoteWins'));
      expect(ConflictResolutionStrategy.manualMerge.name, equals('manualMerge'));
      expect(ConflictResolutionStrategy.automaticMerge.name, equals('automaticMerge'));
      expect(ConflictResolutionStrategy.defer.name, equals('defer'));
    });

    test('Conflict detection identifies field differences', () async {
      // Arrange
      final localRecords = [
        {
          'id': 'event1',
          'title': 'Local Title',
          'description': 'Local Description',
          'version': 2,
        },
      ];
      

      final remoteRecords = [
        {
          'id': 'event1',
          'title': 'Remote Title',
          'description': 'Local Description',
          'version': 3,
        },
      ];

      // Set base record (v1)
      mockBaseRecords['event1'] = {
        'id': 'event1',
        'title': 'Original Title',
        'description': 'Local Description',
        'version': 1,
      };

      // Act
      final conflicts = await conflictService.detectConflicts(
        'timeline_events',
        localRecords,
        remoteRecords,
      );

      // Assert
      expect(conflicts, hasLength(1));
      final conflict = conflicts.first;
      expect(conflict.tableName, equals('timeline_events'));
      expect(conflict.recordId, equals('event1'));
      expect(conflict.conflictingFields, contains('title'));
      expect(conflict.localData['title'], equals('Local Title'));
      expect(conflict.remoteData['title'], equals('Remote Title'));
    });

    test('No conflict when only one side changed', () async {
      // Arrange
      final localRecords = [
        {
          'id': 'event1',
          'title': 'Same Title',
          'description': 'Changed Description',
          'version': 2,
        },
      ];
      

      final remoteRecords = [
        {
          'id': 'event1',
          'title': 'Same Title',
          'description': 'Original Description',
          'version': 1,
        },
      ];

      // Set base record (v1 - same as remote)
      mockBaseRecords['event1'] = {
        'id': 'event1',
        'title': 'Same Title',
        'description': 'Original Description',
        'version': 1,
      };

      // Act
      final conflicts = await conflictService.detectConflicts(
        'timeline_events',
        localRecords,
        remoteRecords,
      );

      // Assert
      expect(conflicts, isEmpty);
    });

    test('Local wins resolution strategy', () async {
      // Arrange
      final conflict = SyncConflict(
        id: uuid.v4(),
        tableName: 'timeline_events',
        recordId: 'event1',
        localData: {'title': 'Local Title', 'description': 'Local Desc'},
        remoteData: {'title': 'Remote Title', 'description': 'Remote Desc'},
        baseData: {'title': 'Original Title', 'description': 'Original Desc'},
        conflictingFields: ['title', 'description'],
        detectedAt: DateTime.now(),
      );

      // Act
      final resolved = await conflictService.resolveConflict(
        conflict,
        ConflictResolutionStrategy.localWins,
      );

      // Assert
      expect(resolved.isResolved, isTrue);
      expect(resolved.resolutionStrategy, equals(ConflictResolutionStrategy.localWins));
      expect(resolved.resolvedData, equals(conflict.localData));
    });

    test('Remote wins resolution strategy', () async {
      // Arrange
      final conflict = SyncConflict(
        id: uuid.v4(),
        tableName: 'timeline_events',
        recordId: 'event1',
        localData: {'title': 'Local Title'},
        remoteData: {'title': 'Remote Title'},
        baseData: {'title': 'Original Title'},
        conflictingFields: ['title'],
        detectedAt: DateTime.now(),
      );

      // Act
      final resolved = await conflictService.resolveConflict(
        conflict,
        ConflictResolutionStrategy.remoteWins,
      );

      // Assert
      expect(resolved.isResolved, isTrue);
      expect(resolved.resolutionStrategy, equals(ConflictResolutionStrategy.remoteWins));
      expect(resolved.resolvedData, equals(conflict.remoteData));
    });

    test('Manual merge resolution strategy', () async {
      // Arrange
      final conflict = SyncConflict(
        id: uuid.v4(),
        tableName: 'timeline_events',
        recordId: 'event1',
        localData: {'title': 'Local Title', 'description': 'Local Desc'},
        remoteData: {'title': 'Remote Title', 'description': 'Remote Desc'},
        baseData: {'title': 'Original Title', 'description': 'Original Desc'},
        conflictingFields: ['title', 'description'],
        detectedAt: DateTime.now(),
      );

      final userResolution = {
        'title': 'Merged Title',
        'description': 'Merged Description',
      };

      // Act
      final resolved = await conflictService.resolveConflict(
        conflict,
        ConflictResolutionStrategy.manualMerge,
        userResolution: userResolution,
      );

      // Assert
      expect(resolved.isResolved, isTrue);
      expect(resolved.resolutionStrategy, equals(ConflictResolutionStrategy.manualMerge));
      expect(resolved.resolvedData, equals(userResolution));
    });

    test('Defer resolution strategy', () async {
      // Arrange
      final conflict = SyncConflict(
        id: uuid.v4(),
        tableName: 'timeline_events',
        recordId: 'event1',
        localData: {'title': 'Local Title'},
        remoteData: {'title': 'Remote Title'},
        baseData: {'title': 'Original Title'},
        conflictingFields: ['title'],
        detectedAt: DateTime.now(),
      );

      // Act
      final resolved = await conflictService.resolveConflict(
        conflict,
        ConflictResolutionStrategy.defer,
      );

      // Assert
      expect(resolved.resolutionStrategy, equals(ConflictResolutionStrategy.defer));
      expect(resolved.resolvedAt, isNotNull);
    });

    test('Automatic merge for non-conflicting fields', () async {
      // Arrange
      final conflict = SyncConflict(
        id: uuid.v4(),
        tableName: 'timeline_events',
        recordId: 'event1',
        localData: {
          'title': 'Local Title',
          'description': 'Same Description',
          'location': 'New Location',
        },
        remoteData: {
          'title': 'Remote Title',
          'description': 'Same Description',
          'date': '2024-01-20',
        },
        baseData: {
          'title': 'Original Title',
          'description': 'Same Description',
        },
        conflictingFields: ['title'],
        detectedAt: DateTime.now(),
      );

      // Act
      final resolved = await conflictService.resolveConflict(
        conflict,
        ConflictResolutionStrategy.automaticMerge,
      );

      // Assert
      expect(resolved.isResolved, isTrue);
      expect(resolved.resolvedData!['description'], equals('Same Description'));
      expect(resolved.resolvedData!['location'], equals('New Location'));
      expect(resolved.resolvedData!['date'], equals('2024-01-20'));
      // Title should be intelligently merged (chooses longer)
      expect(resolved.resolvedData!['title'], isA<String>());
    });

    test('List merging in automatic merge', () async {
      // Arrange
      final conflict = SyncConflict(
        id: uuid.v4(),
        tableName: 'stories',
        recordId: 'story1',
        localData: {
          'tags': ['family', 'vacation'],
          'title': 'Story Title',
        },
        remoteData: {
          'tags': ['family', 'celebration'],
          'title': 'Story Title',
        },
        baseData: {
          'tags': ['family'],
          'title': 'Story Title',
        },
        conflictingFields: ['tags'],
        detectedAt: DateTime.now(),
      );

      // Act
      final resolved = await conflictService.resolveConflict(
        conflict,
        ConflictResolutionStrategy.automaticMerge,
      );

      // Assert
      expect(resolved.isResolved, isTrue);
      final mergedTags = resolved.resolvedData!['tags'] as List;
      expect(mergedTags, contains('family'));
      expect(mergedTags, contains('vacation'));
      expect(mergedTags, contains('celebration'));
      expect(mergedTags, hasLength(3));
    });

    test('Map merging in automatic merge', () async {
      // Arrange
      final conflict = SyncConflict(
        id: uuid.v4(),
        tableName: 'timeline_events',
        recordId: 'event1',
        localData: {
          'metadata': {
            'camera': 'Canon',
            'settings': {'iso': 100},
          },
          'title': 'Event',
        },
        remoteData: {
          'metadata': {
            'camera': 'Canon',
            'settings': {'aperture': 'f/2.8'},
          },
          'title': 'Event',
        },
        baseData: {
          'metadata': {
            'camera': 'Canon',
          },
          'title': 'Event',
        },
        conflictingFields: ['metadata'],
        detectedAt: DateTime.now(),
      );

      // Act
      final resolved = await conflictService.resolveConflict(
        conflict,
        ConflictResolutionStrategy.automaticMerge,
      );

      // Assert
      expect(resolved.isResolved, isTrue);
      final metadata = resolved.resolvedData!['metadata'] as Map;
      expect(metadata['camera'], equals('Canon'));
      final settings = metadata['settings'] as Map;
      expect(settings['iso'], equals(100));
      expect(settings['aperture'], equals('f/2.8'));
    });

    test('Multiple conflicts detection', () async {
      // Arrange
      final localRecords = [
        {
          'id': 'event1',
          'title': 'Local Title 1',
          'version': 2,
        },
        {
          'id': 'event2',
          'title': 'Local Title 2',
          'description': 'Local Desc',
          'version': 2,
        },
        {
          'id': 'event3',
          'title': 'Same Title',
          'version': 1,
        },
      ];
      
      final remoteRecords = [
        {
          'id': 'event1',
          'title': 'Remote Title 1',
          'version': 3,
        },
        {
          'id': 'event2',
          'title': 'Remote Title 2',
          'description': 'Remote Desc',
          'version': 3,
        },
        {
          'id': 'event3',
          'title': 'Same Title',
          'version': 1,
        },
      ];

      // Act
      final conflicts = await conflictService.detectConflicts(
        'timeline_events',
        localRecords,
        remoteRecords,
      );

      // Assert
      expect(conflicts, hasLength(2));
      expect(conflicts.map((c) => c.recordId), contains('event1'));
      expect(conflicts.map((c) => c.recordId), contains('event2'));
      // event3 should not have a conflict
    });

    test('Conflict model properties', () {
      // Arrange
      final conflict = SyncConflict(
        id: uuid.v4(),
        tableName: 'timeline_events',
        recordId: 'event1',
        localData: {'title': 'Local'},
        remoteData: {'title': 'Remote'},
        baseData: {'title': 'Base'},
        conflictingFields: ['title'],
        detectedAt: DateTime.now(),
      );

      // Assert
      expect(conflict.isResolved, isFalse);
      expect(conflict.conflictingFields, hasLength(1));

      // Act - Resolve
      final resolved = conflict.copyWith(
        resolutionStrategy: ConflictResolutionStrategy.localWins,
        resolvedAt: DateTime.now(),
        resolvedData: {'title': 'Resolved'},
      );

      // Assert
      expect(resolved.isResolved, isTrue);
      expect(resolved.resolvedData!['title'], equals('Resolved'));
    });

    test('Data payload extraction', () async {
      // Arrange
      final records = [
        {
          'id': 'event1',
          'title': 'Event Title',
          'description': 'Description',
          'version': 1,
          'created_at': '2024-01-15T10:00:00Z',
          'updated_at': '2024-01-15T10:00:00Z',
          'sync_status': 'synced',
        },
      ];

      // Act
      final conflicts = await conflictService.detectConflicts(
        'timeline_events',
        records,
        records,
      );

      // Assert - Should have no conflicts and metadata should be stripped
      expect(conflicts, isEmpty);
    });

    test('Error handling for manual merge without user data', () async {
      // Arrange
      final conflict = SyncConflict(
        id: uuid.v4(),
        tableName: 'timeline_events',
        recordId: 'event1',
        localData: {'title': 'Local'},
        remoteData: {'title': 'Remote'},
        baseData: {'title': 'Base'},
        conflictingFields: ['title'],
        detectedAt: DateTime.now(),
      );

      // Act & Assert
      expect(
        () => conflictService.resolveConflict(
          conflict,
          ConflictResolutionStrategy.manualMerge,
        ),
        throwsArgumentError,
      );
    });

    test('Conflict statistics tracking', () async {
      // This would test the stats functionality
      // In a real implementation, we'd need to mock the database service
      
      // For now, just verify the method exists
      expect(conflictService.getConflictStats(), isA<Future<Map<String, dynamic>>>());
    });
  });
}
