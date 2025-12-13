import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/data_sovereignty_models.dart';

/// Provider for data sovereignty service
final dataSovereigntyServiceProvider = Provider((ref) => DataSovereigntyService());

/// Core data sovereignty service for regional compliance and data control
class DataSovereigntyService {
  final Map<String, DataSovereigntyPolicy> _policies = {};
  final Map<String, DataResidencyRecord> _residencyRecords = {};
  final Map<String, CrossBorderTransferRequest> _transferRequests = {};
  final Map<String, DataSubjectRightsRequest> _rightsRequests = {};
  final Map<DataResidencyRegion, RegionalComplianceRequirements> _regionalRequirements = {};
  final List<DataSovereigntyAuditEntry> _auditLog = [];
  
  final StreamController<DataResidencyRecord> _residencyStreamController = 
      StreamController<DataResidencyRecord>.broadcast();
  final StreamController<CrossBorderTransferRequest> _transferStreamController = 
      StreamController<CrossBorderTransferRequest>.broadcast();
  final StreamController<DataSubjectRightsRequest> _rightsStreamController = 
      StreamController<DataSubjectRightsRequest>.broadcast();

  Stream<DataResidencyRecord> get residencyStream => _residencyStreamController.stream;
  Stream<CrossBorderTransferRequest> get transferStream => _transferStreamController.stream;
  Stream<DataSubjectRightsRequest> get rightsStream => _rightsStreamController.stream;

  DataSovereigntyService() {
    _initializeDefaultPolicies();
    _initializeRegionalRequirements();
  }

  /// Create or update data sovereignty policy
  Future<void> createPolicy(DataSovereigntyPolicy policy) async {
    _policies[policy.id] = policy.copyWith(lastUpdated: DateTime.now());
    
    _addAuditEntry(DataSovereigntyAuditEntry(
      id: const Uuid().v4(),
      userId: 'system',
      action: DataSovereigntyAuditAction.policyCreated,
      details: 'Policy ${policy.name} created for ${policy.primaryRegion.name}',
      timestamp: DateTime.now(),
      metadata: {'policyId': policy.id},
    ));
  }

  /// Get applicable policy for a user and region
  DataSovereigntyPolicy? getApplicablePolicy(String userId, DataResidencyRegion region) {
    // Find the most specific policy for the region
    final regionPolicies = _policies.values.where((policy) => 
        policy.isActive && 
        (policy.primaryRegion == region || policy.allowedRegions.contains(region)));
    
    if (regionPolicies.isEmpty) {
      // Return global policy if available
      return _policies.values.where((p) => p.isActive && p.primaryRegion == DataResidencyRegion.global).firstOrNull;
    }
    
    // Return the most recently updated policy
    return regionPolicies.reduce((a, b) => 
        (a.lastUpdated ?? a.createdAt).isAfter(b.lastUpdated ?? b.createdAt) ? a : b);
  }

  /// Record data storage location
  Future<DataResidencyRecord> recordDataStorage({
    required String userId,
    required String dataType,
    required String dataId,
    required DataResidencyRegion region,
    required DataClassification classification,
    String? encryptionKeyId,
    Map<String, dynamic>? metadata,
  }) async {
    final policy = getApplicablePolicy(userId, region);
    if (policy != null && !policy.isRegionAllowed(region)) {
      throw Exception('Region ${region.name} is not allowed by policy ${policy.name}');
    }

    final record = DataResidencyRecord(
      id: const Uuid().v4(),
      userId: userId,
      dataType: dataType,
      dataId: dataId,
      storageRegion: region,
      classification: classification,
      createdAt: DateTime.now(),
      encryptionKeyId: encryptionKeyId ?? 'default',
      metadata: metadata ?? {},
      complianceTags: policy?.complianceFrameworks.map((f) => f.name).toList() ?? [],
    );

    _residencyRecords[record.id] = record;
    _residencyStreamController.add(record);

    _addAuditEntry(DataSovereigntyAuditEntry(
      id: const Uuid().v4(),
      userId: userId,
      action: DataSovereigntyAuditAction.dataStored,
      dataId: dataId,
      region: region,
      details: 'Data of type $dataType stored in ${region.name}',
      timestamp: DateTime.now(),
    ));

    return record;
  }

