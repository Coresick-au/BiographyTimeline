import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/widgets/theme_switcher.dart';

/// Settings screen placeholder
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        title: const Text('Settings'),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Profile Section
          Card(
            elevation: 2,
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Theme.of(context).colorScheme.primary,
                child: const Icon(Icons.person, color: Colors.white),
              ),
              title: Text(
                'User Profile',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              subtitle: Text(
                'Manage your account and preferences',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              trailing: Icon(
                Icons.chevron_right,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Profile settings coming soon!')),
                );
              },
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Timeline Settings
          Card(
            elevation: 2,
            child: Column(
              children: [
                ListTile(
                  leading: Icon(
                    Icons.timeline,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  title: Text(
                    'Timeline Settings',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  subtitle: Text(
                    'Configure timeline display and behavior',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  trailing: Icon(
                    Icons.chevron_right,
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                  ),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Timeline settings coming soon!')),
                    );
                  },
                ),
                Divider(
                  height: 1,
                  color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                ),
                ListTile(
                  leading: Icon(
                    Icons.view_carousel,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  title: Text(
                    'Default View',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  subtitle: Text(
                    'Chronological',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  trailing: Icon(
                    Icons.chevron_right,
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                  ),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('View settings coming soon!')),
                    );
                  },
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Appearance & Theme
          Card(
            elevation: 2,
            child: Column(
              children: [
                ListTile(
                  leading: Icon(
                    Icons.palette,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  title: Text(
                    'Theme',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  subtitle: Text(
                    'Choose your app theme',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  trailing: const ThemeSwitcherButton(),
                ),
                Divider(
                  height: 1,
                  color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                ),
                ListTile(
                  leading: Icon(
                    Icons.color_lens,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  title: Text(
                    'Color Scheme',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  subtitle: Text(
                    'Customize colors and appearance',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  trailing: Icon(
                    Icons.chevron_right,
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                  ),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Color customization coming soon!')),
                    );
                  },
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Privacy & Security
          Card(
            elevation: 2,
            child: Column(
              children: [
                ListTile(
                  leading: Icon(
                    Icons.privacy_tip,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  title: Text(
                    'Privacy',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  subtitle: Text(
                    'Manage your privacy settings',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  trailing: Icon(
                    Icons.chevron_right,
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                  ),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Privacy settings coming soon!')),
                    );
                  },
                ),
                Divider(
                  height: 1,
                  color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                ),
                ListTile(
                  leading: Icon(
                    Icons.security,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  title: Text(
                    'Security',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  subtitle: Text(
                    'Security and authentication',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  trailing: Icon(
                    Icons.chevron_right,
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                  ),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Security settings coming soon!')),
                    );
                  },
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Data & Storage
          Card(
            elevation: 2,
            child: Column(
              children: [
                ListTile(
                  leading: Icon(
                    Icons.storage,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  title: Text(
                    'Storage',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  subtitle: Text(
                    'Manage data and storage',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  trailing: Icon(
                    Icons.chevron_right,
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                  ),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Storage settings coming soon!')),
                    );
                  },
                ),
                Divider(
                  height: 1,
                  color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                ),
                ListTile(
                  leading: Icon(
                    Icons.download,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  title: Text(
                    'Export Data',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  subtitle: Text(
                    'Download your timeline data',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  trailing: Icon(
                    Icons.chevron_right,
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                  ),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Export feature coming soon!')),
                    );
                  },
                ),
                Divider(
                  height: 1,
                  color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                ),
                ListTile(
                  leading: Icon(
                    Icons.upload,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  title: Text(
                    'Import Data',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  subtitle: Text(
                    'Import timeline from backup',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  trailing: Icon(
                    Icons.chevron_right,
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                  ),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Import feature coming soon!')),
                    );
                  },
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // App Settings
          Card(
            elevation: 2,
            child: Column(
              children: [
                ListTile(
                  leading: Icon(
                    Icons.notifications,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  title: Text(
                    'Notifications',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  subtitle: Text(
                    'Manage notifications',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  trailing: Switch(
                    value: true,
                    onChanged: (value) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Notification settings coming soon!')),
                      );
                    },
                  ),
                ),
                Divider(
                  height: 1,
                  color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                ),
                ListTile(
                  leading: Icon(
                    Icons.dark_mode,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  title: Text(
                    'Dark Mode',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  subtitle: Text(
                    'Theme appearance',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  trailing: Switch(
                    value: false,
                    onChanged: (value) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Theme settings coming soon!')),
                      );
                    },
                  ),
                ),
                Divider(
                  height: 1,
                  color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                ),
                ListTile(
                  leading: Icon(
                    Icons.language,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  title: Text(
                    'Language',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  subtitle: Text(
                    'English',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  trailing: Icon(
                    Icons.chevron_right,
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                  ),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Language settings coming soon!')),
                    );
                  },
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Support
          Card(
            elevation: 2,
            child: Column(
              children: [
                ListTile(
                  leading: Icon(
                    Icons.help_outline,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  title: Text(
                    'Help & Support',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  subtitle: Text(
                    'Get help and contact support',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  trailing: Icon(
                    Icons.chevron_right,
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                  ),
                  onTap: () {
                    _showHelpDialog(context);
                  },
                ),
                Divider(
                  height: 1,
                  color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                ),
                ListTile(
                  leading: Icon(
                    Icons.info_outline,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  title: Text(
                    'About',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  subtitle: Text(
                    'App version and information',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  trailing: Icon(
                    Icons.chevron_right,
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                  ),
                  onTap: () {
                    _showAboutDialog(context);
                  },
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 32),
          
          // Danger Zone
          Card(
            elevation: 2,
            color: Theme.of(context).colorScheme.errorContainer,
            child: ListTile(
              leading: Icon(
                Icons.warning,
                color: Theme.of(context).colorScheme.onErrorContainer,
              ),
              title: Text(
                'Reset App Data',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onErrorContainer,
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Text(
                'Clear all local data and reset to default',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onErrorContainer,
                ),
              ),
              onTap: () {
                _showResetDialog(context);
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Help & Support'),
        content: const Text(
          'Timeline Biography helps you organize and visualize your life events.\n\n'
          'Features:\n'
          '• Multiple timeline views\n'
          '• Story creation\n'
          '• Media management\n'
          '• Event clustering\n'
          '• Location tracking\n\n'
          'For support, contact: support@timelinebiography.app',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Got it!'),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'Timeline Biography',
      applicationVersion: '1.0.0',
      applicationIcon: const Icon(Icons.timeline, size: 48),
      children: const [
        Text('A beautiful way to visualize and organize your life story.'),
        SizedBox(height: 16),
        Text('Created with ❤️ for preserving memories.'),
      ],
    );
  }

  void _showResetDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset App Data'),
        content: const Text(
          'This will clear all your local data including events, stories, and settings. This action cannot be undone.\n\n'
          'Are you sure you want to continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Reset feature coming soon!')),
              );
            },
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }
}
