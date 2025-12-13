import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/encryption_models.dart';
import '../services/encryption_service.dart';
import '../services/secure_storage_service.dart';
import '../../../shared/models/timeline_event.dart';
import '../../../shared/models/fuzzy_date.dart';
import '../../../shared/models/geo_location.dart';
import '../../../shared/models/media_asset.dart';
import '../../../shared/models/story.dart';
import '../../../shared/models/user.dart';
import '../../social/models/user_models.dart';

/// Provider for data encryption service
final dataEncryptionServiceProvider = Provider((ref) => DataEncryptionService(
  encryptionService: ref.read(encryptionServiceProvider),
  secureStorageService: ref.read(secureStorageServiceProvider),
));

/// Service for encrypting and decrypting timeline data
class DataEncryptionService {
  final EncryptionService _encryptionService;
  final SecureStorageService _secureStorageService;

  DataEncryptionService({
    required EncryptionService encryptionService,
    required SecureStorageService secureStorageService,
  }) : _encryptionService = encryptionService,
       _secureStorageService = secureStorageService;

  /// Encrypt a timeline event
  Future<EncryptedTimelineEvent> encryptTimelineEvent(
    TimelineEvent event,
    String userId,
  ) async {
    try {
      // Get user's encryption key
      final userKeyPairs = await _secureStorageService.getUserKeyPairs(userId);
      if (userKeyPairs.isEmpty) {
        throw Exception('No encryption keys found for user: $userId');
      }

      final keyPair = userKeyPairs.first; // Use the first active key
      
      // Serialize event to JSON
      final eventJson = event.toJson();
      
      // Encrypt sensitive fields
      final encryptedFields = <String, EncryptedData>{};
      
      // Encrypt title if present
      if (event.title != null && event.title!.isNotEmpty) {
        encryptedFields['title'] = await _encryptionService.encryptSymmetric(
          event.title!,
          _getSymmetricKey(userId),
        );
      }
      
      // Encrypt description if present
      if (event.description != null && event.description!.isNotEmpty) {
        encryptedFields['description'] = await _encryptionService.encryptSymmetric(
          event.description!,
          _getSymmetricKey(userId),
        );
      }
      
      // Encrypt location if present
      if (event.location != null) {
        final locationJson = event.location!.toJson();
        encryptedFields['location'] = await _encryptionService.encryptSymmetric(
          json.encode(locationJson),
          _getSymmetricKey(userId),
        );
      }
      
      // Encrypt custom attributes if present
      if (event.customAttributes.isNotEmpty) {
        encryptedFields['customAttributes'] = await _encryptionService.encryptSymmetric(
          json.encode(event.customAttributes),
          _getSymmetricKey(userId),
        );
      }
      
      // Encrypt story if present
      if (event.story != null) {
        final storyJson = event.story!.toJson();
        encryptedFields['story'] = await _encryptionService.encryptSymmetric(
          json.encode(storyJson),
          _getSymmetricKey(userId),
        );
      }
      
      // Encrypt participant IDs for privacy
      if (event.participantIds.isNotEmpty) {
        encryptedFields['participantIds'] = await _encryptionService.encryptSymmetric(
          json.encode(event.participantIds),
          _getSymmetricKey(userId),
        );
      }
      
      // Encrypt media assets if present
      if (event.assets.isNotEmpty) {
        final assetsJson = event.assets.map((asset) => asset.toJson()).toList();
        encryptedFields['assets'] = await _encryptionService.encryptSymmetric(
          json.encode(assetsJson),
          _getSymmetricKey(userId),
        );
      }
      
      final encryptedEvent = EncryptedTimelineEvent(
        id: event.id,
        contextId: event.contextId,
        ownerId: event.ownerId,
        timestamp: event.timestamp,
        fuzzyDate: event.fuzzyDate,
        eventType: event.eventType,
        encryptedFields: encryptedFields,
        privacyLevel: event.privacyLevel,
        createdAt: event.createdAt,
        updatedAt: event.updatedAt,
        encryptionKeyId: keyPair.keyId,
        encryptionAlgorithm: keyPair.algorithm,
      );
      
      return encryptedEvent;
      
    } catch (e) {
      throw Exception('Failed to encrypt timeline event: $e');
    }
  }

