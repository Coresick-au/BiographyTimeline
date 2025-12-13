import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/granular_privacy_models.dart';
import '../services/granular_privacy_service.dart';

/// Widget for displaying and controlling privacy settings inline
class PrivacyControlWidget extends ConsumerWidget {
  final String eventId;
  final String? timelineId;
  final bool showFullDetails;
  final VoidCallback? onTap;

  const PrivacyControlWidget({
    super.key,
    required this.eventId,
    this.timelineId,
    this.showFullDetails = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final privacyService = ref.watch(granularPrivacyServiceProvider);
    final eventSettings = privacyService.getEventSettings(eventId);
    
    return GestureDetector(
      onTap: onTap ?? () => _showPrivacyDialog(context, ref),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: _getPrivacyColor(context, eventSettings).withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: _getPrivacyColor(context, eventSettings).withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _getPrivacyIcon(eventSettings),
              size: 16,
              color: _getPrivacyColor(context, eventSettings),
            ),
            const SizedBox(width: 6),
            Text(
              _getPrivacyText(eventSettings),
              style: TextStyle(
                color: _getPrivacyColor(context, eventSettings),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (showFullDetails) ...[
              const SizedBox(width: 4),
              Icon(
                Icons.arrow_drop_down,
                size: 16,
                color: _getPrivacyColor(context, eventSettings),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _getPrivacyColor(BuildContext context, EventPrivacySettings settings) {
    if (settings.inheritFromTimeline) {
      return Theme.of(context).colorScheme.primary;
    }
    
    final visibilityLevel = settings.privacyLevels[PrivacyControlType.visibility] ?? 
                          EnhancedPrivacyLevel.friends;
    
    switch (visibilityLevel) {
      case EnhancedPrivacyLevel.onlyMe:
        return Colors.red;
      case EnhancedPrivacyLevel.closeFamily:
      case EnhancedPrivacyLevel.extendedFamily:
        return Colors.orange;
      case EnhancedPrivacyLevel.closeFriends:
        return Colors.purple;
      case EnhancedPrivacyLevel.friends:
        return Colors.blue;
      case EnhancedPrivacyLevel.colleagues:
        return Colors.teal;
      case EnhancedPrivacyLevel.connections:
        return Colors.cyan;
      case EnhancedPrivacyLevel.public:
        return Colors.green;
    }
  }

  IconData _getPrivacyIcon(EventPrivacySettings settings) {
    if (settings.inheritFromTimeline) {
      return Icons.privacy_tip;
    }
    
    final visibilityLevel = settings.privacyLevels[PrivacyControlType.visibility] ?? 
                          EnhancedPrivacyLevel.friends;
    
    switch (visibilityLevel) {
      case EnhancedPrivacyLevel.onlyMe:
        return Icons.lock;
      case EnhancedPrivacyLevel.closeFamily:
        return Icons.family_restroom;
      case EnhancedPrivacyLevel.extendedFamily:
        return Icons.people;
      case EnhancedPrivacyLevel.closeFriends:
        return Icons.favorite;
      case EnhancedPrivacyLevel.friends:
        return Icons.group;
      case EnhancedPrivacyLevel.colleagues:
        return Icons.business_center;
      case EnhancedPrivacyLevel.connections:
        return Icons.share;
      case EnhancedPrivacyLevel.public:
        return Icons.public;
    }
  }

  String _getPrivacyText(EventPrivacySettings settings) {
    if (settings.inheritFromTimeline) {
      return 'Timeline Default';
    }
    
    final visibilityLevel = settings.privacyLevels[PrivacyControlType.visibility] ?? 
                          EnhancedPrivacyLevel.friends;
    
    if (settings.expiresAt != null) {
      return '${visibilityLevel.displayName} ⏰';
    }
    
    return visibilityLevel.displayName;
  }

  void _showPrivacyDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => _PrivacyQuickDialog(
        eventId: eventId,
        timelineId: timelineId,
      ),
    );
  }
}

/// Quick privacy dialog for inline adjustments
class _PrivacyQuickDialog extends ConsumerStatefulWidget {
  final String eventId;
  final String? timelineId;

  const _PrivacyQuickDialog({
    required this.eventId,
    this.timelineId,
  });

  @override
  ConsumerState<_PrivacyQuickDialog> createState() => _PrivacyQuickDialogState();
}

class _PrivacyQuickDialogState extends ConsumerState<_PrivacyQuickDialog> {
  late EventPrivacySettings _settings;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final privacyService = ref.read(granularPrivacyServiceProvider);
    _settings = privacyService.getEventSettings(widget.eventId);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(
            _getPrivacyIcon(_settings),
            color: _getPrivacyColor(_settings),
          ),
          const SizedBox(width: 8),
          const Text('Privacy Settings'),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Inheritance toggle
            SwitchListTile(
              title: const Text('Inherit from Timeline'),
              subtitle: const Text('Use timeline privacy settings'),
              value: _settings.inheritFromTimeline,
              onChanged: (value) {
                setState(() {
                  _settings = _settings.copyWith(inheritFromTimeline: value);
                });
              },
            ),
            
            if (!_settings.inheritFromTimeline) ...[
              const Divider(),
              const SizedBox(height: 8),
              
              // Privacy level selection
              Text(
                'Who can see this event?',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: EnhancedPrivacyLevel.values.map((level) {
                  final isSelected = (_settings.privacyLevels[PrivacyControlType.visibility] ?? 
                                   EnhancedPrivacyLevel.friends) == level;
                  
                  return FilterChip(
                    label: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(_getIconForPrivacyLevel(level), size: 16),
                        const SizedBox(width: 4),
                        Text(level.displayName),
                      ],
                    ),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          final updatedLevels = Map<PrivacyControlType, EnhancedPrivacyLevel>.from(
                            _settings.privacyLevels
                          );
                          updatedLevels[PrivacyControlType.visibility] = level;
                          _settings = _settings.copyWith(privacyLevels: updatedLevels);
                        });
                      }
                    },
                    backgroundColor: Colors.grey.shade200,
                    selectedColor: _getPrivacyColor(level).withOpacity(0.2),
                    checkmarkColor: _getPrivacyColor(level),
                  );
                }).toList(),
              ),
              
              const SizedBox(height: 16),
              
              // Quick attribute toggles
              Text(
                'Visible Attributes',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: ['location', 'media', 'story', 'participants'].map((attribute) {
                  return FilterChip(
                    label: Text(_getAttributeDisplayName(attribute)),
                    selected: _settings.visibleAttributes.contains(attribute),
                    onSelected: (selected) {
                      setState(() {
                        final updatedAttributes = Set<String>.from(_settings.visibleAttributes);
                        if (selected) {
                          updatedAttributes.add(attribute);
                        } else {
                          updatedAttributes.remove(attribute);
                        }
                        _settings = _settings.copyWith(visibleAttributes: updatedAttributes);
                      });
                    },
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => GranularPrivacyScreen(
                eventId: widget.eventId,
                timelineId: widget.timelineId,
              ),
            ),
          ),
          child: const Text('Advanced'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _saveSettings,
          child: _isLoading 
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Save'),
        ),
      ],
    );
  }

  Future<void> _saveSettings() async {
    setState(() => _isLoading = true);
    
    try {
      final privacyService = ref.read(granularPrivacyServiceProvider);
      final userId = 'current_user'; // This would come from auth service
      
      await privacyService.updateEventSettings(userId, _settings);
      
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Privacy settings updated'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Color _getPrivacyColor(EventPrivacySettings settings) {
    final visibilityLevel = settings.privacyLevels[PrivacyControlType.visibility] ?? 
                          EnhancedPrivacyLevel.friends;
    return _getPrivacyColor(visibilityLevel);
  }

  Color _getPrivacyColor(EnhancedPrivacyLevel level) {
    switch (level) {
      case EnhancedPrivacyLevel.onlyMe:
        return Colors.red;
      case EnhancedPrivacyLevel.closeFamily:
      case EnhancedPrivacyLevel.extendedFamily:
        return Colors.orange;
      case EnhancedPrivacyLevel.closeFriends:
        return Colors.purple;
      case EnhancedPrivacyLevel.friends:
        return Colors.blue;
      case EnhancedPrivacyLevel.colleagues:
        return Colors.teal;
      case EnhancedPrivacyLevel.connections:
        return Colors.cyan;
      case EnhancedPrivacyLevel.public:
        return Colors.green;
    }
  }

  IconData _getPrivacyIcon(EventPrivacySettings settings) {
    if (settings.inheritFromTimeline) {
      return Icons.privacy_tip;
    }
    
    final visibilityLevel = settings.privacyLevels[PrivacyControlType.visibility] ?? 
                          EnhancedPrivacyLevel.friends;
    
    switch (visibilityLevel) {
      case EnhancedPrivacyLevel.onlyMe:
        return Icons.lock;
      case EnhancedPrivacyLevel.closeFamily:
        return Icons.family_restroom;
      case EnhancedPrivacyLevel.extendedFamily:
        return Icons.people;
      case EnhancedPrivacyLevel.closeFriends:
        return Icons.favorite;
      case EnhancedPrivacyLevel.friends:
        return Icons.group;
      case EnhancedPrivacyLevel.colleagues:
        return Icons.business_center;
      case EnhancedPrivacyLevel.connections:
        return Icons.share;
      case EnhancedPrivacyLevel.public:
        return Icons.public;
    }
  }

  IconData _getIconForPrivacyLevel(EnhancedPrivacyLevel level) {
    switch (level) {
      case EnhancedPrivacyLevel.onlyMe:
        return Icons.lock;
      case EnhancedPrivacyLevel.closeFamily:
        return Icons.family_restroom;
      case EnhancedPrivacyLevel.extendedFamily:
        return Icons.people;
      case EnhancedPrivacyLevel.closeFriends:
        return Icons.favorite;
      case EnhancedPrivacyLevel.friends:
        return Icons.group;
      case EnhancedPrivacyLevel.colleagues:
        return Icons.business_center;
      case EnhancedPrivacyLevel.connections:
        return Icons.share;
      case EnhancedPrivacyLevel.public:
        return Icons.public;
    }
  }

  String _getAttributeDisplayName(String attribute) {
    switch (attribute) {
      case 'location':
        return 'Location';
      case 'media':
        return 'Media';
      case 'story':
        return 'Story';
      case 'participants':
        return 'People';
      default:
        return attribute;
    }
  }
}

