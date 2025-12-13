import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/consent_models.dart';

/// Provider for consent service
final consentServiceProvider = Provider((ref) => ConsentService());

/// Core consent management service
class ConsentService {
  final Map<String, ConsentRecord> _consentRecords = {};
  final Map<String, ConsentTemplate> _templates = {};
  final Map<String, ConsentRequest> _requests = {};
  final Map<String, ConsentPreferences> _preferences = {};
  final List<ConsentAuditEntry> _auditLog = [];
  
  final StreamController<ConsentRecord> _consentStreamController = 
      StreamController<ConsentRecord>.broadcast();
  final StreamController<ConsentRequest> _requestStreamController = 
      StreamController<ConsentRequest>.broadcast();

  Stream<ConsentRecord> get consentStream => _consentStreamController.stream;
  Stream<ConsentRequest> get requestStream => _requestStreamController.stream;

  ConsentService() {
    _initializeDefaultTemplates();
  }

  /// Request consent from a user
  Future<ConsentRequest> requestConsent({
    required String userId,
    required String templateId,
    String? featureId,
    String? context,
    Map<String, dynamic>? metadata,
    bool isUrgent = false,
  }) async {
    final template = _templates[templateId];
    if (template == null) {
      throw Exception('Consent template not found: $templateId');
    }

    // Check user preferences
    final preferences = _getUserPreferences(userId);
    if (preferences.isConsentTypeBlocked(template.consentType)) {
      throw Exception('Consent type ${template.consentType.name} is blocked by user preferences');
    }

    final requestId = const Uuid().v4();
    final request = ConsentRequest(
      id: requestId,
      userId: userId,
      templateId: templateId,
      consentType: template.consentType,
      scope: template.defaultScope,
      featureId: featureId,
      context: context,
      requestMessage: template.requestMessage,
      detailedDescription: template.detailedDescription,
      requiredPermissions: template.requiredPermissions,
      optionalPermissions: template.optionalPermissions,
      requestedAt: DateTime.now(),
      expiresAt: DateTime.now().add(const Duration(days: 30)),
      isUrgent: isUrgent,
      maxRetries: 3,
      metadata: metadata ?? {},
      status: ConsentRequestStatus.pending,
    );

    _requests[requestId] = request;
    _requestStreamController.add(request);

    // Add audit entry
    _addAuditEntry(ConsentAuditEntry(
      id: const Uuid().v4(),
      userId: userId,
      consentRecordId: requestId,
      action: ConsentAuditAction.requested,
      consentType: template.consentType,
      timestamp: DateTime.now(),
      metadata: metadata ?? {},
    ));

    return request;
  }

  /// Respond to a consent request
  Future<ConsentRecord> respondToConsentRequest({
    required String requestId,
    required ConsentStatus response,
    List<String>? grantedPermissions,
    List<String>? deniedPermissions,
    String? responseDetails,
    String? reason,
  }) async {
    final request = _requests[requestId];
    if (request == null) {
      throw Exception('Consent request not found: $requestId');
    }

    if (request.status != ConsentRequestStatus.pending) {
      throw Exception('Consent request is no longer pending');
    }

    if (request.isExpired) {
      throw Exception('Consent request has expired');
    }

    // Create consent record
    final consentRecordId = const Uuid().v4();
    final template = _templates[request.templateId]!;
    
    final consentRecord = ConsentRecord(
      id: consentRecordId,
      userId: request.userId,
      consentType: request.consentType,
      status: response,
      scope: request.scope,
      featureId: request.featureId,
      context: request.context,
      requestedAt: request.requestedAt,
      respondedAt: DateTime.now(),
      expiresAt: template.defaultExpiration != null 
          ? DateTime.now().add(template.defaultExpiration!)
          : null,
      requestMessage: request.requestMessage,
      responseDetails: responseDetails,
      metadata: request.metadata,
      isGranular: template.isGranular,
      grantedPermissions: grantedPermissions ?? [],
      deniedPermissions: deniedPermissions ?? [],
      version: '1.0',
      legalBasis: template.legalBasis,
    );

    _consentRecords[consentRecordId] = consentRecord;
    _consentStreamController.add(consentRecord);

    // Update request status
    _requests[requestId] = request.copyWith(
      status: ConsentRequestStatus.responded,
    );

    // Add audit entry
    _addAuditEntry(ConsentAuditEntry(
      id: const Uuid().v4(),
      userId: request.userId,
      consentRecordId: consentRecordId,
      action: _mapStatusToAction(response),
      consentType: request.consentType,
      newStatus: response,
      reason: reason,
      timestamp: DateTime.now(),
    ));

    return consentRecord;
  }

