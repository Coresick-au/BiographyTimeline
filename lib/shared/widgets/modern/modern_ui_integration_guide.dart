import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'glassmorphism_card.dart';
import 'animated_buttons.dart';
import 'shimmer_loading.dart';
import 'dark_theme.dart';

/// Comprehensive guide and examples for integrating modern UI components
/// 
/// This file demonstrates how to use all the modern UI components we've created
/// to make your Timeline Biography App look stunning and professional.
/// 
/// ## How to Use These Components:
/// 
/// 1. **Glassmorphism Cards**: Perfect for overlays, modals, and modern card designs
/// 2. **Animated Buttons**: Interactive buttons with gradient effects and animations
/// 3. **Shimmer Loading**: Beautiful loading states for better UX
/// 4. **Dark Theme**: Complete dark mode with smooth transitions
/// 
/// ## Integration Steps:
/// 
/// ### 1. Update your main.dart to include theme switching:
/// ```dart
/// void main() {
///   runApp(const ProviderScope(child: TimelineBiographyApp()));
/// }
/// 
/// class TimelineBiographyApp extends ConsumerWidget {
///   @override
///   Widget build(BuildContext context, WidgetRef ref) {
///     final isDarkMode = ref.watch(themeProvider);
///     
///     return MaterialApp(
///       title: 'Timeline Biography',
///       theme: ThemeData(useMaterial3: true, brightness: Brightness.light),
///       darkTheme: ModernDarkTheme.darkTheme,
///       themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light,
///       home: const EnhancedTimelineScreen(),
///     );
///   }
/// }
/// ```

/// Example of a modern event card using glassmorphism
class ModernEventCard extends StatelessWidget {
  final String title;
  final String description;
  final String date;
  final String imageUrl;
  final VoidCallback onTap;
  final int likes;
  final bool isLiked;

