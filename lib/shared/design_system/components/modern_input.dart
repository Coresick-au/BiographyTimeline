import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../design_tokens.dart';

/// A modern text input component with floating labels and validation
/// 
/// This input follows the design system tokens and provides:
/// - Floating label animation
/// - Clear focus states
/// - Validation feedback with contextual messages
/// - Consistent styling across themes
/// - Accessibility support
class ModernTextInput extends StatefulWidget {
  /// The label text for the input
  final String label;
  
  /// Placeholder text when input is empty
  final String? placeholder;
  
  /// Current value of the input
  final String? value;
  
  /// Callback when the value changes
  final ValueChanged<String>? onChanged;
  
  /// Callback when editing is complete
  final VoidCallback? onEditingComplete;
  
  /// Callback when the input is submitted
  final ValueChanged<String>? onSubmitted;
  
  /// Whether the input is required
  final bool isRequired;
  
  /// Whether the input is enabled
  final bool enabled;
  
  /// Whether the input is obscured (for passwords)
  final bool obscureText;
  
  /// The keyboard type
  final TextInputType keyboardType;
  
  /// Input formatters
  final List<TextInputFormatter>? inputFormatters;
  
  /// Maximum number of lines
  final int? maxLines;
  
  /// Maximum length of input
  final int? maxLength;
  
  /// Validation error message
  final String? errorText;
  
  /// Helper text to display below the input
  final String? helperText;
  
  /// Prefix icon
  final IconData? prefixIcon;
  
  /// Suffix icon
  final IconData? suffixIcon;
  
  /// Callback when suffix icon is pressed
  final VoidCallback? onSuffixIconPressed;
  
  /// Custom controller (optional)
  final TextEditingController? controller;
  
  /// Focus node (optional)
  final FocusNode? focusNode;

  const ModernTextInput({
    super.key,
    required this.label,
    this.placeholder,
    this.value,
    this.onChanged,
    this.onEditingComplete,
    this.onSubmitted,
    this.isRequired = false,
    this.enabled = true,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.inputFormatters,
    this.maxLines = 1,
    this.maxLength,
    this.errorText,
    this.helperText,
    this.prefixIcon,
    this.suffixIcon,
    this.onSuffixIconPressed,
    this.controller,
    this.focusNode,
  });

  @override
  State<ModernTextInput> createState() => _ModernTextInputState();
}

