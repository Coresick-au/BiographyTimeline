import 'package:freezed_annotation/freezed_annotation.dart';
import '../services/timeline_renderer_interface.dart';

part 'view_state.freezed.dart';

/// Represents the state of a timeline view that should be preserved
/// when switching between different view modes.
@freezed
class ViewState with _$ViewState {
  const factory ViewState({
    required TimelineViewMode viewMode,
    @Default(0.0) double scrollOffset,
    @Default(1.0) double zoomLevel,
    String? focusedEventId,
    @Default({}) Map<String, dynamic> customState,
  }) = _ViewState;
}
