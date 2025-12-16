import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/models/story.dart';
import '../../../../shared/models/media_asset.dart';
import '../providers/story_editor_provider.dart';
import '../../../../shared/widgets/core/story_editor_field.dart';

/// Rich text story editor widget with timeline-specific features
class StoryEditor extends ConsumerStatefulWidget {
  final Story story;
  final List<MediaAsset> availableMedia;
  final VoidCallback? onSave;
  final Function(Story)? onStoryChanged;
  final String? initialContent;

  const StoryEditor({
    super.key,
    required this.story,
    required this.availableMedia,
    this.onSave,
    this.onStoryChanged,
    this.initialContent,
  });

  @override
  ConsumerState<StoryEditor> createState() => _StoryEditorState();
}

class _StoryEditorState extends ConsumerState<StoryEditor> {
  late QuillController _controller;
  late ScrollController _scrollController;
  final FocusNode _focusNode = FocusNode();
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    
    // Initialize QuillController with existing story content
    _controller = QuillController.basic();
    
    // Load initial content if provided
    if (widget.initialContent != null && widget.initialContent!.isNotEmpty) {
      _controller.document.insert(0, widget.initialContent!);
    }
    
    // Focus listener
    _focusNode.addListener(() {
      setState(() {
        _isFocused = _focusNode.hasFocus;
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.keyS, control: true): _saveStory,
        const SingleActivator(LogicalKeyboardKey.keyS, meta: true): _saveStory, // Cmd+S on Mac
        const SingleActivator(LogicalKeyboardKey.escape): () {
             if (Navigator.of(context).canPop()) Navigator.of(context).pop();
        },
      },
      child: Focus(
        autofocus: true, 
        child: Scaffold(
          appBar: AppBar(
            title: const Text('Story Editor'),
            actions: [
              IconButton(
                icon: const Icon(Icons.photo_library),
                onPressed: _showMediaPicker,
                tooltip: 'Insert Media',
              ),
              IconButton(
                icon: const Icon(Icons.save),
                onPressed: _saveStory,
                tooltip: 'Save Story (Cmd+S)',
              ),
            ],
          ),
          body: Column(
            children: [
              // Custom toolbar for timeline-specific features
              _buildCustomToolbar(),
              
              // Rich text editor wrapped in StoryEditorField
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: StoryEditorField(
                    label: 'Start writing...',
                    isFocused: _isFocused,
                    child: QuillEditor.basic(
                      focusNode: _focusNode,
                      configurations: QuillEditorConfigurations(
                        controller: _controller,
                        sharedConfigurations: const QuillSharedConfigurations(
                          locale: Locale('en'),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              
              // Status bar
              _buildStatusBar(),
            ],
          ),
        ),
      ),
    );
  }

  /// Build custom toolbar with timeline-specific features
  Widget _buildCustomToolbar() {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).dividerColor,
            width: 1,
          ),
        ),
      ),
      child: QuillSimpleToolbar(
        configurations: QuillSimpleToolbarConfigurations(
          controller: _controller,
          showFontFamily: false,
          showFontSize: false,
          showSearchButton: false,
          showSubscript: false,
          showSuperscript: false,
          showStrikeThrough: false,
          showInlineCode: false,
          showColorButton: false,
          showBackgroundColorButton: false,
          showClearFormat: false,
          showListCheck: false,
          showCodeBlock: false,
          showIndent: false,
          multiRowsDisplay: false,
        ),
      ),
    );
  }

  /// Build status bar showing save status and word count
  Widget _buildStatusBar() {
    final wordCount = _getWordCount();
    // Assuming this provider exists and matches logic
    // We use .maybeWhen or check if we have value to avoid errors if provider not init
    // But original code assumed it's safe.
    final state = ref.watch(storyEditorProvider(widget.story.id));
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant,
        border: Border(
          top: BorderSide(
            color: Theme.of(context).dividerColor,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          if (state.isAutoSaving)
            const Row(
              children: [
                SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                SizedBox(width: 8),
                Text('Saving...'),
              ],
            )
          else if (state.lastSaved != null)
            Text(
              'Saved ${_formatTime(state.lastSaved!)}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          
          const Spacer(),
          
          Text(
            '$wordCount words',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  /// Show media picker dialog
  void _showMediaPicker({String? mediaType}) {
    showModalBottomSheet(
      context: context,
      builder: (context) => MediaPickerSheet(
        availableMedia: widget.availableMedia,
        mediaType: mediaType,
        onMediaSelected: (mediaAsset) {
          Navigator.of(context).pop();
        },
      ),
    );
  }

  /// Save story manually
  void _saveStory() async {
    try {
      // Check if we're on web
      if (kIsWeb) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Story saving is not yet supported on web. Please use desktop app for persistent storage.'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 4),
            ),
          );
        }
        return;
      }
      
      // Get the current content from the Quill editor as plain text
      final document = _controller.document;
      final plainText = document.toPlainText();
      
      // Convert to StoryBlock (for now, just create a single text block)
      final textBlock = StoryBlock.text(
        id: 'block_${DateTime.now().millisecondsSinceEpoch}',
        text: plainText,
      );
      
      // Create updated story with new content
      final updatedStory = Story(
        id: widget.story.id,
        eventId: widget.story.eventId,
        authorId: widget.story.authorId,
        blocks: [textBlock], // Use blocks instead of content
        createdAt: widget.story.createdAt,
        updatedAt: DateTime.now(),
        version: widget.story.version + 1,
        collaboratorIds: widget.story.collaboratorIds,
      );
      
      // Save to repository
      final repository = ref.read(storyRepositoryProvider);
      await repository.saveStory(updatedStory);
      
      // Call the onSave callback
      widget.onSave?.call();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Story saved successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save story: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Get word count from current content
  int _getWordCount() {
    final text = _controller.document.toPlainText();
    return text.split(RegExp(r'\s+')).where((word) => word.isNotEmpty).length;
  }

  /// Format time for display
  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);
    
    if (difference.inMinutes < 1) {
      return 'just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }
}

/// Media picker sheet for inserting media into stories
class MediaPickerSheet extends StatelessWidget {
  final List<MediaAsset> availableMedia;
  final String? mediaType;
  final Function(MediaAsset) onMediaSelected;

  const MediaPickerSheet({
    super.key,
    required this.availableMedia,
    this.mediaType,
    required this.onMediaSelected,
  });

  @override
  Widget build(BuildContext context) {
    final filteredMedia = mediaType != null
        ? availableMedia.where((asset) => asset.type.name == mediaType).toList()
        : availableMedia;

    return Container(
      height: 400,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Select Media',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: filteredMedia.length,
              itemBuilder: (context, index) {
                final asset = filteredMedia[index];
                return GestureDetector(
                  onTap: () => onMediaSelected(asset),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Theme.of(context).dividerColor,
                      ),
                    ),
                    child: _buildMediaThumbnail(asset),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMediaThumbnail(MediaAsset asset) {
    switch (asset.type) {
      case AssetType.photo:
        return ClipRRect(
          borderRadius: BorderRadius.circular(7),
          child: Image.network(
            asset.cloudUrl ?? asset.localPath,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return const Icon(Icons.image, size: 40);
            },
          ),
        );
      case AssetType.video:
        return const Icon(Icons.play_circle_outline, size: 40);
      case AssetType.audio:
        return const Icon(Icons.audiotrack, size: 40);
      case AssetType.document:
        return const Icon(Icons.description, size: 40);
    }
  }
}
