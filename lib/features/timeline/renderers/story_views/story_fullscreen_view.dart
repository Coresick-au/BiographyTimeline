import 'package:flutter/material.dart';
import '../../../../shared/models/story.dart';
import '../../../../shared/models/story_group.dart';
import '../../../../shared/models/timeline_event.dart';

class StoryFullscreenView extends StatelessWidget {
  final StoryGroup storyGroup;
  final PageController pageController;
  final ValueChanged<int> onPageChanged;
  final Widget Function(BuildContext, TimelineEvent) eventBuilder;

  const StoryFullscreenView({
    Key? key,
    required this.storyGroup,
    required this.pageController,
    required this.onPageChanged,
    required this.eventBuilder,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return PageView.builder(
      controller: pageController,
      onPageChanged: onPageChanged,
      itemCount: storyGroup.events.length,
      itemBuilder: (context, eventIndex) {
        final event = storyGroup.events[eventIndex];
        return eventBuilder(context, event);
      },
    );
  }
}
