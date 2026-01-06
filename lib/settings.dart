// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:file_picker/file_picker.dart';
import 'constants/app_constants.dart';
import 'constants/date_format_manager.dart';
import 'services/storage_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _selectedDateFormat = AppConstants.defaultDateFormat;
  bool _isLoading = true;
  bool _isExporting = false;
  bool _isImporting = false;
  List<FileInfo> _exportFiles = [];

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _loadExportFiles();
  }

  Future<void> _loadSettings() async {
    setState(() => _isLoading = true);
    
    final prefs = await SharedPreferences.getInstance();
    final savedFormat = prefs.getString('date_format') ?? AppConstants.defaultDateFormat;
    
    setState(() {
      _selectedDateFormat = savedFormat;
      _isLoading = false;
    });
  }

  Future<void> _loadExportFiles() async {
    final files = await StorageService.instance.getExportFiles();
    setState(() {
      _exportFiles = files;
    });
  }

  Future<void> _saveDateFormat(String format) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('date_format', format);
      
      // Update the DateFormatManager
      await DateFormatManager.setFormat(format);
      
      setState(() {
        _selectedDateFormat = format;
      });

      // Show confirmation
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Date format changed to: ${AppConstants.dateFormatLabels[format]}'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to save date format setting'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> _exportData() async {
    setState(() => _isExporting = true);
    
    try {
      final filePath = await StorageService.instance.exportToJson(
        includeSettings: true,
        includeHistory: true,
      );
      
      await _loadExportFiles();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Data exported successfully!'),
                Text(
                  'Saved to: ${filePath.split('/').last.split('\\').last}',
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export failed: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      setState(() => _isExporting = false);
    }
  }

  Future<void> _importData() async {
    // Show file picker
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );
    
    if (result == null || result.files.isEmpty) return;
    
    final filePath = result.files.single.path;
    if (filePath == null) return;
    
    // Show confirmation dialog
    final shouldReplace = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber, color: Colors.orange),
            SizedBox(width: 8),
            Text('Import Data'),
          ],
        ),
        content: const Text(
          'How would you like to import the data?\n\n'
          '• Merge: Add imported data to existing data\n'
          '• Replace: Delete existing data and import fresh',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Merge'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Replace'),
          ),
        ],
      ),
    );
    
    if (shouldReplace == null) return;
    
    setState(() => _isImporting = true);
    
    try {
      final data = await StorageService.instance.importFromJson(filePath);
      final importResult = await StorageService.instance.applyImport(
        data,
        replaceExisting: shouldReplace,
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Import successful! ${importResult.assetsImported} assets and '
              '${importResult.changesImported} history records imported.',
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Import failed: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      setState(() => _isImporting = false);
    }
  }

  void _showExportFilesDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.folder_open, color: Colors.blue),
            SizedBox(width: 8),
            Text('Export Files'),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: _exportFiles.isEmpty
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('No export files found'),
                  ),
                )
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: _exportFiles.length,
                  itemBuilder: (context, index) {
                    final file = _exportFiles[index];
                    return ListTile(
                      leading: const Icon(Icons.description, color: Colors.green),
                      title: Text(
                        file.name,
                        style: const TextStyle(fontSize: 12),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        '${file.formattedSize} • ${_formatDate(file.modified)}',
                        style: const TextStyle(fontSize: 11),
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                        onPressed: () async {
                          await StorageService.instance.deleteExportFile(file.path);
                          await _loadExportFiles();
                          if (mounted) {
                            Navigator.pop(context);
                            _showExportFilesDialog();
                          }
                        },
                      ),
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
  
  Future<String> _getStoragePath() async {
    try {
      final dir = await StorageService.instance.getAppDataDirectory();
      return dir.path;
    } catch (e) {
      return 'Unable to determine path';
    }
  }

  Widget _buildFormatOption({
    required String format,
    required String label,
    required String example,
  }) {
    final isSelected = _selectedDateFormat == format;
    
    return Card(
      elevation: isSelected ? 4 : 1,
      color: isSelected ? Colors.teal.shade700 : null,
      child: ListTile(
        leading: Radio<String>(
          value: format,
          groupValue: _selectedDateFormat,
          onChanged: (value) {
            if (value != null) {
              _saveDateFormat(value);
            }
          },
          activeColor: Colors.white,
        ),
        title: Text(
          label,
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? Colors.white : null,
          ),
        ),
        subtitle: Text(
          'Example: $example',
          style: TextStyle(
            color: isSelected ? Colors.white70 : Colors.grey.shade600,
          ),
        ),
        onTap: () => _saveDateFormat(format),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Colors.teal.shade700,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: EdgeInsets.only(
                  left: 16.0,
                  right: 16.0,
                  top: 16.0,
                  bottom: 16.0 + MediaQuery.of(context).padding.bottom,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Date Format Settings Section
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.date_range,
                                  color: Colors.teal.shade700,
                                  size: 24,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Date & Time Format',
                                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.teal.shade700,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Choose how dates and times are displayed throughout the app.',
                              style: TextStyle(color: Colors.grey),
                            ),
                            const SizedBox(height: 16),
                            
                            // Format Options
                            _buildFormatOption(
                              format: AppConstants.europeanDateFormat,
                              label: 'European Format (24-hour)',
                              example: '11/09/2025 - 14:30',
                            ),
                            const SizedBox(height: 8),
                            _buildFormatOption(
                              format: AppConstants.americanDateFormat,
                              label: 'American Format (12-hour)',
                              example: 'Sep 11, 2025 - 2:30 PM',
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Data Management Section
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.folder_copy,
                                  color: Colors.green.shade700,
                                  size: 24,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Data Management',
                                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green.shade700,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Export and import your assets and settings as JSON files. '
                              'Exported files are saved in a persistent location that survives app updates.',
                              style: TextStyle(color: Colors.grey),
                            ),
                            const SizedBox(height: 16),
                            
                            // Export Button
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: _isExporting ? null : _exportData,
                                icon: _isExporting
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Icon(Icons.upload_file),
                                label: Text(_isExporting ? 'Exporting...' : 'Export Data'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green.shade700,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                ),
                              ),
                            ),
                            
                            const SizedBox(height: 12),
                            
                            // Import Button
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: _isImporting ? null : _importData,
                                icon: _isImporting
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Icon(Icons.download),
                                label: Text(_isImporting ? 'Importing...' : 'Import Data'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue.shade700,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                ),
                              ),
                            ),
                            
                            const SizedBox(height: 12),
                            
                            // View Exports Button
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                onPressed: _showExportFilesDialog,
                                icon: const Icon(Icons.folder_open),
                                label: Text('View Export Files (${_exportFiles.length})'),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Storage Location Section
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.folder,
                                  color: Colors.orange.shade700,
                                  size: 24,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Storage Location',
                                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.orange.shade700,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Your exported data and backups are stored in a persistent location that survives app updates:',
                              style: TextStyle(color: Colors.grey),
                            ),
                            const SizedBox(height: 12),
                            FutureBuilder<String>(
                              future: _getStoragePath(),
                              builder: (context, snapshot) {
                                final path = snapshot.data ?? 'Loading...';
                                return Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade900,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Colors.grey.shade700),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Documents/FinanceTracker/',
                                        style: TextStyle(
                                          fontFamily: 'monospace',
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        '├── exports/  (Your exported JSON files)',
                                        style: TextStyle(
                                          fontFamily: 'monospace',
                                          fontSize: 12,
                                          color: Colors.grey.shade400,
                                        ),
                                      ),
                                      Text(
                                        '└── backups/  (Automatic backups)',
                                        style: TextStyle(
                                          fontFamily: 'monospace',
                                          fontSize: 12,
                                          color: Colors.grey.shade400,
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        'Full path: $path',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.grey.shade500,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // App Information Section
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  color: Colors.blue.shade700,
                                  size: 24,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'App Information',
                                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue.shade700,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            
                            _buildInfoRow('App Name', AppConstants.appTitle),
                            _buildInfoRow('Version', '1.1.0'),
                            _buildInfoRow('Build', '2'),
                            _buildInfoRow('Framework', 'Flutter'),
                            _buildInfoRow('Data Retention', '5 Years'),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          Text(
            value,
            style: TextStyle(color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }
}