  /// Request cross-border data transfer
  Future<CrossBorderTransferRequest> requestCrossBorderTransfer({
    required String userId,
    required String dataId,
    required DataResidencyRegion fromRegion,
    required DataResidencyRegion toRegion,
    required String reason,
    List<ComplianceFramework>? complianceFrameworks,
    Map<String, dynamic>? metadata,
  }) async {
    final fromPolicy = getApplicablePolicy(userId, fromRegion);
    final toPolicy = getApplicablePolicy(userId, toRegion);

    if (fromPolicy != null && !fromPolicy.isCrossBorderTransferAllowed(fromRegion, toRegion)) {
      throw Exception('Cross-border transfer not allowed by policy ${fromPolicy.name}');
    }

    final requestId = const Uuid().v4();
    final request = CrossBorderTransferRequest(
      id: requestId,
      userId: userId,
      dataId: dataId,
      fromRegion: fromRegion,
      toRegion: toRegion,
      transferReason: reason,
      complianceFrameworks: complianceFrameworks ?? [],
      requestedAt: DateTime.now(),
      status: CrossBorderTransferStatus.pending,
      metadata: metadata ?? {},
      requiredConsents: _getRequiredConsentsForTransfer(fromRegion, toRegion),
    );

    _transferRequests[requestId] = request;
    _transferStreamController.add(request);

    _addAuditEntry(DataSovereigntyAuditEntry(
      id: const Uuid().v4(),
      userId: userId,
      action: DataSovereigntyAuditAction.crossBorderRequest,
      dataId: dataId,
      region: toRegion,
      details: 'Cross-border transfer requested from ${fromRegion.name} to ${toRegion.name}',
      timestamp: DateTime.now(),
    ));

    return request;
  }

  /// Approve cross-border transfer request
  Future<void> approveCrossBorderTransfer(String requestId, String approvedBy) async {
    final request = _transferRequests[requestId];
    if (request == null) {
      throw Exception('Transfer request not found: $requestId');
    }

    if (!request.hasAllRequiredConsents) {
      throw Exception('All required consents must be obtained before approval');
    }

    final updatedRequest = request.copyWith(
      status: CrossBorderTransferStatus.approved,
      approvedAt: DateTime.now(),
      approvedBy: approvedBy,
    );

    _transferRequests[requestId] = updatedRequest;
    _transferStreamController.add(updatedRequest);

    _addAuditEntry(DataSovereigntyAuditEntry(
      id: const Uuid().v4(),
      userId: request.userId,
      action: DataSovereigntyAuditAction.dataTransferred,
      dataId: request.dataId,
      region: request.toRegion,
      details: 'Cross-border transfer approved by $approvedBy',
      timestamp: DateTime.now(),
    ));
  }

  /// Submit data subject rights request
  Future<DataSubjectRightsRequest> submitRightsRequest({
    required String userId,
    required DataSubjectRightsType rightsType,
    required String description,
    List<String>? dataTypes,
    Map<String, dynamic>? metadata,
  }) async {
    final requestId = const Uuid().v4();
    final request = DataSubjectRightsRequest(
      id: requestId,
      userId: userId,
      rightsType: rightsType,
      description: description,
      dataTypes: dataTypes ?? [],
      requestedAt: DateTime.now(),
      status: DataSubjectRightsStatus.pending,
      metadata: metadata ?? {},
      expectedCompletion: DateTime.now().add(const Duration(days: 30)),
    );

    _rightsRequests[requestId] = request;
    _rightsStreamController.add(request);

    _addAuditEntry(DataSovereigntyAuditEntry(
      id: const Uuid().v4(),
      userId: userId,
      action: DataSovereigntyAuditAction.rightsRequest,
      details: '${rightsType.name} request submitted',
      timestamp: DateTime.now(),
    ));

    return request;
  }

