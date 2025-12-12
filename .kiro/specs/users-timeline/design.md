# Users Timeline Design Document

## Overview

Users Timeline is a polymorphic timeline engine that transforms photo collections into rich, interactive chronicles across multiple life contexts. The system serves as a universal "Timeline Engine" that can be configured for personal biographies, pet growth tracking, home renovation documentation, business project management, and other temporal storytelling needs through a flexible context-based architecture.

The system combines automated metadata processing, intelligent event clustering, and social timeline merging with a polymorphic data model that supports context-specific attributes and rendering. This "Engine" approach allows the same core platform to serve completely different markets (new parents, home renovators, pet owners, startups) by simply changing configuration and theming.

The architecture follows a mobile-first approach using Flutter for cross-platform development, with offline-first data synchronization and privacy-by-design principles. The application serves as both a specialized domain tool and collaborative storytelling platform, enabling users to preserve and share their contextual digital heritage.

## Architecture

### System Architecture

The Users Timeline system follows a three-tier architecture:

**Presentation Layer (Flutter Mobile App)**
- Cross-platform mobile application built with Flutter
- Custom rendering engine for timeline visualizations using CustomPainter
- Offline-first local data storage with SQLite
- Rich text editor with scrollytelling capabilities

**Application Layer (Backend Services)**
- RESTful API built with Node.js/Express or Python/FastAPI
- Authentication and authorization services
- Real-time synchronization engine
- Media processing and storage services
- Privacy and consent management

**Data Layer**
- PostgreSQL primary database for user data and relationships
- Redis for caching and session management
- Cloud storage (AWS S3/Google Cloud Storage) for media assets
- ElasticSearch for timeline search and filtering

### Technology Stack

**Mobile Application:**
- Framework: Flutter 3.x with Dart
- State Management: Riverpod or Bloc pattern
- Local Database: SQLite with sqflite package
- Media Processing: photo_manager for gallery access
- Maps: Google Maps SDK or Mapbox
- Rich Text: flutter_quill for story editing

**Backend Services:**
- Runtime: Node.js with Express.js or Python with FastAPI
- Database: PostgreSQL with Prisma ORM
- Authentication: Firebase Auth or Auth0
- File Storage: AWS S3 with CloudFront CDN
- Real-time: WebSocket connections for live sync

**Infrastructure:**
- Deployment: Docker containers on AWS ECS or Google Cloud Run
- CDN: CloudFront or Google Cloud CDN for media delivery
- Monitoring: Sentry for error tracking, DataDog for performance
- CI/CD: GitHub Actions or GitLab CI

## Components and Interfaces

### Core Components

**Polymorphic Timeline Engine**
- Responsible for chronological data organization and display across all context types
- Handles multiple visualization modes (Stream, River, Map, Grid) with context-aware rendering
- Manages temporal navigation and filtering with context-specific granularity
- Interfaces: `ITimelineRenderer`, `IVisualizationMode`, `IContextRenderer`

**Context Management System**
- Manages different timeline contexts (Person, Pet, Project, Business)
- Handles module configuration and feature enablement per context
- Provides context-specific default values and validation rules
- Interfaces: `IContextManager`, `IModuleConfiguration`

**Template Renderer Factory**
- Factory pattern for rendering context-appropriate UI components
- Switches between different event card layouts based on context and event type
- Handles custom attribute display and interaction patterns
- Interfaces: `ITemplateRenderer`, `IEventCardFactory`, `IWidgetFactory`

**Event Clustering Service**
- Processes raw photo metadata into semantic events with polymorphic attributes
- Implements temporal and spatial proximity algorithms
- Handles fuzzy date processing for uncertain timestamps
- Supports context-specific clustering rules (e.g., renovation phases, pet milestones)
- Interfaces: `IClusteringAlgorithm`, `IEventProcessor`, `IContextualClustering`

**Story Editor**
- Rich text editing with multimedia embedding
- Scrollytelling implementation with dynamic backgrounds
- Auto-save and version control for user content
- Context-aware content suggestions and templates
- Interfaces: `IStoryRenderer`, `IScrollytellingController`

