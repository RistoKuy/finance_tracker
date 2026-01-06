// ignore_for_file: avoid_print

import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class AssetDatabase {
  static final AssetDatabase instance = AssetDatabase._init();
  static Database? _database;
  
  // Connection pool for better performance
  static bool _isInitializing = false;

  AssetDatabase._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    
    // Prevent multiple simultaneous initializations
    if (_isInitializing) {
      while (_isInitializing) {
        await Future.delayed(const Duration(milliseconds: 10));
      }
      return _database!;
    }
    
    _isInitializing = true;
    try {
      _database = await _initDB('finance_tracker.db');
      return _database!;
    } catch (e) {
      _isInitializing = false;
      // Log error but don't crash the app
      print('Database initialization error: $e');
      rethrow;
    } finally {
      _isInitializing = false;
    }
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 2,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
      // Removed onConfigure to prevent SQLite PRAGMA issues with sqflite
    );
  }

  Future _createDB(Database db, int version) async {
    const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
    const textType = 'TEXT NOT NULL';
    const doubleType = 'REAL NOT NULL';

    await db.execute('''
    CREATE TABLE assets (
      id $idType,
      type $textType,
      name $textType,
      nominal $doubleType,
      currency $textType,
      date $textType
    )
    ''');

    // Create changes history table
    await db.execute('''
    CREATE TABLE changes_history (
      id $idType,
      change_type $textType,
      asset_name $textType,
      asset_type TEXT,
      old_value REAL,
      new_value REAL,
      currency $textType,
      description $textType,
      timestamp $textType
    )
    ''');
  }

  Future _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Add changes history table for version 2
      const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
      const textType = 'TEXT NOT NULL';
      
      await db.execute('''
      CREATE TABLE changes_history (
        id $idType,
        change_type $textType,
        asset_name $textType,
        asset_type TEXT,
        old_value REAL,
        new_value REAL,
        currency $textType,
        description $textType,
        timestamp $textType
      )
      ''');
    }
  }

  Future<int> createAsset(Map<String, dynamic> asset) async {
    try {
      final db = await instance.database;
      return await db.insert('assets', asset);
    } catch (e) {
      print('Error creating asset: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> readAllAssets() async {
    try {
      final db = await instance.database;
      // Use index for better performance on large datasets
      return await db.query(
        'assets',
        orderBy: 'date DESC',
        // Add limit if needed for pagination in future
      );
    } catch (e) {
      print('Error reading assets: $e');
      return []; // Return empty list instead of crashing
    }
  }

  // Optimized method to get assets by type (with caching potential)
  Future<List<Map<String, dynamic>>> readAssetsByType(String type) async {
    final db = await instance.database;
    return await db.query(
      'assets',
      where: 'type = ?',
      whereArgs: [type],
      orderBy: 'date DESC',
    );
  }

  // Batch operations for better performance
  Future<void> createMultipleAssets(List<Map<String, dynamic>> assets) async {
    final db = await instance.database;
    final batch = db.batch();
    
    for (final asset in assets) {
      batch.insert('assets', asset);
    }
    
    await batch.commit(noResult: true);
  }

  Future<int> updateAsset(int id, Map<String, dynamic> asset) async {
    final db = await instance.database;
    return await db.update(
      'assets',
      asset,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteAsset(int id) async {
    final db = await instance.database;
    return await db.delete(
      'assets',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Changes History Methods
  Future<int> createChangeRecord(Map<String, dynamic> change) async {
    final db = await instance.database;
    return await db.insert('changes_history', change);
  }

  Future<List<Map<String, dynamic>>> readAllChanges() async {
    final db = await instance.database;
    return await db.query(
      'changes_history',
      orderBy: 'timestamp DESC',
      // Consider adding pagination for large datasets
    );
  }

  // Optimized method to get changes with pagination
  Future<List<Map<String, dynamic>>> readChangesPaginated({
    int limit = 50,
    int offset = 0,
  }) async {
    final db = await instance.database;
    return await db.query(
      'changes_history',
      orderBy: 'timestamp DESC',
      limit: limit,
      offset: offset,
    );
  }

  // Get changes count for pagination
  Future<int> getChangesCount() async {
    final db = await instance.database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM changes_history');
    return result.first['count'] as int;
  }

  Future<int> deleteChangeRecord(int id) async {
    final db = await instance.database;
    return await db.delete(
      'changes_history',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteMultipleChanges(List<int> ids) async {
    final db = await instance.database;
    final placeholders = List.filled(ids.length, '?').join(',');
    return await db.delete(
      'changes_history',
      where: 'id IN ($placeholders)',
      whereArgs: ids,
    );
  }

  Future<void> cleanupOldChanges() async {
    final db = await instance.database;
    // Keep data for 5 years (1825 days) instead of just 12 months
    final fiveYearsAgo = DateTime.now().subtract(const Duration(days: 1825)).toIso8601String();
    
    await db.delete(
      'changes_history',
      where: 'timestamp < ?',
      whereArgs: [fiveYearsAgo],
    );
  }

  // Helper method to log asset changes
  Future<void> logAssetChange({
    required String changeType,
    required String assetName,
    String? assetType,
    double? oldValue,
    double? newValue,
    required String currency,
    required String description,
  }) async {
    final change = {
      'change_type': changeType,
      'asset_name': assetName,
      'asset_type': assetType,
      'old_value': oldValue,
      'new_value': newValue,
      'currency': currency,
      'description': description,
      'timestamp': DateTime.now().toIso8601String(),
    };
    
    await createChangeRecord(change);
    
    // Clean up old records (older than 5 years) every time we add a new record
    await cleanupOldChanges();
  }
  
  /// Get all changes within a date range
  Future<List<Map<String, dynamic>>> readChangesInRange({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final db = await instance.database;
    return await db.query(
      'changes_history',
      where: 'timestamp >= ? AND timestamp <= ?',
      whereArgs: [startDate.toIso8601String(), endDate.toIso8601String()],
      orderBy: 'timestamp DESC',
    );
  }
  
  /// Get changes grouped by month for reporting
  Future<Map<String, List<Map<String, dynamic>>>> getChangesGroupedByMonth() async {
    final changes = await readAllChanges();
    final grouped = <String, List<Map<String, dynamic>>>{};
    
    for (final change in changes) {
      final timestamp = DateTime.parse(change['timestamp'] as String);
      final key = '${timestamp.year}-${timestamp.month.toString().padLeft(2, '0')}';
      
      if (!grouped.containsKey(key)) {
        grouped[key] = [];
      }
      grouped[key]!.add(change);
    }
    
    return grouped;
  }
  
  /// Get statistics for reporting
  Future<Map<String, dynamic>> getStatistics() async {
    final db = await instance.database;
    
    // Total assets count
    final assetsResult = await db.rawQuery('SELECT COUNT(*) as count FROM assets');
    final assetsCount = assetsResult.first['count'] as int;
    
    // Total changes count
    final changesResult = await db.rawQuery('SELECT COUNT(*) as count FROM changes_history');
    final changesCount = changesResult.first['count'] as int;
    
    // Get oldest change date
    final oldestResult = await db.rawQuery(
      'SELECT MIN(timestamp) as oldest FROM changes_history'
    );
    final oldestTimestamp = oldestResult.first['oldest'] as String?;
    
    return {
      'assetsCount': assetsCount,
      'changesCount': changesCount,
      'oldestChange': oldestTimestamp,
      'dataRetentionYears': 5,
    };
  }

  Future close() async {
    final db = await instance.database;
    db.close();
  }
}
