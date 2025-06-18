import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:fresh_marikiti/core/models/vendor_models.dart';
import 'package:fresh_marikiti/core/services/api_service.dart';
import 'package:fresh_marikiti/core/utils/api_endpoints.dart';
import 'package:fresh_marikiti/core/services/logger_service.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({Key? key}) : super(key: key);

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen>
    with TickerProviderStateMixin {
  List<InventoryItem> _inventory = [];
  List<InventoryItem> _filteredInventory = [];
  List<StockAlert> _stockAlerts = [];
  bool _isLoading = true;
  String _selectedFilter = 'all';
  String _searchQuery = '';
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  bool _isSelectionMode = false;
  Set<String> _selectedItems = {};

  final List<String> _filterOptions = [
    'all',
    'in_stock',
    'low_stock',
    'out_of_stock',
    'discontinued'
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _filterOptions.length, vsync: this);
    _loadInventoryData();
    _setupPeriodicRefresh();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _setupPeriodicRefresh() {
    Future.delayed(const Duration(minutes: 2), () {
      if (mounted) {
        _loadInventoryData();
        _setupPeriodicRefresh();
      }
    });
  }

  Future<void> _loadInventoryData() async {
    setState(() => _isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      final responses = await Future.wait([
        ApiService.get(ApiEndpoints.vendorInventory),
        ApiService.get(ApiEndpoints.vendorInventoryAlerts),
      ]);

      if (responses.every((response) => response.statusCode == 200)) {
        final inventoryData = json.decode(responses[0].body);
        final alertsData = json.decode(responses[1].body);

        setState(() {
          _inventory = (inventoryData['products'] as List)
              .map((p) => InventoryItem.fromJson(p))
              .toList();
          _stockAlerts = (alertsData['alerts'] as List)
              .map((a) => StockAlert.fromJson(a))
              .toList();
          _filteredInventory = _inventory;
          _isLoading = false;
        });
      } else {
        throw Exception('Failed to load inventory data');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading inventory: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _filterInventory() {
    List<InventoryItem> filtered = _inventory;

    // Filter by status
    switch (_selectedFilter) {
      case 'in_stock':
        filtered = filtered.where((item) => item.currentStock > item.lowStockThreshold).toList();
        break;
      case 'low_stock':
        filtered = filtered.where((item) => 
          item.currentStock <= item.lowStockThreshold && item.currentStock > 0).toList();
        break;
      case 'out_of_stock':
        filtered = filtered.where((item) => item.currentStock == 0).toList();
        break;
      case 'discontinued':
        filtered = filtered.where((item) => item.status == 'discontinued').toList();
        break;
    }

    // Filter by search query
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((item) =>
        item.productName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
        item.sku.toLowerCase().contains(_searchQuery.toLowerCase()) ||
        item.category.toLowerCase().contains(_searchQuery.toLowerCase())).toList();
    }

    // Sort by stock level (critical first)
    filtered.sort((a, b) {
      if (a.currentStock == 0 && b.currentStock > 0) return -1;
      if (b.currentStock == 0 && a.currentStock > 0) return 1;
      if (a.currentStock <= a.lowStockThreshold && b.currentStock > b.lowStockThreshold) return -1;
      if (b.currentStock <= b.lowStockThreshold && a.currentStock > a.lowStockThreshold) return 1;
      return a.productName.compareTo(b.productName);
    });

    setState(() {
      _filteredInventory = filtered;
    });
  }

  Future<void> _updateStock(String productId, int quantity) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      final response = await ApiService.put(
        ApiEndpoints.vendorInventoryStock(productId),
        {'quantity': quantity},
      );

      if (response.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Stock updated successfully'),
              backgroundColor: Colors.green,
            ),
          );
          _loadInventoryData();
        }
      } else {
        throw Exception('Failed to update stock');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating stock: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _bulkUpdateStock() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      final updates = _inventory.map((product) => {
        'productId': product.productId,
        'quantity': product.currentStock,
      }).toList();

      final response = await ApiService.put(
        ApiEndpoints.vendorInventoryBulkStock,
        {'updates': updates},
      );

      if (response.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Bulk stock update completed'),
              backgroundColor: Colors.green,
            ),
          );
          _loadInventoryData();
        }
      } else {
        throw Exception('Failed to bulk update stock');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error bulk updating stock: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showStockUpdateDialog(InventoryItem item) {
    final controller = TextEditingController(text: item.currentStock.toString());
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Update Stock - ${item.productName}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Current Stock: ${item.currentStock}'),
            Text('Low Stock Threshold: ${item.lowStockThreshold}'),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'New Stock Level',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final newStock = int.tryParse(controller.text) ?? 0;
              Navigator.pop(context);
              _updateStock(item.productId, newStock);
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  void _showStockAlerts() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StockAlertsSheet(alerts: _stockAlerts),
    );
  }

  Color _getStockStatusColor(InventoryItem item) {
    if (item.currentStock == 0) return Colors.red;
    if (item.currentStock <= item.lowStockThreshold) return Colors.orange;
    return Colors.green;
  }

  String _getStockStatusText(InventoryItem item) {
    if (item.currentStock == 0) return 'OUT OF STOCK';
    if (item.currentStock <= item.lowStockThreshold) return 'LOW STOCK';
    return 'IN STOCK';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          _isSelectionMode ? '${_selectedItems.length} Selected' : 'Inventory',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF2E7D32),
        elevation: 0,
        leading: _isSelectionMode
            ? IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () {
                  setState(() {
                    _isSelectionMode = false;
                    _selectedItems.clear();
                  });
                },
              )
            : null,
        actions: [
          if (_isSelectionMode) ...[
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.white),
              onPressed: _selectedItems.isNotEmpty ? _bulkUpdateStock : null,
            ),
          ] else ...[
            if (_stockAlerts.isNotEmpty)
              Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.warning, color: Colors.white),
                    onPressed: _showStockAlerts,
                  ),
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Text(
                        '${_stockAlerts.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ],
              ),
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white),
              onPressed: () => _loadInventoryData(),
            ),
          ],
        ],
        bottom: _isSelectionMode
            ? null
            : PreferredSize(
                preferredSize: const Size.fromHeight(100),
                child: Column(
                  children: [
                    // Search Bar
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Search products, SKU, category...',
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear),
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() {
                                      _searchQuery = '';
                                      _filterInventory();
                                    });
                                  },
                                )
                              : null,
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        onChanged: (value) {
                          setState(() {
                            _searchQuery = value;
                            _filterInventory();
                          });
                        },
                      ),
                    ),
                    // Filter Tabs
                    TabBar(
                      controller: _tabController,
                      isScrollable: true,
                      indicatorColor: Colors.white,
                      labelColor: Colors.white,
                      unselectedLabelColor: Colors.white70,
                      onTap: (index) {
                        setState(() {
                          _selectedFilter = _filterOptions[index];
                          _filterInventory();
                        });
                      },
                      tabs: _filterOptions.map((filter) {
                        int count = 0;
                        switch (filter) {
                          case 'all':
                            count = _inventory.length;
                            break;
                          case 'in_stock':
                            count = _inventory.where((i) => i.currentStock > i.lowStockThreshold).length;
                            break;
                          case 'low_stock':
                            count = _inventory.where((i) => 
                              i.currentStock <= i.lowStockThreshold && i.currentStock > 0).length;
                            break;
                          case 'out_of_stock':
                            count = _inventory.where((i) => i.currentStock == 0).length;
                            break;
                          case 'discontinued':
                            count = _inventory.where((i) => i.status == 'discontinued').length;
                            break;
                        }
                        return Tab(
                          text: '${filter.toUpperCase().replaceAll('_', ' ')} ($count)',
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _filteredInventory.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: () => _loadInventoryData(),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _filteredInventory.length,
                    itemBuilder: (context, index) {
                      final item = _filteredInventory[index];
                      return _buildInventoryCard(item);
                    },
                  ),
                ),
      floatingActionButton: !_isSelectionMode
          ? FloatingActionButton(
              onPressed: () {
                setState(() {
                  _isSelectionMode = true;
                });
              },
              backgroundColor: const Color(0xFF2E7D32),
              child: const Icon(Icons.checklist, color: Colors.white),
            )
          : null,
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inventory_2_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isNotEmpty
                ? 'No items found for "$_searchQuery"'
                : _selectedFilter == 'all'
                    ? 'No inventory items'
                    : 'No ${_selectedFilter.replaceAll('_', ' ')} items',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _searchQuery.isNotEmpty
                ? 'Try adjusting your search terms'
                : 'Add products to see inventory here',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInventoryCard(InventoryItem item) {
    final isSelected = _selectedItems.contains(item.productId);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: _isSelectionMode
            ? () {
                setState(() {
                  if (isSelected) {
                    _selectedItems.remove(item.productId);
                  } else {
                    _selectedItems.add(item.productId);
                  }
                });
              }
            : () => _showStockUpdateDialog(item),
        onLongPress: !_isSelectionMode
            ? () {
                setState(() {
                  _isSelectionMode = true;
                  _selectedItems.add(item.productId);
                });
              }
            : null,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: _isSelectionMode && isSelected
                ? Border.all(color: const Color(0xFF2E7D32), width: 2)
                : null,
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Row
                Row(
                  children: [
                    // Product Image
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: item.productImage != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                item.productImage!,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    Icon(Icons.image, color: Colors.grey[400]),
                              ),
                            )
                          : Icon(Icons.image, color: Colors.grey[400]),
                    ),
                    const SizedBox(width: 12),
                    
                    // Product Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.productName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'SKU: ${item.sku}',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            'Category: ${item.category}',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Selection Checkbox
                    if (_isSelectionMode)
                      Checkbox(
                        value: isSelected,
                        onChanged: (value) {
                          setState(() {
                            if (value == true) {
                              _selectedItems.add(item.productId);
                            } else {
                              _selectedItems.remove(item.productId);
                            }
                          });
                        },
                        activeColor: const Color(0xFF2E7D32),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                
                // Stock Status
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _getStockStatusColor(item).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _getStockStatusColor(item).withOpacity(0.3),
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _getStockStatusText(item),
                            style: TextStyle(
                              color: _getStockStatusColor(item),
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            'Current: ${item.currentStock}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Low Stock Alert: ${item.lowStockThreshold}',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            'Reserved: ${item.reservedStock}',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 12),
                
                // Additional Info
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Unit Price',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          'KSh ${item.unitPrice.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Last Updated',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          DateFormat('MMM dd, yyyy').format(item.lastUpdated),
                          style: const TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
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
      ),
    );
  }
}

