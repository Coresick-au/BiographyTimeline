import 'timeline_event.dart';
import 'context.dart';

class StoryGroup {
  final String id;
  final String title;
  final String description;
  final List<TimelineEvent> events;
  final ContextType? contextType;

  StoryGroup({
    required this.id,
    required this.title,
    required this.description,
    required this.events,
    this.contextType,
  });
}
