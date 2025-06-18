import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fresh_marikiti/core/providers/auth_provider.dart';
import 'package:fresh_marikiti/core/config/theme_extensions.dart';
import 'package:fresh_marikiti/core/services/logger_service.dart';
import 'package:fresh_marikiti/core/services/api_service.dart';
import 'package:fresh_marikiti/core/models/product.dart' as product_model;
import 'dart:convert';
import 'package:fresh_marikiti/core/services/navigation_service.dart';

class VendorProduct {
  final String id;
  final String name;
  final String description;
  final String category;
  final double price;
  final int stockQuantity;
  final int lowStockThreshold;
  final String unit;
  final List<String> imageUrls;
  final bool isActive;
  final bool isLowStock;
  final DateTime createdAt;
  final DateTime updatedAt;

  VendorProduct({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.price,
    required this.stockQuantity,
    required this.lowStockThreshold,
    required this.unit,
    required this.imageUrls,
    required this.isActive,
    required this.isLowStock,
    required this.createdAt,
    required this.updatedAt,
  });

  factory VendorProduct.fromJson(Map<String, dynamic> json) {
    return VendorProduct(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      category: json['category'] ?? '',
      price: (json['price'] ?? 0).toDouble(),
      stockQuantity: json['stock_quantity'] ?? 0,
      lowStockThreshold: json['low_stock_threshold'] ?? 10,
      unit: json['unit'] ?? 'piece',
      imageUrls: List<String>.from(json['images'] ?? []),
      isActive: json['is_active'] ?? true,
      isLowStock: json['is_low_stock'] ?? false,
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updated_at'] ?? DateTime.now().toIso8601String()),
    );
  }
}

enum ProductFilter { all, active, inactive, lowStock, outOfStock }
enum ProductSort { name, price, stock, recent }

class ProductManagementScreen extends StatefulWidget {
  const ProductManagementScreen({super.key});

  @override
  State<ProductManagementScreen> createState() => _ProductManagementScreenState();
}

