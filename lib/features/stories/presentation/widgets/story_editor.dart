import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/models/story.dart';
import '../../../../shared/models/media_asset.dart';
// import '../../services/story_editor_service.dart';
import '../providers/story_editor_provider.dart';

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
    
    // Start auto-save
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
    return Scaffold(
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
            tooltip: 'Save Story',
          ),
        ],
      ),
      body: Column(
        children: [
          // Custom toolbar for timeline-specific features
          _buildCustomToolbar(),
          
          // Rich text editor
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              child: QuillEditor.basic(
                configurations: QuillEditorConfigurations(
                  controller: _controller,
                  placeholder: 'Tell your story...',
                  padding: const EdgeInsets.all(16),
                  autoFocus: true,
                  expands: true,
                  scrollable: true,
                  customStyles: _buildCustomStyles(),
                ),
                focusNode: _focusNode,
                scrollController: _scrollController,
              ),
            ),
          ),
          
          // Status bar
          _buildStatusBar(),
        ],
      ),
    );
  }

  /// Build custom toolbar with timeline-specific features
  Widget _buildCustomToolbar() {
    return Container(
      decoration: BoxDecoration(
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
          showBoldButton: true,
          showItalicButton: true,
          showUnderLineButton: true,
          showStrikeThrough: true,
          showColorButton: true,
          showBackgroundColorButton: true,
          showHeaderStyle: true,
          showListNumbers: true,
          showListBullets: true,
          showQuote: true,
          showLink: true,
          showUndo: true,
          showRedo: true,
          showDirection: false,
          showSearchButton: false,
          customButtons: [
            QuillToolbarCustomButtonOptions(
              icon: Icon(Icons.photo),
              onPressed: _showMediaPicker,
              tooltip: 'Insert Photo',
            ),
            QuillToolbarCustomButtonOptions(
              icon: Icon(Icons.videocam),
              onPressed: () => _showMediaPicker(mediaType: 'video'),
              tooltip: 'Insert Video',
            ),
            QuillToolbarCustomButtonOptions(
              icon: Icon(Icons.audiotrack),
              onPressed: () => _showMediaPicker(mediaType: 'audio'),
              tooltip: 'Insert Audio',
            ),
          ],
        ),
      ),
    );
  }

  /// Build custom text styles for mobile reading
  DefaultStyles _buildCustomStyles() {
    final theme = Theme.of(context);
    return DefaultStyles(
      h1: DefaultTextBlockStyle(
        theme.textTheme.headlineMedium!.copyWith(
          fontWeight: FontWeight.bold,
          height: 1.3,
        ),
        const VerticalSpacing(16, 8),
        const VerticalSpacing(0, 0),
        null,
      ),
      h2: DefaultTextBlockStyle(
        theme.textTheme.headlineSmall!.copyWith(
          fontWeight: FontWeight.bold,
          height: 1.3,
        ),
        const VerticalSpacing(12, 6),
        const VerticalSpacing(0, 0),
        null,
      ),
      paragraph: DefaultTextBlockStyle(
        theme.textTheme.bodyLarge!.copyWith(
          height: 1.6, // Optimized line height for mobile reading
          fontSize: 16,
        ),
        const VerticalSpacing(8, 8),
        const VerticalSpacing(0, 0),
        null,
      ),
    );
  }

  /// Build status bar showing save status and word count
  Widget _buildStatusBar() {
    final wordCount = _getWordCount();
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
        // Show message that database isn't available on web
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