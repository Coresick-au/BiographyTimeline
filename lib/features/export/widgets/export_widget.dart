import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import '../../../shared/export/data_export_service.dart';
import '../../../shared/design_system/app_theme.dart';
import '../../../shared/design_system/app_icons.dart';

/// Export widget for timeline data
/// Provides options for PDF, ZIP, and JSON exports
class ExportWidget extends ConsumerStatefulWidget {
  const ExportWidget({
    super.key,
    this.eventIds,
    this.mediaIds,
    this.onExportComplete,
  });

  final List<String>? eventIds;
  final List<String>? mediaIds;
  final Function(String path, ExportType type)? onExportComplete;

  @override
  ConsumerState<ExportWidget> createState() => _ExportWidgetState();
}

class _ExportWidgetState extends ConsumerState<ExportWidget>
    with TickerProviderStateMixin {
  ExportType _selectedType = ExportType.pdf;
  bool _isExporting = false;
  String? _currentExportId;
  ExportProgress? _currentProgress;
  
  late AnimationController _progressController;
  late Animation<double> _progressAnimation;
  
  final Map<ExportType, bool> _expandedOptions = {
    ExportType.pdf: false,
    ExportType.zip: false,
    ExportType.json: false,
  };

  // Export options
  late PDFExportOptions _pdfOptions;
  late ZIPExportOptions _zipOptions;
  late JSONExportOptions _jsonOptions;

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _progressAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _progressController, curve: Curves.easeInOut),
    );
    
    _initializeOptions();
    
    // Listen to export progress
    ref.listen(dataExportProvider, (previous, next) {
      if (_currentExportId != null) {
        final progress = next.getExportProgress(_currentExportId!);
        if (progress != null) {
          setState(() {
            _currentProgress = progress;
          });
          
          if (progress.status == ExportStatus.completed) {
            _onExportCompleted(progress);
          } else if (progress.status == ExportStatus.failed) {
            _onExportFailed(progress);
          }
        }
      }
    });
  }

  @override
  void dispose() {
    _progressController.dispose();
    super.dispose();
  }

  void _initializeOptions() {
    _pdfOptions = const PDFExportOptions(
      title: 'Timeline Biography',
      subtitle: 'Your Life Story',
      includeTitlePage: true,
      includeTableOfContents: true,
      pageBreakBetweenEvents: true,
    );
    
    _zipOptions = const ZIPExportOptions(
      includeMetadata: true,
      includeEvents: true,
      includeMedia: true,
      includeOriginalFiles: true,
      includeThumbnails: true,
      includeMediaMetadata: true,
      includeIndividualFiles: false,
    );
    
    _jsonOptions = const JSONExportOptions(
      includeMediaReferences: true,
      includeBase64Media: false,
      encryptSensitiveData: false,
      prettyPrint: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    
    return Container(
      decoration: BoxDecoration(
        color: theme.colors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: theme.colors.shadow,
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: theme.colors.primary.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  AppIcons.download,
                  color: theme.colors.primary,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  'Export Timeline',
                  style: theme.textStyles.titleLarge.copyWith(
                    color: theme.colors.primary,
                  ),
                ),
              ],
            ),
          ),
          
          // Export type selection
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Choose Export Format',
                  style: theme.textStyles.titleMedium,
                ),
                const SizedBox(height: 16),
                
                // Format options
                Row(
                  children: [
                    _buildFormatOption(
                      context,
                      type: ExportType.pdf,
                      icon: AppIcons.document,
                      title: 'PDF Book',
                      subtitle: 'Printable timeline book',
                    ),
                    const SizedBox(width: 12),
                    _buildFormatOption(
                      context,
                      type: ExportType.zip,
                      icon: AppIcons.archive,
                      title: 'ZIP Archive',
                      subtitle: 'All files and metadata',
                    ),
                    const SizedBox(width: 12),
                    _buildFormatOption(
                      context,
                      type: ExportType.json,
                      icon: AppIcons.code,
                      title: 'JSON Data',
                      subtitle: 'Portable data format',
                    ),
                  ],
                ),
                
                const SizedBox(height: 24),
                
                // Format-specific options
                _buildFormatOptions(theme),
                
                const SizedBox(height: 24),
                
                // Export button
                if (_isExporting)
                  _buildProgressSection(theme)
                else
                  _buildExportButton(theme),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormatOption(
    BuildContext context, {
    required ExportType type,
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    final theme = AppTheme.of(context);
    final isSelected = _selectedType == type;
    
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedType = type),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isSelected 
                ? theme.colors.primary.withOpacity(0.1)
                : theme.colors.surfaceVariant,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected 
                  ? theme.colors.primary
                  : theme.colors.outline.withOpacity(0.2),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                size: 32,
                color: isSelected 
                    ? theme.colors.primary
                    : theme.colors.onSurfaceVariant,
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: theme.textStyles.titleSmall.copyWith(
                  color: isSelected 
                      ? theme.colors.primary
                      : theme.colors.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: theme.textStyles.bodySmall.copyWith(
                  color: theme.colors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFormatOptions(AppTheme theme) {
    switch (_selectedType) {
      case ExportType.pdf:
        return _buildPDFOptions(theme);
      case ExportType.zip:
        return _buildZIPOptions(theme);
      case ExportType.json:
        return _buildJSONOptions(theme);
    }
  }

  Widget _buildPDFOptions(AppTheme theme) {
    return ExpansionTile(
      title: Text(
        'PDF Options',
        style: theme.textStyles.titleSmall,
      ),
      initiallyExpanded: _expandedOptions[ExportType.pdf]!,
      onExpansionChanged: (expanded) {
        setState(() {
          _expandedOptions[ExportType.pdf] = expanded;
        });
      },
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            children: [
              SwitchListTile(
                title: Text('Include Title Page'),
                value: _pdfOptions.includeTitlePage,
                onChanged: (value) {
                  setState(() {
                    _pdfOptions = _pdfOptions.copyWith(
                      includeTitlePage: value,
                    );
                  });
                },
              ),
              SwitchListTile(
                title: Text('Include Table of Contents'),
                value: _pdfOptions.includeTableOfContents,
                onChanged: (value) {
                  setState(() {
                    _pdfOptions = _pdfOptions.copyWith(
                      includeTableOfContents: value,
                    );
                  });
                },
              ),
              SwitchListTile(
                title: Text('Page Break Between Events'),
                value: _pdfOptions.pageBreakBetweenEvents,
                onChanged: (value) {
                  setState(() {
                    _pdfOptions = _pdfOptions.copyWith(
                      pageBreakBetweenEvents: value,
                    );
                  });
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildZIPOptions(AppTheme theme) {
    return ExpansionTile(
      title: Text(
        'ZIP Options',
        style: theme.textStyles.titleSmall,
      ),
      initiallyExpanded: _expandedOptions[ExportType.zip]!,
      onExpansionChanged: (expanded) {
        setState(() {
          _expandedOptions[ExportType.zip] = expanded;
        });
      },
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            children: [
              SwitchListTile(
                title: Text('Include Original Files'),
                subtitle: Text('Full resolution photos and videos'),
                value: _zipOptions.includeOriginalFiles,
                onChanged: (value) {
                  setState(() {
                    _zipOptions = _zipOptions.copyWith(
                      includeOriginalFiles: value,
                    );
                  });
                },
              ),
              SwitchListTile(
                title: Text('Include Thumbnails'),
                subtitle: Text('Smaller preview images'),
                value: _zipOptions.includeThumbnails,
                onChanged: (value) {
                  setState(() {
                    _zipOptions = _zipOptions.copyWith(
                      includeThumbnails: value,
                    );
                  });
                },
              ),
              SwitchListTile(
                title: Text('Include Metadata'),
                subtitle: Text('Event and media information'),
                value: _zipOptions.includeMediaMetadata,
                onChanged: (value) {
                  setState(() {
                    _zipOptions = _zipOptions.copyWith(
                      includeMediaMetadata: value,
                    );
                  });
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildJSONOptions(AppTheme theme) {
    return ExpansionTile(
      title: Text(
        'JSON Options',
        style: theme.textStyles.titleSmall,
      ),
      initiallyExpanded: _expandedOptions[ExportType.json]!,
      onExpansionChanged: (expanded) {
        setState(() {
          _expandedOptions[ExportType.json] = expanded;
        });
      },
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            children: [
              SwitchListTile(
                title: Text('Include Media References'),
                subtitle: Text('Links between events and media'),
                value: _jsonOptions.includeMediaReferences,
                onChanged: (value) {
                  setState(() {
                    _jsonOptions = _jsonOptions.copyWith(
                      includeMediaReferences: value,
                    );
                  });
                },
              ),
              SwitchListTile(
                title: Text('Include Base64 Media'),
                subtitle: Text('Embed small images in JSON'),
                value: _jsonOptions.includeBase64Media,
                onChanged: (value) {
                  setState(() {
                    _jsonOptions = _jsonOptions.copyWith(
                      includeBase64Media: value,
                    );
                  });
                },
              ),
              SwitchListTile(
                title: Text('Encrypt Sensitive Data'),
                subtitle: Text('Protect private information'),
                value: _jsonOptions.encryptSensitiveData,
                onChanged: (value) {
                  setState(() {
                    _jsonOptions = _jsonOptions.copyWith(
                      encryptSensitiveData: value,
                    );
                  });
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildExportButton(AppTheme theme) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _isExporting ? null : _startExport,
        icon: Icon(_getExportIcon()),
        label: Text(_getExportLabel()),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          backgroundColor: theme.colors.primary,
          foregroundColor: theme.colors.onPrimary,
        ),
      ),
    );
  }

  Widget _buildProgressSection(AppTheme theme) {
    return Column(
      children: [
        LinearProgressIndicator(
          value: _currentProgress?.progress ?? 0.0,
          backgroundColor: theme.colors.surfaceVariant,
          valueColor: AlwaysStoppedAnimation<Color>(theme.colors.primary),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _getProgressMessage(),
              style: theme.textStyles.bodyMedium,
            ),
            TextButton(
              onPressed: _cancelExport,
              child: Text(
                'Cancel',
                style: theme.textStyles.labelMedium.copyWith(
                  color: theme.colors.error,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _startExport() async {
    if (widget.eventIds == null || widget.eventIds!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No events selected for export')),
      );
      return;
    }

    setState(() {
      _isExporting = true;
      _currentProgress = null;
    });

    // InteractionFeedback.trigger(); // Temporarily disabled due to design system issues

    try {
      final service = ref.read(dataExportProvider);
      
      switch (_selectedType) {
        case ExportType.pdf:
          _currentExportId = await service.exportToPDF(
            eventIds: widget.eventIds!,
            options: _pdfOptions,
          );
          break;
        case ExportType.zip:
          _currentExportId = await service.exportToZIP(
            eventIds: widget.eventIds!,
            mediaIds: widget.mediaIds ?? [],
            options: _zipOptions,
          );
          break;
        case ExportType.json:
          _currentExportId = await service.exportToJSON(
            eventIds: widget.eventIds!,
            mediaIds: widget.mediaIds ?? [],
            options: _jsonOptions,
          );
          break;
      }
    } catch (e) {
      setState(() {
        _isExporting = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Export failed: $e')),
      );
    }
  }

  void _cancelExport() async {
    if (_currentExportId != null) {
      final service = ref.read(dataExportProvider);
      await service.cancelExport(_currentExportId!);
      setState(() {
        _isExporting = false;
        _currentExportId = null;
        _currentProgress = null;
      });
    }
  }

  void _onExportCompleted(ExportProgress progress) {
    setState(() {
      _isExporting = false;
    });
    
    _progressController.forward().then((_) {
      widget.onExportComplete?.call(progress.outputPath!, progress.type);
      
      // Show share dialog
      if (progress.outputPath != null) {
        _showShareDialog(progress.outputPath!, progress.type);
      }
    });
  }

  void _onExportFailed(ExportProgress progress) {
    setState(() {
      _isExporting = false;
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Export failed: ${progress.error}'),
        backgroundColor: AppTheme.of(context).colors.error,
      ),
    );
  }

  void _showShareDialog(String filePath, ExportType type) {
    final file = File(filePath);
    Share.shareXFiles(
      [XFile(filePath)],
      subject: _getShareSubject(type),
    );
  }

  IconData _getExportIcon() {
    switch (_selectedType) {
      case ExportType.pdf:
        return AppIcons.document;
      case ExportType.zip:
        return AppIcons.archive;
      case ExportType.json:
        return AppIcons.code;
    }
  }

  String _getExportLabel() {
    switch (_selectedType) {
      case ExportType.pdf:
        return 'Export as PDF';
      case ExportType.zip:
        return 'Export as ZIP';
      case ExportType.json:
        return 'Export as JSON';
    }
  }

  String _getProgressMessage() {
    if (_currentProgress == null) return 'Preparing...';
    
    switch (_currentProgress!.status) {
      case ExportStatus.preparing:
        return 'Preparing export...';
      case ExportStatus.processing:
        final percent = (_currentProgress!.progress * 100).toInt();
        return 'Exporting... $percent%';
      case ExportStatus.completed:
        return 'Export completed!';
      default:
        return 'Exporting...';
    }
  }

  String _getShareSubject(ExportType type) {
    switch (type) {
      case ExportType.pdf:
        return 'Timeline Biography PDF';
      case ExportType.zip:
        return 'Timeline Biography Archive';
      case ExportType.json:
        return 'Timeline Biography Data';
    }
  }
}

// Extension for copying with changes
extension PDFExportOptionsCopy on PDFExportOptions {
  PDFExportOptions copyWith({
    String? title,
    String? subtitle,
    String? customFilename,
    bool? includeTitlePage,
    bool? includeTableOfContents,
    bool? pageBreakBetweenEvents,
  }) {
    return PDFExportOptions(
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      customFilename: customFilename ?? this.customFilename,
      includeTitlePage: includeTitlePage ?? this.includeTitlePage,
      includeTableOfContents: includeTableOfContents ?? this.includeTableOfContents,
      pageBreakBetweenEvents: pageBreakBetweenEvents ?? this.pageBreakBetweenEvents,
    );
  }
}

extension ZIPExportOptionsCopy on ZIPExportOptions {
  ZIPExportOptions copyWith({
    String? customFilename,
    bool? includeMetadata,
    bool? includeEvents,
    bool? includeMedia,
    bool? includeOriginalFiles,
    bool? includeThumbnails,
    bool? includeMediaMetadata,
    bool? includeIndividualFiles,
  }) {
    return ZIPExportOptions(
      customFilename: customFilename ?? this.customFilename,
      includeMetadata: includeMetadata ?? this.includeMetadata,
      includeEvents: includeEvents ?? this.includeEvents,
      includeMedia: includeMedia ?? this.includeMedia,
      includeOriginalFiles: includeOriginalFiles ?? this.includeOriginalFiles,
      includeThumbnails: includeThumbnails ?? this.includeThumbnails,
      includeMediaMetadata: includeMediaMetadata ?? this.includeMediaMetadata,
      includeIndividualFiles: includeIndividualFiles ?? this.includeIndividualFiles,
    );
  }
}

extension JSONExportOptionsCopy on JSONExportOptions {
  JSONExportOptions copyWith({
    String? customFilename,
    bool? includeMediaReferences,
    bool? includeBase64Media,
    bool? encryptSensitiveData,
    bool? prettyPrint,
  }) {
    return JSONExportOptions(
      customFilename: customFilename ?? this.customFilename,
      includeMediaReferences: includeMediaReferences ?? this.includeMediaReferences,
      includeBase64Media: includeBase64Media ?? this.includeBase64Media,
      encryptSensitiveData: encryptSensitiveData ?? this.encryptSensitiveData,
      prettyPrint: prettyPrint ?? this.prettyPrint,
    );
  }
}
