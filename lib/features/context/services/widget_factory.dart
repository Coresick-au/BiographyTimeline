import 'package:flutter/material.dart';
import '../../../shared/models/context.dart';
import '../../../shared/models/timeline_theme.dart';
import '../widgets/context_widgets/milestone_card.dart';
import '../widgets/context_widgets/weight_card.dart';
import '../widgets/context_widgets/cost_card.dart';
import '../widgets/context_widgets/revenue_card.dart';
import '../widgets/context_widgets/team_card.dart';
import '../widgets/context_widgets/progress_comparison_widget.dart';

/// Factory for creating context-specific widgets
class WidgetFactory {
  /// Creates a widget based on the widget type and context
  static Widget? createWidget({
    required String widgetType,
    required ContextType contextType,
    required TimelineTheme theme,
    Map<String, dynamic>? data,
    VoidCallback? onTap,
  }) {
    // Check if the widget is enabled for this theme
    if (!theme.isWidgetEnabled(widgetType)) {
      return null;
    }

    switch (widgetType) {
      case 'milestoneCard':
        return MilestoneCard(
          contextType: contextType,
          theme: theme,
          data: data ?? {},
          onTap: onTap,
        );
      case 'weightCard':
        if (contextType == ContextType.pet) {
          return WeightCard(
            theme: theme,
            data: data ?? {},
            onTap: onTap,
          );
        }
        return null;
      case 'costCard':
        if (contextType == ContextType.project) {
          return CostCard(
            theme: theme,
            data: data ?? {},
            onTap: onTap,
          );
        }
        return null;
      case 'revenueCard':
        if (contextType == ContextType.business) {
          return RevenueCard(
            theme: theme,
            data: data ?? {},
            onTap: onTap,
          );
        }
        return null;
      case 'teamCard':
        if (contextType == ContextType.business) {
          return TeamCard(
            theme: theme,
            data: data ?? {},
            onTap: onTap,
          );
        }
        return null;
      case 'progressComparison':
        if (contextType == ContextType.pet || contextType == ContextType.project) {
          return ProgressComparisonWidget(
            contextType: contextType,
            theme: theme,
            data: data ?? {},
            onTap: onTap,
          );
        }
        return null;
      default:
        return null;
    }
  }

  /// Gets available widget types for a context
  static List<String> getAvailableWidgetTypes(ContextType contextType) {
    switch (contextType) {
      case ContextType.person:
        return ['milestoneCard', 'locationCard', 'photoGrid', 'storyCard'];
      case ContextType.pet:
        return ['milestoneCard', 'weightCard', 'vetCard', 'photoGrid', 'progressComparison'];
      case ContextType.project:
        return ['milestoneCard', 'costCard', 'progressCard', 'photoGrid', 'beforeAfterComparison'];
      case ContextType.business:
        return ['milestoneCard', 'revenueCard', 'teamCard', 'photoGrid', 'metricsDashboard'];
    }
  }

  /// Gets widget display name
  static String getWidgetDisplayName(String widgetType) {
    switch (widgetType) {
      case 'milestoneCard':
        return 'Milestone Card';
      case 'weightCard':
        return 'Weight Tracker';
      case 'costCard':
        return 'Cost Tracker';
      case 'revenueCard':
        return 'Revenue Tracker';
      case 'teamCard':
        return 'Team Overview';
      case 'progressComparison':
        return 'Progress Comparison';
      case 'locationCard':
        return 'Location Card';
      case 'photoGrid':
        return 'Photo Grid';
      case 'storyCard':
        return 'Story Card';
      case 'vetCard':
        return 'Vet Visit Card';
      case 'progressCard':
        return 'Progress Card';
      case 'beforeAfterComparison':
        return 'Before/After Comparison';
      case 'metricsDashboard':
        return 'Metrics Dashboard';
      default:
        return widgetType;
    }
  }

  /// Checks if a widget type is context-specific
  static bool isContextSpecific(String widgetType, ContextType contextType) {
    final availableTypes = getAvailableWidgetTypes(contextType);
    return availableTypes.contains(widgetType);
  }

  /// Creates a list of widgets for a context
  static List<Widget> createWidgetList({
    required List<String> widgetTypes,
    required ContextType contextType,
    required TimelineTheme theme,
    Map<String, Map<String, dynamic>>? widgetData,
    Map<String, VoidCallback>? onTapCallbacks,
  }) {
    final widgets = <Widget>[];

    for (final widgetType in widgetTypes) {
      final widget = createWidget(
        widgetType: widgetType,
        contextType: contextType,
        theme: theme,
        data: widgetData?[widgetType],
        onTap: onTapCallbacks?[widgetType],
      );

      if (widget != null) {
        widgets.add(widget);
      }
    }

    return widgets;
  }

  /// Creates a grid layout of widgets
  static Widget createWidgetGrid({
    required List<String> widgetTypes,
    required ContextType contextType,
    required TimelineTheme theme,
    Map<String, Map<String, dynamic>>? widgetData,
    Map<String, VoidCallback>? onTapCallbacks,
    int crossAxisCount = 2,
  }) {
    final widgets = createWidgetList(
      widgetTypes: widgetTypes,
      contextType: contextType,
      theme: theme,
      widgetData: widgetData,
      onTapCallbacks: onTapCallbacks,
    );

    if (widgets.isEmpty) {
      return const SizedBox.shrink();
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: 1.2,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: widgets.length,
      itemBuilder: (context, index) => widgets[index],
    );
  }

  /// Creates a horizontal scrollable list of widgets
  static Widget createWidgetCarousel({
    required List<String> widgetTypes,
    required ContextType contextType,
    required TimelineTheme theme,
    Map<String, Map<String, dynamic>>? widgetData,
    Map<String, VoidCallback>? onTapCallbacks,
    double height = 120,
  }) {
    final widgets = createWidgetList(
      widgetTypes: widgetTypes,
      contextType: contextType,
      theme: theme,
      widgetData: widgetData,
      onTapCallbacks: onTapCallbacks,
    );

    if (widgets.isEmpty) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      height: height,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: widgets.length,
        separatorBuilder: (context, index) => const SizedBox(width: 12),
        itemBuilder: (context, index) => SizedBox(
          width: 200,
          child: widgets[index],
        ),
      ),
    );
  }
}