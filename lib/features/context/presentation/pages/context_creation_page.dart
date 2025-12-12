import 'package:flutter/material.dart';
import '../../../../shared/models/context.dart';
import '../../services/context_management_service.dart';

/// Page for creating a new timeline context
class ContextCreationPage extends StatefulWidget {
  final String userId;
  final ContextManagementService contextService;

  const ContextCreationPage({
    Key? key,
    required this.userId,
    required this.contextService,
  }) : super(key: key);

  @override
  State<ContextCreationPage> createState() => _ContextCreationPageState();
}

class _ContextCreationPageState extends State<ContextCreationPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  ContextType? _selectedType;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create New Timeline'),
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Choose your timeline type',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Each type provides specialized features and organization for different aspects of your life.',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: ListView(
                  children: [
                    _buildContextTypeCard(
                      type: ContextType.person,
                      title: 'Personal Life',
                      description: 'Track your personal memories, milestones, and life events',
                      icon: Icons.person,
                      color: Colors.blue,
                    ),
                    const SizedBox(height: 12),
                    _buildContextTypeCard(
                      type: ContextType.pet,
                      title: 'Pet Timeline',
                      description: 'Document your pet\'s growth, health, and memorable moments',
                      icon: Icons.pets,
                      color: Colors.green,
                    ),
                    const SizedBox(height: 12),
                    _buildContextTypeCard(
                      type: ContextType.project,
                      title: 'Project Progress',
                      description: 'Track renovation, construction, or creative project progress',
                      icon: Icons.construction,
                      color: Colors.orange,
                    ),
                    const SizedBox(height: 12),
                    _buildContextTypeCard(
                      type: ContextType.business,
                      title: 'Business Journey',
                      description: 'Document business milestones, team growth, and achievements',
                      icon: Icons.business,
                      color: Colors.indigo,
                    ),
                  ],
                ),
              ),
              if (_selectedType != null) ...[
                const SizedBox(height: 24),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Timeline Name',
                    hintText: 'e.g., "My Life", "Buddy\'s Journey", "Kitchen Renovation"',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a name for your timeline';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description (Optional)',
                    hintText: 'Add a brief description of this timeline',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 24),
                _buildFeaturePreview(),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _isLoading ? null : _createContext,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator()
                      : const Text(
                          'Create Timeline',
                          style: TextStyle(fontSize: 16),
                        ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContextTypeCard({
    required ContextType type,
    required String title,
    required String description,
    required IconData icon,
    required Color color,
  }) {
    final isSelected = _selectedType == type;
    
    return Card(
      elevation: isSelected ? 8 : 2,
      child: InkWell(
        onTap: () => setState(() => _selectedType = type),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: isSelected
                ? Border.all(color: color, width: 2)
                : null,
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                Icon(
                  Icons.check_circle,
                  color: color,
                  size: 24,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeaturePreview() {
    if (_selectedType == null) return const SizedBox.shrink();

    final config = widget.contextService.getDefaultConfigurationForType(_selectedType!);
    final enabledFeatures = config.entries
        .where((entry) => entry.value == true)
        .map((entry) => _getFeatureDisplayName(entry.key))
        .toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Included Features',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: enabledFeatures
                  .map((feature) => Chip(
                        label: Text(feature),
                        backgroundColor: Colors.blue.withOpacity(0.1),
                      ))
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }

  String _getFeatureDisplayName(String featureKey) {
    switch (featureKey) {
      case 'enableGhostCamera':
        return 'Ghost Camera';
      case 'enableBudgetTracking':
        return 'Budget Tracking';
      case 'enableProgressComparison':
        return 'Progress Comparison';
      case 'enableMilestoneTracking':
        return 'Milestone Tracking';
      case 'enableLocationTracking':
        return 'Location Tracking';
      case 'enableFaceDetection':
        return 'Face Detection';
      case 'enableWeightTracking':
        return 'Weight Tracking';
      case 'enableVetVisitTracking':
        return 'Vet Visit Tracking';
      case 'enableTaskTracking':
        return 'Task Tracking';
      case 'enableTeamTracking':
        return 'Team Tracking';
      case 'enableRevenueTracking':
        return 'Revenue Tracking';
      default:
        return featureKey;
    }
  }

  Future<void> _createContext() async {
    if (!_formKey.currentState!.validate() || _selectedType == null) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      await widget.contextService.createContext(
        ownerId: widget.userId,
        type: _selectedType!,
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
      );

      if (mounted) {
        Navigator.of(context).pop(true); // Return true to indicate success
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create timeline: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}