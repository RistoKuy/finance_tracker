import 'package:flutter/material.dart';

class AssetMenu extends StatefulWidget {
  const AssetMenu({super.key});

  @override
  State<AssetMenu> createState() => _AssetMenuState();
}

class _AssetMenuState extends State<AssetMenu> {
  final List<Map<String, dynamic>> _assets = [];
  final _formKey = GlobalKey<FormState>();
  String _assetType = 'Transactional';
  String _assetName = '';
  double _assetNominal = 0.0;

  void _addOrEditAsset({int? index}) {
    if (index != null) {
      // Pre-fill form for editing
      final asset = _assets[index];
      _assetType = asset['type'];
      _assetName = asset['name'];
      _assetNominal = asset['nominal'];
    } else {
      // Reset form for adding
      _assetType = 'Transactional';
      _assetName = '';
      _assetNominal = 0.0;
    }

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(index == null ? 'Add Asset' : 'Edit Asset'),
          content: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: _assetType,
                  items: ['Transactional', 'Savings', 'Investment']
                      .map((type) => DropdownMenuItem(
                            value: type,
                            child: Text(type),
                          ))
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      _assetType = value!;
                    });
                  },
                  decoration: const InputDecoration(labelText: 'Asset Type'),
                ),
                TextFormField(
                  initialValue: _assetName,
                  decoration: const InputDecoration(labelText: 'Asset Name'),
                  onChanged: (value) {
                    _assetName = value;
                  },
                  validator: (value) =>
                      value == null || value.isEmpty ? 'Enter a name' : null,
                ),
                TextFormField(
                  initialValue: _assetNominal.toString(),
                  decoration: const InputDecoration(labelText: 'Asset Nominal'),
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
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  setState(() {
                    final asset = {
                      'type': _assetType,
                      'name': _assetName,
                      'nominal': _assetNominal,
                      'date': DateTime.now(),
                    };
                    if (index == null) {
                      _assets.add(asset);
                    } else {
                      _assets[index] = asset;
                    }
                  });
                  Navigator.pop(context);
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void _deleteAsset(int index) {
    setState(() {
      _assets.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Assets'),
      ),
      body: ListView.builder(
        itemCount: _assets.length,
        itemBuilder: (context, index) {
          final asset = _assets[index];
          return ListTile(
            title: Text('${asset['name']} (${asset['type']})'),
            subtitle: Text(
                'Nominal: ${asset['nominal']} - Last Updated: ${asset['date']}'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () => _addOrEditAsset(index: index),
                ),
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () => _deleteAsset(index),
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addOrEditAsset(),
        child: const Icon(Icons.add),
      ),
    );
  }
}
