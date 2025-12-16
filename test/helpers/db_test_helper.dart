import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite/sqflite.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'dart:io';

/// Initializes the database factory for FFI (desktop/test)
/// and mocks the path provider
void initializeTestDatabase() {
  databaseFactory = databaseFactoryFfi;
  sqfliteFfiInit();
  
  // Mock path provider
  if (!PathProviderPlatform.instance.toString().contains('FakePathProviderPlatform')) {
    PathProviderPlatform.instance = FakePathProviderPlatform();
  }
}

class FakePathProviderPlatform extends Fake with MockPlatformInterfaceMixin implements PathProviderPlatform {
  @override
  Future<String?> getApplicationDocumentsPath() async {
    return Directory.systemTemp.path;
  }
  
  @override
  Future<String?> getTemporaryPath() async {
    return Directory.systemTemp.path;
  }
}