  /// Check if user has granted consent for a specific type
  bool hasConsent(String userId, ConsentType consentType, {String? featureId}) {
    var userConsents = _consentRecords.values.where((record) => 
        record.userId == userId && 
        record.consentType == consentType &&
        record.isValid).toList();

    if (featureId != null) {
      userConsents.retainWhere((record) => record.featureId == featureId);
    }

    return userConsents.isNotEmpty;
  }

  /// Get valid consent records for a user
  List<ConsentRecord> getUserConsents(String userId, {ConsentType? consentType}) {
    var consents = _consentRecords.values.where((record) => 
        record.userId == userId && record.isValid);

    if (consentType != null) {
      consents = consents.where((record) => record.consentType == consentType);
    }

    return consents.toList();
  }

  /// Get pending consent requests for a user
  List<ConsentRequest> getPendingRequests(String userId) {
    return _requests.values.where((request) => 
        request.userId == userId && 
        request.status == ConsentRequestStatus.pending &&
        !request.isExpired).toList();
  }

  /// Withdraw consent
  Future<void> withdrawConsent(String consentRecordId, {String? reason}) async {
    final record = _consentRecords[consentRecordId];
    if (record == null) {
      throw Exception('Consent record not found: $consentRecordId');
    }

    if (record.status != ConsentStatus.granted) {
      throw Exception('Cannot withdraw consent that is not granted');
    }

    final updatedRecord = record.copyWith(
      status: ConsentStatus.withdrawn,
      withdrawnAt: DateTime.now(),
    );

    _consentRecords[consentRecordId] = updatedRecord;
    _consentStreamController.add(updatedRecord);

    // Add audit entry
    _addAuditEntry(ConsentAuditEntry(
      id: const Uuid().v4(),
      userId: record.userId,
      consentRecordId: consentRecordId,
      action: ConsentAuditAction.withdrawn,
      consentType: record.consentType,
      previousStatus: ConsentStatus.granted,
      newStatus: ConsentStatus.withdrawn,
      reason: reason,
      timestamp: DateTime.now(),
    ));
  }

  /// Renew consent
  Future<ConsentRecord> renewConsent(String consentRecordId, {Duration? newDuration}) async {
    final record = _consentRecords[consentRecordId];
    if (record == null) {
      throw Exception('Consent record not found: $consentRecordId');
    }

    if (record.status != ConsentStatus.granted) {
      throw Exception('Cannot renew consent that is not granted');
    }

    final template = _templates.values.firstWhere(
      (t) => t.consentType == record.consentType,
      orElse: () => throw Exception('Template not found for consent type'),
    );

    final newExpiresAt = newDuration != null 
        ? DateTime.now().add(newDuration)
        : template.defaultExpiration != null 
            ? DateTime.now().add(template.defaultExpiration!)
            : null;

    final updatedRecord = record.copyWith(
      expiresAt: newExpiresAt,
      respondedAt: DateTime.now(), // Update response time for renewal
    );

    _consentRecords[consentRecordId] = updatedRecord;
    _consentStreamController.add(updatedRecord);

    // Add audit entry
    _addAuditEntry(ConsentAuditEntry(
      id: const Uuid().v4(),
      userId: record.userId,
      consentRecordId: consentRecordId,
      action: ConsentAuditAction.renewed,
      consentType: record.consentType,
      timestamp: DateTime.now(),
    ));

    return updatedRecord;
  }

  /// Get consent preferences for a user
  ConsentPreferences getUserPreferences(String userId) {
    return _preferences[userId] ?? _createDefaultPreferences(userId);
  }

  /// Update user consent preferences
  Future<void> updateUserPreferences(ConsentPreferences preferences) async {
    _preferences[preferences.userId] = preferences.copyWith(
      lastUpdated: DateTime.now(),
    );

    // Add audit entry
    _addAuditEntry(ConsentAuditEntry(
      id: const Uuid().v4(),
      userId: preferences.userId,
      action: ConsentAuditAction.modified,
      timestamp: DateTime.now(),
    ));
  }

  /// Get all consent templates
  List<ConsentTemplate> getTemplates({bool activeOnly = true}) {
    var templates = _templates.values;
    if (activeOnly) {
      templates = templates.where((t) => t.isActive);
    }
    return templates.toList();
  }

  /// Get consent template by ID
  ConsentTemplate? getTemplate(String templateId) {
    return _templates[templateId];
  }

