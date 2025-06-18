import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'package:fresh_marikiti/core/providers/auth_provider.dart';
import 'package:fresh_marikiti/core/providers/product_provider.dart';
import 'package:fresh_marikiti/core/providers/cart_provider.dart';
import 'package:fresh_marikiti/core/providers/location_provider.dart';
import 'package:fresh_marikiti/core/providers/notification_provider.dart';
import 'package:fresh_marikiti/core/providers/order_provider.dart';
import 'package:fresh_marikiti/core/config/theme_extensions.dart';
import 'package:fresh_marikiti/core/services/logger_service.dart';
import 'package:fresh_marikiti/core/services/navigation_service.dart';
import 'package:fresh_marikiti/core/models/product.dart';
import 'package:fresh_marikiti/core/models/user.dart';

class CustomerHomeScreen extends StatefulWidget {
  const CustomerHomeScreen({super.key});

  @override
  State<CustomerHomeScreen> createState() => _CustomerHomeScreenState();
}

class _CustomerHomeScreenState extends State<CustomerHomeScreen> 
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late AnimationController _shimmerController;
  
  final ScrollController _scrollController = ScrollController();
  final PageController _bannerController = PageController();
  
  String _selectedCategory = 'All';
  int _currentBannerIndex = 0;
  bool _showSearchOverlay = false;
  
  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _shimmerController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    _initializeData();
    _startBannerTimer();
    LoggerService.info('Customer home screen initialized', tag: 'CustomerHomeScreen');
  }

  void _initializeData() async {
    await Future.delayed(const Duration(milliseconds: 100));
    _animationController.forward();
    
    if (mounted) {
      final productProvider = Provider.of<ProductProvider>(context, listen: false);
      final cartProvider = Provider.of<CartProvider>(context, listen: false);
      final locationProvider = Provider.of<LocationProvider>(context, listen: false);
      
      await Future.wait([
        productProvider.loadFeaturedProducts(),
        productProvider.loadCategories(),
        cartProvider.initialize(),
        locationProvider.getCurrentLocation(),
      ]);
    }
  }

  void _startBannerTimer() {
    Timer.periodic(const Duration(seconds: 4), (timer) {
      if (mounted && _bannerController.hasClients) {
        final nextPage = (_currentBannerIndex + 1) % _getBanners().length;
        _bannerController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _shimmerController.dispose();
    _scrollController.dispose();
    _bannerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer5<AuthProvider, ProductProvider, CartProvider, LocationProvider, NotificationProvider>(
      builder: (context, authProvider, productProvider, cartProvider, locationProvider, notificationProvider, child) {
        return Scaffold(
          backgroundColor: context.colors.surface,
          body: Stack(
            children: [
              // Main content
              RefreshIndicator(
                onRefresh: () => _refreshData(productProvider, cartProvider, locationProvider),
                color: context.colors.freshGreen,
                child: CustomScrollView(
                  controller: _scrollController,
                  slivers: [
                    _buildAppBar(authProvider, locationProvider, cartProvider, notificationProvider),
                    _buildSearchBar(),
                    _buildPromoBanners(),
                    _buildQuickActions(),
                    _buildCategoriesSection(productProvider),
                    _buildFeaturedVendorsSection(productProvider),
                    _buildFeaturedProductsSection(productProvider),
                    _buildRecentOrdersSection(),
                    _buildSustainabilitySection(),
                    const SliverToBoxAdapter(child: SizedBox(height: 100)),
                  ],
                ),
              ),
              
              // Search overlay
              if (_showSearchOverlay) _buildSearchOverlay(),
            ],
          ),
          floatingActionButton: _buildFloatingActionButton(cartProvider),
        );
      },
    );
  }

  Widget _buildAppBar(AuthProvider authProvider, LocationProvider locationProvider, 
                     CartProvider cartProvider, NotificationProvider notificationProvider) {
    final user = authProvider.user;
    final unreadCount = notificationProvider.unreadCount;
    
    return SliverAppBar(
      backgroundColor: context.colors.freshGreen,
      foregroundColor: Colors.white,
      expandedHeight: 120,
      floating: true,
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                context.colors.freshGreen,
                context.colors.ecoBlue,
              ],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: AppSpacing.paddingLG,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      // Greeting and location
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _getGreeting(),
                              style: context.textTheme.bodyMedium?.copyWith(
                                color: Colors.white.withOpacity(0.9),
                              ),
                            ),
                            Text(
                              user?.name ?? 'Customer',
                              style: context.textTheme.titleLarge?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      // Notifications
                      IconButton(
                        icon: Stack(
                          children: [
                            const Icon(Icons.notifications),
                            if (notificationProvider.unreadCount > 0)
                              Positioned(
                                right: 0,
                                top: 0,
                                child: Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: BoxDecoration(
                                    color: Colors.red,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  constraints: const BoxConstraints(
                                    minWidth: 12,
                                    minHeight: 12,
                                  ),
                                  child: Text(
                                    '${notificationProvider.unreadCount}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 8,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        onPressed: () => NavigationService.toNotifications(),
                      ),
                      
                      // Profile
                      GestureDetector(
                        onTap: () => NavigationService.toCustomerProfile(),
                        child: CircleAvatar(
                          radius: 20,
                          backgroundColor: Colors.white.withOpacity(0.2),
                          child: Text(
                            user?.name.isNotEmpty == true ? user!.name[0].toUpperCase() : 'C',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: AppSpacing.sm),
                  
                  // Location
                  Row(
                    children: [
                      Icon(Icons.location_on, color: Colors.white.withOpacity(0.9), size: 16),
                      const SizedBox(width: AppSpacing.xs),
                      Expanded(
                        child: Text(
                          locationProvider.currentAddress ?? 'Detecting location...',
                          style: context.textTheme.bodySmall?.copyWith(
                            color: Colors.white.withOpacity(0.8),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      TextButton(
                        onPressed: () => NavigationService.toAddresses(),
                        child: Text(
                          'Change',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontWeight: FontWeight.w600,
                          ),
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

  Widget _buildSearchBar() {
    return SliverToBoxAdapter(
      child: Container(
        margin: AppSpacing.paddingMD,
        child: GestureDetector(
          onTap: () => NavigationService.toCustomerBrowse(),
          child: Container(
            padding: AppSpacing.paddingMD,
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
            child: Row(
              children: [
                Icon(Icons.search, color: context.colors.textSecondary),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    'Search for fresh produce, vendors...',
                    style: context.textTheme.bodyMedium?.copyWith(
                      color: context.colors.textSecondary,
                    ),
                  ),
                ),
                Icon(Icons.tune, color: context.colors.textSecondary),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPromoBanners() {
    final banners = _getBanners();
    
    return SliverToBoxAdapter(
      child: Container(
        height: 160,
        margin: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: PageView.builder(
          controller: _bannerController,
          onPageChanged: (index) {
            setState(() {
              _currentBannerIndex = index;
            });
          },
          itemCount: banners.length,
          itemBuilder: (context, index) {
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              decoration: BoxDecoration(
                borderRadius: AppRadius.radiusLG,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: banners[index]['colors'] as List<Color>,
                ),
                boxShadow: [
                  BoxShadow(
                    color: (banners[index]['colors'] as List<Color>)[0].withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: AppRadius.radiusLG,
                      child: Image.asset(
                        banners[index]['image'] as String,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: (banners[index]['colors'] as List<Color>)[0].withOpacity(0.2),
                        ),
                      ),
                    ),
                  ),
                  Container(
                    padding: AppSpacing.paddingLG,
                    decoration: BoxDecoration(
                      borderRadius: AppRadius.radiusLG,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.black.withOpacity(0.3),
                          Colors.transparent,
                        ],
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          banners[index]['title'] as String,
                          style: context.textTheme.titleLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            shadows: [
                              Shadow(
                                color: Colors.black.withOpacity(0.5),
                                offset: const Offset(0, 1),
                                blurRadius: 3,
                              ),
                            ],
                          ),
                        ),
                        Text(
                          banners[index]['subtitle'] as String,
                          style: context.textTheme.bodyMedium?.copyWith(
                            color: Colors.white.withOpacity(0.9),
                            shadows: [
                              Shadow(
                                color: Colors.black.withOpacity(0.5),
                                offset: const Offset(0, 1),
                                blurRadius: 3,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return SliverToBoxAdapter(
      child: Container(
        padding: AppSpacing.paddingMD,
        child: Row(
          children: [
            Expanded(
              child: _buildQuickActionCard(
                icon: Icons.shopping_cart,
                title: 'Browse Products',
                subtitle: 'Fresh & organic',
                color: context.colors.freshGreen,
                onTap: () => NavigationService.toCustomerBrowse(),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _buildQuickActionCard(
                icon: Icons.history,
                title: 'Order History',
                subtitle: 'Track & reorder',
                color: context.colors.ecoBlue,
                onTap: () => NavigationService.toOrderHistory(),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _buildQuickActionCard(
                icon: Icons.favorite,
                title: 'Favorites',
                subtitle: 'Saved items',
                color: context.colors.marketOrange,
                onTap: () => NavigationService.toFavorites(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: AppSpacing.paddingMD,
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: AppRadius.radiusLG,
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: AppSpacing.xs),
            Text(
              title,
              style: context.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: context.colors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            Text(
              subtitle,
              style: context.textTheme.bodySmall?.copyWith(
                color: context.colors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoriesSection(ProductProvider productProvider) {
    final categories = productProvider.categories;
    
    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: AppSpacing.paddingMD,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Categories',
                  style: context.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: context.colors.textPrimary,
                  ),
                ),
                TextButton(
                  onPressed: () => NavigationService.toCustomerBrowse(),
                  child: Text(
                    'View All',
                    style: TextStyle(
                      color: context.colors.freshGreen,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              itemCount: categories.length,
              itemBuilder: (context, index) {
                return _buildCategoryCard(categories[index]);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryCard(String category) {
    return GestureDetector(
      onTap: () => NavigationService.toCustomerBrowse(),
      child: Container(
        width: 80,
        margin: const EdgeInsets.only(right: AppSpacing.sm),
        child: Column(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: context.colors.freshGreen.withValues(alpha: 0.1),
                borderRadius: AppRadius.radiusLG,
              ),
              child: Icon(
                _getCategoryIcon(category),
                color: context.colors.freshGreen,
                size: 28,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              category,
              style: context.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeaturedVendorsSection(ProductProvider productProvider) {
    // Use featured products to represent vendors
    final vendorProducts = productProvider.featuredProducts.take(5).toList();
    
    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: AppSpacing.paddingMD,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Featured Vendors',
                  style: context.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: context.colors.textPrimary,
                  ),
                ),
                TextButton(
                  onPressed: () => NavigationService.toCustomerBrowse(),
                  child: Text(
                    'View All',
                    style: TextStyle(
                      color: context.colors.freshGreen,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(
            height: 140,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              itemCount: vendorProducts.length,
              itemBuilder: (context, index) {
                return _buildVendorCard(vendorProducts[index]);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVendorCard(Product product) {
    return GestureDetector(
      onTap: () => NavigationService.toCustomerBrowse(),
      child: Container(
        width: 120,
        margin: const EdgeInsets.only(right: AppSpacing.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 80,
              decoration: BoxDecoration(
                color: context.colors.surfaceColor,
                borderRadius: AppRadius.radiusLG,
                image: (product.imageUrl?.isNotEmpty ?? false)
                    ? DecorationImage(
                        image: NetworkImage(product.imageUrl!),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: (product.imageUrl?.isEmpty ?? true)
                  ? Icon(
                      Icons.store,
                      color: context.colors.textSecondary,
                      size: 32,
                    )
                  : null,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Vendor ${product.vendorId.substring(0, 6)}',
              style: context.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              '${product.category} • ${product.location}',
              style: context.textTheme.bodySmall?.copyWith(
                color: context.colors.textSecondary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeaturedProductsSection(ProductProvider productProvider) {
    final featuredProducts = productProvider.featuredProducts.take(6).toList();
    
    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: AppSpacing.paddingMD,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Featured Products',
                  style: context.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: context.colors.textPrimary,
                  ),
                ),
                TextButton(
                  onPressed: () => NavigationService.toCustomerBrowse(),
                  child: Text(
                    'View All',
                    style: TextStyle(
                      color: context.colors.freshGreen,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: AppSpacing.paddingMD,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: AppSpacing.sm,
              mainAxisSpacing: AppSpacing.sm,
              childAspectRatio: 0.8,
            ),
            itemCount: featuredProducts.length,
            itemBuilder: (context, index) {
              return _buildProductCard(featuredProducts[index]);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard(Product product) {
    return GestureDetector(
      onTap: () => NavigationService.toProductDetails(product),
      child: Container(
        decoration: BoxDecoration(
          color: context.colors.surfaceColor,
          borderRadius: AppRadius.radiusLG,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
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
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(12),
                  ),
                  image: (product.imageUrl?.isNotEmpty ?? false)
                      ? DecorationImage(
                          image: NetworkImage(product.imageUrl!),
                          fit: BoxFit.cover,
                        )
                      : null,
                  color: (product.imageUrl?.isEmpty ?? true)
                      ? context.colors.outline.withValues(alpha: 0.1)
                      : null,
                ),
                child: Stack(
                  children: [
                    if (product.imageUrl?.isEmpty ?? true)
                      Center(
                        child: Icon(
                          Icons.image,
                          color: context.colors.textSecondary,
                          size: 32,
                        ),
                      ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: product.isOrganic
                              ? context.colors.freshGreen
                              : context.colors.marketOrange,
                          borderRadius: AppRadius.radiusSM,
                        ),
                        child: Text(
                          product.isOrganic ? 'Organic' : 'Fresh',
                          style: context.textTheme.bodySmall?.copyWith(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
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
                      'Vendor ${product.vendorId.substring(0, 6)}',
                      style: context.textTheme.bodySmall?.copyWith(
                        color: context.colors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'KSh ${product.price.toStringAsFixed(0)}',
                          style: context.textTheme.titleSmall?.copyWith(
                            color: context.colors.freshGreen,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (product.averageRating > 0)
                          Row(
                            children: [
                              Icon(
                                Icons.star,
                                color: context.colors.marketOrange,
                                size: 12,
                              ),
                              const SizedBox(width: 2),
                              Text(
                                product.averageRating.toStringAsFixed(1),
                                style: context.textTheme.bodySmall?.copyWith(
                                  fontWeight: FontWeight.w600,
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
          ],
        ),
      ),
    );
  }

  Widget _buildRecentOrdersSection() {
    return SliverToBoxAdapter(
      child: Container(
        margin: AppSpacing.paddingMD,
        padding: AppSpacing.paddingLG,
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Quick Reorder',
                  style: context.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: context.colors.textPrimary,
                  ),
                ),
                TextButton(
                  onPressed: () => NavigationService.toOrderHistory(),
                  child: Text(
                    'View History',
                    style: TextStyle(
                      color: context.colors.ecoBlue,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Reorder your favorite items from recent purchases',
              style: context.textTheme.bodyMedium?.copyWith(
                color: context.colors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            ElevatedButton.icon(
              onPressed: () => NavigationService.toOrderHistory(),
              icon: const Icon(Icons.repeat),
              label: const Text('View Recent Orders'),
              style: ElevatedButton.styleFrom(
                backgroundColor: context.colors.ecoBlue,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: AppRadius.radiusLG,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSustainabilitySection() {
    return SliverToBoxAdapter(
      child: Container(
        margin: AppSpacing.paddingMD,
        padding: AppSpacing.paddingLG,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              context.colors.freshGreen.withOpacity(0.1),
              context.colors.ecoBlue.withOpacity(0.1),
            ],
          ),
          borderRadius: AppRadius.radiusLG,
          border: Border.all(
            color: context.colors.freshGreen.withOpacity(0.3),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.eco, color: context.colors.freshGreen, size: 28),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  'Sustainability Impact',
                  style: context.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: context.colors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Join our waste-to-wealth program and earn eco-points for every organic waste contribution.',
              style: context.textTheme.bodyMedium?.copyWith(
                color: context.colors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                Expanded(
                  child: _buildImpactStat('5.2kg', 'Waste Recycled'),
                ),
                Expanded(
                  child: _buildImpactStat('120', 'Eco Points'),
                ),
                Expanded(
                  child: _buildImpactStat('8', 'Trees Saved'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImpactStat(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: context.textTheme.titleLarge?.copyWith(
            color: context.colors.freshGreen,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: context.textTheme.bodySmall?.copyWith(
            color: context.colors.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildSearchOverlay() {
    return Container(
      color: Colors.black.withOpacity(0.5),
      child: Center(
        child: Container(
          margin: AppSpacing.paddingXL,
          padding: AppSpacing.paddingLG,
          decoration: BoxDecoration(
            color: context.colors.surface,
            borderRadius: AppRadius.radiusLG,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Search',
                    style: context.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    onPressed: () => setState(() => _showSearchOverlay = false),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              // Search content would go here
            ],
          ),
        ),
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
        '${cartProvider.itemCount} items • ${cartProvider.total.toStringAsFixed(0)} KSh',
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  // Helper methods
  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  List<Map<String, dynamic>> _getBanners() {
    return [
      {
        'title': 'Fresh & Organic',
        'subtitle': 'Get the best produce delivered fresh',
        'image': 'assets/images/banner1.jpg',
        'colors': [context.colors.freshGreen, context.colors.ecoBlue],
      },
      {
        'title': 'Support Local Vendors',
        'subtitle': 'Connect with your community farmers',
        'image': 'assets/images/banner2.jpg',
        'colors': [context.colors.marketOrange, context.colors.freshGreen],
      },
      {
        'title': 'Waste to Wealth',
        'subtitle': 'Earn eco-points for sustainability',
        'image': 'assets/images/banner3.jpg',
        'colors': [context.colors.ecoBlue, context.colors.freshGreen],
      },
    ];
  }

  Color _getCategoryColor(String category) {
    final colors = [
      context.colors.freshGreen,
      context.colors.marketOrange,
      context.colors.ecoBlue,
      Colors.purple,
      Colors.red,
    ];
    return colors[category.length % colors.length];
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'vegetables':
        return Icons.eco;
      case 'fruits':
        return Icons.apple;
      case 'dairy':
        return Icons.water_drop;
      case 'grains':
        return Icons.grain;
      case 'meat':
        return Icons.lunch_dining;
      default:
        return Icons.category;
    }
  }

  Future<void> _refreshData(ProductProvider productProvider, CartProvider cartProvider, 
                           LocationProvider locationProvider) async {
    await Future.wait([
      productProvider.loadFeaturedProducts(),
      productProvider.loadCategories(),
      cartProvider.loadCart(),
      locationProvider.getCurrentLocation(),
    ]);
  }

  void _toggleFavorite(Product product) {
    // Implementation for toggling favorites
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Added ${product.name} to favorites'),
        backgroundColor: context.colors.freshGreen,
      ),
    );
  }
} 