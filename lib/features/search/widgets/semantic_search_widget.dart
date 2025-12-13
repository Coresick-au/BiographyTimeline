import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_quill/flutter_quill.dart';
import '../../../shared/intelligence/semantic_search_service.dart';
import '../../../shared/design_system/app_theme.dart';
import '../../../shared/design_system/app_icons.dart';
import '../../../shared/design_system/responsive_layout.dart';

/// Semantic search widget with natural language query support
/// Provides intelligent content discovery with suggestions and filters
class SemanticSearchWidget extends ConsumerStatefulWidget {
  const SemanticSearchWidget({
    super.key,
    this.onResultSelected,
    this.initialQuery,
    this.placeholder = 'Search your timeline...',
    this.showFilters = true,
    this.maxResults = 20,
  });

  final Function(SearchResult)? onResultSelected;
  final String? initialQuery;
  final String placeholder;
  final bool showFilters;
  final int maxResults;

  @override
  ConsumerState<SemanticSearchWidget> createState() => _SemanticSearchWidgetState();
}

class _SemanticSearchWidgetState extends ConsumerState<SemanticSearchWidget>
    with TickerProviderStateMixin {
  final _searchController = TextEditingController();
  final _focusNode = FocusNode();
  final _debouncer = Debouncer(milliseconds: 500);
  
  List<SearchResult> _results = [];
  List<String> _suggestions = [];
  List<String> _trending = [];
  bool _isSearching = false;
  bool _showSuggestions = false;
  SearchType _selectedType = SearchType.all;
  List<String> _selectedFilters = [];
  
  late AnimationController _suggestionController;
  late Animation<double> _suggestionAnimation;
  
  @override
  void initState() {
    super.initState();
    _suggestionController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _suggestionAnimation = CurvedAnimation(
      parent: _suggestionController,
      curve: Curves.easeInOut,
    );
    
    if (widget.initialQuery != null) {
      _searchController.text = widget.initialQuery!;
      _performSearch(widget.initialQuery!);
    }
    
    _loadTrendingSearches();
    
    _searchController.addListener(_onQueryChanged);
    _focusNode.addListener(_onFocusChanged);
  }
  
  @override
  void dispose() {
    _searchController.removeListener(_onQueryChanged);
    _focusNode.removeListener(_onFocusChanged);
    _searchController.dispose();
    _focusNode.dispose();
    _suggestionController.dispose();
    super.dispose();
  }
  
  void _onQueryChanged() {
    final query = _searchController.text;
    if (query.isNotEmpty) {
      _debouncer.run(() {
        _getSuggestions(query);
      });
    }
  }
  
  void _onFocusChanged() {
    setState(() {
      _showSuggestions = _focusNode.hasFocus && _searchController.text.isNotEmpty;
    });
    
    if (_showSuggestions) {
      _suggestionController.forward();
    } else {
      _suggestionController.reverse();
    }
  }
  
  Future<void> _loadTrendingSearches() async {
    final service = ref.read(semanticSearchProvider);
    final trending = await service.getTrendingSearches();
    if (mounted) {
      setState(() {
        _trending = trending;
      });
    }
  }
  
  Future<void> _getSuggestions(String query) async {
    final service = ref.read(semanticSearchProvider);
    final suggestions = await service.getSuggestions(query);
    if (mounted) {
      setState(() {
        _suggestions = suggestions;
      });
    }
  }
  
  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) return;
    
    setState(() {
      _isSearching = true;
      _showSuggestions = false;
    });
    
    try {
      final service = ref.read(semanticSearchProvider);
      final results = await service.search(
        query,
        limit: widget.maxResults,
        type: _selectedType,
        filters: _selectedFilters,
      );
      
      if (mounted) {
        setState(() {
          _results = results;
          _isSearching = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSearching = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Search failed: $e')),
        );
      }
    }
  }
  
  void _onResultTapped(SearchResult result) {
    widget.onResultSelected?.call(result);
    _focusNode.unfocus();
  }
  
  void _onSuggestionTapped(String suggestion) {
    _searchController.text = suggestion;
    _performSearch(suggestion);
    _focusNode.unfocus();
  }
  
  void _onTrendingTapped(String query) {
    _searchController.text = query;
    _performSearch(query);
  }
  
  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _results.clear();
      _suggestions.clear();
    });
  }
  
  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    
    return Column(
      children: [
        _buildSearchBar(theme),
        if (widget.showFilters) _buildFilters(theme),
        if (_isSearching)
          _buildLoadingIndicator()
        else if (_results.isNotEmpty)
          _buildResults(theme)
        else if (_searchController.text.isEmpty && _trending.isNotEmpty)
          _buildTrending(theme),
        _buildSuggestionsOverlay(theme),
      ],
    );
  }
  
  Widget _buildSearchBar(AppTheme theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              focusNode: _focusNode,
              decoration: InputDecoration(
                hintText: widget.placeholder,
                prefixIcon: Icon(AppIcons.search, color: theme.colors.textSecondary),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(AppIcons.close, color: theme.colors.textSecondary),
                        onPressed: _clearSearch,
                      )
                    : null,
                filled: true,
                fillColor: theme.colors.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              onSubmitted: _performSearch,
            ),
          ),
          const SizedBox(width: 12),
          ResponsiveLayout.isMobile(context)
              ? Container()
              : FilterButton(
                  selectedType: _selectedType,
                  onTypeChanged: (type) {
                    setState(() {
                      _selectedType = type;
                    });
                    if (_searchController.text.isNotEmpty) {
                      _performSearch(_searchController.text);
                    }
                  },
                ),
        ],
      ),
    );
  }
  
  Widget _buildFilters(AppTheme theme) {
    final filters = [
      'Recent', 'Old', 'Family', 'Friends', 'Vacation',
      'Celebration', 'Outdoor', 'Indoor', 'Food', 'Nature',
    ];
    
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        itemBuilder: (context, index) {
          final filter = filters[index];
          final isSelected = _selectedFilters.contains(filter);
          
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(filter),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _selectedFilters.add(filter);
                  } else {
                    _selectedFilters.remove(filter);
                  }
                });
                if (_searchController.text.isNotEmpty) {
                  _performSearch(_searchController.text);
                }
              },
            ),
          );
        },
      ),
    );
  }
  
  Widget _buildLoadingIndicator() {
    return const Expanded(
      child: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
  
  Widget _buildResults(AppTheme theme) {
    return Expanded(
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _results.length,
        itemBuilder: (context, index) {
          final result = _results[index];
          return SearchResultCard(
            result: result,
            onTap: () => _onResultTapped(result),
          );
        },
      ),
    );
  }
  
  Widget _buildTrending(AppTheme theme) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Trending Searches',
              style: theme.textStyles.titleMedium,
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _trending.map((query) {
                return ActionChip(
                  label: Text(query),
                  onPressed: () => _onTrendingTapped(query),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSuggestionsOverlay(AppTheme theme) {
    return AnimatedBuilder(
      animation: _suggestionAnimation,
      builder: (context, child) {
        return Opacity(
          opacity: _suggestionAnimation.value,
          child: _showSuggestions && _suggestions.isNotEmpty
              ? Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: theme.colors.surface,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: theme.colors.shadow,
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: _suggestions.length,
                    itemBuilder: (context, index) {
                      final suggestion = _suggestions[index];
                      return ListTile(
                        dense: true,
                        leading: Icon(
                          AppIcons.history,
                          size: 20,
                          color: theme.colors.textSecondary,
                        ),
                        title: Text(suggestion),
                        onTap: () => _onSuggestionTapped(suggestion),
                      );
                    },
                  ),
                )
              : const SizedBox.shrink(),
        );
      },
    );
  }
}

/// Search result card widget
class SearchResultCard extends StatelessWidget {
  const SearchResultCard({
    super.key,
    required this.result,
    required this.onTap,
  });

  final SearchResult result;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    result.type == SearchType.media
                        ? AppIcons.photo
                        : AppIcons.event,
                    size: 20,
                    color: theme.colors.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      result.title,
                      style: theme.textStyles.titleMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${(result.score * 100).toInt()}% match',
                      style: theme.textStyles.labelSmall.copyWith(
                        color: theme.colors.primary,
                      ),
                    ),
                  ),
                ],
              ),
              if (result.description != null) ...[
                const SizedBox(height: 8),
                Text(
                  result.description!,
                  style: theme.textStyles.bodyMedium,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              if (result.tags.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children: result.tags.take(5).map((tag) {
                    return Chip(
                      label: Text(
                        tag,
                        style: theme.textStyles.labelSmall,
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    );
                  }).toList(),
                ),
              ],
              if (result.locationName != null || result.dateText != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    if (result.locationName != null) ...[
                      Icon(
                        AppIcons.location,
                        size: 16,
                        color: theme.colors.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        result.locationName!,
                        style: theme.textStyles.bodySmall.copyWith(
                          color: theme.colors.textSecondary,
                        ),
                      ),
                    ],
                    if (result.locationName != null && result.dateText != null)
                      const SizedBox(width: 16),
                    if (result.dateText != null) ...[
                      Icon(
                        AppIcons.calendar,
                        size: 16,
                        color: theme.colors.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        result.dateText!,
                        style: theme.textStyles.bodySmall.copyWith(
                          color: theme.colors.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Filter button for desktop view
class FilterButton extends StatelessWidget {
  const FilterButton({
    super.key,
    required this.selectedType,
    required this.onTypeChanged,
  });

  final SearchType selectedType;
  final Function(SearchType) onTypeChanged;

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    
    return PopupMenuButton<SearchType>(
      icon: Icon(AppIcons.filter, color: theme.colors.textSecondary),
      onSelected: onTypeChanged,
      itemBuilder: (context) => [
        PopupMenuItem(
          value: SearchType.all,
          child: Row(
            children: [
              Icon(
                AppIcons.timeline,
                size: 20,
                color: selectedType == SearchType.all
                    ? theme.colors.primary
                    : theme.colors.textSecondary,
              ),
              const SizedBox(width: 12),
              Text('All'),
            ],
          ),
        ),
        PopupMenuItem(
          value: SearchType.media,
          child: Row(
            children: [
              Icon(
                AppIcons.photo,
                size: 20,
                color: selectedType == SearchType.media
                    ? theme.colors.primary
                    : theme.colors.textSecondary,
              ),
              const SizedBox(width: 12),
              Text('Photos'),
            ],
          ),
        ),
        PopupMenuItem(
          value: SearchType.event,
          child: Row(
            children: [
              Icon(
                AppIcons.event,
                size: 20,
                color: selectedType == SearchType.event
                    ? theme.colors.primary
                    : theme.colors.textSecondary,
              ),
              const SizedBox(width: 12),
              Text('Events'),
            ],
          ),
        ),
      ],
    );
  }
}

/// Debouncer for search queries
class Debouncer {
  final int milliseconds;
  Timer? _timer;
  
  Debouncer({required this.milliseconds});
  
  run(VoidCallback action) {
    _timer?.cancel();
    _timer = Timer(Duration(milliseconds: milliseconds), action);
  }
}
