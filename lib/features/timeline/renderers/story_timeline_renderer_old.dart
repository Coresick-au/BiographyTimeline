import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:typed_data';
import '../services/timeline_renderer_interface.dart';
import '../../../shared/models/timeline_event.dart';
import '../../../shared/models/context.dart';
import '../../../shared/models/timeline_theme.dart';
import '../../../shared/models/story.dart';
import '../../../core/templates/template_manager.dart';

/// Story-based timeline renderer with narrative flow and scrollytelling
class StoryTimelineRenderer extends BaseTimelineRenderer {
  final ScrollController _scrollController = ScrollController();
  final PageController _pageController = PageController();
  final TemplateManager _templateManager = TemplateManager();
  
  // Story configuration
  List<Story> _stories = [];
  int _currentStoryIndex = 0;
  int _currentChapterIndex = 0;
  bool _isStoryMode = true;
  bool _showNarrative = true;
  bool _autoPlay = false;
  Timer? _autoPlayTimer;
  
  // Visual settings
  StoryLayout _layout = StoryLayout.fullscreen;
  TextStyle _narrativeStyle = const TextStyle(fontSize: 16, height: 1.6);
  Color _accentColor = Colors.blue;

  StoryTimelineRenderer(
    super.config, 
    super.data,
  ) {
    _initializeServices();
  }

  Future<void> _initializeServices() async {
    await _templateManager.initialize();
    await _generateStories();
  }