  /// Process data subject rights request
  Future<void> processRightsRequest(String requestId, String processedBy, {String? notes}) async {
    final request = _rightsRequests[requestId];
    if (request == null) {
      throw Exception('Rights request not found: $requestId');
    }

    final updatedRequest = request.copyWith(
      status: DataSubjectRightsStatus.processing,
      processedAt: DateTime.now(),
      processedBy: processedBy,
      notes: notes,
    );

    _rightsRequests[requestId] = updatedRequest;
    _rightsStreamController.add(updatedRequest);

    // Execute the rights request based on type
    await _executeRightsRequest(updatedRequest);
  }

  /// Get data residency records for a user
  List<DataResidencyRecord> getUserResidencyRecords(String userId, {DataResidencyRegion? region}) {
    var records = _residencyRecords.values.where((record) => record.userId == userId);
    
    if (region != null) {
      records = records.where((record) => record.storageRegion == region);
    }
    
    return records.toList();
  }

  /// Get cross-border transfer requests
  List<CrossBorderTransferRequest> getTransferRequests({
    String? userId,
    CrossBorderTransferStatus? status,
    DataResidencyRegion? fromRegion,
    DataResidencyRegion? toRegion,
  }) {
    var requests = _transferRequests.values;
    
    if (userId != null) {
      requests = requests.where((r) => r.userId == userId);
    }
    
    if (status != null) {
      requests = requests.where((r) => r.status == status);
    }
    
    if (fromRegion != null) {
      requests = requests.where((r) => r.fromRegion == fromRegion);
    }
    
    if (toRegion != null) {
      requests = requests.where((r) => r.toRegion == toRegion);
    }
    
    return requests.toList();
  }

  /// Get data subject rights requests
  List<DataSubjectRightsRequest> getRightsRequests({
    String? userId,
    DataSubjectRightsType? rightsType,
    DataSubjectRightsStatus? status,
  }) {
    var requests = _rightsRequests.values;
    
    if (userId != null) {
      requests = requests.where((r) => r.userId == userId);
    }
    
    if (rightsType != null) {
      requests = requests.where((r) => r.rightsType == rightsType);
    }
    
    if (status != null) {
      requests = requests.where((r) => r.status == status);
    }
    
    return requests.toList();
  }

  /// Check compliance for data storage
  Future<ComplianceResult> checkStorageCompliance(String userId, DataResidencyRegion region) async {
    final policy = getApplicablePolicy(userId, region);
    if (policy == null) {
      return ComplianceResult(
        isCompliant: false,
        issues: ['No applicable policy found for region ${region.name}'],
        recommendations: ['Create a policy for ${region.name} or use global policy'],
      );
    }

    final issues = <String>[];
    final recommendations = <String>[];

    // Check regional requirements
    final regionalReq = _regionalRequirements[region];
    if (regionalReq != null) {
      if (!policy.complianceFrameworks.any((f) => regionalReq.frameworks.contains(f))) {
        issues.add('Missing required compliance frameworks');
        recommendations.addAll(regionalReq.frameworks.map((f) => 'Add $f to policy'));
      }
    }

    return ComplianceResult(
      isCompliant: issues.isEmpty,
      issues: issues,
      recommendations: recommendations,
      applicableFrameworks: policy.complianceFrameworks,
    );
  }

