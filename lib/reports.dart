// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'database/asset_database.dart';
import 'constants/date_format_manager.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  bool _isLoading = true;
  bool _showMonthly = true; // true = monthly, false = yearly
  String? _selectedCurrency; // null = show all, otherwise filter by currency
  List<Map<String, dynamic>> _assets = [];
  List<Map<String, dynamic>> _changes = [];
  
  // Processed data for charts
  final Map<String, List<TotalAssetSnapshot>> _snapshotsByCurrency = {};
  
  // Available currencies (only those with assets)
  List<String> get _availableCurrencies {
    final currencies = <String>{};
    for (final asset in _assets) {
      currencies.add(asset['currency'] as String);
    }
    final list = currencies.toList()..sort();
    return list;
  }
  
  // Filtered snapshots based on selected currency
  Map<String, List<TotalAssetSnapshot>> get _filteredSnapshots {
    if (_selectedCurrency == null) {
      return _snapshotsByCurrency;
    }
    return {
      if (_snapshotsByCurrency.containsKey(_selectedCurrency))
        _selectedCurrency!: _snapshotsByCurrency[_selectedCurrency]!,
    };
  }
  
  @override
  void initState() {
    super.initState();
    _loadData();
  }
  
  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    final assets = await AssetDatabase.instance.readAllAssets();
    final changes = await AssetDatabase.instance.readAllChanges();
    
    setState(() {
      _assets = assets;
      _changes = changes;
      _processSnapshots();
      _isLoading = false;
    });
  }
  
  void _processSnapshots() {
    _snapshotsByCurrency.clear();
    
    // Get all unique currencies
    final currencies = <String>{};
    for (final asset in _assets) {
      currencies.add(asset['currency'] as String);
    }
    for (final change in _changes) {
      currencies.add(change['currency'] as String);
    }
    
    // Process snapshots for each currency
    for (final currency in currencies) {
      final snapshots = _calculateSnapshots(currency);
      if (snapshots.isNotEmpty) {
        _snapshotsByCurrency[currency] = snapshots;
      }
    }
  }
  
  List<TotalAssetSnapshot> _calculateSnapshots(String currency) {
    final snapshots = <TotalAssetSnapshot>[];
    
    // Get changes for this currency, sorted by date
    final currencyChanges = _changes
        .where((c) => c['currency'] == currency)
        .toList();
    
    if (currencyChanges.isEmpty) {
      // If no changes, create a snapshot from current assets
      double total = 0;
      for (final asset in _assets) {
        if (asset['currency'] == currency) {
          total += (asset['nominal'] as num).toDouble();
        }
      }
      
      if (total > 0) {
        final now = DateTime.now();
        snapshots.add(TotalAssetSnapshot(
          date: DateTime(now.year, now.month),
          total: total,
          currency: currency,
        ));
      }
      return snapshots;
    }
    
    // Sort changes by timestamp
    currencyChanges.sort((a, b) {
      final aDate = DateTime.parse(a['timestamp'] as String);
      final bDate = DateTime.parse(b['timestamp'] as String);
      return aDate.compareTo(bDate);
    });
    
    // Group changes by month or year
    final groupedSnapshots = <String, double>{};
    
    // Start with current total and work backwards, or calculate running total
    double runningTotal = 0;
    
    // Calculate current total for this currency
    for (final asset in _assets) {
      if (asset['currency'] == currency) {
        runningTotal += (asset['nominal'] as num).toDouble();
      }
    }
    
    // Add current month snapshot
    final now = DateTime.now();
    final currentKey = _showMonthly 
        ? '${now.year}-${now.month.toString().padLeft(2, '0')}'
        : '${now.year}';
    groupedSnapshots[currentKey] = runningTotal;
    
    // Process changes in reverse to reconstruct historical totals
    final reversedChanges = currencyChanges.reversed.toList();
    double historicalTotal = runningTotal;
    
    for (final change in reversedChanges) {
      final timestamp = DateTime.parse(change['timestamp'] as String);
      final key = _showMonthly 
          ? '${timestamp.year}-${timestamp.month.toString().padLeft(2, '0')}'
          : '${timestamp.year}';
      
      final changeType = change['change_type'] as String;
      final oldValue = (change['old_value'] as num?)?.toDouble() ?? 0;
      final newValue = (change['new_value'] as num?)?.toDouble() ?? 0;
      
      // Reverse the change to get previous state
      switch (changeType) {
        case 'CREATE':
          historicalTotal -= newValue;
          break;
        case 'DELETE':
        case 'BULK_DELETE':
          historicalTotal += oldValue;
          break;
        case 'UPDATE':
          historicalTotal = historicalTotal - newValue + oldValue;
          break;
      }
      
      // Store the snapshot for this period (last value wins)
      if (!groupedSnapshots.containsKey(key) || 
          _parseDate(key).isBefore(_parseDate(currentKey))) {
        groupedSnapshots[key] = historicalTotal > 0 ? historicalTotal : 0;
      }
    }
    
    // Convert to list and sort
    for (final entry in groupedSnapshots.entries) {
      snapshots.add(TotalAssetSnapshot(
        date: _parseDate(entry.key),
        total: entry.value,
        currency: currency,
      ));
    }
    
    snapshots.sort((a, b) => a.date.compareTo(b.date));
    
    // Keep only last 12 months or 5 years
    final maxItems = _showMonthly ? 12 : 5;
    if (snapshots.length > maxItems) {
      return snapshots.sublist(snapshots.length - maxItems);
    }
    
    return snapshots;
  }
  
  DateTime _parseDate(String key) {
    final parts = key.split('-');
    final year = int.parse(parts[0]);
    final month = parts.length > 1 ? int.parse(parts[1]) : 1;
    return DateTime(year, month);
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports'),
        backgroundColor: Colors.indigo.shade700,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: _loadData,
          ),
        ],
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _snapshotsByCurrency.isEmpty
                ? _buildEmptyState()
                : SingleChildScrollView(
                    padding: EdgeInsets.only(
                      left: 16,
                      right: 16,
                      top: 16,
                      bottom: 16 + MediaQuery.of(context).padding.bottom,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Toggle button for monthly/yearly
                        _buildToggleButton(),
                        const SizedBox(height: 16),
                        
                        // Currency filter
                        _buildCurrencyFilter(),
                        const SizedBox(height: 24),
                        
                        // Charts for filtered currencies
                        ..._filteredSnapshots.entries.map((entry) {
                          return Column(
                            children: [
                              _buildCurrencyChart(entry.key, entry.value),
                              const SizedBox(height: 24),
                            ],
                          );
                        }),
                        
                        // Snapshots list
                        _buildSnapshotsList(),
                      ],
                    ),
                  ),
      ),
    );
  }
  
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.bar_chart,
            size: 80,
            color: Colors.grey.shade500,
          ),
          const SizedBox(height: 16),
          const Text(
            'No data to display',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text('Add some assets to see your reports'),
        ],
      ),
    );
  }
  
  Widget _buildToggleButton() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('View: ', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(width: 8),
            ToggleButtons(
              isSelected: [_showMonthly, !_showMonthly],
              onPressed: (index) {
                setState(() {
                  _showMonthly = index == 0;
                  _processSnapshots();
                });
              },
              borderRadius: BorderRadius.circular(8),
              selectedColor: Colors.white,
              fillColor: Colors.indigo.shade700,
              children: const [
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Text('Monthly'),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Text('Yearly'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildCurrencyFilter() {
    final currencies = _availableCurrencies;
    if (currencies.isEmpty) return const SizedBox.shrink();
    
    final currencySymbols = {
      'USD': '\$',
      'EUR': '€',
      'JPY': '¥',
      'IDR': 'Rp',
    };
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.filter_list, color: Colors.indigo.shade600, size: 20),
                const SizedBox(width: 8),
                const Text('Currency: ', style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                // "All" option
                ChoiceChip(
                  label: const Text('All'),
                  selected: _selectedCurrency == null,
                  onSelected: (selected) {
                    setState(() {
                      _selectedCurrency = null;
                    });
                  },
                  selectedColor: Colors.indigo.shade600,
                  labelStyle: TextStyle(
                    color: _selectedCurrency == null ? Colors.white : null,
                    fontWeight: _selectedCurrency == null ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                // Currency options
                ...currencies.map((currency) {
                  final isSelected = _selectedCurrency == currency;
                  final symbol = currencySymbols[currency] ?? '';
                  return ChoiceChip(
                    label: Text('$currency ($symbol)'),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _selectedCurrency = selected ? currency : null;
                      });
                    },
                    selectedColor: Colors.indigo.shade600,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : null,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  );
                }),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildCurrencyChart(String currency, List<TotalAssetSnapshot> snapshots) {
    if (snapshots.isEmpty) return const SizedBox.shrink();
    
    final currencySymbols = {
      'USD': '\$',
      'EUR': '€',
      'JPY': '¥',
      'IDR': 'Rp',
    };
    
    final symbol = currencySymbols[currency] ?? '\$';
    
    // Find max value for scaling
    double maxValue = snapshots.map((s) => s.total).reduce((a, b) => a > b ? a : b);
    if (maxValue == 0) maxValue = 100;
    
    // Create line chart data
    final spots = <FlSpot>[];
    for (var i = 0; i < snapshots.length; i++) {
      spots.add(FlSpot(i.toDouble(), snapshots[i].total));
    }
    
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.indigo.shade200, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.indigo.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    currency,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.indigo.shade800,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Total Assets Over Time',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            // Chart
            SizedBox(
              height: 250,
              child: spots.length < 2
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.info_outline, color: Colors.grey.shade400, size: 48),
                          const SizedBox(height: 8),
                          Text(
                            'Need at least 2 data points for chart',
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Current: $symbol${_formatNumber(snapshots.first.total)}',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    )
                  : LineChart(
                      LineChartData(
                        gridData: FlGridData(
                          show: true,
                          drawVerticalLine: false,
                          horizontalInterval: maxValue / 5,
                          getDrawingHorizontalLine: (value) {
                            return FlLine(
                              color: Colors.grey.shade300,
                              strokeWidth: 1,
                            );
                          },
                        ),
                        titlesData: FlTitlesData(
                          show: true,
                          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 30,
                              interval: 1,
                              getTitlesWidget: (value, meta) {
                                final index = value.toInt();
                                if (index < 0 || index >= snapshots.length) {
                                  return const SizedBox.shrink();
                                }
                                final snapshot = snapshots[index];
                                final label = _showMonthly
                                    ? DateFormat('MMM').format(snapshot.date)
                                    : '${snapshot.date.year}';
                                return Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Text(
                                    label,
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 60,
                              interval: maxValue / 5,
                              getTitlesWidget: (value, meta) {
                                return Text(
                                  _formatCompactNumber(value),
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.grey.shade600,
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        borderData: FlBorderData(show: false),
                        minX: 0,
                        maxX: (snapshots.length - 1).toDouble(),
                        minY: 0,
                        maxY: maxValue * 1.1,
                        lineBarsData: [
                          LineChartBarData(
                            spots: spots,
                            isCurved: true,
                            color: Colors.indigo.shade600,
                            barWidth: 3,
                            isStrokeCapRound: true,
                            dotData: FlDotData(
                              show: true,
                              getDotPainter: (spot, percent, barData, index) {
                                return FlDotCirclePainter(
                                  radius: 5,
                                  color: Colors.indigo.shade600,
                                  strokeWidth: 2,
                                  strokeColor: Colors.white,
                                );
                              },
                            ),
                            belowBarData: BarAreaData(
                              show: true,
                              color: Colors.indigo.shade100.withAlpha(128),
                            ),
                          ),
                        ],
                        lineTouchData: LineTouchData(
                          touchTooltipData: LineTouchTooltipData(
                            getTooltipColor: (touchedSpot) => Colors.indigo.shade800,
                            getTooltipItems: (touchedSpots) {
                              return touchedSpots.map((spot) {
                                final index = spot.x.toInt();
                                final snapshot = snapshots[index];
                                final dateLabel = _showMonthly
                                    ? DateFormat('MMM yyyy').format(snapshot.date)
                                    : '${snapshot.date.year}';
                                return LineTooltipItem(
                                  '$dateLabel\n$symbol${_formatNumber(spot.y)}',
                                  const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                );
                              }).toList();
                            },
                          ),
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSnapshotsList() {
    final currencySymbols = {
      'USD': '\$',
      'EUR': '€',
      'JPY': '¥',
      'IDR': 'Rp',
    };
    
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.list_alt,
                  color: Colors.indigo.shade700,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  _showMonthly ? 'Monthly Snapshots' : 'Yearly Snapshots',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.indigo.shade700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            
            if (_snapshotsByCurrency.isEmpty)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: Text('No snapshots available')),
              )
            else
              ..._snapshotsByCurrency.entries.expand((entry) {
                final currency = entry.key;
                final snapshots = entry.value;
                final symbol = currencySymbols[currency] ?? '\$';
                
                // Reverse to show newest first
                final reversedSnapshots = snapshots.reversed.toList();
                
                return [
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                    margin: const EdgeInsets.only(top: 8),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      currency,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade800,
                      ),
                    ),
                  ),
                  ...reversedSnapshots.map((snapshot) {
                    final dateLabel = _showMonthly
                        ? DateFormat(DateFormatManager.monthYearFormat).format(snapshot.date)
                        : '${snapshot.date.year}';
                    
                    return ListTile(
                      dense: true,
                      leading: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.indigo.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          _showMonthly ? Icons.calendar_month : Icons.calendar_today,
                          color: Colors.indigo.shade600,
                          size: 20,
                        ),
                      ),
                      title: Text(
                        dateLabel,
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      trailing: Text(
                        '$symbol${_formatNumber(snapshot.total)}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.indigo.shade700,
                        ),
                      ),
                    );
                  }),
                ];
              }),
          ],
        ),
      ),
    );
  }
  
  String _formatNumber(double value) {
    if (value >= 1000000000) {
      return '${(value / 1000000000).toStringAsFixed(2)}B';
    } else if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(2)}M';
    } else if (value >= 1000) {
      return NumberFormat('#,###').format(value.round());
    }
    return value.toStringAsFixed(2);
  }
  
  String _formatCompactNumber(double value) {
    if (value >= 1000000000) {
      return '${(value / 1000000000).toStringAsFixed(1)}B';
    } else if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)}M';
    } else if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)}K';
    }
    return value.toStringAsFixed(0);
  }
}

/// Represents a snapshot of total assets at a specific point in time
class TotalAssetSnapshot {
  final DateTime date;
  final double total;
  final String currency;
  
  TotalAssetSnapshot({
    required this.date,
    required this.total,
    required this.currency,
  });
}
