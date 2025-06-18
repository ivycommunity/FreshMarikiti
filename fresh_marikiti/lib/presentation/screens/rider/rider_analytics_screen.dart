import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fresh_marikiti/core/providers/auth_provider.dart';
import 'package:fresh_marikiti/core/config/theme_extensions.dart';
import 'package:fresh_marikiti/core/services/logger_service.dart';
import 'package:fresh_marikiti/core/services/api_service.dart';
import 'dart:convert';

class AnalyticsData {
  final Map<String, double> deliveryTrends;
  final Map<String, double> earningsTrends;
  final double averageRating;
  final int totalRatings;
  final List<CustomerReview> recentReviews;
  final Map<String, int> deliveryStats;
  final Map<String, double> performanceMetrics;
  final DateTime lastUpdated;

  AnalyticsData({
    required this.deliveryTrends,
    required this.earningsTrends,
    required this.averageRating,
    required this.totalRatings,
    required this.recentReviews,
    required this.deliveryStats,
    required this.performanceMetrics,
    required this.lastUpdated,
  });

  factory AnalyticsData.fromJson(Map<String, dynamic> json) {
    return AnalyticsData(
      deliveryTrends: Map<String, double>.from(json['delivery_trends'] ?? {}),
      earningsTrends: Map<String, double>.from(json['earnings_trends'] ?? {}),
      averageRating: (json['average_rating'] ?? 0).toDouble(),
      totalRatings: json['total_ratings'] ?? 0,
      recentReviews: (json['recent_reviews'] as List? ?? [])
          .map((review) => CustomerReview.fromJson(review))
          .toList(),
      deliveryStats: Map<String, int>.from(json['delivery_stats'] ?? {}),
      performanceMetrics: Map<String, double>.from(json['performance_metrics'] ?? {}),
      lastUpdated: DateTime.parse(json['last_updated'] ?? DateTime.now().toIso8601String()),
    );
  }
}

class CustomerReview {
  final String id;
  final String customerName;
  final double rating;
  final String comment;
  final DateTime createdAt;
  final String orderId;

  CustomerReview({
    required this.id,
    required this.customerName,
    required this.rating,
    required this.comment,
    required this.createdAt,
    required this.orderId,
  });

  factory CustomerReview.fromJson(Map<String, dynamic> json) {
    return CustomerReview(
      id: json['id'],
      customerName: json['customer_name'] ?? 'Anonymous',
      rating: (json['rating'] ?? 0).toDouble(),
      comment: json['comment'] ?? '',
      createdAt: DateTime.parse(json['created_at']),
      orderId: json['order_id'] ?? '',
    );
  }
}

class RiderAnalyticsScreen extends StatefulWidget {
  const RiderAnalyticsScreen({super.key});

  @override
  State<RiderAnalyticsScreen> createState() => _RiderAnalyticsScreenState();
}