**Social Graph Manager**
- Handles user connections and timeline merging across contexts
- Manages privacy permissions and consent flows
- Implements relationship lifecycle (connect/disconnect/archive)
- Supports cross-context sharing (e.g., sharing pet timeline with family)
- Interfaces: `IRelationshipManager`, `IPrivacyController`

**Ghost Camera System**
- Provides semi-transparent overlay of previous photos for comparison shots
- Manages reference photo selection and overlay rendering
- Handles opacity controls and alignment guides
- Context-aware activation (enabled for renovation/pet contexts, hidden for personal)
- Interfaces: `IGhostCamera`, `IOverlayRenderer`

**Sync Engine**
- Offline-first data synchronization with polymorphic data support
- Conflict resolution for concurrent edits on custom attributes
- Incremental sync with delta updates
- Context-aware sync priorities and strategies
- Interfaces: `ISyncManager`, `IConflictResolver`

### Interface Definitions

```dart
abstract class ITimelineRenderer {
  Future<List<TimelineEvent>> getEventsInRange(DateRange range);
  Future<void> renderVisualization(VisualizationMode mode);
  Stream<TimelineEvent> watchEventUpdates();
}

abstract class IEventProcessor {
  Future<List<TimelineEvent>> clusterPhotos(List<PhotoAsset> photos);
  Future<TimelineEvent> createEventFromCluster(List<PhotoAsset> cluster);
  Future<void> updateEventMetadata(String eventId, EventMetadata metadata);
}

abstract class IStoryRenderer {
  Future<void> renderStory(Story story, ScrollController controller);
  Future<void> updateBackgroundMedia(MediaAsset asset, double scrollOffset);
  Stream<StoryBlock> watchStoryBlocks(String storyId);
}
```

## Data Models

### Core Entities

**Context**
```dart
class Context {
  final String id;
  final String ownerId;
  final ContextType type; // Person, Pet, Project, Business
  final String name;
  final String? description;
  final Map<String, dynamic> moduleConfiguration; // JSON blob for enabled features
  final TimelineTheme theme;
  final DateTime createdAt;
  final DateTime updatedAt;
}

enum ContextType {
  person,
  pet,
  project,
  business,
}
```

**User**
```dart
class User {
  final String id;
  final String email;
  final String displayName;
  final String? profileImageUrl;
  final PrivacySettings privacySettings;
  final List<String> contextIds; // Multiple contexts per user
  final DateTime createdAt;
  final DateTime lastActiveAt;
}
```

**TimelineEvent (Polymorphic)**
```dart
class TimelineEvent {
  final String id;
  final String contextId; // Links to Context instead of User directly
  final String ownerId;
  final DateTime timestamp;
  final FuzzyDate? fuzzyDate;
  final GeoLocation? location;
  final String eventType; // Discriminator for rendering (e.g., "renovation_progress", "pet_weight", "milestone")
  final Map<String, dynamic> customAttributes; // JSONB for context-specific data
  final List<MediaAsset> assets;
  final String? title;
  final String? description;
  final Story? story;
  final List<String> participantIds;
  final PrivacyLevel privacyLevel;
  final DateTime createdAt;
  final DateTime updatedAt;
}

// Example custom attributes by context:
// Renovation: {"cost": 1500, "contractor": "Bob", "room": "kitchen", "phase": "demolition"}
// Pet: {"weight_kg": 12.5, "vaccine_type": "Rabies", "vet_visit": true, "mood": "playful"}
// Business: {"milestone": "MVP Launch", "budget_spent": 25000, "team_size": 5}
```

**Story**
```dart
class Story {
  final String id;
  final String eventId;
  final String authorId;
  final List<StoryBlock> blocks;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int version;
}

class StoryBlock {
  final String id;
  final BlockType type; // text, image, video, audio
  final Map<String, dynamic> content;
  final Map<String, dynamic>? styling;
  final MediaAsset? backgroundMedia;
}
```

**TimelineTheme**
```dart
class TimelineTheme {
  final String id;
  final String name;
  final ContextType contextType;
  final Map<String, Color> colorPalette;
  final Map<String, IconData> iconSet;
  final Map<String, TextStyle> typography;
  final Map<String, Widget Function(TimelineEvent)> widgetFactories; // Context-specific widgets
  final bool enableGhostCamera;
  final bool enableBudgetTracking;
  final bool enableProgressComparison;
}
```