  /// Decrypt a timeline event
  Future<TimelineEvent> decryptTimelineEvent(
    EncryptedTimelineEvent encryptedEvent,
    String userId,
  ) async {
    try {
      // Get user's decryption key
      final userKeyPairs = await _secureStorageService.getUserKeyPairs(userId);
      if (userKeyPairs.isEmpty) {
        throw Exception('No decryption keys found for user: $userId');
      }
      
      final keyPair = userKeyPairs.firstWhere(
        (kp) => kp.keyId == encryptedEvent.encryptionKeyId,
        orElse: () => userKeyPairs.first,
      );
      
      // Decrypt sensitive fields
      final decryptedFields = <String, dynamic>{};
      
      for (final entry in encryptedEvent.encryptedFields.entries) {
        try {
          final decryptedData = await _encryptionService.decryptSymmetric(
            entry.value,
            _getSymmetricKey(userId),
          );
          
          // Parse JSON for complex fields
          if (['location', 'customAttributes', 'story', 'participantIds', 'assets'].contains(entry.key)) {
            decryptedFields[entry.key] = json.decode(decryptedData);
          } else {
            decryptedFields[entry.key] = decryptedData;
          }
        } catch (e) {
          print('Failed to decrypt field ${entry.key}: $e');
          // Use default values for failed decryption
          decryptedFields[entry.key] = _getDefaultFieldValue(entry.key);
        }
      }
      
      // Reconstruct timeline event
      final event = TimelineEvent(
        id: encryptedEvent.id,
        contextId: encryptedEvent.contextId,
        ownerId: encryptedEvent.ownerId,
        timestamp: encryptedEvent.timestamp,
        fuzzyDate: encryptedEvent.fuzzyDate,
        location: decryptedFields['location'] != null 
            ? GeoLocation.fromJson(decryptedFields['location'])
            : null,
        eventType: encryptedEvent.eventType,
        customAttributes: decryptedFields['customAttributes'] ?? {},
        assets: decryptedFields['assets'] != null
            ? (decryptedFields['assets'] as List).map((asset) => MediaAsset.fromJson(asset)).toList()
            : [],
        title: decryptedFields['title'],
        description: decryptedFields['description'],
        story: decryptedFields['story'] != null
            ? Story.fromJson(decryptedFields['story'])
            : null,
        participantIds: decryptedFields['participantIds']?.cast<String>() ?? [],
        privacyLevel: encryptedEvent.privacyLevel,
        createdAt: encryptedEvent.createdAt,
        updatedAt: encryptedEvent.updatedAt,
      );
      
      return event;
      
    } catch (e) {
      throw Exception('Failed to decrypt timeline event: $e');
    }
  }

  /// Encrypt timeline data for sharing
  Future<SharedEncryptedData> encryptForSharing(
    TimelineEvent event,
    String ownerId,
    String recipientId,
  ) async {
    try {
      // Get shared secret between users
      final sharedSecrets = await _secureStorageService.getSharedSecretsBetweenUsers(
        ownerId,
        recipientId,
      );
      
      if (sharedSecrets.isEmpty) {
        // Generate new shared secret
        final ownerKeyPair = (await _secureStorageService.getUserKeyPairs(ownerId)).first;
        final recipientKeyPair = (await _secureStorageService.getUserKeyPairs(recipientId)).first;
        
        final sharedSecret = await _encryptionService.generateSharedSecret(
          ownerId,
          recipientId,
          ownerKeyPair.publicKey,
          recipientKeyPair.publicKey,
        );
        
        await _secureStorageService.storeSharedSecret(sharedSecret);
        sharedSecrets.add(sharedSecret);
      }
      
      final sharedSecret = sharedSecrets.first;
      
      // Get the actual shared secret key
      final ownerPrivateKey = (await _secureStorageService.getUserKeyPairs(ownerId)).first.privateKey;
      final secretKey = await _encryptionService.deriveSharedSecret(
        sharedSecret,
        ownerId,
        ownerPrivateKey,
      );
      
      // Encrypt the event data
      final eventJson = event.toJson();
      final encryptedData = await _encryptionService.encryptSymmetric(
        json.encode(eventJson),
        secretKey,
        additionalData: {
          'ownerId': ownerId,
          'recipientId': recipientId,
          'eventId': event.id,
        },
      );
      
      return SharedEncryptedData(
        dataId: const Uuid().v4(),
        eventId: event.id,
        ownerId: ownerId,
        recipientId: recipientId,
        encryptedData: encryptedData,
        sharedSecretId: sharedSecret.secretId,
        createdAt: DateTime.now(),
        expiresAt: DateTime.now().add(const Duration(days: 30)),
      );
      
    } catch (e) {
      throw Exception('Failed to encrypt data for sharing: $e');
    }
  }

