import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:finance_tracker/database/asset_database.dart';
import 'package:finance_tracker/services/storage_service.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

// Fake PathProviderPlatform for testing
class FakePathProviderPlatform extends Fake
    with MockPlatformInterfaceMixin
    implements PathProviderPlatform {
  final String _appDocDir;
  
  FakePathProviderPlatform(this._appDocDir);

  @override
  Future<String?> getApplicationDocumentsPath() async {
    return _appDocDir;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Initialize FFI for tests
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('StorageService Export/Import Tests', () {
    late StorageService storageService;
    late AssetDatabase dbHelper;
    late Directory tempDir;

    setUp(() async {
      // Mock path_provider
      tempDir = await Directory.systemTemp.createTemp('finance_tracker_test');
      PathProviderPlatform.instance = FakePathProviderPlatform(tempDir.path);

      dbHelper = AssetDatabase.instance;
      storageService = StorageService.instance;
      
      final db = await dbHelper.database;
      // Clean slate
      await db.delete('assets');
      await db.delete('changes_history');
    });

    tearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('Should export all data to JSON successfully', () async {
      // Arrange - Create sample data
      await dbHelper.createAsset({
        'name': 'Asset 1', 'nominal': 1000.0, 'currency': 'USD', 'type': 'savings', 'date': DateTime.now().toIso8601String()
      });
      await dbHelper.createAsset({
        'name': 'Asset 2', 'nominal': 2000.0, 'currency': 'EUR', 'type': 'investment', 'date': DateTime.now().toIso8601String()
      });

      // Act
      final startTime = DateTime.now();
      final exportPath = await storageService.exportToJson();
      final duration = DateTime.now().difference(startTime);

      // Assert
      final file = File(exportPath);
      expect(await file.exists(), isTrue);
      
      final importedData = await storageService.importFromJson(exportPath);
      expect(importedData, isNotEmpty);
      expect(importedData['assets'], isList);
      expect(importedData['assets'].length, 2);
      expect(duration.inMilliseconds, lessThan(2000)); // < 2 seconds
    });

    test('Should import JSON data with replace option', () async {
      // Arrange - Create initial data
      await dbHelper.createAsset({
        'name': 'Old Asset', 'nominal': 1000.0, 'currency': 'USD', 'type': 'savings', 'date': DateTime.now().toIso8601String()
      });

      final jsonData = {
        'assets': [
          {
            'name': 'New Asset', 'nominal': 5000.0, 'currency': 'EUR', 'type': 'investment', 'date': DateTime.now().toIso8601String()
          }
        ],
        'changesHistory': []
      };

      // Act
      await storageService.applyImport(jsonData, replaceExisting: true);

      // Assert
      final assets = await dbHelper.readAllAssets();
      expect(assets.length, 1);
      expect(assets[0]['name'], 'New Asset');
      expect(assets.any((a) => a['name'] == 'Old Asset'), false);
    });

    test('Should handle backup rotation correctly (keep max 5 backups)', () async {
      // Act - Create multiple exports (backups)
      for (int i = 0; i < 7; i++) {
        await storageService.createBackup();
        // small delay so timestamps might differ if StorageService uses it for naming
        await Future.delayed(const Duration(milliseconds: 10));
      }

      // Assert - Should keep only logic (though StorageService handles cleanup on createBackup if implemented)
      // I'll check if getBackups() or list is available or just read the directory directly
      final backupsDir = await storageService.getBackupsDirectory();
      final backups = await backupsDir.list().toList();
      // Implementation-specific: if createBackup caps at 5, it should be 5
      expect(backups.length, lessThanOrEqualTo(5)); 
    });
  });
}