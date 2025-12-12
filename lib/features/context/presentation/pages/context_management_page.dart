import 'package:flutter/material.dart';
import '../../../../shared/models/context.dart';
import '../../services/context_management_service.dart';
import 'context_creation_page.dart';
import '../widgets/context_card.dart';

/// Page for managing all user contexts and switching between them
class ContextManagementPage extends StatefulWidget {
  final String userId;
  final ContextManagementService contextService;
  final String? currentContextId;
  final Function(String contextId)? onContextSelected;

  const ContextManagementPage({
    Key? key,
    required this.userId,
    required this.contextService,
    this.currentContextId,
    this.onContextSelected,
  }) : super(key: key);

  @override
  State<ContextManagementPage> createState() => _ContextManagementPageState();
}

class _ContextManagementPageState extends State<ContextManagementPage> {
  List<Context> _contexts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadContexts();
    _listenToContextChanges();
  }

  void _listenToContextChanges() {
    widget.contextService.contextsStream.listen((contexts) {
      if (mounted) {
        setState(() {
          _contexts = contexts;
          _isLoading = false;
        });
      }
    });
  }

  Future<void> _loadContexts() async {
    try {
      final contexts = await widget.contextService.getContextsForUser(widget.userId);
      if (mounted) {
        setState(() {
          _contexts = contexts;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load timelines: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Timelines'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _navigateToCreateContext,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_contexts.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: _loadContexts,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _contexts.length,
        itemBuilder: (context, index) {
          final contextItem = _contexts[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: ContextCard(
              context: contextItem,
              isSelected: contextItem.id == widget.currentContextId,
              onTap: () => _selectContext(contextItem.id),
              onEdit: () => _editContext(contextItem),
              onDelete: () => _deleteContext(contextItem),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.timeline,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No Timelines Yet',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Create your first timeline to start organizing your memories and experiences.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[500],
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _navigateToCreateContext,
              icon: const Icon(Icons.add),
              label: const Text('Create Timeline'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _navigateToCreateContext() async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => ContextCreationPage(
          userId: widget.userId,
          contextService: widget.contextService,
        ),
      ),
    );

    if (result == true) {
      _loadContexts();
    }
  }

  void _selectContext(String contextId) {
    if (widget.onContextSelected != null) {
      widget.onContextSelected!(contextId);
    }
    Navigator.of(context).pop();
  }

  Future<void> _editContext(Context context) async {
    // Navigate to context editing page (to be implemented)
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Context editing coming soon'),
      ),
    );
  }

  Future<void> _deleteContext(Context context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Timeline'),
        content: Text(
          'Are you sure you want to delete "${context.name}"? This action cannot be undone and will remove all associated events and stories.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await widget.contextService.deleteContext(context.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Timeline "${context.name}" deleted'),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete timeline: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}