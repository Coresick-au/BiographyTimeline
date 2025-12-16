import '../../lib/shared/models/context.dart';

class ContextManagementService {
  List<ContextType> getAvailableContextTypes() {
    return ContextType.values;
  }

  Map<String, dynamic> getDefaultConfigurationForType(ContextType type) {
    switch (type) {
      case ContextType.person:
        return {
          'enableGhostCamera': false,
          'enableBudgetTracking': false,
          'enableProgressComparison': false,
          'enableMilestoneTracking': true,
          'enableLocationTracking': true,
          'enableStoryTelling': true,
          'enableFaceDetection': true,
        };
      case ContextType.pet:
        return {
          'enableGhostCamera': true,
          'enableBudgetTracking': false,
          'enableProgressComparison': true,
          'enableMilestoneTracking': true,
          'enableLocationTracking': false,
          'enableWeightTracking': true,
          'enableMedicalTracking': true,
          'enableVetVisitTracking': true,
        };
      case ContextType.project:
        return {
          'enableGhostCamera': true,
          'enableBudgetTracking': true,
          'enableProgressComparison': true,
          'enableMilestoneTracking': true,
          'enableLocationTracking': false,
          'enableBeforeAfter': true,
          'enableCostTracking': true,
          'enableTaskTracking': true,
          'enableTeamTracking': true,
        };
      case ContextType.business:
        return {
          'enableGhostCamera': false,
          'enableBudgetTracking': true,
          'enableProgressComparison': false,
          'enableMilestoneTracking': true,
          'enableLocationTracking': true,
          'enableRevenueTracking': true,
          'enableTeamManagement': true,
          'enableTeamTracking': true,
        };
    }
  }

  Future<Context> createContext({
    required String ownerId,
    required ContextType type,
    required String name,
    String? description,
  }) async {
    // Mock implementation - returns a basic context
    return Context.create(
      id: 'mock_context_${DateTime.now().millisecondsSinceEpoch}',
      ownerId: ownerId,
      type: type,
      name: name,
      description: description,
    );
  }
}

class TestContextManagementService extends ContextManagementService {}
