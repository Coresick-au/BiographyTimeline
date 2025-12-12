/// Verification script for code generation and testing infrastructure
/// Run this to verify that all generated code and tests are working correctly

import 'dart:io';

void main() {
  print('🔍 Verifying Users Timeline Code Generation and Testing Setup...\n');

  // Check for required generated files
  final requiredGeneratedFiles = [
    'lib/shared/models/context.g.dart',
    'lib/shared/models/timeline_event.g.dart',
    'lib/shared/models/timeline_theme.g.dart',
    'lib/shared/models/user.g.dart',
    'lib/shared/models/fuzzy_date.g.dart',
    'lib/shared/models/geo_location.g.dart',
    'lib/shared/models/exif_data.g.dart',
    'lib/shared/models/media_asset.g.dart',
    'lib/shared/models/story.g.dart',
    'lib/shared/models/relationship.g.dart',
  ];

  print('📁 Checking generated files...');
  bool allGeneratedFilesExist = true;
  for (final filePath in requiredGeneratedFiles) {
    final file = File(filePath);
    if (file.existsSync()) {
      print('  ✅ $filePath');
    } else {
      print('  ❌ $filePath (missing)');
      allGeneratedFilesExist = false;
    }
  }

  // Check for test infrastructure files
  final requiredTestFiles = [
    'test/test_config.dart',
    'test/test_runner.dart',
    'test/serialization_test.dart',
    'test/all_tests.dart',
    'test/property_tests/data_model_integrity_property_test.dart',
    'test/property_tests/timezone_handling_property_test.dart',
  ];

  print('\n🧪 Checking test infrastructure...');
  bool allTestFilesExist = true;
  for (final filePath in requiredTestFiles) {
    final file = File(filePath);
    if (file.existsSync()) {
      print('  ✅ $filePath');
    } else {
      print('  ❌ $filePath (missing)');
      allTestFilesExist = false;
    }
  }

  // Check for configuration files
  final requiredConfigFiles = [
    'build.yaml',
    'pubspec.yaml',
    'CODE_GENERATION_README.md',
  ];

  print('\n⚙️  Checking configuration files...');
  bool allConfigFilesExist = true;
  for (final filePath in requiredConfigFiles) {
    final file = File(filePath);
    if (file.existsSync()) {
      print('  ✅ $filePath');
    } else {
      print('  ❌ $filePath (missing)');
      allConfigFilesExist = false;
    }
  }

  // Check pubspec.yaml for required dependencies
  print('\n📦 Checking dependencies...');
  final pubspecFile = File('pubspec.yaml');
  if (pubspecFile.existsSync()) {
    final pubspecContent = pubspecFile.readAsStringSync();
    
    final requiredDependencies = [
      'json_annotation',
      'faker',
      'build_runner',
      'json_serializable',
    ];

    bool allDependenciesPresent = true;
    for (final dep in requiredDependencies) {
      if (pubspecContent.contains(dep)) {
        print('  ✅ $dep');
      } else {
        print('  ❌ $dep (missing from pubspec.yaml)');
        allDependenciesPresent = false;
      }
    }

    if (!allDependenciesPresent) {
      allConfigFilesExist = false;
    }
  }

  // Summary
  print('\n📋 Setup Verification Summary:');
  print('  Generated Files: ${allGeneratedFilesExist ? "✅ Complete" : "❌ Incomplete"}');
  print('  Test Infrastructure: ${allTestFilesExist ? "✅ Complete" : "❌ Incomplete"}');
  print('  Configuration: ${allConfigFilesExist ? "✅ Complete" : "❌ Incomplete"}');

  if (allGeneratedFilesExist && allTestFilesExist && allConfigFilesExist) {
    print('\n🎉 All systems ready! Code generation and testing infrastructure is properly set up.');
    print('\n📚 Next steps:');
    print('  1. Run `flutter pub get` to install dependencies');
    print('  2. Run `flutter test` to execute all tests');
    print('  3. Run `flutter packages pub run build_runner build` to regenerate code if needed');
    print('  4. See CODE_GENERATION_README.md for detailed documentation');
  } else {
    print('\n⚠️  Setup incomplete. Please check the missing files above.');
    exit(1);
  }
}