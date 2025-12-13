# Implementation Plan

- [x] 1. Set up project foundation and polymorphic data models





  - Create Flutter project with required dependencies (photo_manager, sqflite, flutter_quill)
  - Set up project structure with feature-based architecture (timeline, stories, social, sync)
  - Configure development environment with linting, testing, and CI/CD
  - _Requirements: All requirements depend on solid foundation_

- [x] 1.1 Create polymorphic data models and database schema


  - Implement Context, User, TimelineEvent (with custom_attributes JSONB), Story, Relationship, and MediaAsset data classes
  - Set up SQLite database with polymorphic design: contexts table, events table with event_type discriminator and custom_attributes JSON column
  - Create database migration system for schema evolution without breaking existing data
  - _Requirements: 1.1, 2.1, 3.1, 4.1, 9.1_

- [x] 1.2 Implement data model polymorphism for future extensibility


  - Ensure TimelineEvent table has custom_attributes (JSON) column and event_type discriminator
  - Create validation system for context-specific custom attributes
  - Build migration-free extensibility for adding new context types
  - _Requirements: 9.1, 9.4 - Future context expansion without database changes_

- [x] 1.3 Write property test for data model integrity


  - **Property 5: Caption Preservation Integrity**
  - **Validates: Requirements 1.5**

- [x] 1.4 Write property test for timezone handling


  - **Property 2: Timezone Round-Trip Consistency**
  - **Validates: Requirements 1.2**

- [x] 1.5 Generate required code and setup testing infrastructure





  - Run Flutter code generation to create missing .g.dart files for data models
  - Set up build_runner configuration for automatic code generation
  - Ensure all JSON serialization code is properly generated
  - Verify testing framework is properly configured and all tests can run
  - _Requirements: Foundation for all testing and data serialization_

- [x] 2. Implement photo import and EXIF processing engine





  - Build photo library access using photo_manager package
  - Create EXIF data extraction service with comprehensive metadata parsing
  - Implement timezone normalization and GPS coordinate processing
  - Add fuzzy date support for photos without EXIF data
  - _Requirements: 1.1, 1.2, 1.3, 1.4, 1.5_

- [x] 2.1 Create EXIF data extraction service


  - Implement ExifProcessor class to parse DateTimeOriginal, GPS coordinates, and timezone offsets
  - Add reverse geocoding integration for location name generation
  - Handle missing or malformed EXIF data gracefully
  - _Requirements: 1.1, 1.3_

- [x] 2.2 Write property test for EXIF extraction


  - **Property 1: Context-Agnostic EXIF Extraction**
  - **Validates: Requirements 1.1**

- [x] 2.3 Write property test for geocoding reliability


  - **Property 3: Geocoding Service Reliability**
  - **Validates: Requirements 1.3**

- [x] 2.4 Implement fuzzy date system


  - Create FuzzyDate class supporting year, season, and decade granularity
  - Build UI components for manual date entry when EXIF is missing
  - Implement sorting and display logic for uncertain dates
  - _Requirements: 1.4_

- [x] 2.5 Write property test for fuzzy date fallback


  - **Property 4: Context-Appropriate Fuzzy Date Granularity**
  - **Validates: Requirements 1.4**

- [x] 3. Build event clustering and timeline organization







  - Implement clustering algorithms for temporal and spatial proximity
  - Create burst detection for rapid photo sequences
  - Build timeline event management with manual override capabilities
  - Add event display logic with photo count indicators
  - _Requirements: 2.1, 2.2, 2.3, 2.4, 2.5_

- [x] 3.1 Create event clustering service


  - Implement ClusteringService with configurable time and distance thresholds
  - Add burst detection algorithm for rapid photo sequences
  - Create logic to select key photos for event clusters
  - _Requirements: 2.1, 2.2, 2.3_

- [x] 3.2 Write property test for temporal clustering


  - **Property 6: Configurable Temporal Clustering**
  - **Validates: Requirements 2.1**

