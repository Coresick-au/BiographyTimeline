import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/equatable.dart';

part 'data_sovereignty_models.g.dart';

/// Data residency regions for compliance
enum DataResidencyRegion {
  @JsonValue('global')
  global,
  @JsonValue('united_states')
  unitedStates,
  @JsonValue('european_union')
  europeanUnion,
  @JsonValue('united_kingdom')
  unitedKingdom,
  @JsonValue('canada')
  canada,
  @JsonValue('australia')
  australia,
  @JsonValue('japan')
  japan,
  @JsonValue('singapore')
  singapore,
  @JsonValue('switzerland')
  switzerland,
  @JsonValue('brazil')
  brazil,
  @JsonValue('india')
  india,
  @JsonValue('china')
  china,
  @JsonValue('russia')
  russia,
  @JsonValue('south_korea')
  southKorea,
  @JsonValue('mexico')
  mexico,
  @JsonValue('argentina')
  argentina,
  @JsonValue('south_africa')
  southAfrica,
  @JsonValue('uae')
  uae,
  @JsonValue('saudi_arabia')
  saudiArabia,
  @JsonValue('israel')
  israel,
  @JsonValue('new_zealand')
  newZealand,
  @JsonValue('norway')
  norway,
  @JsonValue('iceland')
  iceland,
  @JsonValue('liechtenstein')
  liechtenstein,
}

/// Data sovereignty compliance frameworks
enum ComplianceFramework {
  @JsonValue('gdpr')
  gdpr,
  @JsonValue('ccpa')
  ccpa,
  @JsonValue('lgpd')
  lgpd,
  @JsonValue('pipeda')
  pipeda,
  @JsonValue('pdpa')
  pdpa,
  @JsonValue('apci')
  apci,
  @JsonValue('pdpa_singapore')
  pdpaSingapore,
  @JsonValue('dpa_uk')
  dpaUk,
  @JsonValue('fisma')
  fisma,
  @JsonValue('hipaa')
  hipaa,
  @JsonValue('sox')
  sox,
  @JsonValue('iso27001')
  iso27001,
  @JsonValue('soc2')
  soc2,
  @JsonValue('nist')
  nist,
}

/// Data classification levels
enum DataClassification {
  @JsonValue('public')
  public,
  @JsonValue('internal')
  internal,
  @JsonValue('confidential')
  confidential,
  @JsonValue('restricted')
  restricted,
  @JsonValue('sensitive')
  sensitive,
  @JsonValue('personal')
  personal,
  @JsonValue('special_category')
  specialCategory,
}

/// Data localization requirements
enum DataLocalizationRequirement {
  @JsonValue('none')
  none,
  @JsonValue('storage_only')
  storageOnly,
  @JsonValue('processing_only')
  processingOnly,
  @JsonValue('storage_and_processing')
  storageAndProcessing,
  @JsonValue('backup_only')
  backupOnly,
  @JsonValue('cross_border_restricted')
  crossBorderRestricted,
}

/// Data sovereignty policy
@JsonSerializable()
class DataSovereigntyPolicy extends Equatable {
  final String id;
  final String name;
  final String description;
  final DataResidencyRegion primaryRegion;
  final List<DataResidencyRegion> allowedRegions;
  final List<DataResidencyRegion> restrictedRegions;
  final List<ComplianceFramework> complianceFrameworks;
  final DataLocalizationRequirement localizationRequirement;
  final Map<String, DataClassification> dataClassifications;
  final bool requireExplicitConsent;
  final bool allowCrossBorderTransfer;
  final Duration dataRetentionPeriod;
  final bool enableRightToBeForgotten;
  final bool enableDataPortability;
  final bool requireAuditLogging;
  final String encryptionStandard;
  final Map<String, dynamic> regionalRequirements;
  final DateTime createdAt;
  final DateTime? lastUpdated;
  final bool isActive;

  const DataSovereigntyPolicy({
    required this.id,
    required this.name,
    required this.description,
    required this.primaryRegion,
    this.allowedRegions = const [],
    this.restrictedRegions = const [],
    this.complianceFrameworks = const [],
    required this.localizationRequirement,
    this.dataClassifications = const {},
    this.requireExplicitConsent = true,
    this.allowCrossBorderTransfer = false,
    required this.dataRetentionPeriod,
    this.enableRightToBeForgotten = true,
    this.enableDataPortability = true,
    this.requireAuditLogging = true,
    required this.encryptionStandard,
    this.regionalRequirements = const {},
    required this.createdAt,
    this.lastUpdated,
    this.isActive = true,
  });