class _ProductManagementScreenState extends State<ProductManagementScreen>
    with TickerProviderStateMixin {
  
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  
  List<VendorProduct> _products = [];
  List<VendorProduct> _filteredProducts = [];
  bool _isLoading = true;
  String? _error;
  String _searchQuery = '';
  ProductFilter _currentFilter = ProductFilter.all;
  ProductSort _currentSort = ProductSort.recent;
  bool _isGridView = false;
  
  final Set<String> _selectedProducts = {};
  bool _isSelectionMode = false;

  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    _loadProducts();
    _animationController.forward();
    
    LoggerService.info('Product management screen initialized', tag: 'ProductManagementScreen');
  }

  Future<void> _loadProducts() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await ApiService.get('/vendor/products');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        setState(() {
          _products = (data['products'] as List)
              .map((json) => VendorProduct.fromJson(json))
              .toList();
          _applyFiltersAndSort();
          _isLoading = false;
        });
      } else {
        throw Exception('Failed to load products: ${response.statusCode}');
      }
    } catch (e) {
      LoggerService.error('Failed to load products', error: e, tag: 'ProductManagementScreen');
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  void _applyFiltersAndSort() {
    var filtered = _products.where((product) {
      // Search filter
      if (_searchQuery.isNotEmpty) {
        return product.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
               product.category.toLowerCase().contains(_searchQuery.toLowerCase());
      }
      return true;
    }).toList();

    // Status filter
    switch (_currentFilter) {
      case ProductFilter.active:
        filtered = filtered.where((product) => product.isActive).toList();
        break;
      case ProductFilter.inactive:
        filtered = filtered.where((product) => !product.isActive).toList();
        break;
      case ProductFilter.lowStock:
        filtered = filtered.where((product) => product.isLowStock).toList();
        break;
      case ProductFilter.outOfStock:
        filtered = filtered.where((product) => product.stockQuantity == 0).toList();
        break;
      case ProductFilter.all:
      default:
        break;
    }

    // Sort products
    switch (_currentSort) {
      case ProductSort.name:
        filtered.sort((a, b) => a.name.compareTo(b.name));
        break;
      case ProductSort.price:
        filtered.sort((a, b) => a.price.compareTo(b.price));
        break;
      case ProductSort.stock:
        filtered.sort((a, b) => b.stockQuantity.compareTo(a.stockQuantity));
        break;
      case ProductSort.recent:
        filtered.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
        break;
    }

    setState(() {
      _filteredProducts = filtered;
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        return Scaffold(
          backgroundColor: context.colors.surface,
          appBar: _buildAppBar(),
          body: AnimatedBuilder(
            animation: _fadeAnimation,
            builder: (context, child) {
              return Opacity(
                opacity: _fadeAnimation.value,
                child: _error != null
                    ? _buildErrorState()
                    : Column(
                        children: [
                          _buildSearchAndFilters(),
                          _buildStats(),
                          Expanded(child: _buildProductList()),
                        ],
                      ),
              );
            },
          ),
          floatingActionButton: _buildFAB(),
          bottomNavigationBar: _isSelectionMode ? _buildSelectionActions() : null,
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: context.colors.freshGreen,
      foregroundColor: Colors.white,
      title: Text(
        _isSelectionMode 
            ? '${_selectedProducts.length} selected'
            : 'Product Management',
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      actions: [
        if (_isSelectionMode) ...[
          IconButton(
            icon: const Icon(Icons.select_all),
            onPressed: _selectAll,
            tooltip: 'Select All',
          ),
          IconButton(
            icon: const Icon(Icons.clear),
            onPressed: _clearSelection,
            tooltip: 'Clear Selection',
          ),
        ] else ...[
          IconButton(
            icon: Icon(_isGridView ? Icons.view_list : Icons.grid_view),
            onPressed: () => setState(() => _isGridView = !_isGridView),
            tooltip: _isGridView ? 'List View' : 'Grid View',
          ),
          IconButton(
            icon: const Icon(Icons.sort),
            onPressed: _showSortOptions,
            tooltip: 'Sort',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadProducts,
            tooltip: 'Refresh',
          ),
        ],
      ],
      leading: _isSelectionMode 
          ? IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => setState(() {
                _isSelectionMode = false;
                _selectedProducts.clear();
              }),
            )
          : null,
    );
  }

  Widget _buildSearchAndFilters() {
    return Container(
      padding: AppSpacing.paddingMD,
      decoration: BoxDecoration(
        color: context.colors.surfaceColor,
        boxShadow: [
          BoxShadow(
            offset: const Offset(0, 2),
            blurRadius: 4,
            color: Colors.black.withValues(alpha: 0.1),
          ),
        ],
      ),
      child: Column(
        children: [
          // Search bar
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search products...',
              prefixIcon: Icon(Icons.search, color: context.colors.textSecondary),
              border: OutlineInputBorder(
                borderRadius: AppRadius.radiusMD,
                borderSide: BorderSide(color: context.colors.outline),
              ),
              filled: true,
              fillColor: context.colors.surface,
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
                _applyFiltersAndSort();
              });
            },
          ),
          
          const SizedBox(height: AppSpacing.sm),
          
          // Filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: ProductFilter.values.map((filter) {
                final isSelected = _currentFilter == filter;
                return Container(
                  margin: const EdgeInsets.only(right: AppSpacing.sm),
                  child: FilterChip(
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _currentFilter = filter;
                        _applyFiltersAndSort();
                      });
                    },
                    label: Text(_getFilterLabel(filter)),
                    backgroundColor: isSelected ? context.colors.freshGreen : null,
                    selectedColor: context.colors.freshGreen,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : null,
                      fontWeight: isSelected ? FontWeight.bold : null,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStats() {
    final totalProducts = _products.length;
    final activeProducts = _products.where((p) => p.isActive).length;
    final lowStockProducts = _products.where((p) => p.isLowStock).length;
    final outOfStockProducts = _products.where((p) => p.stockQuantity == 0).length;

    return Container(
      padding: AppSpacing.paddingMD,
      child: Row(
        children: [
          _buildStatChip('Total', totalProducts.toString(), context.colors.ecoBlue),
          const SizedBox(width: AppSpacing.sm),
          _buildStatChip('Active', activeProducts.toString(), context.colors.freshGreen),
          const SizedBox(width: AppSpacing.sm),
          _buildStatChip('Low Stock', lowStockProducts.toString(), Colors.orange),
          const SizedBox(width: AppSpacing.sm),
          _buildStatChip('Out of Stock', outOfStockProducts.toString(), Colors.red),
        ],
      ),
    );
  }

  Widget _buildStatChip(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: AppSpacing.paddingSM,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: AppRadius.radiusMD,
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: context.textTheme.titleMedium?.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              label,
              style: context.textTheme.bodySmall?.copyWith(
                color: color,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductList() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_filteredProducts.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: _loadProducts,
      color: context.colors.freshGreen,
      child: _isGridView ? _buildGridView() : _buildListView(),
    );
  }

  Widget _buildListView() {
    return ListView.builder(
      controller: _scrollController,
      padding: AppSpacing.paddingMD,
      itemCount: _filteredProducts.length,
      itemBuilder: (context, index) {
        final product = _filteredProducts[index];
        return _buildProductCard(product);
      },
    );
  }

  Widget _buildGridView() {
    return GridView.builder(
      controller: _scrollController,
      padding: AppSpacing.paddingMD,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: AppSpacing.sm,
        mainAxisSpacing: AppSpacing.sm,
        childAspectRatio: 0.75,
      ),
      itemCount: _filteredProducts.length,
      itemBuilder: (context, index) {
        final product = _filteredProducts[index];
        return _buildProductGridCard(product);
      },
    );
  }

  Widget _buildProductCard(VendorProduct product) {
    final isSelected = _selectedProducts.contains(product.id);
    final stockColor = _getStockColor(product);
    
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.radiusLG),
        child: InkWell(
          borderRadius: AppRadius.radiusLG,
          onTap: () => _handleProductTap(product),
          onLongPress: () => _enterSelectionMode(product),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: AppRadius.radiusLG,
              border: isSelected 
                  ? Border.all(color: context.colors.freshGreen, width: 2)
                  : null,
            ),
            child: Padding(
              padding: AppSpacing.paddingMD,
              child: Row(
                children: [
                  // Product image
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: context.colors.surfaceColor,
                      borderRadius: AppRadius.radiusMD,
                      image: product.imageUrls.isNotEmpty
                          ? DecorationImage(
                              image: NetworkImage(product.imageUrls.first),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: product.imageUrls.isEmpty
                        ? Icon(
                            Icons.inventory,
                            color: context.colors.textSecondary,
                            size: 30,
                          )
                        : null,
                  ),
                  
                  const SizedBox(width: AppSpacing.sm),
                  
                  // Product details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                product.name,
                                style: context.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (!product.isActive)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.grey.withValues(alpha: 0.2),
                                  borderRadius: AppRadius.radiusSM,
                                ),
                                child: Text(
                                  'Inactive',
                                  style: context.textTheme.bodySmall?.copyWith(
                                    color: Colors.grey,
                                    fontSize: 10,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          product.category,
                          style: context.textTheme.bodySmall?.copyWith(
                            color: context.colors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              'KSh ${product.price.toStringAsFixed(0)}',
                              style: context.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: context.colors.freshGreen,
                              ),
                            ),
                            Text(
                              '/${product.unit}',
                              style: context.textTheme.bodySmall?.copyWith(
                                color: context.colors.textSecondary,
                              ),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: stockColor.withValues(alpha: 0.2),
                                borderRadius: AppRadius.radiusSM,
                              ),
                              child: Text(
                                '${product.stockQuantity} left',
                                style: context.textTheme.bodySmall?.copyWith(
                                  color: stockColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  // Actions
                  PopupMenuButton<String>(
                    onSelected: (value) => _handleMenuAction(value, product),
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: ListTile(
                          leading: Icon(Icons.edit),
                          title: Text('Edit'),
                        ),
                      ),
                      PopupMenuItem(
                        value: product.isActive ? 'deactivate' : 'activate',
                        child: ListTile(
                          leading: Icon(product.isActive ? Icons.visibility_off : Icons.visibility),
                          title: Text(product.isActive ? 'Deactivate' : 'Activate'),
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'stock',
                        child: ListTile(
                          leading: Icon(Icons.add_box),
                          title: Text('Update Stock'),
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: ListTile(
                          leading: Icon(Icons.delete, color: Colors.red),
                          title: Text('Delete'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProductGridCard(VendorProduct product) {
    final isSelected = _selectedProducts.contains(product.id);
    final stockColor = _getStockColor(product);
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: AppRadius.radiusLG),
      child: InkWell(
        borderRadius: AppRadius.radiusLG,
        onTap: () => _handleProductTap(product),
        onLongPress: () => _enterSelectionMode(product),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: AppRadius.radiusLG,
            border: isSelected 
                ? Border.all(color: context.colors.freshGreen, width: 2)
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product image
              Expanded(
                flex: 3,
                child: Container(
                  decoration: BoxDecoration(
                    color: context.colors.surfaceColor,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(12),
                      topRight: Radius.circular(12),
                    ),
                    image: product.imageUrls.isNotEmpty
                        ? DecorationImage(
                            image: NetworkImage(product.imageUrls.first),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: Stack(
                    children: [
                      if (product.imageUrls.isEmpty)
                        Center(
                          child: Icon(
                            Icons.inventory,
                            color: context.colors.textSecondary,
                            size: 40,
                          ),
                        ),
                      if (!product.isActive)
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.grey.withValues(alpha: 0.9),
                              borderRadius: AppRadius.radiusSM,
                            ),
                            child: Text(
                              'Inactive',
                              style: context.textTheme.bodySmall?.copyWith(
                                color: Colors.white,
                                fontSize: 10,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              
              // Product details
              Expanded(
                flex: 2,
                child: Padding(
                  padding: AppSpacing.paddingSM,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.name,
                        style: context.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        product.category,
                        style: context.textTheme.bodySmall?.copyWith(
                          color: context.colors.textSecondary,
                          fontSize: 10,
                        ),
                      ),
                      const Spacer(),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'KSh ${product.price.toStringAsFixed(0)}',
                              style: context.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: context.colors.freshGreen,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                            decoration: BoxDecoration(
                              color: stockColor.withValues(alpha: 0.2),
                              borderRadius: AppRadius.radiusSM,
                            ),
                            child: Text(
                              '${product.stockQuantity}',
                              style: context.textTheme.bodySmall?.copyWith(
                                color: stockColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 10,
                              ),
                            ),
                          ),
                        ],
                      ),
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

  Widget _buildFAB() {
    return FloatingActionButton(
      onPressed: () => NavigationService.toAddProduct(),
      backgroundColor: context.colors.freshGreen,
      child: const Icon(Icons.add, color: Colors.white),
    );
  }

  Widget _buildSelectionActions() {
    return Container(
      padding: AppSpacing.paddingMD,
      decoration: BoxDecoration(
        color: context.colors.surface,
        boxShadow: [
          BoxShadow(
            offset: const Offset(0, -2),
            blurRadius: 8,
            color: Colors.black.withValues(alpha: 0.1),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _selectedProducts.isEmpty ? null : _bulkActivateDeactivate,
                icon: const Icon(Icons.visibility),
                label: const Text('Toggle Status'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: context.colors.ecoBlue,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _selectedProducts.isEmpty ? null : _bulkUpdateStock,
                icon: const Icon(Icons.add_box),
                label: const Text('Update Stock'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: context.colors.marketOrange,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _selectedProducts.isEmpty ? null : _bulkDelete,
                icon: const Icon(Icons.delete),
                label: const Text('Delete'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
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
            Icons.inventory_2_outlined,
            size: 64,
            color: context.colors.textSecondary.withValues(alpha: 0.5),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'No products found',
            style: context.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: context.colors.textSecondary,
            ),
          ),
          Text(
            _searchQuery.isNotEmpty 
                ? 'Try adjusting your search or filters'
                : 'Add your first product to get started',
            style: context.textTheme.bodyMedium?.copyWith(
              color: context.colors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.lg),
          ElevatedButton.icon(
            onPressed: () => NavigationService.toAddProduct(),
            icon: const Icon(Icons.add),
            label: const Text('Add Product'),
            style: ElevatedButton.styleFrom(
              backgroundColor: context.colors.freshGreen,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red.withValues(alpha: 0.5),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Failed to load products',
            style: context.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.red,
            ),
          ),
          Text(
            _error ?? 'Unknown error occurred',
            style: context.textTheme.bodyMedium?.copyWith(
              color: context.colors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.lg),
          ElevatedButton(
            onPressed: _loadProducts,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  // Helper methods
  Color _getStockColor(VendorProduct product) {
    if (product.stockQuantity == 0) return Colors.red;
    if (product.isLowStock) return Colors.orange;
    return context.colors.freshGreen;
  }

  String _getFilterLabel(ProductFilter filter) {
    switch (filter) {
      case ProductFilter.all:
        return 'All';
      case ProductFilter.active:
        return 'Active';
      case ProductFilter.inactive:
        return 'Inactive';
      case ProductFilter.lowStock:
        return 'Low Stock';
      case ProductFilter.outOfStock:
        return 'Out of Stock';
    }
  }

  void _handleProductTap(VendorProduct product) {
    if (_isSelectionMode) {
      setState(() {
        if (_selectedProducts.contains(product.id)) {
          _selectedProducts.remove(product.id);
          if (_selectedProducts.isEmpty) {
            _isSelectionMode = false;
          }
        } else {
          _selectedProducts.add(product.id);
        }
      });
    } else {
      NavigationService.toEditProduct(_convertToProduct(product));
    }
  }

  void _enterSelectionMode(VendorProduct product) {
    setState(() {
      _isSelectionMode = true;
      _selectedProducts.clear();
      _selectedProducts.add(product.id);
    });
  }

  void _selectAll() {
    setState(() {
      _selectedProducts.clear();
      _selectedProducts.addAll(_filteredProducts.map((p) => p.id));
    });
  }

  void _clearSelection() {
    setState(() {
      _selectedProducts.clear();
      _isSelectionMode = false;
    });
  }

  void _showSortOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: AppSpacing.paddingLG,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Sort Products',
              style: context.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            ...ProductSort.values.map((sort) {
              return ListTile(
                leading: Radio<ProductSort>(
                  value: sort,
                  groupValue: _currentSort,
                  onChanged: (value) {
                    setState(() {
                      _currentSort = value!;
                      _applyFiltersAndSort();
                    });
                    Navigator.pop(context);
                  },
                ),
                title: Text(_getSortLabel(sort)),
                onTap: () {
                  setState(() {
                    _currentSort = sort;
                    _applyFiltersAndSort();
                  });
                  Navigator.pop(context);
                },
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  String _getSortLabel(ProductSort sort) {
    switch (sort) {
      case ProductSort.name:
        return 'Name (A-Z)';
      case ProductSort.price:
        return 'Price (Low to High)';
      case ProductSort.stock:
        return 'Stock (High to Low)';
      case ProductSort.recent:
        return 'Recently Updated';
    }
  }

  void _handleMenuAction(String action, VendorProduct product) {
    switch (action) {
      case 'edit':
        NavigationService.toEditProduct(_convertToProduct(product));
        break;
      case 'activate':
      case 'deactivate':
        _toggleProductStatus(product);
        break;
      case 'stock':
        _showStockUpdateDialog(product);
        break;
      case 'delete':
        _showDeleteConfirmation(product);
        break;
    }
  }

  Future<void> _toggleProductStatus(VendorProduct product) async {
    try {
      final response = await ApiService.patch('/vendor/products/${product.id}/status', {
        'is_active': !product.isActive,
      });
      
      if (response.statusCode == 200) {
        _loadProducts();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Product ${product.isActive ? 'deactivated' : 'activated'}'),
            backgroundColor: context.colors.freshGreen,
          ),
        );
      } else {
        throw Exception('Failed to update product status');
      }
    } catch (e) {
      LoggerService.error('Failed to toggle product status', error: e, tag: 'ProductManagementScreen');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update product: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showStockUpdateDialog(VendorProduct product) {
    final controller = TextEditingController(text: product.stockQuantity.toString());
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Update Stock - ${product.name}'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: 'Stock Quantity',
            hintText: 'Enter new stock quantity',
            border: const OutlineInputBorder(),
            suffixText: product.unit,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final newStock = int.tryParse(controller.text);
              if (newStock != null && newStock >= 0) {
                Navigator.pop(context);
                _updateProductStock(product, newStock);
              }
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  Future<void> _updateProductStock(VendorProduct product, int newStock) async {
    try {
      final response = await ApiService.patch('/vendor/products/${product.id}/stock', {
        'stock_quantity': newStock,
      });
      
      if (response.statusCode == 200) {
        _loadProducts();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Stock updated for ${product.name}'),
            backgroundColor: context.colors.freshGreen,
          ),
        );
      } else {
        throw Exception('Failed to update stock');
      }
    } catch (e) {
      LoggerService.error('Failed to update stock', error: e, tag: 'ProductManagementScreen');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update stock: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showDeleteConfirmation(VendorProduct product) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Product'),
        content: Text('Are you sure you want to delete "${product.name}"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteProduct(product);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteProduct(VendorProduct product) async {
    try {
      final response = await ApiService.delete('/vendor/products/${product.id}');
      
      if (response.statusCode == 200) {
        _loadProducts();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Product "${product.name}" deleted'),
            backgroundColor: context.colors.freshGreen,
          ),
        );
      } else {
        throw Exception('Failed to delete product');
      }
    } catch (e) {
      LoggerService.error('Failed to delete product', error: e, tag: 'ProductManagementScreen');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to delete product: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Bulk operations
  Future<void> _bulkActivateDeactivate() async {
    try {
      final response = await ApiService.patch('/vendor/products/bulk/status', {
        'product_ids': _selectedProducts.toList(),
        'action': 'toggle',
      });
      
      if (response.statusCode == 200) {
        _loadProducts();
        _clearSelection();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Updated ${_selectedProducts.length} products'),
            backgroundColor: context.colors.freshGreen,
          ),
        );
      } else {
        throw Exception('Failed to update products');
      }
    } catch (e) {
      LoggerService.error('Failed to bulk update products', error: e, tag: 'ProductManagementScreen');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update products: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _bulkUpdateStock() {
    final controller = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Update Stock for ${_selectedProducts.length} products'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Stock Quantity',
            hintText: 'Enter stock quantity to add',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final stockToAdd = int.tryParse(controller.text);
              if (stockToAdd != null && stockToAdd >= 0) {
                Navigator.pop(context);
                _performBulkStockUpdate(stockToAdd);
              }
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  Future<void> _performBulkStockUpdate(int stockToAdd) async {
    try {
      final response = await ApiService.patch('/vendor/products/bulk/stock', {
        'product_ids': _selectedProducts.toList(),
        'stock_to_add': stockToAdd,
      });
      
      if (response.statusCode == 200) {
        _loadProducts();
        _clearSelection();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Updated stock for ${_selectedProducts.length} products'),
            backgroundColor: context.colors.freshGreen,
          ),
        );
      } else {
        throw Exception('Failed to update stock');
      }
    } catch (e) {
      LoggerService.error('Failed to bulk update stock', error: e, tag: 'ProductManagementScreen');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update stock: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _bulkDelete() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Products'),
        content: Text('Are you sure you want to delete ${_selectedProducts.length} products? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _performBulkDelete();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _performBulkDelete() async {
    try {
      final response = await ApiService.post('/vendor/products/bulk/delete', {
        'product_ids': _selectedProducts.toList(),
      });
      
      if (response.statusCode == 200) {
        _loadProducts();
        _clearSelection();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Deleted ${_selectedProducts.length} products'),
            backgroundColor: context.colors.freshGreen,
          ),
        );
      } else {
        throw Exception('Failed to delete products');
      }
    } catch (e) {
      LoggerService.error('Failed to bulk delete products', error: e, tag: 'ProductManagementScreen');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to delete products: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  product_model.Product _convertToProduct(VendorProduct product) {
    return product_model.Product(
      id: product.id,
      vendorId: 'current_vendor', // You might need to get this from auth provider
      name: product.name,
      description: product.description,
      price: product.price,
      quantityAvailable: product.stockQuantity,
      category: product.category,
      images: product.imageUrls,
      createdAt: product.createdAt,
      updatedAt: product.updatedAt,
      isActive: product.isActive,
      unit: product.unit,
    );
  }
} 