- [x] 3.3 Write property test for spatial clustering


  - **Property 7: Spatial Clustering Threshold Consistency**
  - **Validates: Requirements 2.2**

- [x] 3.4 Write property test for burst detection


  - **Property 8: Burst Detection and Consolidation**
  - **Validates: Requirements 2.3**

- [x] 3.4 Implement manual clustering controls


  - Build UI for splitting and merging timeline events
  - Create event management service for user overrides
  - Add validation to prevent invalid clustering operations
  - _Requirements: 2.5_

- [x] 3.5 Write property test for context-specific default attributes


  - **Property 9: Context-Specific Default Attributes**
  - **Validates: Requirements 2.4**

- [x] 3.6 Write property test for cluster display completeness


  - **Property 10: Cluster Display Completeness**
  - **Validates: Requirements 2.5**

- [x] 3.7 Write property test for manual clustering attribute preservation



  - **Property 11: Manual Clustering Attribute Preservation**
  - **Validates: Requirements 2.6**

- [x] 4. Implement context management and polymorphic rendering system





  - Build context creation interface allowing users to select from Person, Pet, Project, Business types
  - Implement module configuration system enabling/disabling features per context
  - Create Template_Renderer factory for context-appropriate UI components
  - Add context switching and management interface
  - _Requirements: 9.1, 9.2, 9.3, 9.4, 9.5_

- [x] 4.1 Create context management system


  - Build context creation flow with predefined types (Person, Pet, Project, Business)
  - Implement module configuration JSON system for enabling context-specific features
  - Create context switching interface and management dashboard
  - _Requirements: 9.1, 9.2_

- [x] 4.2 Implement polymorphic event rendering


  - Build Template_Renderer factory pattern for context-specific event cards
  - Create widget factories for different event types (renovation progress, pet milestones, business goals)
  - Implement custom attribute display and editing interfaces
  - _Requirements: 9.3, 9.4_

- [x] 4.3 Implement TimelineTheme system for context-aware UI


  - Create TimelineTheme class defining colors, icons, and available widgets per context
  - Build theme switching based on context type (e.g., RenovationTheme enables cost slider widget)
  - Implement context-specific feature enablement (Ghost Camera for renovation/pet contexts)
  - _Requirements: 9.3, 9.5 - Context-appropriate UI rendering_

- [x] 4.4 Write property test for context type selection


  - **Property 15: Context Type Selection Availability**
  - **Validates: Requirements 9.1**

- [x] 4.5 Write property test for context-based feature configuration


  - **Property 16: Context-Based Feature Configuration**
  - **Validates: Requirements 9.2**

- [x] 4.6 Write property test for template renderer switching


  - **Property 17: Template Renderer Context Switching**
  - **Validates: Requirements 9.3**

- [x] 4.7 Write property test for custom attribute validation


  - **Property 18: Polymorphic Custom Attribute Validation**
  - **Validates: Requirements 9.4**

- [x] 4.8 Write property test for context theme application


  - **Property 19: Context Theme Application**
  - **Validates: Requirements 9.5**

- [x] 5. Implement quick text-only timeline entry





  - Build quick entry interface for creating text-only timeline events
  - Add date picker supporting both precise dates and fuzzy date options
  - Create visual indicators to distinguish text-only events from photo events
  - Integrate quick entries seamlessly with existing timeline visualization
  - _Requirements: 8.1, 8.2, 8.3, 8.4, 8.5_

- [x] 5.1 Create quick entry interface


  - Build prominent "Quick Entry" button on main timeline view
  - Implement rich text editor for story writing without photos
  - Add date/time picker with fuzzy date granularity options
  - _Requirements: 8.1, 8.2, 8.3_

- [x] 5.2 Write property test for quick entry creation


  - **Property 35: Quick Entry Creation**
  - **Validates: Requirements 8.1, 8.3, 8.4**

- [x] 5.3 Implement text-only event visualization


  - Create distinct visual indicators for text-only timeline events
  - Design icons and styling that differentiate from photo events
  - Ensure text-only events integrate seamlessly in all timeline views
  - _Requirements: 8.5_