  factory DataSovereigntyPolicy.fromJson(Map<String, dynamic> json) =>
      _$DataSovereigntyPolicyFromJson(json);
  Map<String, dynamic> toJson() => _$DataSovereigntyPolicyToJson(this);

  DataSovereigntyPolicy copyWith({
    String? id,
    String? name,
    String? description,
    DataResidencyRegion? primaryRegion,
    List<DataResidencyRegion>? allowedRegions,
    List<DataResidencyRegion>? restrictedRegions,
    List<ComplianceFramework>? complianceFrameworks,
    DataLocalizationRequirement? localizationRequirement,
    Map<String, DataClassification>? dataClassifications,
    bool? requireExplicitConsent,
    bool? allowCrossBorderTransfer,
    Duration? dataRetentionPeriod,
    bool? enableRightToBeForgotten,
    bool? enableDataPortability,
    bool? requireAuditLogging,
    String? encryptionStandard,
    Map<String, dynamic>? regionalRequirements,
    DateTime? createdAt,
    DateTime? lastUpdated,
    bool? isActive,
  }) {
    return DataSovereigntyPolicy(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      primaryRegion: primaryRegion ?? this.primaryRegion,
      allowedRegions: allowedRegions ?? this.allowedRegions,
      restrictedRegions: restrictedRegions ?? this.restrictedRegions,
      complianceFrameworks: complianceFrameworks ?? this.complianceFrameworks,
      localizationRequirement: localizationRequirement ?? this.localizationRequirement,
      dataClassifications: dataClassifications ?? this.dataClassifications,
      requireExplicitConsent: requireExplicitConsent ?? this.requireExplicitConsent,
      allowCrossBorderTransfer: allowCrossBorderTransfer ?? this.allowCrossBorderTransfer,
      dataRetentionPeriod: dataRetentionPeriod ?? this.dataRetentionPeriod,
      enableRightToBeForgotten: enableRightToBeForgotten ?? this.enableRightToBeForgotten,
      enableDataPortability: enableDataPortability ?? this.enableDataPortability,
      requireAuditLogging: requireAuditLogging ?? this.requireAuditLogging,
      encryptionStandard: encryptionStandard ?? this.encryptionStandard,
      regionalRequirements: regionalRequirements ?? this.regionalRequirements,
      createdAt: createdAt ?? this.createdAt,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      isActive: isActive ?? this.isActive,
    );
  }

  /// Check if a region is allowed for data storage/processing
  bool isRegionAllowed(DataResidencyRegion region) {
    if (restrictedRegions.contains(region)) {
      return false;
    }
    return allowedRegions.isEmpty || allowedRegions.contains(region);
  }

  /// Check if cross-border data transfer is allowed
  bool isCrossBorderTransferAllowed(DataResidencyRegion from, DataResidencyRegion to) {
    if (!allowCrossBorderTransfer) {
      return false;
    }
    return isRegionAllowed(from) && isRegionAllowed(to);
  }

  @override
  List<Object?> get props => [
        id,
        name,
        description,
        primaryRegion,
        allowedRegions,
        restrictedRegions,
        complianceFrameworks,
        localizationRequirement,
        dataClassifications,
        requireExplicitConsent,
        allowCrossBorderTransfer,
        dataRetentionPeriod,
        enableRightToBeForgotten,
        enableDataPortability,
        requireAuditLogging,
        encryptionStandard,
        regionalRequirements,
        createdAt,
        lastUpdated,
        isActive,
      ];
}

/// Data residency record for tracking data location
@JsonSerializable()
class DataResidencyRecord extends Equatable {
  final String id;
  final String userId;
  final String dataType;
  final String dataId;
  final DataResidencyRegion storageRegion;
  final DataResidencyRegion? processingRegion;
  final DataClassification classification;
  final DateTime createdAt;
  final DateTime? lastAccessed;
  final DateTime? expiresAt;
  final bool isEncrypted;
  final String encryptionKeyId;
  final Map<String, dynamic> metadata;
  final List<String> complianceTags;

