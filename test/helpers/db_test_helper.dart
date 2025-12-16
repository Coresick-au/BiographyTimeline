import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite/sqflite.dart';

/// Initializes the database factory for FFI (desktop/test)
void initializeTestDatabase() {
  databaseFactory = databaseFactoryFfi;
  sqfliteFfiInit();
}