  /// Decrypt shared timeline data
  Future<TimelineEvent> decryptSharedData(
    SharedEncryptedData sharedData,
    String userId,
  ) async {
    try {
      // Verify user is the intended recipient
      if (sharedData.recipientId != userId && sharedData.ownerId != userId) {
        throw Exception('User is not authorized to decrypt this shared data');
      }
      
      // Get shared secret
      final sharedSecret = await _secureStorageService.getSharedSecret(sharedData.sharedSecretId);
      if (sharedSecret == null) {
        throw Exception('Shared secret not found');
      }
      
      // Get user's private key
      final userKeyPairs = await _secureStorageService.getUserKeyPairs(userId);
      if (userKeyPairs.isEmpty) {
        throw Exception('No decryption keys found for user: $userId');
      }
      
      final privateKey = userKeyPairs.first.privateKey;
      
      // Derive the shared secret key
      final secretKey = await _encryptionService.deriveSharedSecret(
        sharedSecret,
        userId,
        privateKey,
      );
      
      // Decrypt the data
      final decryptedJson = await _encryptionService.decryptSymmetric(
        sharedData.encryptedData,
        secretKey,
      );
      
      final eventData = json.decode(decryptedJson) as Map<String, dynamic>;
      return TimelineEvent.fromJson(eventData);
      
    } catch (e) {
      throw Exception('Failed to decrypt shared data: $e');
    }
  }

