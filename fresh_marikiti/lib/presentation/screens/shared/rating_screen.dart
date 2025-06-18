import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fresh_marikiti/core/providers/theme_provider.dart';
import 'package:fresh_marikiti/core/config/theme_extensions.dart';
import 'package:fresh_marikiti/core/services/logger_service.dart';

class RatingScreen extends StatefulWidget {
  final String? targetId; // Order ID, User ID, Product ID
  final String ratingType; // 'order', 'connector', 'product', 'vendor'
  final Map<String, dynamic>? targetData;

  const RatingScreen({
    super.key,
    this.targetId,
    required this.ratingType,
    this.targetData,
  });

  @override
  State<RatingScreen> createState() => _RatingScreenState();
}

class _RatingScreenState extends State<RatingScreen>
    with TickerProviderStateMixin {
  late AnimationController _starAnimationController;
  late AnimationController _submitAnimationController;
  late List<Animation<double>> _starAnimations;
  late Animation<double> _submitAnimation;
  
  int _selectedRating = 0;
  final _commentController = TextEditingController();
  final Map<String, int> _categoryRatings = {};
  List<String> _selectedTags = [];
  bool _isSubmitting = false;
  bool _isAnonymous = false;

  @override
  void initState() {
    super.initState();
    
    _starAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _submitAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    // Create staggered star animations
    _starAnimations = List.generate(5, (index) {
      return Tween<double>(
        begin: 0.0,
        end: 1.0,
      ).animate(CurvedAnimation(
        parent: _starAnimationController,
        curve: Interval(
          index * 0.1,
          (index * 0.1) + 0.5,
          curve: Curves.elasticOut,
        ),
      ));
    });
    
    _submitAnimation = Tween<double>(
      begin: 1.0,
      end: 0.9,
    ).animate(CurvedAnimation(
      parent: _submitAnimationController,
      curve: Curves.easeInOut,
    ));
    
    _starAnimationController.forward();
    _initializeCategoryRatings();
    LoggerService.info('Rating screen initialized for ${widget.ratingType}', tag: 'RatingScreen');
  }

  void _initializeCategoryRatings() {
    final categories = _getRatingCategories();
    for (final category in categories) {
      _categoryRatings[category] = 0;
    }
  }

  @override
  void dispose() {
    _starAnimationController.dispose();
    _submitAnimationController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return Scaffold(
          backgroundColor: context.colors.surface,
          appBar: _buildAppBar(context),
          body: SingleChildScrollView(
            padding: AppSpacing.paddingLG,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Rating target info
                _buildTargetInfo(),
                
                const SizedBox(height: AppSpacing.xl),
                
                // Overall rating
                _buildOverallRating(),
                
                const SizedBox(height: AppSpacing.xl),
                
                // Category ratings
                if (_getRatingCategories().isNotEmpty) ...[
                  _buildCategoryRatings(),
                  const SizedBox(height: AppSpacing.xl),
                ],
                
                // Quick tags
                _buildQuickTags(),
                
                const SizedBox(height: AppSpacing.xl),
                
                // Comment section
                _buildCommentSection(),
                
                const SizedBox(height: AppSpacing.xl),
                
                // Privacy options
                _buildPrivacyOptions(),
                
                const SizedBox(height: AppSpacing.xl),
                
                // Submit button
                _buildSubmitButton(),
              ],
            ),
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
        'Rate ${_getRatingTypeText()}',
        style: context.textTheme.titleLarge?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text(
            'Skip',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTargetInfo() {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: AppRadius.radiusLG),
      child: Padding(
        padding: AppSpacing.paddingLG,
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: context.colors.freshGreen.withOpacity(0.2),
                borderRadius: AppRadius.radiusMD,
              ),
              child: Icon(
                _getTargetIcon(),
                color: context.colors.freshGreen,
                size: 30,
              ),
            ),
            const SizedBox(width: AppSpacing.lg),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _getTargetTitle(),
                    style: context.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _getTargetSubtitle(),
                    style: context.textTheme.bodyMedium?.copyWith(
                      color: context.colors.textSecondary,
                    ),
                  ),
                  if (widget.targetData?['date'] != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      widget.targetData!['date'] as String,
                      style: context.textTheme.bodySmall?.copyWith(
                        color: context.colors.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverallRating() {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: AppRadius.radiusLG),
      child: Padding(
        padding: AppSpacing.paddingXL,
        child: Column(
          children: [
            Text(
              'How was your experience?',
              style: context.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: context.colors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.lg),
            
            // Star rating
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                return AnimatedBuilder(
                  animation: _starAnimations[index],
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _starAnimations[index].value,
                      child: GestureDetector(
                        onTap: () => _setRating(index + 1),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          child: Icon(
                            index < _selectedRating ? Icons.star : Icons.star_border,
                            color: index < _selectedRating 
                                ? _getStarColor(index + 1)
                                : context.colors.textSecondary,
                            size: 40,
                          ),
                        ),
                      ),
                    );
                  },
                );
              }),
            ),
            
            const SizedBox(height: AppSpacing.sm),
            
            // Rating description
            if (_selectedRating > 0)
              Text(
                _getRatingDescription(_selectedRating),
                style: context.textTheme.bodyLarge?.copyWith(
                  color: _getStarColor(_selectedRating),
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryRatings() {
    final categories = _getRatingCategories();
    
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: AppRadius.radiusLG),
      child: Padding(
        padding: AppSpacing.paddingLG,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Rate specific aspects',
              style: context.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: context.colors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            
            ...categories.map((category) => _buildCategoryRatingRow(category)),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryRatingRow(String category) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              category,
              style: context.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: List.generate(5, (index) {
                return GestureDetector(
                  onTap: () => _setCategoryRating(category, index + 1),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    child: Icon(
                      index < (_categoryRatings[category] ?? 0) 
                          ? Icons.star 
                          : Icons.star_border,
                      color: index < (_categoryRatings[category] ?? 0)
                          ? context.colors.marketOrange
                          : context.colors.textSecondary,
                      size: 20,
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickTags() {
    final tags = _getQuickTags();
    
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: AppRadius.radiusLG),
      child: Padding(
        padding: AppSpacing.paddingLG,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quick feedback',
              style: context.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: context.colors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Select what applies (optional)',
              style: context.textTheme.bodySmall?.copyWith(
                color: context.colors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: tags.map((tag) => _buildTagChip(tag)).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTagChip(String tag) {
    final isSelected = _selectedTags.contains(tag);
    
    return GestureDetector(
      onTap: () => _toggleTag(tag),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected 
              ? context.colors.freshGreen
              : context.colors.surfaceColor,
          borderRadius: AppRadius.radiusLG,
          border: Border.all(
            color: isSelected 
                ? context.colors.freshGreen 
                : context.colors.textSecondary.withOpacity(0.3),
          ),
        ),
        child: Text(
          tag,
          style: context.textTheme.bodySmall?.copyWith(
            color: isSelected ? Colors.white : context.colors.textPrimary,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildCommentSection() {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: AppRadius.radiusLG),
      child: Padding(
        padding: AppSpacing.paddingLG,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Additional comments',
              style: context.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: context.colors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Share more details about your experience (optional)',
              style: context.textTheme.bodySmall?.copyWith(
                color: context.colors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            
            TextField(
              controller: _commentController,
              maxLines: 4,
              maxLength: 500,
              decoration: InputDecoration(
                hintText: _getCommentHint(),
                border: OutlineInputBorder(
                  borderRadius: AppRadius.radiusMD,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: AppRadius.radiusMD,
                  borderSide: BorderSide(color: context.colors.freshGreen),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrivacyOptions() {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: AppRadius.radiusLG),
      child: Padding(
        padding: AppSpacing.paddingLG,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Privacy',
              style: context.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: context.colors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            
            Row(
              children: [
                Checkbox(
                  value: _isAnonymous,
                  onChanged: (value) {
                    setState(() {
                      _isAnonymous = value ?? false;
                    });
                  },
                  activeColor: context.colors.freshGreen,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    'Submit this review anonymously',
                    style: context.textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: AppSpacing.sm),
            
            Text(
              'Your review will help improve the Fresh Marikiti experience for everyone.',
              style: context.textTheme.bodySmall?.copyWith(
                color: context.colors.textSecondary,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    final canSubmit = _selectedRating > 0;
    
    return AnimatedBuilder(
      animation: _submitAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _submitAnimation.value,
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: canSubmit && !_isSubmitting ? _submitRating : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: context.colors.freshGreen,
                foregroundColor: Colors.white,
                disabledBackgroundColor: context.colors.textSecondary.withOpacity(0.3),
                shape: RoundedRectangleBorder(borderRadius: AppRadius.radiusMD),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Text(
                      'Submit Review',
                      style: context.textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
        );
      },
    );
  }

  // Helper methods
  String _getRatingTypeText() {
    switch (widget.ratingType) {
      case 'order':
        return 'Order';
      case 'connector':
        return 'Connector';
      case 'product':
        return 'Product';
      case 'vendor':
        return 'Vendor';
      default:
        return 'Experience';
    }
  }

  IconData _getTargetIcon() {
    switch (widget.ratingType) {
      case 'order':
        return Icons.shopping_bag;
      case 'connector':
        return Icons.person;
      case 'product':
        return Icons.inventory;
      case 'vendor':
        return Icons.store;
      default:
        return Icons.star;
    }
  }

  String _getTargetTitle() {
    switch (widget.ratingType) {
      case 'order':
        return 'Order #${widget.targetId?.substring(0, 8) ?? 'Unknown'}';
      case 'connector':
        return widget.targetData?['name'] ?? 'Connector';
      case 'product':
        return widget.targetData?['name'] ?? 'Product';
      case 'vendor':
        return widget.targetData?['name'] ?? 'Vendor';
      default:
        return 'Experience';
    }
  }

  String _getTargetSubtitle() {
    switch (widget.ratingType) {
      case 'order':
        return '${widget.targetData?['itemCount'] ?? 0} items • Delivered';
      case 'connector':
        return widget.targetData?['location'] ?? 'Local Connector';
      case 'product':
        return widget.targetData?['category'] ?? 'Product';
      case 'vendor':
        return widget.targetData?['location'] ?? 'Vendor';
      default:
        return 'Share your feedback';
    }
  }

  List<String> _getRatingCategories() {
    switch (widget.ratingType) {
      case 'order':
        return ['Delivery Speed', 'Product Quality', 'Communication', 'Value for Money'];
      case 'connector':
        return ['Professionalism', 'Communication', 'Timeliness', 'Product Knowledge'];
      case 'product':
        return ['Quality', 'Freshness', 'Value', 'Packaging'];
      case 'vendor':
        return ['Product Quality', 'Service', 'Pricing', 'Reliability'];
      default:
        return [];
    }
  }

  List<String> _getQuickTags() {
    switch (widget.ratingType) {
      case 'order':
        return [
          'Fast delivery',
          'Fresh products',
          'Good packaging',
          'Helpful connector',
          'Good value',
          'Will order again',
          'Late delivery',
          'Poor quality',
          'Missing items',
        ];
      case 'connector':
        return [
          'Professional',
          'Friendly',
          'On time',
          'Knowledgeable',
          'Responsive',
          'Helpful',
          'Unreliable',
          'Poor communication',
          'Late',
        ];
      case 'product':
        return [
          'Fresh',
          'High quality',
          'Good value',
          'Well packaged',
          'As described',
          'Organic',
          'Poor quality',
          'Overpriced',
          'Not fresh',
        ];
      case 'vendor':
        return [
          'Quality products',
          'Fair prices',
          'Good service',
          'Reliable',
          'Fresh stock',
          'Friendly',
          'Expensive',
          'Poor quality',
          'Unreliable',
        ];
      default:
        return ['Great', 'Good', 'Average', 'Poor', 'Excellent'];
    }
  }

  String _getCommentHint() {
    switch (widget.ratingType) {
      case 'order':
        return 'How was your overall order experience? Any specific feedback about the products or delivery?';
      case 'connector':
        return 'Share your experience with this connector. What did they do well or what could be improved?';
      case 'product':
        return 'Tell others about this product. Was it fresh? Good quality? Worth the price?';
      case 'vendor':
        return 'How was your experience with this vendor? Would you recommend them to others?';
      default:
        return 'Share your feedback...';
    }
  }

  Color _getStarColor(int rating) {
    if (rating <= 2) return Colors.red;
    if (rating == 3) return context.colors.marketOrange;
    return context.colors.freshGreen;
  }

  String _getRatingDescription(int rating) {
    switch (rating) {
      case 1:
        return 'Very Poor';
      case 2:
        return 'Poor';
      case 3:
        return 'Average';
      case 4:
        return 'Good';
      case 5:
        return 'Excellent';
      default:
        return '';
    }
  }

  void _setRating(int rating) {
    setState(() {
      _selectedRating = rating;
    });
    
    // Trigger haptic feedback
    // HapticFeedback.lightImpact();
  }

  void _setCategoryRating(String category, int rating) {
    setState(() {
      _categoryRatings[category] = rating;
    });
  }

  void _toggleTag(String tag) {
    setState(() {
      if (_selectedTags.contains(tag)) {
        _selectedTags.remove(tag);
      } else {
        _selectedTags.add(tag);
      }
    });
  }

  void _submitRating() async {
    if (_selectedRating == 0) return;
    
    setState(() {
      _isSubmitting = true;
    });
    
    _submitAnimationController.forward().then((_) {
      _submitAnimationController.reverse();
    });
    
    // Simulate submission
    await Future.delayed(const Duration(seconds: 2));
    
    if (mounted) {
      setState(() {
        _isSubmitting = false;
      });
      
      // Show success dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => _buildSuccessDialog(),
      );
    }
  }

  Widget _buildSuccessDialog() {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: AppRadius.radiusLG),
      child: Padding(
        padding: AppSpacing.paddingXL,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: context.colors.freshGreen,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check,
                color: Colors.white,
                size: 40,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Thank you!',
              style: context.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: context.colors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Your review has been submitted successfully',
              style: context.textTheme.bodyLarge?.copyWith(
                color: context.colors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xl),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context); // Close dialog
                  Navigator.pop(context, {
                    'rating': _selectedRating,
                    'categoryRatings': _categoryRatings,
                    'tags': _selectedTags,
                    'comment': _commentController.text,
                    'isAnonymous': _isAnonymous,
                  }); // Close rating screen
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: context.colors.freshGreen,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: AppRadius.radiusMD),
                ),
                child: const Text('Done'),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 