- [x] 5.4 Write property test for visual distinction


  - **Property 36: Quick Entry Visual Distinction**
  - **Validates: Requirements 8.5**

- [x] 6. Checkpoint - Ensure core timeline functionality works




  - Ensure all tests pass, ask the user if questions arise.

- [x] 7. Develop rich story editor with scrollytelling





  - Integrate flutter_quill for rich text editing
  - Build scrollytelling controller for dynamic background changes
  - Implement media embedding for photos, videos, and audio
  - Add auto-save functionality with version history
  - _Requirements: 3.1, 3.2, 3.3, 3.4, 3.5_

- [ ] 6.7 Implement template system for context-aware rendering
  - Create TimelineTheme class defining colors, icons, and available widgets per context
  - Build Template_Renderer factory pattern for context-specific event cards
  - Implement widget switching based on context type (e.g., RenovationTheme enables cost slider widget)
  - _Requirements: 9.3, 9.5 - Context-appropriate UI rendering_

- [x] 6.1 Create rich text story editor


  - Integrate flutter_quill with custom toolbar for timeline-specific features
  - Implement block-based editing with media insertion capabilities
  - Add support for embedding photos, videos, audio, and documents
  - _Requirements: 3.1, 3.3_

- [x] 7.2 Write property test for rich editor features


  - **Property 12: Rich Editor Feature Completeness**
  - **Validates: Requirements 3.1**

- [x] 7.3 Write property test for media embedding


  - **Property 14: Media Embedding Support**
  - **Validates: Requirements 3.3**

- [x] 6.4 Separate story editor and scrollytelling viewer


  - Create StoryEditor for block-based content input (Notion-style)
  - Build StoryViewer for parallax rendering and scroll-driven animations
  - Implement data structure linking paragraphs to background media
  - _Requirements: 3.2_

- [x] 7.5 Write property test for scrollytelling sync


  - **Property 13: Scrollytelling Synchronization**
  - **Validates: Requirements 3.2**

- [x] 6.6 Add auto-save and version control


  - Implement automatic saving during story editing
  - Create version history system for story revisions
  - Add conflict detection for concurrent edits
  - _Requirements: 3.5_

- [x] 7.7 Write property test for auto-save functionality


  - **Property 14: Story Auto-save and Versioning**
  - **Validates: Requirements 3.5**

- [-] 7. Build timeline visualization engine

  - Create base timeline renderer with multiple view modes
  - Implement Life Stream view with infinite scroll
  - Build Map View with animated playback
  - Add Bento Grid visualization for life overview
  - _Requirements: 5.1, 5.2, 5.3, 5.4, 5.5_



- [ ] 6.1 Create timeline visualization framework
  - Build ITimelineRenderer interface with pluggable visualization modes
  - Implement base timeline data processing and filtering
  - Create smooth navigation between different time periods
  - _Requirements: 5.1, 5.5_

- [ ] 6.2 Write property test for visualization completeness
  - **Property 20: Visualization Mode Completeness**

  - **Validates: Requirements 5.1, 5.2, 5.3, 5.4**



- [ ] 6.3 Implement Life Stream view
  - Create infinite scroll timeline with chronological photo display
  - Add sticky headers for years and months
  - Implement lazy loading for performance with large photo collections
  - _Requirements: 5.1_

- [ ] 6.4 Build Map View with playback
  - Integrate Google Maps or Mapbox SDK
  - Create animated playback showing movement over time


  - Add clustering for high-density location areas
  - _Requirements: 5.2_

- [ ] 6.5 Create Bento Grid life overview
  - Implement grid visualization showing life density patterns
  - Add color coding for different life periods and activities
  - Create interactive navigation from grid to detailed timeline
  - _Requirements: 5.3_

- [ ] 6.6 Write property test for view transitions
  - **Property 21: View Transition Context Preservation**
  - **Validates: Requirements 5.5**

