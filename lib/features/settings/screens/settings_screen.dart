import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Settings screen placeholder
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Profile Section
          Card(
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Theme.of(context).colorScheme.primary,
                child: const Icon(Icons.person, color: Colors.white),
              ),
              title: const Text('User Profile'),
              subtitle: const Text('Manage your account and preferences'),
              trailing: const Icon(Icons.chevron_right),
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
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.timeline),
                  title: const Text('Timeline Settings'),
                  subtitle: const Text('Configure timeline display and behavior'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Timeline settings coming soon!')),
                    );
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.view_carousel),
                  title: const Text('Default View'),
                  subtitle: const Text('Chronological'),
                  trailing: const Icon(Icons.chevron_right),
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
          
          // Privacy & Security
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.privacy_tip),
                  title: const Text('Privacy'),
                  subtitle: const Text('Manage your privacy settings'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Privacy settings coming soon!')),
                    );
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.security),
                  title: const Text('Security'),
                  subtitle: const Text('Security and authentication'),
                  trailing: const Icon(Icons.chevron_right),
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
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.storage),
                  title: const Text('Storage'),
                  subtitle: const Text('Manage data and storage'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Storage settings coming soon!')),
                    );
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.download),
                  title: const Text('Export Data'),
                  subtitle: const Text('Download your timeline data'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Export feature coming soon!')),
                    );
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.upload),
                  title: const Text('Import Data'),
                  subtitle: const Text('Import timeline from backup'),
                  trailing: const Icon(Icons.chevron_right),
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
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.notifications),
                  title: const Text('Notifications'),
                  subtitle: const Text('Manage notifications'),
                  trailing: Switch(
                    value: true,
                    onChanged: (value) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Notification settings coming soon!')),
                      );
                    },
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.dark_mode),
                  title: const Text('Dark Mode'),
                  subtitle: const Text('Theme appearance'),
                  trailing: Switch(
                    value: false,
                    onChanged: (value) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Theme settings coming soon!')),
                      );
                    },
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.language),
                  title: const Text('Language'),
                  subtitle: const Text('English'),
                  trailing: const Icon(Icons.chevron_right),
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
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.help_outline),
                  title: const Text('Help & Support'),
                  subtitle: const Text('Get help and contact support'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    _showHelpDialog(context);
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.info_outline),
                  title: const Text('About'),
                  subtitle: const Text('App version and information'),
                  trailing: const Icon(Icons.chevron_right),
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