  /// Create new consent template
  Future<void> createTemplate(ConsentTemplate template) async {
    _templates[template.id] = template;

    // Add audit entry
    _addAuditEntry(ConsentAuditEntry(
      id: const Uuid().v4(),
      userId: 'system',
      action: ConsentAuditAction.modified,
      timestamp: DateTime.now(),
      metadata: {'templateId': template.id},
    ));
  }

  /// Get consent audit log
  List<ConsentAuditEntry> getAuditLog({String? userId, ConsentType? consentType}) {
    var filteredLog = _auditLog;
    
    if (userId != null) {
      filteredLog = filteredLog.where((entry) => entry.userId == userId).toList();
    }
    
    if (consentType != null) {
      filteredLog = filteredLog.where((entry) => entry.consentType == consentType).toList();
    }
    
    return filteredLog;
  }

  /// Get consents that are expiring soon
  List<ConsentRecord> getExpiringConsents({Duration within = const Duration(days: 7)}) {
    final now = DateTime.now();
    final expiryThreshold = now.add(within);
    
    return _consentRecords.values
        .where((record) => 
            record.status == ConsentStatus.granted &&
            record.expiresAt != null && 
            record.expiresAt!.isBefore(expiryThreshold))
        .toList();
  }

  /// Clean up expired consent requests
  Future<void> cleanupExpiredRequests() async {
    final now = DateTime.now();
    final expiredRequests = _requests.entries
        .where((entry) => 
            entry.value.expiresAt != null && 
            entry.value.expiresAt!.isBefore(now))
        .map((entry) => entry.key)
        .toList();

    for (final requestId in expiredRequests) {
      final request = _requests[requestId]!;
      _requests[requestId] = request.copyWith(
        status: ConsentRequestStatus.expired,
      );
    }
  }

  /// Auto-renew consents if user has enabled it
  Future<void> processAutoRenewals() async {
    final now = DateTime.now();
    final expiringSoon = _consentRecords.values
        .where((record) => 
            record.status == ConsentStatus.granted &&
            record.expiresAt != null &&
            record.expiresAt!.difference(now).inDays <= 7)
        .toList();

    for (final record in expiringSoon) {
      final preferences = _getUserPreferences(record.userId);
      if (preferences.autoRenewConsent) {
        try {
          await renewConsent(record.id);
        } catch (e) {
          print('Failed to auto-renew consent ${record.id}: $e');
        }
      }
    }
  }

  /// Get consent statistics
  Map<String, dynamic> getConsentStatistics() {
    final totalRecords = _consentRecords.length;
    final grantedRecords = _consentRecords.values.where((r) => r.status == ConsentStatus.granted).length;
    final deniedRecords = _consentRecords.values.where((r) => r.status == ConsentStatus.denied).length;
    final withdrawnRecords = _consentRecords.values.where((r) => r.status == ConsentStatus.withdrawn).length;
    final expiredRecords = _consentRecords.values.where((r) => r.status == ConsentStatus.expired).length;
    final pendingRequests = _requests.values.where((r) => r.status == ConsentRequestStatus.pending).length;

    return {
      'totalConsentRecords': totalRecords,
      'grantedConsents': grantedRecords,
      'deniedConsents': deniedRecords,
      'withdrawnConsents': withdrawnRecords,
      'expiredConsents': expiredRecords,
      'pendingRequests': pendingRequests,
      'activeTemplates': _templates.values.where((t) => t.isActive).length,
      'totalTemplates': _templates.length,
    };
  }

  /// Export user consent data (GDPR compliance)
  Map<String, dynamic> exportUserData(String userId) {
    final userConsents = getUserConsents(userId);
    final userPreferences = getUserPreferences(userId);
    final userAuditLog = getAuditLog(userId: userId);

    return {
      'userId': userId,
      'consentRecords': userConsents.map((c) => c.toJson()).toList(),
      'preferences': userPreferences.toJson(),
      'auditLog': userAuditLog.map((e) => e.toJson()).toList(),
      'exportedAt': DateTime.now().toIso8601String(),
    };
  }

  /// Delete user consent data (right to be forgotten)
  Future<void> deleteUserData(String userId) async {
    // Remove consent records
    final userConsentIds = _consentRecords.entries
        .where((entry) => entry.value.userId == userId)
        .map((entry) => entry.key)
        .toList();
    
    for (final id in userConsentIds) {
      _consentRecords.remove(id);
    }

    // Remove requests
    final userRequestIds = _requests.entries
        .where((entry) => entry.value.userId == userId)
        .map((entry) => entry.key)
        .toList();
    
    for (final id in userRequestIds) {
      _requests.remove(id);
    }

    // Remove preferences
    _preferences.remove(userId);

    // Add audit entry
    _addAuditEntry(ConsentAuditEntry(
      id: const Uuid().v4(),
      userId: userId,
      action: ConsentAuditAction.deleted,
      timestamp: DateTime.now(),
    ));
  }

