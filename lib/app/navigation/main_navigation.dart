import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/timeline/screens/timeline_screen.dart';
import '../../features/timeline/screens/event_creation_screen.dart';
import '../../features/timeline/screens/event_details_screen.dart';
import '../../features/stories/screens/stories_screen.dart';
import '../../features/stories/screens/story_editor_screen.dart';
import '../../features/social/screens/connections_screen.dart';
import '../../features/media/screens/media_screen.dart';
import '../../features/settings/screens/settings_screen.dart';
import '../../features/search/widgets/simple_search_widget.dart';
import '../../features/ghost_camera/widgets/simple_ghost_camera_dialog.dart';
import '../../features/notifications/screens/notifications_screen.dart';
import '../../features/notifications/providers/notification_provider.dart';
import '../../features/timeline/services/timeline_data_service.dart' as timeline_service;

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
      height: 80,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
          BoxShadow(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
            blurRadius: 30,
            offset: const Offset(0, -10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        child: Row(
          children: [
            _buildCustomNavItem(
              icon: Icons.timeline_outlined,
              activeIcon: Icons.timeline,
              label: 'Timeline',
              index: 0,
            ),
            _buildCustomNavItem(
              icon: Icons.auto_stories_outlined,
              activeIcon: Icons.auto_stories,
              label: 'Stories',
              index: 1,
            ),
            _buildCustomNavItem(
              icon: Icons.people_outline,
              activeIcon: Icons.people,
              label: 'Connections',
              index: 2,
            ),
            _buildCustomNavItem(
              icon: Icons.photo_library_outlined,
              activeIcon: Icons.photo_library,
              label: 'Media',
              index: 3,
            ),
            _buildCustomNavItem(
              icon: Icons.settings_outlined,
              activeIcon: Icons.settings,
              label: 'Settings',
              index: 4,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomNavItem({
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required int index,
  }) {
    final isSelected = _currentIndex == index;
    final color = isSelected 
        ? Theme.of(context).colorScheme.primary
        : Theme.of(context).colorScheme.onSurface.withOpacity(0.6);
    
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _currentIndex = index;
          });
          _pageController.animateToPage(
            index,
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOutCubic,
          );
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: EdgeInsets.all(isSelected ? 8.0 : 4.0),
                decoration: BoxDecoration(
                  color: isSelected 
                      ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: isSelected ? [
                    BoxShadow(
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ] : null,
                ),
                child: Icon(
                  isSelected ? activeIcon : icon,
                  color: color,
                  size: isSelected ? 26 : 24,
                ),
              ),
              const SizedBox(height: 4),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 200),
                style: TextStyle(
                  color: color,
                  fontSize: isSelected ? 12 : 11,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                ),
                child: Text(label),
              ),
            ],
          ),
        ),
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

/// Provider for navigation state (commented out to avoid errors)
// final navigationProvider = StateNotifierProvider<NavigationNotifier, int>((ref) {
//   return NavigationNotifier();
// });

/// Provider for navigation items (commented out to avoid errors)
// final navigationItemsProvider = Provider<List<NavigationItem>>((ref) {
//   return [
//     const NavigationItem(
//       id: 'timeline',
//       title: 'Timeline',
//       icon: Icons.timeline,
//       activeIcon: Icons.timeline,
//       widget: TimelineScreen(),
//     ),
//     const NavigationItem(
//       id: 'stories',
//       title: 'Stories',
//       icon: Icons.auto_stories,
//       activeIcon: Icons.auto_stories,
//       widget: StoriesScreen(),
//     ),
//     const NavigationItem(
//       id: 'media',
//       title: 'Media',
//       icon: Icons.photo_library,
//       activeIcon: Icons.photo_library,
//       widget: MediaScreen(),
//     ),
//     const NavigationItem(
//       id: 'settings',
//       title: 'Settings',
//       icon: Icons.settings,
//       activeIcon: Icons.settings,
//       widget: SettingsScreen(),
//     ),
//   ];
// });

/// Enhanced navigation with drawer option
class EnhancedNavigation extends ConsumerStatefulWidget {
  const EnhancedNavigation({super.key});

  @override
  ConsumerState<EnhancedNavigation> createState() => _EnhancedNavigationState();
}

