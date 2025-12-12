import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/models/story.dart';
import '../../../../shared/models/timeline_event.dart';
import '../../../../shared/models/media_asset.dart';
import '../widgets/story_editor.dart';
import '../widgets/story_viewer.dart';
import '../widgets/version_history_dialog.dart';
import '../providers/story_editor_provider.dart';

/// Main page for story creation and viewing
class StoryPage extends ConsumerStatefulWidget {
  final TimelineEvent event;
  final Story? existingStory;
  final bool isViewMode;

  const StoryPage({
    super.key,
    required this.event,
    this.existingStory,
    this.isViewMode = false,
  });

  @override
  ConsumerState<StoryPage> createState() => _StoryPageState();
}

class _StoryPageState extends ConsumerState<StoryPage> {
  late Story _currentStory;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _currentStory = widget.existingStory ?? _createNewStory();
    _isEditing = !widget.isViewMode && widget.existingStory == null;
  }

  Story _createNewStory() {
    return Story.empty(
      id: 'story_${widget.event.id}',
      eventId: widget.event.id,
      authorId: widget.event.ownerId,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isEditing) {
      return StoryEditor(
        story: _currentStory,
        availableMedia: widget.event.assets,
        onSave: () {
          setState(() {
            _isEditing = false;
          });
        },
        onStoryChanged: (updatedStory) {
          setState(() {
            _currentStory = updatedStory;
          });
        },
      );
    } else {
      return StoryViewer(
        story: _currentStory,
        onEdit: widget.isViewMode ? null : () {
          setState(() {
            _isEditing = true;
          });
        },
      );
    }
  }
}

/// Floating action button for creating stories from timeline events
class CreateStoryFAB extends StatelessWidget {
  final TimelineEvent event;

  const CreateStoryFAB({
    super.key,
    required this.event,
  });

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.extended(
      onPressed: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => StoryPage(event: event),
          ),
        );
      },
      icon: const Icon(Icons.auto_stories),
      label: const Text('Create Story'),
    );
  }
}

/// Widget for displaying story options in timeline events
class StoryOptionsWidget extends ConsumerWidget {
  final TimelineEvent event;

  const StoryOptionsWidget({
    super.key,
    required this.event,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Story Options',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            
            // Create new story
            ListTile(
              leading: const Icon(Icons.add_circle_outline),
              title: const Text('Create New Story'),
              subtitle: const Text('Write a rich narrative for this event'),
              onTap: () => _createNewStory(context),
            ),
            
            // View existing stories
            if (event.story != null) ...[
              ListTile(
                leading: const Icon(Icons.auto_stories),
                title: const Text('View Story'),
                subtitle: Text('${event.story!.wordCount} words'),
                onTap: () => _viewStory(context),
              ),
              
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text('Edit Story'),
                onTap: () => _editStory(context),
              ),
              
              ListTile(
                leading: const Icon(Icons.history),
                title: const Text('Version History'),
                onTap: () => _showVersionHistory(context),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _createNewStory(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => StoryPage(event: event),
      ),
    );
  }

  void _viewStory(BuildContext context) {
    if (event.story != null) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => StoryPage(
            event: event,
            existingStory: event.story,
            isViewMode: true,
          ),
        ),
      );
    }
  }

  void _editStory(BuildContext context) {
    if (event.story != null) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => StoryPage(
            event: event,
            existingStory: event.story,
            isViewMode: false,
          ),
        ),
      );
    }
  }

  void _showVersionHistory(BuildContext context) {
    if (event.story != null) {
      showDialog(
        context: context,
        builder: (context) => VersionHistoryDialog(
          storyId: event.story!.id,
          onVersionRestore: (version) {
            // Handle version restoration
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Restored to version $version'),
              ),
            );
          },
        ),
      );
    }
  }
}