**Relationship (Cross-Context)**
```dart
class Relationship {
  final String id;
  final String userAId;
  final String userBId;
  final RelationshipType type; // friend, family, partner, collaborator
  final List<String> sharedContextIds; // Can share multiple contexts
  final DateTime startDate;
  final DateTime? endDate;
  final RelationshipStatus status; // active, archived, disconnected
  final Map<String, PermissionScope> contextPermissions; // Per-context permissions
}
```

**MediaAsset**
```dart
class MediaAsset {
  final String id;
  final String eventId;
  final AssetType type; // photo, video, audio, document
  final String localPath;
  final String? cloudUrl;
  final ExifData? exifData;
  final String? caption;
  final DateTime createdAt;
  final bool isKeyAsset; // primary photo for event cluster
}
```

### Database Schema (Polymorphic Design)

**Contexts Table (The "Wrapper")**
- Primary key: id (UUID)
- Foreign key: owner_id → users.id
- Fields: type (enum), name, description, module_configuration (JSONB), theme_id
- Indexes: owner_id, type
- Enables multiple contexts per user with different configurations

**Events Table (The Generic Holder)**
- Primary key: id (UUID)
- Foreign key: context_id → contexts.id, owner_id → users.id
- Fields: timestamp, event_type (discriminator), custom_attributes (JSONB)
- Indexes: timestamp, context_id, event_type, location (GiST)
- Supports polymorphic data: renovation events, pet events, business milestones
- Example custom_attributes: {"cost": 1500, "contractor": "Bob"} or {"weight_kg": 12.5, "vaccine_type": "Rabies"}

**Timeline_Themes Table**
- Primary key: id (UUID)
- Fields: name, context_type, color_palette (JSONB), icon_set (JSONB), widget_config (JSONB)
- Defines rendering rules and available widgets per context type

**Event_Participants Junction Table**
- Composite key: (event_id, user_id)
- Role field for ownership vs. participation
- Enables efficient shared event queries across contexts

**Relationships Table (Cross-Context Support)**
- Composite unique constraint: (user_a_id, user_b_id)
- Fields: shared_context_ids (JSONB array), context_permissions (JSONB)
- Temporal validity with start_date/end_date
- Supports sharing different contexts with different permission levels

## Error Handling

### Error Categories

**Data Processing Errors**
- EXIF parsing failures: Graceful degradation to manual date entry
- Clustering algorithm errors: Fall back to individual photo events
- Geocoding failures: Store raw coordinates, retry with exponential backoff

**Sync Conflicts**
- Concurrent story edits: Last-writer-wins with conflict notification
- Timeline merge conflicts: User-mediated resolution with diff view
- Permission changes: Immediate revocation with audit trail

**Privacy Violations**
- Unauthorized access attempts: Log and block with rate limiting
- Data breach scenarios: Automatic encryption key rotation
- Consent withdrawal: Immediate data isolation and purge workflows

### Error Recovery Strategies

**Offline Resilience**
- Queue failed operations for retry when online
- Maintain local-first data integrity during network partitions
- Progressive sync with priority for user-visible content

**Data Corruption Protection**
- Immutable event history with append-only logs
- Regular backup verification and integrity checks
- Rollback capabilities for critical data corruption

## Testing Strategy

*A property is a characteristic or behavior that should hold true across all valid executions of a system-essentially, a formal statement about what the system should do. Properties serve as the bridge between human-readable specifications and machine-verifiable correctness guarantees.*

The testing approach combines comprehensive unit testing for specific functionality with property-based testing to verify universal system behaviors across all possible inputs.

**Property-Based Testing Framework:** The system will use the `faker` package for Dart to generate test data and implement custom property testing using the `test` package with parameterized tests running minimum 100 iterations per property.

**Unit Testing Approach:** Unit tests will focus on specific examples, integration points between components, and edge cases that demonstrate correct behavior. These complement property tests by catching concrete bugs while property tests verify general correctness.

**Test Tagging Requirements:** Each property-based test must include a comment explicitly referencing the design document property using the format: `**Feature: users-timeline, Property {number}: {property_text}**`