  /// Encrypt user profile data
  Future<EncryptedUserProfile> encryptUserProfile(
    Map<String, dynamic> profileData,
    String userId,
  ) async {
    try {
      final symmetricKey = _getSymmetricKey(userId);
      
      // Encrypt sensitive profile fields
      final encryptedFields = <String, EncryptedData>{};
      
      final sensitiveFields = [
        'email', 'phone', 'address', 'birthDate', 
        'realName', 'personalBio', 'socialSecurityNumber'
      ];
      
      for (final field in sensitiveFields) {
        if (profileData.containsKey(field) && profileData[field] != null) {
          encryptedFields[field] = await _encryptionService.encryptSymmetric(
            profileData[field].toString(),
            symmetricKey,
          );
        }
      }
      
      return EncryptedUserProfile(
        userId: userId,
        publicData: Map.from(profileData)..removeWhere((key, value) => sensitiveFields.contains(key)),
        encryptedFields: encryptedFields,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
    } catch (e) {
      throw Exception('Failed to encrypt user profile: $e');
    }
  }

  /// Decrypt user profile data
  Future<Map<String, dynamic>> decryptUserProfile(
    EncryptedUserProfile encryptedProfile,
    String userId,
  ) async {
    try {
      final symmetricKey = _getSymmetricKey(userId);
      final decryptedProfile = Map<String, dynamic>.from(encryptedProfile.publicData);
      
      // Decrypt sensitive fields
      for (final entry in encryptedProfile.encryptedFields.entries) {
        try {
          final decryptedValue = await _encryptionService.decryptSymmetric(
            entry.value,
            symmetricKey,
          );
          decryptedProfile[entry.key] = decryptedValue;
        } catch (e) {
          print('Failed to decrypt profile field ${entry.key}: $e');
        }
      }
      
      return decryptedProfile;
      
    } catch (e) {
      throw Exception('Failed to decrypt user profile: $e');
    }
  }

  /// Batch encrypt multiple events
  Future<List<EncryptedTimelineEvent>> encryptBatchEvents(
    List<TimelineEvent> events,
    String userId,
  ) async {
    final encryptedEvents = <EncryptedTimelineEvent>[];
    
    for (final event in events) {
      try {
        final encryptedEvent = await encryptTimelineEvent(event, userId);
        encryptedEvents.add(encryptedEvent);
      } catch (e) {
        print('Failed to encrypt event ${event.id}: $e');
        // Continue with other events
      }
    }
    
    return encryptedEvents;
  }

  /// Batch decrypt multiple events
  Future<List<TimelineEvent>> decryptBatchEvents(
    List<EncryptedTimelineEvent> encryptedEvents,
    String userId,
  ) async {
    final decryptedEvents = <TimelineEvent>[];
    
    for (final encryptedEvent in encryptedEvents) {
      try {
        final event = await decryptTimelineEvent(encryptedEvent, userId);
        decryptedEvents.add(event);
      } catch (e) {
        print('Failed to decrypt event ${encryptedEvent.id}: $e');
        // Continue with other events
      }
    }
    
    return decryptedEvents;
  }

  /// Rotate encryption for user data
  Future<void> rotateUserDataEncryption(String userId) async {
    try {
      // Get current key pair
      final currentKeyPairs = await _secureStorageService.getUserKeyPairs(userId);
      if (currentKeyPairs.isEmpty) {
        throw Exception('No encryption keys found for user: $userId');
      }
      
      final currentKeyPair = currentKeyPairs.first;
      
      // Generate new key pair
      await _secureStorageService.rotateKeyPair(userId, currentKeyPair.keyId);
      
      // In a real implementation, this would trigger re-encryption of all user data
      print('Encryption rotation completed for user: $userId');
      
    } catch (e) {
      throw Exception('Failed to rotate user encryption: $e');
    }
  }

  /// Get encryption status for user
  Future<Map<String, dynamic>> getEncryptionStatus(String userId) async {
    try {
      final keyPairs = await _secureStorageService.getUserKeyPairs(userId);
      final symmetricKeys = await _secureStorageService.getUserSymmetricKeys(userId);
      final sharedSecrets = await _secureStorageService.getSharedSecretsBetweenUsers(userId, userId);
      
      return {
        'hasEncryptionKeys': keyPairs.isNotEmpty,
        'activeKeyPairs': keyPairs.length,
        'symmetricKeys': symmetricKeys.length,
        'sharedSecrets': sharedSecrets.length,
        'encryptionEnabled': keyPairs.isNotEmpty,
        'lastKeyRotation': keyPairs.isNotEmpty ? keyPairs.first.createdAt.toIso8601String() : null,
        'keyAlgorithm': keyPairs.isNotEmpty ? keyPairs.first.algorithm : null,
      };
      
    } catch (e) {
      return {
        'hasEncryptionKeys': false,
        'encryptionEnabled': false,
        'error': e.toString(),
      };
    }
  }

  // Private helper methods

  String _getSymmetricKey(String userId) {
    // In a real implementation, this would retrieve and decrypt the user's symmetric key
    // For now, return a mock key
    return 'symmetric_key_$userId';
  }

  dynamic _getDefaultFieldValue(String fieldName) {
    switch (fieldName) {
      case 'title':
      case 'description':
        return '';
      case 'location':
        return null;
      case 'customAttributes':
        return {};
      case 'story':
        return null;
      case 'participantIds':
        return [];
      case 'assets':
        return [];
      default:
        return null;
    }
  }
}

/// Encrypted timeline event model
class EncryptedTimelineEvent {
  final String id;
  final String contextId;
  final String ownerId;
  final DateTime timestamp;
  final FuzzyDate? fuzzyDate;
  final String eventType;
  final Map<String, EncryptedData> encryptedFields;
  final PrivacyLevel privacyLevel;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String encryptionKeyId;
  final String encryptionAlgorithm;

