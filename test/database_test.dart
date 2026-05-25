import 'package:flutter_test/flutter_test.dart';
import 'package:finance_tracker/database/asset_database.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  // Initialize sqflite ffi for testing
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('Database Module Tests', () {
    late AssetDatabase dbHelper;

    setUp(() async {
      dbHelper = AssetDatabase.instance;
      final db = await dbHelper.database;
      // Clean slate
      await db.delete('assets');
      await db.delete('changes_history');
    });

    test('Should create a new asset successfully', () async {
      // Arrange
      final asset = {
        'name': 'Savings Account',
        'nominal': 5000000.0,
        'currency': 'IDR',
        'type': 'savings',
        'date': DateTime.now().toIso8601String(),
      };

      // Act
      final id = await dbHelper.createAsset(asset);

      // Assert
      expect(id, greaterThan(0));
      final assets = await dbHelper.readAllAssets();
      expect(assets.length, 1);
      expect(assets[0]['name'], 'Savings Account');
    });

    test('Should update asset value correctly', () async {
      // Arrange
      final asset = {
        'name': 'Investment',
        'nominal': 10000000.0,
        'currency': 'USD',
        'type': 'investment',
        'date': DateTime.now().toIso8601String(),
      };
      final id = await dbHelper.createAsset(asset);

      // Act
      final updatedAsset = Map<String, dynamic>.from(asset);
      updatedAsset['nominal'] = 12000000.0;
      await dbHelper.updateAsset(id, updatedAsset);

      // Assert
      final assets = await dbHelper.readAllAssets();
      expect(assets[0]['nominal'], 12000000.0);
    });

    test('Should delete asset and log history', () async {
      // Arrange
      final asset = {
        'name': 'Cash',
        'nominal': 500000.0,
        'currency': 'IDR',
        'type': 'transactional',
        'date': DateTime.now().toIso8601String(),
      };
      final id = await dbHelper.createAsset(asset);

      // Act
      await dbHelper.deleteAsset(id);
      await dbHelper.logAssetChange(
        changeType: 'DELETE',
        assetName: asset['name'] as String,
        assetType: asset['type'] as String,
        currency: asset['currency'] as String,
        description: 'Asset deleted manually',
      );

      // Assert
      final assets = await dbHelper.readAllAssets();
      expect(assets.length, 0);

      // Check history
      final history = await dbHelper.readAllChanges();
      expect(history.length, greaterThan(0));
      expect(history[0]['change_type'], 'DELETE');
    });

    test('Should handle batch operations efficiently', () async {
      // Arrange
      final assets = List.generate(100, (index) => {
        'name': 'Asset $index',
        'nominal': 1000.0 * (index + 1),
        'currency': 'EUR',
        'type': 'savings',
        'date': DateTime.now().toIso8601String(),
      });

      // Act
      final startTime = DateTime.now();
      await dbHelper.createMultipleAssets(assets);
      final duration = DateTime.now().difference(startTime);

      // Assert
      final result = await dbHelper.readAllAssets();
      expect(result.length, 100);
      expect(duration.inMilliseconds, lessThan(5000)); // Performance check
    });
  });
}