  const DataResidencyRecord({
    required this.id,
    required this.userId,
    required this.dataType,
    required this.dataId,
    required this.storageRegion,
    this.processingRegion,
    required this.classification,
    required this.createdAt,
    this.lastAccessed,
    this.expiresAt,
    this.isEncrypted = true,
    required this.encryptionKeyId,
    this.metadata = const {},
    this.complianceTags = const [],
  });

  factory DataResidencyRecord.fromJson(Map<String, dynamic> json) =>
      _$DataResidencyRecordFromJson(json);
  Map<String, dynamic> toJson() => _$DataResidencyRecordToJson(this);

  DataResidencyRecord copyWith({
    String? id,
    String? userId,
    String? dataType,
    String? dataId,
    DataResidencyRegion? storageRegion,
    DataResidencyRegion? processingRegion,
    DataClassification? classification,
    DateTime? createdAt,
    DateTime? lastAccessed,
    DateTime? expiresAt,
    bool? isEncrypted,
    String? encryptionKeyId,
    Map<String, dynamic>? metadata,
    List<String>? complianceTags,
  }) {
    return DataResidencyRecord(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      dataType: dataType ?? this.dataType,
      dataId: dataId ?? this.dataId,
      storageRegion: storageRegion ?? this.storageRegion,
      processingRegion: processingRegion ?? this.processingRegion,
      classification: classification ?? this.classification,
      createdAt: createdAt ?? this.createdAt,
      lastAccessed: lastAccessed ?? this.lastAccessed,
      expiresAt: expiresAt ?? this.expiresAt,
      isEncrypted: isEncrypted ?? this.isEncrypted,
      encryptionKeyId: encryptionKeyId ?? this.encryptionKeyId,
      metadata: metadata ?? this.metadata,
      complianceTags: complianceTags ?? this.complianceTags,
    );
  }

  /// Check if the data record is expired
  bool get isExpired {
    if (expiresAt == null) return false;
    return DateTime.now().isAfter(expiresAt!);
  }

  /// Check if the data record needs retention review
  bool get needsRetentionReview {
    if (expiresAt == null) return false;
    final reviewThreshold = expiresAt!.subtract(const Duration(days: 30));
    return DateTime.now().isAfter(reviewThreshold);
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        dataType,
        dataId,
        storageRegion,
        processingRegion,
        classification,
        createdAt,
        lastAccessed,
        expiresAt,
        isEncrypted,
        encryptionKeyId,
        metadata,
        complianceTags,
      ];
}

/// Cross-border data transfer request
@JsonSerializable()
class CrossBorderTransferRequest extends Equatable {
  final String id;
  final String userId;
  final String dataId;
  final DataResidencyRegion fromRegion;
  final DataResidencyRegion toRegion;
  final String transferReason;
  final List<ComplianceFramework> complianceFrameworks;
  final DateTime requestedAt;
  final DateTime? approvedAt;
  final DateTime? completedAt;
  final CrossBorderTransferStatus status;
  final String? approvedBy;
  final String? rejectionReason;
  final Map<String, dynamic> metadata;
  final List<String> requiredConsents;
  final List<String> obtainedConsents;

  const CrossBorderTransferRequest({
    required this.id,
    required this.userId,
    required this.dataId,
    required this.fromRegion,
    required this.toRegion,
    required this.transferReason,
    this.complianceFrameworks = const [],
    required this.requestedAt,
    this.approvedAt,
    this.completedAt,
    required this.status,
    this.approvedBy,
    this.rejectionReason,
    this.metadata = const {},
    this.requiredConsents = const [],
    this.obtainedConsents = const [],
  });

  factory CrossBorderTransferRequest.fromJson(Map<String, dynamic> json) =>
      _$CrossBorderTransferRequestFromJson(json);
  Map<String, dynamic> toJson() => _$CrossBorderTransferRequestToJson(this);

