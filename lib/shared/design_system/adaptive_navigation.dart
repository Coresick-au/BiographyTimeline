import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'responsive_layout.dart';
import 'app_icons.dart';

/// Adaptive navigation system that adjusts to different screen sizes
/// Provides consistent navigation patterns across platforms
class AdaptiveNavigation extends ConsumerStatefulWidget {
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final List<NavigationItem> destinations;
  final Widget? body;
  final Widget? floatingActionButton;
  final List<Widget>? persistentFooterButtons;
  final Widget? drawer;
  final bool extendBody;
  final bool extendBodyBehindAppBar;
  final PreferredSizeWidget? appBar;
  final Color? backgroundColor;
  final bool showUnselectedLabels;
  final double? navigationRailWidth;

  const AdaptiveNavigation({
    Key? key,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.destinations,
    this.body,
    this.floatingActionButton,
    this.persistentFooterButtons,
    this.drawer,
    this.extendBody = false,
    this.extendBodyBehindAppBar = false,
    this.appBar,
    this.backgroundColor,
    this.showUnselectedLabels = true,
    this.navigationRailWidth,
  }) : super(key: key);

  @override
  ConsumerState<AdaptiveNavigation> createState() => _AdaptiveNavigationState();
}

class _AdaptiveNavigationState extends ConsumerState<AdaptiveNavigation> {
  late int _selectedIndex;
  late bool _isExtended;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.selectedIndex;
    _isExtended = ResponsiveLayout.isDesktop(context);
  }

  @override
  void didUpdateWidget(AdaptiveNavigation oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedIndex != widget.selectedIndex) {
      setState(() {
        _selectedIndex = widget.selectedIndex;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = ResponsiveLayout.getScreenSize(context);
    
    switch (screenSize) {
      case ScreenSize.mobile:
        return _buildMobileLayout();
      case ScreenSize.tablet:
        return _buildTabletLayout();
      case ScreenSize.desktop:
      case ScreenSize.largeDesktop:
        return _buildDesktopLayout();
    }
  }

  Widget _buildMobileLayout() {
    return Scaffold(
      key: _scaffoldKey,
      appBar: widget.appBar,
      body: widget.body,
      backgroundColor: widget.backgroundColor,
      extendBody: widget.extendBody,
      extendBodyBehindAppBar: widget.extendBodyBehindAppBar,
      floatingActionButton: widget.floatingActionButton,
      persistentFooterButtons: widget.persistentFooterButtons,
      drawer: widget.drawer ?? _buildDrawer(),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildTabletLayout() {
    return Scaffold(
      key: _scaffoldKey,
      appBar: widget.appBar,
      body: Row(
        children: [
          _buildNavigationRail(),
          Expanded(child: widget.body ?? Container()),
        ],
      ),
      backgroundColor: widget.backgroundColor,
      extendBody: widget.extendBody,
      extendBodyBehindAppBar: widget.extendBodyBehindAppBar,
      floatingActionButton: widget.floatingActionButton,
      persistentFooterButtons: widget.persistentFooterButtons,
      drawer: widget.drawer,
    );
  }

  Widget _buildDesktopLayout() {
    return Scaffold(
      key: _scaffoldKey,
      appBar: widget.appBar,
      body: Row(
        children: [
          _buildNavigationRail(extended: true),
          Expanded(child: widget.body ?? Container()),
        ],
      ),
      backgroundColor: widget.backgroundColor,
      extendBody: widget.extendBody,
      extendBodyBehindAppBar: widget.extendBodyBehindAppBar,
      floatingActionButton: widget.floatingActionButton,
      persistentFooterButtons: widget.persistentFooterButtons,
      drawer: widget.drawer,
    );
  }

  Widget _buildBottomNavigationBar() {
    return NavigationBar(
      selectedIndex: _selectedIndex,
      onDestinationSelected: (index) {
        setState(() {
          _selectedIndex = index;
        });
        widget.onDestinationSelected(index);
      },
      destinations: widget.destinations
          .map((item) => NavigationDestination(
                icon: Icon(item.icon),
                selectedIcon: Icon(item.selectedIcon ?? item.icon),
                label: item.label,
                tooltip: item.tooltip,
              ))
          .toList(),
      backgroundColor: widget.backgroundColor,
      labelBehavior: widget.showUnselectedLabels
          ? NavigationDestinationLabelBehavior.alwaysShow
          : NavigationDestinationLabelBehavior.onlyShowSelected,
    );
  }

  Widget _buildNavigationRail({bool extended = false}) {
    return NavigationRail(
      selectedIndex: _selectedIndex,
      onDestinationSelected: (index) {
        setState(() {
          _selectedIndex = index;
        });
        widget.onDestinationSelected(index);
      },
      extended: extended,
      width: widget.navigationRailWidth,
      destinations: widget.destinations
          .map((item) => NavigationRailDestination(
                icon: Icon(item.icon),
                selectedIcon: Icon(item.selectedIcon ?? item.icon),
                label: Text(item.label),
              ))
          .toList(),
      backgroundColor: widget.backgroundColor,
      leading: extended ? _buildRailHeader() : null,
      trailing: extended ? _buildRailFooter() : null,
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          _buildDrawerHeader(),
          ...widget.destinations.map((item) => ListTile(
                leading: Icon(item.icon),
                title: Text(item.label),
                onTap: () {
                  Navigator.pop(context);
                  final index = widget.destinations.indexOf(item);
                  setState(() {
                    _selectedIndex = index;
                  });
                  widget.onDestinationSelected(index);
                },
                selected: _selectedIndex == widget.destinations.indexOf(item),
              )),
        ],
      ),
    );
  }

  Widget _buildDrawerHeader() {
    return DrawerHeader(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            AppIcons.viewTimeline,
            size: 48,
            color: Theme.of(context).colorScheme.onPrimary,
          ),
          SizedBox(height: 16),
          Text(
            'Timeline Biography',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Theme.of(context).colorScheme.onPrimary,
            ),
          ),
          Text(
            'Your Life, Your Story',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRailHeader() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            AppIcons.viewTimeline,
            size: 32,
            color: Theme.of(context).colorScheme.primary,
          ),
          SizedBox(height: 8),
          Text(
            'Timeline',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRailFooter() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: IconButton(
        icon: Icon(Icons.settings),
        onPressed: () {
          // Handle settings
        },
        tooltip: 'Settings',
      ),
    );
  }
}

