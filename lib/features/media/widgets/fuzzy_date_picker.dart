import 'package:flutter/material.dart';
import '../../../shared/models/fuzzy_date.dart';
import '../../../shared/models/context.dart';
import '../services/fuzzy_date_service.dart';

/// Widget for selecting fuzzy dates with context-appropriate granularity options
class FuzzyDatePicker extends StatefulWidget {
  final ContextType contextType;
  final FuzzyDate? initialDate;
  final Function(FuzzyDate?) onDateChanged;
  final String? label;

  const FuzzyDatePicker({
    super.key,
    required this.contextType,
    required this.onDateChanged,
    this.initialDate,
    this.label,
  });

  @override
  State<FuzzyDatePicker> createState() => _FuzzyDatePickerState();
}

class _FuzzyDatePickerState extends State<FuzzyDatePicker> {
  late FuzzyDateService _fuzzyDateService;
  late List<FuzzyDateGranularity> _availableGranularities;
  
  FuzzyDateGranularity? _selectedGranularity;
  int? _selectedYear;
  int? _selectedMonth;
  int? _selectedDay;
  Season? _selectedSeason;

  @override
  void initState() {
    super.initState();
    _fuzzyDateService = FuzzyDateService();
    _availableGranularities = _fuzzyDateService.getAvailableGranularities(widget.contextType);
    
    // Initialize with existing date if provided
    if (widget.initialDate != null) {
      _initializeFromExistingDate(widget.initialDate!);
    } else {
      // Default to most precise granularity available
      _selectedGranularity = _availableGranularities.first;
    }
  }