  /// Get data sovereignty statistics
  Map<String, dynamic> getSovereigntyStatistics() {
    final totalRecords = _residencyRecords.length;
    final regionStats = <DataResidencyRegion, int>{};
    final classificationStats = <DataClassification, int>{};
    
    for (final record in _residencyRecords.values) {
      regionStats[record.storageRegion] = (regionStats[record.storageRegion] ?? 0) + 1;
      classificationStats[record.classification] = (classificationStats[record.classification] ?? 0) + 1;
    }

    final transferStats = _transferRequests.values.fold(
      <CrossBorderTransferStatus, int>{},
      (map, request) {
        map[request.status] = (map[request.status] ?? 0) + 1;
        return map;
      },
    );

    final rightsStats = _rightsRequests.values.fold(
      <DataSubjectRightsStatus, int>{},
      (map, request) {
        map[request.status] = (map[request.status] ?? 0) + 1;
        return map;
      },
    );

    return {
      'totalDataRecords': totalRecords,
      'activePolicies': _policies.values.where((p) => p.isActive).length,
      'totalPolicies': _policies.length,
      'pendingTransfers': transferStats[CrossBorderTransferStatus.pending] ?? 0,
      'approvedTransfers': transferStats[CrossBorderTransferStatus.approved] ?? 0,
      'completedTransfers': transferStats[CrossBorderTransferStatus.completed] ?? 0,
      'pendingRightsRequests': rightsStats[DataSubjectRightsStatus.pending] ?? 0,
      'processingRightsRequests': rightsStats[DataSubjectRightsStatus.processing] ?? 0,
      'completedRightsRequests': rightsStats[DataSubjectRightsStatus.completed] ?? 0,
      'regionDistribution': regionStats.map((k, v) => MapEntry(k.name, v)),
      'classificationDistribution': classificationStats.map((k, v) => MapEntry(k.name, v)),
    };
  }

  /// Export user data for data portability
  Future<Map<String, dynamic>> exportUserData(String userId) async {
    final residencyRecords = getUserResidencyRecords(userId);
    final transferRequests = getTransferRequests(userId: userId);
    final rightsRequests = getRightsRequests(userId: userId);

    return {
      'userId': userId,
      'residencyRecords': residencyRecords.map((r) => r.toJson()).toList(),
      'transferRequests': transferRequests.map((r) => r.toJson()).toList(),
      'rightsRequests': rightsRequests.map((r) => r.toJson()).toList(),
      'exportedAt': DateTime.now().toIso8601String(),
      'format': 'JSON',
      'version': '1.0',
    };
  }

  /// Delete user data (right to be forgotten)
  Future<void> deleteUserData(String userId) async {
    // Remove residency records
    final userRecordIds = _residencyRecords.entries
        .where((entry) => entry.value.userId == userId)
        .map((entry) => entry.key)
        .toList();
    
    for (final id in userRecordIds) {
      final record = _residencyRecords[id]!;
      _residencyRecords.remove(id);
      
      _addAuditEntry(DataSovereigntyAuditEntry(
        id: const Uuid().v4(),
        userId: userId,
        action: DataSovereigntyAuditAction.dataDeleted,
        dataId: record.dataId,
        region: record.storageRegion,
        details: 'Data deleted as part of right to be forgotten',
        timestamp: DateTime.now(),
      ));
    }

    // Remove transfer requests
    final userTransferIds = _transferRequests.entries
        .where((entry) => entry.value.userId == userId)
        .map((entry) => entry.key)
        .toList();
    
    for (final id in userTransferIds) {
      _transferRequests.remove(id);
    }

    // Remove rights requests
    final userRightsIds = _rightsRequests.entries
        .where((entry) => entry.value.userId == userId)
        .map((entry) => entry.key)
        .toList();
    
    for (final id in userRightsIds) {
      _rightsRequests.remove(id);
    }
  }

  /// Get audit log
  List<DataSovereigntyAuditEntry> getAuditLog({
    String? userId,
    DataSovereigntyAuditAction? action,
    DataResidencyRegion? region,
  }) {
    var filteredLog = _auditLog;
    
    if (userId != null) {
      filteredLog = filteredLog.where((entry) => entry.userId == userId).toList();
    }
    
    if (action != null) {
      filteredLog = filteredLog.where((entry) => entry.action == action).toList();
    }
    
    if (region != null) {
      filteredLog = filteredLog.where((entry) => entry.region == region).toList();
    }
    
    return filteredLog;
  }

