import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../database/asset_database.dart';

/// Service for managing persistent storage that survives app updates
class StorageService {
  static final StorageService instance = StorageService._init();
  
  StorageService._init();
  
  /// Get the persistent app data directory
  /// This directory survives app updates and is the recommended location for user data
  Future<Directory> getAppDataDirectory() async {
    final directory = await getApplicationDocumentsDirectory();
    final appDir = Directory('${directory.path}/FinanceTracker');
    
    // Create the directory if it doesn't exist
    if (!await appDir.exists()) {
      await appDir.create(recursive: true);
    }
    
    return appDir;
  }
  
  /// Get the exports directory
  Future<Directory> getExportsDirectory() async {
    final appDir = await getAppDataDirectory();
    final exportsDir = Directory('${appDir.path}/exports');
    
    if (!await exportsDir.exists()) {
      await exportsDir.create(recursive: true);
    }
    
    return exportsDir;
  }
  
  /// Get the backups directory
  Future<Directory> getBackupsDirectory() async {
    final appDir = await getAppDataDirectory();
    final backupsDir = Directory('${appDir.path}/backups');
    
    if (!await backupsDir.exists()) {
      await backupsDir.create(recursive: true);
    }
    
    return backupsDir;
  }
  
  /// Export assets and settings to JSON file
  Future<String> exportToJson({bool includeSettings = true, bool includeHistory = true}) async {
    final exportsDir = await getExportsDirectory();
    final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-').split('.').first;
    final fileName = 'finance_tracker_export_$timestamp.json';
    final file = File('${exportsDir.path}/$fileName');
    
    // Gather all data
    final assets = await AssetDatabase.instance.readAllAssets();
    
    final Map<String, dynamic> exportData = {
      'version': '1.0',
      'exportDate': DateTime.now().toIso8601String(),
      'assets': assets,
    };
    
    // Include history if requested
    if (includeHistory) {
      final changes = await AssetDatabase.instance.readAllChanges();
      exportData['changesHistory'] = changes;
    }
    
    // Include settings if requested (placeholder for future settings)
    if (includeSettings) {
      exportData['settings'] = {
        'dateFormat': 'dd/MM/yyyy - HH:mm',
        // Add more settings as needed
      };
    }
    
    // Write to file
    final jsonString = const JsonEncoder.withIndent('  ').convert(exportData);
    await file.writeAsString(jsonString);
    
    return file.path;
  }
  
  /// Import data from JSON file
  Future<Map<String, dynamic>> importFromJson(String filePath) async {
    final file = File(filePath);
    
    if (!await file.exists()) {
      throw Exception('File not found: $filePath');
    }
    
    final jsonString = await file.readAsString();
    final data = json.decode(jsonString) as Map<String, dynamic>;
    
    return data;
  }
  
  /// Apply imported data to the database
  Future<ImportResult> applyImport(Map<String, dynamic> data, {bool replaceExisting = false}) async {
    int assetsImported = 0;
    int changesImported = 0;
    
    // Import assets
    if (data.containsKey('assets')) {
      final assets = data['assets'] as List<dynamic>;
      
      if (replaceExisting) {
        // Clear existing assets first
        final existingAssets = await AssetDatabase.instance.readAllAssets();
        for (final asset in existingAssets) {
          await AssetDatabase.instance.deleteAsset(asset['id']);
        }
      }
      
      for (final assetData in assets) {
        final asset = Map<String, dynamic>.from(assetData);
        asset.remove('id'); // Remove ID to create new entries
        await AssetDatabase.instance.createAsset(asset);
        assetsImported++;
      }
    }
    
    // Import changes history
    if (data.containsKey('changesHistory')) {
      final changes = data['changesHistory'] as List<dynamic>;
      
      for (final changeData in changes) {
        final change = Map<String, dynamic>.from(changeData);
        change.remove('id'); // Remove ID to create new entries
        await AssetDatabase.instance.createChangeRecord(change);
        changesImported++;
      }
    }
    
    return ImportResult(
      assetsImported: assetsImported,
      changesImported: changesImported,
      success: true,
    );
  }
  
  /// Get list of available export files
  Future<List<FileInfo>> getExportFiles() async {
    final exportsDir = await getExportsDirectory();
    final files = <FileInfo>[];
    
    if (await exportsDir.exists()) {
      await for (final entity in exportsDir.list()) {
        if (entity is File && entity.path.endsWith('.json')) {
          final stat = await entity.stat();
          files.add(FileInfo(
            path: entity.path,
            name: entity.path.split('/').last.split('\\').last,
            size: stat.size,
            modified: stat.modified,
          ));
        }
      }
    }
    
    // Sort by modified date, newest first
    files.sort((a, b) => b.modified.compareTo(a.modified));
    
    return files;
  }
  
  /// Delete an export file
  Future<void> deleteExportFile(String filePath) async {
    final file = File(filePath);
    if (await file.exists()) {
      await file.delete();
    }
  }
  
  /// Create an automatic backup
  Future<String> createBackup() async {
    final backupsDir = await getBackupsDirectory();
    final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-').split('.').first;
    final fileName = 'backup_$timestamp.json';
    final file = File('${backupsDir.path}/$fileName');
    
    // Gather all data
    final assets = await AssetDatabase.instance.readAllAssets();
    final changes = await AssetDatabase.instance.readAllChanges();
    
    final Map<String, dynamic> backupData = {
      'version': '1.0',
      'backupDate': DateTime.now().toIso8601String(),
      'assets': assets,
      'changesHistory': changes,
    };
    
    // Write to file
    final jsonString = const JsonEncoder.withIndent('  ').convert(backupData);
    await file.writeAsString(jsonString);
    
    // Clean up old backups (keep only last 5)
    await _cleanupOldBackups(5);
    
    return file.path;
  }
  
  /// Clean up old backups, keeping only the specified number
  Future<void> _cleanupOldBackups(int keepCount) async {
    final backupsDir = await getBackupsDirectory();
    final files = <File>[];
    
    if (await backupsDir.exists()) {
      await for (final entity in backupsDir.list()) {
        if (entity is File && entity.path.endsWith('.json')) {
          files.add(entity);
        }
      }
    }
    
    // Sort by name (which includes timestamp) descending
    files.sort((a, b) => b.path.compareTo(a.path));
    
    // Delete files beyond the keep count
    if (files.length > keepCount) {
      for (var i = keepCount; i < files.length; i++) {
        await files[i].delete();
      }
    }
  }
}

/// Result of an import operation
class ImportResult {
  final int assetsImported;
  final int changesImported;
  final bool success;
  final String? error;
  
  ImportResult({
    required this.assetsImported,
    required this.changesImported,
    required this.success,
    this.error,
  });
}

/// Information about a file
class FileInfo {
  final String path;
  final String name;
  final int size;
  final DateTime modified;
  
  FileInfo({
    required this.path,
    required this.name,
    required this.size,
    required this.modified,
  });
  
  /// Get file size in human readable format
  String get formattedSize {
    if (size < 1024) return '$size B';
    if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(1)} KB';
    return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