/// Navigation item configuration
class NavigationItem {
  final IconData icon;
  final IconData? selectedIcon;
  final String label;
  final String? tooltip;

  const NavigationItem({
    required this.icon,
    this.selectedIcon,
    required this.label,
    this.tooltip,
  });
}

/// Common navigation destinations for the app
class AppNavigationDestinations {
  // Private constructor to prevent instantiation
  AppNavigationDestinations._();

  static const List<NavigationItem> primary = [
    NavigationItem(
      icon: AppIcons.timeline,
      label: 'Timeline',
      tooltip: 'View timeline',
    ),
    NavigationItem(
      icon: AppIcons.photoLibrary,
      label: 'Media',
      tooltip: 'Browse media',
    ),
    NavigationItem(
      icon: AppIcons.people,
      label: 'People',
      tooltip: 'View people',
    ),
    NavigationItem(
      icon: AppIcons.locationOn,
      label: 'Places',
      tooltip: 'View places',
    ),
    NavigationItem(
      icon: AppIcons.star,
      label: 'Milestones',
      tooltip: 'View milestones',
    ),
  ];

  static const List<NavigationItem> secondary = [
    NavigationItem(
      icon: AppIcons.search,
      label: 'Search',
      tooltip: 'Search content',
    ),
    NavigationItem(
      icon: AppIcons.settings,
      label: 'Settings',
      tooltip: 'App settings',
    ),
  ];
}

/// Tab bar navigation for sub-sections
class AdaptiveTabBar extends StatelessWidget {
  final List<Tab> tabs;
  final TabController? controller;
  final bool isScrollable;
  final Color? indicatorColor;
  final Color? labelColor;
  final Color? unselectedLabelColor;
  final TextStyle? labelStyle;
  final TextStyle? unselectedLabelStyle;

