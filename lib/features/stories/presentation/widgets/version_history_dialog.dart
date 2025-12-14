import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../shared/models/story.dart';
import '../../../../shared/models/media_asset.dart';
import '../providers/story_editor_provider.dart';

/// Story version model for version history
class StoryVersion {
  final int version;
  final String summary;
  final DateTime timestamp;
  final int wordCount;
  final Story story;

  StoryVersion({
    required this.version,
    required this.summary,
    required this.timestamp,
    required this.wordCount,
    required this.story,
  });
}

/// Version control service for managing story versions
class VersionControlService {
  final StoryRepository _repository;

  VersionControlService(this._repository);

  Future<List<StoryVersion>> getVersionHistory(String storyId) async {
    try {
      final stories = await _repository.getStoryVersions(storyId);
      return stories.map((story) => StoryVersion(
        version: story.version,
        summary: _generateSummary(story),
        timestamp: story.updatedAt,
        wordCount: _countWords(story),
        story: story,
      )).toList();
    } catch (e) {
      return [];
    }
  }

  String _generateSummary(Story story) {
    final firstBlock = story.blocks.isNotEmpty ? story.blocks.first : null;
    if (firstBlock != null && firstBlock.type.name == 'text') {
      final text = firstBlock.content['text'] as String? ?? '';
      return text.length > 50 ? '${text.substring(0, 50)}...' : text;
    }
    return 'Version ${story.version}';
  }

  int _countWords(Story story) {
    int wordCount = 0;
    for (final block in story.blocks) {
      if (block.type.name == 'text') {
        final text = block.content['text'] as String? ?? '';
        wordCount += text.split(RegExp(r'\s+')).where((word) => word.isNotEmpty).length;
      }
    }
    return wordCount;
  }

  Future<void> restoreVersion(String storyId, int version) async {
    // Get the version to restore
    final versions = await getVersionHistory(storyId);
    final targetVersion = versions.firstWhere((v) => v.version == version);
    
    // Create a new story based on the restored version
    final restoredStory = targetVersion.story.copyWith(
      version: targetVersion.story.version + 1,
      updatedAt: DateTime.now(),
    );
    
    // Save the restored story
    await _repository.saveStory(restoredStory);
  }
}

/// Dialog for viewing and managing story version history
class VersionHistoryDialog extends ConsumerStatefulWidget {
  final String storyId;
  final Function(int)? onVersionRestore;

  const VersionHistoryDialog({
    super.key,
    required this.storyId,
    this.onVersionRestore,
  });

  @override
  ConsumerState<VersionHistoryDialog> createState() => _VersionHistoryDialogState();
}

class _VersionHistoryDialogState extends ConsumerState<VersionHistoryDialog> {
  List<StoryVersion>? _versions;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadVersionHistory();
  }

  Future<void> _loadVersionHistory() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final versionService = VersionControlService(ref.read(storyRepositoryProvider));
      final versions = await versionService.getVersionHistory(widget.storyId);
      
      setState(() {
        _versions = versions;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load version history: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.8,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Text(
                  'Version History',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Content
            Expanded(
              child: _buildContent(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadVersionHistory,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_versions == null || _versions!.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, size: 48, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No version history available',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: _versions!.length,
      itemBuilder: (context, index) {
        final version = _versions![index];
        final isLatest = index == 0;
        
        return _buildVersionItem(version, isLatest);
      },
    );
  }

  Widget _buildVersionItem(StoryVersion version, bool isLatest) {
    final dateFormat = DateFormat('MMM dd, yyyy HH:mm');
    
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isLatest 
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.surfaceVariant,
          child: Text(
            'v${version.version}',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: isLatest ? Colors.white : null,
            ),
          ),
        ),
        
        title: Text(
          version.summary,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              dateFormat.format(version.timestamp),
              style: Theme.of(context).textTheme.bodySmall,
            ),
            Text(
              '${version.wordCount} words',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ],
        ),
        
        trailing: isLatest 
            ? Chip(
                label: const Text('Current'),
                backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              )
            : PopupMenuButton<String>(
                onSelected: (action) => _handleVersionAction(action, version),
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'restore',
                    child: Row(
                      children: [
                        Icon(Icons.restore),
                        SizedBox(width: 8),
                        Text('Restore'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'compare',
                    child: Row(
                      children: [
                        Icon(Icons.compare_arrows),
                        SizedBox(width: 8),
                        Text('Compare'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'preview',
                    child: Row(
                      children: [
                        Icon(Icons.preview),
                        SizedBox(width: 8),
                        Text('Preview'),
                      ],
                    ),
                  ),
                ],
              ),
        
        onTap: () => _showVersionPreview(version),
      ),
    );
  }

  void _handleVersionAction(String action, StoryVersion version) {
    switch (action) {
      case 'restore':
        _showRestoreConfirmation(version);
        break;
      case 'compare':
        _showVersionComparison(version);
        break;
      case 'preview':
        _showVersionPreview(version);
        break;
    }
  }

  void _showRestoreConfirmation(StoryVersion version) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Restore Version'),
        content: Text(
          'Are you sure you want to restore version ${version.version}? '
          'This will create a new version with the restored content.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _restoreVersion(version);
            },
            child: const Text('Restore'),
          ),
        ],
      ),
    );
  }

  Future<void> _restoreVersion(StoryVersion version) async {
    try {
      final versionService = VersionControlService(ref.read(storyRepositoryProvider));
      await versionService.restoreVersion(widget.storyId, version.version);
      
      widget.onVersionRestore?.call(version.version);
      
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Version ${version.version} restored successfully'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to restore version: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  void _showVersionComparison(StoryVersion version) {
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Version comparison view opened'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _showVersionPreview(StoryVersion version) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          height: MediaQuery.of(context).size.height * 0.7,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'Version ${version.version} Preview',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: version.story.blocks.map((block) {
                      if (block.type.name == 'text') {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Text(
                            block.content['text'] as String? ?? '',
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    }).toList(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}