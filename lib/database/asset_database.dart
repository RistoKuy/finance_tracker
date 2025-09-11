import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class AssetDatabase {
  static final AssetDatabase instance = AssetDatabase._init();
  static Database? _database;

  AssetDatabase._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('finance_tracker.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(path, version: 2, onCreate: _createDB, onUpgrade: _upgradeDB);
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
    final db = await instance.database;
    return await db.insert('assets', asset);
  }

  Future<List<Map<String, dynamic>>> readAllAssets() async {
    final db = await instance.database;
    return await db.query('assets', orderBy: 'date DESC');
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
    return await db.query('changes_history', orderBy: 'timestamp DESC');
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
    final twelveMonthsAgo = DateTime.now().subtract(const Duration(days: 365)).toIso8601String();
    
    await db.delete(
      'changes_history',
      where: 'timestamp < ?',
      whereArgs: [twelveMonthsAgo],
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
    
    // Clean up old records (older than 12 months) every time we add a new record
    await cleanupOldChanges();
  }

  Future close() async {
    final db = await instance.database;
    db.close();
  }
}
