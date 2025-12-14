import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../presentation/providers/story_editor_provider.dart';
import '../presentation/widgets/story_editor.dart';
import '../../../shared/models/story.dart';
import '../../../shared/models/timeline_event.dart';
import '../../../shared/models/user.dart';

/// Screen for editing stories, accessible from timeline events
class StoryEditorScreen extends ConsumerWidget {
  final String? eventId;
  final String contextId;

  const StoryEditorScreen({
    super.key,
    this.eventId,
    required this.contextId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // If no eventId, create a standalone story
    if (eventId == null) {
      return StoryEditor(
        story: _createMockStory(),
        availableMedia: [],
        onSave: () {
          Navigator.of(context).pop();
        },
      );
    }
    
    // Watch for existing stories for this event
    final storiesAsync = ref.watch(storiesForEventProvider(eventId!));
    
    return storiesAsync.when(
      loading: () => const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      ),
      error: (error, stack) => Scaffold(
        body: Center(
          child: Text('Error loading story: $error'),
        ),
      ),
      data: (stories) {
        // Use existing story or create new one
        final existingStory = stories.isNotEmpty ? stories.first : null;
        
        return StoryEditor(
          story: existingStory ?? _createMockStory(),
          availableMedia: [],
          onSave: () {
            Navigator.of(context).pop();
          },
        );
      },
    );
  }

  // Create a mock story for the story editor
  Story _createMockStory() {
    return Story.empty(
      id: 'mock_story_id',
      eventId: eventId ?? 'standalone',
      authorId: 'current_user',
    );
  }
}

/// Provider for stories of a specific event
final storiesForEventProvider = FutureProvider.family<List<Story>, String>((ref, eventId) async {
  final repository = ref.read(storyRepositoryProvider);
  // Initialize the repository if needed
  try {
    return await repository.getStoriesForEvent(eventId);
  } catch (e) {
    // Handle initialization error
    return [];
  }
});
