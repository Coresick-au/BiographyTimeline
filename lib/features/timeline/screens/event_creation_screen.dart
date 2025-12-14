import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import '../../../shared/models/timeline_event.dart';
import '../../../shared/models/media_asset.dart';
import '../../../shared/models/geo_location.dart';
import '../../../shared/models/user.dart';
import '../services/timeline_data_service.dart';
import '../services/google_maps_location_service.dart';
import 'dart:io';

/// Screen for creating a new timeline event
class EventCreationScreen extends ConsumerStatefulWidget {
  final String? contextId;
  
  const EventCreationScreen({
    super.key,
    this.contextId,
  });

  @override
  ConsumerState<EventCreationScreen> createState() => _EventCreationScreenState();
}

class _EventCreationScreenState extends ConsumerState<EventCreationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _uuid = const Uuid();
  
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  PrivacyLevel _privacyLevel = PrivacyLevel.private;
  String _eventType = 'photo';
  List<XFile> _selectedPhotos = [];
  GeoLocation? _location;
  bool _isLoading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Timeline Event'),
        actions: [
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else
            TextButton(
              onPressed: _saveEvent,
              child: const Text('Save'),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Photo selection
            _buildPhotoSection(),
            const SizedBox(height: 24),
            
            // Title field
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Title',
                hintText: 'Give your event a title',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.title),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a title';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            
            // Description field
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                hintText: 'Describe this moment...',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.description),
              ),
              maxLines: 4,
            ),
            const SizedBox(height: 16),
            
            // Date picker
            _buildDateTimePicker(),
            const SizedBox(height: 16),
            
            // Event type selector
            _buildEventTypeSelector(),
            const SizedBox(height: 16),
            
            // Privacy selector
            _buildPrivacySelector(),
            const SizedBox(height: 16),
            
            // Location (optional)
            _buildLocationSection(),
            const SizedBox(height: 32),
            
            // Save button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _saveEvent,
                icon: const Icon(Icons.save),
                label: Text(_isLoading ? 'Saving...' : 'Create Event'),
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Photos',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                TextButton.icon(
                  onPressed: _pickPhotos,
                  icon: const Icon(Icons.add_photo_alternate),
                  label: const Text('Add Photos'),
                ),
              ],
            ),
            if (_selectedPhotos.isNotEmpty) ...[
              const SizedBox(height: 12),
              SizedBox(
                height: 100,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _selectedPhotos.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: kIsWeb
                                ? Image.network(
                                    _selectedPhotos[index].path,
                                    width: 100,
                                    height: 100,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        width: 100,
                                        height: 100,
                                        color: Colors.grey[300],
                                        child: const Icon(Icons.image, size: 40),
                                      );
                                    },
                                  )
                                : Image.file(
                                    File(_selectedPhotos[index].path),
                                    width: 100,
                                    height: 100,
                                    fit: BoxFit.cover,
                                  ),
                          ),
                          Positioned(
                            top: 4,
                            right: 4,
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedPhotos.removeAt(index);
                                });
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.black54,
                                  shape: BoxShape.circle,
                                ),
                                padding: const EdgeInsets.all(4),
                                child: const Icon(
                                  Icons.close,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ] else
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Center(
                  child: Text(
                    'No photos added yet',
                    style: TextStyle(
                      color: Theme.of(context).textTheme.bodySmall?.color,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateTimePicker() {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.calendar_today),
        title: const Text('Date & Time'),
        subtitle: Text(
          '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year} at ${_selectedTime.format(context)}',
        ),
        trailing: const Icon(Icons.edit),
        onTap: () async {
          // Pick date
          final date = await showDatePicker(
            context: context,
            initialDate: _selectedDate,
            firstDate: DateTime(1900),
            lastDate: DateTime.now().add(const Duration(days: 365)),
          );
          
          if (date != null) {
            // Pick time
            final time = await showTimePicker(
              context: context,
              initialTime: _selectedTime,
            );
            
            if (time != null) {
              setState(() {
                _selectedDate = date;
                _selectedTime = time;
              });
            }
          }
        },
      ),
    );
  }

  Widget _buildEventTypeSelector() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Event Type',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildEventTypeChip('photo', 'Photo', Icons.photo),
                _buildEventTypeChip('text', 'Text Only', Icons.text_fields),
                _buildEventTypeChip('milestone', 'Milestone', Icons.flag),
                _buildEventTypeChip('location', 'Location', Icons.place),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEventTypeChip(String type, String label, IconData icon) {
    final isSelected = _eventType == type;
    return FilterChip(
      selected: isSelected,
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16),
          const SizedBox(width: 4),
          Text(label),
        ],
      ),
      onSelected: (selected) {
        setState(() {
          _eventType = type;
        });
      },
    );
  }

  Widget _buildPrivacySelector() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Privacy',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            ...PrivacyLevel.values.map((level) {
              return RadioListTile<PrivacyLevel>(
                title: Text(_getPrivacyLabel(level)),
                subtitle: Text(_getPrivacyDescription(level)),
                value: level,
                groupValue: _privacyLevel,
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _privacyLevel = value;
                    });
                  }
                },
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationSection() {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.location_on),
        title: const Text('Location'),
        subtitle: _location != null
            ? Text('${_location!.latitude}, ${_location!.longitude}')
            : const Text('No location set'),
        trailing: TextButton(
          onPressed: () async {
            final locationService = GoogleMapsLocationService();
            final location = await locationService.pickLocation(
              context,
              initialLocation: _location,
            );
            
            if (location != null) {
              setState(() {
                _location = location;
              });
            }
          },
          child: const Text('Set'),
        ),
      ),
    );
  }

  String _getPrivacyLabel(PrivacyLevel level) {
    switch (level) {
      case PrivacyLevel.private:
        return 'Private';
      case PrivacyLevel.shared:
        return 'Shared';
      case PrivacyLevel.public:
        return 'Public';
    }
  }

  String _getPrivacyDescription(PrivacyLevel level) {
    switch (level) {
      case PrivacyLevel.private:
        return 'Only you can see this event';
      case PrivacyLevel.shared:
        return 'Share with selected connections';
      case PrivacyLevel.public:
        return 'Anyone can see this event';
    }
  }

  Future<void> _pickPhotos() async {
    final ImagePicker picker = ImagePicker();
    final List<XFile> images = await picker.pickMultiImage();
    
    if (images.isNotEmpty) {
      setState(() {
        _selectedPhotos.addAll(images);
      });
    }
  }

  Future<void> _saveEvent() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Combine date and time
      final timestamp = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedTime.hour,
        _selectedTime.minute,
      );

      // Create media assets from selected photos
      final assets = _selectedPhotos.map((photo) {
        return MediaAsset.photo(
          id: _uuid.v4(),
          eventId: '', // Will be set when event is created
          localPath: photo.path,
          createdAt: DateTime.now(),
        );
      }).toList();

      // Create the event
      final event = TimelineEvent.create(
        id: _uuid.v4(),
        contextId: widget.contextId ?? 'context-1', // Use first context if not specified
        ownerId: 'user-1', // TODO: Get from auth provider
        timestamp: timestamp,
        eventType: _eventType,
        title: _titleController.text,
        description: _descriptionController.text.isEmpty 
            ? null 
            : _descriptionController.text,
        assets: assets,
        location: _location,
        privacyLevel: _privacyLevel,
      );

      // Save to database via service
      await ref.read(timelineDataNotifierProvider.notifier).addEvent(event);

      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Event created successfully!'),
            backgroundColor: Colors.green,
          ),
        );

        // Navigate back
        Navigator.of(context).pop(event);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating event: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
