// Conditional imports for database

// Export the database class (mobile-only)
export 'app_database_stub.dart'
    if (dart.library.ffi) 'app_database.dart';
