import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../modern/glassmorphism_card.dart';
import '../modern/animated_buttons.dart';
import '../modern/shimmer_loading.dart';

/// Enhanced timeline screen with modern UI design
class EnhancedTimelineScreen extends ConsumerStatefulWidget {
  const EnhancedTimelineScreen({super.key});

  @override
  ConsumerState<EnhancedTimelineScreen> createState() => _EnhancedTimelineScreenState();
}

class _EnhancedTimelineScreenState extends ConsumerState<EnhancedTimelineScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _fabController;
  late AnimationController _headerController;
  late Animation<double> _fabAnimation;
  late Animation<double> _headerOpacityAnimation;
  late Animation<Offset> _headerSlideAnimation;
  
  bool _isLoading = true;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _fabController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _headerController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fabAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fabController,
      curve: Curves.elasticOut,
    ));

    _headerOpacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _headerController,
      curve: Curves.easeInOut,
    ));

    _headerSlideAnimation = Tween<Offset>(
      begin: const Offset(0, -0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _headerController,
      curve: Curves.easeOutBack,
    ));

    // Start animations
    _headerController.forward();
    _fabController.forward();

    // Simulate loading
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _fabController.dispose();
    _headerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            _buildSliverAppBar(),
            _buildSliverTabBar(),
          ];
        },
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildChronologicalView(),
            _buildClusteredView(),
            _buildMapView(),
            _buildStoriesView(),
          ],
        ),
      ),
      floatingActionButton: _buildFloatingActionButton(),
      floatingActionButtonLocation: FloatingActionButtonLocation.endDocked,
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 200,
      floating: false,
      pinned: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFF667EEA),
                const Color(0xFF764BA2),
                const Color(0xFF667EEA).withOpacity(0.8),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AnimatedBuilder(
                    animation: _headerOpacityAnimation,
                    builder: (context, child) {
                      return FadeTransition(
                        opacity: _headerOpacityAnimation,
                        child: SlideTransition(
                          position: _headerSlideAnimation,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Your Life Timeline',
                                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Capture every moment of your journey',
                                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                  color: Colors.white.withOpacity(0.9),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                  const Spacer(),
                  _buildStatsRow(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatsRow() {
    return AnimatedBuilder(
      animation: _headerOpacityAnimation,
      builder: (context, child) {
        return FadeTransition(
          opacity: _headerOpacityAnimation,
          child: Row(
            children: [
              _buildStatCard('Events', '1,234', Icons.event),
              const SizedBox(width: 12),
              _buildStatCard('Stories', '56', Icons.book),
              const SizedBox(width: 12),
              _buildStatCard('Photos', '892', Icons.photo),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon) {
    return GlassmorphismCard(
      width: 100,
      height: 60,
      borderRadius: 12,
      opacity: 0.15,
      padding: const EdgeInsets.all(8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.white, size: 16),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverTabBar() {
    return SliverPersistentHeader(
      delegate: _TabBarDelegate(
        TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Chronological'),
            Tab(text: 'Clustered'),
            Tab(text: 'Map'),
            Tab(text: 'Stories'),
          ],
          labelColor: const Color(0xFF667EEA),
          unselectedLabelColor: Colors.grey,
          indicatorColor: const Color(0xFF667EEA),
          indicatorWeight: 3,
          labelStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),
      pinned: true,
    );
  }

  Widget _buildChronologicalView() {
    if (_isLoading) {
      return _buildLoadingView();
    }

    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                return _buildTimelineEventCard(index);
              },
              childCount: 10,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildClusteredView() {
    if (_isLoading) {
      return _buildLoadingView();
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.8,
      ),
      itemBuilder: (context, index) {
        return _buildClusterCard(index);
      },
      itemCount: 6,
    );
  }

  Widget _buildMapView() {
    if (_isLoading) {
      return _buildLoadingView();
    }

    return Container(
      margin: const EdgeInsets.all(16),
      child: GlassmorphismCard(
        height: 400,
        borderRadius: 16,
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.map, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                'Map View',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Interactive map coming soon',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStoriesView() {
    if (_isLoading) {
      return _buildLoadingView();
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemBuilder: (context, index) {
        return _buildStoryCard(index);
      },
      itemCount: 5,
    );
  }

  Widget _buildTimelineEventCard(int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: GradientCard(
        gradient: LinearGradient(
          colors: [
            Colors.primaries[index % Colors.primaries.length].withOpacity(0.8),
            Colors.primaries[index % Colors.primaries.length].withOpacity(0.6),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: 16,
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: const Icon(
                    Icons.event,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Event ${index + 1}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'December ${10 + index}, 2024',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'This is a sample timeline event description that showcases the beautiful design of the enhanced timeline interface.',
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 14,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                ModernOutlineButton(
                  text: 'View Details',
                  onPressed: () {},
                  textColor: Colors.white,
                  borderColor: Colors.white,
                  borderRadius: 8,
                ),
                const Spacer(),
                Icon(
                  Icons.favorite_border,
                  color: Colors.white.withOpacity(0.8),
                  size: 20,
                ),
                const SizedBox(width: 4),
                Text(
                  '42',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClusterCard(int index) {
    return GlassmorphismCard(
      borderRadius: 16,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.primaries[index % Colors.primaries.length],
                  Colors.primaries[index % Colors.primaries.length].withOpacity(0.7),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.category,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Cluster ${index + 1}',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${(index + 1) * 12} events',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
          const Spacer(),
          LinearProgressIndicator(
            value: (index + 1) / 6,
            backgroundColor: Colors.grey[200],
            valueColor: AlwaysStoppedAnimation<Color>(
              Colors.primaries[index % Colors.primaries.length],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStoryCard(int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: NeumorphicContainer(
        borderRadius: 16,
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.primaries[index % Colors.primaries.length],
                        Colors.primaries[index % Colors.primaries.length].withOpacity(0.7),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.book,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Story Chapter ${index + 1}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Last updated ${index + 1} days ago',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'A compelling story about your experiences and memories from this period of your life.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
                height: 1.4,
              ),
            ),
            const SizedBox(height: 12),
            ModernAnimatedButton(
              text: 'Continue Reading',
              onPressed: () {},
              primaryColor: Colors.primaries[index % Colors.primaries.length],
              height: 36,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingView() {
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                return const TimelineEventSkeleton(
                  showAvatar: true,
                  showDate: true,
                  showDescription: true,
                );
              },
              childCount: 8,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFloatingActionButton() {
    return AnimatedBuilder(
      animation: _fabAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _fabAnimation.value,
          child: ModernFloatingActionButton(
            onPressed: () {
              _showAddEventDialog();
            },
            child: const Icon(Icons.add),
            backgroundColor: const Color(0xFF667EEA),
            enableRotation: true,
            enablePulse: false,
          ),
        );
      },
    );
  }

  Widget _buildBottomNavigationBar() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            spreadRadius: 0,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: (index) {
            setState(() => _selectedIndex = index);
          },
          backgroundColor: Colors.transparent,
          elevation: 0,
          type: BottomNavigationBarType.fixed,
          selectedItemColor: const Color(0xFF667EEA),
          unselectedItemColor: Colors.grey,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.timeline),
              label: 'Timeline',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.grid_view),
              label: 'Overview',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.people),
              label: 'Social',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.settings),
              label: 'Settings',
            ),
          ],
        ),
      ),
    );
  }

  void _showAddEventDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF667EEA).withOpacity(0.1),
                  const Color(0xFF764BA2).withOpacity(0.1),
                ],
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Add New Event',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                ModernAnimatedButton(
                  text: 'Create Event',
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  primaryColor: const Color(0xFF667EEA),
                ),
                const SizedBox(height: 12),
                ModernOutlineButton(
                  text: 'Cancel',
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  borderColor: const Color(0xFF667EEA),
                  textColor: const Color(0xFF667EEA),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Custom delegate for the persistent header
class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar _tabBar;

  _TabBarDelegate(this._tabBar);

  @override
  double get minExtent => _tabBar.preferredSize.height;

  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_TabBarDelegate oldDelegate) {
    return false;
  }
}
