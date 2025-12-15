import 'package:uuid/uuid.dart';
import '../../../shared/models/timeline_event.dart';
import '../../../shared/models/context.dart';
import '../../../shared/models/media_asset.dart';

/// Mock repository for web testing (bypasses SQLite web issues)
class MockTimelineRepository {
  final _uuid = const Uuid();
  
  /// Returns sample timeline events for testing (multi-user data)
  Future<List<TimelineEvent>> getEvents() async {
    await Future.delayed(const Duration(milliseconds: 100));
    
    final now = DateTime.now();
    
    return [
      // === USER 1 EVENTS ===
      
      // 2025 - Shared Holiday Event
      TimelineEvent.create(
        id: _uuid.v4(),
        tags: ['Family', 'Holiday', 'Celebration'],
        ownerId: 'user-1',
        timestamp: now.subtract(const Duration(days: 2)),
        eventType: 'photo_burst',
        title: 'Holiday Season 2025',
        description: 'Wonderful time with the family! The decorations looked amazing this year.',
        assets: List.generate(5, (index) => MediaAsset.photo(
          id: _uuid.v4(),
          eventId: '',
          localPath: 'https://picsum.photos/400/300?random=${100+index}',
          createdAt: now,
        )),
        isPrivate: false,
      ),
      
      TimelineEvent.create(
        id: _uuid.v4(),
        tags: ['Personal', 'Growth'],
        ownerId: 'user-1',
        timestamp: now.subtract(const Duration(days: 45)),
        eventType: 'text',
        title: 'New Year\'s Resolution',
        description: 'Committed to learning Flutter and building this amazing biography app.',
        isPrivate: true,
      ),

      // 2023 - Shared Home Purchase
      TimelineEvent.create(
        id: _uuid.v4(),
        tags: ['Home', 'Milestone'],
        ownerId: 'user-1',
        timestamp: now.subtract(const Duration(days: 365 * 2)),
        eventType: 'milestone',
        title: 'Bought First House',
        description: 'Officially became homeowners! It has good bones and a lovely garden.',
        isPrivate: false,
      ),
      
      TimelineEvent.create(
        id: _uuid.v4(),
        tags: ['Home', 'Renovation'],
        ownerId: 'user-1',
        timestamp: now.subtract(const Duration(days: (365 * 2) - 30)),
        eventType: 'photo_collection',
        title: 'Home Renovations',
        description: 'Painting the living room and fixing up the kitchen.',
        assets: List.generate(3, (index) => MediaAsset.photo(
          id: _uuid.v4(),
          eventId: '',
          localPath: 'https://picsum.photos/400/300?random=${200+index}',
          createdAt: now,
        )),
        isPrivate: false,
      ),

      // 2020
      TimelineEvent.create(
        id: _uuid.v4(),
        tags: ['Education', 'Milestone', 'Career'],
        ownerId: 'user-1',
        timestamp: DateTime(2020, 5, 20),
        eventType: 'milestone',
        title: 'University Graduation',
        description: 'Graduated with honors! Strange ceremony but we celebrated at home.',
        isPrivate: false,
      ),

      // 2015 - Shared Paris Trip
      TimelineEvent.create(
        id: _uuid.v4(),
        tags: ['Travel', 'Europe', 'Vacation'],
        ownerId: 'user-1',
        timestamp: DateTime(2015, 8, 14),
        eventType: 'photo',
        title: 'Paris Adventure',
        description: 'First time seeing the Eiffel Tower together!',
        assets: [
          MediaAsset.photo(
            id: _uuid.v4(),
            eventId: '',
            localPath: 'https://picsum.photos/400/300?random=301',
            createdAt: DateTime(2015, 8, 14),
          )
        ],
        isPrivate: false,
      ),

      // === USER 2 EVENTS ===
      
      // 2025 - Shared Holiday Event
      TimelineEvent.create(
        id: _uuid.v4(),
        tags: ['Family', 'Holiday', 'Celebration'],
        ownerId: 'user-2',
        timestamp: now.subtract(const Duration(days: 2)),
        eventType: 'photo_burst',
        title: 'Holiday Season 2025',
        description: 'Amazing holiday with loved ones. The kids were so excited!',
        assets: List.generate(4, (index) => MediaAsset.photo(
          id: _uuid.v4(),
          eventId: '',
          localPath: 'https://picsum.photos/400/300?random=${150+index}',
          createdAt: now,
        )),
        isPrivate: false,
      ),
      
      TimelineEvent.create(
        id: _uuid.v4(),
        tags: ['Work', 'Career'],
        ownerId: 'user-2',
        timestamp: now.subtract(const Duration(days: 60)),
        eventType: 'milestone',
        title: 'Promotion at Work',
        description: 'Finally got that senior position I\'ve been working towards!',
        isPrivate: false,
      ),

      // 2023 - Shared Home Purchase
      TimelineEvent.create(
        id: _uuid.v4(),
        tags: ['Home', 'Milestone'],
        ownerId: 'user-2',
        timestamp: now.subtract(const Duration(days: 365 * 2)),
        eventType: 'milestone',
        title: 'Bought First House',
        description: 'Our dream home! Can\'t wait to make memories here.',
        isPrivate: false,
      ),
      
      TimelineEvent.create(
        id: _uuid.v4(),
        tags: ['Personal', 'Hobby'],
        ownerId: 'user-2',
        timestamp: now.subtract(const Duration(days: (365 * 2) - 90)),
        eventType: 'photo',
        title: 'Started Gardening',
        description: 'Planted my first vegetable garden in the backyard.',
        assets: [
          MediaAsset.photo(
            id: _uuid.v4(),
            eventId: '',
            localPath: 'https://picsum.photos/400/300?random=250',
            createdAt: now,
          )
        ],
        isPrivate: false,
      ),

      // 2021
      TimelineEvent.create(
        id: _uuid.v4(),
        tags: ['Career', 'Achievement'],
        ownerId: 'user-2',
        timestamp: DateTime(2021, 9, 15),
        eventType: 'milestone',
        title: 'Started New Job',
        description: 'Exciting new role at a tech company. Fresh start!',
        isPrivate: false,
      ),

      // 2015 - Shared Paris Trip
      TimelineEvent.create(
        id: _uuid.v4(),
        tags: ['Travel', 'Europe', 'Vacation'],
        ownerId: 'user-2',
        timestamp: DateTime(2015, 8, 14),
        eventType: 'photo',
        title: 'Paris Adventure',
        description: 'The Eiffel Tower was breathtaking! Best trip ever.',
        assets: [
          MediaAsset.photo(
            id: _uuid.v4(),
            eventId: '',
            localPath: 'https://picsum.photos/400/300?random=350',
            createdAt: DateTime(2015, 8, 14),
          )
        ],
        isPrivate: false,
      ),
      
      TimelineEvent.create(
        id: _uuid.v4(),
        tags: ['Travel', 'Europe'],
        ownerId: 'user-2',
        timestamp: DateTime(2015, 8, 16),
        eventType: 'photo',
        title: 'Louvre Museum',
        description: 'Spent hours exploring the art. The Mona Lisa was smaller than expected!',
        assets: [
          MediaAsset.photo(
            id: _uuid.v4(),
            eventId: '',
            localPath: 'https://picsum.photos/400/300?random=351',
            createdAt: DateTime(2015, 8, 16),
          )
        ],
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
