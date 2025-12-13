import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/equatable.dart';

part 'consent_models.g.dart';

/// Types of consent that can be requested
enum ConsentType {
  @JsonValue('data_processing')
  dataProcessing,
  @JsonValue('analytics')
  analytics,
  @JsonValue('marketing')
  marketing,
  @JsonValue('third_party_sharing')
  thirdPartySharing,
  @JsonValue('location_tracking')
  locationTracking,
  @JsonValue('biometric_auth')
  biometricAuth,
  @JsonValue('personalized_content')
  personalizedContent,
  @JsonValue('research_participation')
  researchParticipation,
  @JsonValue('emergency_contacts')
  emergencyContacts,
  @JsonValue('media_analysis')
  mediaAnalysis,
  @JsonValue('collaborative_features')
  collaborativeFeatures,
}

/// Status of a consent record
enum ConsentStatus {
  @JsonValue('pending')
  pending,
  @JsonValue('granted')
  granted,
  @JsonValue('denied')
  denied,
  @JsonValue('withdrawn')
  withdrawn,
  @JsonValue('expired')
  expired,
  @JsonValue('revoked')
  revoked,
}

/// Scope of consent (how broad or specific)
enum ConsentScope {
  @JsonValue('global')
  global,
  @JsonValue('feature_specific')
  featureSpecific,
  @JsonValue('time_limited')
  timeLimited,
  @JsonValue('contextual')
  contextual,
}

/// Consent record for tracking user permissions
@JsonSerializable()
class ConsentRecord extends Equatable {
  final String id;
  final String userId;
  final ConsentType consentType;
  final ConsentStatus status;
  final ConsentScope scope;
  final String? featureId; // Specific feature this consent applies to
  final String? context; // Context in which consent was requested
  final DateTime requestedAt;
  final DateTime? respondedAt;
  final DateTime? expiresAt;
  final DateTime? withdrawnAt;
  final String? requestMessage;
  final String? responseDetails;
  final Map<String, dynamic> metadata;
  final bool isGranular;
  final List<String> grantedPermissions;
  final List<String> deniedPermissions;
  final String? version; // Consent policy version
  final String? legalBasis; // Legal basis for processing

  const ConsentRecord({
    required this.id,
    required this.userId,
    required this.consentType,
    required this.status,
    required this.scope,
    this.featureId,
    this.context,
    required this.requestedAt,
    this.respondedAt,
    this.expiresAt,
    this.withdrawnAt,
    this.requestMessage,
    this.responseDetails,
    this.metadata = const {},
    this.isGranular = false,
    this.grantedPermissions = const [],
    this.deniedPermissions = const [],
    this.version,
    this.legalBasis,
  });

  factory ConsentRecord.fromJson(Map<String, dynamic> json) =>
      _$ConsentRecordFromJson(json);
  Map<String, dynamic> toJson() => _$ConsentRecordToJson(this);

  ConsentRecord copyWith({
    String? id,
    String? userId,
    ConsentType? consentType,
    ConsentStatus? status,
    ConsentScope? scope,
    String? featureId,
    String? context,
    DateTime? requestedAt,
    DateTime? respondedAt,
    DateTime? expiresAt,
    DateTime? withdrawnAt,
    String? requestMessage,
    String? responseDetails,
    Map<String, dynamic>? metadata,
    bool? isGranular,
    List<String>? grantedPermissions,
    List<String>? deniedPermissions,
    String? version,
    String? legalBasis,
  }) {
    return ConsentRecord(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      consentType: consentType ?? this.consentType,
      status: status ?? this.status,
      scope: scope ?? this.scope,
      featureId: featureId ?? this.featureId,
      context: context ?? this.context,
      requestedAt: requestedAt ?? this.requestedAt,
      respondedAt: respondedAt ?? this.respondedAt,
      expiresAt: expiresAt ?? this.expiresAt,
      withdrawnAt: withdrawnAt ?? this.withdrawnAt,
      requestMessage: requestMessage ?? this.requestMessage,
      responseDetails: responseDetails ?? this.responseDetails,
      metadata: metadata ?? this.metadata,
      isGranular: isGranular ?? this.isGranular,
      grantedPermissions: grantedPermissions ?? this.grantedPermissions,
      deniedPermissions: deniedPermissions ?? this.deniedPermissions,
      version: version ?? this.version,
      legalBasis: legalBasis ?? this.legalBasis,
    );
  }

