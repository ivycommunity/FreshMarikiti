import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fresh_marikiti/core/providers/order_provider.dart';
import 'package:fresh_marikiti/core/providers/auth_provider.dart';
import 'package:fresh_marikiti/core/config/theme_extensions.dart';
import 'package:fresh_marikiti/core/services/logger_service.dart';
import 'package:fresh_marikiti/core/models/order_model.dart';
import 'package:fresh_marikiti/core/services/navigation_service.dart';

class ReviewsScreen extends StatefulWidget {
  const ReviewsScreen({super.key});

  @override
  State<ReviewsScreen> createState() => _ReviewsScreenState();
}

class _ReviewsScreenState extends State<ReviewsScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;
  
  String _selectedTab = 'pending';
  bool _isLoading = false;
  String _filterRating = 'all';
  
  // Demo review data
  List<Map<String, dynamic>> _pendingReviews = [];
  List<Map<String, dynamic>> _completedReviews = [];

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
    
    _loadReviews();
    _animationController.forward();
    LoggerService.info('Reviews screen initialized', tag: 'ReviewsScreen');
  }

  void _loadReviews() {
    _loadPendingReviews();
    _loadCompletedReviews();
  }

  void _loadPendingReviews() {
    // Demo pending reviews - orders ready for review
    _pendingReviews = [
      {
        'orderId': 'ORD_001',
        'orderDate': DateTime.now().subtract(const Duration(days: 2)),
        'totalAmount': 1250.0,
        'vendorName': 'Green Valley Farm',
        'vendorId': 'vendor_001',
        'items': [
          {'name': 'Organic Tomatoes', 'quantity': 2, 'unit': 'kg'},
          {'name': 'Fresh Spinach', 'quantity': 1, 'unit': 'bunch'},
        ],
        'deliveryRating': null,
        'productReviews': [],
        'overallExperience': null,
      },
      {
        'orderId': 'ORD_002',
        'orderDate': DateTime.now().subtract(const Duration(days: 5)),
        'totalAmount': 875.5,
        'vendorName': 'Fresh Fruits Market',
        'vendorId': 'vendor_002',
        'items': [
          {'name': 'Ripe Bananas', 'quantity': 1, 'unit': 'dozen'},
          {'name': 'Red Apples', 'quantity': 3, 'unit': 'kg'},
        ],
        'deliveryRating': null,
        'productReviews': [],
        'overallExperience': null,
      },
    ];
  }

  void _loadCompletedReviews() {
    // Demo completed reviews
    _completedReviews = [
      {
        'orderId': 'ORD_003',
        'orderDate': DateTime.now().subtract(const Duration(days: 15)),
        'reviewDate': DateTime.now().subtract(const Duration(days: 12)),
        'totalAmount': 950.0,
        'vendorName': 'Green Valley Farm',
        'vendorId': 'vendor_001',
        'items': [
          {'name': 'Organic Carrots', 'quantity': 2, 'unit': 'kg'},
        ],
        'deliveryRating': 5,
        'overallRating': 5,
        'comment': 'Excellent quality vegetables, very fresh and delivered on time!',
        'productReviews': [
          {
            'productName': 'Organic Carrots',
            'rating': 5,
            'comment': 'Super fresh and crunchy!',
            'photos': [],
          }
        ],
        'overallExperience': 5,
        'wouldRecommend': true,
      },
      {
        'orderId': 'ORD_004',
        'orderDate': DateTime.now().subtract(const Duration(days: 25)),
        'reviewDate': DateTime.now().subtract(const Duration(days: 20)),
        'totalAmount': 1500.0,
        'vendorName': 'Fresh Fruits Market',
        'vendorId': 'vendor_002',
        'items': [
          {'name': 'Mangoes', 'quantity': 5, 'unit': 'pieces'},
          {'name': 'Pineapple', 'quantity': 1, 'unit': 'piece'},
        ],
        'deliveryRating': 4,
        'overallRating': 4,
        'comment': 'Good quality fruits, delivery was a bit delayed but fruits were fresh.',
        'productReviews': [
          {
            'productName': 'Mangoes',
            'rating': 4,
            'comment': 'Sweet and juicy, but one was overripe',
            'photos': [],
          },
          {
            'productName': 'Pineapple',
            'rating': 5,
            'comment': 'Perfect ripeness!',
            'photos': [],
          }
        ],
        'overallExperience': 4,
        'wouldRecommend': true,
      },
    ];
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<OrderProvider, AuthProvider>(
      builder: (context, orderProvider, authProvider, child) {
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
                      if (_selectedTab == 'completed') _buildFilters(),
                      Expanded(
                        child: _buildSelectedTabContent(),
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
        'Reviews & Ratings',
        style: context.textTheme.titleLarge?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.insights),
          onPressed: () => _showReviewStats(),
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
            child: _buildTabButton('pending', 'Pending Reviews', Icons.rate_review),
          ),
          Expanded(
            child: _buildTabButton('completed', 'My Reviews', Icons.reviews),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton(String tabId, String title, IconData icon) {
    final isSelected = _selectedTab == tabId;
    final count = tabId == 'pending' ? _pendingReviews.length : _completedReviews.length;
    
    return GestureDetector(
      onTap: () => setState(() => _selectedTab = tabId),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected ? context.colors.freshGreen : Colors.transparent,
          borderRadius: AppRadius.radiusLG,
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  color: isSelected ? Colors.white : context.colors.textSecondary,
                  size: 18,
                ),
                const SizedBox(width: 4),
                if (count > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: isSelected 
                          ? Colors.white.withValues(alpha: 0.2)
                          : context.colors.freshGreen,
                      borderRadius: AppRadius.radiusSM,
                    ),
                    child: Text(
                      count.toString(),
                      style: context.textTheme.bodySmall?.copyWith(
                        color: isSelected ? Colors.white : Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
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

  Widget _buildFilters() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Icon(Icons.filter_list, color: context.colors.freshGreen, size: 18),
          const SizedBox(width: 8),
          Text(
            'Filter by rating:',
            style: context.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: context.colors.surfaceColor,
                borderRadius: AppRadius.radiusMD,
                border: Border.all(color: context.colors.textSecondary.withValues(alpha: 0.2)),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _filterRating,
                  isExpanded: true,
                  items: const [
                    DropdownMenuItem(value: 'all', child: Text('All Ratings')),
                    DropdownMenuItem(value: '5', child: Text('5 Stars')),
                    DropdownMenuItem(value: '4', child: Text('4 Stars')),
                    DropdownMenuItem(value: '3', child: Text('3 Stars')),
                    DropdownMenuItem(value: '2', child: Text('2 Stars')),
                    DropdownMenuItem(value: '1', child: Text('1 Star')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _filterRating = value!;
                    });
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedTabContent() {
    switch (_selectedTab) {
      case 'pending':
        return _buildPendingReviewsTab();
      case 'completed':
        return _buildCompletedReviewsTab();
      default:
        return _buildPendingReviewsTab();
    }
  }

  Widget _buildPendingReviewsTab() {
    if (_isLoading) {
      return _buildLoadingState();
    }
    
    if (_pendingReviews.isEmpty) {
      return _buildEmptyPendingState();
    }
    
    return ListView.builder(
      padding: AppSpacing.paddingMD,
      itemCount: _pendingReviews.length,
      itemBuilder: (context, index) {
        final review = _pendingReviews[index];
        return _buildPendingReviewCard(review, index);
      },
    );
  }

  Widget _buildCompletedReviewsTab() {
    final filteredReviews = _getFilteredCompletedReviews();
    
    if (filteredReviews.isEmpty) {
      return _buildEmptyCompletedState();
    }
    
    return ListView.builder(
      padding: AppSpacing.paddingMD,
      itemCount: filteredReviews.length,
      itemBuilder: (context, index) {
        final review = filteredReviews[index];
        return _buildCompletedReviewCard(review, index);
      },
    );
  }

  Widget _buildPendingReviewCard(Map<String, dynamic> review, int index) {
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
                child: Padding(
                  padding: AppSpacing.paddingLG,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Order header
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: context.colors.marketOrange.withValues(alpha: 0.2),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.rate_review,
                              color: context.colors.marketOrange,
                              size: 20,
                            ),
                          ),
                          
                          const SizedBox(width: AppSpacing.sm),
                          
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Order ${review['orderId']}',
                                  style: context.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  'From ${review['vendorName']}',
                                  style: context.textTheme.bodySmall?.copyWith(
                                    color: context.colors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                'KSh ${review['totalAmount'].toStringAsFixed(2)}',
                                style: context.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: context.colors.freshGreen,
                                ),
                              ),
                              Text(
                                _formatDate(review['orderDate']),
                                style: context.textTheme.bodySmall?.copyWith(
                                  color: context.colors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: AppSpacing.md),
                      
                      // Items summary
                      Container(
                        padding: AppSpacing.paddingMD,
                        decoration: BoxDecoration(
                          color: context.colors.freshGreen.withValues(alpha: 0.1),
                          borderRadius: AppRadius.radiusMD,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Items in this order:',
                              style: context.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            ...review['items'].map<Widget>((item) => Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Text(
                                '• ${item['name']} (${item['quantity']} ${item['unit']})',
                                style: context.textTheme.bodySmall,
                              ),
                            )),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: AppSpacing.md),
                      
                      // Review call-to-action
                      Container(
                        padding: AppSpacing.paddingMD,
                        decoration: BoxDecoration(
                          color: context.colors.ecoBlue.withValues(alpha: 0.1),
                          borderRadius: AppRadius.radiusMD,
                          border: Border.all(color: context.colors.ecoBlue.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.star, color: context.colors.ecoBlue, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Help others by sharing your experience!',
                                style: context.textTheme.bodyMedium?.copyWith(
                                  color: context.colors.ecoBlue,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: AppSpacing.md),
                      
                      // Action button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () => _startReview(review),
                          icon: const Icon(Icons.rate_review, size: 18),
                          label: const Text('Write Review'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: context.colors.freshGreen,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: AppRadius.radiusMD),
                          ),
                        ),
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

  Widget _buildCompletedReviewCard(Map<String, dynamic> review, int index) {
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
                child: Padding(
                  padding: AppSpacing.paddingLG,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Review header
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: context.colors.freshGreen.withValues(alpha: 0.2),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.reviews,
                              color: context.colors.freshGreen,
                              size: 20,
                            ),
                          ),
                          
                          const SizedBox(width: AppSpacing.sm),
                          
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Order ${review['orderId']}',
                                  style: context.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  'From ${review['vendorName']}',
                                  style: context.textTheme.bodySmall?.copyWith(
                                    color: context.colors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              _buildStarRating(review['overallRating']),
                              Text(
                                _formatDate(review['reviewDate']),
                                style: context.textTheme.bodySmall?.copyWith(
                                  color: context.colors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: AppSpacing.md),
                      
                      // Review comment
                      if (review['comment'] != null && review['comment'].isNotEmpty) ...[
                        Container(
                          padding: AppSpacing.paddingMD,
                          decoration: BoxDecoration(
                            color: context.colors.surfaceColor,
                            borderRadius: AppRadius.radiusMD,
                          ),
                          child: Text(
                            review['comment'],
                            style: context.textTheme.bodyMedium,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                      ],
                      
                      // Delivery rating
                      Row(
                        children: [
                          Icon(Icons.delivery_dining, 
                               color: context.colors.ecoBlue, size: 18),
                          const SizedBox(width: 4),
                          Text(
                            'Delivery:',
                            style: context.textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 4),
                          _buildStarRating(review['deliveryRating']),
                        ],
                      ),
                      
                      const SizedBox(height: AppSpacing.sm),
                      
                      // Product reviews
                      if (review['productReviews'].isNotEmpty) ...[
                        Text(
                          'Product Reviews:',
                          style: context.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        ...review['productReviews'].map<Widget>((productReview) => 
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    productReview['productName'],
                                    style: context.textTheme.bodySmall,
                                  ),
                                ),
                                _buildStarRating(productReview['rating']),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                      ],
                      
                      // Action buttons
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => _editReview(review),
                              icon: const Icon(Icons.edit, size: 16),
                              label: const Text('Edit'),
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(color: context.colors.ecoBlue),
                                shape: RoundedRectangleBorder(borderRadius: AppRadius.radiusMD),
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => _shareReview(review),
                              icon: const Icon(Icons.share, size: 16),
                              label: const Text('Share'),
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
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStarRating(int rating) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        return Icon(
          index < rating ? Icons.star : Icons.star_border,
          color: Colors.amber,
          size: 16,
        );
      }),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: AppSpacing.lg),
          Text('Loading reviews...'),
        ],
      ),
    );
  }

  Widget _buildEmptyPendingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.rate_review_outlined,
            size: 120,
            color: context.colors.textSecondary.withValues(alpha: 0.5),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(
            'No pending reviews',
            style: context.textTheme.headlineMedium?.copyWith(
              color: context.colors.textSecondary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Complete an order to start reviewing',
            style: context.textTheme.bodyLarge?.copyWith(
              color: context.colors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xl),
          ElevatedButton.icon(
            onPressed: () => NavigationService.toCustomerHome(),
            icon: const Icon(Icons.shopping_bag),
            label: const Text('Start Shopping'),
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

  Widget _buildEmptyCompletedState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.reviews_outlined,
            size: 120,
            color: context.colors.textSecondary.withValues(alpha: 0.5),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(
            'No reviews yet',
            style: context.textTheme.headlineMedium?.copyWith(
              color: context.colors.textSecondary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Your completed reviews will appear here',
            style: context.textTheme.bodyLarge?.copyWith(
              color: context.colors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // Helper methods
  List<Map<String, dynamic>> _getFilteredCompletedReviews() {
    if (_filterRating == 'all') {
      return _completedReviews;
    }
    
    final rating = int.parse(_filterRating);
    return _completedReviews.where((review) => 
        review['overallRating'] == rating).toList();
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _startReview(Map<String, dynamic> order) {
    _showReviewDialog(order);
  }

  void _showReviewDialog(Map<String, dynamic> order) {
    int deliveryRating = 0;
    int overallRating = 0;
    final commentController = TextEditingController();
    final Map<String, int> productRatings = {};
    final Map<String, String> productComments = {};
    
    // Initialize product ratings
    for (var item in order['items']) {
      productRatings[item['name']] = 0;
      productComments[item['name']] = '';
    }
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Dialog(
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.8,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Dialog header
                Container(
                  padding: AppSpacing.paddingLG,
                  decoration: BoxDecoration(
                    color: context.colors.freshGreen,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.rate_review, color: Colors.white),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Review Order ${order['orderId']}',
                          style: context.textTheme.titleMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                
                // Dialog content
                Expanded(
                  child: SingleChildScrollView(
                    padding: AppSpacing.paddingLG,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Overall rating
                        Text(
                          'Overall Experience',
                          style: context.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _buildInteractiveRating(
                          overallRating,
                          (rating) => setState(() => overallRating = rating),
                        ),
                        
                        const SizedBox(height: AppSpacing.lg),
                        
                        // Delivery rating
                        Text(
                          'Delivery Service',
                          style: context.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _buildInteractiveRating(
                          deliveryRating,
                          (rating) => setState(() => deliveryRating = rating),
                        ),
                        
                        const SizedBox(height: AppSpacing.lg),
                        
                        // Product ratings
                        Text(
                          'Product Quality',
                          style: context.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ...order['items'].map<Widget>((item) {
                          final productName = item['name'];
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                productName,
                                style: context.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              _buildInteractiveRating(
                                productRatings[productName] ?? 0,
                                (rating) => setState(() => productRatings[productName] = rating),
                              ),
                              const SizedBox(height: AppSpacing.sm),
                            ],
                          );
                        }),
                        
                        const SizedBox(height: AppSpacing.lg),
                        
                        // Comment
                        Text(
                          'Additional Comments',
                          style: context.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: commentController,
                          maxLines: 3,
                          decoration: const InputDecoration(
                            hintText: 'Share your experience...',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                // Dialog actions
                Container(
                  padding: AppSpacing.paddingLG,
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            _submitReview(
                              order,
                              overallRating,
                              deliveryRating,
                              productRatings,
                              commentController.text,
                            );
                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: context.colors.freshGreen,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Submit Review'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInteractiveRating(int rating, Function(int) onRatingChanged) {
    return Row(
      children: List.generate(5, (index) {
        return GestureDetector(
          onTap: () => onRatingChanged(index + 1),
          child: Icon(
            index < rating ? Icons.star : Icons.star_border,
            color: Colors.amber,
            size: 32,
          ),
        );
      }),
    );
  }

  void _submitReview(
    Map<String, dynamic> order,
    int overallRating,
    int deliveryRating,
    Map<String, int> productRatings,
    String comment,
  ) {
    // Create review object
    final review = {
      'orderId': order['orderId'],
      'orderDate': order['orderDate'],
      'reviewDate': DateTime.now(),
      'totalAmount': order['totalAmount'],
      'vendorName': order['vendorName'],
      'vendorId': order['vendorId'],
      'items': order['items'],
      'deliveryRating': deliveryRating,
      'overallRating': overallRating,
      'comment': comment,
      'productReviews': productRatings.entries.map((entry) => {
        'productName': entry.key,
        'rating': entry.value,
        'comment': '',
        'photos': [],
      }).toList(),
      'overallExperience': overallRating,
      'wouldRecommend': overallRating >= 4,
    };
    
    setState(() {
      // Move from pending to completed
      _pendingReviews.removeWhere((r) => r['orderId'] == order['orderId']);
      _completedReviews.insert(0, review);
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Review submitted successfully!'),
        backgroundColor: context.colors.freshGreen,
        action: SnackBarAction(
          label: 'View',
          textColor: Colors.white,
          onPressed: () => setState(() => _selectedTab = 'completed'),
        ),
      ),
    );
  }

  void _editReview(Map<String, dynamic> review) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Edit review functionality coming soon'),
        backgroundColor: context.colors.ecoBlue,
      ),
    );
  }

  void _shareReview(Map<String, dynamic> review) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Sharing review for Order ${review['orderId']}'),
        backgroundColor: context.colors.ecoBlue,
      ),
    );
  }

  void _showReviewStats() {
    final totalReviews = _completedReviews.length;
    final averageRating = totalReviews > 0 
        ? _completedReviews.fold(0.0, (sum, review) => sum + review['overallRating']) / totalReviews
        : 0.0;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.insights, color: context.colors.freshGreen),
            const SizedBox(width: 8),
            const Text('Review Statistics'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildStatItem('Total Reviews', totalReviews.toString(), Icons.reviews),
            const SizedBox(height: AppSpacing.md),
            _buildStatItem('Average Rating', averageRating.toStringAsFixed(1), Icons.star),
            const SizedBox(height: AppSpacing.md),
            _buildStatItem('Pending Reviews', _pendingReviews.length.toString(), Icons.pending),
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

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: context.colors.freshGreen, size: 20),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: context.textTheme.bodyMedium,
          ),
        ),
        Text(
          value,
          style: context.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: context.colors.freshGreen,
          ),
        ),
      ],
    );
  }
} 