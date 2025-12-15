import 'package:flutter/material.dart';
import '../../design_system/design_system.dart';

/// A standardized avatar widget for users.
/// 
/// Displays an image if available, otherwise shows initials on a colorful background.
class AppAvatar extends StatelessWidget {
  final String? imageUrl;
  final String? name;
  final double radius;
  final VoidCallback? onTap;

  const AppAvatar({
    super.key,
    this.imageUrl,
    this.name,
    this.radius = 20.0, // Total diameter = 40.0
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final initials = _getInitials(name);
    
    // Calculate color based on name hash for consistency
    final backgroundColor = name != null 
        ? _generateColorForName(name!, theme) 
        : theme.colorScheme.primaryContainer;
        
    final foregroundColor = name != null
        ? _getContrastColor(backgroundColor)
        : theme.colorScheme.onPrimaryContainer;

    Widget avatar = CircleAvatar(
      radius: radius,
      backgroundColor: backgroundColor,
      backgroundImage: imageUrl != null ? NetworkImage(imageUrl!) : null,
      child: imageUrl == null
          ? Text(
              initials,
              style: theme.textTheme.labelLarge?.copyWith(
                color: foregroundColor,
                fontSize: radius * 0.8,
                fontWeight: FontWeight.bold,
              ),
            )
          : null,
    );

    if (onTap != null) {
      avatar = InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: avatar,
      );
    }

    return avatar;
  }

  String _getInitials(String? name) {
    if (name == null || name.isEmpty) return '?';
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name[0].toUpperCase();
  }

  Color _generateColorForName(String name, ThemeData theme) {
    // Determine hash code
    final hash = name.hashCode;
    
    // Use hash to pick from a set of semantic colors if desired, 
    // or just generate a color. For better visual consistency, 
    // we'll rotate through the theme's tertiary/secondary colors or use a consistent logic.
    switch (hash % 4) {
      case 0: return theme.colorScheme.primary;
      case 1: return theme.colorScheme.secondary;
      case 2: return theme.colorScheme.tertiary;
      case 3: return theme.colorScheme.error; // Maybe stick to positive colors?
      default: return theme.colorScheme.primary;
    }
  }
  
  Color _getContrastColor(Color background) {
    // Simple check for now, can be improved
    return background.computeLuminance() > 0.5 ? Colors.black : Colors.white;
  }
}