  /// Check if consent is currently valid
  bool get isValid {
    final now = DateTime.now();
    
    // Check status
    if (status != ConsentStatus.granted) {
      return false;
    }
    
    // Check expiration
    if (expiresAt != null && now.isAfter(expiresAt!)) {
      return false;
    }
    
    // Check if withdrawn
    if (withdrawnAt != null && now.isAfter(withdrawnAt!)) {
      return false;
    }
    
    return true;
  }

  /// Check if consent has expired
  bool get isExpired {
    if (expiresAt == null) return false;
    return DateTime.now().isAfter(expiresAt!);
  }

  /// Check if consent has been withdrawn
  bool get isWithdrawn {
    if (withdrawnAt == null) return false;
    return DateTime.now().isAfter(withdrawnAt!);
  }

  /// Get days until expiration
  int? get daysUntilExpiration {
    if (expiresAt == null) return null;
    return expiresAt!.difference(DateTime.now()).inDays;
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        consentType,
        status,
        scope,
        featureId,
        context,
        requestedAt,
        respondedAt,
        expiresAt,
        withdrawnAt,
        requestMessage,
        responseDetails,
        metadata,
        isGranular,
        grantedPermissions,
        deniedPermissions,
        version,
        legalBasis,
      ];
}

/// Consent template for standardized requests
@JsonSerializable()
class ConsentTemplate extends Equatable {
  final String id;
  final String name;
  final String description;
  final ConsentType consentType;
  final ConsentScope defaultScope;
  final String requestMessage;
  final String detailedDescription;
  final List<String> requiredPermissions;
  final List<String> optionalPermissions;
  final Duration? defaultExpiration;
  final bool isGranular;
  final String legalBasis;
  final String privacyPolicyUrl;
  final String termsOfServiceUrl;
  final Map<String, dynamic> metadata;
  final DateTime createdAt;
  final DateTime? lastUpdated;
  final bool isActive;

  const ConsentTemplate({
    required this.id,
    required this.name,
    required this.description,
    required this.consentType,
    required this.defaultScope,
    required this.requestMessage,
    required this.detailedDescription,
    this.requiredPermissions = const [],
    this.optionalPermissions = const [],
    this.defaultExpiration,
    this.isGranular = false,
    required this.legalBasis,
    required this.privacyPolicyUrl,
    required this.termsOfServiceUrl,
    this.metadata = const {},
    required this.createdAt,
    this.lastUpdated,
    this.isActive = true,
  });

  factory ConsentTemplate.fromJson(Map<String, dynamic> json) =>
      _$ConsentTemplateFromJson(json);
  Map<String, dynamic> toJson() => _$ConsentTemplateToJson(this);

  ConsentTemplate copyWith({
    String? id,
    String? name,
    String? description,
    ConsentType? consentType,
    ConsentScope? defaultScope,
    String? requestMessage,
    String? detailedDescription,
    List<String>? requiredPermissions,
    List<String>? optionalPermissions,
    Duration? defaultExpiration,
    bool? isGranular,
    String? legalBasis,
    String? privacyPolicyUrl,
    String? termsOfServiceUrl,
    Map<String, dynamic>? metadata,
    DateTime? createdAt,
    DateTime? lastUpdated,
    bool? isActive,
  }) {
    return ConsentTemplate(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      consentType: consentType ?? this.consentType,
      defaultScope: defaultScope ?? this.defaultScope,
      requestMessage: requestMessage ?? this.requestMessage,
      detailedDescription: detailedDescription ?? this.detailedDescription,
      requiredPermissions: requiredPermissions ?? this.requiredPermissions,
      optionalPermissions: optionalPermissions ?? this.optionalPermissions,
      defaultExpiration: defaultExpiration ?? this.defaultExpiration,
      isGranular: isGranular ?? this.isGranular,
      legalBasis: legalBasis ?? this.legalBasis,
      privacyPolicyUrl: privacyPolicyUrl ?? this.privacyPolicyUrl,
      termsOfServiceUrl: termsOfServiceUrl ?? this.termsOfServiceUrl,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt ?? this.createdAt,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      isActive: isActive ?? this.isActive,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        description,
        consentType,
        defaultScope,
        requestMessage,
        detailedDescription,
        requiredPermissions,
        optionalPermissions,
        defaultExpiration,
        isGranular,
        legalBasis,
        privacyPolicyUrl,
        termsOfServiceUrl,
        metadata,
        createdAt,
        lastUpdated,
        isActive,
      ];
}

/// Consent request for tracking pending requests
@JsonSerializable()
class ConsentRequest extends Equatable {
  final String id;
  final String userId;
  final String templateId;
  final ConsentType consentType;
  final ConsentScope scope;
  final String? featureId;
  final String? context;
  final String requestMessage;
  final String detailedDescription;
  final List<String> requiredPermissions;
  final List<String> optionalPermissions;
  final DateTime requestedAt;
  final DateTime? expiresAt;
  final bool isUrgent;
  final int? maxRetries;
  final int currentRetries;
  final Map<String, dynamic> metadata;
  final ConsentRequestStatus status;