  // Private helper methods

  void _initializeDefaultPolicies() {
    final now = DateTime.now();

    // Global policy
    _policies['global'] = DataSovereigntyPolicy(
      id: 'global',
      name: 'Global Data Sovereignty Policy',
      description: 'Default policy for global data handling',
      primaryRegion: DataResidencyRegion.global,
      localizationRequirement: DataLocalizationRequirement.none,
      dataRetentionPeriod: const Duration(days: 365 * 7), // 7 years
      encryptionStandard: 'AES-256-GCM',
      createdAt: now,
    );

    // GDPR policy for EU
    _policies['gdpr_eu'] = DataSovereigntyPolicy(
      id: 'gdpr_eu',
      name: 'GDPR EU Policy',
      description: 'GDPR compliant policy for European Union data',
      primaryRegion: DataResidencyRegion.europeanUnion,
      allowedRegions: [DataResidencyRegion.europeanUnion],
      complianceFrameworks: [ComplianceFramework.gdpr],
      localizationRequirement: DataLocalizationRequirement.storageAndProcessing,
      dataRetentionPeriod: const Duration(days: 365 * 5), // 5 years
      encryptionStandard: 'AES-256-GCM',
      regionalRequirements: {
        'requireExplicitConsent': true,
        'enableRightToBeForgotten': true,
        'enableDataPortability': true,
        'dataProtectionOfficer': true,
        'breachNotification': '72h',
      },
      createdAt: now,
    );

    // CCPA policy for California
    _policies['ccpa_ca'] = DataSovereigntyPolicy(
      id: 'ccpa_ca',
      name: 'CCPA California Policy',
      description: 'CCPA compliant policy for California data',
      primaryRegion: DataResidencyRegion.unitedStates,
      allowedRegions: [DataResidencyRegion.unitedStates],
      complianceFrameworks: [ComplianceFramework.ccpa],
      localizationRequirement: DataLocalizationRequirement.storageOnly,
      dataRetentionPeriod: const Duration(days: 365 * 2), // 2 years
      encryptionStandard: 'AES-256-GCM',
      regionalRequirements: {
        'consumerRights': true,
        'optOutSale': true,
        'disclosureRequirements': true,
      },
      createdAt: now,
    );
  }

  void _initializeRegionalRequirements() {
    // EU requirements
    _regionalRequirements[DataResidencyRegion.europeanUnion] = RegionalComplianceRequirements(
      region: DataResidencyRegion.europeanUnion,
      frameworks: [ComplianceFramework.gdpr],
      requiredConsents: ['explicit_consent', 'data_processing'],
      maximumRetentionPeriod: const Duration(days: 365 * 5),
      requireLocalEncryption: true,
      encryptionStandard: 'AES-256-GCM',
      allowCrossBorderTransfer: false,
      auditRequirements: {
        'logRetention': '6_years',
        'accessLogs': true,
        'changeLogs': true,
      },
    );

    // US requirements
    _regionalRequirements[DataResidencyRegion.unitedStates] = RegionalComplianceRequirements(
      region: DataResidencyRegion.unitedStates,
      frameworks: [ComplianceFramework.ccpa],
      requiredConsents: ['notice_and_choice'],
      maximumRetentionPeriod: const Duration(days: 365 * 2),
      requireLocalEncryption: true,
      encryptionStandard: 'AES-256-GCM',
      allowCrossBorderTransfer: true,
      allowedTransferRegions: [DataResidencyRegion.canada, DataResidencyRegion.mexico],
      auditRequirements: {
        'logRetention': '2_years',
        'accessLogs': true,
      },
    );
  }

