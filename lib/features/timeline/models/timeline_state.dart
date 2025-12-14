import 'package:freezed_annotation/freezed_annotation.dart';
import '../../../shared/models/timeline_event.dart';
import '../../../shared/models/context.dart';

part 'timeline_state.freezed.dart';

@freezed
class TimelineState with _$TimelineState {
  const factory TimelineState({
    @Default([]) List<TimelineEvent> allEvents,
    @Default([]) List<TimelineEvent> filteredEvents,
    @Default([]) List<Context> contexts,
    @Default({}) Map<String, List<TimelineEvent>> clusteredEvents,
    @Default(true) bool showPrivateEvents,
    String? activeContextId,
    DateTime? startDate,
    DateTime? endDate,
    @Default('all') String eventFilter,
    String? currentViewerId,
    String? timelineOwnerId,
    @Default(false) bool isLoading,
    String? error,
  }) = _TimelineState;
}
