import 'package:flutter/material.dart';

/// A wrapper for text inputs in the story editor to provide consistent
/// visual affordance, focus states, and meaningful hierarchy.
class StoryEditorField extends StatefulWidget {
  final Widget child;
  final String? label;
  final FocusNode? focusNode;
  final bool isFocused;

  const StoryEditorField({
    super.key,
    required this.child,
    this.label,
    this.focusNode,
    this.isFocused = false,
  });

  @override
  State<StoryEditorField> createState() => _StoryEditorFieldState();
}

class _StoryEditorFieldState extends State<StoryEditorField> {
  // If external focus node isn't provided/monitored, we might need internal tracking
  // But usually parent tracks focus to update isFocused.
  // For simplicity, we'll rely on the parent passing `isFocused` or just style it statically
  // if focus tracking is complex with Quill. 
  // Ideally, we wrap with Focus and listen.

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    // Visual states
    final borderColor = widget.isFocused 
        ? colorScheme.primary 
        : colorScheme.outline.withOpacity(0.3);
        
    final backgroundColor = widget.isFocused
        ? colorScheme.surface
        : colorScheme.surfaceVariant.withOpacity(0.3);
        
    final double elevation = widget.isFocused ? 2.0 : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.label != null)
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 4),
            child: Text(
              widget.label!,
              style: theme.textTheme.labelMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: borderColor,
              width: widget.isFocused ? 2.0 : 1.0,
            ),
            boxShadow: widget.isFocused 
                ? [
                    BoxShadow(
                      color: colorScheme.primary.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    )
                  ] 
                : [],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(11),
            child: widget.child,
          ),
        ),
      ],
    );
  }
}