  List<String> _getRequiredConsentsForTransfer(DataResidencyRegion from, DataResidencyRegion to) {
    final fromReq = _regionalRequirements[from];
    final toReq = _regionalRequirements[to];
    
    final required = <String>[];
    
    if (fromReq != null) {
      required.addAll(fromReq.requiredConsents);
    }
    
    if (toReq != null) {
      required.addAll(toReq.requiredConsents);
    }
    
    return required.toSet().toList();
  }

  Future<void> _executeRightsRequest(DataSubjectRightsRequest request) async {
    switch (request.rightsType) {
      case DataSubjectRightsType.access:
        // Generate data export
        break;
      case DataSubjectRightsType.erasure:
        // Delete user data
        await deleteUserData(request.userId);
        break;
      case DataSubjectRightsType.portability:
        // Export data in portable format
        break;
      case DataSubjectRightsType.rectification:
        // Allow data correction
        break;
      case DataSubjectRightsType.restriction:
        // Restrict data processing
        break;
      case DataSubjectRightsType.objection:
        // Object to processing
        break;
      case DataSubjectRightsType.consentWithdrawal:
        // Withdraw consent
        break;
      case DataSubjectRightsType.automatedDecision:
        // Request human intervention
        break;
    }
  }

  void _addAuditEntry(DataSovereigntyAuditEntry entry) {
    _auditLog.add(entry);
    
    // Keep audit log size manageable
    if (_auditLog.length > 10000) {
      _auditLog.removeRange(0, _auditLog.length - 10000);
    }
  }

  void dispose() {
    _residencyStreamController.close();
    _transferStreamController.close();
    _rightsStreamController.close();
  }
}

/// Compliance check result
class ComplianceResult {
  final bool isCompliant;
  final List<String> issues;
  final List<String> recommendations;
  final List<ComplianceFramework> applicableFrameworks;

  const ComplianceResult({
    required this.isCompliant,
    required this.issues,
    required this.recommendations,
    required this.applicableFrameworks,
  });
}

/// Extension methods for data residency regions
extension DataResidencyRegionExtension on DataResidencyRegion {
  String get displayName {
    switch (this) {
      case DataResidencyRegion.global:
        return 'Global';
      case DataResidencyRegion.unitedStates:
        return 'United States';
      case DataResidencyRegion.europeanUnion:
        return 'European Union';
      case DataResidencyRegion.unitedKingdom:
        return 'United Kingdom';
      case DataResidencyRegion.canada:
        return 'Canada';
      case DataResidencyRegion.australia:
        return 'Australia';
      case DataResidencyRegion.japan:
        return 'Japan';
      case DataResidencyRegion.singapore:
        return 'Singapore';
      case DataResidencyRegion.switzerland:
        return 'Switzerland';
      case DataResidencyRegion.brazil:
        return 'Brazil';
      case DataResidencyRegion.india:
        return 'India';
      case DataResidencyRegion.china:
        return 'China';
      case DataResidencyRegion.russia:
        return 'Russia';
      case DataResidencyRegion.southKorea:
        return 'South Korea';
      case DataResidencyRegion.mexico:
        return 'Mexico';
      case DataResidencyRegion.argentina:
        return 'Argentina';
      case DataResidencyRegion.southAfrica:
        return 'South Africa';
      case DataResidencyRegion.uae:
        return 'UAE';
      case DataResidencyRegion.saudiArabia:
        return 'Saudi Arabia';
      case DataResidencyRegion.israel:
        return 'Israel';
      case DataResidencyRegion.newZealand:
        return 'New Zealand';
      case DataResidencyRegion.norway:
        return 'Norway';
      case DataResidencyRegion.iceland:
        return 'Iceland';
      case DataResidencyRegion.liechtenstein:
        return 'Liechtenstein';
    }
  }

