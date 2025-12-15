import 'package:flutter/material.dart';
import '../../design_system/design_system.dart';

/// A standardized tag/chip widget.
/// 
/// Used for categories, labels, or status indicators.
class AppTag extends StatelessWidget {
  final String label;
  final IconData? icon;
  final Color? color;
  final VoidCallback? onTap;
  final bool isSelected;
  final VoidCallback? onDeleted;

  const AppTag({
    super.key,
    required this.label,
    this.icon,
    this.color,
    this.onTap,
    this.isSelected = false,
    this.onDeleted,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    // Determine effective color
    final baseColor = color ?? theme.colorScheme.primary;
    
    // Standard chip feels heavy, implementing a custom lighter version or using ChipTheme
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadii.circular),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.xs + 2,
          ),
          decoration: BoxDecoration(
            color: isSelected 
                ? baseColor 
                : baseColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(AppRadii.circular),
            border: Border.all(
              color: isSelected ? baseColor : baseColor.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: 16,
                  color: isSelected ? theme.colorScheme.onPrimary : baseColor,
                ),
                const SizedBox(width: AppSpacing.xs),
              ],
              Text(
                label,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: isSelected ? theme.colorScheme.onPrimary : baseColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (onDeleted != null) ...[
                const SizedBox(width: AppSpacing.xs),
                InkWell(
                  onTap: onDeleted,
                  child: Icon(
                    Icons.close,
                    size: 16,
                    color: isSelected ? theme.colorScheme.onPrimary : baseColor,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
