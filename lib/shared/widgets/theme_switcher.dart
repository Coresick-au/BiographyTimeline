import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/theme_provider.dart';

/// Simple theme switcher button for the app bar
class ThemeSwitcherButton extends ConsumerWidget {
  const ThemeSwitcherButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentTheme = ref.watch(currentThemeProvider);
    
    return IconButton(
      icon: Icon(
        currentTheme.mode == ThemeMode.dark 
            ? Icons.dark_mode 
            : Icons.light_mode,
      ),
      tooltip: 'Change theme',
      onPressed: () {
        _showThemePicker(context, ref);
      },
    );
  }

  void _showThemePicker(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      builder: (context) => const ThemePickerSheet(),
    );
  }
}

/// Theme picker bottom sheet
class ThemePickerSheet extends ConsumerWidget {
  const ThemePickerSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentTheme = ref.watch(currentThemeProvider);
    
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Choose Theme',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: TimelineThemes.allThemes.length,
              itemBuilder: (context, index) {
                final theme = TimelineThemes.allThemes[index];
                final isSelected = theme.id == currentTheme.id;
                
                return ListTile(
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: theme.accentColor,
                      borderRadius: BorderRadius.circular(8),
                      border: isSelected 
                          ? Border.all(color: Colors.white, width: 2)
                          : null,
                    ),
                  ),
                  title: Text(theme.name),
                  subtitle: Text(theme.description),
                  trailing: isSelected 
                      ? const Icon(Icons.check_circle, color: Colors.green)
                      : null,
                  onTap: () {
                    ref.read(currentThemeProvider.notifier).setTheme(theme);
                    Navigator.pop(context);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