  const EncryptedTimelineEvent({
    required this.id,
    required this.contextId,
    required this.ownerId,
    required this.timestamp,
    this.fuzzyDate,
    required this.eventType,
    required this.encryptedFields,
    required this.privacyLevel,
    required this.createdAt,
    required this.updatedAt,
    required this.encryptionKeyId,
    required this.encryptionAlgorithm,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'contextId': contextId,
      'ownerId': ownerId,
      'timestamp': timestamp.toIso8601String(),
      'fuzzyDate': fuzzyDate?.toJson(),
      'eventType': eventType,
      'encryptedFields': encryptedFields.map((k, v) => MapEntry(k, v.toJson())),
      'privacyLevel': privacyLevel.name,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'encryptionKeyId': encryptionKeyId,
      'encryptionAlgorithm': encryptionAlgorithm,
    };
  }

  factory EncryptedTimelineEvent.fromJson(Map<String, dynamic> json) {
    return EncryptedTimelineEvent(
      id: json['id'],
      contextId: json['contextId'],
      ownerId: json['ownerId'],
      timestamp: DateTime.parse(json['timestamp']),
      fuzzyDate: json['fuzzyDate'] != null ? FuzzyDate.fromJson(json['fuzzyDate']) : null,
      eventType: json['eventType'],
      encryptedFields: (json['encryptedFields'] as Map<String, dynamic>).map(
        (k, v) => MapEntry(k, EncryptedData.fromJson(v)),
      ),
      privacyLevel: PrivacyLevel.values.firstWhere((level) => level.name == json['privacyLevel']),
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      encryptionKeyId: json['encryptionKeyId'],
      encryptionAlgorithm: json['encryptionAlgorithm'],
    );
  }
}

/// Shared encrypted data model
class SharedEncryptedData {
  final String dataId;
  final String eventId;
  final String ownerId;
  final String recipientId;
  final EncryptedData encryptedData;
  final String sharedSecretId;
  final DateTime createdAt;
  final DateTime? expiresAt;

  const SharedEncryptedData({
    required this.dataId,
    required this.eventId,
    required this.ownerId,
    required this.recipientId,
    required this.encryptedData,
    required this.sharedSecretId,
    required this.createdAt,
    this.expiresAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'dataId': dataId,
      'eventId': eventId,
      'ownerId': ownerId,
      'recipientId': recipientId,
      'encryptedData': encryptedData.toJson(),
      'sharedSecretId': sharedSecretId,
      'createdAt': createdAt.toIso8601String(),
      'expiresAt': expiresAt?.toIso8601String(),
    };
  }

  factory SharedEncryptedData.fromJson(Map<String, dynamic> json) {
    return SharedEncryptedData(
      dataId: json['dataId'],
      eventId: json['eventId'],
      ownerId: json['ownerId'],
      recipientId: json['recipientId'],
      encryptedData: EncryptedData.fromJson(json['encryptedData']),
      sharedSecretId: json['sharedSecretId'],
      createdAt: DateTime.parse(json['createdAt']),
      expiresAt: json['expiresAt'] != null ? DateTime.parse(json['expiresAt']) : null,
    );
  }
}

/// Encrypted user profile model
class EncryptedUserProfile {
  final String userId;
  final Map<String, dynamic> publicData;
  final Map<String, EncryptedData> encryptedFields;
  final DateTime createdAt;
  final DateTime updatedAt;

  const EncryptedUserProfile({
    required this.userId,
    required this.publicData,
    required this.encryptedFields,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'publicData': publicData,
      'encryptedFields': encryptedFields.map((k, v) => MapEntry(k, v.toJson())),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory EncryptedUserProfile.fromJson(Map<String, dynamic> json) {
    return EncryptedUserProfile(
      userId: json['userId'],
      publicData: json['publicData'],
      encryptedFields: (json['encryptedFields'] as Map<String, dynamic>).map(
        (k, v) => MapEntry(k, EncryptedData.fromJson(v)),
      ),
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }
}
