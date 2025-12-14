import 'package:flutter/material.dart';
import '../../../../shared/models/story.dart';
import '../../../../shared/models/story_group.dart';
import '../../../../shared/models/timeline_event.dart';

class StorySplitView extends StatelessWidget {
  final StoryGroup storyGroup;
  final PageController pageController;
  final ValueChanged<int> onPageChanged;
  final Widget Function(BuildContext, TimelineEvent) eventBuilder;
  final WidgetBuilder outlineBuilder;

  const StorySplitView({
    Key? key,
    required this.storyGroup,
    required this.pageController,
    required this.onPageChanged,
    required this.eventBuilder,
    required this.outlineBuilder,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          flex: 1,
          child: Container(
            color: Colors.grey[100],
            child: outlineBuilder(context),
          ),
        ),
        Expanded(
          flex: 2,
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
      ],
    );
  }
}