### Property-Based Tests

Each correctness property will be implemented as a single property-based test with 100+ iterations to ensure comprehensive coverage across the input space.

### Correctness Properties

*A property is a characteristic or behavior that should hold true across all valid executions of a system-essentially, a formal statement about what the system should do. Properties serve as the bridge between human-readable specifications and machine-verifiable correctness guarantees.*

Based on the prework analysis, the following properties must hold across all valid system executions:

**Property 1: Context-Agnostic EXIF Extraction**
*For any* image file with valid EXIF data and any context type, the extraction process should successfully identify and parse DateTimeOriginal, GPS coordinates, and timezone offset fields when present
**Validates: Requirements 1.1**

**Property 2: Timezone Round-Trip Consistency**
*For any* timestamp with timezone information, converting to UTC for storage and back to local time for display should preserve the original temporal meaning
**Validates: Requirements 1.2**

**Property 3: Geocoding Service Reliability**
*For any* valid GPS coordinate pair, the reverse geocoding service should return a human-readable location string or appropriate error handling
**Validates: Requirements 1.3**

**Property 4: Context-Appropriate Fuzzy Date Granularity**
*For any* image lacking EXIF timestamp data, the system should provide manual date entry options with granularity levels appropriate to the context type
**Validates: Requirements 1.4**

**Property 5: Caption Preservation Integrity**
*For any* image with existing caption or description metadata, the import process should preserve this text without modification or loss
**Validates: Requirements 1.5**

**Property 6: Configurable Temporal Clustering**
*For any* collection of photos and time window configuration, the clustering algorithm should group images within the specified time window consistently
**Validates: Requirements 2.1**

**Property 7: Spatial Clustering Threshold Consistency**
*For any* collection of photos with GPS coordinates and distance threshold configuration, the system should create new clusters when spatial distance exceeds the threshold
**Validates: Requirements 2.2**

**Property 8: Burst Detection and Consolidation**
*For any* sequence of photos taken in rapid succession, the system should detect bursts and consolidate them into single events with key photo selection
**Validates: Requirements 2.3**

**Property 9: Context-Specific Default Attributes**
*For any* timeline event creation and context type, the system should initialize custom_attributes with appropriate default values based on the event_type and context
**Validates: Requirements 2.4**

**Property 10: Cluster Display Completeness**
*For any* clustered timeline event, the display should show accurate photo counts and provide expansion capabilities to view all contained photos
**Validates: Requirements 2.5**

**Property 11: Manual Clustering Attribute Preservation**
*For any* manual clustering operation (split or merge), the system should preserve all custom_attributes data without loss or corruption
**Validates: Requirements 2.6**

**Property 12: Rich Editor Feature Completeness**
*For any* selected timeline event, the story editor should provide formatted text, media embedding, and block-based editing capabilities
**Validates: Requirements 3.1**

**Property 11: Scrollytelling Synchronization**
*For any* story with embedded media, scrolling through the narrative should trigger background media changes at the correct scroll positions
**Validates: Requirements 3.2**

**Property 12: Media Embedding Support**
*For any* supported media type (photo, video, audio, document), the story editor should successfully embed the content within the narrative
**Validates: Requirements 3.3**

**Property 13: Mobile Typography Optimization**
*For any* story content, the rendering should apply appropriate line length, spacing, and typography hierarchy for mobile readability
**Validates: Requirements 3.4**

**Property 14: Story Auto-save and Versioning**
*For any* story editing session, the system should automatically save changes and maintain version history without data loss
**Validates: Requirements 3.5**

**Property 15: Context Type Selection Availability**
*For any* new timeline creation, the system should provide all predefined context types (Person, Pet, Project, Business) as selectable options
**Validates: Requirements 9.1**

**Property 16: Context-Based Feature Configuration**
*For any* context type selection, the system should automatically configure module_configuration settings to enable appropriate features for that context
**Validates: Requirements 9.2**

**Property 17: Template Renderer Context Switching**
*For any* timeline event and context type, the Template_Renderer should display context-appropriate widgets and data fields based on the event's context
**Validates: Requirements 9.3**

