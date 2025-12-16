import 'package:flutter_test/flutter_test.dart';
import 'package:faker/faker.dart';
import '../../lib/features/media/services/fuzzy_date_service.dart';
import '../../lib/shared/models/fuzzy_date.dart';
import '../../lib/shared/models/context.dart';

void main() {
  group('Fuzzy Date Fallback Property Tests', () {
    late FuzzyDateService fuzzyDateService;
    late Faker faker;

    setUp(() {
      fuzzyDateService = FuzzyDateService();
      faker = Faker();
    });

    test('**Feature: users-timeline, Property 4: Context-Appropriate Fuzzy Date Granularity**', () async {
      // **Validates: Requirements 1.4**
      
      // Property: For any image lacking EXIF timestamp data, the system should 
      // provide manual date entry options with granularity levels appropriate 
      // to the context type

      for (int i = 0; i < 100; i++) {
        // Generate random context type
        final contextType = _generateRandomContextType(faker);
        
        // Get available granularities for this context
        final availableGranularities = fuzzyDateService.getAvailableGranularities(contextType);
        
        // Verify that appropriate granularities are available for each context type
        _verifyContextAppropriateGranularities(contextType, availableGranularities);
        
        // Test that we can create fuzzy dates with each available granularity
        for (final granularity in availableGranularities) {
          final testData = _generateValidFuzzyDateData(faker, granularity);
          
          // Verify that the service can create a fuzzy date with this granularity
          final isValid = fuzzyDateService.isValidFuzzyDateInput(
            granularity: granularity,
            year: testData.year,
            month: testData.month,
            day: testData.day,
            season: testData.season,
          );
          
          expect(isValid, isTrue,
            reason: 'Should accept valid input for $granularity in $contextType context');
          
          if (isValid) {
            try {
              final fuzzyDate = fuzzyDateService.createFuzzyDate(
                granularity: granularity,
                year: testData.year,
                month: testData.month,
                day: testData.day,
                season: testData.season,
              );
              
              // Verify the created fuzzy date has the correct granularity
              expect(fuzzyDate.granularity, equals(granularity),
                reason: 'Created fuzzy date should have the requested granularity');
              
              // Verify the fuzzy date has appropriate display text
              expect(fuzzyDate.toString(), isNotEmpty,
                reason: 'Fuzzy date should have non-empty display text');
              
              // Verify the approximate date is reasonable
              final approximateDate = fuzzyDate.approximateDateTime;
              expect(approximateDate.year, greaterThan(1900),
                reason: 'Approximate date should be reasonable');
              expect(approximateDate.year, lessThanOrEqualTo(DateTime.now().year + 10),
                reason: 'Approximate date should not be too far in the future');
              
            } catch (e) {
              fail('Should be able to create fuzzy date with valid input: $e');
            }
          }
        }
      }
    });

    test('Context-specific granularity restrictions are enforced', () {
      // Test that each context type has appropriate granularity options
      for (final contextType in ContextType.values) {
        final granularities = fuzzyDateService.getAvailableGranularities(contextType);
        
        expect(granularities, isNotEmpty,
          reason: 'Every context type should have at least one granularity option');
        
        // Verify context-specific restrictions
        switch (contextType) {
          case ContextType.person:
            // Personal timelines should have all granularities available
            expect(granularities.length, greaterThanOrEqualTo(4),
              reason: 'Personal context should have comprehensive granularity options');
            break;
          
          case ContextType.pet:
            // Pet timelines should focus on more precise dates
            expect(granularities, contains(FuzzyDateGranularity.day),
              reason: 'Pet context should support precise dates for health tracking');
            expect(granularities, contains(FuzzyDateGranularity.month),
              reason: 'Pet context should support monthly granularity');
            break;
          
          case ContextType.project:
            // Project timelines need precise tracking
            expect(granularities, contains(FuzzyDateGranularity.day),
              reason: 'Project context should support precise dates');
            expect(granularities, contains(FuzzyDateGranularity.month),
              reason: 'Project context should support monthly granularity');
            break;
          
          case ContextType.business:
            // Business timelines focus on quarters and years
            expect(granularities, contains(FuzzyDateGranularity.year),
              reason: 'Business context should support yearly granularity');
            // Season can represent quarters in business context
            expect(granularities, contains(FuzzyDateGranularity.season),
              reason: 'Business context should support seasonal/quarterly granularity');
            break;
        }
      }
    });

    test('Fuzzy date sorting works correctly across granularities', () {
      for (int i = 0; i < 50; i++) {
        // Generate a list of fuzzy dates with different granularities
        final dates = <FuzzyDate>[];
        
        for (int j = 0; j < 10; j++) {
          final granularity = _generateRandomGranularity(faker);
          final testData = _generateValidFuzzyDateData(faker, granularity);
          
          try {
            final fuzzyDate = fuzzyDateService.createFuzzyDate(
              granularity: granularity,
              year: testData.year,
              month: testData.month,
              day: testData.day,
              season: testData.season,
            );
            dates.add(fuzzyDate);
          } catch (e) {
            // Skip invalid dates
            continue;
          }
        }
        
        if (dates.length < 2) continue;
        
        // Sort the dates
        final sortedDates = fuzzyDateService.sortFuzzyDates(dates);
        
        // Verify sorting is chronological
        for (int k = 1; k < sortedDates.length; k++) {
          final previous = sortedDates[k - 1].approximateDateTime;
          final current = sortedDates[k].approximateDateTime;
          
          expect(current.isAfter(previous) || current.isAtSameMomentAs(previous), isTrue,
            reason: 'Sorted fuzzy dates should be in chronological order');
        }
      }
    });

    test('Fuzzy date validation rejects invalid inputs', () {
      // Test various invalid inputs
      final invalidCases = [
        // Invalid year
        _FuzzyDateTestData(
          granularity: FuzzyDateGranularity.year,
          year: 1800, // Too old
        ),
        _FuzzyDateTestData(
          granularity: FuzzyDateGranularity.year,
          year: 2050, // Too far in future
        ),
        
        // Invalid month
        _FuzzyDateTestData(
          granularity: FuzzyDateGranularity.month,
          year: 2023,
          month: 13, // Invalid month
        ),
        _FuzzyDateTestData(
          granularity: FuzzyDateGranularity.month,
          year: 2023,
          month: 0, // Invalid month
        ),
        
        // Invalid day
        _FuzzyDateTestData(
          granularity: FuzzyDateGranularity.day,
          year: 2023,
          month: 2,
          day: 30, // February doesn't have 30 days
        ),
        
        // Missing required fields
        _FuzzyDateTestData(
          granularity: FuzzyDateGranularity.month,
          year: 2023,
          // Missing month
        ),
        _FuzzyDateTestData(
          granularity: FuzzyDateGranularity.season,
          year: 2023,
          // Missing season
        ),
      ];

      for (final testCase in invalidCases) {
        final isValid = fuzzyDateService.isValidFuzzyDateInput(
          granularity: testCase.granularity,
          year: testCase.year,
          month: testCase.month,
          day: testCase.day,
          season: testCase.season,
        );
        
        expect(isValid, isFalse,
          reason: 'Should reject invalid fuzzy date input: ${testCase.granularity}');
      }
    });
  });
}