  // Private helper methods

  void _initializeDefaultTemplates() {
    final now = DateTime.now();

    // Data processing consent
    _templates['data_processing'] = ConsentTemplate(
      id: 'data_processing',
      name: 'Data Processing',
      description: 'Consent for processing your personal data',
      consentType: ConsentType.dataProcessing,
      defaultScope: ConsentScope.global,
      requestMessage: 'We need your consent to process your personal data to provide timeline services.',
      detailedDescription: 'This includes storing your timeline events, personal information, and preferences to provide you with a personalized experience.',
      requiredPermissions: ['store_data', 'process_events'],
      optionalPermissions: ['analytics', 'personalization'],
      defaultExpiration: const Duration(days: 365),
      isGranular: true,
      legalBasis: 'Legitimate interest - service provision',
      privacyPolicyUrl: 'https://example.com/privacy',
      termsOfServiceUrl: 'https://example.com/terms',
      createdAt: now,
    );

    // Analytics consent
    _templates['analytics'] = ConsentTemplate(
      id: 'analytics',
      name: 'Analytics and Usage Data',
      description: 'Consent for collecting analytics data',
      consentType: ConsentType.analytics,
      defaultScope: ConsentScope.global,
      requestMessage: 'Help us improve by allowing us to collect anonymous usage analytics.',
      detailedDescription: 'We collect anonymous data about how you use the app to improve our services and user experience.',
      requiredPermissions: ['basic_analytics'],
      optionalPermissions: ['detailed_analytics', 'crash_reporting'],
      defaultExpiration: const Duration(days: 365),
      isGranular: true,
      legalBasis: 'Legitimate interest - service improvement',
      privacyPolicyUrl: 'https://example.com/privacy',
      termsOfServiceUrl: 'https://example.com/terms',
      createdAt: now,
    );

    // Location tracking consent
    _templates['location_tracking'] = ConsentTemplate(
      id: 'location_tracking',
      name: 'Location Services',
      description: 'Consent for location tracking',
      consentType: ConsentType.locationTracking,
      defaultScope: ConsentScope.featureSpecific,
      requestMessage: 'Allow location tracking to enhance your timeline with location data.',
      detailedDescription: 'We can automatically add location information to your timeline events when you enable location services.',
      requiredPermissions: ['location_access'],
      optionalPermissions: ['background_location', 'location_history'],
      defaultExpiration: const Duration(days: 365),
      isGranular: true,
      legalBasis: 'Explicit consent',
      privacyPolicyUrl: 'https://example.com/privacy',
      termsOfServiceUrl: 'https://example.com/terms',
      createdAt: now,
    );

    // Collaborative features consent
    _templates['collaborative_features'] = ConsentTemplate(
      id: 'collaborative_features',
      name: 'Collaborative Features',
      description: 'Consent for collaborative timeline features',
      consentType: ConsentType.collaborativeFeatures,
      defaultScope: ConsentScope.global,
      requestMessage: 'Enable collaborative features to share and edit timelines with others.',
      detailedDescription: 'Collaborative features allow you to share timeline events, co-edit stories, and connect with other users.',
      requiredPermissions: ['share_events', 'collaborative_editing'],
      optionalPermissions: ['public_sharing', 'find_connections'],
      defaultExpiration: const Duration(days: 365),
      isGranular: true,
      legalBasis: 'Explicit consent',
      privacyPolicyUrl: 'https://example.com/privacy',
      termsOfServiceUrl: 'https://example.com/terms',
      createdAt: now,
    );
  }

  ConsentPreferences _getUserPreferences(String userId) {
    return _preferences[userId] ?? _createDefaultPreferences(userId);
  }

  ConsentPreferences _createDefaultPreferences(String userId) {
    return ConsentPreferences(
      userId: userId,
      defaultPreferences: {
        ConsentType.dataProcessing: ConsentStatus.pending,
        ConsentType.analytics: ConsentStatus.denied,
        ConsentType.locationTracking: ConsentStatus.pending,
        ConsentType.collaborativeFeatures: ConsentStatus.pending,
      },
      createdAt: DateTime.now(),
    );
  }

  ConsentAuditAction _mapStatusToAction(ConsentStatus status) {
    switch (status) {
      case ConsentStatus.granted:
        return ConsentAuditAction.granted;
      case ConsentStatus.denied:
        return ConsentAuditAction.denied;
      case ConsentStatus.withdrawn:
        return ConsentAuditAction.withdrawn;
      case ConsentStatus.expired:
        return ConsentAuditAction.expired;
      case ConsentStatus.revoked:
        return ConsentAuditAction.revoked;
      case ConsentStatus.pending:
        return ConsentAuditAction.requested;
    }
  }

