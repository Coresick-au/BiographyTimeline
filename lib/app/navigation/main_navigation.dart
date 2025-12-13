import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/timeline/screens/timeline_screen.dart';
import '../../features/stories/screens/stories_screen.dart';
import '../../features/media/screens/media_screen.dart';
import '../../features/settings/screens/settings_screen.dart';
import '../../features/social/screens/connections_screen.dart';
import '../../features/social/services/privacy_settings_service.dart';

/// Main navigation shell for the app
class MainNavigation extends ConsumerStatefulWidget {
  const MainNavigation({super.key});

  @override
  ConsumerState<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends ConsumerState<MainNavigation> {
  int _currentIndex = 0;
  final PageController _pageController = PageController();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        children: const [
          TimelineScreen(),
          StoriesScreen(),
          ConnectionsScreen(),
          MediaScreen(),
          SettingsScreen(),
        ],
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildBottomNavigationBar() {
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
          _pageController.animateToPage(
            index,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.timeline),
            activeIcon: Icon(Icons.timeline),
            label: 'Timeline',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.auto_stories),
            activeIcon: Icon(Icons.auto_stories),
            label: 'Stories',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people),
            activeIcon: Icon(Icons.people),
            label: 'Connections',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.photo_library),
            activeIcon: Icon(Icons.photo_library),
            label: 'Media',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            activeIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}

/// Navigation item model
class NavigationItem {
  final String id;
  final String title;
  final IconData icon;
  final IconData activeIcon;
  final Widget widget;

  const NavigationItem({
    required this.id,
    required this.title,
    required this.icon,
    required this.activeIcon,
    required this.widget,
  });
}

/// Navigation provider for managing navigation state
class NavigationNotifier extends StateNotifier<int> {
  NavigationNotifier() : super(0);

  void setIndex(int index) {
    state = index;
  }

  void navigateToTimeline() => state = 0;
  void navigateToStories() => state = 1;
  void navigateToMedia() => state = 2;
  void navigateToSettings() => state = 3;
}

/// Provider for navigation state
final navigationProvider = StateNotifierProvider<NavigationNotifier, int>((ref) {
  return NavigationNotifier();
});

/// Provider for navigation items
final navigationItemsProvider = Provider<List<NavigationItem>>((ref) {
  return [
    const NavigationItem(
      id: 'timeline',
      title: 'Timeline',
      icon: Icons.timeline,
      activeIcon: Icons.timeline,
      widget: TimelineScreen(),
    ),
    const NavigationItem(
      id: 'stories',
      title: 'Stories',
      icon: Icons.auto_stories,
      activeIcon: Icons.auto_stories,
      widget: StoriesScreen(),
    ),
    const NavigationItem(
      id: 'media',
      title: 'Media',
      icon: Icons.photo_library,
      activeIcon: Icons.photo_library,
      widget: MediaScreen(),
    ),
    const NavigationItem(
      id: 'settings',
      title: 'Settings',
      icon: Icons.settings,
      activeIcon: Icons.settings,
      widget: SettingsScreen(),
    ),
  ];
});

/// Enhanced navigation with drawer option
class EnhancedNavigation extends ConsumerStatefulWidget {
  const EnhancedNavigation({super.key});

  @override
  ConsumerState<EnhancedNavigation> createState() => _EnhancedNavigationState();
}

class _EnhancedNavigationState extends ConsumerState<EnhancedNavigation> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  
  @override
  Widget build(BuildContext context) {
    final currentIndex = ref.watch(navigationProvider);
    final navigationItems = ref.watch(navigationItemsProvider);
    
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text(navigationItems[currentIndex].title),
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: _showSearch,
          ),
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: _showNotifications,
          ),
        ],
      ),
      drawer: _buildDrawer(navigationItems, currentIndex),
      body: navigationItems[currentIndex].widget,
      bottomNavigationBar: _buildBottomNavigationBar(navigationItems, currentIndex),
      floatingActionButton: _buildFloatingActionButton(currentIndex),
    );
  }

  Widget _buildDrawer(List<NavigationItem> items, int currentIndex) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Theme.of(context).colorScheme.onPrimary,
                  child: Icon(
                    Icons.person,
                    size: 30,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Timeline Biography',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Your life story, beautifully organized',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.8),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          ...items.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            return ListTile(
              leading: Icon(
                currentIndex == index ? item.activeIcon : item.icon,
                color: currentIndex == index 
                    ? Theme.of(context).colorScheme.primary 
                    : null,
              ),
              title: Text(
                item.title,
                style: TextStyle(
                  color: currentIndex == index 
                      ? Theme.of(context).colorScheme.primary 
                      : null,
                  fontWeight: currentIndex == index 
                      ? FontWeight.bold 
                      : null,
                ),
              ),
              onTap: () {
                Navigator.of(context).pop();
                ref.read(navigationProvider.notifier).setIndex(index);
              },
              selected: currentIndex == index,
            );
          }).toList(),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.help_outline),
            title: const Text('Help & Support'),
            onTap: () {
              Navigator.of(context).pop();
              _showHelp();
            },
          ),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('About'),
            onTap: () {
              Navigator.of(context).pop();
              _showAbout();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavigationBar(List<NavigationItem> items, int currentIndex) {
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: (index) {
          ref.read(navigationProvider.notifier).setIndex(index);
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        items: items.map((item) => BottomNavigationBarItem(
          icon: Icon(item.icon),
          activeIcon: Icon(item.activeIcon),
          label: item.title,
        )).toList(),
      ),
    );
  }

  Widget _buildFloatingActionButton(int currentIndex) {
    switch (currentIndex) {
      case 0: // Timeline
        return FloatingActionButton(
          onPressed: _addTimelineEvent,
          child: const Icon(Icons.add),
        );
      case 1: // Stories
        return FloatingActionButton(
          onPressed: _createStory,
          child: const Icon(Icons.add),
        );
      case 2: // Media
        return FloatingActionButton(
          onPressed: _uploadMedia,
          child: const Icon(Icons.upload),
        );
      default:
        return const SizedBox.shrink();
    }
  }

  void _showSearch() {
    // TODO: Implement search functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Search coming soon!')),
    );
  }

  void _showNotifications() {
    // TODO: Implement notifications
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Notifications coming soon!')),
    );
  }

  void _addTimelineEvent() {
    // TODO: Navigate to add event screen
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Add event coming soon!')),
    );
  }

  void _createStory() {
    // TODO: Navigate to create story screen
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Create story coming soon!')),
    );
  }

  void _uploadMedia() {
    // TODO: Navigate to upload media screen
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Upload media coming soon!')),
    );
  }

  void _showHelp() {
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

  void _showAbout() {
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
}