- [ ] 8. Implement social features and timeline merging
  - Build user connection and relationship management
  - Create timeline merging with River visualization
  - Implement shared event detection and collaborative editing
  - Add relationship lifecycle management (connect/disconnect/archive)
  - _Requirements: 4.1, 4.2, 4.3, 4.4, 4.5_

- [ ] 7.1 Create user connection system
  - Implement relationship management with explicit consent flows
  - Build privacy scope configuration for timeline sharing
  - Add user discovery and connection request functionality
  - _Requirements: 4.1_

- [ ] 7.2 Write property test for connection consent
  - **Property 15: Connection Consent Requirements**
  - **Validates: Requirements 4.1**

- [ ] 7.3 Build enhanced shared event detection with face clustering
  - Implement algorithm combining temporal, spatial, and face recognition data
  - Integrate google_mlkit_face_detection for on-device face clustering
  - Create confidence scoring that includes face match data for shared events
  - _Requirements: 4.2_

- [ ] 7.4 Write property test for shared event detection
  - **Property 16: Shared Event Detection Accuracy**
  - **Validates: Requirements 4.2**

- [ ] 7.5 Implement River visualization for merged timelines
  - Create CustomPainter for Sankey-style timeline merging visualization
  - Build Bézier curve rendering for smooth merge/diverge transitions
  - Add interactive elements for exploring merged timeline segments
  - _Requirements: 4.3_

- [ ] 7.6 Write property test for River visualization
  - **Property 17: River Visualization Rendering**
  - **Validates: Requirements 4.3**

- [ ] 7.7 Add collaborative event editing
  - Implement multi-user story contribution for shared events
  - Create conflict resolution for simultaneous edits
  - Add attribution and version tracking for collaborative content
  - _Requirements: 4.4_

- [ ] 7.8 Write property test for collaborative editing
  - **Property 18: Collaborative Event Editing**
  - **Validates: Requirements 4.4**

- [ ] 7.9 Build relationship lifecycle management
  - Implement relationship termination with content management options
  - Create archive, redact, and bifurcate workflows for ended relationships
  - Add secure access revocation and data isolation
  - _Requirements: 4.5_

- [ ] 7.10 Write property test for relationship termination
  - **Property 19: Relationship Termination Handling**
  - **Validates: Requirements 4.5**

- [ ] 9. Checkpoint - Ensure social features work correctly
  - Ensure all tests pass, ask the user if questions arise.

- [ ] 10. Implement privacy and security framework
  - Build granular privacy controls for events and stories
  - Implement end-to-end encryption for sensitive content
  - Create consent management and data sharing controls
  - Add secure access revocation and audit logging
  - _Requirements: 6.1, 6.2, 6.3, 6.4, 6.5_

- [ ] 9.1 Create privacy control system
  - Implement event-level privacy settings (private, shared, public)
  - Build granular permission scoping for date ranges and content types
  - Add privacy inheritance rules for shared events
  - _Requirements: 6.1, 6.2_

- [ ] 9.2 Write property test for privacy controls
  - **Property 22: Privacy Control Availability**
  - **Validates: Requirements 6.1**

- [ ] 9.3 Write property test for permission scoping
  - **Property 23: Granular Permission Scoping**
  - **Validates: Requirements 6.2**

- [ ] 9.4 Implement consent and disclosure system
  - Create explicit consent flows for timeline merging
  - Build clear data sharing disclosure interfaces
  - Add consent withdrawal and data isolation mechanisms
  - _Requirements: 6.3, 6.4_

- [ ] 9.5 Write property test for merge consent
  - **Property 24: Merge Consent and Disclosure**
  - **Validates: Requirements 6.3**

- [ ] 9.6 Add data encryption and security
  - Implement end-to-end encryption for sensitive user content
  - Create secure key management and data sovereignty controls
  - Add audit logging for privacy-sensitive operations
  - _Requirements: 6.5_

- [ ] 9.7 Write property test for data encryption
  - **Property 26: Data Encryption and Sovereignty**
  - **Validates: Requirements 6.5**