  void _initializeFromExistingDate(FuzzyDate date) {
    _selectedGranularity = date.granularity;
    _selectedYear = date.year;
    _selectedMonth = date.month;
    _selectedDay = date.day;
    
    // Determine season from month if needed
    if (date.granularity == FuzzyDateGranularity.season && date.month != null) {
      _selectedSeason = _getSeasonFromMonth(date.month!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.label != null) ...[
              Text(
                widget.label!,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 16),
            ],
            
            // Granularity selector
            _buildGranularitySelector(),
            
            const SizedBox(height: 16),
            
            // Date input fields based on selected granularity
            if (_selectedGranularity != null) ...[
              _buildDateInputFields(),
              const SizedBox(height: 16),
              _buildPreview(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildGranularitySelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Date Precision',
          style: Theme.of(context).textTheme.labelLarge,
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: _availableGranularities.map((granularity) {
            return ChoiceChip(
              label: Text(_fuzzyDateService.getGranularityDisplayName(granularity)),
              selected: _selectedGranularity == granularity,
              onSelected: (selected) {
                if (selected) {
                  setState(() {
                    _selectedGranularity = granularity;
                    _clearDateFields();
                  });
                }
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildDateInputFields() {
    switch (_selectedGranularity!) {
      case FuzzyDateGranularity.decade:
        return _buildYearInput(label: 'Year (for decade)');
      
      case FuzzyDateGranularity.year:
        return _buildYearInput();
      
      case FuzzyDateGranularity.season:
        return Column(
          children: [
            _buildYearInput(),
            const SizedBox(height: 12),
            _buildSeasonSelector(),
          ],
        );
      
      case FuzzyDateGranularity.month:
        return Column(
          children: [
            _buildYearInput(),
            const SizedBox(height: 12),
            _buildMonthSelector(),
          ],
        );
      
      case FuzzyDateGranularity.day:
        return Column(
          children: [
            _buildYearInput(),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _buildMonthSelector()),
                const SizedBox(width: 12),
                Expanded(child: _buildDaySelector()),
              ],
            ),
          ],
        );
    }
  }

  Widget _buildYearInput({String label = 'Year'}) {
    return TextFormField(
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      keyboardType: TextInputType.number,
      initialValue: _selectedYear?.toString(),
      onChanged: (value) {
        setState(() {
          _selectedYear = int.tryParse(value);
          _updateFuzzyDate();
        });
      },
    );
  }

  Widget _buildMonthSelector() {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];

    return DropdownButtonFormField<int>(
      decoration: const InputDecoration(
        labelText: 'Month',
        border: OutlineInputBorder(),
      ),
      value: _selectedMonth,
      items: months.asMap().entries.map((entry) {
        return DropdownMenuItem<int>(
          value: entry.key + 1,
          child: Text(entry.value),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          _selectedMonth = value;
          _selectedDay = null; // Reset day when month changes
          _updateFuzzyDate();
        });
      },
    );
  }

  Widget _buildDaySelector() {
    final daysInMonth = _selectedYear != null && _selectedMonth != null
        ? DateTime(_selectedYear!, _selectedMonth! + 1, 0).day
        : 31;

    return DropdownButtonFormField<int>(
      decoration: const InputDecoration(
        labelText: 'Day',
        border: OutlineInputBorder(),
      ),
      value: _selectedDay,
      items: List.generate(daysInMonth, (index) {
        final day = index + 1;
        return DropdownMenuItem<int>(
          value: day,
          child: Text(day.toString()),
        );
      }),
      onChanged: (value) {
        setState(() {
          _selectedDay = value;
          _updateFuzzyDate();
        });
      },
    );
  }

  Widget _buildSeasonSelector() {
    return DropdownButtonFormField<Season>(
      decoration: const InputDecoration(
        labelText: 'Season',
        border: OutlineInputBorder(),
      ),
      value: _selectedSeason,
      items: Season.values.map((season) {
        return DropdownMenuItem<Season>(
          value: season,
          child: Text(season.displayName),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          _selectedSeason = value;
          _updateFuzzyDate();
        });
      },
    );
  }

  Widget _buildPreview() {
    if (!_isValidInput()) {
      return const SizedBox.shrink();
    }

    try {
      final fuzzyDate = _createFuzzyDate();
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceVariant,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(
              Icons.preview,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 8),
            Text(
              'Preview: ${fuzzyDate.toString()}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    } catch (e) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.errorContainer,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(
              Icons.error_outline,
              color: Theme.of(context).colorScheme.onErrorContainer,
            ),
            const SizedBox(width: 8),
            Text(
              'Invalid date input',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onErrorContainer,
              ),
            ),
          ],
        ),
      );
    }
  }

  void _clearDateFields() {
    _selectedYear = null;
    _selectedMonth = null;
    _selectedDay = null;
    _selectedSeason = null;
    _updateFuzzyDate();
  }

  void _updateFuzzyDate() {
    if (_isValidInput()) {
      try {
        final fuzzyDate = _createFuzzyDate();
        widget.onDateChanged(fuzzyDate);
      } catch (e) {
        widget.onDateChanged(null);
      }
    } else {
      widget.onDateChanged(null);
    }
  }

  bool _isValidInput() {
    return _fuzzyDateService.isValidFuzzyDateInput(
      granularity: _selectedGranularity!,
      year: _selectedYear,
      month: _selectedMonth,
      day: _selectedDay,
      season: _selectedSeason,
    );
  }

  FuzzyDate _createFuzzyDate() {
    return _fuzzyDateService.createFuzzyDate(
      granularity: _selectedGranularity!,
      year: _selectedYear,
      month: _selectedMonth,
      day: _selectedDay,
      season: _selectedSeason,
    );
  }

  Season _getSeasonFromMonth(int month) {
    switch (month) {
      case 12:
      case 1:
      case 2:
        return Season.winter;
      case 3:
      case 4:
      case 5:
        return Season.spring;
      case 6:
      case 7:
      case 8:
        return Season.summer;
      case 9:
      case 10:
      case 11:
        return Season.fall;
      default:
        throw ArgumentError('Invalid month: $month');
    }
  }
}
