// ignore_for_file: unused_local_variable, use_build_context_synchronously, deprecated_member_use, unnecessary_to_list_in_spreads

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'database/asset_database.dart';

class AssetMenu extends StatefulWidget {
  const AssetMenu({super.key});

  @override
  State<AssetMenu> createState() => _AssetMenuState();
}

class _AssetMenuState extends State<AssetMenu> {
  final List<Map<String, dynamic>> _assets = [];
  bool _isLoading = true;
  final _formKey = GlobalKey<FormState>();
  String _assetType = 'Transactional';
  String _assetName = '';
  double _assetNominal = 0.0;
  String _currency = 'USD'; // Default currency
  
  // Multiple selection mode
  bool _isSelectionMode = false;
  Set<int> _selectedAssetIds = {};
  
  // Controller for formatted asset value input
  final TextEditingController _assetValueController = TextEditingController();

  // Currency options
  final Map<String, String> _currencySymbols = {
    'USD': '\$',
    'EUR': '€',
    'JPY': '¥',
    'IDR': 'Rp',
  };
  
  final Map<String, String> _currencyLocales = {
    'USD': 'en_US',
    'EUR': 'de_DE',
    'JPY': 'ja_JP',
    'IDR': 'id_ID',
  };

  // Asset type specific colors and icons
  final Map<String, Color> _typeColors = {
    'Transactional': Colors.blue,
    'Savings': Colors.green,
    'Investment': Colors.amber,
  };

  final Map<String, IconData> _typeIcons = {
    'Transactional': Icons.account_balance_wallet,
    'Savings': Icons.savings,
    'Investment': Icons.trending_up,
  };