- [ ] 11. Build offline-first sync engine
  - Implement local-first data architecture with SQLite
  - Create sync engine for cloud synchronization
  - Add conflict resolution for concurrent edits
  - Build intelligent caching for media assets
  - _Requirements: 7.1, 7.2, 7.3, 7.4, 7.5_

- [ ] 10.1 Create offline-first data layer
  - Implement local SQLite database with full timeline functionality
  - Build offline editing capabilities for stories and events
  - Add local media caching with storage management
  - _Requirements: 7.1, 7.5_

- [ ] 10.2 Write property test for offline functionality
  - **Property 27: Offline Functionality Completeness**
  - **Validates: Requirements 7.1**

- [ ] 10.3 Integrate PowerSync for offline-first synchronization
  - Integrate PowerSync SDK to handle local-first SQLite replication
  - Configure PowerSync with PostgreSQL backend for automatic sync
  - Replace manual delta-sync logic with PowerSync's proven sync engine
  - _Requirements: 7.2_

- [ ] 10.4 Write property test for offline sync
  - **Property 28: Offline Change Synchronization**
  - **Validates: Requirements 7.2**

- [ ] 10.5 Add conflict resolution system
  - Implement conflict detection for concurrent edits on shared events
  - Create user-mediated resolution interfaces
  - Add automatic merge strategies for non-conflicting changes
  - _Requirements: 7.3_

- [ ] 10.6 Write property test for conflict resolution
  - **Property 29: Concurrent Edit Conflict Resolution**
  - **Validates: Requirements 7.3**

- [ ] 10.7 Build intelligent media caching
  - Implement on-demand cloud loading for large media files
  - Create configurable local storage management
  - Add selective sync options for storage-constrained devices
  - _Requirements: 7.4, 7.5_

- [ ] 10.8 Write property test for media caching
  - **Property 30: Intelligent Media Caching**
  - **Validates: Requirements 7.4**

- [ ] 12. Implement UI theming and interaction design
  - Create comprehensive theming system with multiple color modes
  - Build consistent iconography and typography system
  - Add haptic feedback and smooth animations
  - Implement responsive design for different screen sizes
  - _Requirements: 8.1, 8.2, 8.3, 8.4, 8.5_

- [ ] 11.1 Create theming system
  - Implement theme engine with Neutral, Dark, Light, and Sepia modes
  - Build instant theme switching with preference persistence
  - Create consistent color palette and design tokens
  - _Requirements: 8.1, 8.2_

- [ ] 11.2 Write property test for theme system
  - **Property 32: Theme Availability and Application**
  - **Validates: Requirements 8.1, 8.2**

- [ ] 11.3 Build iconography and typography system
  - Create consistent icon set for different content types
  - Implement responsive typography hierarchy
  - Add accessibility support for different screen sizes and preferences
  - _Requirements: 8.3, 8.4_

- [ ] 11.4 Write property test for iconography consistency
  - **Property 33: Iconography Consistency**
  - **Validates: Requirements 8.3**

- [ ] 11.5 Write property test for responsive typography
  - **Property 34: Responsive Typography Implementation**
  - **Validates: Requirements 8.4**

- [ ] 11.6 Add interaction feedback system
  - Implement haptic feedback for timeline interactions
  - Create smooth animations for view transitions and gestures
  - Add loading states and progress indicators
  - _Requirements: 8.5_

- [ ] 12.7 Write property test for interaction feedback
  - **Property 37: Interaction Feedback Consistency**
  - **Validates: Requirements 9.5**

- [ ] 13. Implement advanced intelligence and search features
  - Add local face detection and clustering for person identification
  - Build semantic search capabilities for content discovery
  - Implement data export functionality for user data sovereignty
  - Create intelligent content suggestions and automated tagging
  - _Requirements: Enhanced user experience and data ownership_

