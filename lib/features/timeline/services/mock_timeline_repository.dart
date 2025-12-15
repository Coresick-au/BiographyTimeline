import 'package:uuid/uuid.dart';
import '../../../shared/models/timeline_event.dart';
import '../../../shared/models/context.dart';
import '../../../shared/models/media_asset.dart';

/// Mock repository for web testing (bypasses SQLite web issues)
class MockTimelineRepository {
  final _uuid = const Uuid();
  
  /// Returns sample timeline events for testing
  Future<List<TimelineEvent>> getEvents() async {
    // Simulate async delay
    await Future.delayed(const Duration(milliseconds: 100));
    
    final now = DateTime.now();
    
    return [
      TimelineEvent.create(
        id: _uuid.v4(),
        tags: ['Family', 'Milestone'],
        ownerId: 'user-1',
        timestamp: now.subtract(const Duration(days: 365)),
        eventType: 'milestone',
        title: 'Started Timeline Biography App',
        description: 'Beginning of an amazing journey to preserve family memories.',
        isPrivate: false,
      ),
      TimelineEvent.create(
        id: _uuid.v4(),
        tags: ['Family', 'Vacation'],
        ownerId: 'user-1',
        timestamp: now.subtract(const Duration(days: 180)),
        eventType: 'photo',
        title: 'Summer Beach Trip',
        description: 'Amazing family vacation at the coast. The kids loved building sandcastles!',
        assets: [
          MediaAsset.photo(
            id: _uuid.v4(),
            eventId: '',
            localPath: 'https://picsum.photos/400/300?random=1',
            createdAt: now.subtract(const Duration(days: 180)),
          ),
        ],
        isPrivate: false,
      ),
      TimelineEvent.create(
        id: _uuid.v4(),
        tags: ['Family', 'Birthday'],
        ownerId: 'user-1',
        timestamp: now.subtract(const Duration(days: 90)),
        eventType: 'photo',
        title: 'Emma\'s 10th Birthday',
        description: 'Double digits! Had a wonderful party with friends and family.',
        assets: [
          MediaAsset.photo(
            id: _uuid.v4(),
            eventId: '',
            localPath: 'https://picsum.photos/400/300?random=2',
            createdAt: now.subtract(const Duration(days: 90)),
          ),
        ],
        isPrivate: false,
      ),
      TimelineEvent.create(
        id: _uuid.v4(),
        tags: ['Family'],
        ownerId: 'user-1',
        timestamp: now.subtract(const Duration(days: 30)),
        eventType: 'text',
        title: 'Family Game Night',
        description: 'Played board games until midnight. Mom won at Monopoly again!',
        isPrivate: false,
      ),
      TimelineEvent.create(
        id: _uuid.v4(),
        tags: ['Family', 'School'],
        ownerId: 'user-1',
        timestamp: now.subtract(const Duration(days: 7)),
        eventType: 'milestone',
        title: 'First Day of School',
        description: 'Both kids started their new school year. Excited and a bit nervous!',
        isPrivate: false,
      ),
    ];
  }
  
  /// Returns sample contexts
  Future<List<Context>> getContexts() async {
    await Future.delayed(const Duration(milliseconds: 50));
    
    return [
      Context(
        id: _uuid.v4(),
        ownerId: 'user-1',
        type: ContextType.person,
        name: 'Family',
        description: 'Our family timeline',
        moduleConfiguration: {},
        themeId: 'personal_theme',
        createdAt: DateTime.now().subtract(const Duration(days: 365)),
        updatedAt: DateTime.now(),
      ),
    ];
  }
  
  // Stub methods for CRUD operations (not needed for read-only testing)
  Future<void> addEvent(TimelineEvent event) async {}
  Future<void> updateEvent(TimelineEvent event) async {}
  Future<void> removeEvent(String eventId) async {}
  Future<void> addContext(Context context) async {}
  Future<void> updateContext(Context context) async {}
  Future<void> removeContext(String contextId) async {}
}
