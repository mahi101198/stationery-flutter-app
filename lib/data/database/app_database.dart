import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

part 'app_database.g.dart';

// Products table
class Products extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get description => text()();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  IntColumn get stock => integer().withDefault(const Constant(0))();
  TextColumn get miniInfo => text()(); // JSON string
  TextColumn get images => text()(); // JSON string
  TextColumn get category => text()();
  TextColumn get subCategory => text()();
  IntColumn get popularRanking => integer().withDefault(const Constant(11))();
  IntColumn get categoryRanking => integer().withDefault(const Constant(11))();
  IntColumn get flashSaleRanking => integer().withDefault(const Constant(11))();
  RealColumn get mrp => real().withDefault(const Constant(0.0))(); // Market Retail Price
  RealColumn get price => real()(); // Selling price
  RealColumn get discount => real().withDefault(const Constant(0.0))(); // Discount percentage
  RealColumn get discountPrice => real().nullable()(); // Legacy field for backward compatibility
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

// Cart items table
class CartItems extends Table {
  TextColumn get productId => text()();
  IntColumn get quantity => integer().withDefault(const Constant(1))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {productId};
}

// Wishlist items table
class WishlistItems extends Table {
  TextColumn get productId => text()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {productId};
}

// Cache metadata table
class CacheMetadata extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {key};
}

@DriftDatabase(tables: [Products, CartItems, WishlistItems, CacheMetadata])
class AppDatabase extends _$AppDatabase {
  // Private constructor
  AppDatabase._() : super(_openConnection());

  // Singleton instance
  static AppDatabase? _instance;

  /// Get the singleton instance of AppDatabase
  static AppDatabase get instance {
    _instance ??= AppDatabase._();
    return _instance!;
  }

  /// Close the database instance (for testing or cleanup)
  static Future<void> closeInstance() async {
    if (_instance != null) {
      await _instance!.close();
      _instance = null;
    }
  }

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (Migrator m) async {
      await m.createAll();
    },
    onUpgrade: (Migrator m, int from, int to) async {
      // Handle database migrations here
      if (from == 1) {
        // Migration from version 1 to 2: Add mrp and discount columns
        await m.addColumn(products, products.mrp);
        await m.addColumn(products, products.discount);
      }
    },
  );
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'rps_stationery.db'));
    return NativeDatabase(file);
  });
}