**Property 18: Polymorphic Custom Attribute Validation**
*For any* custom attribute addition to an event, the system should validate and store the data in the polymorphic JSON metadata field according to context-specific rules
**Validates: Requirements 9.4**

**Property 19: Context Theme Application**
*For any* context switch, the system should apply the appropriate Timeline_Theme including colors, icons, and interaction patterns specific to that context type
**Validates: Requirements 9.5**

**Property 20: Context-Aware Ghost Camera Availability**
*For any* context that benefits from comparison photography (renovation, pet), the system should provide Ghost_Camera functionality, while hiding it for contexts that don't need it
**Validates: Requirements 10.1, 10.5**

**Property 21: Ghost Camera Reference Selection**
*For any* Ghost Camera usage, the system should allow users to select which previous photo to use as overlay reference from available options
**Validates: Requirements 10.2**

**Property 22: Ghost Camera Overlay Fidelity**
*For any* previous photo overlay, the system should maintain proper aspect ratio and provide alignment guides for consistent framing
**Validates: Requirements 10.3**

**Property 23: Ghost Camera Opacity Control**
*For any* Ghost Camera overlay, the system should provide opacity controls that ensure visibility of the current camera view while showing the reference image
**Validates: Requirements 10.4**

**Property 24: Connection Consent Requirements**
*For any* timeline connection request, the system should require explicit mutual consent with configurable privacy scope options
**Validates: Requirements 4.1**

**Property 25: Shared Event Detection Accuracy**
*For any* pair of connected users, the system should correctly identify shared events based on temporal and spatial proximity of their photos
**Validates: Requirements 4.2**

**Property 26: River Visualization Rendering**
*For any* connected timeline pair, the river visualization should accurately display individual and merged timeline segments with proper merge/diverge points
**Validates: Requirements 4.3**

**Property 27: Collaborative Event Editing**
*For any* shared timeline event, both connected users should be able to contribute stories and media without edit conflicts
**Validates: Requirements 4.4**

**Property 28: Relationship Termination Handling**
*For any* ended relationship, the system should provide appropriate options (archive, redact, bifurcate) for managing previously shared content
**Validates: Requirements 4.5**

**Property 29: Visualization Mode Completeness**
*For any* timeline data, all visualization modes (Life Stream, Map View, Bento Grid, Network Diagram) should render appropriately with the available data
**Validates: Requirements 5.1, 5.2, 5.3, 5.4**

**Property 30: View Transition Context Preservation**
*For any* visualization mode switch, the system should maintain temporal context and navigation state across the transition
**Validates: Requirements 5.5**

**Property 31: Privacy Control Availability**
*For any* timeline event, the system should provide complete privacy setting options (private, shared with specific users, public)
**Validates: Requirements 6.1**

**Property 32: Granular Permission Scoping**
*For any* timeline sharing request, users should be able to configure limited scope permissions for specific date ranges and content types
**Validates: Requirements 6.2**

**Property 33: Merge Consent and Disclosure**
*For any* timeline merge request, the system should require explicit consent with clear disclosure of data sharing implications
**Validates: Requirements 6.3**

**Property 34: Access Revocation Security**
*For any* relationship status change, the system should provide secure methods to revoke access and manage previously shared content
**Validates: Requirements 6.4**

**Property 35: Data Encryption and Sovereignty**
*For any* sensitive user data, the system should implement end-to-end encryption and maintain data sovereignty principles
**Validates: Requirements 6.5**

**Property 36: Offline Functionality Completeness**
*For any* previously synced content, the system should provide full access and editing capabilities when offline
**Validates: Requirements 7.1**

**Property 37: Offline Change Synchronization**
*For any* changes made while offline, the system should queue modifications and sync automatically when connectivity returns
**Validates: Requirements 7.2**

**Property 38: Concurrent Edit Conflict Resolution**
*For any* simultaneous editing scenario on shared events, the system should handle conflicts with appropriate resolution mechanisms
**Validates: Requirements 7.3**

**Property 39: Intelligent Media Caching**
*For any* large media file, the system should implement appropriate caching strategies with on-demand cloud loading
**Validates: Requirements 7.4**

