import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/person_filter_provider.dart';
import '../models/river_flow_models.dart';

/// Reusable person selector dropdown for all timeline views
class PersonSelectorDropdown extends ConsumerWidget {
  final List<String> availablePeople;
  
  const PersonSelectorDropdown({
    super.key,
    required this.availablePeople,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedPeople = ref.watch(personFilterProvider);
    final personFilterNotifier = ref.read(personFilterProvider.notifier);
    
    if (availablePeople.isEmpty) {
      return const Text(
        'No people found',
        style: TextStyle(color: Colors.white30, fontSize: 12),
      );
    }

    return PopupMenuButton<String>(
      color: const Color(0xFF1A1F2E),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.white.withOpacity(0.2)),
      ),
      offset: const Offset(0, 45),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.2)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.people, size: 18, color: Colors.blue.shade300),
            const SizedBox(width: 8),
            Text(
              personFilterNotifier.getDisplayText(availablePeople),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.arrow_drop_down, size: 20, color: Colors.white70),
          ],
        ),
      ),
      itemBuilder: (context) {
        final items = <PopupMenuEntry<String>>[];
        
        // "All People" option
        items.add(
          PopupMenuItem<String>(
            value: '__all__',
            child: Row(
              children: [
                Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.blue.withOpacity(0.3),
                    border: Border.all(color: Colors.blue, width: 2),
                  ),
                  child: selectedPeople.isEmpty
                      ? const Icon(Icons.check, size: 10, color: Colors.blue)
                      : null,
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'All People',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
        
        items.add(const PopupMenuDivider());
        
        // Individual people
        for (int i = 0; i < availablePeople.length; i++) {
          final personId = availablePeople[i];
          final isSelected = personFilterNotifier.isPersonSelected(personId) && selectedPeople.isNotEmpty;
          final color = RiverFlowColors.getColorForPerson(personId, i);
          
          items.add(
            PopupMenuItem<String>(
              value: personId,
              child: Row(
                children: [
                  Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: color.withOpacity(0.3),
                      border: Border.all(color: color, width: 2),
                    ),
                    child: isSelected
                        ? Icon(Icons.check, size: 10, color: color)
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _formatPersonName(personId),
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.white70,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }
        
        return items;
      },
      onSelected: (value) {
        if (value == '__all__') {
          personFilterNotifier.selectAll();
        } else {
          personFilterNotifier.togglePerson(value);
        }
      },
    );
  }

  String _formatPersonName(String personId) {
    return personId
        .replaceAll('-', ' ')
        .split(' ')
        .map((w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : w)
        .join(' ');
  }
}
