import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../shared/models/context.dart';
import '../../shared/models/timeline_theme.dart';
import '../../shared/models/timeline_event.dart';
import '../../shared/models/user.dart';
// import '../../core/factories/context_factory.dart'; // Removed in Family-First MVP
import '../../core/factories/timeline_event_factory.dart';
import '../timeline/widgets/quick_entry_button.dart';
import '../timeline/widgets/timeline_view.dart';
import 'widgets/context_card.dart';
import 'widgets/timeline_event_card.dart';
import 'timeline_progress_demo.dart';

class DemoPage extends ConsumerStatefulWidget {
  const DemoPage({super.key});

  @override
  ConsumerState<DemoPage> createState() => _DemoPageState();
}

class _DemoPageState extends ConsumerState<DemoPage> {
  ContextType selectedContextType = ContextType.person;
  late List<Context> demoContexts;
  late List<TimelineEvent> demoEvents;

  @override
  void initState() {
    super.initState();
    _initializeDemoData();
  }

  void _initializeDemoData() {
    // Create demo contexts for each type
    demoContexts = [
      Context(
        id: 'personal-context',
        ownerId: 'demo-user',
        type: ContextType.person,
        name: 'My Life Journey',
        description: 'Personal memories and milestones',
        moduleConfiguration: {},
        themeId: 'personal_theme',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      Context(
        id: 'pet-context',
        ownerId: 'demo-user',
        type: ContextType.pet,
        name: 'Buddy\'s Adventures',
        description: 'My dog\'s growth and memories',
        moduleConfiguration: {},
        themeId: 'pet_theme',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      Context(
        id: 'project-context',
        ownerId: 'demo-user',
        type: ContextType.project,
        name: 'Kitchen Renovation',
        description: 'Complete kitchen makeover project',
        moduleConfiguration: {},
        themeId: 'renovation_theme',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      Context(
        id: 'business-context',
        ownerId: 'demo-user',
        type: ContextType.business,
        name: 'Startup Journey',
        description: 'Building my tech startup',
        moduleConfiguration: {},
        themeId: 'business_theme',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    ];

    _generateDemoEvents();
  }

  void _generateDemoEvents() {
    final selectedContext = demoContexts.firstWhere(
      (context) => context.type == selectedContextType,
    );

    demoEvents = _createEventsForContext(selectedContext);
  }

  void _addNewEvent(TimelineEvent event) {
    setState(() {
      demoEvents.insert(0, event); // Add to beginning for most recent
      // Sort by timestamp descending (most recent first)
      demoEvents.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    });
  }

  List<TimelineEvent> _createEventsForContext(Context context) {
    final now = DateTime.now();
    
    switch (context.type) {
      case ContextType.person:
        return [
          TimelineEventFactory.createTextEvent(
            id: 'personal-1',
            contextId: context.id,
            ownerId: context.ownerId,
            contextType: context.type,
            timestamp: now.subtract(const Duration(days: 30)),
            text: 'Started learning Flutter development. Excited about building mobile apps!',
            title: 'New Learning Journey',
          ),
          TimelineEventFactory.createMilestoneEvent(
            id: 'personal-2',
            contextId: context.id,
            ownerId: context.ownerId,
            contextType: context.type,
            timestamp: now.subtract(const Duration(days: 7)),
            milestoneTitle: 'Completed First Flutter App',
            description: 'Successfully built and deployed my first Flutter application.',
            milestoneAttributes: {
              'milestone_type': 'achievement',
              'significance': 'high',
            },
          ),
        ];
        
      case ContextType.pet:
        return [
          TimelineEventFactory.createMilestoneEvent(
            id: 'pet-1',
            contextId: context.id,
            ownerId: context.ownerId,
            contextType: context.type,
            timestamp: now.subtract(const Duration(days: 14)),
            milestoneTitle: 'Vet Checkup',
            description: 'Annual vaccination and health checkup.',
            milestoneAttributes: {
              'weight_kg': 25.5,
              'vaccine_type': 'Rabies',
              'vet_visit': true,
              'mood': 'calm',
            },
          ),
          TimelineEventFactory.createTextEvent(
            id: 'pet-2',
            contextId: context.id,
            ownerId: context.ownerId,
            contextType: context.type,
            timestamp: now.subtract(const Duration(days: 3)),
            text: 'Buddy learned a new trick today! He can now roll over on command.',
            title: 'New Trick Mastered',
          ),
        ];
        
      case ContextType.project:
        return [
          TimelineEventFactory.createMilestoneEvent(
            id: 'project-1',
            contextId: context.id,
            ownerId: context.ownerId,
            contextType: context.type,
            timestamp: now.subtract(const Duration(days: 21)),
            milestoneTitle: 'Demolition Complete',
            description: 'Finished tearing down old cabinets and countertops.',
            milestoneAttributes: {
              'cost': 2500.0,
              'contractor': 'Mike\'s Demo Crew',
              'room': 'kitchen',
              'phase': 'demolition',
            },
          ),
          TimelineEventFactory.createMilestoneEvent(
            id: 'project-2',
            contextId: context.id,
            ownerId: context.ownerId,
            contextType: context.type,
            timestamp: now.subtract(const Duration(days: 10)),
            milestoneTitle: 'New Cabinets Installed',
            description: 'Beautiful new white shaker cabinets are in place.',
            milestoneAttributes: {
              'cost': 8500.0,
              'contractor': 'Cabinet Masters',
              'room': 'kitchen',
              'phase': 'construction',
            },
          ),
        ];
        
      case ContextType.business:
        return [
          TimelineEventFactory.createMilestoneEvent(
            id: 'business-1',
            contextId: context.id,
            ownerId: context.ownerId,
            contextType: context.type,
            timestamp: now.subtract(const Duration(days: 45)),
            milestoneTitle: 'MVP Launch',
            description: 'Successfully launched our minimum viable product to beta users.',
            milestoneAttributes: {
              'milestone': 'MVP Launch',
              'budget_spent': 25000.0,
              'team_size': 5,
            },
          ),
          TimelineEventFactory.createTextEvent(
            id: 'business-2',
            contextId: context.id,
            ownerId: context.ownerId,
            contextType: context.type,
            timestamp: now.subtract(const Duration(days: 2)),
            text: 'Reached 1000 active users! The growth is accelerating.',
            title: '1K Users Milestone',
          ),
        ];
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = TimelineTheme.forContextType(selectedContextType);
    final selectedContext = demoContexts.firstWhere(
      (context) => context.type == selectedContextType,
    );
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Users Timeline Demo'),
        backgroundColor: theme.getColor('primary'),
        foregroundColor: Colors.white,
        actions: [
          CompactQuickEntryButton(
            contextType: selectedContextType,
            contextId: selectedContext.id,
            ownerId: selectedContext.ownerId,
            onEventCreated: _addNewEvent,
          ),
        ],
      ),
      body: Column(
        children: [
          // Context Type Selector
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Select Context Type:',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  children: ContextType.values.map((type) {
                    final isSelected = type == selectedContextType;
                    return ChoiceChip(
                      label: Text(_getContextTypeName(type)),
                      selected: isSelected,
                      onSelected: (selected) {
                        if (selected) {
                          setState(() {
                            selectedContextType = type;
                            _generateDemoEvents();
                          });
                        }
                      },
                      selectedColor: theme.getColor('primary').withOpacity(0.3),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          
          const Divider(),
          
          // Context Information
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Context Card
                ContextCard(
                  context: demoContexts.firstWhere(
                    (context) => context.type == selectedContextType,
                  ),
                  theme: theme,
                ),
                
                const SizedBox(height: 24),
                
                // Timeline Events
                const Text(
                  'Timeline Events:',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                
                // Timeline View with filtering
                SizedBox(
                  height: 400,
                  child: TimelineView(
                    events: demoEvents,
                    contextType: selectedContextType,
                    contextId: selectedContext.id,
                    ownerId: selectedContext.ownerId,
                    onEventCreated: _addNewEvent,
                  ),
                ),
                
                // Features showcase
                const SizedBox(height: 24),
                _buildFeaturesShowcase(theme),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const TimelineProgressDemo(),
            ),
          );
        },
        icon: const Icon(Icons.timeline),
        label: const Text('Timeline Engine'),
        backgroundColor: theme.getColor('primary'),
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildFeaturesShowcase(TimelineTheme theme) {
    final context = demoContexts.firstWhere(
      (context) => context.type == selectedContextType,
    );
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Context Features:',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: theme.getColor('primary'),
              ),
            ),
            const SizedBox(height: 12),
            
            ...context.moduleConfiguration.entries.map((entry) {
              final isEnabled = entry.value == true;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Icon(
                      isEnabled ? Icons.check_circle : Icons.cancel,
                      color: isEnabled ? Colors.green : Colors.grey,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _formatFeatureName(entry.key),
                      style: TextStyle(
                        color: isEnabled ? Colors.black87 : Colors.grey,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  String _getContextTypeName(ContextType type) {
    switch (type) {
      case ContextType.person:
        return 'Personal';
      case ContextType.pet:
        return 'Pet';
      case ContextType.project:
        return 'Project';
      case ContextType.business:
        return 'Business';
    }
  }

  String _formatFeatureName(String key) {
    return key
        .replaceAll(RegExp(r'([A-Z])'), ' \$1')
        .replaceAll('enable', '')
        .trim()
        .split(' ')
        .map((word) => word.isEmpty ? '' : word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }
}
