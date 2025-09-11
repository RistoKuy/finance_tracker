// ignore_for_file: unused_field, unused_element

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'database/asset_database.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final List<Map<String, dynamic>> _changes = [];
  bool _isLoading = true;
  bool _isSelectionMode = false;
  final Set<int> _selectedChangeIds = {};
  String _filterType = 'ALL'; // ALL, CREATE, UPDATE, DELETE, BULK_DELETE
  String _selectedMonth = 'ALL'; // ALL or YYYY-MM format
  DateTime? _selectedDate; // For specific date filtering
  final bool _showCalendar = false; // Toggle calendar view
  final DateTime _focusedDay = DateTime.now();
  DateTime _selectedCalendarMonth = DateTime.now();

  // Filter options
  final List<String> _filterOptions = ['ALL', 'CREATE', 'UPDATE', 'DELETE', 'BULK_DELETE'];
  final Map<String, String> _filterLabels = {
    'ALL': 'All Changes',
    'CREATE': 'Created',
    'UPDATE': 'Updated', 
    'DELETE': 'Deleted',
    'BULK_DELETE': 'Bulk Deleted',
  };

  // Change type colors and icons
  final Map<String, Color> _changeColors = {
    'CREATE': Colors.green,
    'UPDATE': Colors.blue,
    'DELETE': Colors.red,
    'BULK_DELETE': Colors.redAccent,
  };

  final Map<String, IconData> _changeIcons = {
    'CREATE': Icons.add_circle,
    'UPDATE': Icons.edit,
    'DELETE': Icons.delete,
    'BULK_DELETE': Icons.delete_sweep,
  };

  @override
  void initState() {
    super.initState();
    _refreshChanges();
  }

  Future<void> _refreshChanges() async {
    setState(() => _isLoading = true);
    final changes = await AssetDatabase.instance.readAllChanges();
    setState(() {
      _changes.clear();
      _changes.addAll(changes);
      _isLoading = false;
    });
  }

  List<Map<String, dynamic>> get _filteredChanges {
    List<Map<String, dynamic>> filtered = _changes;
    
    // Filter by change type
    if (_filterType != 'ALL') {
      filtered = filtered.where((change) => change['change_type'] == _filterType).toList();
    }
    
    // Filter by specific date (takes priority over month filter)
    if (_selectedDate != null) {
      filtered = filtered.where((change) {
        if (change['timestamp'] == null) return false;
        try {
          final changeDate = DateTime.parse(change['timestamp']);
          return DateUtils.isSameDay(changeDate, _selectedDate!);
        } catch (e) {
          return false;
        }
      }).toList();
    }
    // Filter by month (only if no specific date is selected)
    else if (_selectedMonth != 'ALL') {
      filtered = filtered.where((change) {
        if (change['timestamp'] == null) return false;
        try {
          final changeDate = DateTime.parse(change['timestamp']);
          final changeMonth = '${changeDate.year}-${changeDate.month.toString().padLeft(2, '0')}';
          return changeMonth == _selectedMonth;
        } catch (e) {
          return false;
        }
      }).toList();
    }
    
    return filtered;
  }
  
  // Get available months from changes data
  List<String> get _availableMonths {
    final monthsSet = <String>{};
    
    for (final change in _changes) {
      if (change['timestamp'] != null) {
        try {
          final changeDate = DateTime.parse(change['timestamp']);
          final monthKey = '${changeDate.year}-${changeDate.month.toString().padLeft(2, '0')}';
          monthsSet.add(monthKey);
        } catch (e) {
          // Skip invalid dates
        }
      }
    }
    
    final monthsList = monthsSet.toList()..sort((a, b) => b.compareTo(a)); // Sort newest first
    return ['ALL', ...monthsList];
  }
  
  // Format month for display
  String _formatMonthDisplay(String monthKey) {
    if (monthKey == 'ALL') return 'All Months';
    
    try {
      final parts = monthKey.split('-');
      final year = int.parse(parts[0]);
      final month = int.parse(parts[1]);
      final date = DateTime(year, month);
      return DateFormat('MMMM yyyy').format(date);
    } catch (e) {
      return monthKey;
    }
  }
  
  // Group changes by date for better organization
  Map<String, List<Map<String, dynamic>>> get _groupedChanges {
    final Map<String, List<Map<String, dynamic>>> grouped = {};
    final filteredChanges = _filteredChanges;
    
    for (final change in filteredChanges) {
      if (change['timestamp'] == null) continue;
      
      try {
        final changeDate = DateTime.parse(change['timestamp']);
        final dateKey = DateFormat('yyyy-MM-dd').format(changeDate);
        
        if (!grouped.containsKey(dateKey)) {
          grouped[dateKey] = [];
        }
        grouped[dateKey]!.add(change);
      } catch (e) {
        // Skip invalid dates
      }
    }
    
    // Sort groups by date (newest first)
    final sortedEntries = grouped.entries.toList()
      ..sort((a, b) => b.key.compareTo(a.key));
    
    return Map.fromEntries(sortedEntries);
  }
  
  // Get all dates that have changes (for calendar markers)
  Set<DateTime> get _datesWithChanges {
    final dates = <DateTime>{};
    
    for (final change in _changes) {
      if (change['timestamp'] != null) {
        try {
          final changeDate = DateTime.parse(change['timestamp']);
          // Normalize to date only (remove time)
          final normalizedDate = DateTime(changeDate.year, changeDate.month, changeDate.day);
          dates.add(normalizedDate);
        } catch (e) {
          // Skip invalid dates
        }
      }
    }
    
    return dates;
  }
  
  // Get changes count for a specific date
  int _getChangesCountForDate(DateTime date) {
    int count = 0;
    
    for (final change in _changes) {
      if (change['timestamp'] != null) {
        try {
          final changeDate = DateTime.parse(change['timestamp']);
          if (DateUtils.isSameDay(changeDate, date)) {
            count++;
          }
        } catch (e) {
          // Skip invalid dates
        }
      }
    }
    
    return count;
  }
  
  // Get change types for a specific date (for visual indicators)
  Set<String> _getChangeTypesForDate(DateTime date) {
    final types = <String>{};
    
    for (final change in _changes) {
      if (change['timestamp'] != null) {
        try {
          final changeDate = DateTime.parse(change['timestamp']);
          if (DateUtils.isSameDay(changeDate, date)) {
            types.add(change['change_type'] ?? 'UNKNOWN');
          }
        } catch (e) {
          // Skip invalid dates
        }
      }
    }
    
    return types;
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter Changes'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: _filterOptions.map((option) => 
            RadioListTile<String>(
              title: Text(_filterLabels[option]!),
              value: option,
              groupValue: _filterType,
              onChanged: (value) {
                setState(() {
                  _filterType = value!;
                  // Exit selection mode when filter changes
                  _isSelectionMode = false;
                  _selectedChangeIds.clear();
                });
                Navigator.pop(context);
              },
            ),
          ).toList(),
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
  
  void _showMonthFilterDialog() {
    final availableMonths = _availableMonths;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter by Month'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: availableMonths.length,
            itemBuilder: (context, index) {
              final monthKey = availableMonths[index];
              return RadioListTile<String>(
                title: Text(_formatMonthDisplay(monthKey)),
                subtitle: monthKey != 'ALL' ? Text(monthKey) : null,
                value: monthKey,
                groupValue: _selectedMonth,
                onChanged: (value) {
                  setState(() {
                    _selectedMonth = value!;
                    _selectedDate = null; // Clear specific date filter
                    // Exit selection mode when filter changes
                    _isSelectionMode = false;
                    _selectedChangeIds.clear();
                  });
                  Navigator.pop(context);
                },
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
  
  void _showCalendarDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          width: 400,
          height: 500,
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Text(
                'Select Date',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: _buildCalendar(),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  TextButton.icon(
                    onPressed: () {
                      setState(() {
                        _selectedDate = null;
                        _selectedMonth = 'ALL';
                      });
                      Navigator.pop(context);
                    },
                    icon: const Icon(Icons.clear),
                    label: const Text('Clear'),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Close'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildCalendar() {
    return StatefulBuilder(
      builder: (context, setCalendarState) {
        return Column(
          children: [
            // Month/Year navigation
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  onPressed: () {
                    setCalendarState(() {
                      _selectedCalendarMonth = DateTime(
                        _selectedCalendarMonth.year,
                        _selectedCalendarMonth.month - 1,
                      );
                    });
                  },
                  icon: const Icon(Icons.chevron_left),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      final monthKey = '${_selectedCalendarMonth.year}-${_selectedCalendarMonth.month.toString().padLeft(2, '0')}';
                      
                      if (_isCurrentMonthSelected()) {
                        // Clear the month filter if it's already selected
                        setState(() {
                          _selectedMonth = 'ALL';
                          _selectedDate = null;
                          _isSelectionMode = false;
                          _selectedChangeIds.clear();
                        });
                        Navigator.pop(context);
                        
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Month filter cleared - showing all changes'),
                            backgroundColor: Colors.orange,
                            duration: Duration(seconds: 2),
                          ),
                        );
                      } else {
                        // Filter by the currently displayed month
                        setState(() {
                          _selectedMonth = monthKey;
                          _selectedDate = null; // Clear specific date filter
                          _isSelectionMode = false;
                          _selectedChangeIds.clear();
                        });
                        Navigator.pop(context); // Close calendar dialog
                        
                        // Show confirmation message
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Filtered by ${DateFormat('MMMM yyyy').format(_selectedCalendarMonth)}'),
                            backgroundColor: Colors.green,
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                      decoration: BoxDecoration(
                        color: _isCurrentMonthSelected() 
                            ? Colors.green.withValues(alpha: 0.2)
                            : Colors.blue.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: _isCurrentMonthSelected()
                              ? Colors.green.withValues(alpha: 0.5)
                              : Colors.blue.withValues(alpha: 0.3),
                          width: _isCurrentMonthSelected() ? 2 : 1,
                        ),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (_isCurrentMonthSelected()) ...[
                                Icon(
                                  Icons.check_circle,
                                  size: 16,
                                  color: Colors.green.shade700,
                                ),
                                const SizedBox(width: 4),
                              ],
                              Text(
                                DateFormat('MMMM yyyy').format(_selectedCalendarMonth),
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: _isCurrentMonthSelected()
                                      ? Colors.green.shade700
                                      : Colors.blue.shade700,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _isCurrentMonthSelected() 
                                ? 'Currently filtered by this month'
                                : 'Tap to filter by this month',
                            style: TextStyle(
                              fontSize: 10,
                              color: _isCurrentMonthSelected()
                                  ? Colors.green.shade600
                                  : Colors.blue.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () {
                    setCalendarState(() {
                      _selectedCalendarMonth = DateTime(
                        _selectedCalendarMonth.year,
                        _selectedCalendarMonth.month + 1,
                      );
                    });
                  },
                  icon: const Icon(Icons.chevron_right),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Calendar grid
            Expanded(
              child: _buildCalendarGrid(setCalendarState),
            ),
          ],
        );
      },
    );
  }
  
  Widget _buildCalendarGrid(StateSetter setCalendarState) {
    final firstDayOfMonth = DateTime(_selectedCalendarMonth.year, _selectedCalendarMonth.month, 1);
    final firstDayWeekday = firstDayOfMonth.weekday;
    
    // Calculate days to show (including previous and next month days)
    final startDate = firstDayOfMonth.subtract(Duration(days: firstDayWeekday - 1));
    
    return Column(
      children: [
        // Weekday headers
        Row(
          children: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']
              .map((day) => Expanded(
                    child: Center(
                      child: Text(
                        day,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ),
                  ))
              .toList(),
        ),
        const SizedBox(height: 8),
        
        // Calendar days
        Expanded(
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              childAspectRatio: 1.0,
            ),
            itemCount: 42, // 6 weeks * 7 days
            itemBuilder: (context, index) {
              final date = startDate.add(Duration(days: index));
              final isCurrentMonth = date.month == _selectedCalendarMonth.month;
              final isToday = DateUtils.isSameDay(date, DateTime.now());
              final isSelected = _selectedDate != null && DateUtils.isSameDay(date, _selectedDate!);
              final hasChanges = _getChangesCountForDate(date) > 0;
              final changesCount = _getChangesCountForDate(date);
              final changeTypes = _getChangeTypesForDate(date);
              
              return GestureDetector(
                onTap: () {
                  setCalendarState(() {
                    setState(() {
                      _selectedDate = isSelected ? null : date;
                      _selectedMonth = 'ALL'; // Clear month filter when selecting specific date
                      _isSelectionMode = false;
                      _selectedChangeIds.clear();
                    });
                  });
                },
                child: Container(
                  margin: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Theme.of(context).colorScheme.primary
                        : isToday
                            ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.3)
                            : null,
                    border: isToday && !isSelected
                        ? Border.all(
                            color: Theme.of(context).colorScheme.primary,
                            width: 2,
                          )
                        : null,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Stack(
                    children: [
                      Center(
                        child: Text(
                          '${date.day}',
                          style: TextStyle(
                            fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                            color: isSelected
                                ? Colors.white
                                : isCurrentMonth
                                    ? null
                                    : Colors.grey.shade400,
                          ),
                        ),
                      ),
                      
                      // Changes indicator
                      if (hasChanges) ...[
                        Positioned(
                          top: 2,
                          right: 2,
                          child: Container(
                            width: 16,
                            height: 16,
                            decoration: BoxDecoration(
                              color: _getIndicatorColor(changeTypes),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                '$changesCount',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 8,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
  
  Color _getIndicatorColor(Set<String> changeTypes) {
    if (changeTypes.contains('DELETE') || changeTypes.contains('BULK_DELETE')) {
      return Colors.red;
    } else if (changeTypes.contains('CREATE')) {
      return Colors.green;
    } else if (changeTypes.contains('UPDATE')) {
      return Colors.blue;
    } else {
      return Colors.orange;
    }
  }
  
  // Check if the currently displayed calendar month is the selected filter month
  bool _isCurrentMonthSelected() {
    if (_selectedMonth == 'ALL') return false;
    
    final calendarMonthKey = '${_selectedCalendarMonth.year}-${_selectedCalendarMonth.month.toString().padLeft(2, '0')}';
    return _selectedMonth == calendarMonthKey;
  }

  void _toggleSelectionMode() {
    setState(() {
      _isSelectionMode = !_isSelectionMode;
      if (!_isSelectionMode) {
        _selectedChangeIds.clear();
      }
    });
  }

  void _toggleChangeSelection(int changeId) {
    setState(() {
      if (_selectedChangeIds.contains(changeId)) {
        _selectedChangeIds.remove(changeId);
      } else {
        _selectedChangeIds.add(changeId);
      }
      
      // If no items selected, exit selection mode
      if (_selectedChangeIds.isEmpty && _isSelectionMode) {
        _isSelectionMode = false;
      }
    });
  }

  void _selectAllChanges() {
    setState(() {
      final filteredChanges = _filteredChanges;
      final visibleChangeIds = filteredChanges.map((change) => change['id'] as int).toSet();
      
      if (_selectedChangeIds.containsAll(visibleChangeIds)) {
        // If all visible are selected, deselect them
        _selectedChangeIds.removeAll(visibleChangeIds);
      } else {
        // Select all visible (filtered) changes
        _selectedChangeIds.addAll(visibleChangeIds);
      }
    });
  }

  void _deleteSelectedChanges() {
    if (_selectedChangeIds.isEmpty) return;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: Text(
          'Are you sure you want to delete ${_selectedChangeIds.length} selected ${_selectedChangeIds.length == 1 ? 'change record' : 'change records'}?\n\nThis action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () async {
              final selectedCount = _selectedChangeIds.length;
              // Delete all selected changes
              await AssetDatabase.instance.deleteMultipleChanges(_selectedChangeIds.toList());
              
              // Refresh the list and exit selection mode
              await _refreshChanges();
              setState(() {
                _isSelectionMode = false;
                _selectedChangeIds.clear();
              });
              
              if (context.mounted) {
                Navigator.pop(context);
                
                // Show success message
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Deleted $selectedCount change records'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  // Method to delete individual change by passing the change object directly
  void _deleteIndividualChangeByObject(Map<String, dynamic> change) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: Text('Are you sure you want to delete this change record?\n\n"${change['description']}"\n\nThis action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () async {
              await AssetDatabase.instance.deleteChangeRecord(change['id']);
              await _refreshChanges();
              
              if (context.mounted) {
                Navigator.pop(context);
                
                // Show success message
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Change record deleted'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showChangeDetails(Map<String, dynamic> change) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${change['change_type']} Details'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Asset Name', change['asset_name']),
              if (change['asset_type'] != null)
                _buildDetailRow('Asset Type', change['asset_type']),
              if (change['old_value'] != null)
                _buildDetailRow('Previous Value', _formatCurrency(change['old_value'], change['currency'])),
              if (change['new_value'] != null)
                _buildDetailRow('New Value', _formatCurrency(change['new_value'], change['currency'])),
              _buildDetailRow('Currency', change['currency']),
              _buildDetailRow('Description', change['description']),
              _buildDetailRow('Date & Time', _formatDateTime(change['timestamp'])),
            ],
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

  Widget _buildDetailRow(String label, String? value) {
    if (value == null || value.isEmpty) return const SizedBox.shrink();
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  String _formatCurrency(double? amount, String? currency) {
    if (amount == null || currency == null) return 'N/A';
    
    final Map<String, String> currencySymbols = {
      'USD': '\$',
      'EUR': '€',
      'JPY': '¥',
      'IDR': 'Rp',
    };
    
    final Map<String, String> currencyLocales = {
      'USD': 'en_US',
      'EUR': 'de_DE', 
      'JPY': 'ja_JP',
      'IDR': 'id_ID',
    };
    
    final locale = currencyLocales[currency] ?? 'en_US';
    final symbol = currencySymbols[currency] ?? '\$';
    
    if (currency == 'IDR' || currency == 'JPY') {
      return NumberFormat.currency(
        locale: locale,
        symbol: symbol,
        decimalDigits: 0,
      ).format(amount);
    } else {
      return NumberFormat.currency(
        locale: locale,
        symbol: symbol,
      ).format(amount);
    }
  }

  String _formatDateTime(String? timestamp) {
    if (timestamp == null) return 'Unknown';
    
    try {
      final dateTime = DateTime.parse(timestamp);
      return DateFormat('MMM d, yyyy - h:mm a').format(dateTime);
    } catch (e) {
      return 'Invalid date';
    }
  }

  String _getTimeAgo(String? timestamp) {
    if (timestamp == null) return '';
    
    try {
      final dateTime = DateTime.parse(timestamp);
      final now = DateTime.now();
      final difference = now.difference(dateTime);
      
      if (difference.inMinutes < 1) {
        return 'Just now';
      } else if (difference.inHours < 1) {
        return '${difference.inMinutes}m ago';
      } else if (difference.inDays < 1) {
        return '${difference.inHours}h ago';
      } else if (difference.inDays < 7) {
        return '${difference.inDays}d ago';
      } else {
        return DateFormat('MMM d').format(dateTime);
      }
    } catch (e) {
      return '';
    }
  }

  Widget _buildGroupedChangesList() {
    final groupedChanges = _groupedChanges;
    
    if (groupedChanges.isEmpty) {
      return const Center(
        child: Text('No changes found for the selected filters.'),
      );
    }
    
    return ListView.builder(
      itemCount: groupedChanges.length,
      itemBuilder: (context, groupIndex) {
        final dateKey = groupedChanges.keys.elementAt(groupIndex);
        final dayChanges = groupedChanges[dateKey]!;
        
        // Format the date for display
        String displayDate;
        try {
          final date = DateTime.parse(dateKey);
          final now = DateTime.now();
          final today = DateTime(now.year, now.month, now.day);
          final changeDate = DateTime(date.year, date.month, date.day);
          
          if (changeDate == today) {
            displayDate = 'Today';
          } else if (changeDate == today.subtract(const Duration(days: 1))) {
            displayDate = 'Yesterday';
          } else {
            displayDate = DateFormat('EEEE, MMM d, yyyy').format(date);
          }
        } catch (e) {
          displayDate = dateKey;
        }
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: [
                  Text(
                    displayDate,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${dayChanges.length} ${dayChanges.length == 1 ? 'change' : 'changes'}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Changes for this day
            ...dayChanges.map((change) {
              final changeId = change['id'] as int;
              final isSelected = _selectedChangeIds.contains(changeId);
              
              return Card(
                margin: const EdgeInsets.fromLTRB(8, 2, 8, 2),
                elevation: isSelected ? 4 : 1,
                color: isSelected 
                    ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.1)
                    : null,
                child: ListTile(
                  leading: _isSelectionMode
                      ? Checkbox(
                          value: isSelected,
                          onChanged: (_) => _toggleChangeSelection(changeId),
                        )
                      : Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: _changeColors[change['change_type']]?.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Icon(
                            _changeIcons[change['change_type']] ?? Icons.help,
                            color: _changeColors[change['change_type']],
                            size: 20,
                          ),
                        ),
                  title: Text(
                    change['asset_name'] ?? 'Unknown Asset',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        change['description'] ?? 'No description',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            size: 12,
                            color: Colors.grey.shade600,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _getTimeAgo(change['timestamp']),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  trailing: _isSelectionMode
                      ? null
                      : PopupMenuButton(
                          itemBuilder: (context) => [
                            PopupMenuItem(
                              child: const Row(
                                children: [
                                  Icon(Icons.info_outline),
                                  SizedBox(width: 8),
                                  Text('View Details'),
                                ],
                              ),
                              onTap: () => _showChangeDetails(change),
                            ),
                            PopupMenuItem(
                              child: const Row(
                                children: [
                                  Icon(Icons.delete, color: Colors.red),
                                  SizedBox(width: 8),
                                  Text('Delete', 
                                      style: TextStyle(color: Colors.red)),
                                ],
                              ),
                              onTap: () => _deleteIndividualChangeByObject(change),
                            ),
                          ],
                        ),
                  onTap: _isSelectionMode
                      ? () => _toggleChangeSelection(changeId)
                      : () => _showChangeDetails(change),
                  onLongPress: !_isSelectionMode
                      ? () {
                          _toggleSelectionMode();
                          _toggleChangeSelection(changeId);
                        }
                      : null,
                ),
              );
            }),
            
            const SizedBox(height: 8), // Spacing between date groups
          ],
        );
      },
    );
  }
  
  String _getNoChangesTitle() {
    if (_selectedDate != null) {
      if (_filterType != 'ALL') {
        return 'No ${_filterLabels[_filterType]!.toLowerCase()} changes on ${DateFormat('MMM d, yyyy').format(_selectedDate!)}';
      } else {
        return 'No changes on ${DateFormat('MMM d, yyyy').format(_selectedDate!)}';
      }
    } else if (_filterType != 'ALL' && _selectedMonth != 'ALL') {
      return 'No ${_filterLabels[_filterType]!.toLowerCase()} changes in ${_formatMonthDisplay(_selectedMonth)}';
    } else if (_filterType != 'ALL') {
      return 'No ${_filterLabels[_filterType]!.toLowerCase()} changes found';
    } else if (_selectedMonth != 'ALL') {
      return 'No changes in ${_formatMonthDisplay(_selectedMonth)}';
    } else {
      return 'No changes recorded yet';
    }
  }
  
  String _getNoChangesSubtitle() {
    if (_selectedDate != null || _filterType != 'ALL' || _selectedMonth != 'ALL') {
      return 'Try changing the filters or create some assets to see changes';
    } else {
      return 'Asset changes will appear here as you create, edit, or delete assets';
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredChanges = _filteredChanges;
    
    return Scaffold(
      appBar: AppBar(
        title: _isSelectionMode 
            ? Text('${_selectedChangeIds.length} selected')
            : const Text('Changes History'),
        leading: _isSelectionMode
            ? IconButton(
                icon: const Icon(Icons.close),
                onPressed: _toggleSelectionMode,
              )
            : null,
        actions: [
          if (filteredChanges.isNotEmpty)
            _isSelectionMode
                ? PopupMenuButton(
                    icon: const Icon(Icons.more_vert),
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        child: Row(
                          children: [
                            Icon(_selectedChangeIds.length == filteredChanges.length 
                                ? Icons.deselect 
                                : Icons.select_all),
                            const SizedBox(width: 8),
                            Text(_selectedChangeIds.length == filteredChanges.length 
                                ? 'Deselect All' 
                                : 'Select All'),
                          ],
                        ),
                        onTap: () => _selectAllChanges(),
                      ),
                      if (_selectedChangeIds.isNotEmpty)
                        PopupMenuItem(
                          child: const Row(
                            children: [
                              Icon(Icons.delete, color: Colors.red),
                              SizedBox(width: 8),
                              Text('Delete Selected', 
                                  style: TextStyle(color: Colors.red)),
                            ],
                          ),
                          onTap: () => _deleteSelectedChanges(),
                        ),
                    ],
                  )
                : Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.filter_list),
                        onPressed: _showFilterDialog,
                        tooltip: 'Filter by type',
                      ),
                      IconButton(
                        icon: const Icon(Icons.calendar_today),
                        onPressed: _showCalendarDialog,
                        tooltip: 'Calendar view',
                      ),
                      if (filteredChanges.isNotEmpty)
                        IconButton(
                          icon: const Icon(Icons.checklist),
                          onPressed: _toggleSelectionMode,
                          tooltip: 'Select multiple',
                        ),
                    ],
                  ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : filteredChanges.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.history,
                        size: 64,
                        color: Colors.grey.shade500,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _getNoChangesTitle(),
                        style: const TextStyle(
                          fontSize: 18, 
                          fontWeight: FontWeight.bold
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _getNoChangesSubtitle(),
                        textAlign: TextAlign.center,
                      ),
                      if (_filterType != 'ALL' || _selectedMonth != 'ALL' || _selectedDate != null) ...[
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: () {
                            setState(() {
                              _filterType = 'ALL';
                              _selectedMonth = 'ALL';
                              _selectedDate = null;
                            });
                          },
                          icon: const Icon(Icons.clear_all),
                          label: const Text('Show All Changes'),
                        ),
                      ],
                    ],
                  ),
                )
              : Column(
                  children: [
                    // Filter indicators
                    if (_filterType != 'ALL' || _selectedMonth != 'ALL' || _selectedDate != null)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(8),
                        color: Colors.blue.withValues(alpha: 0.1),
                        child: Column(
                          children: [
                            if (_filterType != 'ALL')
                              Row(
                                children: [
                                  Icon(
                                    Icons.filter_list,
                                    size: 16,
                                    color: Colors.blue.shade700,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Type: ${_filterLabels[_filterType]}',
                                    style: TextStyle(
                                      color: Colors.blue.shade700,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const Spacer(),
                                  TextButton(
                                    onPressed: () {
                                      setState(() {
                                        _filterType = 'ALL';
                                      });
                                    },
                                    child: const Text('Clear'),
                                  ),
                                ],
                              ),
                            if (_selectedDate != null)
                              Row(
                                children: [
                                  Icon(
                                    Icons.calendar_today,
                                    size: 16,
                                    color: Colors.purple.shade700,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Date: ${DateFormat('MMM d, yyyy').format(_selectedDate!)}',
                                    style: TextStyle(
                                      color: Colors.purple.shade700,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const Spacer(),
                                  TextButton(
                                    onPressed: () {
                                      setState(() {
                                        _selectedDate = null;
                                      });
                                    },
                                    child: const Text('Clear'),
                                  ),
                                ],
                              )
                            else if (_selectedMonth != 'ALL')
                              Row(
                                children: [
                                  Icon(
                                    Icons.date_range,
                                    size: 16,
                                    color: Colors.green.shade700,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Month: ${_formatMonthDisplay(_selectedMonth)}',
                                    style: TextStyle(
                                      color: Colors.green.shade700,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const Spacer(),
                                  TextButton(
                                    onPressed: () {
                                      setState(() {
                                        _selectedMonth = 'ALL';
                                      });
                                    },
                                    child: const Text('Clear'),
                                  ),
                                ],
                              ),
                            if (_filterType != 'ALL' || _selectedMonth != 'ALL' || _selectedDate != null)
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  TextButton.icon(
                                    onPressed: () {
                                      setState(() {
                                        _filterType = 'ALL';
                                        _selectedMonth = 'ALL';
                                        _selectedDate = null;
                                      });
                                    },
                                    icon: const Icon(Icons.clear_all),
                                    label: const Text('Clear All Filters'),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ),
                    
                    // Changes list - grouped by date
                    Expanded(
                      child: _buildGroupedChangesList(),
                    ),
                  ],
                ),
    );
  }
}