class _FuzzyDateTestData {
  final FuzzyDateGranularity granularity;
  final int? year;
  final int? month;
  final int? day;
  final Season? season;

  _FuzzyDateTestData({
    required this.granularity,
    this.year,
    this.month,
    this.day,
    this.season,
  });
}

ContextType _generateRandomContextType(Faker faker) {
  return faker.randomGenerator.element(ContextType.values);
}

FuzzyDateGranularity _generateRandomGranularity(Faker faker) {
  return faker.randomGenerator.element(FuzzyDateGranularity.values);
}

_FuzzyDateTestData _generateValidFuzzyDateData(Faker faker, FuzzyDateGranularity granularity) {
  final currentYear = DateTime.now().year;
  // Generate a year within a reasonable range (1950 to current year + 10)
  final minYear = 1950;
  final maxYear = currentYear + 10;
  final year = faker.randomGenerator.integer(maxYear - minYear) + minYear;
  
  switch (granularity) {
    case FuzzyDateGranularity.decade:
      return _FuzzyDateTestData(
        granularity: granularity,
        year: year,
      );
    
    case FuzzyDateGranularity.year:
      return _FuzzyDateTestData(
        granularity: granularity,
        year: year,
      );
    
    case FuzzyDateGranularity.season:
      return _FuzzyDateTestData(
        granularity: granularity,
        year: year,
        season: faker.randomGenerator.element(Season.values),
      );
    
    case FuzzyDateGranularity.month:
      return _FuzzyDateTestData(
        granularity: granularity,
        year: year,
        month: faker.randomGenerator.integer(12, min: 1),
      );
    
    case FuzzyDateGranularity.day:
      final month = faker.randomGenerator.integer(12, min: 1);
      final daysInMonth = DateTime(year, month + 1, 0).day;
      final day = faker.randomGenerator.integer(daysInMonth, min: 1);
      
      return _FuzzyDateTestData(
        granularity: granularity,
        year: year,
        month: month,
        day: day,
      );
  }
}

void _verifyContextAppropriateGranularities(ContextType contextType, List<FuzzyDateGranularity> granularities) {
  expect(granularities, isNotEmpty,
    reason: 'Context $contextType should have at least one granularity option');
  
  // Verify that granularities are appropriate for the context
  switch (contextType) {
    case ContextType.person:
      // Personal context should have comprehensive options
      expect(granularities.length, greaterThanOrEqualTo(3),
        reason: 'Personal context should have multiple granularity options');
      break;
    
    case ContextType.pet:
      // Pet context should focus on health-relevant precision
      expect(granularities, contains(FuzzyDateGranularity.day),
        reason: 'Pet context should support daily precision for health tracking');
      break;
    
    case ContextType.project:
      // Project context should support precise tracking
      expect(granularities, contains(FuzzyDateGranularity.day),
        reason: 'Project context should support daily precision for project management');
      break;
    
    case ContextType.business:
      // Business context should focus on business-relevant periods
      expect(granularities, contains(FuzzyDateGranularity.year),
        reason: 'Business context should support yearly granularity');
      break;
  }
}
