import 'package:flutter_test/flutter_test.dart';
import 'package:uuid/uuid.dart';
import '../../lib/features/social/services/privacy_settings_service.dart';
import '../../lib/features/social/models/user_models.dart';

/// Property 22: Privacy Control Availability
/// 
/// This test validates that privacy controls are available and functional:
/// 1. Event-level privacy settings (private, friends, family, public) are available
/// 2. Privacy settings can be created, read, updated for any user
/// 3. Default privacy levels are applied correctly
/// 4. Privacy level hierarchy is enforced correctly
/// 5. Privacy settings persist across service operations
/// 6. Privacy controls are accessible for all content types

void main() {
  group('Property 22: Privacy Control Availability', () {
    late PrivacySettingsService privacyService;
    const uuid = Uuid();

    setUp(() {
      privacyService = PrivacySettingsService();
    });

    tearDown(() {
      privacyService.dispose();
    });

    test('Event-level privacy settings are available for all levels', () async {
      // Arrange
      final userId = 'user_${uuid.v4()}';

      // Act - Test all privacy levels can be set
      for (final level in PrivacyLevel.values) {
        final settings = TimelinePrivacySettings(
          userId: userId,
          defaultLevel: level,
        );
        await privacyService.updateSettings(userId, settings);
        
        // Assert
        final retrievedSettings = privacyService.getSettings(userId);
        expect(retrievedSettings.defaultLevel, equals(level));
      }
    });

    test('Privacy settings can be created for new users', () async {
      // Arrange
      final userId = 'new_user_${uuid.v4()}';

      // Act - Get settings for new user (should create default)
      final settings = privacyService.getSettings(userId);

      // Assert
      expect(settings, isNotNull);
      expect(settings.userId, equals(userId));
      expect(settings.defaultLevel, equals(PrivacyLevel.friends)); // Default level
    });

    test('Privacy settings can be updated', () async {
      // Arrange
      final userId = 'user_${uuid.v4()}';
      final initialSettings = TimelinePrivacySettings(
        userId: userId,
        defaultLevel: PrivacyLevel.private,
      );
      await privacyService.updateSettings(userId, initialSettings);

      // Act - Update settings
      final updatedSettings = initialSettings.copyWith(
        defaultLevel: PrivacyLevel.public,
        allowEventRequests: false,
      );
      await privacyService.updateSettings(userId, updatedSettings);

      // Assert
      final retrievedSettings = privacyService.getSettings(userId);
      expect(retrievedSettings.defaultLevel, equals(PrivacyLevel.public));
      expect(retrievedSettings.allowEventRequests, isFalse);
    });

    test('Default privacy levels are applied correctly', () async {
      // Arrange
      final userId = 'user_${uuid.v4()}';
      final viewerId = 'viewer_${uuid.v4()}';
      
      // Set default level to friends
      final settings = TimelinePrivacySettings(
        userId: userId,
        defaultLevel: PrivacyLevel.friends,
      );
      await privacyService.updateSettings(userId, settings);

      // Act & Assert - Check access based on default level
      // Friends level should allow access (default relationship level is friends)
      final canAccess = privacyService.canAccessTimeline(viewerId, userId);
      expect(canAccess, isTrue);
    });

    test('Private level restricts access appropriately', () async {
      // Arrange
      final userId = 'user_${uuid.v4()}';
      final viewerId = 'viewer_${uuid.v4()}';
      
      // Set default level to private
      final settings = TimelinePrivacySettings(
        userId: userId,
        defaultLevel: PrivacyLevel.private,
      );
      await privacyService.updateSettings(userId, settings);

      // Act & Assert - Private should restrict access
      final canAccess = privacyService.canAccessTimeline(viewerId, userId);
      expect(canAccess, isFalse);
    });

    test('Public level allows universal access', () async {
      // Arrange
      final userId = 'user_${uuid.v4()}';
      final viewerId = 'viewer_${uuid.v4()}';
      
      // Set default level to public
      final settings = TimelinePrivacySettings(
        userId: userId,
        defaultLevel: PrivacyLevel.public,
      );
      await privacyService.updateSettings(userId, settings);

      // Act & Assert - Public should allow access
      final canAccess = privacyService.canAccessTimeline(viewerId, userId);
      expect(canAccess, isTrue);
    });

    test('Privacy settings persist across service operations', () async {
      // Arrange
      final userId = 'user_${uuid.v4()}';
      final targetId = 'target_${uuid.v4()}';
      
      final settings = TimelinePrivacySettings(
        userId: userId,
        defaultLevel: PrivacyLevel.friends,
        allowEventRequests: true,
        allowContextRequests: false,
      );
      await privacyService.updateSettings(userId, settings);

      // Act - Perform multiple operations
      await privacyService.setRelationshipPrivacyLevel(userId, targetId, PrivacyLevel.family);
      await privacyService.shareEvents(userId, targetId, {'event1', 'event2'});
      await privacyService.shareContexts(userId, targetId, {'context1'});

      // Assert - All settings should persist
      final retrievedSettings = privacyService.getSettings(userId);
      expect(retrievedSettings.defaultLevel, equals(PrivacyLevel.friends));
      expect(retrievedSettings.allowEventRequests, isTrue);
      expect(retrievedSettings.allowContextRequests, isFalse);
      expect(retrievedSettings.relationshipOverrides[targetId], equals(PrivacyLevel.family));
      expect(retrievedSettings.sharedEventIds[targetId], containsAll(['event1', 'event2']));
      expect(retrievedSettings.sharedContextIds[targetId], contains('context1'));
    });

    test('Privacy controls work for events', () async {
      // Arrange
      final userId = 'user_${uuid.v4()}';
      final viewerId = 'viewer_${uuid.v4()}';
      final eventIds = {'event1', 'event2', 'event3'};

      // Set up privacy settings
      final settings = TimelinePrivacySettings(
        userId: userId,
        defaultLevel: PrivacyLevel.friends,
      );
      await privacyService.updateSettings(userId, settings);

      // Act - Share specific events
      await privacyService.shareEvents(userId, viewerId, eventIds);

      // Assert
      final accessibleEvents = privacyService.getAccessibleEvents(viewerId, userId);
      expect(accessibleEvents, containsAll(eventIds));
    });

    test('Privacy controls work for contexts', () async {
      // Arrange
      final userId = 'user_${uuid.v4()}';
      final viewerId = 'viewer_${uuid.v4()}';
      final contextIds = {'context1', 'context2'};

      // Set up privacy settings
      final settings = TimelinePrivacySettings(
        userId: userId,
        defaultLevel: PrivacyLevel.friends,
      );
      await privacyService.updateSettings(userId, settings);

      // Act - Share specific contexts
      await privacyService.shareContexts(userId, viewerId, contextIds);

      // Assert
      final accessibleContexts = privacyService.getAccessibleContexts(viewerId, userId);
      expect(accessibleContexts, containsAll(contextIds));
    });

    test('Privacy level enum has all required values', () {
      // Assert - All privacy levels are available
      expect(PrivacyLevel.values, contains(PrivacyLevel.private));
      expect(PrivacyLevel.values, contains(PrivacyLevel.friends));
      expect(PrivacyLevel.values, contains(PrivacyLevel.family));
      expect(PrivacyLevel.values, contains(PrivacyLevel.public));
      expect(PrivacyLevel.values, hasLength(4));
    });

    test('Settings stream emits updates', () async {
      // Arrange
      final userId = 'user_${uuid.v4()}';
      final settingsReceived = <TimelinePrivacySettings>[];
      
      privacyService.settingsStream.listen((settings) {
        settingsReceived.add(settings);
      });

      // Act - Update settings multiple times
      for (final level in PrivacyLevel.values) {
        final settings = TimelinePrivacySettings(
          userId: userId,
          defaultLevel: level,
        );
        await privacyService.updateSettings(userId, settings);
      }

      // Wait for stream updates
      await Future.delayed(const Duration(milliseconds: 100));

      // Assert
      expect(settingsReceived, hasLength(4));
      expect(settingsReceived.map((s) => s.defaultLevel), 
             containsAll(PrivacyLevel.values));
    });

    test('Relationship overrides take precedence over default level', () async {
      // Arrange
      final userId = 'user_${uuid.v4()}';
      final friendId = 'friend_${uuid.v4()}';
      
      // Set restrictive default but allow specific friend
      final settings = TimelinePrivacySettings(
        userId: userId,
        defaultLevel: PrivacyLevel.private,
        relationshipOverrides: {
          friendId: PrivacyLevel.friends,
        },
      );
      await privacyService.updateSettings(userId, settings);

      // Act & Assert
      final canAccess = privacyService.canAccessTimeline(friendId, userId);
      expect(canAccess, isTrue); // Override should allow access
    });
  });
}
