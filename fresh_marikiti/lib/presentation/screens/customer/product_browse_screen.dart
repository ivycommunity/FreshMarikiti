import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fresh_marikiti/core/providers/product_provider.dart';
import 'package:fresh_marikiti/core/providers/cart_provider.dart';
import 'package:fresh_marikiti/core/providers/auth_provider.dart';
import 'package:fresh_marikiti/core/config/theme_extensions.dart';
import 'package:fresh_marikiti/core/services/logger_service.dart';
import 'package:fresh_marikiti/core/models/product.dart';
import 'package:fresh_marikiti/core/services/navigation_service.dart';

class ProductBrowseScreen extends StatefulWidget {
  final Map<String, dynamic>? arguments;

  const ProductBrowseScreen({
    super.key,
    this.arguments,
  });

  @override
  State<ProductBrowseScreen> createState() => _ProductBrowseScreenState();
}

class _ProductBrowseScreenState extends State<ProductBrowseScreen>
    with TickerProviderStateMixin {
  late AnimationController _filterAnimationController;
  late Animation<double> _filterAnimation;
  
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  
  bool _showFilters = false;
  bool _isGridView = true;
  String _selectedCategory = 'all';
  String _selectedVendor = '';
  String _sortBy = 'name';
  double _minPrice = 0.0;
  double _maxPrice = 1000.0;
  bool _organicOnly = false;
  bool _inStockOnly = true;
  
  @override
  void initState() {
    super.initState();
    
    _filterAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _filterAnimation = CurvedAnimation(
      parent: _filterAnimationController,
      curve: Curves.easeInOut,
    );
    
    _initializeFilters();
    _setupScrollListener();
    LoggerService.info('Product browse screen initialized', tag: 'ProductBrowseScreen');
  }

  void _initializeFilters() {
    final args = widget.arguments;
    if (args != null) {
      _selectedCategory = args['category'] ?? 'all';
      _selectedVendor = args['vendorId'] ?? '';
    }
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final productProvider = Provider.of<ProductProvider>(context, listen: false);
      productProvider.loadCategories();
      _applyFilters();
    });
  }

  void _setupScrollListener() {
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >= 
          _scrollController.position.maxScrollExtent - 200) {
        final productProvider = Provider.of<ProductProvider>(context, listen: false);
        if (productProvider.hasMoreProducts && !productProvider.isLoadingMore) {
          productProvider.loadMoreProducts();
        }
      }
    });
  }

  void _applyFilters() {
    final productProvider = Provider.of<ProductProvider>(context, listen: false);
    
    productProvider.setCategory(_selectedCategory);
    productProvider.setPriceRange(_minPrice, _maxPrice);
    productProvider.setSorting(_sortBy, 'asc');
    productProvider.setInStockOnly(_inStockOnly);
    
    if (_searchController.text.isNotEmpty) {
      productProvider.searchProducts(_searchController.text);
    } else {
      productProvider.loadProducts(refresh: true);
    }
  }

  @override
  void dispose() {
    _filterAnimationController.dispose();
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer3<ProductProvider, CartProvider, AuthProvider>(
      builder: (context, productProvider, cartProvider, authProvider, child) {
        return Scaffold(
          backgroundColor: context.colors.surface,
          appBar: _buildAppBar(context),
          body: Column(
            children: [
              // Search bar
              _buildSearchBar(productProvider),
              
              // Filter controls
              _buildFilterControls(productProvider),
              
              // Filters panel
              if (_showFilters) _buildFiltersPanel(productProvider),
              
              // Products section
              Expanded(
                child: _buildProductsSection(productProvider, cartProvider),
              ),
            ],
          ),
          floatingActionButton: _buildFloatingActionButton(cartProvider),
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: context.colors.freshGreen,
      foregroundColor: Colors.white,
      elevation: 0,
      title: Text(
        'Browse Products',
        style: context.textTheme.titleLarge?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
      actions: [
        IconButton(
          icon: Icon(_isGridView ? Icons.view_list : Icons.grid_view),
          onPressed: () {
            setState(() {
              _isGridView = !_isGridView;
            });
          },
          tooltip: _isGridView ? 'List View' : 'Grid View',
        ),
        IconButton(
          icon: const Icon(Icons.shopping_cart),
          onPressed: () => NavigationService.toCart(),
        ),
      ],
    );
  }

  Widget _buildSearchBar(ProductProvider productProvider) {
    return Container(
      padding: AppSpacing.paddingMD,
      decoration: BoxDecoration(
        color: context.colors.freshGreen,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(16),
          bottomRight: Radius.circular(16),
        ),
      ),
      child: TextField(
        controller: _searchController,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: 'Search products, categories...',
          hintStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
          prefixIcon: Icon(Icons.search, color: Colors.white.withOpacity(0.7)),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.clear, color: Colors.white.withOpacity(0.7)),
                  onPressed: () {
                    _searchController.clear();
                    productProvider.clearSearch();
                    _applyFilters();
                  },
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: AppRadius.radiusLG,
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white.withOpacity(0.2),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        onSubmitted: (value) {
          if (value.isNotEmpty) {
            productProvider.searchProducts(value);
          } else {
            _applyFilters();
          }
        },
        onChanged: (value) {
          setState(() {});
        },
      ),
    );
  }

  Widget _buildFilterControls(ProductProvider productProvider) {
    return Container(
      padding: AppSpacing.paddingMD,
      decoration: BoxDecoration(
        color: context.colors.surfaceColor,
        border: Border(
          bottom: BorderSide(
            color: context.colors.textSecondary.withOpacity(0.2),
          ),
        ),
      ),
      child: Row(
        children: [
          // Category chips
          Expanded(
            child: SizedBox(
              height: 40,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: productProvider.categories.length,
                itemBuilder: (context, index) {
                  final category = productProvider.categories[index];
                  final isSelected = _selectedCategory == category;
                  
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedCategory = category;
                      });
                      _applyFilters();
                    },
                    child: Container(
                      margin: const EdgeInsets.only(right: AppSpacing.sm),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected 
                            ? context.colors.freshGreen 
                            : Colors.transparent,
                        borderRadius: AppRadius.radiusLG,
                        border: Border.all(
                          color: isSelected 
                              ? context.colors.freshGreen 
                              : context.colors.textSecondary.withOpacity(0.3),
                        ),
                      ),
                      child: Text(
                        category.toUpperCase(),
                        style: context.textTheme.bodySmall?.copyWith(
                          color: isSelected ? Colors.white : context.colors.textPrimary,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          
          // Filter button
          IconButton(
            icon: Stack(
              children: [
                const Icon(Icons.tune),
                if (_hasActiveFilters())
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: context.colors.marketOrange,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
            onPressed: () {
              setState(() {
                _showFilters = !_showFilters;
              });
              if (_showFilters) {
                _filterAnimationController.forward();
              } else {
                _filterAnimationController.reverse();
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFiltersPanel(ProductProvider productProvider) {
    return AnimatedBuilder(
      animation: _filterAnimation,
      builder: (context, child) {
        return SizeTransition(
          sizeFactor: _filterAnimation,
          child: Container(
            padding: AppSpacing.paddingLG,
            decoration: BoxDecoration(
              color: context.colors.surfaceColor,
              border: Border(
                bottom: BorderSide(
                  color: context.colors.textSecondary.withOpacity(0.2),
                ),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Filters',
                      style: context.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextButton(
                      onPressed: _resetFilters,
                      child: Text(
                        'Reset',
                        style: TextStyle(
                          color: context.colors.freshGreen,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: AppSpacing.md),
                
                // Price range
                Text(
                  'Price Range',
                  style: context.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                RangeSlider(
                  values: RangeValues(_minPrice, _maxPrice),
                  min: 0,
                  max: 1000,
                  divisions: 20,
                  labels: RangeLabels(
                    'KSh ${_minPrice.round()}',
                    'KSh ${_maxPrice.round()}',
                  ),
                  activeColor: context.colors.freshGreen,
                  onChanged: (values) {
                    setState(() {
                      _minPrice = values.start;
                      _maxPrice = values.end;
                    });
                  },
                ),
                
                const SizedBox(height: AppSpacing.sm),
                
                // Sort options
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Sort By',
                            style: context.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          DropdownButton<String>(
                            value: _sortBy,
                            isExpanded: true,
                            items: [
                              'name',
                              'price',
                              'rating',
                              'newest',
                            ].map((option) {
                              return DropdownMenuItem(
                                value: option,
                                child: Text(_getSortLabel(option)),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                _sortBy = value ?? 'name';
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: AppSpacing.sm),
                
                // Toggle options
                Row(
                  children: [
                    Expanded(
                      child: CheckboxListTile(
                        title: const Text('Organic Only'),
                        value: _organicOnly,
                        onChanged: (value) {
                          setState(() {
                            _organicOnly = value ?? false;
                          });
                        },
                        activeColor: context.colors.freshGreen,
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    Expanded(
                      child: CheckboxListTile(
                        title: const Text('In Stock Only'),
                        value: _inStockOnly,
                        onChanged: (value) {
                          setState(() {
                            _inStockOnly = value ?? true;
                          });
                        },
                        activeColor: context.colors.freshGreen,
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: AppSpacing.lg),
                
                // Apply button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      _applyFilters();
                      setState(() {
                        _showFilters = false;
                      });
                      _filterAnimationController.reverse();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: context.colors.freshGreen,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: AppRadius.radiusMD),
                    ),
                    child: const Text('Apply Filters'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildProductsSection(ProductProvider productProvider, CartProvider cartProvider) {
    if (productProvider.isLoading && productProvider.products.isEmpty) {
      return _buildLoadingState();
    }
    
    if (productProvider.error != null && productProvider.products.isEmpty) {
      return _buildErrorState(productProvider);
    }
    
    if (productProvider.products.isEmpty) {
      return _buildEmptyState();
    }
    
    return RefreshIndicator(
      onRefresh: () => _refreshProducts(productProvider),
      color: context.colors.freshGreen,
      child: _isGridView 
          ? _buildGridView(productProvider, cartProvider)
          : _buildListView(productProvider, cartProvider),
    );
  }

  Widget _buildGridView(ProductProvider productProvider, CartProvider cartProvider) {
    return GridView.builder(
      controller: _scrollController,
      padding: AppSpacing.paddingMD,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: AppSpacing.sm,
        mainAxisSpacing: AppSpacing.sm,
        childAspectRatio: 0.75,
      ),
      itemCount: productProvider.products.length + (productProvider.hasMoreProducts ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= productProvider.products.length) {
          return _buildLoadingItem();
        }
        
        final product = productProvider.products[index];
        return _buildProductCard(product, cartProvider);
      },
    );
  }

  Widget _buildListView(ProductProvider productProvider, CartProvider cartProvider) {
    return ListView.builder(
      controller: _scrollController,
      padding: AppSpacing.paddingMD,
      itemCount: productProvider.products.length + (productProvider.hasMoreProducts ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= productProvider.products.length) {
          return _buildLoadingItem();
        }
        
        final product = productProvider.products[index];
        return _buildProductListTile(product, cartProvider);
      },
    );
  }

  Widget _buildProductCard(Product product, CartProvider cartProvider) {
    return GestureDetector(
      onTap: () => NavigationService.toProductDetails(product,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: context.colors.surfaceColor,
          borderRadius: AppRadius.radiusLG,
          boxShadow: [
            BoxShadow(
              color: context.colors.textSecondary.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: Container(
                decoration: BoxDecoration(
                  color: context.colors.freshGreen.withOpacity(0.1),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Stack(
                  children: [
                    Center(
                      child: Icon(
                        Icons.eco,
                        color: context.colors.freshGreen,
                        size: 40,
                      ),
                    ),
                    if (product.isOrganic)
                      Positioned(
                        top: 8,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: context.colors.freshGreen,
                            borderRadius: AppRadius.radiusSM,
                          ),
                          child: Text(
                            'Organic',
                            style: context.textTheme.bodySmall?.copyWith(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: GestureDetector(
                        onTap: () => _toggleFavorite(product),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.9),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.favorite_border,
                            color: context.colors.textSecondary,
                            size: 16,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
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
                    const SizedBox(height: 2),
                    Text(
                      product.formattedPrice,
                      style: context.textTheme.titleMedium?.copyWith(
                        color: context.colors.freshGreen,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (product.hasRating) ...[
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(
                            Icons.star,
                            color: context.colors.marketOrange,
                            size: 12,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            product.ratingDisplay,
                            style: context.textTheme.bodySmall?.copyWith(
                              color: context.colors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                    const Spacer(),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: product.isAvailable
                            ? () => _addToCart(product, cartProvider)
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: context.colors.freshGreen,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: AppRadius.radiusSM),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                        child: Text(
                          product.isAvailable ? 'Add to Cart' : 'Out of Stock',
                          style: context.textTheme.bodySmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductListTile(Product product, CartProvider cartProvider) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      decoration: BoxDecoration(
        color: context.colors.surfaceColor,
        borderRadius: AppRadius.radiusLG,
        boxShadow: [
          BoxShadow(
            color: context.colors.textSecondary.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: AppSpacing.paddingMD,
        leading: Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: context.colors.freshGreen.withOpacity(0.1),
            borderRadius: AppRadius.radiusMD,
          ),
          child: Icon(
            Icons.eco,
            color: context.colors.freshGreen,
            size: 24,
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                product.name,
                style: context.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            if (product.isOrganic)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: context.colors.freshGreen,
                  borderRadius: AppRadius.radiusSM,
                ),
                child: Text(
                  'Organic',
                  style: context.textTheme.bodySmall?.copyWith(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              product.formattedPrice,
              style: context.textTheme.titleMedium?.copyWith(
                color: context.colors.freshGreen,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (product.hasRating) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    Icons.star,
                    color: context.colors.marketOrange,
                    size: 12,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${product.ratingDisplay} (${product.totalRatings} reviews)',
                    style: context.textTheme.bodySmall?.copyWith(
                      color: context.colors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 4),
            Text(
              product.stockStatus,
              style: context.textTheme.bodySmall?.copyWith(
                color: product.isAvailable 
                    ? context.colors.freshGreen 
                    : context.colors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            IconButton(
              icon: const Icon(Icons.favorite_border),
              onPressed: () => _toggleFavorite(product),
              iconSize: 20,
            ),
            IconButton(
              icon: const Icon(Icons.add_shopping_cart),
              onPressed: product.isAvailable
                  ? () => _addToCart(product, cartProvider)
                  : null,
              iconSize: 20,
            ),
          ],
        ),
        onTap: () => NavigationService.toProductDetails(product,
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return GridView.builder(
      padding: AppSpacing.paddingMD,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: AppSpacing.sm,
        mainAxisSpacing: AppSpacing.sm,
        childAspectRatio: 0.75,
      ),
      itemCount: 6,
      itemBuilder: (context, index) => _buildShimmerCard(),
    );
  }

  Widget _buildShimmerCard() {
    return Container(
      decoration: BoxDecoration(
        color: context.colors.surfaceColor,
        borderRadius: AppRadius.radiusLG,
      ),
      child: Column(
        children: [
          Expanded(
            flex: 3,
            child: Container(
              decoration: BoxDecoration(
                color: context.colors.textSecondary.withOpacity(0.1),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Padding(
              padding: AppSpacing.paddingSM,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 16,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: context.colors.textSecondary.withOpacity(0.1),
                      borderRadius: AppRadius.radiusSM,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 20,
                    width: 80,
                    decoration: BoxDecoration(
                      color: context.colors.textSecondary.withOpacity(0.1),
                      borderRadius: AppRadius.radiusSM,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    height: 32,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: context.colors.textSecondary.withOpacity(0.1),
                      borderRadius: AppRadius.radiusSM,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingItem() {
    return Container(
      height: 80,
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      decoration: BoxDecoration(
        color: context.colors.surfaceColor,
        borderRadius: AppRadius.radiusLG,
      ),
      child: const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  Widget _buildErrorState(ProductProvider productProvider) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 80,
            color: context.colors.textSecondary.withOpacity(0.5),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Something went wrong',
            style: context.textTheme.headlineSmall?.copyWith(
              color: context.colors.textSecondary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            productProvider.error ?? 'Failed to load products',
            style: context.textTheme.bodyLarge?.copyWith(
              color: context.colors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xl),
          ElevatedButton(
            onPressed: () => _refreshProducts(productProvider),
            style: ElevatedButton.styleFrom(
              backgroundColor: context.colors.freshGreen,
              foregroundColor: Colors.white,
            ),
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 80,
            color: context.colors.textSecondary.withOpacity(0.5),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'No products found',
            style: context.textTheme.headlineSmall?.copyWith(
              color: context.colors.textSecondary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Try adjusting your search or filters',
            style: context.textTheme.bodyLarge?.copyWith(
              color: context.colors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xl),
          ElevatedButton(
            onPressed: _resetFilters,
            style: ElevatedButton.styleFrom(
              backgroundColor: context.colors.freshGreen,
              foregroundColor: Colors.white,
            ),
            child: const Text('Clear Filters'),
          ),
        ],
      ),
    );
  }

  Widget? _buildFloatingActionButton(CartProvider cartProvider) {
    if (cartProvider.isEmpty) return null;
    
    return FloatingActionButton.extended(
      onPressed: () => NavigationService.toCart(),
      backgroundColor: context.colors.freshGreen,
      icon: const Icon(Icons.shopping_cart, color: Colors.white),
      label: Text(
        '${cartProvider.itemCount} items',
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  // Helper methods
  bool _hasActiveFilters() {
    return _selectedCategory != 'all' ||
           _minPrice > 0 ||
           _maxPrice < 1000 ||
           _organicOnly ||
           !_inStockOnly ||
           _sortBy != 'name';
  }

  String _getSortLabel(String sortBy) {
    switch (sortBy) {
      case 'name':
        return 'Name';
      case 'price':
        return 'Price';
      case 'rating':
        return 'Rating';
      case 'newest':
        return 'Newest';
      default:
        return 'Name';
    }
  }

  void _resetFilters() {
    setState(() {
      _selectedCategory = 'all';
      _selectedVendor = '';
      _sortBy = 'name';
      _minPrice = 0.0;
      _maxPrice = 1000.0;
      _organicOnly = false;
      _inStockOnly = true;
    });
    _searchController.clear();
    _applyFilters();
  }

  Future<void> _refreshProducts(ProductProvider productProvider) async {
    await productProvider.loadProducts(refresh: true);
  }

  void _addToCart(Product product, CartProvider cartProvider) async {
    await cartProvider.addToCart(product);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${product.name} added to cart'),
          backgroundColor: context.colors.freshGreen,
          action: SnackBarAction(
            label: 'View Cart',
            textColor: Colors.white,
            onPressed: () => NavigationService.toCart(),
          ),
        ),
      );
    }
  }

  void _toggleFavorite(Product product) {
    // Implementation for toggling favorites
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${product.name} added to favorites'),
        backgroundColor: context.colors.freshGreen,
      ),
    );
  }
} 