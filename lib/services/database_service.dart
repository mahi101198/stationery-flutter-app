import 'dart:developer';
import 'package:get/get.dart';
import 'package:rps_stationery/data/database/database_interface.dart';

/// Service to manage database lifecycle and prevent multiple instances
class DatabaseService extends GetxService {
  static DatabaseService get instance => Get.find();
  
  AppDatabase? _database;
  bool _isInitialized = false;

  /// Initialize database service
  Future<void> initialize() async {
    if (_isInitialized) {
      log('Database service already initialized', name: 'DatabaseService');
      return;
    }

    try {
      log('Initializing database service...', name: 'DatabaseService');
      
      // Get the singleton instance
      _database = AppDatabase.instance;
      
      // Database instance obtained successfully
      
      _isInitialized = true;
      log('Database service initialized successfully', name: 'DatabaseService');
    } catch (e) {
      log('Failed to initialize database service: $e', name: 'DatabaseService');
      rethrow;
    }
  }

  /// Get database instance
  AppDatabase get database {
    if (!_isInitialized || _database == null) {
      throw Exception('Database service not initialized. Call initialize() first.');
    }
    return _database!;
  }

  /// Check if database is initialized
  bool get isInitialized => _isInitialized;

  /// Close database connection
  Future<void> close() async {
    if (_database != null) {
      try {
        await AppDatabase.closeInstance();
        _database = null;
        _isInitialized = false;
        log('Database service closed successfully', name: 'DatabaseService');
      } catch (e) {
        log('Error closing database service: $e', name: 'DatabaseService');
      }
    }
  }

  /// Reset database (for testing)
  Future<void> reset() async {
    await close();
    await initialize();
  }

  @override
  void onClose() {
    close();
    super.onClose();
  }
}
