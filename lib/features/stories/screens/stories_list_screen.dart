import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/models/story.dart';
import '../../../shared/models/timeline_event.dart';
import '../presentation/pages/story_page.dart';

/// Stories list screen showing all created stories
class StoriesListScreen extends ConsumerStatefulWidget {
  const StoriesListScreen({super.key});

  @override
  ConsumerState<StoriesListScreen> createState() => _StoriesListScreenState();
}

class _StoriesListScreenState extends ConsumerState<StoriesListScreen> {
  List<Story> _stories = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStories();
  }

  Future<void> _loadStories() async {
    setState(() => _isLoading = true);
    
    try {
      // For now, create sample stories using the actual Story model
      _stories = [
        Story(
          id: 'story-1',
          eventId: 'event-1',
          authorId: 'user-1',
          blocks: [
            StoryBlock.text(
              id: 'block-1',
              text: 'That amazing summer vacation at the beach was unforgettable. The sun, the sand, and the sound of waves created memories that will last a lifetime...',
            ),
          ],
          createdAt: DateTime.now().subtract(const Duration(days: 30)),
          updatedAt: DateTime.now().subtract(const Duration(days: 30)),
          version: 1,
        ),
        Story(
          id: 'story-2',
          eventId: 'event-2',
          authorId: 'user-1',
          blocks: [
            StoryBlock.text(
              id: 'block-2',
              text: 'Walking into the office on my first day, I felt a mix of excitement and nerves. The corporate environment was new to me, but I was ready for the challenge...',
            ),
          ],
          createdAt: DateTime.now().subtract(const Duration(days: 60)),
          updatedAt: DateTime.now().subtract(const Duration(days: 58)),
          version: 1,
        ),
      ];
    } catch (e) {
      debugPrint('Error loading stories: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // App bar
          SliverAppBar(
            expandedHeight: 120,
            floating: false,
            pinned: true,
            backgroundColor: Colors.transparent,
            elevation: 0,
            flexibleSpace: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF667EEA),
                    const Color(0xFF764BA2),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Stories',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${_stories.length} stories',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          // Content
          if (_isLoading)
            const SliverFillRemaining(
              child: Center(
                child: CircularProgressIndicator(),
              ),
            )
          else if (_stories.isEmpty)
            SliverFillRemaining(
              child: _buildEmptyState(),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => _buildStoryCard(_stories[index]),
                  childCount: _stories.length,
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createNewStory,
        icon: const Icon(Icons.add),
        label: const Text('Create Story'),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.auto_stories,
            size: 64,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'No stories yet',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create your first story from a timeline event',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStoryCard(Story story) {
    // Extract title from first text block
    final firstTextBlock = story.blocks.firstWhere(
      (block) => block.type == BlockType.text,
      orElse: () => StoryBlock.text(id: 'empty', text: 'Untitled Story'),
    );
    final text = firstTextBlock.content['text'] as String? ?? '';
    final title = text.length > 50 
        ? '${text.substring(0, 50)}...' 
        : text;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      child: InkWell(
        onTap: () => _openStory(story),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleLarge,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Text(
                text,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.schedule,
                    size: 16,
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _formatDate(story.updatedAt),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.short_text,
                    size: 16,
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${story.wordCount} words',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else if (difference.inDays < 30) {
      return '${(difference.inDays / 7).floor()} weeks ago';
    } else {
      return '${(difference.inDays / 30).floor()} months ago';
    }
  }

  void _openStory(Story story) {
    // Create a dummy event for the story
    final event = TimelineEvent.create(
      id: story.eventId,
      contextId: 'personal-1',
      ownerId: story.authorId,
      timestamp: story.createdAt,
      eventType: 'story',
      title: 'Story Event',
      description: 'A story',
    );

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => StoryPage(
          event: event,
          existingStory: story,
          isViewMode: true,
        ),
      ),
    );
  }

  void _createNewStory() {
    // For now, show a dialog to select an event
    // In a real app, this would navigate to event selection
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create New Story'),
        content: const Text(
          'To create a story, first select an event from your timeline.\n\n'
          'Navigate to the Timeline tab, tap on an event, and choose "Create Story".',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }
}
