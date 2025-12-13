import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../shared/models/context.dart';
import '../../shared/providers/theme_provider.dart';

/// Widget that allows users to switch between different context themes
class ThemeSwitcher extends ConsumerWidget {
  const ThemeSwitcher({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentContextType = ref.watch(contextTypeProvider);
    final currentTheme = ref.watch(activeThemeProvider);
    
    return PopupMenuButton<ContextType>(
      icon: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getContextIcon(currentContextType),
            color: Theme.of(context).colorScheme.onSurface,
          ),
          const SizedBox(width: 4),
          Text(
            _getContextName(currentContextType),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const Icon(Icons.arrow_drop_down),
        ],
      ),
      onSelected: (ContextType newContextType) {
        ref.read(contextTypeProvider.notifier).state = newContextType;
      },
      itemBuilder: (BuildContext context) => [
        PopupMenuItem(
          value: ContextType.person,
          child: Row(
            children: [
              Icon(Icons.person, color: Colors.blue),
              const SizedBox(width: 8),
              const Text('Personal'),
              if (currentContextType == ContextType.person) ...[
                const Spacer(),
                Icon(Icons.check, color: Theme.of(context).primaryColor),
              ],
            ],
          ),
        ),
        PopupMenuItem(
          value: ContextType.pet,
          child: Row(
            children: [
              Icon(Icons.pets, color: Colors.green),
              const SizedBox(width: 8),
              const Text('Pet'),
              if (currentContextType == ContextType.pet) ...[
                const Spacer(),
                Icon(Icons.check, color: Theme.of(context).primaryColor),
              ],
            ],
          ),
        ),
        PopupMenuItem(
          value: ContextType.project,
          child: Row(
            children: [
              Icon(Icons.construction, color: Colors.orange),
              const SizedBox(width: 8),
              const Text('Project'),
              if (currentContextType == ContextType.project) ...[
                const Spacer(),
                Icon(Icons.check, color: Theme.of(context).primaryColor),
              ],
            ],
          ),
        ),
        PopupMenuItem(
          value: ContextType.business,
          child: Row(
            children: [
              Icon(Icons.business, color: Colors.purple),
              const SizedBox(width: 8),
              const Text('Business'),
              if (currentContextType == ContextType.business) ...[
                const Spacer(),
                Icon(Icons.check, color: Theme.of(context).primaryColor),
              ],
            ],
          ),
        ),
      ],
    );
  }

  IconData _getContextIcon(ContextType contextType) {
    switch (contextType) {
      case ContextType.person:
        return Icons.person;
      case ContextType.pet:
        return Icons.pets;
      case ContextType.project:
        return Icons.construction;
      case ContextType.business:
        return Icons.business;
    }
  }

  String _getContextName(ContextType contextType) {
    switch (contextType) {
      case ContextType.person:
        return 'Personal';
      case ContextType.pet:
        return 'Pet';
      case ContextType.project:
        return 'Project';
      case ContextType.business:
        return 'Business';
    }
  }
}

/// Simple theme switcher button for use in app bars or toolbars
class ThemeSwitcherButton extends ConsumerWidget {
  const ThemeSwitcherButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentContextType = ref.watch(contextTypeProvider);
    
    return IconButton(
      icon: Icon(_getContextIcon(currentContextType)),
      onPressed: () {
        _showThemeDialog(context, ref, currentContextType);
      },
      tooltip: 'Switch Theme',
    );
  }

  void _showThemeDialog(BuildContext context, WidgetRef ref, ContextType currentType) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Choose Theme'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildThemeOption(
                context,
                ref,
                ContextType.person,
                Icons.person,
                'Personal',
                Colors.blue,
                currentType,
              ),
              _buildThemeOption(
                context,
                ref,
                ContextType.pet,
                Icons.pets,
                'Pet',
                Colors.green,
                currentType,
              ),
              _buildThemeOption(
                context,
                ref,
                ContextType.project,
                Icons.construction,
                'Project',
                Colors.orange,
                currentType,
              ),
              _buildThemeOption(
                context,
                ref,
                ContextType.business,
                Icons.business,
                'Business',
                Colors.purple,
                currentType,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildThemeOption(
    BuildContext context,
    WidgetRef ref,
    ContextType contextType,
    IconData icon,
    String label,
    Color color,
    ContextType currentType,
  ) {
    final isSelected = currentType == contextType;
    
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: color.withOpacity(0.2),
        child: Icon(icon, color: color),
      ),
      title: Text(label),
      trailing: isSelected 
          ? Icon(Icons.check, color: Theme.of(context).primaryColor)
          : null,
      onTap: () {
        ref.read(contextTypeProvider.notifier).state = contextType;
        Navigator.of(context).pop();
      },
    );
  }

  IconData _getContextIcon(ContextType contextType) {
    switch (contextType) {
      case ContextType.person:
        return Icons.person;
      case ContextType.pet:
        return Icons.pets;
      case ContextType.project:
        return Icons.construction;
      case ContextType.business:
        return Icons.business;
    }
  }
}
