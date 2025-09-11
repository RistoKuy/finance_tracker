// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'constants/app_constants.dart';
import 'constants/date_format_manager.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _selectedDateFormat = AppConstants.defaultDateFormat;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
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
                          _buildInfoRow('Version', '1.0.0'),
                          _buildInfoRow('Build', '1'),
                          _buildInfoRow('Framework', 'Flutter'),
                        ],
                      ),
                    ),
                  ),
                ],
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