  void _addAuditEntry(ConsentAuditEntry entry) {
    _auditLog.add(entry);
    
    // Keep audit log size manageable
    if (_auditLog.length > 10000) {
      _auditLog.removeRange(0, _auditLog.length - 10000);
    }
  }

  void dispose() {
    _consentStreamController.close();
    _requestStreamController.close();
  }
}

/// Extension methods for consent types
extension ConsentTypeExtension on ConsentType {
  String get displayName {
    switch (this) {
      case ConsentType.dataProcessing:
        return 'Data Processing';
      case ConsentType.analytics:
        return 'Analytics';
      case ConsentType.marketing:
        return 'Marketing';
      case ConsentType.thirdPartySharing:
        return 'Third Party Sharing';
      case ConsentType.locationTracking:
        return 'Location Tracking';
      case ConsentType.biometricAuth:
        return 'Biometric Authentication';
      case ConsentType.personalizedContent:
        return 'Personalized Content';
      case ConsentType.researchParticipation:
        return 'Research Participation';
      case ConsentType.emergencyContacts:
        return 'Emergency Contacts';
      case ConsentType.mediaAnalysis:
        return 'Media Analysis';
      case ConsentType.collaborativeFeatures:
        return 'Collaborative Features';
    }
  }

  String get description {
    switch (this) {
      case ConsentType.dataProcessing:
        return 'Processing of personal data for service provision';
      case ConsentType.analytics:
        return 'Collection of usage analytics for service improvement';
      case ConsentType.marketing:
        return 'Marketing communications and promotional content';
      case ConsentType.thirdPartySharing:
        return 'Sharing data with third-party services';
      case ConsentType.locationTracking:
        return 'Access to device location services';
      case ConsentType.biometricAuth:
        return 'Use of biometric data for authentication';
      case ConsentType.personalizedContent:
        return 'Personalization of content and recommendations';
      case ConsentType.researchParticipation:
        return 'Participation in research studies';
      case ConsentType.emergencyContacts:
        return 'Access to emergency contact information';
      case ConsentType.mediaAnalysis:
        return 'Analysis of uploaded media content';
      case ConsentType.collaborativeFeatures:
        return 'Sharing and collaborative editing features';
    }
  }

  String get iconName {
    switch (this) {
      case ConsentType.dataProcessing:
        return 'storage';
      case ConsentType.analytics:
        return 'analytics';
      case ConsentType.marketing:
        return 'campaign';
      case ConsentType.thirdPartySharing:
        return 'share';
      case ConsentType.locationTracking:
        return 'location_on';
      case ConsentType.biometricAuth:
        return 'fingerprint';
      case ConsentType.personalizedContent:
        return 'recommend';
      case ConsentType.researchParticipation:
        return 'science';
      case ConsentType.emergencyContacts:
        return 'emergency';
      case ConsentType.mediaAnalysis:
        return 'image_search';
      case ConsentType.collaborativeFeatures:
        return 'groups';
    }
  }
}

/// Extension methods for consent status
extension ConsentStatusExtension on ConsentStatus {
  String get displayName {
    switch (this) {
      case ConsentStatus.pending:
        return 'Pending';
      case ConsentStatus.granted:
        return 'Granted';
      case ConsentStatus.denied:
        return 'Denied';
      case ConsentStatus.withdrawn:
        return 'Withdrawn';
      case ConsentStatus.expired:
        return 'Expired';
      case ConsentStatus.revoked:
        return 'Revoked';
    }
  }

  String get description {
    switch (this) {
      case ConsentStatus.pending:
        return 'Waiting for user response';
      case ConsentStatus.granted:
        return 'User has given consent';
      case ConsentStatus.denied:
        return 'User has denied consent';
      case ConsentStatus.withdrawn:
        return 'User has withdrawn consent';
      case ConsentStatus.expired:
        return 'Consent has expired';
      case ConsentStatus.revoked:
        return 'Consent has been revoked';
    }
  }

  Color get color {
    switch (this) {
      case ConsentStatus.pending:
        return Colors.orange;
      case ConsentStatus.granted:
        return Colors.green;
      case ConsentStatus.denied:
        return Colors.red;
      case ConsentStatus.withdrawn:
        return Colors.grey;
      case ConsentStatus.expired:
        return Colors.grey;
      case ConsentStatus.revoked:
        return Colors.red;
    }
  }
}