  String get flag {
    switch (this) {
      case DataResidencyRegion.global:
        return '🌍';
      case DataResidencyRegion.unitedStates:
        return '🇺🇸';
      case DataResidencyRegion.europeanUnion:
        return '🇪🇺';
      case DataResidencyRegion.unitedKingdom:
        return '🇬🇧';
      case DataResidencyRegion.canada:
        return '🇨🇦';
      case DataResidencyRegion.australia:
        return '🇦🇺';
      case DataResidencyRegion.japan:
        return '🇯🇵';
      case DataResidencyRegion.singapore:
        return '🇸🇬';
      case DataResidencyRegion.switzerland:
        return '🇨🇭';
      case DataResidencyRegion.brazil:
        return '🇧🇷';
      case DataResidencyRegion.india:
        return '🇮🇳';
      case DataResidencyRegion.china:
        return '🇨🇳';
      case DataResidencyRegion.russia:
        return '🇷🇺';
      case DataResidencyRegion.southKorea:
        return '🇰🇷';
      case DataResidencyRegion.mexico:
        return '🇲🇽';
      case DataResidencyRegion.argentina:
        return '🇦🇷';
      case DataResidencyRegion.southAfrica:
        return '🇿🇦';
      case DataResidencyRegion.uae:
        return '🇦🇪';
      case DataResidencyRegion.saudiArabia:
        return '🇸🇦';
      case DataResidencyRegion.israel:
        return '🇮🇱';
      case DataResidencyRegion.newZealand:
        return '🇳🇿';
      case DataResidencyRegion.norway:
        return '🇳🇴';
      case DataResidencyRegion.iceland:
        return '🇮🇸';
      case DataResidencyRegion.liechtenstein:
        return '🇱🇮';
    }
  }
}

/// Extension methods for compliance frameworks
extension ComplianceFrameworkExtension on ComplianceFramework {
  String get displayName {
    switch (this) {
      case ComplianceFramework.gdpr:
        return 'GDPR';
      case ComplianceFramework.ccpa:
        return 'CCPA';
      case ComplianceFramework.lgpd:
        return 'LGPD';
      case ComplianceFramework.pipeda:
        return 'PIPEDA';
      case ComplianceFramework.pdpa:
        return 'PDPA';
      case ComplianceFramework.apci:
        return 'APCI';
      case ComplianceFramework.pdpaSingapore:
        return 'PDPA Singapore';
      case ComplianceFramework.dpaUk:
        return 'DPA UK';
      case ComplianceFramework.fisma:
        return 'FISMA';
      case ComplianceFramework.hipaa:
        return 'HIPAA';
      case ComplianceFramework.sox:
        return 'SOX';
      case ComplianceFramework.iso27001:
        return 'ISO 27001';
      case ComplianceFramework.soc2:
        return 'SOC 2';
      case ComplianceFramework.nist:
        return 'NIST';
    }
  }

  String get description {
    switch (this) {
      case ComplianceFramework.gdpr:
        return 'General Data Protection Regulation';
      case ComplianceFramework.ccpa:
        return 'California Consumer Privacy Act';
      case ComplianceFramework.lgpd:
        return 'Lei Geral de Proteção de Dados';
      case ComplianceFramework.pipeda:
        return 'Personal Information Protection and Electronic Documents Act';
      case ComplianceFramework.pdpa:
        return 'Personal Data Protection Act';
      case ComplianceFramework.apci:
        return 'Argentina Personal Data Protection Law';
      case ComplianceFramework.pdpaSingapore:
        return 'Singapore Personal Data Protection Act';
      case ComplianceFramework.dpaUk:
        return 'UK Data Protection Act';
      case ComplianceFramework.fisma:
        return 'Federal Information Security Management Act';
      case ComplianceFramework.hipaa:
        return 'Health Insurance Portability and Accountability Act';
      case ComplianceFramework.sox:
        return 'Sarbanes-Oxley Act';
      case ComplianceFramework.iso27001:
        return 'ISO/IEC 27001 Information Security Management';
      case ComplianceFramework.soc2:
        return 'Service Organization Control 2';
      case ComplianceFramework.nist:
        return 'National Institute of Standards and Technology';
    }
  }
}