class BulkStockUpdateDialog extends StatefulWidget {
  final int selectedCount;

  const BulkStockUpdateDialog({
    Key? key,
    required this.selectedCount,
  }) : super(key: key);

  @override
  State<BulkStockUpdateDialog> createState() => _BulkStockUpdateDialogState();
}

class _BulkStockUpdateDialogState extends State<BulkStockUpdateDialog> {
  String _operation = 'set';
  final TextEditingController _valueController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Bulk Update Stock (${widget.selectedCount} items)'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DropdownButtonFormField<String>(
            value: _operation,
            decoration: const InputDecoration(
              labelText: 'Operation',
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(value: 'set', child: Text('Set to')),
              DropdownMenuItem(value: 'add', child: Text('Add')),
              DropdownMenuItem(value: 'subtract', child: Text('Subtract')),
            ],
            onChanged: (value) {
              setState(() {
                _operation = value!;
              });
            },
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _valueController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Value',
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            final value = int.tryParse(_valueController.text);
            if (value != null) {
              Navigator.pop(context, {
                'operation': _operation,
                'value': value,
              });
            }
          },
          child: const Text('Update'),
        ),
      ],
    );
  }
}

class StockAlertsSheet extends StatelessWidget {
  final List<StockAlert> alerts;

  const StockAlertsSheet({Key? key, required this.alerts}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Header
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Stock Alerts (${alerts.length})',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),
          
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: alerts.length,
              itemBuilder: (context, index) {
                final alert = alerts[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: alert.severity == 'critical' 
                          ? Colors.red 
                          : Colors.orange,
                      child: Icon(
                        alert.severity == 'critical' 
                            ? Icons.error 
                            : Icons.warning,
                        color: Colors.white,
                      ),
                    ),
                    title: Text(alert.productName),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Current Stock: ${alert.currentStock}'),
                        Text('Threshold: ${alert.threshold}'),
                      ],
                    ),
                    trailing: Text(
                      alert.severity.toUpperCase(),
                      style: TextStyle(
                        color: alert.severity == 'critical' 
                            ? Colors.red 
                            : Colors.orange,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class InventoryItem {
  final String productId;
  final String productName;
  final String sku;
  final String category;
  final String? productImage;
  final int currentStock;
  final int lowStockThreshold;
  final int reservedStock;
  final double unitPrice;
  final String status;
  final DateTime lastUpdated;

  InventoryItem({
    required this.productId,
    required this.productName,
    required this.sku,
    required this.category,
    this.productImage,
    required this.currentStock,
    required this.lowStockThreshold,
    required this.reservedStock,
    required this.unitPrice,
    required this.status,
    required this.lastUpdated,
  });

  factory InventoryItem.fromJson(Map<String, dynamic> json) {
    return InventoryItem(
      productId: json['productId'] ?? '',
      productName: json['productName'] ?? 'Unknown Product',
      sku: json['sku'] ?? '',
      category: json['category'] ?? 'Uncategorized',
      productImage: json['productImage'],
      currentStock: json['currentStock'] ?? 0,
      lowStockThreshold: json['lowStockThreshold'] ?? 10,
      reservedStock: json['reservedStock'] ?? 0,
      unitPrice: (json['unitPrice'] ?? 0).toDouble(),
      status: json['status'] ?? 'active',
      lastUpdated: DateTime.parse(json['lastUpdated'] ?? DateTime.now().toIso8601String()),
    );
  }
}

class StockAlert {
  final String productId;
  final String productName;
  final int currentStock;
  final int threshold;
  final String severity;
  final DateTime createdAt;

  StockAlert({
    required this.productId,
    required this.productName,
    required this.currentStock,
    required this.threshold,
    required this.severity,
    required this.createdAt,
  });

  factory StockAlert.fromJson(Map<String, dynamic> json) {
    return StockAlert(
      productId: json['productId'] ?? '',
      productName: json['productName'] ?? 'Unknown Product',
      currentStock: json['currentStock'] ?? 0,
      threshold: json['threshold'] ?? 0,
      severity: json['severity'] ?? 'warning',
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
    );
  }
} 