/// Privacy indicator for timeline items
class PrivacyIndicator extends ConsumerWidget {
  final String eventId;
  final bool showLabel;

  const PrivacyIndicator({
    super.key,
    required this.eventId,
    this.showLabel = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final privacyService = ref.watch(granularPrivacyServiceProvider);
    final eventSettings = privacyService.getEventSettings(eventId);
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          _getPrivacyIcon(eventSettings),
          size: 16,
          color: _getPrivacyColor(context, eventSettings),
        ),
        if (showLabel) ...[
          const SizedBox(width: 4),
          Text(
            _getPrivacyText(eventSettings),
            style: TextStyle(
              color: _getPrivacyColor(context, eventSettings),
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }

  Color _getPrivacyColor(BuildContext context, EventPrivacySettings settings) {
    if (settings.inheritFromTimeline) {
      return Theme.of(context).colorScheme.primary;
    }
    
    final visibilityLevel = settings.privacyLevels[PrivacyControlType.visibility] ?? 
                          EnhancedPrivacyLevel.friends;
    
    switch (visibilityLevel) {
      case EnhancedPrivacyLevel.onlyMe:
        return Colors.red.shade600;
      case EnhancedPrivacyLevel.closeFamily:
        return Colors.orange.shade600;
      case EnhancedPrivacyLevel.extendedFamily:
        return Colors.deepOrange.shade600;
      case EnhancedPrivacyLevel.closeFriends:
        return Colors.purple.shade600;
      case EnhancedPrivacyLevel.friends:
        return Colors.blue.shade600;
      case EnhancedPrivacyLevel.colleagues:
        return Colors.teal.shade600;
      case EnhancedPrivacyLevel.connections:
        return Colors.cyan.shade600;
      case EnhancedPrivacyLevel.public:
        return Colors.green.shade600;
    }
  }

  IconData _getPrivacyIcon(EventPrivacySettings settings) {
    if (settings.inheritFromTimeline) {
      return Icons.privacy_tip;
    }
    
    final visibilityLevel = settings.privacyLevels[PrivacyControlType.visibility] ?? 
                          EnhancedPrivacyLevel.friends;
    
    switch (visibilityLevel) {
      case EnhancedPrivacyLevel.onlyMe:
        return Icons.lock;
      case EnhancedPrivacyLevel.closeFamily:
        return Icons.family_restroom;
      case EnhancedPrivacyLevel.extendedFamily:
        return Icons.people;
      case EnhancedPrivacyLevel.closeFriends:
        return Icons.favorite;
      case EnhancedPrivacyLevel.friends:
        return Icons.group;
      case EnhancedPrivacyLevel.colleagues:
        return Icons.business_center;
      case EnhancedPrivacyLevel.connections:
        return Icons.share;
      case EnhancedPrivacyLevel.public:
        return Icons.public;
    }
  }

  String _getPrivacyText(EventPrivacySettings settings) {
    if (settings.inheritFromTimeline) {
      return 'Default';
    }
    
    final visibilityLevel = settings.privacyLevels[PrivacyControlType.visibility] ?? 
                          EnhancedPrivacyLevel.friends;
    
    return visibilityLevel.displayName;
  }
}