  // Format currency based on selected currency
  String formatCurrency(double amount, String currency) {
    final locale = _currencyLocales[currency] ?? 'en_US';
    final symbol = _currencySymbols[currency] ?? '\$';
    
    if (currency == 'IDR') {
      // Special case for IDR to show without decimal places
      return NumberFormat.currency(
        locale: locale,
        symbol: symbol,
        decimalDigits: 0,
      ).format(amount);
    } else if (currency == 'JPY') {
      // JPY typically doesn't use decimal places
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

  @override
  void initState() {
    super.initState();
    _refreshAssets();
  }

  Future<void> _refreshAssets() async {
    setState(() => _isLoading = true);
    final assets = await AssetDatabase.instance.readAllAssets();
    setState(() {
      _assets.clear();
      _assets.addAll(assets);
      _isLoading = false;
    });
  }

  void _addOrEditAsset({int? index}) {
    if (index != null) {
      // Pre-fill form for editing
      final asset = _assets[index];
      _assetType = asset['type'];
      _assetName = asset['name'];
      _assetNominal = asset['nominal'];
      _currency = asset['currency'];
      // Set the controller text with just the number value (without currency symbol)
      _assetValueController.text = _assetNominal.toString().replaceAll(RegExp(r'\.0+$'), '');
      // Format the number with thousand separators
      if (_assetNominal > 0) {
        String formattedValue = NumberFormat('#,###').format(_assetNominal.toInt());
        _assetValueController.text = formattedValue;
      }
    } else {
      // Reset form for adding
      _assetType = 'Transactional';
      _assetName = '';
      _assetNominal = 0.0;
      _assetValueController.clear();
      // Keep the last selected currency for convenience
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        // Create a StatefulBuilder to update the dialog content when currency changes
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(
                index == null ? 'Add New Asset' : 'Edit Asset',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              content: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Select asset type:'),
                      const SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade700),
                        ),
                        child: DropdownButtonFormField<String>(
                          value: _assetType,
                          decoration: const InputDecoration(
                            contentPadding: EdgeInsets.symmetric(horizontal: 16),
                            border: InputBorder.none,
                          ),
                          items: ['Transactional', 'Savings', 'Investment']
                              .map((type) => DropdownMenuItem(
                                    value: type,
                                    child: Row(
                                      children: [
                                        Icon(_typeIcons[type], color: _typeColors[type]),
                                        const SizedBox(width: 8),
                                        Text(type),
                                      ],
                                    ),
                                  ))
                              .toList(),
                          onChanged: (value) {
                            setState(() {
                              _assetType = value!;
                            });
                          },
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        initialValue: _assetName,
                        decoration: InputDecoration(
                          labelText: 'Asset Name',
                          prefixIcon: const Icon(Icons.label),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onChanged: (value) {
                          _assetName = value;
                        },
                        validator: (value) =>
                            value == null || value.isEmpty ? 'Enter a name' : null,
                      ),
                      const SizedBox(height: 16),
                      const Text('Select currency:'),
                      const SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade700),
                        ),
                        child: DropdownButtonFormField<String>(
                          value: _currency,
                          decoration: const InputDecoration(
                            contentPadding: EdgeInsets.symmetric(horizontal: 16),
                            border: InputBorder.none,
                          ),
                          items: _currencySymbols.entries
                              .map((entry) => DropdownMenuItem(
                                    value: entry.key,
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 28,
                                          height: 28,
                                          decoration: BoxDecoration(
                                            color: Colors.grey.shade800,
                                            shape: BoxShape.circle,
                                          ),
                                          alignment: Alignment.center,
                                          child: Text(
                                            entry.value,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text('${entry.key} (${entry.value})'),
                                      ],
                                    ),
                                  ))
                              .toList(),
                          onChanged: (value) {
                            // Update both the dialog state and the parent state
                            setDialogState(() {
                              _currency = value!;
                            });
                            setState(() {
                              _currency = value!;
                            });
                          },
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _assetValueController,
                        decoration: InputDecoration(
                          labelText: 'Asset Value',
                          hintText: '0.00',
                          prefixIcon: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 15),
                            child: Text(
                              _currencySymbols[_currency] ?? '\$',
                              style: const TextStyle(fontSize: 16),
                            ),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        keyboardType: TextInputType.number,
                        onChanged: (value) {
                          if (value.isEmpty) {
                            _assetNominal = 0.0;
                            return;
                          }
                          
                          // Remove any non-digit characters to get the raw number
                          String cleanedValue = value.replaceAll(RegExp(r'[^0-9]'), '');
                          
                          // Convert to double for storage
                          if (cleanedValue.isNotEmpty) {
                            _assetNominal = double.parse(cleanedValue);
                          } else {
                            _assetNominal = 0.0;
                          }
                          
                          // Only update the text field if we have a valid number
                          if (cleanedValue.isNotEmpty) {
                            // Format the cleaned value with thousand separators
                            String formattedValue = NumberFormat('#,###').format(int.parse(cleanedValue));
                            
                            // Only update if the formatted value is different to avoid cursor jumping
                            if (formattedValue != value) {
                              // Update the controller text with the formatted value and preserve cursor position
                              int cursorPosition = _assetValueController.selection.start;
                              // Calculate how many separators were before the cursor
                              int oldSeparatorsBeforeCursor = value.substring(0, cursorPosition).replaceAll(RegExp(r'[0-9]'), '').length;
                              // Calculate new cursor position
                              int newPosition = cursorPosition + (formattedValue.length - value.length);
                              if (newPosition < 0) newPosition = 0;
                              if (newPosition > formattedValue.length) newPosition = formattedValue.length;
                              
                              // Update the controller value
                              _assetValueController.value = TextEditingValue(
                                text: formattedValue,
                                selection: TextSelection.collapsed(offset: newPosition),
                              );
                            }
                          }
                        },
                        validator: (value) {
                          // Allow saving if the value hasn't changed or if it's a valid number
                          if (value == null || value.isEmpty) {
                            return 'Please enter an amount';
                          }
                          
                          String cleanedValue = value.replaceAll(RegExp(r'[^0-9]'), '');
                          if (cleanedValue.isEmpty) {
                            return 'Please enter a valid number';
                          }
                          
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.cancel),
                  label: const Text('Cancel'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.red,
                  ),
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                    elevation: 2,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () async {
                    if (_formKey.currentState!.validate()) {
                      final asset = {
                        'type': _assetType,
                        'name': _assetName,
                        'nominal': _assetNominal,
                        'currency': _currency,
                        'date': DateTime.now().toIso8601String(),
                      };
                      
                      // Save to database
                      if (index == null) {
                        // Create new asset
                        await AssetDatabase.instance.createAsset(asset);
                      } else {
                        // Update existing asset
                        await AssetDatabase.instance.updateAsset(
                          _assets[index]['id'],
                          asset,
                        );
                      }
                      
                      // Refresh the list
                      await _refreshAssets();
                      Navigator.pop(context);
                    }
                  },
                  icon: const Icon(Icons.save),
                  label: const Text(
                    'Save',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            );
          }
        );
      },
    );
  }

  void _deleteAsset(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: Text('Are you sure you want to delete ${_assets[index]['name']}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () async {
              await AssetDatabase.instance.deleteAsset(_assets[index]['id']);
              await _refreshAssets();
              Navigator.pop(context);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  // Get total assets by currency
  Map<String, double> _getTotalsByCurrency() {
    final Map<String, double> totals = {};
    
    for (final asset in _assets) {
      final String currency = asset['currency'];
      final double amount = asset['nominal'];
      
      if (totals.containsKey(currency)) {
        totals[currency] = totals[currency]! + amount;
      } else {
        totals[currency] = amount;
      }
    }
    
    return totals;
  }
  
  // Get sub-totals by asset type for each currency
  Map<String, Map<String, double>> _getSubTotalsByTypeAndCurrency() {
    final Map<String, Map<String, double>> subTotals = {};
    
    for (final asset in _assets) {
      final String currency = asset['currency'];
      final String type = asset['type'];
      final double amount = asset['nominal'];
      
      if (!subTotals.containsKey(currency)) {
        subTotals[currency] = {};
      }
      
      if (subTotals[currency]!.containsKey(type)) {
        subTotals[currency]![type] = subTotals[currency]![type]! + amount;
      } else {
        subTotals[currency]![type] = amount;
      }
    }
    
    return subTotals;
  }
  
  // Build the Total Assets summary widget
  Widget _buildTotalAssetsWidget() {
    // Get totals
    final Map<String, double> totals = _getTotalsByCurrency();
    final Map<String, Map<String, double>> subTotals = _getSubTotalsByTypeAndCurrency();
    
    return Card(
      elevation: 3,
      margin: const EdgeInsets.all(8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: Colors.purple.withOpacity(0.5),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title section
            Row(
              children: [
                Container(
                  width: 45,
                  height: 45,
                  decoration: BoxDecoration(
                    color: Colors.purple.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(22.5),
                  ),
                  child: const Icon(
                    Icons.account_balance,
                    color: Colors.purple,
                    size: 25,
                  ),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Text(
                    'Total Assets',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Row(
                          children: [
                            Icon(Icons.info_outline, color: Colors.blue),
                            SizedBox(width: 8),
                            Text('Asset Totals Information'),
                          ],
                        ),
                        content: const SingleChildScrollView(
                          child: ListBody(
                            children: [
                              Text('This section shows the total value of all your assets grouped by currency.'),
                              SizedBox(height: 8),
                              Text('• Each currency is displayed separately as they cannot be directly combined.'),
                              SizedBox(height: 8),
                              Text('• Below each currency total, you can see a breakdown by asset type (Transactional, Savings, and Investment).'),
                              SizedBox(height: 8),
                              Text('• The percentage shows how much of your portfolio each type represents within that currency.'),
                            ],
                          ),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Got it'),
                          ),
                        ],
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.info_outline,
                      color: Colors.blue,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 16),
            
            // No assets case
            if (totals.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Text(
                    'No assets to display',
                    style: TextStyle(
                      fontSize: 16,
                      fontStyle: FontStyle.italic,
                      color: Colors.grey,
                    ),
                  ),
                ),
              )
            else
              // Display each currency total with its breakdown
              ...totals.entries.map((entry) {
                final String currency = entry.key;
                final double totalAmount = entry.value;
                final Map<String, double>? currencySubTotals = subTotals[currency];
                
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Currency total
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade800,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            currency,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade200,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          formatCurrency(totalAmount, currency),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    
                    // Subtotals by asset type for this currency
                    ...?currencySubTotals?.entries.map((typeEntry) {
                      final String type = typeEntry.key;
                      final double typeAmount = typeEntry.value;
                      final double percentage = (typeAmount / totalAmount) * 100;
                      
                      return Padding(
                        padding: const EdgeInsets.only(left: 24, bottom: 8),
                        child: Row(
                          children: [
                            Icon(
                              _typeIcons[type],
                              color: _typeColors[type],
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                type,
                                style: TextStyle(
                                  color: _typeColors[type],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            Text(
                              formatCurrency(typeAmount, currency),
                              style: TextStyle(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: _typeColors[type]!.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                '${percentage.toStringAsFixed(1)}%',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: _typeColors[type],
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                    
                    // Add divider between currencies
                    if (currency != totals.keys.last)
                      Column(
                        children: [
                          const SizedBox(height: 8),
                          Divider(color: Colors.grey.shade700),
                          const SizedBox(height: 16),
                        ],
                      ),
                  ],
                );
              }).toList(),
          ],
        ),
      ),
    );
  }

  void _showAssetDetails(Map<String, dynamic> asset) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Asset Details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Name: ${asset['name']}'),
            Text('Type: ${asset['type']}'),
            Text('Value: ${formatCurrency(asset['nominal'], asset['currency'])}'),
            Text('Currency: ${asset['currency']}'),
            Text('Date: ${DateFormat('MMM d, yyyy - h:mm a').format(DateTime.parse(asset['date']))}'),
          ],
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

  // Toggle selection mode
  void _toggleSelectionMode() {
    setState(() {
      _isSelectionMode = !_isSelectionMode;
      // Clear selections when exiting selection mode
      if (!_isSelectionMode) {
        _selectedAssetIds.clear();
      }
    });
  }
  
  // Toggle selection of a specific asset
  void _toggleAssetSelection(int assetId) {
    setState(() {
      if (_selectedAssetIds.contains(assetId)) {
        _selectedAssetIds.remove(assetId);
      } else {
        _selectedAssetIds.add(assetId);
      }
      
      // If no items selected, exit selection mode
      if (_selectedAssetIds.isEmpty && _isSelectionMode) {
        _isSelectionMode = false;
      }
    });
  }
  
  // Select all assets
  void _selectAllAssets() {
    setState(() {
      if (_selectedAssetIds.length == _assets.length) {
        // If all are selected, deselect all
        _selectedAssetIds.clear();
      } else {
        // Select all
        _selectedAssetIds = _assets.map((asset) => asset['id'] as int).toSet();
      }
    });
  }
  
  // Delete multiple assets
  void _deleteSelectedAssets() {
    if (_selectedAssetIds.isEmpty) return;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: Text(
          'Are you sure you want to delete ${_selectedAssetIds.length} selected ${_selectedAssetIds.length == 1 ? 'asset' : 'assets'}?'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () async {
              // Delete all selected assets
              for (final id in _selectedAssetIds) {
                await AssetDatabase.instance.deleteAsset(id);
              }
              
              // Refresh the list and exit selection mode
              await _refreshAssets();
              setState(() {
                _isSelectionMode = false;
                _selectedAssetIds.clear();
              });
              
              Navigator.pop(context);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _isSelectionMode 
          ? Text('${_selectedAssetIds.length} selected')
          : const Text('Assets'),
        leading: _isSelectionMode
          ? IconButton(
              icon: const Icon(Icons.close),
              onPressed: _toggleSelectionMode,
            )
          : null,
        actions: [
          if (_assets.isNotEmpty)
            _isSelectionMode
              ? Row(
                  children: [
                    // Select all button
                    IconButton(
                      icon: Icon(
                        _selectedAssetIds.length == _assets.length
                            ? Icons.select_all
                            : Icons.check_box_outline_blank,
                      ),
                      tooltip: 'Select all',
                      onPressed: _selectAllAssets,
                    ),
                    // Delete selected button
                    IconButton(
                      icon: const Icon(Icons.delete),
                      tooltip: 'Delete selected',
                      onPressed: _selectedAssetIds.isNotEmpty
                          ? _deleteSelectedAssets
                          : null,
                    ),
                  ],
                )
              : IconButton(
                  icon: const Icon(Icons.sort),
                  tooltip: 'Sort assets',
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => SimpleDialog(
                        title: const Text('Sort by'),
                        children: [
                          _buildSortOption('Name', () {
                            setState(() {
                              _assets.sort((a, b) => a['name'].compareTo(b['name']));
                            });
                            Navigator.pop(context);
                          }),
                          _buildSortOption('Value (High to Low)', () {
                            setState(() {
                              _assets.sort((a, b) => b['nominal'].compareTo(a['nominal']));
                            });
                            Navigator.pop(context);
                          }),
                          _buildSortOption('Most Recent', () {
                            setState(() {
                              _assets.sort((a, b) => b['date'].compareTo(a['date']));
                            });
                            Navigator.pop(context);
                          }),
                        ],
                      ),
                    );
                  },
                ),
          // Selection mode toggle
          if (_assets.isNotEmpty && !_isSelectionMode)
            IconButton(
              icon: const Icon(Icons.checklist),
              tooltip: 'Select multiple',
              onPressed: _toggleSelectionMode,
            ),
        ],
      ),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator())
          : _assets.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.account_balance,
                        size: 80,
                        color: Colors.grey.shade500,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'No assets added yet',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      const Text('Tap the + button to add your first asset'),
                      const SizedBox(height: 24),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Total Assets Summary
                      _buildTotalAssetsWidget(),
                      
                      // Individual Assets List Title
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                        child: Row(
                          children: [
                            const Text(
                              'Your Assets',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade800,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${_assets.length}',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey.shade200,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      // Individual Assets List - No longer in an Expanded widget
                      ListView.builder(
                        padding: const EdgeInsets.all(8),
                        shrinkWrap: true, // Important to make ListView work inside ScrollView
                        physics: const NeverScrollableScrollPhysics(), // Disable ListView's scrolling
                        itemCount: _assets.length,
                        itemBuilder: (context, index) {
                          final asset = _assets[index];
                          final DateTime assetDate = DateTime.parse(asset['date']);
                          
                          return Card(
                            elevation: 2,
                            margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(
                                color: _selectedAssetIds.contains(asset['id'])
                                    ? Colors.blue
                                    : _typeColors[asset['type']]!.withOpacity(0.5),
                                width: _selectedAssetIds.contains(asset['id']) ? 2 : 1,
                              ),
                            ),
                            child: InkWell(
                              onTap: _isSelectionMode
                                ? () => _toggleAssetSelection(asset['id'])
                                : () => _showAssetDetails(asset), // Make card tappable to show details
                              onLongPress: !_isSelectionMode
                                ? () {
                                    _toggleSelectionMode();
                                    _toggleAssetSelection(asset['id']);
                                  }
                                : null,
                              child: Padding(
                                padding: const EdgeInsets.all(12.0), // Reduced padding
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Main info row
                                    Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        // Selection checkbox (shown only in selection mode)
                                        if (_isSelectionMode)
                                          Padding(
                                            padding: const EdgeInsets.only(right: 8),
                                            child: Container(
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                color: _selectedAssetIds.contains(asset['id'])
                                                    ? Colors.blue
                                                    : Colors.grey.shade300.withOpacity(0.3),
                                              ),
                                              child: Padding(
                                                padding: const EdgeInsets.all(2.0),
                                                child: _selectedAssetIds.contains(asset['id'])
                                                    ? const Icon(Icons.check, size: 18, color: Colors.white)
                                                    : const Icon(Icons.circle_outlined, size: 18, color: Colors.white70),
                                              ),
                                            ),
                                          ),
                                        
                                        // Asset type icon - smaller
                                        Container(
                                          width: 40, // Smaller icon
                                          height: 40,
                                          decoration: BoxDecoration(
                                            color: _typeColors[asset['type']]!.withOpacity(0.2),
                                            borderRadius: BorderRadius.circular(20),
                                          ),
                                          child: Icon(
                                            _typeIcons[asset['type']],
                                            color: _typeColors[asset['type']],
                                            size: 24, // Smaller icon
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        
                                        // Asset info - responsive layout
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  // Asset name with ellipsis
                                                  Expanded(
                                                    child: Tooltip(
                                                      message: asset['name'],
                                                      child: Text(
                                                        asset['name'],
                                                        style: const TextStyle(
                                                          fontSize: 16, // Slightly smaller
                                                          fontWeight: FontWeight.bold,
                                                        ),
                                                        maxLines: 1,
                                                        overflow: TextOverflow.ellipsis,
                                                      ),
                                                    ),
                                                  ),
                                                  
                                                  // Details icon for any asset
                                                  GestureDetector(
                                                    onTap: () => _showAssetDetails(asset),
                                                    child: Container(
                                                      margin: const EdgeInsets.only(left: 4),
                                                      padding: const EdgeInsets.all(2),
                                                      decoration: BoxDecoration(
                                                        color: Colors.grey.shade800.withOpacity(0.3),
                                                        shape: BoxShape.circle,
                                                      ),
                                                      child: const Icon(
                                                        Icons.info_outline,
                                                        size: 14,
                                                        color: Colors.white70,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              
                                              const SizedBox(height: 4),
                                              
                                              // Asset type and currency
                                              Row(
                                                children: [
                                                  Text(
                                                    asset['type'],
                                                    style: TextStyle(
                                                      fontSize: 12, // Smaller
                                                      color: _typeColors[asset['type']],
                                                      fontWeight: FontWeight.w500,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                                    decoration: BoxDecoration(
                                                      color: Colors.grey.shade800,
                                                      borderRadius: BorderRadius.circular(3),
                                                    ),
                                                    child: Text(
                                                      asset['currency'],
                                                      style: TextStyle(
                                                        fontSize: 10,
                                                        color: Colors.grey.shade300,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                        
                                        // Asset value
                                        Tooltip(
                                          message: formatCurrency(asset['nominal'], asset['currency']),
                                          child: Container(
                                            constraints: const BoxConstraints(maxWidth: 120), // More constrained
                                            child: Text(
                                              formatCurrency(asset['nominal'], asset['currency']),
                                              style: const TextStyle(
                                                fontSize: 16, // Smaller font
                                                fontWeight: FontWeight.bold,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    
                                    const SizedBox(height: 8), // Smaller gap
                                    
                                    // Bottom row with date and action buttons
                                    Row(
                                      crossAxisAlignment: CrossAxisAlignment.center,
                                      children: [
                                        // Date with shorter format
                                        Expanded(
                                          child: Text(
                                            'Updated: ${DateFormat('MM/dd/yy').format(assetDate)}',
                                            style: TextStyle(
                                              fontSize: 11, // Smaller
                                              color: Colors.grey.shade400,
                                            ),
                                          ),
                                        ),
                                        
                                        // Action buttons - more compact
                                        Row(
                                          children: [
                                            // Edit button - compact
                                            ElevatedButton.icon(
                                              onPressed: () => _addOrEditAsset(index: index),
                                              icon: const Icon(Icons.edit, size: 16),
                                              label: const Text('Edit', 
                                                style: TextStyle(fontSize: 12),
                                              ),
                                              style: ElevatedButton.styleFrom(
                                                foregroundColor: Colors.white,
                                                backgroundColor: Colors.blue.shade700,
                                                minimumSize: const Size(60, 30),
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(6),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 6),
                                            // Delete button - compact
                                            ElevatedButton.icon(
                                              onPressed: () => _deleteAsset(index),
                                              icon: const Icon(Icons.delete, size: 16),
                                              label: const Text('Delete',
                                                style: TextStyle(fontSize: 12),
                                              ),
                                              style: ElevatedButton.styleFrom(
                                                foregroundColor: Colors.white,
                                                backgroundColor: Colors.red.shade700,
                                                minimumSize: const Size(60, 30),
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(6),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addOrEditAsset(),
        tooltip: 'Add Asset',
        icon: const Icon(Icons.add),
        label: const Text('Add Asset'),
      ),
    );
  }

  Widget _buildSortOption(String title, VoidCallback onTap) {
    return SimpleDialogOption(
      onPressed: onTap,
      child: Row(
        children: [
          const Icon(Icons.sort),
          const SizedBox(width: 8),
          Text(title),
        ],
      ),
    );
  }
}