class _RiderAnalyticsScreenState extends State<RiderAnalyticsScreen>
    with TickerProviderStateMixin {
  
  late TabController _tabController;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  final ScrollController _scrollController = ScrollController();
  
  AnalyticsData? _analyticsData;
  bool _isLoading = true;
  String? _error;
  String _selectedPeriod = 'week';

  @override
  void initState() {
    super.initState();
    
    _tabController = TabController(length: 3, vsync: this);
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
    
    _loadAnalyticsData();
    _animationController.forward();
    
    LoggerService.info('Rider analytics screen initialized', tag: 'RiderAnalyticsScreen');
  }

  Future<void> _loadAnalyticsData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await ApiService.get('/rider/analytics?period=$_selectedPeriod');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (mounted) {
          setState(() {
            _analyticsData = AnalyticsData.fromJson(data['data']);
            _isLoading = false;
          });
        }
      } else {
        throw Exception('Failed to load analytics: ${response.statusCode}');
      }
    } catch (e) {
      LoggerService.error('Failed to load analytics data', error: e, tag: 'RiderAnalyticsScreen');
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _animationController.dispose();
    _scrollController.dispose();
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
                child: _isLoading
                    ? _buildLoadingState()
                    : _error != null
                        ? _buildErrorState()
                        : Column(
                            children: [
                              _buildPeriodSelector(),
                              _buildTabBar(),
                              Expanded(child: _buildTabBarView()),
                            ],
                          ),
              );
            },
          ),
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: context.colors.ecoBlue,
      foregroundColor: Colors.white,
      title: const Text(
        'Performance Analytics',
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: () => _loadAnalyticsData(),
          tooltip: 'Refresh',
        ),
        IconButton(
          icon: const Icon(Icons.share),
          onPressed: _shareAnalytics,
          tooltip: 'Share',
        ),
      ],
    );
  }

  Widget _buildPeriodSelector() {
    final periods = {
      'week': 'This Week',
      'month': 'This Month',
      'quarter': 'This Quarter',
      'year': 'This Year',
    };
    
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
      child: Row(
        children: periods.entries.map((entry) {
          final isSelected = _selectedPeriod == entry.key;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedPeriod = entry.key;
                });
                _loadAnalyticsData();
              },
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected ? context.colors.ecoBlue : Colors.transparent,
                  borderRadius: AppRadius.radiusMD,
                  border: Border.all(
                    color: isSelected ? context.colors.ecoBlue : context.colors.outline,
                  ),
                ),
                child: Text(
                  entry.value,
                  textAlign: TextAlign.center,
                  style: context.textTheme.titleSmall?.copyWith(
                    color: isSelected ? Colors.white : context.colors.textPrimary,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      decoration: BoxDecoration(
        color: context.colors.surfaceColor,
        border: Border(
          bottom: BorderSide(color: context.colors.outline.withValues(alpha: 0.2)),
        ),
      ),
      child: TabBar(
        controller: _tabController,
        tabs: const [
          Tab(text: 'Overview', icon: Icon(Icons.dashboard, size: 20)),
          Tab(text: 'Performance', icon: Icon(Icons.trending_up, size: 20)),
          Tab(text: 'Reviews', icon: Icon(Icons.star, size: 20)),
        ],
        labelColor: context.colors.ecoBlue,
        unselectedLabelColor: context.colors.textSecondary,
        indicatorColor: context.colors.ecoBlue,
      ),
    );
  }

  Widget _buildTabBarView() {
    return TabBarView(
      controller: _tabController,
      children: [
        _buildOverviewTab(),
        _buildPerformanceTab(),
        _buildReviewsTab(),
      ],
    );
  }

  Widget _buildOverviewTab() {
    if (_analyticsData == null) return const SizedBox.shrink();
    
    return RefreshIndicator(
      onRefresh: _loadAnalyticsData,
      color: context.colors.ecoBlue,
      child: SingleChildScrollView(
        controller: _scrollController,
        padding: AppSpacing.paddingMD,
        child: Column(
          children: [
            _buildRatingOverview(),
            const SizedBox(height: AppSpacing.md),
            _buildDeliveryStats(),
            const SizedBox(height: AppSpacing.md),
            _buildTrendsChart(),
          ],
        ),
      ),
    );
  }

  Widget _buildRatingOverview() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: AppRadius.radiusLG),
      child: Container(
        padding: AppSpacing.paddingLG,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              context.colors.marketOrange,
              context.colors.marketOrange.withValues(alpha: 0.8),
            ],
          ),
          borderRadius: AppRadius.radiusLG,
        ),
        child: Column(
          children: [
            Row(
              children: [
                Icon(
                  Icons.star,
                  color: Colors.white,
                  size: 32,
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Customer Rating',
                        style: context.textTheme.titleMedium?.copyWith(
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                      ),
                      Text(
                        '${_analyticsData!.averageRating.toStringAsFixed(1)} ⭐',
                        style: context.textTheme.headlineMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: AppRadius.radiusMD,
                  ),
                  child: Text(
                    '${_analyticsData!.totalRatings} reviews',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: AppSpacing.lg),
            
            Row(
              children: [
                _buildRatingMetric('Excellent', _getRatingPercentage(5), Icons.sentiment_very_satisfied),
                _buildRatingMetric('Good', _getRatingPercentage(4), Icons.sentiment_satisfied),
                _buildRatingMetric('Average', _getRatingPercentage(3), Icons.sentiment_neutral),
                _buildRatingMetric('Poor', _getRatingPercentage(1, 2), Icons.sentiment_dissatisfied),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRatingMetric(String label, double percentage, IconData icon) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 20),
          const SizedBox(height: 4),
          Text(
            '${percentage.toStringAsFixed(0)}%',
            style: context.textTheme.titleSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: context.textTheme.bodySmall?.copyWith(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 10,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildDeliveryStats() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: AppRadius.radiusLG),
      child: Padding(
        padding: AppSpacing.paddingLG,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Delivery Statistics',
              style: context.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            
            const SizedBox(height: AppSpacing.md),
            
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: AppSpacing.sm,
              mainAxisSpacing: AppSpacing.sm,
              childAspectRatio: 1.5,
              children: [
                _buildStatCard(
                  'Total Deliveries',
                  '${_analyticsData!.deliveryStats['total'] ?? 0}',
                  Icons.local_shipping,
                  context.colors.ecoBlue,
                ),
                _buildStatCard(
                  'On-Time Deliveries',
                  '${_analyticsData!.deliveryStats['on_time'] ?? 0}',
                  Icons.schedule,
                  context.colors.freshGreen,
                ),
                _buildStatCard(
                  'Average Delivery Time',
                  '${_analyticsData!.performanceMetrics['avg_delivery_time']?.toStringAsFixed(0) ?? 0} min',
                  Icons.timer,
                  context.colors.marketOrange,
                ),
                _buildStatCard(
                  'Acceptance Rate',
                  '${(_analyticsData!.performanceMetrics['acceptance_rate'] ?? 0).toStringAsFixed(0)}%',
                  Icons.check_circle,
                  Colors.purple,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: AppSpacing.paddingMD,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: AppRadius.radiusMD,
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 4),
          Text(
            value,
            style: context.textTheme.titleMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          Text(
            title,
            style: context.textTheme.bodySmall?.copyWith(
              color: context.colors.textSecondary,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildTrendsChart() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: AppRadius.radiusLG),
      child: Padding(
        padding: AppSpacing.paddingLG,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Delivery & Earnings Trends',
              style: context.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            
            const SizedBox(height: AppSpacing.md),
            
            // Simple chart representation
            Container(
              height: 200,
              decoration: BoxDecoration(
                color: context.colors.surfaceColor,
                borderRadius: AppRadius.radiusMD,
                border: Border.all(color: context.colors.outline.withValues(alpha: 0.3)),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.trending_up,
                      size: 48,
                      color: context.colors.ecoBlue.withValues(alpha: 0.5),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Trends Chart',
                      style: context.textTheme.titleMedium?.copyWith(
                        color: context.colors.textSecondary,
                      ),
                    ),
                    Text(
                      'Implementation requires chart library',
                      style: context.textTheme.bodySmall?.copyWith(
                        color: context.colors.textSecondary,
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

  Widget _buildPerformanceTab() {
    if (_analyticsData == null) return const SizedBox.shrink();
    
    return SingleChildScrollView(
      padding: AppSpacing.paddingMD,
      child: Column(
        children: [
          _buildPerformanceMetrics(),
          const SizedBox(height: AppSpacing.md),
          _buildImprovementSuggestions(),
        ],
      ),
    );
  }

  Widget _buildPerformanceMetrics() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: AppRadius.radiusLG),
      child: Padding(
        padding: AppSpacing.paddingLG,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Performance Metrics',
              style: context.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            
            const SizedBox(height: AppSpacing.md),
            
            Column(
              children: [
                _buildPerformanceItem(
                  'Acceptance Rate',
                  _analyticsData!.performanceMetrics['acceptance_rate'] ?? 0,
                  95.0,
                  '%',
                  context.colors.freshGreen,
                ),
                _buildPerformanceItem(
                  'On-Time Delivery',
                  _analyticsData!.performanceMetrics['on_time_rate'] ?? 0,
                  90.0,
                  '%',
                  context.colors.ecoBlue,
                ),
                _buildPerformanceItem(
                  'Customer Satisfaction',
                  _analyticsData!.averageRating * 20,
                  96.0,
                  '%',
                  context.colors.marketOrange,
                ),
                _buildPerformanceItem(
                  'Completion Rate',
                  _analyticsData!.performanceMetrics['completion_rate'] ?? 0,
                  98.0,
                  '%',
                  Colors.purple,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPerformanceItem(String title, double value, double target, String unit, Color color) {
    final percentage = (value / target).clamp(0.0, 1.0);
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: context.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '${value.toStringAsFixed(0)}$unit',
                style: context.textTheme.bodyMedium?.copyWith(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          LinearProgressIndicator(
            value: percentage,
            backgroundColor: color.withValues(alpha: 0.2),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
          const SizedBox(height: 4),
          Text(
            'Target: ${target.toStringAsFixed(0)}$unit',
            style: context.textTheme.bodySmall?.copyWith(
              color: context.colors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImprovementSuggestions() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: AppRadius.radiusLG),
      child: Padding(
        padding: AppSpacing.paddingLG,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.lightbulb_outline,
                  color: context.colors.marketOrange,
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  'Improvement Suggestions',
                  style: context.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: context.colors.marketOrange,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: AppSpacing.md),
            
            Column(
              children: [
                '• Maintain consistent communication with customers',
                '• Use GPS navigation for optimal routes',
                '• Handle items with care to ensure quality',
                '• Be punctual for pickup and delivery times',
                '• Keep your vehicle and appearance professional',
              ].map((suggestion) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Icon(
                      Icons.check_circle_outline,
                      size: 16,
                      color: context.colors.freshGreen,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        suggestion.substring(2),
                        style: context.textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
              )).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewsTab() {
    if (_analyticsData == null) return const SizedBox.shrink();
    
    return RefreshIndicator(
      onRefresh: _loadAnalyticsData,
      color: context.colors.ecoBlue,
      child: _analyticsData!.recentReviews.isEmpty
          ? _buildEmptyReviews()
          : ListView.builder(
              padding: AppSpacing.paddingMD,
              itemCount: _analyticsData!.recentReviews.length,
              itemBuilder: (context, index) {
                final review = _analyticsData!.recentReviews[index];
                return _buildReviewCard(review);
              },
            ),
    );
  }

  Widget _buildReviewCard(CustomerReview review) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: AppRadius.radiusLG),
      child: Padding(
        padding: AppSpacing.paddingMD,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: context.colors.marketOrange.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.person,
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
                        review.customerName,
                        style: context.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Row(
                        children: [
                          ...List.generate(5, (index) {
                            return Icon(
                              index < review.rating ? Icons.star : Icons.star_border,
                              color: context.colors.marketOrange,
                              size: 16,
                            );
                          }),
                          const SizedBox(width: 8),
                          Text(
                            review.rating.toStringAsFixed(1),
                            style: context.textTheme.bodySmall?.copyWith(
                              color: context.colors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                Text(
                  _formatDate(review.createdAt),
                  style: context.textTheme.bodySmall?.copyWith(
                    color: context.colors.textSecondary,
                  ),
                ),
              ],
            ),
            
            if (review.comment.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.sm),
              Container(
                padding: AppSpacing.paddingMD,
                decoration: BoxDecoration(
                  color: context.colors.surfaceColor,
                  borderRadius: AppRadius.radiusMD,
                ),
                child: Text(
                  review.comment,
                  style: context.textTheme.bodyMedium,
                ),
              ),
            ],
            
            const SizedBox(height: AppSpacing.sm),
            
            Text(
              'Order #${review.orderId}',
              style: context.textTheme.bodySmall?.copyWith(
                color: context.colors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyReviews() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.star_outline,
            size: 64,
            color: context.colors.textSecondary.withValues(alpha: 0.5),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'No reviews yet',
            style: context.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: context.colors.textSecondary,
            ),
          ),
          Text(
            'Complete deliveries to receive customer feedback',
            style: context.textTheme.bodyMedium?.copyWith(
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
      child: CircularProgressIndicator(),
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
            'Failed to load analytics',
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
            onPressed: _loadAnalyticsData,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  double _getRatingPercentage(int minRating, [int? maxRating]) {
    // Calculate percentage based on actual review data from backend
    if (_analyticsData?.recentReviews.isEmpty ?? true) {
      return 0.0;
    }
    
    maxRating ??= minRating;
    final reviews = _analyticsData!.recentReviews;
    final matchingReviews = reviews.where((review) {
      return review.rating >= minRating && review.rating <= maxRating!;
    }).length;
    
    return (matchingReviews / reviews.length) * 100;
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays > 30) {
      return '${date.day}/${date.month}/${date.year}';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else {
      return 'Recent';
    }
  }

  void _shareAnalytics() {
    // TODO: Implement analytics sharing
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Analytics sharing feature coming soon'),
      ),
    );
  }
} 