  const ModernEventCard({
    super.key,
    required this.title,
    required this.description,
    required this.date,
    required this.imageUrl,
    required this.onTap,
    this.likes = 0,
    this.isLiked = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: GlassmorphismCard(
        onTap: onTap,
        borderRadius: 20,
        blur: 15,
        opacity: isDark ? 0.05 : 0.1,
        backgroundColor: isDark ? Colors.white : Colors.black,
        padding: const EdgeInsets.all(20),
        boxShadow: [
          BoxShadow(
            color: isDark 
                ? Colors.black.withOpacity(0.3)
                : Colors.black.withOpacity(0.1),
            blurRadius: 20,
            spreadRadius: 0,
            offset: const Offset(0, 10),
          ),
        ],
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with image and title
            Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: LinearGradient(
                      colors: [
                        Theme.of(context).primaryColor,
                        Theme.of(context).primaryColor.withOpacity(0.7),
                      ],
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Icon(
                          Icons.event,
                          color: Colors.white,
                          size: 30,
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        date,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                ModernAnimatedButton(
                  text: '',
                  onPressed: () {},
                  primaryColor: isLiked ? Colors.red : Theme.of(context).primaryColor,
                  width: 40,
                  height: 40,
                  icon: Icon(
                    isLiked ? Icons.favorite : Icons.favorite_border,
                    size: 20,
                  ),
                  enableShadow: false,
                  enableGradient: false,
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Description
            Text(
              description,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                height: 1.4,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            
            const SizedBox(height: 16),
            
            // Footer with actions
            Row(
              children: [
                ModernOutlineButton(
                  text: 'View Details',
                  onPressed: onTap,
                  borderRadius: 12,
                  height: 36,
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.favorite_border,
                        size: 16,
                        color: Theme.of(context).primaryColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        likes.toString(),
                        style: TextStyle(
                          color: Theme.of(context).primaryColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Icon(
                  Icons.share,
                  color: Theme.of(context).iconTheme.color?.withOpacity(0.7),
                  size: 20,
                ),
                const SizedBox(width: 16),
                Icon(
                  Icons.bookmark_border,
                  color: Theme.of(context).iconTheme.color?.withOpacity(0.7),
                  size: 20,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Modern story card with neumorphic design
class ModernStoryCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String coverImageUrl;
  final int chapterCount;
  final VoidCallback onTap;

  const ModernStoryCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.coverImageUrl,
    required this.chapterCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      margin: const EdgeInsets.all(16),
      child: NeumorphicContainer(
        borderRadius: 20,
        backgroundColor: isDark ? const Color(0xFF1E1E2E) : const Color(0xFFF0F0F0),
        padding: const EdgeInsets.all(20),
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cover image
            Container(
              width: double.infinity,
              height: 150,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).primaryColor,
                    Theme.of(context).primaryColor.withOpacity(0.7),
                  ],
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.network(
                  coverImageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Center(
                      child: Icon(
                        Icons.book,
                        color: Colors.white,
                        size: 50,
                      ),
                    );
                  },
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Title and subtitle
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            
            const SizedBox(height: 8),
            
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            
            const SizedBox(height: 16),
            
            // Chapter count and action button
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    '$chapterCount chapters',
                    style: TextStyle(
                      color: Theme.of(context).primaryColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
                const Spacer(),
                ModernAnimatedButton(
                  text: 'Continue Reading',
                  onPressed: onTap,
                  height: 36,
                  borderRadius: 18,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Modern loading screen with shimmer effects
class ModernLoadingScreen extends StatelessWidget {
  const ModernLoadingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Header shimmer
              ShimmerLoading(
                child: Container(
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
              
              const SizedBox(height: 20),
              
              // Timeline event skeletons
              Expanded(
                child: ListView.builder(
                  itemCount: 8,
                  itemBuilder: (context, index) {
                    return const TimelineEventSkeleton(
                      showAvatar: true,
                      showDate: true,
                      showDescription: true,
                      margin: EdgeInsets.only(bottom: 16),
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
}

/// Modern stats widget with glassmorphism
class ModernStatsWidget extends StatelessWidget {
  final int totalEvents;
  final int totalStories;
  final int totalPhotos;
  final int totalConnections;

  const ModernStatsWidget({
    super.key,
    required this.totalEvents,
    required this.totalStories,
    required this.totalPhotos,
    required this.totalConnections,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              context,
              'Events',
              totalEvents.toString(),
              Icons.event,
              Theme.of(context).primaryColor,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              context,
              'Stories',
              totalStories.toString(),
              Icons.book,
              Colors.purple,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              context,
              'Photos',
              totalPhotos.toString(),
              Icons.photo,
              Colors.green,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              context,
              'Connections',
              totalConnections.toString(),
              Icons.people,
              Colors.orange,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return GlassmorphismCard(
      height: 80,
      borderRadius: 16,
      opacity: 0.1,
      backgroundColor: color,
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              color: color.withOpacity(0.8),
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}

/// Modern action bar with floating buttons
class ModernActionBar extends StatelessWidget {
  final VoidCallback onAddEvent;
  final VoidCallback onAddStory;
  final VoidCallback onFilter;
  final VoidCallback onSearch;

  const ModernActionBar({
    super.key,
    required this.onAddEvent,
    required this.onAddStory,
    required this.onFilter,
    required this.onSearch,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Row(
        children: [
          ModernFloatingActionButton(
            onPressed: onAddEvent,
            child: const Icon(Icons.add),
            backgroundColor: Theme.of(context).primaryColor,
            size: 48,
          ),
          const SizedBox(width: 12),
          ModernFloatingActionButton(
            onPressed: onAddStory,
            child: const Icon(Icons.book),
            backgroundColor: Colors.purple,
            size: 48,
          ),
          const Spacer(),
          ModernOutlineButton(
            text: 'Filter',
            onPressed: onFilter,
            icon: const Icon(Icons.filter_list, size: 16),
          ),
          const SizedBox(width: 12),
          ModernOutlineButton(
            text: 'Search',
            onPressed: onSearch,
            icon: const Icon(Icons.search, size: 16),
          ),
        ],
      ),
    );
  }
}

/// Example of how to integrate everything in a complete screen
class ModernTimelineExample extends ConsumerStatefulWidget {
  const ModernTimelineExample({super.key});

  @override
  ConsumerState<ModernTimelineExample> createState() => _ModernTimelineExampleState();
}

class _ModernTimelineExampleState extends ConsumerState<ModernTimelineExample>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    // Simulate loading
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() => _isLoading = false);
        _animationController.forward();
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const ModernLoadingScreen();
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          // App bar with gradient
          SliverAppBar(
            expandedHeight: 200,
            floating: false,
            pinned: true,
            backgroundColor: Colors.transparent,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: ModernDarkTheme.primaryGradient,
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Your Timeline',
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Beautifully organized memories',
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                        const Spacer(),
                        ModernStatsWidget(
                          totalEvents: 1234,
                          totalStories: 56,
                          totalPhotos: 892,
                          totalConnections: 42,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          
          // Content
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  return AnimatedBuilder(
                    animation: _animationController,
                    builder: (context, child) {
                      final delay = index * 0.1;
                      return TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0.0, end: 1.0),
                        duration: const Duration(milliseconds: 500),
                        builder: (context, value, child) {
                          return Transform.translate(
                            offset: Offset(0, 50 * (1 - value)),
                            child: Opacity(
                              opacity: value,
                              child: child,
                            ),
                          );
                        },
                        child: index % 2 == 0
                            ? ModernEventCard(
                                title: 'Amazing Event ${index + 1}',
                                description: 'This is a beautiful description of an amazing event that happened in your life. It showcases the modern design capabilities of your app.',
                                date: 'December ${10 + index}, 2024',
                                imageUrl: 'https://picsum.photos/seed/event$index/60/60.jpg',
                                onTap: () {},
                                likes: 42 + index,
                                isLiked: index % 3 == 0,
                              )
                            : ModernStoryCard(
                                title: 'Life Chapter ${index ~/ 2 + 1}',
                                subtitle: 'The story of this amazing period in your life',
                                coverImageUrl: 'https://picsum.photos/seed/story$index/300/150.jpg',
                                chapterCount: 5 + index,
                                onTap: () {},
                              ),
                      );
                    },
                  );
                },
                childCount: 10,
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
      floatingActionButton: ModernFloatingActionButton(
        onPressed: () {
          // Add new event
        },
        child: const Icon(Icons.add),
        backgroundColor: Theme.of(context).primaryColor,
        enableRotation: true,
      ),
    );
  }

  Widget _buildBottomNavigationBar() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
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
          currentIndex: 0,
          onTap: (index) {
            // Handle navigation
          },
          backgroundColor: Colors.transparent,
          elevation: 0,
          type: BottomNavigationBarType.fixed,
          selectedItemColor: Theme.of(context).primaryColor,
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
              icon: Icon(Icons.book),
              label: 'Stories',
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
}

/// Theme provider for managing dark/light mode
final themeProvider = StateProvider<bool>((ref) => false);

/// Theme switcher widget
class ThemeSwitcher extends ConsumerWidget {
  const ThemeSwitcher({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDarkMode = ref.watch(themeProvider);
    
    return ModernAnimatedButton(
      text: isDarkMode ? 'Light Mode' : 'Dark Mode',
      onPressed: () {
        ref.read(themeProvider.notifier).state = !isDarkMode;
      },
      primaryColor: isDarkMode ? Colors.orange : Theme.of(context).primaryColor,
      icon: Icon(isDarkMode ? Icons.light_mode : Icons.dark_mode),
      height: 40,
    );
  }
}
