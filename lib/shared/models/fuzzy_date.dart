import 'package:json_annotation/json_annotation.dart';

part 'fuzzy_date.g.dart';

@JsonSerializable()
class FuzzyDate {
  final int? year;
  final int? month;
  final int? day;
  final FuzzyDateGranularity granularity;
  final String? displayText;

  const FuzzyDate({
    this.year,
    this.month,
    this.day,
    required this.granularity,
    this.displayText,
  });

  factory FuzzyDate.fromJson(Map<String, dynamic> json) =>
      _$FuzzyDateFromJson(json);
  Map<String, dynamic> toJson() => _$FuzzyDateToJson(this);

  /// Creates a fuzzy date for a specific year
  factory FuzzyDate.year(int year) {
    return FuzzyDate(
      year: year,
      granularity: FuzzyDateGranularity.year,
      displayText: year.toString(),
    );
  }

  /// Creates a fuzzy date for a season in a year
  factory FuzzyDate.season(int year, Season season) {
    return FuzzyDate(
      year: year,
      granularity: FuzzyDateGranularity.season,
      displayText: '${season.displayName} $year',
    );
  }

  /// Creates a fuzzy date for a decade
  factory FuzzyDate.decade(int startYear) {
    final endYear = startYear + 9;
    return FuzzyDate(
      year: startYear,
      granularity: FuzzyDateGranularity.decade,
      displayText: '${startYear}s',
    );
  }

  /// Creates a fuzzy date for a month in a year
  factory FuzzyDate.month(int year, int month) {
    return FuzzyDate(
      year: year,
      month: month,
      granularity: FuzzyDateGranularity.month,
    );
  }

  /// Gets the approximate DateTime for sorting purposes
  DateTime get approximateDateTime {
    switch (granularity) {
      case FuzzyDateGranularity.decade:
        return DateTime(year ?? 1970, 1, 1);
      case FuzzyDateGranularity.year:
        return DateTime(year ?? 1970, 6, 15); // Mid-year
      case FuzzyDateGranularity.season:
        final seasonMonth = _getSeasonMonth();
        return DateTime(year ?? 1970, seasonMonth, 15);
      case FuzzyDateGranularity.month:
        return DateTime(year ?? 1970, month ?? 1, 15); // Mid-month
      case FuzzyDateGranularity.day:
        return DateTime(year ?? 1970, month ?? 1, day ?? 1);
    }
  }

  /// Converts fuzzy date to approximate DateTime for timeline events
  DateTime toApproximateDateTime() {
    return approximateDateTime;
  }

  int _getSeasonMonth() {
    // This is a simplified approach - in reality, we'd need more context
    // about which season this represents
    return 6; // Default to summer
  }

  FuzzyDate copyWith({
    int? year,
    int? month,
    int? day,
    FuzzyDateGranularity? granularity,
    String? displayText,
  }) {
    return FuzzyDate(
      year: year ?? this.year,
      month: month ?? this.month,
      day: day ?? this.day,
      granularity: granularity ?? this.granularity,
      displayText: displayText ?? this.displayText,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FuzzyDate &&
          runtimeType == other.runtimeType &&
          year == other.year &&
          month == other.month &&
          day == other.day &&
          granularity == other.granularity &&
          displayText == other.displayText;

  @override
  int get hashCode =>
      year.hashCode ^
      month.hashCode ^
      day.hashCode ^
      granularity.hashCode ^
      displayText.hashCode;

  @override
  String toString() {
    return displayText ?? 'Unknown date';
  }
}

enum FuzzyDateGranularity {
  @JsonValue('decade')
  decade,
  @JsonValue('year')
  year,
  @JsonValue('season')
  season,
  @JsonValue('month')
  month,
  @JsonValue('day')
  day,
}

enum Season {
  @JsonValue('spring')
  spring,
  @JsonValue('summer')
  summer,
  @JsonValue('fall')
  fall,
  @JsonValue('winter')
  winter;

  String get displayName {
    switch (this) {
      case Season.spring:
        return 'Spring';
      case Season.summer:
        return 'Summer';
      case Season.fall:
        return 'Fall';
      case Season.winter:
        return 'Winter';
    }
  }
}
