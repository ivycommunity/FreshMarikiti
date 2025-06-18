import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:fresh_marikiti/core/providers/cart_provider.dart';
import 'package:fresh_marikiti/core/providers/rating_provider.dart';
import 'package:fresh_marikiti/core/providers/auth_provider.dart';
import 'package:fresh_marikiti/core/config/theme_extensions.dart';
import 'package:fresh_marikiti/core/services/logger_service.dart';
import 'package:fresh_marikiti/core/services/navigation_service.dart';
import 'package:fresh_marikiti/core/models/product.dart';
import 'package:fresh_marikiti/core/models/user.dart';
import 'dart:async';

class ProductDetailsScreen extends StatefulWidget {
  final Product product;

  const ProductDetailsScreen({
    super.key,
    required this.product,
  });

  @override
  State<ProductDetailsScreen> createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late AnimationController _fabAnimationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;
  late Animation<double> _fabAnimation;

  final ScrollController _scrollController = ScrollController();
  final PageController _imageController = PageController();

  int _currentImageIndex = 0;
  int _quantity = 1;
  bool _isFavorite = false;
  bool _showFullDescription = false;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fabAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
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
      begin: 50.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    _fabAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fabAnimationController,
      curve: Curves.elasticOut,
    ));

    _animationController.forward();
    Future.delayed(const Duration(milliseconds: 300), () {
      _fabAnimationController.forward();
    });

    _loadProductRatings();
    LoggerService.info(
        'Product details screen initialized for ${widget.product.name}',
        tag: 'ProductDetailsScreen');
  }

  void _loadProductRatings() {
    // Since the RatingProvider doesn't have loadProductRatings method,
    // we'll handle ratings through the UserRating system
    // This will be implemented when we have proper product ratings
  }

  @override
  void dispose() {
    _animationController.dispose();
    _fabAnimationController.dispose();
    _scrollController.dispose();
    _imageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer3<CartProvider, Null, AuthProvider>(
      builder: (context, cartProvider, ratingProvider, authProvider, child) {
        return Scaffold(
          backgroundColor: context.colors.surface,
          body: CustomScrollView(
            controller: _scrollController,
            slivers: [
              _buildAppBar(context),
              _buildProductImages(),
              _buildProductInfo(),
              _buildVendorInfo(),
              _buildDescription(),
              _buildNutritionInfo(),
              //_buildRatingsSection(ratingProvider),
              _buildRelatedProducts(),
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),
          floatingActionButton: AnimatedBuilder(
            animation: _fabAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _fabAnimation.value,
                child: FloatingActionButton.extended(
                  onPressed: widget.product.isAvailable
                      ? () => _addToCart(cartProvider)
                      : null,
                  backgroundColor: widget.product.isAvailable
                      ? context.colors.freshGreen
                      : context.colors.textSecondary,
                  icon:
                      const Icon(Icons.add_shopping_cart, color: Colors.white),
                  label: Text(
                    widget.product.isAvailable ? 'Add to Cart' : 'Out of Stock',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return SliverAppBar(
      backgroundColor: context.colors.freshGreen,
      foregroundColor: Colors.white,
      expandedHeight: 60,
      floating: true,
      pinned: true,
      actions: [
        IconButton(
          icon: Icon(_isFavorite ? Icons.favorite : Icons.favorite_border),
          onPressed: () => _toggleFavorite(),
        ),
        IconButton(
          icon: const Icon(Icons.share),
          onPressed: () => _shareProduct(),
        ),
        IconButton(
          icon: const Icon(Icons.shopping_cart),
          onPressed: () => NavigationService.toCart(),
        ),
      ],
    );
  }

  Widget _buildProductImages() {
    final images = widget.product.hasImages
        ? widget.product.images
        : ['assets/images/placeholder_product.png'];

    return SliverToBoxAdapter(
      child: AnimatedBuilder(
        animation: _fadeAnimation,
        builder: (context, child) {
          return Opacity(
            opacity: _fadeAnimation.value,
            child: Container(
              height: 300,
              child: Stack(
                children: [
                  PageView.builder(
                    controller: _imageController,
                    onPageChanged: (index) {
                      setState(() {
                        _currentImageIndex = index;
                      });
                    },
                    itemCount: images.length,
                    itemBuilder: (context, index) {
                      return Container(
                        decoration: BoxDecoration(
                          color: context.colors.freshGreen.withOpacity(0.1),
                        ),
                        child: Center(
                          child: Icon(
                            Icons.eco,
                            size: 120,
                            color: context.colors.freshGreen.withOpacity(0.3),
                          ),
                        ),
                      );
                    },
                  ),

                  // Image indicator
                  if (images.length > 1)
                    Positioned(
                      bottom: 16,
                      left: 0,
                      right: 0,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: images.asMap().entries.map((entry) {
                          return Container(
                            width: 8,
                            height: 8,
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _currentImageIndex == entry.key
                                  ? context.colors.freshGreen
                                  : Colors.white.withOpacity(0.5),
                            ),
                          );
                        }).toList(),
                      ),
                    ),

                  // Product badges
                  Positioned(
                    top: 16,
                    left: 16,
                    child: Column(
                      children: [
                        if (widget.product.isOrganic)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: context.colors.freshGreen,
                              borderRadius: AppRadius.radiusMD,
                            ),
                            child: Text(
                              'Organic',
                              style: context.textTheme.bodySmall?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        if (widget.product.isFeatured)
                          Container(
                            margin: const EdgeInsets.only(top: 8),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: context.colors.marketOrange,
                              borderRadius: AppRadius.radiusMD,
                            ),
                            child: Text(
                              'Featured',
                              style: context.textTheme.bodySmall?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),

                  // Stock status
                  Positioned(
                    top: 16,
                    right: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: widget.product.isAvailable
                            ? context.colors.freshGreen
                            : Colors.red,
                        borderRadius: AppRadius.radiusMD,
                      ),
                      child: Text(
                        widget.product.stockStatus,
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
          );
        },
      ),
    );
  }

  Widget _buildProductInfo() {
    return SliverToBoxAdapter(
      child: AnimatedBuilder(
        animation: _slideAnimation,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(0, _slideAnimation.value),
            child: Container(
              padding: AppSpacing.paddingLG,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Product name and rating
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          widget.product.name,
                          style: context.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: context.colors.textPrimary,
                          ),
                        ),
                      ),
                      if (widget.product.hasRating)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: context.colors.marketOrange.withOpacity(0.2),
                            borderRadius: AppRadius.radiusLG,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.star,
                                color: context.colors.marketOrange,
                                size: 16,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                widget.product.ratingDisplay,
                                style: context.textTheme.titleSmall?.copyWith(
                                  color: context.colors.marketOrange,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                ' (${widget.product.totalRatings})',
                                style: context.textTheme.bodySmall?.copyWith(
                                  color: context.colors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),

                  const SizedBox(height: AppSpacing.sm),

                  // Category
                  Text(
                    widget.product.category.toUpperCase(),
                    style: context.textTheme.bodySmall?.copyWith(
                      color: context.colors.textSecondary,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.2,
                    ),
                  ),

                  const SizedBox(height: AppSpacing.lg),

                  // Price and quantity selector
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.product.formattedPrice,
                              style: context.textTheme.headlineLarge?.copyWith(
                                color: context.colors.freshGreen,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'per ${widget.product.unit}',
                              style: context.textTheme.bodyMedium?.copyWith(
                                color: context.colors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Quantity selector
                      if (widget.product.isAvailable)
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(
                              color:
                                  context.colors.textSecondary.withOpacity(0.3),
                            ),
                            borderRadius: AppRadius.radiusLG,
                          ),
                          child: Row(
                            children: [
                              IconButton(
                                onPressed: _quantity > 1
                                    ? () => _decreaseQuantity()
                                    : null,
                                icon: const Icon(Icons.remove),
                                iconSize: 20,
                              ),
                              Container(
                                width: 40,
                                child: Text(
                                  _quantity.toString(),
                                  style:
                                      context.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              IconButton(
                                onPressed:
                                    _quantity < widget.product.quantityAvailable
                                        ? () => _increaseQuantity()
                                        : null,
                                icon: const Icon(Icons.add),
                                iconSize: 20,
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),

                  const SizedBox(height: AppSpacing.sm),

                  // Available quantity
                  Text(
                    '${widget.product.quantityAvailable} ${widget.product.unit}s available',
                    style: context.textTheme.bodySmall?.copyWith(
                      color: context.colors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildVendorInfo() {
    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        padding: AppSpacing.paddingLG,
        decoration: BoxDecoration(
          color: context.colors.surfaceColor,
          borderRadius: AppRadius.radiusLG,
          border: Border.all(
            color: context.colors.textSecondary.withOpacity(0.2),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: context.colors.freshGreen.withOpacity(0.2),
                    borderRadius: AppRadius.radiusMD,
                  ),
                  child: Icon(
                    Icons.store,
                    color: context.colors.freshGreen,
                    size: 24,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Vendor ${widget.product.vendorId.substring(0, 8)}',
                        style: context.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        widget.product.location,
                        style: context.textTheme.bodyMedium?.copyWith(
                          color: context.colors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () => _viewVendor(),
                  child: Text(
                    'View Store',
                    style: TextStyle(
                      color: context.colors.freshGreen,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: AppSpacing.md),

            // Vendor stats
            Row(
              children: [
                Expanded(
                  child: _buildVendorStat('4.2', 'Rating'),
                ),
                Expanded(
                  child: _buildVendorStat('150+', 'Products'),
                ),
                Expanded(
                  child: _buildVendorStat('2.5km', 'Distance'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVendorStat(String value, String label) {
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
        ),
      ],
    );
  }

  Widget _buildDescription() {
    if (widget.product.description == null ||
        widget.product.description!.isEmpty) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }

    return SliverToBoxAdapter(
      child: Container(
        padding: AppSpacing.paddingLG,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Description',
              style: context.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: context.colors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              widget.product.description!,
              style: context.textTheme.bodyLarge?.copyWith(
                height: 1.5,
                color: context.colors.textPrimary,
              ),
              maxLines: _showFullDescription ? null : 3,
              overflow: _showFullDescription ? null : TextOverflow.ellipsis,
            ),
            if (widget.product.description!.length > 150)
              TextButton(
                onPressed: () {
                  setState(() {
                    _showFullDescription = !_showFullDescription;
                  });
                },
                child: Text(
                  _showFullDescription ? 'Show Less' : 'Show More',
                  style: TextStyle(
                    color: context.colors.freshGreen,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildNutritionInfo() {
    if (widget.product.nutritionInfo == null ||
        widget.product.nutritionInfo!.isEmpty) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }

    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        padding: AppSpacing.paddingLG,
        decoration: BoxDecoration(
          color: context.colors.surfaceColor,
          borderRadius: AppRadius.radiusLG,
          border: Border.all(
            color: context.colors.textSecondary.withOpacity(0.2),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.local_dining,
                  color: context.colors.ecoBlue,
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  'Nutrition Information',
                  style: context.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: context.colors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            ...widget.product.nutritionInfo!.entries.map((entry) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      entry.key,
                      style: context.textTheme.bodyMedium,
                    ),
                    Text(
                      entry.value.toString(),
                      style: context.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  // Widget _buildRatingsSection(RatingProvider ratingProvider) {
  //   return SliverToBoxAdapter(
  //     child: Container(
  //       padding: AppSpacing.paddingLG,
  //       child: Column(
  //         crossAxisAlignment: CrossAxisAlignment.start,
  //         children: [
  //           Row(
  //             mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //             children: [
  //               Text(
  //                 'Reviews & Ratings',
  //                 style: context.textTheme.titleLarge?.copyWith(
  //                   fontWeight: FontWeight.bold,
  //                   color: context.colors.textPrimary,
  //                 ),
  //               ),
  //               TextButton(
  //                 onPressed: () => _writeReview(),
  //                 child: Text(
  //                   'Write Review',
  //                   style: TextStyle(
  //                     color: context.colors.freshGreen,
  //                     fontWeight: FontWeight.w600,
  //                   ),
  //                 ),
  //               ),
  //             ],
  //           ),

  //           const SizedBox(height: AppSpacing.md),

  //           if (widget.product.hasRating) ...[
  //             // Rating summary
  //             Row(
  //               children: [
  //                 Text(
  //                   widget.product.averageRating.toStringAsFixed(1),
  //                   style: context.textTheme.headlineLarge?.copyWith(
  //                     color: context.colors.marketOrange,
  //                     fontWeight: FontWeight.bold,
  //                   ),
  //                 ),
  //                 const SizedBox(width: AppSpacing.sm),
  //                 Column(
  //                   crossAxisAlignment: CrossAxisAlignment.start,
  //                   children: [
  //                     Row(
  //                       children: List.generate(5, (index) {
  //                         return Icon(
  //                           index < widget.product.averageRating.floor()
  //                               ? Icons.star
  //                               : Icons.star_border,
  //                           color: context.colors.marketOrange,
  //                           size: 20,
  //                         );
  //                       }),
  //                     ),
  //                     Text(
  //                       '${widget.product.totalRatings} reviews',
  //                       style: context.textTheme.bodySmall?.copyWith(
  //                         color: context.colors.textSecondary,
  //                       ),
  //                     ),
  //                   ],
  //                 ),
  //               ],
  //             ),

  //             const SizedBox(height: AppSpacing.lg),

  //             // Recent reviews placeholder
  //             if (ratingProvider.isLoading)
  //               const Center(child: CircularProgressIndicator())
  //             else if (ratingProvider.userRatings.isNotEmpty)
  //               ...ratingProvider.userRatings.take(3).map((rating) {
  //                 return Container(
  //                   margin: const EdgeInsets.only(bottom: AppSpacing.md),
  //                   padding: AppSpacing.paddingMD,
  //                   decoration: BoxDecoration(
  //                     color: context.colors.surfaceColor,
  //                     borderRadius: AppRadius.radiusMD,
  //                     border: Border.all(
  //                       color: context.colors.textSecondary.withOpacity(0.2),
  //                     ),
  //                   ),
  //                   child: Column(
  //                     crossAxisAlignment: CrossAxisAlignment.start,
  //                     children: [
  //                       Row(
  //                         children: [
  //                           CircleAvatar(
  //                             radius: 16,
  //                             backgroundColor: context.colors.freshGreen,
  //                             child: Text(
  //                               'U',
  //                               style: const TextStyle(
  //                                 color: Colors.white,
  //                                 fontWeight: FontWeight.bold,
  //                                 fontSize: 12,
  //                               ),
  //                             ),
  //                           ),
  //                           const SizedBox(width: AppSpacing.sm),
  //                           Expanded(
  //                             child: Column(
  //                               crossAxisAlignment: CrossAxisAlignment.start,
  //                               children: [
  //                                 Text(
  //                                   'Customer Review',
  //                                   style: context.textTheme.titleSmall?.copyWith(
  //                                     fontWeight: FontWeight.bold,
  //                                   ),
  //                                 ),
  //                                 Row(
  //                                   children: [
  //                                     ...List.generate(5, (index) {
  //                                       return Icon(
  //                                         index < rating.overallRating
  //                                             ? Icons.star
  //                                             : Icons.star_border,
  //                                         color: context.colors.marketOrange,
  //                                         size: 14,
  //                                       );
  //                                     }),
  //                                     const SizedBox(width: AppSpacing.xs),
  //                                     Text(
  //                                       rating.createdAt.toLocal().toString().split(' ')[0],
  //                                       style: context.textTheme.bodySmall?.copyWith(
  //                                         color: context.colors.textSecondary,
  //                                       ),
  //                                     ),
  //                                   ],
  //                                 ),
  //                               ],
  //                             ),
  //                           ),
  //                         ],
  //                       ),
  //                       if (rating.comment?.isNotEmpty == true) ...[
  //                         const SizedBox(height: AppSpacing.sm),
  //                         Text(
  //                           rating.comment!,
  //                           style: context.textTheme.bodyMedium?.copyWith(
  //                             height: 1.4,
  //                           ),
  //                         ),
  //                       ],
  //                     ],
  //                   ),
  //                 );
  //               }),

  //             TextButton(
  //               onPressed: () => _viewAllReviews(),
  //               child: Text(
  //                 'View All Reviews',
  //                 style: TextStyle(
  //                   color: context.colors.freshGreen,
  //                   fontWeight: FontWeight.w600,
  //                 ),
  //               ),
  //             ),
  //           ] else ...[
  //             Container(
  //               padding: AppSpacing.paddingXL,
  //               decoration: BoxDecoration(
  //                 color: context.colors.surfaceColor,
  //                 borderRadius: AppRadius.radiusMD,
  //               ),
  //               child: Column(
  //                 children: [
  //                   Icon(
  //                     Icons.star_border,
  //                     size: 48,
  //                     color: context.colors.textSecondary.withOpacity(0.5),
  //                   ),
  //                   const SizedBox(height: AppSpacing.sm),
  //                   Text(
  //                     'No reviews yet',
  //                     style: context.textTheme.titleMedium?.copyWith(
  //                       color: context.colors.textSecondary,
  //                       fontWeight: FontWeight.bold,
  //                     ),
  //                   ),
  //                   Text(
  //                     'Be the first to review this product',
  //                     style: context.textTheme.bodyMedium?.copyWith(
  //                       color: context.colors.textSecondary,
  //                     ),
  //                   ),
  //                 ],
  //               ),
  //             ),
  //           ],
  //         ],
  //       ),
  //     ),
  //   );
  // }

  Widget _buildRelatedProducts() {
    return SliverToBoxAdapter(
      child: Container(
        padding: AppSpacing.paddingLG,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Related Products',
              style: context.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: context.colors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Container(
              height: 200,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: 5, // Mock related products
                itemBuilder: (context, index) {
                  return Container(
                    width: 150,
                    margin: const EdgeInsets.only(right: AppSpacing.sm),
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
                          child: Container(
                            decoration: BoxDecoration(
                              color: context.colors.freshGreen.withOpacity(0.1),
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(16),
                                topRight: Radius.circular(16),
                              ),
                            ),
                            child: Center(
                              child: Icon(
                                Icons.eco,
                                color: context.colors.freshGreen,
                                size: 32,
                              ),
                            ),
                          ),
                        ),
                        Padding(
                          padding: AppSpacing.paddingSM,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Related Product ${index + 1}',
                                style: context.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                'KSh ${(50 + index * 10).toStringAsFixed(2)}',
                                style: context.textTheme.titleMedium?.copyWith(
                                  color: context.colors.freshGreen,
                                  fontWeight: FontWeight.bold,
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
          ],
        ),
      ),
    );
  }

  // Helper methods
  void _increaseQuantity() {
    if (_quantity < widget.product.quantityAvailable) {
      setState(() {
        _quantity++;
      });
    }
  }

  void _decreaseQuantity() {
    if (_quantity > 1) {
      setState(() {
        _quantity--;
      });
    }
  }

  void _addToCart(CartProvider cartProvider) async {
    await cartProvider.addToCart(widget.product, quantity: _quantity);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${widget.product.name} added to cart'),
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

  void _toggleFavorite() {
    setState(() {
      _isFavorite = !_isFavorite;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_isFavorite
            ? '${widget.product.name} added to favorites'
            : '${widget.product.name} removed from favorites'),
        backgroundColor: context.colors.freshGreen,
      ),
    );
  }

  void _shareProduct() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Sharing ${widget.product.name}...'),
        backgroundColor: context.colors.freshGreen,
      ),
    );
  }

  void _viewVendor() {
    NavigationService.toCustomerBrowse();
  }

  void _writeReview() {
    NavigationService.toRating(
      targetId: widget.product.id,
      ratingType: 'product',
      targetData: {
        'name': widget.product.name,
        'category': widget.product.category,
      },
    );
  }

  void _viewAllReviews() {
    NavigationService.toReviews();
  }
}
