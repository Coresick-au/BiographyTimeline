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
  List<StoryGroup> _storyGroups = [];
  int _currentStoryIndex = 0;
  int _currentBlockIndex = 0;
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
    await _generateStoryGroups();
  }

  @override
  Widget build({
    TimelineEventCallback? onEventTap,
    TimelineEventCallback? onEventLongPress,
    TimelineDateCallback? onDateTap,
    TimelineContextCallback? onContextTap,
    ScrollController? scrollController,
  }) {
    return StreamBuilder<List<StoryGroup>>(
      stream: _getStoryGroupsStream(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final storyGroups = snapshot.data!;
        if (storyGroups.isEmpty) {
          return _buildEmptyState();
        }

        return _buildStoryView(
          storyGroups,
          onEventTap: onEventTap,
          onEventLongPress: onEventLongPress,
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
    List<StoryGroup> storyGroups, {
    TimelineEventCallback? onEventTap,
    TimelineEventCallback? onEventLongPress,
    TimelineContextCallback? onContextTap,
  }) {
    if (_isStoryMode) {
      return _buildStoryReader(
        storyGroups,
        onEventTap: onEventTap,
        onEventLongPress: onEventLongPress,
        onContextTap: onContextTap,
      );
    } else {
      return _buildStoryGallery(
        storyGroups,
        onEventTap: onEventTap,
        onEventLongPress: onEventLongPress,
        onContextTap: onContextTap,
      );
    }
  }

  Widget _buildStoryReader(
    List<StoryGroup> storyGroups, {
    TimelineEventCallback? onEventTap,
    TimelineEventCallback? onEventLongPress,
    TimelineContextCallback? onContextTap,
  }) {
    if (_currentStoryIndex >= storyGroups.length) {
      _currentStoryIndex = 0;
    }

    final currentStoryGroup = storyGroups[_currentStoryIndex];
    
    return Scaffold(
      body: Stack(
        children: [
          _buildStoryContent(currentStoryGroup),
          _buildStoryControls(storyGroups),
          _buildStoryNavigation(storyGroups),
          if (_showNarrative) _buildNarrativeOverlay(currentStoryGroup),
        ],
      ),
    );
  }

  Widget _buildStoryContent(
    StoryGroup storyGroup, {
    TimelineEventCallback? onEventTap,
    TimelineEventCallback? onEventLongPress,
    TimelineContextCallback? onContextTap,
  }) {
    switch (_layout) {
      case StoryLayout.fullscreen:
        return _buildFullscreenStory(storyGroup);
      case StoryLayout.split:
        return _buildSplitStory(storyGroup);
      case StoryLayout.carousel:
        return _buildCarouselStory(storyGroup);
    }
  }

  Widget _buildFullscreenStory(
    StoryGroup storyGroup, {
    TimelineEventCallback? onEventTap,
    TimelineEventCallback? onEventLongPress,
    TimelineContextCallback? onContextTap,
  }) {
    return PageView.builder(
      controller: _pageController,
      onPageChanged: (index) {
        _currentBlockIndex = index;
      },
      itemCount: storyGroup.events.length,
      itemBuilder: (context, eventIndex) {
        final event = storyGroup.events[eventIndex];
        return _buildEventStoryView(event, storyGroup);
      },
    );
  }

  Widget _buildSplitStory(
    StoryGroup storyGroup, {
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
            child: _buildStoryOutline(storyGroup),
          ),
        ),
        Expanded(
          flex: 2,
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              _currentBlockIndex = index;
            },
            itemCount: storyGroup.events.length,
            itemBuilder: (context, eventIndex) {
              final event = storyGroup.events[eventIndex];
              return _buildEventStoryView(event, storyGroup);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCarouselStory(
    StoryGroup storyGroup, {
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
              _currentBlockIndex = index;
            },
            itemCount: storyGroup.events.length,
            itemBuilder: (context, eventIndex) {
              final event = storyGroup.events[eventIndex];
              return _buildEventStoryView(event, storyGroup);
            },
          ),
        ),
        Expanded(
          flex: 1,
          child: Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey[50],
            child: _buildEventNavigation(storyGroup),
          ),
        ),
      ],
    );
  }

  Widget _buildEventStoryView(
    TimelineEvent event,
    StoryGroup storyGroup, {
    TimelineEventCallback? onEventTap,
    TimelineEventCallback? onEventLongPress,
    TimelineContextCallback? onContextTap,
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (storyGroup.title.isNotEmpty) ...[
            Text(
              storyGroup.title,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
          ],
          if (storyGroup.description.isNotEmpty && _showNarrative) ...[
            Text(
              storyGroup.description,
              style: _narrativeStyle,
            ),
            const SizedBox(height: 24),
          ],
          Expanded(
            child: _buildStoryEventCard(event),
          ),
        ],
      ),
    );
  }

  Widget _buildStoryEventCard(
    TimelineEvent event, {
    TimelineEventCallback? onEventTap,
    TimelineEventCallback? onEventLongPress,
    TimelineContextCallback? onContextTap,
  }) {
    final context = data.contexts.firstWhere(
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

  Widget _buildStoryOutline(StoryGroup storyGroup) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            storyGroup.title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            storyGroup.description,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              itemCount: storyGroup.events.length,
              itemBuilder: (context, index) {
                final event = storyGroup.events[index];
                final isActive = index == _currentBlockIndex;
                
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
                    event.title ?? 'Untitled Event',
                    style: TextStyle(
                      fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                      color: isActive ? _accentColor : null,
                    ),
                  ),
                  subtitle: Text(_formatDate(event.timestamp)),
                  onTap: () {
                    _currentBlockIndex = index;
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

  Widget _buildEventNavigation(StoryGroup storyGroup) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Events',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: storyGroup.events.asMap().entries.map((entry) {
              final index = entry.key;
              final event = entry.value;
              final isActive = index == _currentBlockIndex;
              
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text(event.title ?? 'Event ${index + 1}'),
                  selected: isActive,
                  onSelected: (selected) {
                    if (selected) {
                      _currentBlockIndex = index;
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

  Widget _buildStoryControls(List<StoryGroup> storyGroups) {
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
      child: Icon(_isStoryMode ? Icons.grid_view : Icons.auto_stories),
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

  Widget _buildStoryNavigation(List<StoryGroup> storyGroups) {
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
                    storyGroups[_currentStoryIndex].title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  Text(
                    'Story ${_currentStoryIndex + 1} of ${storyGroups.length}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: _currentStoryIndex < storyGroups.length - 1 ? _nextStory : null,
              icon: const Icon(Icons.skip_next),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNarrativeOverlay(StoryGroup storyGroup) {
    if (_currentBlockIndex >= storyGroup.events.length) return const SizedBox.shrink();
    
    final event = storyGroup.events[_currentBlockIndex];
    
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
          event.description ?? 'A moment in your story',
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
    List<StoryGroup> storyGroups, {
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
      itemCount: storyGroups.length,
      itemBuilder: (context, index) {
        final storyGroup = storyGroups[index];
        return _buildStoryGroupCard(storyGroup);
      },
    );
  }

  Widget _buildStoryGroupCard(
    StoryGroup storyGroup, {
    TimelineEventCallback? onEventTap,
    TimelineEventCallback? onEventLongPress,
    TimelineContextCallback? onContextTap,
  }) {
    return Card(
      elevation: 4,
      child: InkWell(
        onTap: () {
          _currentStoryIndex = _storyGroups.indexOf(storyGroup);
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
                storyGroup.title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                storyGroup.description,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              const Spacer(),
              Text(
                '${storyGroup.events.length} events',
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
      if (_currentBlockIndex < _storyGroups[_currentStoryIndex].events.length - 1) {
        _currentBlockIndex++;
        _pageController.animateToPage(
          _currentBlockIndex,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      } else if (_currentStoryIndex < _storyGroups.length - 1) {
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
      _currentBlockIndex = 0;
      _pageController.jumpToPage(0);
    }
  }

  void _nextStory() {
    if (_currentStoryIndex < _storyGroups.length - 1) {
      _currentStoryIndex++;
      _currentBlockIndex = 0;
      _pageController.jumpToPage(0);
    }
  }

  Future<void> _generateStoryGroups() async {
    _storyGroups.clear();
    
    // Group events by themes and time periods to create story groups
    final filteredEvents = filterEvents(data.events);
    
    // Create story groups based on context types
    final contextGroups = <ContextType, List<TimelineEvent>>{};
    for (final event in filteredEvents) {
      final context = data.contexts.firstWhere(
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

    // Generate story groups for each context type
    for (final entry in contextGroups.entries) {
      final storyGroup = await _createStoryGroupFromEvents(entry.value, entry.key);
      if (storyGroup.events.isNotEmpty) {
        _storyGroups.add(storyGroup);
      }
    }

    // Also create a chronological story group
    if (filteredEvents.isNotEmpty) {
      final chronologicalStoryGroup = await _createChronologicalStoryGroup(filteredEvents);
      _storyGroups.insert(0, chronologicalStoryGroup); // Add at beginning
    }
  }

  Future<StoryGroup> _createStoryGroupFromEvents(List<TimelineEvent> events, ContextType contextType) async {
    final sortedEvents = events
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    return StoryGroup(
      id: 'story_${contextType.name}',
      title: '${_getContextTypeName(contextType)} Journey',
      description: 'The story of your ${_getContextTypeName(contextType).toLowerCase()} experiences',
      events: sortedEvents,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  Future<StoryGroup> _createChronologicalStoryGroup(List<TimelineEvent> events) async {
    final sortedEvents = events
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    return StoryGroup(
      id: 'chronological_story',
      title: 'Life Timeline',
      description: 'Your complete life story in chronological order',
      events: sortedEvents,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
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
      return '${difference.inDays}d ago';
    } else if (difference.inDays < 30) {
      return '${(difference.inDays / 7).floor()}w ago';
    } else {
      return '${date.day}/${date.month}';
    }
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

  Stream<List<StoryGroup>> _getStoryGroupsStream() {
    return Stream.value(_storyGroups);
  }

  void setState(VoidCallback fn) {
    fn();
  }

  @override
  Future<void> updateData(TimelineRenderData data) async {
    await super.updateData(data);
    await _generateStoryGroups();
  }

  @override
  Future<void> navigateToDate(DateTime date) async {
    // Find the story group and event containing this date
    for (final storyGroup in _storyGroups) {
      for (int i = 0; i < storyGroup.events.length; i++) {
        final event = storyGroup.events[i];
        final hasDate = event.timestamp.isAfter(date.subtract(const Duration(days: 1))) &&
                       event.timestamp.isBefore(date.add(const Duration(days: 1)));
        
        if (hasDate) {
          _currentStoryIndex = _storyGroups.indexOf(storyGroup);
          _currentBlockIndex = i;
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

/// Story group for organizing events into narratives
class StoryGroup {
  final String id;
  final String title;
  final String description;
  final List<TimelineEvent> events;
  final DateTime createdAt;
  final DateTime updatedAt;

  const StoryGroup({
    required this.id,
    required this.title,
    required this.description,
    required this.events,
    required this.createdAt,
    required this.updatedAt,
  });
}
