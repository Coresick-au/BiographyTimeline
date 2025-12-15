import 'dart:ui';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
// import 'package:share_plus/share_plus.dart'; // Removed as not in dependencies
// Actually share_plus is not in the list. I'll check pubspec again.
// share_plus is not in the list. I will use path_provider to save to documents.

import '../../../shared/models/timeline_event.dart';
import '../../../shared/design_system/design_system.dart';

class ExportDialog extends StatefulWidget {
  final List<TimelineEvent> events;

  const ExportDialog({super.key, required this.events});

  @override
  State<ExportDialog> createState() => _ExportDialogState();
}

class _ExportDialogState extends State<ExportDialog> {
  bool _isExporting = false;
  String? _resultMessage;

  Future<void> _exportToJson() async {
    setState(() {
      _isExporting = true;
      _resultMessage = null;
    });

    try {
      // 1. Convert events to JSON
      final eventsJson = widget.events.map((e) => e.toJson()).toList();
      final jsonString = jsonEncode({
        'version': '1.0',
        'timestamp': DateTime.now().toIso8601String(),
        'events': eventsJson,
      });

      // 2. Save to file
      final directory = await getApplicationDocumentsDirectory();
      final fileName = 'timeline_backup_${DateTime.now().millisecondsSinceEpoch}.json';
      final file = File('${directory.path}/$fileName');
      
      await file.writeAsString(jsonString);

      if (mounted) {
        setState(() {
          _resultMessage = 'Exported to ${file.path}';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _resultMessage = 'Export failed: $e';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isExporting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(16),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        constraints: const BoxConstraints(maxWidth: 400),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          color: theme.scaffoldBackgroundColor.withOpacity(0.9),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Icon(Icons.ios_share, color: theme.colorScheme.primary),
                      const SizedBox(width: 12),
                      Text(
                        'Export Timeline',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  _buildExportOption(
                    context,
                    icon: Icons.data_object,
                    title: 'JSON Backup',
                    subtitle: 'Full data backup compatible with import',
                    onTap: _isExporting ? null : _exportToJson,
                  ),
                  
                  const SizedBox(height: 12),
                  
                  _buildExportOption(
                    context,
                    icon: Icons.picture_as_pdf,
                    title: 'PDF Document',
                    subtitle: 'Printable version (Coming Soon)',
                    onTap: null, // Disabled for now
                    isDisabled: true,
                  ),

                  if (_isExporting) ...[
                    const SizedBox(height: 24),
                    const Center(child: CircularProgressIndicator()),
                  ],

                  if (_resultMessage != null) ...[
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.secondaryContainer.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _resultMessage!,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSecondaryContainer,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Close'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildExportOption(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    VoidCallback? onTap,
    bool isDisabled = false,
  }) {
    final theme = Theme.of(context);
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(
              color: theme.dividerColor.withOpacity(isDisabled ? 0.05 : 0.2),
            ),
            borderRadius: BorderRadius.circular(16),
            color: theme.colorScheme.surface.withOpacity(isDisabled ? 0.3 : 0.5),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDisabled 
                      ? theme.disabledColor.withOpacity(0.1)
                      : theme.colorScheme.primaryContainer.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: isDisabled 
                      ? theme.disabledColor
                      : theme.colorScheme.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: isDisabled ? theme.disabledColor : null,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant.withOpacity(
                          isDisabled ? 0.5 : 0.8
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (!isDisabled)
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: theme.colorScheme.onSurface.withOpacity(0.3),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
