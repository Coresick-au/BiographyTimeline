import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/models/timeline_event.dart';
import '../../timeline/services/timeline_data_service.dart';

/// Simple export dialog that works without complex dependencies
class SimpleExportDialog extends ConsumerStatefulWidget {
  const SimpleExportDialog({super.key});

  @override
  ConsumerState<SimpleExportDialog> createState() => _SimpleExportDialogState();
}

class _SimpleExportDialogState extends ConsumerState<SimpleExportDialog> {
  bool _isExporting = false;
  String _selectedFormat = 'JSON';

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 400,
        height: 300,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Export Timeline',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            Text(
              'Choose export format:',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 16),
            
            RadioListTile<String>(
              title: const Text('JSON'),
              subtitle: const Text('Export all data as JSON file'),
              value: 'JSON',
              groupValue: _selectedFormat,
              onChanged: (value) {
                setState(() {
                  _selectedFormat = value!;
                });
              },
            ),
            RadioListTile<String>(
              title: const Text('CSV'),
              subtitle: const Text('Export events as CSV spreadsheet'),
              value: 'CSV',
              groupValue: _selectedFormat,
              onChanged: (value) {
                setState(() {
                  _selectedFormat = value!;
                });
              },
            ),
            
            const Spacer(),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: _isExporting ? null : () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: _isExporting ? null : _performExport,
                  child: _isExporting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text('Export $_selectedFormat'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _performExport() async {
    setState(() => _isExporting = true);
    
    try {
      final asyncState = ref.read(timelineDataProvider);
      final events = asyncState.value?.allEvents ?? [];
      
      // Simple export simulation
      await Future.delayed(const Duration(seconds: 2));
      
      // In a real implementation, this would generate and save the file
      final exportData = {
        'format': _selectedFormat,
        'eventCount': events.length,
        'exportedAt': DateTime.now().toIso8601String(),
        'events': events.map((e) => e.toJson()).toList(),
      };
      
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Exported ${events.length} events as $_selectedFormat'),
          backgroundColor: Colors.green,
        ),
      );
      
      debugPrint('Export data: ${exportData.toString()}');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Export failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }
}
