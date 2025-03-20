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

    return await openDatabase(path, version: 1, onCreate: _createDB);
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

  Future close() async {
    final db = await instance.database;
    db.close();
  }
}