  @override
  Widget build({
    TimelineEventCallback? onEventTap,
    TimelineEventCallback? onEventLongPress,
    TimelineDateCallback? onDateTap,
    TimelineContextCallback? onContextTap,
    ScrollController? scrollController,
  }) {
    return StreamBuilder<List<Story>>(
      stream: _getStoriesStream(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final stories = snapshot.data!;
        if (stories.isEmpty) {
          return _buildEmptyState();
        }

        return _buildStoryView(
          stories,
          onEventTap: onEventTap,
          onEventLongPress: onEventLongPress,
          onDateTap: onDateTap,
          onContextTap: onContextTap,
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.auto_stories_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No stories yet',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your timeline will be woven into narrative stories',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStoryView(
    List<Story> stories, {
    TimelineEventCallback? onEventTap,
    TimelineEventCallback? onEventLongPress,
    TimelineDateCallback? onDateTap,
    TimelineContextCallback? onContextTap,
  }) {
    if (_isStoryMode) {
      return _buildStoryReader(
        stories,
        onEventTap: onEventTap,
        onEventLongPress: onEventLongPress,
        onContextTap: onContextTap,
      );
    } else {
      return _buildStoryGallery(
        stories,
        onEventTap: onEventTap,
        onEventLongPress: onEventLongPress,
        onContextTap: onContextTap,
      );
    }
  }

  Widget _buildStoryReader(
    List<Story> stories, {
    TimelineEventCallback? onEventTap,
    TimelineEventCallback? onEventLongPress,
    TimelineContextCallback? onContextTap,
  }) {
    if (_currentStoryIndex >= stories.length) {
      _currentStoryIndex = 0;
    }

    final currentStory = stories[_currentStoryIndex];
    
    return Scaffold(
      body: Stack(
        children: [
          _buildStoryContent(currentStory, onEventTap, onEventLongPress, onContextTap),
          _buildStoryControls(stories),
          _buildStoryNavigation(stories),
          if (_showNarrative) _buildNarrativeOverlay(currentStory),
        ],
      ),
    );
  }

  Widget _buildStoryContent(
    Story story, {
    TimelineEventCallback? onEventTap,
    TimelineEventCallback? onEventLongPress,
    TimelineContextCallback? onContextTap,
  }) {
    switch (_layout) {
      case StoryLayout.fullscreen:
        return _buildFullscreenStory(story, onEventTap, onEventLongPress, onContextTap);
      case StoryLayout.split:
        return _buildSplitStory(story, onEventTap, onEventLongPress, onContextTap);
      case StoryLayout.carousel:
        return _buildCarouselStory(story, onEventTap, onEventLongPress, onContextTap);
    }
  }

  Widget _buildFullscreenStory(
    Story story, {
    TimelineEventCallback? onEventTap,
    TimelineEventCallback? onEventLongPress,
    TimelineContextCallback? onContextTap,
  }) {
    return PageView.builder(
      controller: _pageController,
      onPageChanged: (index) {
        _currentChapterIndex = index;
      },
      itemCount: story.chapters.length,
      itemBuilder: (context, chapterIndex) {
        final chapter = story.chapters[chapterIndex];
        return _buildChapterView(chapter, onEventTap, onEventLongPress, onContextTap);
      },
    );
  }

  Widget _buildSplitStory(
    Story story, {
    TimelineEventCallback? onEventTap,
    TimelineEventCallback? onEventLongPress,
    TimelineContextCallback? onContextTap,
  }) {
    return Row(
      children: [
        Expanded(
          flex: 1,
          child: Container(
            color: Colors.grey[100],
            child: _buildStoryOutline(story),
          ),
        ),
        Expanded(
          flex: 2,
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              _currentChapterIndex = index;
            },
            itemCount: story.chapters.length,
            itemBuilder: (context, chapterIndex) {
              final chapter = story.chapters[chapterIndex];
              return _buildChapterView(chapter, onEventTap, onEventLongPress, onContextTap);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCarouselStory(
    Story story, {
    TimelineEventCallback? onEventTap,
    TimelineEventCallback? onEventLongPress,
    TimelineContextCallback? onContextTap,
  }) {
    return Column(
      children: [
        Expanded(
          flex: 3,
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              _currentChapterIndex = index;
            },
            itemCount: story.chapters.length,
            itemBuilder: (context, chapterIndex) {
              final chapter = story.chapters[chapterIndex];
              return _buildChapterView(chapter, onEventTap, onEventLongPress, onContextTap);
            },
          ),
        ),
        Expanded(
          flex: 1,
          child: Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey[50],
            child: _buildChapterNavigation(story),
          ),
        ),
      ],
    );
  }

  Widget _buildChapterView(
    Chapter chapter, {
    TimelineEventCallback? onEventTap,
    TimelineEventCallback? onEventLongPress,
    TimelineContextCallback? onContextTap,
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (chapter.title.isNotEmpty) ...[
            Text(
              chapter.title,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
          ],
          if (chapter.narrative.isNotEmpty && _showNarrative) ...[
            Text(
              chapter.narrative,
              style: _narrativeStyle,
            ),
            const SizedBox(height: 24),
          ],
          Expanded(
            child: _buildChapterEvents(chapter.events, onEventTap, onEventLongPress, onContextTap),
          ),
        ],
      ),
    );
  }

  Widget _buildChapterEvents(
    List<TimelineEvent> events, {
    TimelineEventCallback? onEventTap,
    TimelineEventCallback? onEventLongPress,
    TimelineContextCallback? onContextTap,
  }) {
    return ListView.builder(
      controller: _scrollController,
      itemCount: events.length,
      itemBuilder: (context, index) {
        final event = events[index];
        return _buildStoryEventCard(event, onEventTap, onEventLongPress, onContextTap);
      },
    );
  }

  Widget _buildStoryEventCard(
    TimelineEvent event, {
    TimelineEventCallback? onEventTap,
    TimelineEventCallback? onEventLongPress,
    TimelineContextCallback? onContextTap,
  }) {
    final context = _data.contexts.firstWhere(
      (ctx) => ctx.id == event.contextId,
      orElse: () => Context(
        id: 'default',
        ownerId: event.ownerId,
        type: ContextType.person,
        name: 'Default',
        moduleConfiguration: {},
        themeId: 'default',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );

    final theme = TimelineTheme(
      id: 'story',
      name: 'Story Theme',
      contextType: context.type,
      colorPalette: {
        'primary': _accentColor.value,
        'background': Colors.white.value,
        'text': Colors.black87.value,
        'card': Colors.grey[50]!.value,
      },
      iconSet: {'default': 'material'},
      typography: {
        'body': {'fontSize': 14.0, 'fontWeight': 'normal'},
        'header': {'fontSize': 16.0, 'fontWeight': 'bold'},
      },
      widgetFactories: {'card': true, 'list': true},
      enableGhostCamera: false,
      enableBudgetTracking: false,
      enableProgressComparison: false,
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: _templateManager.createEventCard(
        event: event,
        context: context,
        theme: theme,
        onTap: () => onEventTap?.call(event),
        onEdit: () => _handleEditEvent(event),
        onDelete: () => _handleDeleteEvent(event),
      ),
    );
  }

  Widget _buildStoryOutline(Story story) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            story.title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            story.description,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              itemCount: story.chapters.length,
              itemBuilder: (context, index) {
                final chapter = story.chapters[index];
                final isActive = index == _currentChapterIndex;
                
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: isActive ? _accentColor : Colors.grey[300],
                    child: Text(
                      '${index + 1}',
                      style: TextStyle(
                        color: isActive ? Colors.white : Colors.black,
                      ),
                    ),
                  ),
                  title: Text(
                    chapter.title,
                    style: TextStyle(
                      fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                      color: isActive ? _accentColor : null,
                    ),
                  ),
                  subtitle: Text('${chapter.events.length} events'),
                  onTap: () {
                    _currentChapterIndex = index;
                    _pageController.animateToPage(
                      index,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChapterNavigation(Story story) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Chapters',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: story.chapters.asMap().entries.map((entry) {
              final index = entry.key;
              final chapter = entry.value;
              final isActive = index == _currentChapterIndex;
              
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text(chapter.title.isEmpty ? 'Chapter ${index + 1}' : chapter.title),
                  selected: isActive,
                  onSelected: (selected) {
                    if (selected) {
                      _currentChapterIndex = index;
                      _pageController.animateToPage(
                        index,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    }
                  },
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildStoryControls(List<Story> stories) {
    return Positioned(
      top: 16,
      right: 16,
      child: Column(
        children: [
          _buildViewModeButton(),
          const SizedBox(height: 8),
          _buildLayoutButton(),
          const SizedBox(height: 8),
          _buildNarrativeButton(),
          const SizedBox(height: 8),
          _buildAutoPlayButton(),
        ],
      ),
    );
  }

  Widget _buildViewModeButton() {
    return FloatingActionButton(
      mini: true,
      onPressed: _toggleViewMode,
      child: Icon(_isStoryMode ? Icons.view_gallery : Icons.auto_stories),
    );
  }

  Widget _buildLayoutButton() {
    return FloatingActionButton(
      mini: true,
      onPressed: _cycleLayout,
      child: Icon(_getLayoutIcon()),
    );
  }

  Widget _buildNarrativeButton() {
    return FloatingActionButton(
      mini: true,
      onPressed: _toggleNarrative,
      backgroundColor: _showNarrative ? _accentColor : null,
      child: const Icon(Icons.text_fields),
    );
  }

  Widget _buildAutoPlayButton() {
    return FloatingActionButton(
      mini: true,
      onPressed: _toggleAutoPlay,
      backgroundColor: _autoPlay ? _accentColor : null,
      child: Icon(_autoPlay ? Icons.pause : Icons.play_arrow),
    );
  }

  Widget _buildStoryNavigation(List<Story> stories) {
    return Positioned(
      bottom: 16,
      left: 16,
      right: 16,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            IconButton(
              onPressed: _currentStoryIndex > 0 ? _previousStory : null,
              icon: const Icon(Icons.skip_previous),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    stories[_currentStoryIndex].title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  Text(
                    'Story ${_currentStoryIndex + 1} of ${stories.length}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: _currentStoryIndex < stories.length - 1 ? _nextStory : null,
              icon: const Icon(Icons.skip_next),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNarrativeOverlay(Story story) {
    if (_currentChapterIndex >= story.chapters.length) return const SizedBox.shrink();
    
    final chapter = story.chapters[_currentChapterIndex];
    if (chapter.narrative.isEmpty) return const SizedBox.shrink();

    return Positioned(
      bottom: 100,
      left: 16,
      right: 16,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.8),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          chapter.narrative,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            height: 1.4,
          ),
        ),
      ),
    );
  }

  Widget _buildStoryGallery(
    List<Story> stories, {
    TimelineEventCallback? onEventTap,
    TimelineEventCallback? onEventLongPress,
    TimelineContextCallback? onContextTap,
  }) {
    return GridView.builder(
      controller: _scrollController,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      padding: const EdgeInsets.all(16),
      itemCount: stories.length,
      itemBuilder: (context, index) {
        final story = stories[index];
        return _buildStoryCard(story, onEventTap, onEventLongPress, onContextTap);
      },
    );
  }

  Widget _buildStoryCard(
    Story story, {
    TimelineEventCallback? onEventTap,
    TimelineEventCallback? onEventLongPress,
    TimelineContextCallback? onContextTap,
  }) {
    return Card(
      elevation: 4,
      child: InkWell(
        onTap: () {
          _currentStoryIndex = stories.indexOf(story);
          _isStoryMode = true;
          // Trigger rebuild
        },
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.auto_stories,
                color: _accentColor,
                size: 32,
              ),
              const SizedBox(height: 8),
              Text(
                story.title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                story.description,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              const Spacer(),
              Text(
                '${story.chapters.length} chapters • ${story.chapters.fold(0, (sum, chapter) => sum + chapter.events.length)} events',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey[500],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _toggleViewMode() {
    setState(() {
      _isStoryMode = !_isStoryMode;
    });
  }

  void _cycleLayout() {
    setState(() {
      switch (_layout) {
        case StoryLayout.fullscreen:
          _layout = StoryLayout.split;
          break;
        case StoryLayout.split:
          _layout = StoryLayout.carousel;
          break;
        case StoryLayout.carousel:
          _layout = StoryLayout.fullscreen;
          break;
      }
    });
  }

  void _toggleNarrative() {
    setState(() {
      _showNarrative = !_showNarrative;
    });
  }

  void _toggleAutoPlay() {
    setState(() {
      _autoPlay = !_autoPlay;
      if (_autoPlay) {
        _startAutoPlay();
      } else {
        _stopAutoPlay();
      }
    });
  }

  IconData _getLayoutIcon() {
    switch (_layout) {
      case StoryLayout.fullscreen:
        return Icons.fullscreen;
      case StoryLayout.split:
        return Icons.view_column;
      case StoryLayout.carousel:
        return Icons.view_carousel;
    }
  }

  void _startAutoPlay() {
    _autoPlayTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (_currentChapterIndex < _stories[_currentStoryIndex].chapters.length - 1) {
        _currentChapterIndex++;
        _pageController.animateToPage(
          _currentChapterIndex,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      } else if (_currentStoryIndex < _stories.length - 1) {
        _nextStory();
      } else {
        _stopAutoPlay();
      }
    });
  }

  void _stopAutoPlay() {
    _autoPlayTimer?.cancel();
    _autoPlayTimer = null;
  }

  void _previousStory() {
    if (_currentStoryIndex > 0) {
      _currentStoryIndex--;
      _currentChapterIndex = 0;
      _pageController.jumpToPage(0);
    }
  }

  void _nextStory() {
    if (_currentStoryIndex < _stories.length - 1) {
      _currentStoryIndex++;
      _currentChapterIndex = 0;
      _pageController.jumpToPage(0);
    }
  }

  Future<void> _generateStories() async {
    _stories.clear();
    
    // Group events by themes and time periods to create stories
    final filteredEvents = filterEvents(data.events);
    
    // Create stories based on context types
    final contextGroups = <ContextType, List<TimelineEvent>>{};
    for (final event in filteredEvents) {
      final context = _data.contexts.firstWhere(
        (ctx) => ctx.id == event.contextId,
        orElse: () => Context(
          id: 'default',
          ownerId: event.ownerId,
          type: ContextType.person,
          name: 'Default',
          moduleConfiguration: {},
          themeId: 'default',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );
      
      contextGroups.putIfAbsent(context.type, () => []).add(event);
    }

    // Generate stories for each context type
    for (final entry in contextGroups.entries) {
      final story = await _createStoryFromEvents(entry.value, entry.key);
      if (story.chapters.isNotEmpty) {
        _stories.add(story);
      }
    }

    // Also create a chronological story
    if (filteredEvents.isNotEmpty) {
      final chronologicalStory = await _createChronologicalStory(filteredEvents);
      _stories.insert(0, chronologicalStory); // Add at beginning
    }
  }

  Future<Story> _createStoryFromEvents(List<TimelineEvent> events, ContextType contextType) async {
    final sortedEvents = events
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    final chapters = <Chapter>[];
    
    // Group events by time periods (months)
    final timeGroups = <String, List<TimelineEvent>>{};
    for (final event in sortedEvents) {
      final timeKey = '${event.timestamp.year}-${event.timestamp.month}';
      timeGroups.putIfAbsent(timeKey, () => []).add(event);
    }

    for (final entry in timeGroups.entries) {
      final date = DateTime.parse('${entry.key}-01');
      final chapter = Chapter(
        title: _formatMonthYear(date),
        narrative: _generateNarrativeForEvents(entry.value, contextType),
        events: entry.value,
      );
      chapters.add(chapter);
    }

    return Story(
      id: 'story_${contextType.name}',
      title: '${_getContextTypeName(contextType)} Journey',
      description: 'The story of your ${_getContextTypeName(contextType).toLowerCase()} experiences',
      chapters: chapters,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  Future<Story> _createChronologicalStory(List<TimelineEvent> events) async {
    final sortedEvents = events
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    final chapters = <Chapter>[];
    
    // Group events by years
    final yearGroups = <String, List<TimelineEvent>>{};
    for (final event in sortedEvents) {
      final yearKey = event.timestamp.year.toString();
      yearGroups.putIfAbsent(yearKey, () => []).add(event);
    }

    for (final entry in yearGroups.entries) {
      final year = int.parse(entry.key);
      final chapter = Chapter(
        title: 'The Year $year',
        narrative: _generateChronologicalNarrative(entry.value, year),
        events: entry.value,
      );
      chapters.add(chapter);
    }

    return Story(
      id: 'chronological_story',
      title: 'Life Timeline',
      description: 'Your complete life story in chronological order',
      chapters: chapters,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  String _generateNarrativeForEvents(List<TimelineEvent> events, ContextType contextType) {
    if (events.isEmpty) return '';

    final eventTypes = events.map((e) => e.eventType).toSet();
    final milestones = events.where((e) => e.eventType.contains('milestone')).length;
    final photos = events.where((e) => e.eventType == 'photo').length;
    
    String narrative = 'This period marked ';
    
    if (milestones > 0) {
      narrative += '$milestones significant milestone${milestones > 1 ? 's' : ''}';
    }
    
    if (photos > 0) {
      if (milestones > 0) narrative += ', ';
      narrative += '$photos captured moment${photos > 1 ? 's' : ''}';
    }
    
    narrative += ' in your ${_getContextTypeName(contextType).toLowerCase()} journey.';
    
    return narrative;
  }

  String _generateChronologicalNarrative(List<TimelineEvent> events, int year) {
    if (events.isEmpty) return 'No events recorded for $year.';

    final contexts = events.map((e) => e.contextId).toSet().length;
    final months = events.map((e) => e.timestamp.month).toSet().length;
    
    return 'The year $year was filled with experiences across $contexts different areas of your life, spanning $months month${months > 1 ? 's' : ''} of activity and ${events.length} memorable events.';
  }

  String _formatMonthYear(DateTime date) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '${months[date.month - 1]} ${date.year}';
  }

  String _getContextTypeName(ContextType type) {
    switch (type) {
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

  void _handleEditEvent(TimelineEvent event) {
    debugPrint('Edit event: ${event.id}');
  }

  void _handleDeleteEvent(TimelineEvent event) {
    debugPrint('Delete event: ${event.id}');
  }

  Stream<List<Story>> _getStoriesStream() {
    return Stream.value(_stories);
  }

  void setState(VoidCallback fn) {
    fn();
  }

  @override
  Future<void> updateData(TimelineRenderData data) async {
    await super.updateData(data);
    await _generateStories();
  }

  @override
  Future<void> navigateToDate(DateTime date) async {
    // Find the story and chapter containing this date
    for (final story in _stories) {
      for (int i = 0; i < story.chapters.length; i++) {
        final chapter = story.chapters[i];
        final hasDate = chapter.events.any((e) => 
            e.timestamp.isAfter(date.subtract(const Duration(days: 1))) &&
            e.timestamp.isBefore(date.add(const Duration(days: 1)))
        );
        
        if (hasDate) {
          _currentStoryIndex = _stories.indexOf(story);
          _currentChapterIndex = i;
          _pageController.jumpToPage(i);
          return;
        }
      }
    }

    await super.navigateToDate(date);
  }

  @override
  Future<Uint8List?> exportAsImage() async {
    // Implementation for story export
    return null;
  }

  @override
  void dispose() {
    _stopAutoPlay();
    _scrollController.dispose();
    _pageController.dispose();
    super.dispose();
  }
}

/// Story layout options
enum StoryLayout {
  fullscreen,
  split,
  carousel,
}