class _EnhancedNavigationState extends ConsumerState<EnhancedNavigation> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int _currentIndex = 0;
    
  @override
  Widget build(BuildContext context) {
    final navigationItems = [
      NavigationItem(
        id: 'timeline',
        title: 'Timeline',
        icon: Icons.timeline_outlined,
        activeIcon: Icons.timeline,
        widget: const TimelineScreen(),
      ),
      NavigationItem(
        id: 'stories',
        title: 'Stories',
        icon: Icons.auto_stories_outlined,
        activeIcon: Icons.auto_stories,
        widget: const StoriesScreen(),
      ),
      NavigationItem(
        id: 'connections',
        title: 'Connections',
        icon: Icons.people_outline,
        activeIcon: Icons.people,
        widget: const ConnectionsScreen(),
      ),
      NavigationItem(
        id: 'media',
        title: 'Media',
        icon: Icons.photo_library_outlined,
        activeIcon: Icons.photo_library,
        widget: const MediaScreen(),
      ),
      NavigationItem(
        id: 'settings',
        title: 'Settings',
        icon: Icons.settings_outlined,
        activeIcon: Icons.settings,
        widget: const SettingsScreen(),
      ),
    ];
    
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text(navigationItems[_currentIndex].title),
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: _showSearch,
          ),
          // Notification bell with badge
          Stack(
            clipBehavior: Clip.none,
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined),
                onPressed: _showNotifications,
                tooltip: 'Notifications',
              ),
              // Unread badge
              Consumer(
                builder: (context, ref, child) {
                  final unreadCount = ref.watch(unreadNotificationCountProvider);
                  if (unreadCount == 0) return const SizedBox.shrink();
                  
                  return Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Text(
                        unreadCount > 9 ? '9+' : unreadCount.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
      drawer: _buildDrawer(navigationItems, _currentIndex),
      body: navigationItems[_currentIndex].widget,
      bottomNavigationBar: _buildBottomNavigationBar(navigationItems, _currentIndex),
      floatingActionButton: _buildFloatingActionButton(_currentIndex),
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
                setState(() {
                  _currentIndex = index;
                });
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
      height: 80,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
          BoxShadow(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
            blurRadius: 30,
            offset: const Offset(0, -10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        child: Row(
          children: items.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            return _buildEnhancedCustomNavItem(
              icon: item.icon,
              activeIcon: item.activeIcon,
              label: item.title,
              index: index,
              currentIndex: currentIndex,
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildEnhancedCustomNavItem({
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required int index,
    required int currentIndex,
  }) {
    final isSelected = currentIndex == index;
    final color = isSelected 
        ? Theme.of(context).colorScheme.primary
        : Theme.of(context).colorScheme.onSurface.withOpacity(0.6);
    
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _currentIndex = index;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: EdgeInsets.all(isSelected ? 8.0 : 4.0),
                decoration: BoxDecoration(
                  color: isSelected 
                      ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: isSelected ? [
                    BoxShadow(
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ] : null,
                ),
                child: Icon(
                  isSelected ? activeIcon : icon,
                  color: color,
                  size: isSelected ? 26 : 24,
                ),
              ),
              const SizedBox(height: 4),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 200),
                style: TextStyle(
                  color: color,
                  fontSize: isSelected ? 12 : 11,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                ),
                child: Text(label),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFloatingActionButton(int currentIndex) {
    switch (currentIndex) {
      case 0: // Timeline
        return FloatingActionButton(
          heroTag: 'main_nav_timeline_fab',
          onPressed: _addTimelineEvent,
          child: const Icon(Icons.add),
        );
      case 1: // Stories
        return FloatingActionButton(
          heroTag: 'main_nav_stories_fab',
          onPressed: _createStory,
          child: const Icon(Icons.add),
        );
      case 2: // Media
        return FloatingActionButton(
          heroTag: 'main_nav_media_fab',
          onPressed: _uploadMedia,
          child: const Icon(Icons.upload),
        );
      default:
        return const SizedBox.shrink();
    }
  }

  void _showSearch() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          height: MediaQuery.of(context).size.height * 0.8,
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Search Timeline',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: SimpleSearchWidget(
                  onResultSelected: (event) {
                    Navigator.of(context).pop(); // Close search dialog
                    
                    // Get the context for this event
                    final asyncState = ref.read(timeline_service.timelineDataProvider);
                    final contexts = asyncState.value?.contexts ?? [];
                    final eventContext = contexts.firstWhere(
                      (ctx) => ctx.id == event.contextId,
                      orElse: () => contexts.isNotEmpty ? contexts.first : throw Exception('No context found'),
                    );
                    
                    // Navigate to event details screen
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => EventDetailsScreen(
                          event: event,
                          context: eventContext,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showNotifications() {
    // TODO: Implement
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const NotificationsScreen(),
      ),
    );
  }

  void _addTimelineEvent() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const EventCreationScreen(),
      ),
    ).then((event) {
      if (event != null) {
        // Event was created successfully
        // The timeline will refresh automatically via providers
      }
    });
  }

  void _createStory() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const StoryEditorScreen(
          eventId: null, // Creating a new story without an event
          contextId: 'context-1', // Use first context
        ),
      ),
    );
  }

  void _uploadMedia() {
    showDialog(
      context: context,
      builder: (context) => const SimpleGhostCameraDialog(),
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
