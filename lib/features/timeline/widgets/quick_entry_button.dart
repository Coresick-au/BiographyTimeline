import 'package:flutter/material.dart';
import '../../../shared/models/context.dart';
import '../../../shared/models/timeline_event.dart';
import 'quick_entry_dialog.dart';

/// Prominent floating action button for creating quick text-only timeline entries
class QuickEntryButton extends StatelessWidget {
  final ContextType contextType;
  final String contextId;
  final String ownerId;
  final Function(TimelineEvent) onEventCreated;

  const QuickEntryButton({
    super.key,
    required this.contextType,
    required this.contextId,
    required this.ownerId,
    required this.onEventCreated,
  });

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.extended(
      onPressed: () => _showQuickEntryDialog(context),
      icon: const Icon(Icons.edit_note),
      label: const Text('Quick Entry'),
      backgroundColor: Theme.of(context).colorScheme.primary,
      foregroundColor: Theme.of(context).colorScheme.onPrimary,
      elevation: 4,
    );
  }

  void _showQuickEntryDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => QuickEntryDialog(
        contextType: contextType,
        contextId: contextId,
        ownerId: ownerId,
        onEventCreated: onEventCreated,
      ),
    );
  }
}

/// Alternative compact quick entry button for use in app bars or toolbars
class CompactQuickEntryButton extends StatelessWidget {
  final ContextType contextType;
  final String contextId;
  final String ownerId;
  final Function(TimelineEvent) onEventCreated;

  const CompactQuickEntryButton({
    super.key,
    required this.contextType,
    required this.contextId,
    required this.ownerId,
    required this.onEventCreated,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: () => _showQuickEntryDialog(context),
      icon: const Icon(Icons.edit_note),
      tooltip: 'Quick Entry',
    );
  }

  void _showQuickEntryDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => QuickEntryDialog(
        contextType: contextType,
        contextId: contextId,
        ownerId: ownerId,
        onEventCreated: onEventCreated,
      ),
    );
  }
}
