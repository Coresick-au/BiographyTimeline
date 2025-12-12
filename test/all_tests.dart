/// Comprehensive test suite runner for Users Timeline
/// This file imports and runs all test suites to verify the testing infrastructure
import 'package:flutter_test/flutter_test.dart';

// Import all test suites
import 'test_runner.dart' as test_runner;
import 'serialization_test.dart' as serialization_test;
import 'property_tests/data_model_integrity_property_test.dart' as data_model_integrity;
import 'property_tests/timezone_handling_property_test.dart' as timezone_handling;
import 'property_tests/context_type_selection_property_test.dart' as context_type_selection;
import 'property_tests/context_feature_configuration_property_test.dart' as context_feature_configuration;
import 'property_tests/template_renderer_switching_property_test.dart' as template_renderer_switching;
import 'property_tests/custom_attribute_validation_property_test.dart' as custom_attribute_validation;
import 'property_tests/context_theme_application_property_test.dart' as context_theme_application;

void main() {
  group('Complete Test Suite', () {
    group('Infrastructure Tests', () {
      test_runner.main();
    });

    group('Serialization Tests', () {
      serialization_test.main();
    });

    group('Property-Based Tests', () {
      group('Data Model Integrity', () {
        data_model_integrity.main();
      });

      group('Timezone Handling', () {
        timezone_handling.main();
      });

      group('Context Type Selection', () {
        context_type_selection.main();
      });

      group('Context Feature Configuration', () {
        context_feature_configuration.main();
      });

      group('Template Renderer Switching', () {
        template_renderer_switching.main();
      });

      group('Custom Attribute Validation', () {
        custom_attribute_validation.main();
      });

      group('Context Theme Application', () {
        context_theme_application.main();
      });
    });
  });
}