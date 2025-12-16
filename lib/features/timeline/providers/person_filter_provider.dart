import 'package:flutter_riverpod/flutter_riverpod.dart';

/// State notifier for global person filter
class PersonFilterNotifier extends StateNotifier<Set<String>> {
  PersonFilterNotifier() : super({});

  /// Toggle a person in the filter
  void togglePerson(String personId) {
    final current = Set<String>.from(state);
    if (current.contains(personId)) {
      current.remove(personId);
    } else {
      current.add(personId);
    }
    state = current;
  }

  /// Select only this person
  void selectOnly(String personId) {
    state = {personId};
  }

  /// Select all people (clear filter)
  void selectAll() {
    state = {};
  }

  /// Clear all selections
  void clear() {
    state = {};
  }

  /// Check if a person is selected (or if all are selected)
  bool isPersonSelected(String personId) {
    return state.isEmpty || state.contains(personId);
  }

  /// Get display text for current selection
  String getDisplayText(List<String> allPeople) {
    if (state.isEmpty) return 'All People';
    if (state.length == 1) {
      final personId = state.first;
      return _formatPersonName(personId);
    }
    return '${state.length} People';
  }

  String _formatPersonName(String personId) {
    return personId
        .replaceAll('-', ' ')
        .split(' ')
        .map((w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : w)
        .join(' ');
  }
}

/// Global person filter provider
final personFilterProvider = StateNotifierProvider<PersonFilterNotifier, Set<String>>((ref) {
  return PersonFilterNotifier();
});