  const ConsentRequest({
    required this.id,
    required this.userId,
    required this.templateId,
    required this.consentType,
    required this.scope,
    this.featureId,
    this.context,
    required this.requestMessage,
    required this.detailedDescription,
    this.requiredPermissions = const [],
    this.optionalPermissions = const [],
    required this.requestedAt,
    this.expiresAt,
    this.isUrgent = false,
    this.maxRetries,
    this.currentRetries = 0,
    this.metadata = const {},
    required this.status,
  });

  factory ConsentRequest.fromJson(Map<String, dynamic> json) =>
      _$ConsentRequestFromJson(json);
  Map<String, dynamic> toJson() => _$ConsentRequestToJson(this);

  ConsentRequest copyWith({
    String? id,
    String? userId,
    String? templateId,
    ConsentType? consentType,
    ConsentScope? scope,
    String? featureId,
    String? context,
    String? requestMessage,
    String? detailedDescription,
    List<String>? requiredPermissions,
    List<String>? optionalPermissions,
    DateTime? requestedAt,
    DateTime? expiresAt,
    bool? isUrgent,
    int? maxRetries,
    int? currentRetries,
    Map<String, dynamic>? metadata,
    ConsentRequestStatus? status,
  }) {
    return ConsentRequest(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      templateId: templateId ?? this.templateId,
      consentType: consentType ?? this.consentType,
      scope: scope ?? this.scope,
      featureId: featureId ?? this.featureId,
      context: context ?? this.context,
      requestMessage: requestMessage ?? this.requestMessage,
      detailedDescription: detailedDescription ?? this.detailedDescription,
      requiredPermissions: requiredPermissions ?? this.requiredPermissions,
      optionalPermissions: optionalPermissions ?? this.optionalPermissions,
      requestedAt: requestedAt ?? this.requestedAt,
      expiresAt: expiresAt ?? this.expiresAt,
      isUrgent: isUrgent ?? this.isUrgent,
      maxRetries: maxRetries ?? this.maxRetries,
      currentRetries: currentRetries ?? this.currentRetries,
      metadata: metadata ?? this.metadata,
      status: status ?? this.status,
    );
  }

  /// Check if request has expired
  bool get isExpired {
    if (expiresAt == null) return false;
    return DateTime.now().isAfter(expiresAt!);
  }

  /// Check if max retries have been exceeded
  bool get maxRetriesExceeded {
    if (maxRetries == null) return false;
    return currentRetries >= maxRetries!;
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        templateId,
        consentType,
        scope,
        featureId,
        context,
        requestMessage,
        detailedDescription,
        requiredPermissions,
        optionalPermissions,
        requestedAt,
        expiresAt,
        isUrgent,
        maxRetries,
        currentRetries,
        metadata,
        status,
      ];
}

/// Status of consent requests
enum ConsentRequestStatus {
  @JsonValue('pending')
  pending,
  @JsonValue('responded')
  responded,
  @JsonValue('expired')
  expired,
  @JsonValue('cancelled')
  cancelled,
  @JsonValue('failed')
  failed,
}

/// User consent preferences for default behaviors
@JsonSerializable()
class ConsentPreferences extends Equatable {
  final String userId;
  final Map<ConsentType, ConsentStatus> defaultPreferences;
  final Map<String, ConsentStatus> featurePreferences;
  final bool requireExplicitConsent;
  final Duration defaultConsentDuration;
  final bool autoRenewConsent;
  final int consentReminderDays;
  final bool allowGranularConsent;
  final List<ConsentType> blockedConsentTypes;
  final Map<String, dynamic> metadata;
  final DateTime createdAt;
  final DateTime? lastUpdated;