  const AdaptiveTabBar({
    Key? key,
    required this.tabs,
    this.controller,
    this.isScrollable = false,
    this.indicatorColor,
    this.labelColor,
    this.unselectedLabelColor,
    this.labelStyle,
    this.unselectedLabelStyle,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveLayout.isMobile(context);
    
    return TabBar(
      controller: controller,
      tabs: tabs,
      isScrollable: isScrollable || (isMobile && tabs.length > 3),
      indicatorColor: indicatorColor,
      labelColor: labelColor,
      unselectedLabelColor: unselectedLabelColor,
      labelStyle: labelStyle,
      unselectedLabelStyle: unselectedLabelStyle,
      indicatorWeight: isMobile ? 2.0 : 3.0,
      tabAlignment: isScrollable ? TabAlignment.start : TabAlignment.center,
    );
  }
}

/// Breadcrumb navigation
class BreadcrumbNavigation extends StatelessWidget {
  final List<BreadcrumbItem> items;
  final Color? separatorColor;
  final TextStyle? itemStyle;
  final TextStyle? lastItemStyle;

  const BreadcrumbNavigation({
    Key? key,
    required this.items,
    this.separatorColor,
    this.itemStyle,
    this.lastItemStyle,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: _buildBreadcrumbItems(),
    );
  }

  List<Widget> _buildBreadcrumbItems() {
    final List<Widget> widgets = [];
    
    for (int i = 0; i < items.length; i++) {
      final item = items[i];
      final isLast = i == items.length - 1;
      
      if (i > 0) {
        widgets.add(
          Icon(
            Icons.chevron_right,
            size: 16,
            color: separatorColor ?? Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        );
      }
      
      if (isLast || item.onTap == null) {
        widgets.add(
          Text(
            item.label,
            style: lastItemStyle ?? Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface,
              fontWeight: FontWeight.w500,
            ),
          ),
        );
      } else {
        widgets.add(
          InkWell(
            onTap: item.onTap,
            borderRadius: BorderRadius.circular(4),
            child: Text(
              item.label,
              style: itemStyle ?? Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
        );
      }
    }
    
    return widgets;
  }
}

/// Breadcrumb item
class BreadcrumbItem {
  final String label;
  final VoidCallback? onTap;

  const BreadcrumbItem({
    required this.label,
    this.onTap,
  });
}

/// Quick action buttons for adaptive navigation
class QuickActions extends StatelessWidget {
  final List<QuickAction> actions;
  final Axis direction;
  final double spacing;

  const QuickActions({
    Key? key,
    required this.actions,
    this.direction = Axis.horizontal,
    this.spacing = 8.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveLayout.isMobile(context);
    final actionSpacing = isMobile ? spacing * 0.8 : spacing;
    
    if (direction == Axis.horizontal) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: _buildActions(actionSpacing),
      );
    } else {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: _buildActions(actionSpacing),
      );
    }
  }

  List<Widget> _buildActions(double spacing) {
    final List<Widget> widgets = [];
    
    for (int i = 0; i < actions.length; i++) {
      if (i > 0) {
        widgets.add(SizedBox(
          width: direction == Axis.horizontal ? spacing : 0,
          height: direction == Axis.vertical ? spacing : 0,
        ));
      }
      
      widgets.add(_buildActionButton(actions[i], context));
    }
    
    return widgets;
  }

  Widget _buildActionButton(QuickAction action, BuildContext context) {
    return Tooltip(
      message: action.tooltip ?? action.label,
      child: IconButton.filled(
        onPressed: action.onPressed,
        icon: Icon(action.icon),
        iconSize: ResponsiveLayout.isMobile(context) ? 20 : 24,
      ),
    );
  }
}

/// Quick action configuration
class QuickAction {
  final IconData icon;
  final String label;
  final String? tooltip;
  final VoidCallback onPressed;

  const QuickAction({
    required this.icon,
    required this.label,
    this.tooltip,
    required this.onPressed,
  });
}

/// Provider for navigation state
final navigationIndexProvider = StateProvider<int>((ref) => 0);

/// Extension on BuildContext for navigation utilities
extension NavigationContextExtension on BuildContext {
  /// Get current navigation index
  int get navigationIndex => read(navigationIndexProvider);
  
  /// Update navigation index
  void updateNavigationIndex(int index) => read(navigationIndexProvider.notifier).state = index;
  
  /// Navigate to destination
  void navigateTo(int index) {
    updateNavigationIndex(index);
  }
}
