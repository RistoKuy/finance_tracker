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
    } else {
      // Reset form for adding
      _assetType = 'Transactional';
      _assetName = '';
      _assetNominal = 0.0;
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
                        initialValue: _assetNominal > 0 ? _assetNominal.toString() : '',
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
                          _assetNominal = double.tryParse(value) ?? 0.0;
                        },
                        validator: (value) =>
                            value == null || double.tryParse(value) == null
                                ? 'Enter a valid number'
                                : null,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Assets'),
        actions: [
          if (_assets.isNotEmpty)
            IconButton(
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
              : ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: _assets.length,
                  itemBuilder: (context, index) {
                    final asset = _assets[index];
                    // For the date, parse it from string back to DateTime
                    final DateTime assetDate = DateTime.parse(asset['date']);
                    
                    return Card(
                      elevation: 2,
                      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: _typeColors[asset['type']]!.withOpacity(0.5),
                          width: 1,
                        ),
                      ),
                      // Removed the InkWell to make the card non-touchable
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header row with asset info and larger action buttons
                            Row(
                              children: [
                                Container(
                                  width: 50,
                                  height: 50,
                                  decoration: BoxDecoration(
                                    color: _typeColors[asset['type']]!.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(25),
                                  ),
                                  child: Icon(
                                    _typeIcons[asset['type']],
                                    color: _typeColors[asset['type']],
                                    size: 30,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        asset['name'],
                                        style: const TextStyle(
                                            fontSize: 18, fontWeight: FontWeight.bold),
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Text(
                                            asset['type'],
                                            style: TextStyle(
                                              color: _typeColors[asset['type']],
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: Colors.grey.shade800,
                                              borderRadius: BorderRadius.circular(4),
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
                                Text(
                                  formatCurrency(asset['nominal'], asset['currency']),
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            // Bottom row with date and more accessible action buttons
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    'Last updated: ${DateFormat('MMM d, yyyy - h:mm a').format(assetDate)}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade400,
                                    ),
                                  ),
                                ),
                                // More accessible action buttons for mobile users
                                Row(
                                  children: [
                                    // Edit button - larger and more touchable
                                    ElevatedButton.icon(
                                      onPressed: () => _addOrEditAsset(index: index),
                                      icon: const Icon(Icons.edit),
                                      label: const Text('Edit'),
                                      style: ElevatedButton.styleFrom(
                                        foregroundColor: Colors.white,
                                        backgroundColor: Colors.blue.shade700,
                                        minimumSize: const Size(100, 36),
                                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    // Delete button - larger and more touchable
                                    ElevatedButton.icon(
                                      onPressed: () => _deleteAsset(index),
                                      icon: const Icon(Icons.delete),
                                      label: const Text('Delete'),
                                      style: ElevatedButton.styleFrom(
                                        foregroundColor: Colors.white,
                                        backgroundColor: Colors.red.shade700,
                                        minimumSize: const Size(100, 36),
                                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(8),
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
                    );
                  },
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