- [ ] 12.1 Implement local face detection and clustering
  - Integrate google_mlkit_face_detection for on-device face recognition
  - Build face clustering algorithm to identify frequent contacts (Partner, Family)
  - Create person tagging system with privacy-first local processing
  - _Requirements: 4.2 - Enhanced shared event detection_

- [ ] 13.2 Write property test for face clustering accuracy
  - **Property 38: Face Clustering Consistency**
  - **Validates: Enhanced shared event detection accuracy**

- [ ] 12.3 Build semantic search with sqlite-vec
  - Set up sqlite-vec extension for local vector storage
  - Implement lightweight text embedding for photo captions and stories
  - Create search interface for content-based discovery ("camping 2019", "beach sunset")
  - _Requirements: Enhanced content discovery_

- [ ] 13.4 Write property test for semantic search
  - **Property 39: Semantic Search Relevance**
  - **Validates: Content discovery functionality**

- [ ] 12.5 Implement comprehensive data export
  - Create PDF export using flutter_quill_to_pdf for timeline books
  - Build ZIP archive export for original media assets and metadata
  - Add JSON export for complete data portability and backup
  - _Requirements: 6.5 - Data sovereignty and user control_

- [ ] 13.6 Write property test for data export integrity
  - **Property 40: Export Data Completeness**
  - **Validates: Data sovereignty and backup functionality**

- [ ] 14. Implement Ghost Camera for progress comparison
  - Build camera overlay system that displays semi-transparent previous images
  - Create reference photo selection interface for comparison shots
  - Add opacity controls and alignment guides for consistent framing
  - Implement context-aware activation (enabled for renovation/pet contexts, hidden for personal)
  - _Requirements: 10.1, 10.2, 10.3, 10.4, 10.5_

- [ ] 14.1 Create Ghost Camera overlay system
  - Implement camera view with semi-transparent overlay of previous images
  - Build photo selection system for choosing comparison reference
  - Add alignment guides and opacity controls for precise framing
  - _Requirements: 10.1, 10.2, 10.3_

- [ ] 14.2 Implement context-aware Ghost Camera activation
  - Enable Ghost Camera for renovation and pet contexts automatically
  - Hide Ghost Camera features for personal biography contexts
  - Create context-specific camera interface variations
  - _Requirements: 10.4, 10.5 - Context-appropriate feature activation_

- [ ] 14.3 Write property test for Ghost Camera availability
  - **Property 20: Context-Aware Ghost Camera Availability**
  - **Validates: Requirements 10.1, 10.5**

- [ ] 14.4 Write property test for Ghost Camera reference selection
  - **Property 21: Ghost Camera Reference Selection**
  - **Validates: Requirements 10.2**

- [ ] 14.5 Write property test for Ghost Camera overlay fidelity
  - **Property 22: Ghost Camera Overlay Fidelity**
  - **Validates: Requirements 10.3**

- [ ] 14.6 Write property test for Ghost Camera opacity control
  - **Property 23: Ghost Camera Opacity Control**
  - **Validates: Requirements 10.4**

- [ ] 15. Final integration and polish
  - Integrate all components into cohesive user experience
  - Add onboarding flow and user guidance
  - Implement error handling and recovery mechanisms
  - Optimize performance for large photo collections
  - _Requirements: All requirements integration_

- [ ] 12.1 Create onboarding and user guidance
  - Build welcome flow explaining key features and privacy controls
  - Add contextual help and feature discovery
  - Create sample data and tutorial content
  - _Requirements: All requirements - user education_

- [ ] 12.2 Implement comprehensive error handling
  - Add graceful degradation for network failures and data corruption
  - Create user-friendly error messages and recovery options
  - Implement crash reporting and diagnostic logging
  - _Requirements: All requirements - reliability_

- [ ] 12.3 Optimize performance and scalability
  - Profile and optimize timeline rendering for large datasets
  - Implement efficient image loading and memory management
  - Add performance monitoring and analytics
  - _Requirements: All requirements - performance_

- [ ] 15. Final Checkpoint - Complete system validation
  - Ensure all tests pass, ask the user if questions arise.