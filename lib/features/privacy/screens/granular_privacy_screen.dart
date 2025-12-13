import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/granular_privacy_models.dart';
import '../services/granular_privacy_service.dart';
import '../../social/models/user_models.dart';

/// Screen for managing granular privacy controls
class GranularPrivacyScreen extends ConsumerStatefulWidget {
  final String? eventId;
  final String? timelineId;

  const GranularPrivacyScreen({
    super.key,
    this.eventId,
    this.timelineId,
  });

  @override
  ConsumerState<GranularPrivacyScreen> createState() => _GranularPrivacyScreenState();
}

class _GranularPrivacyScreenState extends ConsumerState<GranularPrivacyScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  EventPrivacySettings? _eventSettings;
  TimelinePrivacySettings? _timelineSettings;
  List<PrivacyTemplate> _templates = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: widget.eventId != null ? 4 : 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    try {
      final privacyService = ref.read(granularPrivacyServiceProvider);
      
      if (widget.eventId != null) {
        _eventSettings = privacyService.getEventSettings(widget.eventId!);
      }
      
      if (widget.timelineId != null) {
        _timelineSettings = privacyService.getTimelineSettings(widget.timelineId!);
      }
      
      _templates = privacyService.getTemplates();
      
    } catch (e) {
      _showErrorDialog('Error loading privacy settings', e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.eventId != null ? 'Event Privacy' : 'Timeline Privacy'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: [
            const Tab(text: 'General', icon: Icon(Icons.privacy_tip)),
            const Tab(text: 'Controls', icon: Icon(Icons.tune)),
            if (widget.eventId != null) const Tab(text: 'Attributes', icon: Icon(Icons.visibility)),
            const Tab(text: 'Templates', icon: Icon(Icons.dashboard)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: _showAuditLog,
            tooltip: 'Privacy History',
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildGeneralSettings(),
          _buildControlSettings(),
          if (widget.eventId != null) _buildAttributeSettings(),
          _buildTemplateSettings(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _saveSettings,
        child: const Icon(Icons.save),
        tooltip: 'Save Settings',
      ),
    );
  }

  Widget _buildGeneralSettings() {
    if (widget.eventId != null && _eventSettings != null) {
      return _buildEventGeneralSettings();
    } else if (_timelineSettings != null) {
      return _buildTimelineGeneralSettings();
    }
    return const Center(child: Text('No settings available'));
  }

  Widget _buildEventGeneralSettings() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Privacy Inheritance',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  'Inherit privacy settings from timeline or use custom settings for this event.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  title: const Text('Inherit from Timeline'),
                  subtitle: const Text('Use timeline privacy settings as default'),
                  value: _eventSettings!.inheritFromTimeline,
                  onChanged: (value) {
                    setState(() {
                      _eventSettings = _eventSettings!.copyWith(inheritFromTimeline: value);
                    });
                  },
                ),
                if (!_eventSettings!.inheritFromTimeline) ...[
                  const Divider(),
                  const SizedBox(height: 16),
                  Text(
                    'Custom Privacy Message',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: TextEditingController(text: _eventSettings!.customMessage),
                    decoration: const InputDecoration(
                      labelText: 'Privacy Message (optional)',
                      border: OutlineInputBorder(),
                      helperText: 'Explain why this event has custom privacy',
                    ),
                    maxLines: 3,
                    onChanged: (value) {
                      setState(() {
                        _eventSettings = _eventSettings!.copyWith(customMessage: value.isEmpty ? null : value);
                      });
                    },
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Expiration Settings',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                ListTile(
                  title: const Text('Privacy Expires'),
                  subtitle: Text(
                    _eventSettings!.expiresAt != null
                        ? 'Expires on ${_formatDate(_eventSettings!.expiresAt!)}'
                        : 'Never expires',
                  ),
                  trailing: const Icon(Icons.schedule),
                  onTap: _showExpirationPicker,
                ),
                if (_eventSettings!.expiresAt != null) ...[
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: () {
                      setState(() {
                        _eventSettings = _eventSettings!.copyWith(expiresAt: null);
                      });
                    },
                    icon: const Icon(Icons.clear),
                    label: const Text('Remove Expiration'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTimelineGeneralSettings() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Default Privacy Level',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<EnhancedPrivacyLevel>(
                  value: _timelineSettings!.defaultLevel,
                  decoration: const InputDecoration(
                    labelText: 'Default Level',
                    border: OutlineInputBorder(),
                  ),
                  items: EnhancedPrivacyLevel.values.map((level) {
                    return DropdownMenuItem(
                      value: level,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(level.displayName),
                          Text(
                            level.description,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _timelineSettings = _timelineSettings!.copyWith(defaultLevel: value);
                      });
                    }
                  },
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Interaction Settings',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  title: const Text('Allow Event Requests'),
                  subtitle: const Text('Others can request access to specific events'),
                  value: _timelineSettings!.allowEventRequests,
                  onChanged: (value) {
                    setState(() {
                      _timelineSettings = _timelineSettings!.copyWith(allowEventRequests: value);
                    });
                  },
                ),
                SwitchListTile(
                  title: const Text('Allow Context Requests'),
                  subtitle: const Text('Others can request access to specific contexts'),
                  value: _timelineSettings!.allowContextRequests,
                  onChanged: (value) {
                    setState(() {
                      _timelineSettings = _timelineSettings!.copyWith(allowContextRequests: value);
                    });
                  },
                ),
                SwitchListTile(
                  title: const Text('Allow Tagging'),
                  subtitle: const Text('Others can tag you in events'),
                  value: _timelineSettings!.allowTagging,
                  onChanged: (value) {
                    setState(() {
                      _timelineSettings = _timelineSettings!.copyWith(allowTagging: value);
                    });
                  },
                ),
                SwitchListTile(
                  title: const Text('Allow Mentions'),
                  subtitle: const Text('Others can mention you in comments'),
                  value: _timelineSettings!.allowMentions,
                  onChanged: (value) {
                    setState(() {
                      _timelineSettings = _timelineSettings!.copyWith(allowMentions: value);
                    });
                  },
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Profile Visibility',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  title: const Text('Show Online Status'),
                  subtitle: const Text('Let others see when you\'re online'),
                  value: _timelineSettings!.showOnlineStatus,
                  onChanged: (value) {
                    setState(() {
                      _timelineSettings = _timelineSettings!.copyWith(showOnlineStatus: value);
                    });
                  },
                ),
                SwitchListTile(
                  title: const Text('Show Last Active'),
                  subtitle: const Text('Let others see when you were last active'),
                  value: _timelineSettings!.showLastActive,
                  onChanged: (value) {
                    setState(() {
                      _timelineSettings = _timelineSettings!.copyWith(showLastActive: value);
                    });
                  },
                ),
                SwitchListTile(
                  title: const Text('Show Participation Stats'),
                  subtitle: const Text('Let others see your event participation statistics'),
                  value: _timelineSettings!.showParticipationStats,
                  onChanged: (value) {
                    setState(() {
                      _timelineSettings = _timelineSettings!.copyWith(showParticipationStats: value);
                    });
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildControlSettings() {
    if (widget.eventId != null && _eventSettings != null) {
      return _buildEventControlSettings();
    } else if (_timelineSettings != null) {
      return _buildTimelineControlSettings();
    }
    return const Center(child: Text('No control settings available'));
  }

  Widget _buildEventControlSettings() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Privacy Controls',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  'Set specific privacy levels for different aspects of this event.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                ...PrivacyControlType.values.map((controlType) {
                  final currentLevel = _eventSettings!.privacyLevels[controlType] ?? 
                      _timelineSettings?.defaultControlLevels[controlType] ?? 
                      EnhancedPrivacyLevel.friends;
                  
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          controlType.displayName,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          controlType.description,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<EnhancedPrivacyLevel>(
                          value: currentLevel,
                          decoration: InputDecoration(
                            labelText: controlType.displayName,
                            border: const OutlineInputBorder(),
                            isDense: true,
                          ),
                          items: EnhancedPrivacyLevel.values.map((level) {
                            return DropdownMenuItem(
                              value: level,
                              child: Row(
                                children: [
                                  Icon(
                                    _getIconForPrivacyLevel(level),
                                    size: 16,
                                    color: Theme.of(context).colorScheme.primary,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(child: Text(level.displayName)),
                                ],
                              ),
                            );
                          }).toList(),
                          onChanged: (value) {
                            if (value != null) {
                              setState(() {
                                final updatedLevels = Map<PrivacyControlType, EnhancedPrivacyLevel>.from(
                                  _eventSettings!.privacyLevels
                                );
                                updatedLevels[controlType] = value;
                                _eventSettings = _eventSettings!.copyWith(privacyLevels: updatedLevels);
                              });
                            }
                          },
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTimelineControlSettings() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Default Privacy Controls',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  'Set default privacy levels for different types of content in your timeline.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                ...PrivacyControlType.values.map((controlType) {
                  final currentLevel = _timelineSettings!.defaultControlLevels[controlType] ?? 
                      _timelineSettings!.defaultLevel;
                  
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          controlType.displayName,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          controlType.description,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<EnhancedPrivacyLevel>(
                          value: currentLevel,
                          decoration: InputDecoration(
                            labelText: 'Default ${controlType.displayName}',
                            border: const OutlineInputBorder(),
                            isDense: true,
                          ),
                          items: EnhancedPrivacyLevel.values.map((level) {
                            return DropdownMenuItem(
                              value: level,
                              child: Row(
                                children: [
                                  Icon(
                                    _getIconForPrivacyLevel(level),
                                    size: 16,
                                    color: Theme.of(context).colorScheme.primary,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(child: Text(level.displayName)),
                                ],
                              ),
                            );
                          }).toList(),
                          onChanged: (value) {
                            if (value != null) {
                              setState(() {
                                final updatedLevels = Map<PrivacyControlType, EnhancedPrivacyLevel>.from(
                                  _timelineSettings!.defaultControlLevels
                                );
                                updatedLevels[controlType] = value;
                                _timelineSettings = _timelineSettings!.copyWith(
                                  defaultControlLevels: updatedLevels
                                );
                              });
                            }
                          },
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAttributeSettings() {
    if (_eventSettings == null) return const SizedBox.shrink();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Visible Attributes',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  'Choose which attributes of this event are visible to others.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                ...['title', 'description', 'timestamp', 'location', 'media', 'story', 'participants'].map((attribute) {
                  return CheckboxListTile(
                    title: Text(_getAttributeDisplayName(attribute)),
                    subtitle: Text(_getAttributeDescription(attribute)),
                    value: _eventSettings!.visibleAttributes.contains(attribute),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          final updatedAttributes = Set<String>.from(_eventSettings!.visibleAttributes);
                          if (value) {
                            updatedAttributes.add(attribute);
                          } else {
                            updatedAttributes.remove(attribute);
                          }
                          _eventSettings = _eventSettings!.copyWith(visibleAttributes: updatedAttributes);
                        });
                      }
                    },
                  );
                }),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTemplateSettings() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Privacy Templates',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  'Quickly apply pre-configured privacy settings to your content.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                ..._templates.map((template) {
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: CircleAvatar(
                        child: Icon(_getIconForPrivacyLevel(
                          template.privacyLevels[PrivacyControlType.visibility] ?? 
                          EnhancedPrivacyLevel.friends
                        )),
                      ),
                      title: Text(template.name),
                      subtitle: Text(template.description),
                      trailing: widget.eventId != null 
                          ? IconButton(
                              icon: const Icon(Icons.apply),
                              onPressed: () => _applyTemplate(template),
                              tooltip: 'Apply Template',
                            )
                          : null,
                      onTap: () => _showTemplateDetails(template),
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _saveSettings() async {
    try {
      final privacyService = ref.read(granularPrivacyServiceProvider);
      final userId = 'current_user'; // This would come from auth service
      
      if (widget.eventId != null && _eventSettings != null) {
        await privacyService.updateEventSettings(userId, _eventSettings!);
      }
      
      if (widget.timelineId != null && _timelineSettings != null) {
        await privacyService.updateTimelineSettings(userId, _timelineSettings!);
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Privacy settings saved successfully'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      _showErrorDialog('Error saving settings', e.toString());
    }
  }

  Future<void> _showExpirationPicker() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _eventSettings!.expiresAt ?? DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (date != null) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_eventSettings!.expiresAt ?? DateTime.now()),
      );

      if (time != null) {
        setState(() {
          _eventSettings = _eventSettings!.copyWith(
            expiresAt: DateTime(
              date.year,
              date.month,
              date.day,
              time.hour,
              time.minute,
            ),
          );
        });
      }
    }
  }

  Future<void> _applyTemplate(PrivacyTemplate template) async {
    try {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Apply ${template.name}'),
          content: Text('This will replace current privacy settings with the template settings. Continue?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Apply'),
            ),
          ],
        ),
      );

      if (confirmed == true && widget.eventId != null) {
        final privacyService = ref.read(granularPrivacyServiceProvider);
        final userId = 'current_user';
        
        await privacyService.applyTemplateToEvent(userId, template.id, widget.eventId!);
        await _loadData(); // Reload to get updated settings
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Applied ${template.name} template'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      _showErrorDialog('Error applying template', e.toString());
    }
  }

  void _showTemplateDetails(PrivacyTemplate template) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(template.name),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(template.description),
              const SizedBox(height: 16),
              const Text('Privacy Settings:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              ...template.privacyLevels.entries.map((entry) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    children: [
                      Icon(_getIconForPrivacyLevel(entry.value), size: 16),
                      const SizedBox(width: 8),
                      Expanded(child: Text('${entry.key.displayName}: ${entry.value.displayName}')),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
          if (widget.eventId != null)
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _applyTemplate(template);
              },
              child: const Text('Apply'),
            ),
        ],
      ),
    );
  }

  void _showAuditLog() {
    // This would show the privacy audit log
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Privacy history coming soon!')),
    );
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} at ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  String _getAttributeDisplayName(String attribute) {
    switch (attribute) {
      case 'title':
        return 'Title';
      case 'description':
        return 'Description';
      case 'timestamp':
        return 'Date & Time';
      case 'location':
        return 'Location';
      case 'media':
        return 'Media Files';
      case 'story':
        return 'Story Content';
      case 'participants':
        return 'Participants';
      default:
        return attribute;
    }
  }

  String _getAttributeDescription(String attribute) {
    switch (attribute) {
      case 'title':
        return 'Event title and name';
      case 'description':
        return 'Event description and details';
      case 'timestamp':
        return 'When the event occurred';
      case 'location':
        return 'Where the event took place';
      case 'media':
        return 'Photos, videos, and other files';
      case 'story':
        return 'Story narrative and content';
      case 'participants':
        return 'People involved in the event';
      default:
        return '';
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
}
