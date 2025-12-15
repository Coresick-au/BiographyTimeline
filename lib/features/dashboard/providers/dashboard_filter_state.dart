import 'package:flutter_riverpod/flutter_riverpod.dart';

class DashboardFilters {
  final DateTime? startDate;
  final DateTime? endDate;
  final List<String>? selectedTags;
  final String? selectedOwnerId;

  const DashboardFilters({
    this.startDate,
    this.endDate,
    this.selectedTags,
    this.selectedOwnerId,
  });

  DashboardFilters copyWith({
    DateTime? startDate,
    DateTime? endDate,
    List<String>? selectedTags,
    String? selectedOwnerId,
  }) {
    return DashboardFilters(
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      selectedTags: selectedTags ?? this.selectedTags,
      selectedOwnerId: selectedOwnerId ?? this.selectedOwnerId,
    );
  }
}

class DashboardFilterNotifier extends StateNotifier<DashboardFilters> {
  DashboardFilterNotifier() : super(const DashboardFilters());

  void setDateRange(DateTime? start, DateTime? end) {
    state = state.copyWith(startDate: start, endDate: end);
  }

  void toggleTag(String tag) {
    final currentTags = state.selectedTags ?? [];
    if (currentTags.contains(tag)) {
      state = state.copyWith(selectedTags: currentTags.where((t) => t != tag).toList());
    } else {
      state = state.copyWith(selectedTags: [...currentTags, tag]);
    }
  }

  void setOwner(String? ownerId) {
    state = state.copyWith(selectedOwnerId: ownerId);
  }
  
  void reset() {
    state = const DashboardFilters();
  }
}

final dashboardFilterProvider = StateNotifierProvider<DashboardFilterNotifier, DashboardFilters>((ref) {
  return DashboardFilterNotifier();
});