class _ModernTextInputState extends State<ModernTextInput>
    with SingleTickerProviderStateMixin {
  late TextEditingController _controller;
  late FocusNode _focusNode;
  late AnimationController _animationController;
  late Animation<double> _labelAnimation;
  late Animation<Color?> _borderColorAnimation;
  
  bool _isFocused = false;
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    
    _controller = widget.controller ?? TextEditingController(text: widget.value);
    _focusNode = widget.focusNode ?? FocusNode();
    
    _animationController = AnimationController(
      duration: DesignTokens.durationFast,
      vsync: this,
    );
    
    _labelAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: DesignTokens.curveStandard,
    ));
    
    _borderColorAnimation = ColorTween(
      begin: Theme.of(context).colorScheme.outline,
      end: Theme.of(context).colorScheme.primary,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: DesignTokens.curveStandard,
    ));
    
    _focusNode.addListener(_handleFocusChange);
    _controller.addListener(_handleTextChange);
    
    _hasText = _controller.text.isNotEmpty;
    if (_hasText) {
      _animationController.value = 1.0;
    }
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _controller.dispose();
    }
    if (widget.focusNode == null) {
      _focusNode.dispose();
    }
    _animationController.dispose();
    super.dispose();
  }

  void _handleFocusChange() {
    setState(() {
      _isFocused = _focusNode.hasFocus;
    });
    
    if (_isFocused || _hasText) {
      _animationController.forward();
    } else {
      _animationController.reverse();
    }
  }

  void _handleTextChange() {
    final hasText = _controller.text.isNotEmpty;
    if (hasText != _hasText) {
      setState(() {
        _hasText = hasText;
      });
      
      if (_hasText || _isFocused) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    }
    
    widget.onChanged?.call(_controller.text);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    // Determine colors based on state
    Color borderColor = colorScheme.outline;
    Color labelColor = colorScheme.onSurfaceVariant;
    
    if (widget.errorText != null) {
      borderColor = colorScheme.error;
      labelColor = colorScheme.error;
    } else if (_isFocused) {
      borderColor = colorScheme.primary;
      labelColor = colorScheme.primary;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(DesignTokens.radiusSmall),
            border: Border.all(
              color: borderColor,
              width: _isFocused ? 2.0 : 1.0,
            ),
          ),
          child: Stack(
            children: [
              // Main text field
              Padding(
                padding: EdgeInsets.only(
                  top: DesignTokens.space6,
                  bottom: DesignTokens.space3,
                  left: widget.prefixIcon != null ? DesignTokens.space12 : DesignTokens.space4,
                  right: widget.suffixIcon != null ? DesignTokens.space12 : DesignTokens.space4,
                ),
                child: TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  enabled: widget.enabled,
                  obscureText: widget.obscureText,
                  keyboardType: widget.keyboardType,
                  inputFormatters: widget.inputFormatters,
                  maxLines: widget.maxLines,
                  maxLength: widget.maxLength,
                  onEditingComplete: widget.onEditingComplete,
                  onSubmitted: widget.onSubmitted,
                  style: DesignTokens.bodyLarge.copyWith(
                    color: widget.enabled ? colorScheme.onSurface : colorScheme.onSurface.withOpacity(0.6),
                  ),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: _isFocused || _hasText ? widget.placeholder : null,
                    hintStyle: DesignTokens.bodyLarge.copyWith(
                      color: colorScheme.onSurfaceVariant.withOpacity(0.6),
                    ),
                    counterText: '', // Hide default counter
                  ),
                ),
              ),
              
              // Floating label
              Positioned(
                left: widget.prefixIcon != null ? DesignTokens.space12 : DesignTokens.space4,
                top: DesignTokens.space4,
                child: AnimatedBuilder(
                  animation: _labelAnimation,
                  builder: (context, child) {
                    final progress = _labelAnimation.value;
                    final scale = 0.75 + (0.25 * (1 - progress));
                    final offsetY = progress * -8;
                    
                    return Transform.translate(
                      offset: Offset(0, offsetY),
                      child: Transform.scale(
                        scale: scale,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          widget.label + (widget.isRequired ? ' *' : ''),
                          style: DesignTokens.bodyLarge.copyWith(
                            color: labelColor,
                            fontWeight: progress > 0.5 ? FontWeight.w500 : FontWeight.w400,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              
              // Prefix icon
              if (widget.prefixIcon != null)
                Positioned(
                  left: DesignTokens.space3,
                  top: 0,
                  bottom: 0,
                  child: Icon(
                    widget.prefixIcon,
                    color: _isFocused ? colorScheme.primary : colorScheme.onSurfaceVariant,
                    size: 20,
                  ),
                ),
              
              // Suffix icon
              if (widget.suffixIcon != null)
                Positioned(
                  right: DesignTokens.space3,
                  top: 0,
                  bottom: 0,
                  child: IconButton(
                    icon: Icon(
                      widget.suffixIcon,
                      color: _isFocused ? colorScheme.primary : colorScheme.onSurfaceVariant,
                      size: 20,
                    ),
                    onPressed: widget.onSuffixIconPressed,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 24,
                      minHeight: 24,
                    ),
                  ),
                ),
            ],
          ),
        ),
        
        // Helper/Error text
        if (widget.errorText != null || widget.helperText != null) ...[
          SizedBox(height: DesignTokens.space1),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: DesignTokens.space4),
            child: Text(
              widget.errorText ?? widget.helperText!,
              style: DesignTokens.bodySmall.copyWith(
                color: widget.errorText != null ? colorScheme.error : colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
        
        // Character counter
        if (widget.maxLength != null) ...[
          SizedBox(height: DesignTokens.space1),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: DesignTokens.space4),
            child: Align(
              alignment: Alignment.centerRight,
              child: Text(
                '${_controller.text.length}/${widget.maxLength}',
                style: DesignTokens.bodySmall.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// A modern dropdown/select input component
class ModernDropdown<T> extends StatelessWidget {
  final String label;
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?>? onChanged;
  final bool isRequired;
  final bool enabled;
  final String? errorText;
  final String? helperText;
  final IconData? prefixIcon;

  const ModernDropdown({
    super.key,
    required this.label,
    this.value,
    required this.items,
    this.onChanged,
    this.isRequired = false,
    this.enabled = true,
    this.errorText,
    this.helperText,
    this.prefixIcon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    Color borderColor = colorScheme.outline;
    Color labelColor = colorScheme.onSurfaceVariant;
    
    if (errorText != null) {
      borderColor = colorScheme.error;
      labelColor = colorScheme.error;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(DesignTokens.radiusSmall),
            border: Border.all(color: borderColor),
          ),
          child: Stack(
            children: [
              Padding(
                padding: EdgeInsets.only(
                  top: DesignTokens.space6,
                  bottom: DesignTokens.space3,
                  left: prefixIcon != null ? DesignTokens.space12 : DesignTokens.space4,
                  right: DesignTokens.space4,
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<T>(
                    value: value,
                    items: items,
                    onChanged: enabled ? onChanged : null,
                    isExpanded: true,
                    style: DesignTokens.bodyLarge.copyWith(
                      color: enabled ? colorScheme.onSurface : colorScheme.onSurface.withOpacity(0.6),
                    ),
                    dropdownColor: colorScheme.surface,
                    icon: Icon(
                      Icons.keyboard_arrow_down,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
              
              // Label
              Positioned(
                left: prefixIcon != null ? DesignTokens.space12 : DesignTokens.space4,
                top: DesignTokens.space1,
                child: Text(
                  label + (isRequired ? ' *' : ''),
                  style: DesignTokens.bodySmall.copyWith(
                    color: labelColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              
              // Prefix icon
              if (prefixIcon != null)
                Positioned(
                  left: DesignTokens.space3,
                  top: 0,
                  bottom: 0,
                  child: Icon(
                    prefixIcon,
                    color: colorScheme.onSurfaceVariant,
                    size: 20,
                  ),
                ),
            ],
          ),
        ),
        
        // Helper/Error text
        if (errorText != null || helperText != null) ...[
          SizedBox(height: DesignTokens.space1),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: DesignTokens.space4),
            child: Text(
              errorText ?? helperText!,
              style: DesignTokens.bodySmall.copyWith(
                color: errorText != null ? colorScheme.error : colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// A modern checkbox component
class ModernCheckbox extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool>? onChanged;
  final bool enabled;
  final String? description;

  const ModernCheckbox({
    super.key,
    required this.label,
    required this.value,
    this.onChanged,
    this.enabled = true,
    this.description,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return InkWell(
      onTap: enabled ? () => onChanged?.call(!value) : null,
      borderRadius: BorderRadius.circular(DesignTokens.radiusSmall),
      child: Padding(
        padding: EdgeInsets.all(DesignTokens.space2),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Checkbox(
              value: value,
              onChanged: enabled ? (newValue) => onChanged?.call(newValue ?? false) : null,
              activeColor: colorScheme.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(DesignTokens.radiusXSmall),
              ),
            ),
            SizedBox(width: DesignTokens.space2),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: DesignTokens.bodyMedium.copyWith(
                      color: enabled ? colorScheme.onSurface : colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                  if (description != null) ...[
                    SizedBox(height: DesignTokens.space1),
                    Text(
                      description!,
                      style: DesignTokens.bodySmall.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}