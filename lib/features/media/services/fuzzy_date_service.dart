import '../../../shared/models/fuzzy_date.dart';
import '../../../shared/models/context.dart';

/// Service for managing fuzzy dates and providing context-appropriate granularity options
class FuzzyDateService {
  
  /// Gets appropriate fuzzy date granularity options based on context type
  List<FuzzyDateGranularity> getAvailableGranularities(ContextType contextType) {
    switch (contextType) {
      case ContextType.person:
        // Personal timelines benefit from all granularities
        return [
          FuzzyDateGranularity.day,
          FuzzyDateGranularity.month,
          FuzzyDateGranularity.season,
          FuzzyDateGranularity.year,
          FuzzyDateGranularity.decade,
        ];
      
      case ContextType.pet:
        // Pet timelines focus on more precise dates for health tracking
        return [
          FuzzyDateGranularity.day,
          FuzzyDateGranularity.month,
          FuzzyDateGranularity.season,
          FuzzyDateGranularity.year,
        ];
      
      case ContextType.project:
        // Project timelines need precise tracking
        return [
          FuzzyDateGranularity.day,
          FuzzyDateGranularity.month,
          FuzzyDateGranularity.year,
        ];
      
      case ContextType.business:
        // Business timelines focus on quarters and years
        return [
          FuzzyDateGranularity.month,
          FuzzyDateGranularity.season, // Can represent quarters
          FuzzyDateGranularity.year,
        ];
    }
  }

  /// Creates a fuzzy date from user input
  FuzzyDate createFuzzyDate({
    required FuzzyDateGranularity granularity,
    int? year,
    int? month,
    int? day,
    Season? season,
  }) {
    switch (granularity) {
      case FuzzyDateGranularity.decade:
        if (year == null) throw ArgumentError('Year is required for decade granularity');
        final decadeStart = (year ~/ 10) * 10;
        return FuzzyDate.decade(decadeStart);
      
      case FuzzyDateGranularity.year:
        if (year == null) throw ArgumentError('Year is required for year granularity');
        return FuzzyDate.year(year);
      
      case FuzzyDateGranularity.season:
        if (year == null || season == null) {
          throw ArgumentError('Year and season are required for season granularity');
        }
        return FuzzyDate.season(year, season);
      
      case FuzzyDateGranularity.month:
        if (year == null || month == null) {
          throw ArgumentError('Year and month are required for month granularity');
        }
        return FuzzyDate.month(year, month);
      
      case FuzzyDateGranularity.day:
        if (year == null || month == null || day == null) {
          throw ArgumentError('Year, month, and day are required for day granularity');
        }
        return FuzzyDate(
          year: year,
          month: month,
          day: day,
          granularity: FuzzyDateGranularity.day,
          displayText: '${_getMonthName(month)} $day, $year',
        );
    }
  }

  /// Converts a precise DateTime to a fuzzy date with specified granularity
  FuzzyDate dateTimeToFuzzyDate(DateTime dateTime, FuzzyDateGranularity granularity) {
    switch (granularity) {
      case FuzzyDateGranularity.decade:
        final decadeStart = (dateTime.year ~/ 10) * 10;
        return FuzzyDate.decade(decadeStart);
      
      case FuzzyDateGranularity.year:
        return FuzzyDate.year(dateTime.year);
      
      case FuzzyDateGranularity.season:
        final season = _getSeasonFromMonth(dateTime.month);
        return FuzzyDate.season(dateTime.year, season);
      
      case FuzzyDateGranularity.month:
        return FuzzyDate.month(dateTime.year, dateTime.month);
      
      case FuzzyDateGranularity.day:
        return FuzzyDate(
          year: dateTime.year,
          month: dateTime.month,
          day: dateTime.day,
          granularity: FuzzyDateGranularity.day,
          displayText: '${_getMonthName(dateTime.month)} ${dateTime.day}, ${dateTime.year}',
        );
    }
  }

  /// Sorts a list of fuzzy dates chronologically
  List<FuzzyDate> sortFuzzyDates(List<FuzzyDate> dates) {
    final sortedDates = List<FuzzyDate>.from(dates);
    sortedDates.sort((a, b) => a.approximateDateTime.compareTo(b.approximateDateTime));
    return sortedDates;
  }

  /// Checks if a fuzzy date falls within a date range
  bool isWithinRange(FuzzyDate fuzzyDate, DateTime start, DateTime end) {
    final approximateDate = fuzzyDate.approximateDateTime;
    return approximateDate.isAfter(start.subtract(const Duration(days: 1))) &&
           approximateDate.isBefore(end.add(const Duration(days: 1)));
  }

  /// Gets display text for granularity options
  String getGranularityDisplayName(FuzzyDateGranularity granularity) {
    switch (granularity) {
      case FuzzyDateGranularity.day:
        return 'Specific Date';
      case FuzzyDateGranularity.month:
        return 'Month & Year';
      case FuzzyDateGranularity.season:
        return 'Season & Year';
      case FuzzyDateGranularity.year:
        return 'Year Only';
      case FuzzyDateGranularity.decade:
        return 'Decade';
    }
  }

  /// Gets the season from a month number (1-12)
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

  /// Gets month name from month number
  String _getMonthName(int month) {
    const monthNames = [
      '', 'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    
    if (month < 1 || month > 12) {
      throw ArgumentError('Invalid month: $month');
    }
    
    return monthNames[month];
  }

  /// Validates fuzzy date input
  bool isValidFuzzyDateInput({
    required FuzzyDateGranularity granularity,
    int? year,
    int? month,
    int? day,
    Season? season,
  }) {
    // Check year validity
    if (year != null && (year < 1900 || year > DateTime.now().year + 10)) {
      return false;
    }

    // Check month validity
    if (month != null && (month < 1 || month > 12)) {
      return false;
    }

    // Check day validity
    if (day != null && year != null && month != null) {
      final daysInMonth = DateTime(year, month + 1, 0).day;
      if (day < 1 || day > daysInMonth) {
        return false;
      }
    }

    // Check required fields for each granularity
    switch (granularity) {
      case FuzzyDateGranularity.decade:
      case FuzzyDateGranularity.year:
        return year != null;
      
      case FuzzyDateGranularity.season:
        return year != null && season != null;
      
      case FuzzyDateGranularity.month:
        return year != null && month != null;
      
      case FuzzyDateGranularity.day:
        return year != null && month != null && day != null;
    }
  }
}
