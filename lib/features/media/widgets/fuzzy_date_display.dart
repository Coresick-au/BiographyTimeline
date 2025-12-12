import 'package:flutter/material.dart';
import '../../../shared/models/fuzzy_date.dart';

/// Widget for displaying fuzzy dates with appropriate visual styling
class FuzzyDateDisplay extends StatelessWidget {
  final FuzzyDate fuzzyDate;
  final TextStyle? style;
  final bool showGranularityIndicator;
  final bool showTooltip;

  const FuzzyDateDisplay({
    super.key,
    required this.fuzzyDate,
    this.style,
    this.showGranularityIndicator = false,
    this.showTooltip = true,
  });

  @override
  Widget build(BuildContext context) {
    final displayText = fuzzyDate.toString();
    final granularityIcon = _getGranularityIcon();
    
    Widget content = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showGranularityIndicator && granularityIcon != null) ...[
          Icon(
            granularityIcon,
            size: 16,
            color: _getGranularityColor(context),
          ),
          const SizedBox(width: 4),
        ],
        Text(
          displayText,
          style: style ?? Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: _getTextColor(context),
          ),
        ),
      ],
    );

    if (showTooltip) {
      content = Tooltip(
        message: _getTooltipMessage(),
        child: content,
      );
    }

    return content;
  }

  IconData? _getGranularityIcon() {
    switch (fuzzyDate.granularity) {
      case FuzzyDateGranularity.day:
        return Icons.today;
      case FuzzyDateGranularity.month:
        return Icons.calendar_month;
      case FuzzyDateGranularity.season:
        return Icons.nature;
      case FuzzyDateGranularity.year:
        return Icons.calendar_view_year;
      case FuzzyDateGranularity.decade:
        return Icons.history;
    }
  }

  Color _getGranularityColor(BuildContext context) {
    switch (fuzzyDate.granularity) {
      case FuzzyDateGranularity.day:
        return Theme.of(context).colorScheme.primary;
      case FuzzyDateGranularity.month:
        return Theme.of(context).colorScheme.secondary;
      case FuzzyDateGranularity.season:
        return Theme.of(context).colorScheme.tertiary;
      case FuzzyDateGranularity.year:
        return Theme.of(context).colorScheme.outline;
      case FuzzyDateGranularity.decade:
        return Theme.of(context).colorScheme.outlineVariant;
    }
  }

  Color _getTextColor(BuildContext context) {
    // Use different opacity based on granularity to indicate uncertainty
    final baseColor = Theme.of(context).colorScheme.onSurface;
    
    switch (fuzzyDate.granularity) {
      case FuzzyDateGranularity.day:
        return baseColor; // Full opacity for precise dates
      case FuzzyDateGranularity.month:
        return baseColor.withOpacity(0.9);
      case FuzzyDateGranularity.season:
        return baseColor.withOpacity(0.8);
      case FuzzyDateGranularity.year:
        return baseColor.withOpacity(0.7);
      case FuzzyDateGranularity.decade:
        return baseColor.withOpacity(0.6); // Lower opacity for uncertain dates
    }
  }

  String _getTooltipMessage() {
    final granularityName = _getGranularityDisplayName();
    return 'Date precision: $granularityName';
  }

  String _getGranularityDisplayName() {
    switch (fuzzyDate.granularity) {
      case FuzzyDateGranularity.day:
        return 'Exact date';
      case FuzzyDateGranularity.month:
        return 'Month and year';
      case FuzzyDateGranularity.season:
        return 'Season and year';
      case FuzzyDateGranularity.year:
        return 'Year only';
      case FuzzyDateGranularity.decade:
        return 'Decade';
    }
  }
}

/// Widget for displaying a list of fuzzy dates in chronological order
class FuzzyDateTimeline extends StatelessWidget {
  final List<FuzzyDate> dates;
  final Function(FuzzyDate)? onDateTap;

  const FuzzyDateTimeline({
    super.key,
    required this.dates,
    this.onDateTap,
  });

  @override
  Widget build(BuildContext context) {
    // Sort dates chronologically
    final sortedDates = List<FuzzyDate>.from(dates);
    sortedDates.sort((a, b) => a.approximateDateTime.compareTo(b.approximateDateTime));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: sortedDates.map((date) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0),
          child: InkWell(
            onTap: onDateTap != null ? () => onDateTap!(date) : null,
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: FuzzyDateDisplay(
                fuzzyDate: date,
                showGranularityIndicator: true,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

/// Widget for comparing two fuzzy dates
class FuzzyDateComparison extends StatelessWidget {
  final FuzzyDate? beforeDate;
  final FuzzyDate? afterDate;
  final String beforeLabel;
  final String afterLabel;

  const FuzzyDateComparison({
    super.key,
    this.beforeDate,
    this.afterDate,
    this.beforeLabel = 'Before',
    this.afterLabel = 'After',
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Date Comparison',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        beforeLabel,
                        style: Theme.of(context).textTheme.labelMedium,
                      ),
                      const SizedBox(height: 4),
                      beforeDate != null
                          ? FuzzyDateDisplay(
                              fuzzyDate: beforeDate!,
                              showGranularityIndicator: true,
                            )
                          : Text(
                              'Not set',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Theme.of(context).colorScheme.outline,
                              ),
                            ),
                    ],
                  ),
                ),
                
                const SizedBox(width: 16),
                Icon(
                  Icons.arrow_forward,
                  color: Theme.of(context).colorScheme.outline,
                ),
                const SizedBox(width: 16),
                
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        afterLabel,
                        style: Theme.of(context).textTheme.labelMedium,
                      ),
                      const SizedBox(height: 4),
                      afterDate != null
                          ? FuzzyDateDisplay(
                              fuzzyDate: afterDate!,
                              showGranularityIndicator: true,
                            )
                          : Text(
                              'Not set',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Theme.of(context).colorScheme.outline,
                              ),
                            ),
                    ],
                  ),
                ),
              ],
            ),
            
            if (beforeDate != null && afterDate != null) ...[
              const SizedBox(height: 12),
              _buildComparisonSummary(context),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildComparisonSummary(BuildContext context) {
    final before = beforeDate!.approximateDateTime;
    final after = afterDate!.approximateDateTime;
    final difference = after.difference(before);
    
    String summaryText;
    if (difference.inDays > 365) {
      final years = (difference.inDays / 365).round();
      summaryText = 'Approximately $years year${years != 1 ? 's' : ''} apart';
    } else if (difference.inDays > 30) {
      final months = (difference.inDays / 30).round();
      summaryText = 'Approximately $months month${months != 1 ? 's' : ''} apart';
    } else if (difference.inDays > 0) {
      summaryText = '${difference.inDays} day${difference.inDays != 1 ? 's' : ''} apart';
    } else {
      summaryText = 'Same approximate time period';
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            size: 16,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 8),
          Text(
            summaryText,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}