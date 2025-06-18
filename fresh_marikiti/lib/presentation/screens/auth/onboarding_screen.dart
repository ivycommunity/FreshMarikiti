import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fresh_marikiti/core/providers/theme_provider.dart';
import 'package:fresh_marikiti/core/config/theme_extensions.dart';
import 'package:fresh_marikiti/core/services/logger_service.dart';
import 'package:fresh_marikiti/presentation/navigation/route_names.dart';
import 'package:fresh_marikiti/core/services/navigation_service.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final List<OnboardingPage> _pages = [
    OnboardingPage(
      title: 'Connect to Fresh Markets',
      subtitle: 'Discover local vendors and fresh produce in your area',
      description: 'Browse products from verified local vendors and markets. Get access to the freshest fruits, vegetables, and local specialties delivered to your doorstep.',
      icon: Icons.store,
      color: const Color(0xFF2E7D32), // Fresh Green
      illustration: 'market',
    ),
    OnboardingPage(
      title: 'Smart Connector System',
      subtitle: 'Our unique connector handles your shopping',
      description: 'Personal shoppers (Connectors) visit markets for you, ensuring quality selection and handling vendor negotiations. No more crowded markets!',
      icon: Icons.person_search,
      color: const Color(0xFF388E3C), // Organic Green
      illustration: 'connector',
    ),
    OnboardingPage(
      title: 'Reliable Delivery',
      subtitle: 'Fast delivery by trusted riders',
      description: 'Professional riders deliver your fresh produce quickly and safely. Track your order in real-time from market to your door.',
      icon: Icons.delivery_dining,
      color: const Color(0xFFFF9800), // Market Orange
      illustration: 'delivery',
    ),
    OnboardingPage(
      title: 'Sustainable Impact',
      subtitle: 'Supporting local communities & environment',
      description: 'Reduce food waste, support local farmers, and contribute to sustainable communities. Track your environmental impact with every order.',
      icon: Icons.eco,
      color: const Color(0xFF4CAF50), // Eco Blue (using green for eco)
      illustration: 'sustainability',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    LoggerService.info('Onboarding screen initialized', tag: 'OnboardingScreen');
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    _animationController.forward();
  }

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: AppDurations.medium,
        curve: Curves.easeInOut,
      );
    } else {
      _navigateToAuth();
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: AppDurations.medium,
        curve: Curves.easeInOut,
      );
    }
  }

  void _skipOnboarding() {
    LoggerService.info('User skipped onboarding', tag: 'OnboardingScreen');
    _navigateToAuth();
  }

  void _navigateToAuth() {
    NavigationService.toLogin();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return Scaffold(
          backgroundColor: context.colors.surface,
          body: SafeArea(
            child: Column(
              children: [
                // Top Navigation
                Padding(
                  padding: AppSpacing.paddingMD,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Back button (only show if not first page)
                      if (_currentPage > 0)
                        IconButton(
                          onPressed: _previousPage,
                          icon: Icon(
                            Icons.arrow_back_ios,
                            color: context.colors.textSecondary,
                          ),
                        )
                      else
                        const SizedBox(width: 48),

                      // Page indicator
                      Row(
                        children: List.generate(
                          _pages.length,
                          (index) => Container(
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            width: _currentPage == index ? 24 : 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: _currentPage == index
                                  ? _pages[_currentPage].color
                                  : context.colors.textSecondary.withOpacity(0.3),
                              borderRadius: AppRadius.radiusPill,
                            ),
                          ),
                        ),
                      ),

                      // Skip button
                      TextButton(
                        onPressed: _skipOnboarding,
                        child: Text(
                          'Skip',
                          style: context.textTheme.bodyMedium?.copyWith(
                            color: context.colors.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Page Content
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    onPageChanged: (index) {
                      setState(() {
                        _currentPage = index;
                      });
                      _animationController.reset();
                      _animationController.forward();
                    },
                    itemCount: _pages.length,
                    itemBuilder: (context, index) {
                      return FadeTransition(
                        opacity: _fadeAnimation,
                        child: SlideTransition(
                          position: _slideAnimation,
                          child: _buildPageContent(_pages[index]),
                        ),
                      );
                    },
                  ),
                ),

                // Bottom Navigation
                Padding(
                  padding: AppSpacing.paddingLG,
                  child: Row(
                    children: [
                      // Previous button (invisible for spacing)
                      const SizedBox(width: 100),

                      // Next/Get Started button
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _nextPage,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _pages[_currentPage].color,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: AppRadius.radiusLG,
                            ),
                            elevation: 4,
                          ),
                          child: Text(
                            _currentPage == _pages.length - 1
                                ? 'Get Started'
                                : 'Next',
                            style: context.textTheme.labelLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(width: 100),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPageContent(OnboardingPage page) {
    return Padding(
      padding: AppSpacing.horizontalLG,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Illustration
          Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              color: page.color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              page.icon,
              size: 80,
              color: page.color,
            ),
          ),

          const SizedBox(height: AppSpacing.xl),

          // Title
          Text(
            page.title,
            style: context.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: page.color,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: AppSpacing.md),

          // Subtitle
          Text(
            page.subtitle,
            style: context.textTheme.titleMedium?.copyWith(
              color: context.colors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: AppSpacing.lg),

          // Description
          Text(
            page.description,
            style: context.textTheme.bodyLarge?.copyWith(
              color: context.colors.textSecondary,
              height: 1.6,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: AppSpacing.xl),

          // Feature highlights for specific pages
          if (_currentPage == 1) _buildConnectorFeatures(),
          if (_currentPage == 2) _buildDeliveryFeatures(),
          if (_currentPage == 3) _buildSustainabilityFeatures(),
        ],
      ),
    );
  }

  Widget _buildConnectorFeatures() {
    return Container(
      padding: AppSpacing.paddingMD,
      decoration: BoxDecoration(
        color: context.colors.organicGreen.withOpacity(0.1),
        borderRadius: AppRadius.radiusLG,
        border: Border.all(
          color: context.colors.organicGreen.withOpacity(0.3),
        ),
      ),
      child: Column(
        children: [
          _buildFeatureItem(
            Icons.shopping_basket,
            'Personal Shopping',
            'Expert selection of fresh produce',
          ),
          const SizedBox(height: AppSpacing.sm),
          _buildFeatureItem(
            Icons.chat,
            'Real-time Updates',
            'Stay informed throughout the process',
          ),
          const SizedBox(height: AppSpacing.sm),
          _buildFeatureItem(
            Icons.verified,
            'Quality Assured',
            'Every item checked for freshness',
          ),
        ],
      ),
    );
  }

  Widget _buildDeliveryFeatures() {
    return Container(
      padding: AppSpacing.paddingMD,
      decoration: BoxDecoration(
        color: context.colors.marketOrange.withOpacity(0.1),
        borderRadius: AppRadius.radiusLG,
        border: Border.all(
          color: context.colors.marketOrange.withOpacity(0.3),
        ),
      ),
      child: Column(
        children: [
          _buildFeatureItem(
            Icons.schedule,
            'Fast Delivery',
            'Within 2 hours of ordering',
          ),
          const SizedBox(height: AppSpacing.sm),
          _buildFeatureItem(
            Icons.gps_fixed,
            'Live Tracking',
            'Know exactly where your order is',
          ),
          const SizedBox(height: AppSpacing.sm),
          _buildFeatureItem(
            Icons.local_shipping,
            'Safe Handling',
            'Temperature-controlled delivery',
          ),
        ],
      ),
    );
  }

  Widget _buildSustainabilityFeatures() {
    return Container(
      padding: AppSpacing.paddingMD,
      decoration: BoxDecoration(
        color: context.colors.freshGreen.withOpacity(0.1),
        borderRadius: AppRadius.radiusLG,
        border: Border.all(
          color: context.colors.freshGreen.withOpacity(0.3),
        ),
      ),
      child: Column(
        children: [
          _buildFeatureItem(
            Icons.recycling,
            'Waste Reduction',
            'Track and minimize food waste',
          ),
          const SizedBox(height: AppSpacing.sm),
          _buildFeatureItem(
            Icons.favorite,
            'Support Local',
            'Directly support local farmers',
          ),
          const SizedBox(height: AppSpacing.sm),
          _buildFeatureItem(
            Icons.eco,
            'Carbon Neutral',
            'Eco-friendly delivery options',
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureItem(IconData icon, String title, String description) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: context.colors.surface,
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            size: 20,
            color: _pages[_currentPage].color,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: context.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: context.colors.textPrimary,
                ),
              ),
              Text(
                description,
                style: context.textTheme.bodySmall?.copyWith(
                  color: context.colors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class OnboardingPage {
  final String title;
  final String subtitle;
  final String description;
  final IconData icon;
  final Color color;
  final String illustration;

  const OnboardingPage({
    required this.title,
    required this.subtitle,
    required this.description,
    required this.icon,
    required this.color,
    required this.illustration,
  });
} 