**Property 40: Storage Management Configuration**
*For any* storage constraint scenario, the system should provide configurable local storage management with selective sync options
**Validates: Requirements 7.5**

**Property 41: Theme Availability and Application**
*For any* theme selection, the system should provide all specified color modes and apply changes instantly across all interface elements
**Validates: Requirements 11.1, 11.2**

**Property 42: Iconography Consistency**
*For any* content type, the system should display consistent and appropriate iconography that distinguishes between different media and event types
**Validates: Requirements 11.3**

**Property 43: Responsive Typography Implementation**
*For any* text content and screen size, the system should implement appropriate typography hierarchy optimized for readability
**Validates: Requirements 11.4**

**Property 44: Quick Entry Creation**
*For any* text-only timeline entry, the system should create a Timeline_Event that integrates seamlessly with photo-based events and supports both precise and fuzzy dates
**Validates: Requirements 8.1, 8.3, 8.4**

**Property 45: Quick Entry Visual Distinction**
*For any* text-only timeline event, the system should display distinct visual indicators that differentiate it from photo-based events while maintaining timeline coherence
**Validates: Requirements 8.5**

**Property 46: Interaction Feedback Consistency**
*For any* user interaction with timeline elements, the system should provide appropriate haptic feedback and smooth animations
**Validates: Requirements 11.5**

### Property Reflection

After reviewing all identified properties, several areas of potential redundancy were identified and consolidated:

**Polymorphic Architecture Properties:** Properties 15-23 address the new context-based system and cannot be consolidated as they each validate distinct aspects of the polymorphic engine (context creation, feature configuration, template rendering, custom attributes, theming, and Ghost Camera functionality).

**Clustering Properties:** Properties 6-8 were kept separate as they address different clustering scenarios (temporal, spatial, and burst detection), providing unique validation value for the polymorphic event system.

**Visualization Properties:** Properties 29-30 were kept separate as Property 29 validates rendering completeness while Property 30 validates state preservation during transitions across all context types.

**Privacy and Security Properties:** Properties 31-35 each address distinct aspects of privacy (event-level controls, permission scoping, consent mechanisms, access revocation, and data encryption) and cannot be consolidated without losing validation coverage.

**Sync and Offline Properties:** Properties 36-40 address different aspects of offline functionality and synchronization, each providing unique validation for specific scenarios across all context types.

**Context-Specific Features:** Properties 20-23 specifically validate the Ghost Camera system which is crucial for renovation and pet contexts but must be hidden for personal contexts.

Each remaining property provides distinct validation value and cannot be consolidated without losing important correctness guarantees for the polymorphic timeline engine.

## Testing Strategy

### Dual Testing Approach

The Users Timeline system requires both unit testing and property-based testing to ensure comprehensive correctness validation:

**Unit Testing Focus:**
- Specific examples demonstrating correct behavior for key user flows
- Integration points between timeline visualization and story editing components
- Edge cases like empty photo libraries, network failures, and malformed EXIF data
- Error handling scenarios and recovery mechanisms

**Property-Based Testing Focus:**
- Universal properties that must hold across all possible inputs and user interactions
- Data transformation correctness (EXIF parsing, clustering algorithms, timezone handling)
- Privacy and security invariants across all user scenarios
- Synchronization and conflict resolution across all possible concurrent edit scenarios

**Property-Based Testing Implementation:**
- Framework: Dart `test` package with custom property testing utilities using `faker` for data generation
- Iteration Count: Minimum 100 iterations per property test to ensure comprehensive input coverage
- Test Tagging: Each property-based test must include the comment format: `**Feature: users-timeline, Property {number}: {property_text}**`
- Generator Strategy: Smart generators that constrain to valid input spaces (e.g., valid GPS coordinates, realistic photo timestamps, proper EXIF data structures)

**Integration Testing:**
- End-to-end user flows from photo import through story creation and timeline sharing
- Cross-platform consistency between iOS and Android implementations
- Performance testing for large photo collections and complex timeline merges
- Privacy workflow testing to ensure data isolation and access control

The combination of unit tests for specific scenarios and property tests for universal behaviors provides comprehensive coverage that catches both concrete bugs and general correctness violations across the entire input space.