  CrossBorderTransferRequest copyWith({
    String? id,
    String? userId,
    String? dataId,
    DataResidencyRegion? fromRegion,
    DataResidencyRegion? toRegion,
    String? transferReason,
    List<ComplianceFramework>? complianceFrameworks,
    DateTime? requestedAt,
    DateTime? approvedAt,
    DateTime? completedAt,
    CrossBorderTransferStatus? status,
    String? approvedBy,
    String? rejectionReason,
    Map<String, dynamic>? metadata,
    List<String>? requiredConsents,
    List<String>? obtainedConsents,
  }) {
    return CrossBorderTransferRequest(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      dataId: dataId ?? this.dataId,
      fromRegion: fromRegion ?? this.fromRegion,
      toRegion: toRegion ?? this.toRegion,
      transferReason: transferReason ?? this.transferReason,
      complianceFrameworks: complianceFrameworks ?? this.complianceFrameworks,
      requestedAt: requestedAt ?? this.requestedAt,
      approvedAt: approvedAt ?? this.approvedAt,
      completedAt: completedAt ?? this.completedAt,
      status: status ?? this.status,
      approvedBy: approvedBy ?? this.approvedBy,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      metadata: metadata ?? this.metadata,
      requiredConsents: requiredConsents ?? this.requiredConsents,
      obtainedConsents: obtainedConsents ?? this.obtainedConsents,
    );
  }

  /// Check if all required consents have been obtained
  bool get hasAllRequiredConsents {
    return requiredConsents.every((consent) => obtainedConsents.contains(consent));
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        dataId,
        fromRegion,
        toRegion,
        transferReason,
        complianceFrameworks,
        requestedAt,
        approvedAt,
        completedAt,
        status,
        approvedBy,
        rejectionReason,
        metadata,
        requiredConsents,
        obtainedConsents,
      ];
}

/// Status of cross-border transfer requests
enum CrossBorderTransferStatus {
  @JsonValue('pending')
  pending,
  @JsonValue('approved')
  approved,
  @JsonValue('rejected')
  rejected,
  @JsonValue('completed')
  completed,
  @JsonValue('cancelled')
  cancelled,
  @JsonValue('expired')
  expired,
}

/// Data subject rights request
@JsonSerializable()
class DataSubjectRightsRequest extends Equatable {
  final String id;
  final String userId;
  final DataSubjectRightsType rightsType;
  final String description;
  final List<String> dataTypes;
  final DateTime requestedAt;
  final DateTime? processedAt;
  final DataSubjectRightsStatus status;
  final String? processedBy;
  final String? notes;
  final Map<String, dynamic> metadata;
  final List<String> supportingDocuments;
  final DateTime? expectedCompletion;

  const DataSubjectRightsRequest({
    required this.id,
    required this.userId,
    required this.rightsType,
    required this.description,
    this.dataTypes = const [],
    required this.requestedAt,
    this.processedAt,
    required this.status,
    this.processedBy,
    this.notes,
    this.metadata = const {},
    this.supportingDocuments = const [],
    this.expectedCompletion,
  });

  factory DataSubjectRightsRequest.fromJson(Map<String, dynamic> json) =>
      _$DataSubjectRightsRequestFromJson(json);
  Map<String, dynamic> toJson() => _$DataSubjectRightsRequestToJson(this);

  DataSubjectRightsRequest copyWith({
    String? id,
    String? userId,
    DataSubjectRightsType? rightsType,
    String? description,
    List<String>? dataTypes,
    DateTime? requestedAt,
    DateTime? processedAt,
    DataSubjectRightsStatus? status,
    String? processedBy,
    String? notes,
    Map<String, dynamic>? metadata,
    List<String>? supportingDocuments,
    DateTime? expectedCompletion,
  }) {
    return DataSubjectRightsRequest(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      rightsType: rightsType ?? this.rightsType,
      description: description ?? this.description,
      dataTypes: dataTypes ?? this.dataTypes,
      requestedAt: requestedAt ?? this.requestedAt,
      processedAt: processedAt ?? this.processedAt,
      status: status ?? this.status,
      processedBy: processedBy ?? this.processedBy,
      notes: notes ?? this.notes,
      metadata: metadata ?? this.metadata,
      supportingDocuments: supportingDocuments ?? this.supportingDocuments,
      expectedCompletion: expectedCompletion ?? this.expectedCompletion,
    );
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        rightsType,
        description,
        dataTypes,
        requestedAt,
        processedAt,
        status,
        processedBy,
        notes,
        metadata,
        supportingDocuments,
        expectedCompletion,
      ];
}