  const ConsentPreferences({
    required this.userId,
    this.defaultPreferences = const {},
    this.featurePreferences = const {},
    this.requireExplicitConsent = true,
    this.defaultConsentDuration = const Duration(days: 365),
    this.autoRenewConsent = false,
    this.consentReminderDays = 30,
    this.allowGranularConsent = true,
    this.blockedConsentTypes = const [],
    this.metadata = const {},
    required this.createdAt,
    this.lastUpdated,
  });

  factory ConsentPreferences.fromJson(Map<String, dynamic> json) =>
      _$ConsentPreferencesFromJson(json);
  Map<String, dynamic> toJson() => _$ConsentPreferencesToJson(this);

  ConsentPreferences copyWith({
    String? userId,
    Map<ConsentType, ConsentStatus>? defaultPreferences,
    Map<String, ConsentStatus>? featurePreferences,
    bool? requireExplicitConsent,
    Duration? defaultConsentDuration,
    bool? autoRenewConsent,
    int? consentReminderDays,
    bool? allowGranularConsent,
    List<ConsentType>? blockedConsentTypes,
    Map<String, dynamic>? metadata,
    DateTime? createdAt,
    DateTime? lastUpdated,
  }) {
    return ConsentPreferences(
      userId: userId ?? this.userId,
      defaultPreferences: defaultPreferences ?? this.defaultPreferences,
      featurePreferences: featurePreferences ?? this.featurePreferences,
      requireExplicitConsent: requireExplicitConsent ?? this.requireExplicitConsent,
      defaultConsentDuration: defaultConsentDuration ?? this.defaultConsentDuration,
      autoRenewConsent: autoRenewConsent ?? this.autoRenewConsent,
      consentReminderDays: consentReminderDays ?? this.consentReminderDays,
      allowGranularConsent: allowGranularConsent ?? this.allowGranularConsent,
      blockedConsentTypes: blockedConsentTypes ?? this.blockedConsentTypes,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt ?? this.createdAt,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  /// Get default preference for a consent type
  ConsentStatus? getDefaultPreference(ConsentType consentType) {
    return defaultPreferences[consentType];
  }

  /// Get preference for a specific feature
  ConsentStatus? getFeaturePreference(String featureId) {
    return featurePreferences[featureId];
  }

  /// Check if consent type is blocked
  bool isConsentTypeBlocked(ConsentType consentType) {
    return blockedConsentTypes.contains(consentType);
  }

  @override
  List<Object?> get props => [
        userId,
        defaultPreferences,
        featurePreferences,
        requireExplicitConsent,
        defaultConsentDuration,
        autoRenewConsent,
        consentReminderDays,
        allowGranularConsent,
        blockedConsentTypes,
        metadata,
        createdAt,
        lastUpdated,
      ];
}

/// Consent audit entry for tracking consent changes
@JsonSerializable()
class ConsentAuditEntry extends Equatable {
  final String id;
  final String userId;
  final String? consentRecordId;
  final ConsentAuditAction action;
  final ConsentType? consentType;
  final ConsentStatus? previousStatus;
  final ConsentStatus? newStatus;
  final String? reason;
  final String? ipAddress;
  final String? userAgent;
  final DateTime timestamp;
  final Map<String, dynamic> metadata;

  const ConsentAuditEntry({
    required this.id,
    required this.userId,
    this.consentRecordId,
    required this.action,
    this.consentType,
    this.previousStatus,
    this.newStatus,
    this.reason,
    this.ipAddress,
    this.userAgent,
    required this.timestamp,
    this.metadata = const {},
  });

  factory ConsentAuditEntry.fromJson(Map<String, dynamic> json) =>
      _$ConsentAuditEntryFromJson(json);
  Map<String, dynamic> toJson() => _$ConsentAuditEntryToJson(this);

  @override
  List<Object?> get props => [
        id,
        userId,
        consentRecordId,
        action,
        consentType,
        previousStatus,
        newStatus,
        reason,
        ipAddress,
        userAgent,
        timestamp,
        metadata,
      ];
}

/// Types of consent audit actions
enum ConsentAuditAction {
  @JsonValue('requested')
  requested,
  @JsonValue('granted')
  granted,
  @JsonValue('denied')
  denied,
  @JsonValue('withdrawn')
  withdrawn,
  @JsonValue('expired')
  expired,
  @JsonValue('revoked')
  revoked,
  @JsonValue('renewed')
  renewed,
  @JsonValue('modified')
  modified,
  @JsonValue('exported')
  exported,
  @JsonValue('deleted')
  deleted,
}
