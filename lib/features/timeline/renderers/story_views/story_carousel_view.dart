import 'package:flutter/material.dart';
import '../../../../shared/models/story.dart';
import '../../../../shared/models/story_group.dart';
import '../../../../shared/models/timeline_event.dart';

class StoryCarouselView extends StatelessWidget {
  final StoryGroup storyGroup;
  final PageController pageController;
  final ValueChanged<int> onPageChanged;
  final Widget Function(BuildContext, TimelineEvent) eventBuilder;
  final WidgetBuilder navigationBuilder;

  const StoryCarouselView({
    Key? key,
    required this.storyGroup,
    required this.pageController,
    required this.onPageChanged,
    required this.eventBuilder,
    required this.navigationBuilder,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          flex: 3,
          child: PageView.builder(
            controller: pageController,
            onPageChanged: onPageChanged,
            itemCount: storyGroup.events.length,
            itemBuilder: (context, eventIndex) {
              final event = storyGroup.events[eventIndex];
              return eventBuilder(context, event);
            },
          ),
        ),
        Expanded(
          flex: 1,
          child: Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey[50],
            child: navigationBuilder(context),
          ),
        ),
      ],
    );
  }
}
