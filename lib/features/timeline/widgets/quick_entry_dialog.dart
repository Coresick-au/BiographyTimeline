import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import '../../../shared/models/context.dart';
import '../../../shared/models/fuzzy_date.dart';
import '../../../shared/models/timeline_event.dart';
import '../../media/widgets/fuzzy_date_picker.dart';

/// Dialog for creating quick text-only timeline entries
class QuickEntryDialog extends StatefulWidget {
  final ContextType contextType;
  final List<String> tags;
  final String ownerId;
  final Function(TimelineEvent) onEventCreated;

  const QuickEntryDialog({
    super.key,
    required this.contextType,
    required this.tags,
    required this.ownerId,
    required this.onEventCreated,
  });

  @override
  State<QuickEntryDialog> createState() => _QuickEntryDialogState();
}

class _QuickEntryDialogState extends State<QuickEntryDialog> {
  final _titleController = TextEditingController();
  final _quillController = QuillController.basic();
  
  DateTime? _selectedDateTime;
  FuzzyDate? _selectedFuzzyDate;
  bool _usePreciseDate = true;
  bool _isCreating = false;

  @override
  void initState() {
    super.initState();
    // Default to current date/time
    _selectedDateTime = DateTime.now();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _quillController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.8,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            const SizedBox(height: 24),
            _buildTitleField(),
            const SizedBox(height: 16),
            _buildDateSelector(),
            const SizedBox(height: 16),
            _buildStoryEditor(),
            const SizedBox(height: 24),
            _buildActions(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        Icon(
          Icons.edit_note,
          color: Theme.of(context).colorScheme.primary,
          size: 28,
        ),
        const SizedBox(width: 12),
        Text(
          'Quick Entry',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const Spacer(),
        IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }

  Widget _buildTitleField() {
    return TextFormField(
      controller: _titleController,
      decoration: const InputDecoration(
        labelText: 'Title (optional)',
        hintText: 'Give your entry a title...',
        border: OutlineInputBorder(),
      ),
      textCapitalization: TextCapitalization.sentences,
    );
  }

  Widget _buildDateSelector() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'When did this happen?',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            
            // Date type selector
            Row(
              children: [
                Expanded(
                  child: RadioListTile<bool>(
                    title: const Text('Precise Date & Time'),
                    value: true,
                    groupValue: _usePreciseDate,
                    onChanged: (value) {
                      setState(() {
                        _usePreciseDate = value!;
                        if (_usePreciseDate) {
                          _selectedFuzzyDate = null;
                        } else {
                          _selectedDateTime = null;
                        }
                      });
                    },
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                Expanded(
                  child: RadioListTile<bool>(
                    title: const Text('Fuzzy Date'),
                    value: false,
                    groupValue: _usePreciseDate,
                    onChanged: (value) {
                      setState(() {
                        _usePreciseDate = !value!;
                        if (_usePreciseDate) {
                          _selectedFuzzyDate = null;
                        } else {
                          _selectedDateTime = null;
                        }
                      });
                    },
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Date input based on selection
            if (_usePreciseDate) 
              _buildPreciseDatePicker()
            else
              _buildFuzzyDatePicker(),
          ],
        ),
      ),
    );
  }

  Widget _buildPreciseDatePicker() {
    return Column(
      children: [
        // Date picker
        ListTile(
          leading: const Icon(Icons.calendar_today),
          title: Text(
            _selectedDateTime != null
                ? '${_selectedDateTime!.day}/${_selectedDateTime!.month}/${_selectedDateTime!.year}'
                : 'Select date',
          ),
          trailing: const Icon(Icons.arrow_drop_down),
          onTap: () async {
            final date = await showDatePicker(
              context: context,
              initialDate: _selectedDateTime ?? DateTime.now(),
              firstDate: DateTime(1900),
              lastDate: DateTime.now().add(const Duration(days: 365)),
            );
            if (date != null) {
              setState(() {
                _selectedDateTime = DateTime(
                  date.year,
                  date.month,
                  date.day,
                  _selectedDateTime?.hour ?? DateTime.now().hour,
                  _selectedDateTime?.minute ?? DateTime.now().minute,
                );
              });
            }
          },
          contentPadding: EdgeInsets.zero,
        ),
        
        // Time picker
        ListTile(
          leading: const Icon(Icons.access_time),
          title: Text(
            _selectedDateTime != null
                ? '${_selectedDateTime!.hour.toString().padLeft(2, '0')}:${_selectedDateTime!.minute.toString().padLeft(2, '0')}'
                : 'Select time',
          ),
          trailing: const Icon(Icons.arrow_drop_down),
          onTap: () async {
            final time = await showTimePicker(
              context: context,
              initialTime: _selectedDateTime != null
                  ? TimeOfDay.fromDateTime(_selectedDateTime!)
                  : TimeOfDay.now(),
            );
            if (time != null) {
              setState(() {
                final now = _selectedDateTime ?? DateTime.now();
                _selectedDateTime = DateTime(
                  now.year,
                  now.month,
                  now.day,
                  time.hour,
                  time.minute,
                );
              });
            }
          },
          contentPadding: EdgeInsets.zero,
        ),
      ],
    );
  }

  Widget _buildFuzzyDatePicker() {
    return FuzzyDatePicker(
      contextType: widget.contextType,
      initialDate: _selectedFuzzyDate,
      onDateChanged: (fuzzyDate) {
        setState(() {
          _selectedFuzzyDate = fuzzyDate;
        });
      },
    );
  }

  Widget _buildStoryEditor() {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your Story',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          
          // Quill toolbar
          QuillSimpleToolbar(
            configurations: QuillSimpleToolbarConfigurations(
              controller: _quillController,
              showFontFamily: false,
              showFontSize: false,
              showSearchButton: false,
              showSubscript: false,
              showSuperscript: false,
            ),
          ),
          
          const SizedBox(height: 8),
          
          // Quill editor
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: Theme.of(context).colorScheme.outline),
                borderRadius: BorderRadius.circular(8),
              ),
              child: QuillEditor.basic(
                configurations: QuillEditorConfigurations(
                  controller: _quillController,
                  sharedConfigurations: const QuillSharedConfigurations(
                    locale: Locale('en'),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActions(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        const SizedBox(width: 12),
        ElevatedButton(
          onPressed: _canCreateEntry() ? _createEntry : null,
          child: _isCreating
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Create Entry'),
        ),
      ],
    );
  }

  bool _canCreateEntry() {
    if (_isCreating) return false;
    
    // Must have either precise date or fuzzy date
    final hasValidDate = _usePreciseDate 
        ? _selectedDateTime != null
        : _selectedFuzzyDate != null;
    
    // Must have some content in the story
    final hasContent = _quillController.document.toPlainText().trim().isNotEmpty;
    
    return hasValidDate && hasContent;
  }

  Future<void> _createEntry() async {
    if (!_canCreateEntry()) return;
    
    setState(() {
      _isCreating = true;
    });

    try {
      // Get the story content as plain text for now
      // In a full implementation, you'd want to preserve rich text formatting
      final storyText = _quillController.document.toPlainText().trim();
      
      // Determine timestamp
      final timestamp = _usePreciseDate 
          ? _selectedDateTime!
          : _selectedFuzzyDate!.toApproximateDateTime();
      
      // Create the timeline event
      final event = TimelineEvent.create(
        id: 'quick_${DateTime.now().millisecondsSinceEpoch}',
        tags: widget.tags,
        ownerId: widget.ownerId,
        timestamp: timestamp,
        fuzzyDate: _usePreciseDate ? null : _selectedFuzzyDate,
        eventType: 'text',
        title: _titleController.text.trim().isEmpty ? null : _titleController.text.trim(),
        description: storyText,
        assets: [], // No assets for text-only entries
      );

      widget.onEventCreated(event);
      
      if (mounted) {
        Navigator.of(context).pop();
        
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Quick entry created successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating entry: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCreating = false;
        });
      }
    }
  }
}
