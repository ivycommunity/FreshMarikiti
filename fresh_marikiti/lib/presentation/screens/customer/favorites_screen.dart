import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fresh_marikiti/core/providers/product_provider.dart';
import 'package:fresh_marikiti/core/providers/cart_provider.dart';
import 'package:fresh_marikiti/core/providers/auth_provider.dart';
import 'package:fresh_marikiti/core/config/theme_extensions.dart';
import 'package:fresh_marikiti/core/services/logger_service.dart';
import 'package:fresh_marikiti/core/models/product.dart';
import 'package:fresh_marikiti/core/services/navigation_service.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;
  
  String _selectedTab = 'products';
  bool _isLoading = false;
  String _selectedCategory = 'all';
  String _sortBy = 'recent';
  
  // Demo favorite data
  List<Product> _favoriteProducts = [];
  List<Map<String, dynamic>> _favoriteVendors = [];
  List<String> _favoriteCategories = [];

  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    _slideAnimation = Tween<double>(
      begin: 30.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));
    
    _loadFavorites();
    _animationController.forward();
    LoggerService.info('Favorites screen initialized', tag: 'FavoritesScreen');
  }

  void _loadFavorites() {
    _loadFavoriteProducts();
    _loadFavoriteVendors();
    _loadFavoriteCategories();
  }

  void _loadFavoriteProducts() {
    // Demo favorite products - in real app, fetch from backend
    _favoriteProducts = [
      Product(
        id: 'prod_001',
        vendorId: 'vendor_001',
        name: 'Organic Tomatoes',
        description: 'Fresh organic tomatoes from local farms',
        price: 80.0,
        quantityAvailable: 50,
        imageUrl: 'assets/images/tomatoes.jpg',
        category: 'vegetables',
        averageRating: 4.5,
        totalRatings: 23,
        isOrganic: true,
        unit: 'kg',
        createdAt: DateTime.now().subtract(const Duration(days: 15)),
        updatedAt: DateTime.now(),
      ),
      Product(
        id: 'prod_002',
        vendorId: 'vendor_002',
        name: 'Fresh Spinach',
        description: 'Crispy fresh spinach leaves',
        price: 60.0,
        quantityAvailable: 30,
        imageUrl: 'assets/images/spinach.jpg',
        category: 'vegetables',
        averageRating: 4.8,
        totalRatings: 18,
        isOrganic: true,
        unit: 'bunch',
        createdAt: DateTime.now().subtract(const Duration(days: 10)),
        updatedAt: DateTime.now(),
      ),
      Product(
        id: 'prod_003',
        vendorId: 'vendor_001',
        name: 'Ripe Bananas',
        description: 'Sweet and ripe bananas perfect for snacking',
        price: 120.0,
        quantityAvailable: 25,
        imageUrl: 'assets/images/bananas.jpg',
        category: 'fruits',
        averageRating: 4.2,
        totalRatings: 31,
        isOrganic: false,
        unit: 'dozen',
        createdAt: DateTime.now().subtract(const Duration(days: 5)),
        updatedAt: DateTime.now(),
      ),
    ];
  }

  void _loadFavoriteVendors() {
    _favoriteVendors = [
      {
        'id': 'vendor_001',
        'name': 'Green Valley Farm',
        'description': 'Organic vegetables and fruits',
        'location': 'Kiambu, Kenya',
        'rating': 4.6,
        'totalProducts': 45,
        'isVerified': true,
        'imageUrl': 'assets/images/vendor1.jpg',
        'addedDate': DateTime.now().subtract(const Duration(days: 20)),
      },
      {
        'id': 'vendor_002',
        'name': 'Fresh Fruits Market',
        'description': 'Wide variety of fresh fruits',
        'location': 'Nakuru, Kenya',
        'rating': 4.4,
        'totalProducts': 32,
        'isVerified': true,
        'imageUrl': 'assets/images/vendor2.jpg',
        'addedDate': DateTime.now().subtract(const Duration(days: 12)),
      },
    ];
  }

  void _loadFavoriteCategories() {
    _favoriteCategories = [
      'vegetables',
      'fruits',
      'grains',
    ];
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer3<ProductProvider, CartProvider, AuthProvider>(
      builder: (context, productProvider, cartProvider, authProvider, child) {
        return Scaffold(
          backgroundColor: context.colors.surface,
          appBar: _buildAppBar(context),
          body: AnimatedBuilder(
            animation: _fadeAnimation,
            builder: (context, child) {
              return Opacity(
                opacity: _fadeAnimation.value,
                child: Transform.translate(
                  offset: Offset(0, _slideAnimation.value),
                  child: Column(
                    children: [
                      _buildTabBar(),
                      if (_selectedTab == 'products') _buildProductsFilters(),
                      Expanded(
                        child: _buildSelectedTabContent(cartProvider),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
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
        'My Favorites',
        style: context.textTheme.titleLarge?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.search),
          onPressed: () => _showSearchDialog(),
        ),
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert),
          onSelected: _handleMenuAction,
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'clearAll',
              child: Row(
                children: [
                  Icon(Icons.clear_all),
                  SizedBox(width: 8),
                  Text('Clear All'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'export',
              child: Row(
                children: [
                  Icon(Icons.download),
                  SizedBox(width: 8),
                  Text('Export List'),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: AppSpacing.paddingMD,
      decoration: BoxDecoration(
        color: context.colors.surfaceColor,
        borderRadius: AppRadius.radiusLG,
        border: Border.all(color: context.colors.textSecondary.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildTabButton('products', 'Products', Icons.eco),
          ),
          Expanded(
            child: _buildTabButton('vendors', 'Vendors', Icons.store),
          ),
          Expanded(
            child: _buildTabButton('categories', 'Categories', Icons.category),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton(String tabId, String title, IconData icon) {
    final isSelected = _selectedTab == tabId;
    
    return GestureDetector(
      onTap: () => setState(() => _selectedTab = tabId),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected ? context.colors.freshGreen : Colors.transparent,
          borderRadius: AppRadius.radiusLG,
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : context.colors.textSecondary,
              size: 18,
            ),
            const SizedBox(height: 2),
            Text(
              title,
              style: context.textTheme.bodySmall?.copyWith(
                color: isSelected ? Colors.white : context.colors.textSecondary,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductsFilters() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: context.colors.surfaceColor,
                borderRadius: AppRadius.radiusMD,
                border: Border.all(color: context.colors.textSecondary.withValues(alpha: 0.2)),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedCategory,
                  hint: const Text('Category'),
                  isExpanded: true,
                  items: [
                    DropdownMenuItem(
                      value: 'all',
                      child: Text('All Categories'),
                    ),
                    ...['vegetables', 'fruits', 'grains', 'dairy']
                        .map((category) => DropdownMenuItem(
                              value: category,
                              child: Text(category.split(' ').map((word) => 
                                  word[0].toUpperCase() + word.substring(1)).join(' ')),
                            )),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedCategory = value!;
                    });
                  },
                ),
              ),
            ),
          ),
          
          const SizedBox(width: AppSpacing.sm),
          
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: context.colors.surfaceColor,
              borderRadius: AppRadius.radiusMD,
              border: Border.all(color: context.colors.textSecondary.withValues(alpha: 0.2)),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _sortBy,
                items: const [
                  DropdownMenuItem(value: 'recent', child: Text('Recent')),
                  DropdownMenuItem(value: 'name', child: Text('Name')),
                  DropdownMenuItem(value: 'price', child: Text('Price')),
                  DropdownMenuItem(value: 'rating', child: Text('Rating')),
                ],
                onChanged: (value) {
                  setState(() {
                    _sortBy = value!;
                  });
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedTabContent(CartProvider cartProvider) {
    switch (_selectedTab) {
      case 'products':
        return _buildProductsTab(cartProvider);
      case 'vendors':
        return _buildVendorsTab();
      case 'categories':
        return _buildCategoriesTab();
      default:
        return _buildProductsTab(cartProvider);
    }
  }

  Widget _buildProductsTab(CartProvider cartProvider) {
    if (_isLoading) {
      return _buildLoadingState();
    }
    
    if (_favoriteProducts.isEmpty) {
      return _buildEmptyProductsState();
    }
    
    final filteredProducts = _getFilteredProducts();
    
    return RefreshIndicator(
      onRefresh: () => _refreshFavorites(),
      color: context.colors.freshGreen,
      child: ListView.builder(
        padding: AppSpacing.paddingMD,
        itemCount: filteredProducts.length,
        itemBuilder: (context, index) {
          final product = filteredProducts[index];
          return _buildProductCard(product, index, cartProvider);
        },
      ),
    );
  }

  Widget _buildVendorsTab() {
    if (_favoriteVendors.isEmpty) {
      return _buildEmptyVendorsState();
    }
    
    return ListView.builder(
      padding: AppSpacing.paddingMD,
      itemCount: _favoriteVendors.length,
      itemBuilder: (context, index) {
        final vendor = _favoriteVendors[index];
        return _buildVendorCard(vendor, index);
      },
    );
  }

  Widget _buildCategoriesTab() {
    if (_favoriteCategories.isEmpty) {
      return _buildEmptyCategoriesState();
    }
    
    return GridView.builder(
      padding: AppSpacing.paddingMD,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: AppSpacing.sm,
        mainAxisSpacing: AppSpacing.sm,
        childAspectRatio: 1.2,
      ),
      itemCount: _favoriteCategories.length,
      itemBuilder: (context, index) {
        final category = _favoriteCategories[index];
        return _buildCategoryCard(category, index);
      },
    );
  }

  Widget _buildProductCard(Product product, int index, CartProvider cartProvider) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 400 + (index * 100)),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 30 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: Container(
              margin: const EdgeInsets.only(bottom: AppSpacing.md),
              child: Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: AppRadius.radiusLG),
                child: InkWell(
                  borderRadius: AppRadius.radiusLG,
                  onTap: () => _navigateToProduct(product),
                  child: Padding(
                    padding: AppSpacing.paddingMD,
                    child: Row(
                      children: [
                        // Product image
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: context.colors.freshGreen.withValues(alpha: 0.1),
                            borderRadius: AppRadius.radiusMD,
                          ),
                          child: Icon(
                            Icons.eco,
                            color: context.colors.freshGreen,
                            size: 32,
                          ),
                        ),
                        
                        const SizedBox(width: AppSpacing.md),
                        
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
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.favorite, color: Colors.red),
                                    onPressed: () => _removeFavoriteProduct(product),
                                  ),
                                ],
                              ),
                              
                              Text(
                                product.description ?? 'Fresh produce',
                                style: context.textTheme.bodySmall?.copyWith(
                                  color: context.colors.textSecondary,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              
                              const SizedBox(height: AppSpacing.sm),
                              
                              Row(
                                children: [
                                  Text(
                                    product.formattedPrice,
                                    style: context.textTheme.titleSmall?.copyWith(
                                      color: context.colors.freshGreen,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(width: AppSpacing.sm),
                                  if (product.hasRating) ...[
                                    Icon(
                                      Icons.star,
                                      size: 16,
                                      color: Colors.amber,
                                    ),
                                    Text(
                                      product.ratingDisplay,
                                      style: context.textTheme.bodySmall,
                                    ),
                                  ],
                                  if (product.isOrganic) ...[
                                    const SizedBox(width: AppSpacing.sm),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: context.colors.freshGreen.withValues(alpha: 0.2),
                                        borderRadius: AppRadius.radiusSM,
                                      ),
                                      child: Text(
                                        'Organic',
                                        style: context.textTheme.bodySmall?.copyWith(
                                          color: context.colors.freshGreen,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              
                              const SizedBox(height: AppSpacing.sm),
                              
                              // Action buttons
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: () => _viewProduct(product),
                                      icon: const Icon(Icons.visibility, size: 16),
                                      label: const Text('View'),
                                      style: OutlinedButton.styleFrom(
                                        side: BorderSide(color: context.colors.ecoBlue),
                                        shape: RoundedRectangleBorder(borderRadius: AppRadius.radiusMD),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: AppSpacing.sm),
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      onPressed: product.isAvailable 
                                          ? () => _addToCart(product, cartProvider)
                                          : null,
                                      icon: const Icon(Icons.shopping_cart, size: 16),
                                      label: const Text('Add'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: context.colors.freshGreen,
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(borderRadius: AppRadius.radiusMD),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildVendorCard(Map<String, dynamic> vendor, int index) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 400 + (index * 100)),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 30 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: Container(
              margin: const EdgeInsets.only(bottom: AppSpacing.md),
              child: Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: AppRadius.radiusLG),
                child: InkWell(
                  borderRadius: AppRadius.radiusLG,
                  onTap: () => _navigateToVendor(vendor),
                  child: Padding(
                    padding: AppSpacing.paddingLG,
                    child: Row(
                      children: [
                        // Vendor image
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: context.colors.ecoBlue.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.store,
                            color: context.colors.ecoBlue,
                            size: 24,
                          ),
                        ),
                        
                        const SizedBox(width: AppSpacing.md),
                        
                        // Vendor details
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      vendor['name'],
                                      style: context.textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  if (vendor['isVerified']) ...[
                                    Icon(
                                      Icons.verified,
                                      color: context.colors.freshGreen,
                                      size: 16,
                                    ),
                                    const SizedBox(width: 4),
                                  ],
                                  IconButton(
                                    icon: const Icon(Icons.favorite, color: Colors.red),
                                    onPressed: () => _removeFavoriteVendor(vendor),
                                  ),
                                ],
                              ),
                              
                              Text(
                                vendor['description'],
                                style: context.textTheme.bodySmall?.copyWith(
                                  color: context.colors.textSecondary,
                                ),
                              ),
                              
                              const SizedBox(height: 4),
                              
                              Row(
                                children: [
                                  Icon(
                                    Icons.location_on,
                                    size: 14,
                                    color: context.colors.textSecondary,
                                  ),
                                  Text(
                                    vendor['location'],
                                    style: context.textTheme.bodySmall?.copyWith(
                                      color: context.colors.textSecondary,
                                    ),
                                  ),
                                  const SizedBox(width: AppSpacing.sm),
                                  Icon(
                                    Icons.star,
                                    size: 14,
                                    color: Colors.amber,
                                  ),
                                  Text(
                                    vendor['rating'].toString(),
                                    style: context.textTheme.bodySmall,
                                  ),
                                  const SizedBox(width: AppSpacing.sm),
                                  Text(
                                    '${vendor['totalProducts']} products',
                                    style: context.textTheme.bodySmall?.copyWith(
                                      color: context.colors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCategoryCard(String category, int index) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 400 + (index * 100)),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 30 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: AppRadius.radiusLG),
              child: InkWell(
                borderRadius: AppRadius.radiusLG,
                onTap: () => _navigateToCategory(category),
                child: Container(
                  padding: AppSpacing.paddingLG,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        _getCategoryColor(category),
                        _getCategoryColor(category).withValues(alpha: 0.8),
                      ],
                    ),
                    borderRadius: AppRadius.radiusLG,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _getCategoryIcon(category),
                        color: Colors.white,
                        size: 32,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        category.split(' ').map((word) => 
                            word[0].toUpperCase() + word.substring(1)).join(' '),
                        style: context.textTheme.titleMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      IconButton(
                        icon: const Icon(Icons.favorite, color: Colors.white),
                        onPressed: () => _removeFavoriteCategory(category),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // Empty states
  Widget _buildEmptyProductsState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.favorite_border,
            size: 120,
            color: context.colors.textSecondary.withValues(alpha: 0.5),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(
            'No favorite products',
            style: context.textTheme.headlineMedium?.copyWith(
              color: context.colors.textSecondary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Start adding products to your favorites',
            style: context.textTheme.bodyLarge?.copyWith(
              color: context.colors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xl),
          ElevatedButton.icon(
            onPressed: () => NavigationService.toCustomerBrowse(),
            icon: const Icon(Icons.shopping_bag),
            label: const Text('Browse Products'),
            style: ElevatedButton.styleFrom(
              backgroundColor: context.colors.freshGreen,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: AppRadius.radiusLG),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyVendorsState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.store_outlined,
            size: 120,
            color: context.colors.textSecondary.withValues(alpha: 0.5),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(
            'No favorite vendors',
            style: context.textTheme.headlineMedium?.copyWith(
              color: context.colors.textSecondary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Discover and follow your favorite vendors',
            style: context.textTheme.bodyLarge?.copyWith(
              color: context.colors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyCategoriesState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.category_outlined,
            size: 120,
            color: context.colors.textSecondary.withValues(alpha: 0.5),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(
            'No favorite categories',
            style: context.textTheme.headlineMedium?.copyWith(
              color: context.colors.textSecondary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Mark categories as favorites for quick access',
            style: context.textTheme.bodyLarge?.copyWith(
              color: context.colors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: AppSpacing.lg),
          Text('Loading favorites...'),
        ],
      ),
    );
  }

  // Helper methods
  List<Product> _getFilteredProducts() {
    var filtered = _favoriteProducts;
    
    if (_selectedCategory != 'all') {
      filtered = filtered.where((p) => p.category == _selectedCategory).toList();
    }
    
    // Sort products
    switch (_sortBy) {
      case 'name':
        filtered.sort((a, b) => a.name.compareTo(b.name));
        break;
      case 'price':
        filtered.sort((a, b) => a.price.compareTo(b.price));
        break;
      case 'rating':
        filtered.sort((a, b) => b.averageRating.compareTo(a.averageRating));
        break;
      case 'recent':
      default:
        filtered.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
        break;
    }
    
    return filtered;
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'vegetables':
        return context.colors.freshGreen;
      case 'fruits':
        return context.colors.marketOrange;
      case 'grains':
        return Colors.brown;
      case 'dairy':
        return context.colors.ecoBlue;
      default:
        return context.colors.textSecondary;
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'vegetables':
        return Icons.eco;
      case 'fruits':
        return Icons.apple;
      case 'grains':
        return Icons.grain;
      case 'dairy':
        return Icons.opacity;
      default:
        return Icons.category;
    }
  }

  Future<void> _refreshFavorites() async {
    setState(() {
      _isLoading = true;
    });
    
    await Future.delayed(const Duration(seconds: 1));
    _loadFavorites();
    
    setState(() {
      _isLoading = false;
    });
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'clearAll':
        _showClearAllConfirmation();
        break;
      case 'export':
        _exportFavorites();
        break;
    }
  }

  void _showClearAllConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Favorites'),
        content: const Text('Are you sure you want to remove all items from your favorites?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _clearAllFavorites();
            },
            child: const Text('Clear All', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _clearAllFavorites() {
    setState(() {
      _favoriteProducts.clear();
      _favoriteVendors.clear();
      _favoriteCategories.clear();
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('All favorites cleared'),
        backgroundColor: context.colors.freshGreen,
      ),
    );
  }

  void _exportFavorites() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Export functionality coming soon'),
        backgroundColor: context.colors.ecoBlue,
      ),
    );
  }

  void _showSearchDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Search Favorites'),
        content: TextField(
          decoration: const InputDecoration(
            hintText: 'Search products, vendors, or categories...',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
          onSubmitted: (query) {
            Navigator.pop(context);
            _performSearch(query);
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _performSearch(String query) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Searching for "$query"...'),
        backgroundColor: context.colors.ecoBlue,
      ),
    );
  }

  void _removeFavoriteProduct(Product product) {
    setState(() {
      _favoriteProducts.removeWhere((p) => p.id == product.id);
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${product.name} removed from favorites'),
        backgroundColor: context.colors.freshGreen,
        action: SnackBarAction(
          label: 'Undo',
          textColor: Colors.white,
          onPressed: () {
            setState(() {
              _favoriteProducts.add(product);
            });
          },
        ),
      ),
    );
  }

  void _removeFavoriteVendor(Map<String, dynamic> vendor) {
    setState(() {
      _favoriteVendors.removeWhere((v) => v['id'] == vendor['id']);
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${vendor['name']} removed from favorites'),
        backgroundColor: context.colors.freshGreen,
      ),
    );
  }

  void _removeFavoriteCategory(String category) {
    setState(() {
      _favoriteCategories.remove(category);
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$category removed from favorites'),
        backgroundColor: context.colors.freshGreen,
      ),
    );
  }

  void _navigateToProduct(Product product) {
    NavigationService.toProductDetails(product,
    );
  }

  void _viewProduct(Product product) {
    NavigationService.toProductDetails(product,
    );
  }

  void _navigateToVendor(Map<String, dynamic> vendor) {
    NavigationService.toCustomerBrowse();
  }

  void _navigateToCategory(String category) {
    NavigationService.toCustomerBrowse();
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
} 