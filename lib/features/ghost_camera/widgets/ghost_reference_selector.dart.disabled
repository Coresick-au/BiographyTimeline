import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/design_system/app_theme.dart';
import '../../../shared/design_system/app_icons.dart';
import '../../../shared/models/media_asset.dart';

/// Widget for selecting reference images for Ghost Camera
/// Shows timeline photos in a grid for easy selection
class GhostReferenceSelector extends ConsumerStatefulWidget {
  const GhostReferenceSelector({
    super.key,
    required this.timelineId,
    required this.onSelected,
    this.initialSelection,
  });

  final String timelineId;
  final Function(MediaAsset asset) onSelected;
  final MediaAsset? initialSelection;

  @override
  ConsumerState<GhostReferenceSelector> createState() => _GhostReferenceSelectorState();
}

class _GhostReferenceSelectorState extends ConsumerState<GhostReferenceSelector> {
  List<MediaAsset> _photos = [];
  MediaAsset? _selectedAsset;
  bool _isLoading = true;
  String _searchQuery = '';
  SortOption _sortOption = SortOption.dateDesc;

  @override
  void initState() {
    super.initState();
    _selectedAsset = widget.initialSelection;
    _loadPhotos();
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    
    return Scaffold(
      backgroundColor: theme.colors.background,
      appBar: AppBar(
        title: Text('Select Reference Photo'),
        actions: [
          IconButton(
            onPressed: _selectedAsset != null ? _confirmSelection : null,
            icon: Icon(AppIcons.check),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search photos...',
                prefixIcon: Icon(AppIcons.search),
                suffixIcon: PopupMenuButton<SortOption>(
                  icon: Icon(AppIcons.sort),
                  onSelected: (option) {
                    setState(() {
                      _sortOption = option;
                    });
                    _sortPhotos();
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: SortOption.dateDesc,
                      child: Text('Date (Newest)'),
                    ),
                    PopupMenuItem(
                      value: SortOption.dateAsc,
                      child: Text('Date (Oldest)'),
                    ),
                    PopupMenuItem(
                      value: SortOption.nameAsc,
                      child: Text('Name (A-Z)'),
                    ),
                  ],
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase();
                });
                _filterPhotos();
              },
            ),
          ),
          
          // Photos grid
          Expanded(
            child: _isLoading
                ? Center(
                    child: CircularProgressIndicator(),
                  )
                : _photos.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              AppIcons.photo,
                              size: 64,
                              color: theme.colors.textSecondary,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No photos found',
                              style: theme.textStyles.titleMedium,
                            ),
                          ],
                        ),
                      )
                    : GridView.builder(
                        padding: const EdgeInsets.all(16),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: _getCrossAxisCount(),
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                          childAspectRatio: 1.0,
                        ),
                        itemCount: _photos.length,
                        itemBuilder: (context, index) {
                          final asset = _photos[index];
                          final isSelected = asset.id == _selectedAsset?.id;
                          
                          return PhotoGridItem(
                            asset: asset,
                            isSelected: isSelected,
                            onTap: () => _selectPhoto(asset),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  int _getCrossAxisCount() {
    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth > 1200) return 5;
    if (screenWidth > 800) return 4;
    if (screenWidth > 600) return 3;
    return 2;
  }

  Future<void> _loadPhotos() async {
    // Implementation would load photos from database
    // For now, just simulate loading
    await Future.delayed(Duration(seconds: 1));
    
    setState(() {
      _isLoading = false;
      // Mock data
      _photos = List.generate(20, (index) => MediaAsset(
        id: 'photo_$index',
        localPath: '/path/to/photo_$index.jpg',
        createdAt: DateTime.now().subtract(Duration(days: index)),
        width: 1920,
        height: 1080,
        mimeType: 'image/jpeg',
        fileSize: 1000000,
      ));
    });
  }

  void _filterPhotos() {
    // Implementation would filter photos based on search query
    // For now, just return all
  }

  void _sortPhotos() {
    switch (_sortOption) {
      case SortOption.dateDesc:
        _photos.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case SortOption.dateAsc:
        _photos.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        break;
      case SortOption.nameAsc:
        _photos.sort((a, b) => a.fileName.compareTo(b.fileName));
        break;
    }
  }

  void _selectPhoto(MediaAsset asset) {
    setState(() {
      _selectedAsset = asset;
    });
  }

  void _confirmSelection() {
    if (_selectedAsset != null) {
      widget.onSelected(_selectedAsset!);
      Navigator.of(context).pop();
    }
  }
}

/// Individual photo item in the grid
class PhotoGridItem extends StatelessWidget {
  const PhotoGridItem({
    super.key,
    required this.asset,
    required this.isSelected,
    required this.onTap,
  });

  final MediaAsset asset;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? theme.colors.primary : theme.colors.outline,
            width: isSelected ? 3 : 1,
          ),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Photo thumbnail
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Image.file(
                File(asset.localPath),
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: theme.colors.surfaceVariant,
                    child: Icon(
                      AppIcons.image,
                      color: theme.colors.textSecondary,
                    ),
                  );
                },
              ),
            ),
            
            // Selection indicator
            if (isSelected)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: theme.colors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    AppIcons.check,
                    color: theme.colors.onPrimary,
                    size: 16,
                  ),
                ),
              ),
            
            // Date overlay
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withOpacity(0.7),
                      Colors.transparent,
                    ],
                  ),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(6),
                    bottomRight: Radius.circular(6),
                  ),
                ),
                child: Text(
                  _formatDate(asset.createdAt),
                  style: theme.textStyles.labelSmall.copyWith(
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else if (difference.inDays < 30) {
      return '${(difference.inDays / 7).floor()} weeks ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}

/// Sort options for photo list
enum SortOption {
  dateDesc,
  dateAsc,
  nameAsc,
}