/// Types of data subject rights requests
enum DataSubjectRightsType {
  @JsonValue('access')
  access,
  @JsonValue('rectification')
  rectification,
  @JsonValue('erasure')
  erasure,
  @JsonValue('portability')
  portability,
  @JsonValue('restriction')
  restriction,
  @JsonValue('objection')
  objection,
  @JsonValue('automated_decision')
  automatedDecision,
  @JsonValue('consent_withdrawal')
  consentWithdrawal,
}

/// Status of data subject rights requests
enum DataSubjectRightsStatus {
  @JsonValue('pending')
  pending,
  @JsonValue('processing')
  processing,
  @JsonValue('completed')
  completed,
  @JsonValue('rejected')
  rejected,
  @JsonValue('cancelled')
  cancelled,
  @JsonValue('requires_verification')
  requiresVerification,
}

/// Data sovereignty audit entry
@JsonSerializable()
class DataSovereigntyAuditEntry extends Equatable {
  final String id;
  final String userId;
  final DataSovereigntyAuditAction action;
  final String? dataId;
  final DataResidencyRegion? region;
  final ComplianceFramework? complianceFramework;
  final String? details;
  final String? ipAddress;
  final String? userAgent;
  final DateTime timestamp;
  final Map<String, dynamic> metadata;

  const DataSovereigntyAuditEntry({
    required this.id,
    required this.userId,
    required this.action,
    this.dataId,
    this.region,
    this.complianceFramework,
    this.details,
    this.ipAddress,
    this.userAgent,
    required this.timestamp,
    this.metadata = const {},
  });

  factory DataSovereigntyAuditEntry.fromJson(Map<String, dynamic> json) =>
      _$DataSovereigntyAuditEntryFromJson(json);
  Map<String, dynamic> toJson() => _$DataSovereigntyAuditEntryToJson(this);

  @override
  List<Object?> get props => [
        id,
        userId,
        action,
        dataId,
        region,
        complianceFramework,
        details,
        ipAddress,
        userAgent,
        timestamp,
        metadata,
      ];
}

/// Types of data sovereignty audit actions
enum DataSovereigntyAuditAction {
  @JsonValue('data_stored')
  dataStored,
  @JsonValue('data_accessed')
  dataAccessed,
  @JsonValue('data_transferred')
  dataTransferred,
  @JsonValue('data_deleted')
  dataDeleted,
  @JsonValue('policy_created')
  policyCreated,
  @JsonValue('policy_updated')
  policyUpdated,
  @JsonValue('cross_border_request')
  crossBorderRequest,
  @JsonValue('rights_request')
  rightsRequest,
  @JsonValue('compliance_check')
  complianceCheck,
  @JsonValue('data_classification')
  dataClassification,
  @JsonValue('retention_review')
  retentionReview,
}

/// Regional compliance requirements
@JsonSerializable()
class RegionalComplianceRequirements extends Equatable {
  final DataResidencyRegion region;
  final List<ComplianceFramework> frameworks;
  final Map<String, dynamic> specificRequirements;
  final List<String> requiredConsents;
  final List<String> prohibitedDataTypes;
  final Duration maximumRetentionPeriod;
  final bool requireLocalEncryption;
  final String encryptionStandard;
  final bool allowCrossBorderTransfer;
  final List<DataResidencyRegion> allowedTransferRegions;
  final Map<String, dynamic> auditRequirements;

  const RegionalComplianceRequirements({
    required this.region,
    required this.frameworks,
    this.specificRequirements = const {},
    this.requiredConsents = const [],
    this.prohibitedDataTypes = const [],
    required this.maximumRetentionPeriod,
    this.requireLocalEncryption = true,
    required this.encryptionStandard,
    this.allowCrossBorderTransfer = false,
    this.allowedTransferRegions = const [],
    this.auditRequirements = const {},
  });

  factory RegionalComplianceRequirements.fromJson(Map<String, dynamic> json) =>
      _$RegionalComplianceRequirementsFromJson(json);
  Map<String, dynamic> toJson() => _$RegionalComplianceRequirementsToJson(this);

  @override
  List<Object?> get props => [
        region,
        frameworks,
        specificRequirements,
        requiredConsents,
        prohibitedDataTypes,
        maximumRetentionPeriod,
        requireLocalEncryption,
        encryptionStandard,
        allowCrossBorderTransfer,
        allowedTransferRegions,
        auditRequirements,
      ];
}
