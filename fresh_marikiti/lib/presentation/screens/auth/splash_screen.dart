import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fresh_marikiti/core/providers/auth_provider.dart';
import 'package:fresh_marikiti/core/providers/theme_provider.dart';
import 'package:fresh_marikiti/core/config/theme_extensions.dart';
import 'package:fresh_marikiti/core/services/logger_service.dart';
import 'package:fresh_marikiti/presentation/navigation/route_names.dart';
import 'package:fresh_marikiti/core/services/navigation_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _textController;
  late AnimationController _progressController;
  
  late Animation<double> _logoScale;
  late Animation<double> _logoRotation;
  late Animation<double> _textOpacity;
  late Animation<double> _progressValue;
  late Animation<Offset> _textSlide;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startSplashSequence();
  }

  void _initializeAnimations() {
    // Logo animation controller
    _logoController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    // Text animation controller
    _textController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    // Progress animation controller
    _progressController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    // Logo animations
    _logoScale = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _logoController,
      curve: Curves.elasticOut,
    ));

    _logoRotation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _logoController,
      curve: Curves.easeInOut,
    ));

    // Text animations
    _textOpacity = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _textController,
      curve: Curves.easeIn,
    ));

    _textSlide = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _textController,
      curve: Curves.easeOut,
    ));

    // Progress animation
    _progressValue = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _progressController,
      curve: Curves.easeInOut,
    ));
  }

  Future<void> _startSplashSequence() async {
    try {
      // Start logo animation
      _logoController.forward();
      
      // Wait a bit then start text animation
      await Future.delayed(const Duration(milliseconds: 500));
      _textController.forward();
      
      // Start progress animation
      await Future.delayed(const Duration(milliseconds: 300));
      _progressController.forward();
      
      // Check authentication and navigate
      await _checkAuthAndNavigate();
      
    } catch (e) {
      LoggerService.error('Splash screen error', error: e, tag: 'SplashScreen');
      _navigateToLogin();
    }
  }

  Future<void> _checkAuthAndNavigate() async {
    // Wait for animations to complete
    await Future.delayed(const Duration(milliseconds: 2500));
    
    if (!mounted) return;
    
    final authProvider = context.read<AuthProvider>();
    
    // Check if user is authenticated
    if (authProvider.isAuthenticated && authProvider.user != null) {
      final homeRoute = authProvider.getHomeRoute();
      LoggerService.info('User authenticated, navigating to: $homeRoute', tag: 'SplashScreen');
      _navigateToRoute(homeRoute);
    } else {
      LoggerService.info('User not authenticated, navigating to login', tag: 'SplashScreen');
      _navigateToLogin();
    }
  }

  void _navigateToRoute(String route) {
    if (mounted) {
      NavigationService.pushAndRemoveUntil(route);
    }
  }

  void _navigateToLogin() {
    if (mounted) {
      NavigationService.toLogin();
    }
  }

  @override
  void dispose() {
    _logoController.dispose();
    _textController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return Scaffold(
          backgroundColor: context.colors.surface,
          body: SafeArea(
            child: Container(
              width: double.infinity,
              height: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    context.colors.freshGreen.withOpacity(0.1),
                    context.colors.surface,
                    context.colors.organicGreen.withOpacity(0.05),
                  ],
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Spacer(flex: 2),
                  
                  // Logo Section
                  AnimatedBuilder(
                    animation: _logoController,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _logoScale.value,
                        child: Transform.rotate(
                          angle: _logoRotation.value * 0.1,
                          child: Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              color: context.colors.freshGreen,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: context.colors.freshGreen.withOpacity(0.3),
                                  blurRadius: 20,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.eco,
                              size: 60,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  
                  const SizedBox(height: AppSpacing.xl),
                  
                  // App Name and Tagline
                  AnimatedBuilder(
                    animation: _textController,
                    builder: (context, child) {
                      return SlideTransition(
                        position: _textSlide,
                        child: FadeTransition(
                          opacity: _textOpacity,
                          child: Column(
                            children: [
                              // App Name
                              Text(
                                'Fresh Marikiti',
                                style: context.textTheme.displaySmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: context.colors.freshGreen,
                                  letterSpacing: 1.2,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              
                              const SizedBox(height: AppSpacing.sm),
                              
                              // Tagline
                              Text(
                                'Your Local Market Connector',
                                style: context.textTheme.titleMedium?.copyWith(
                                  color: context.colors.textSecondary,
                                  fontWeight: FontWeight.w500,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              
                              const SizedBox(height: AppSpacing.sm),
                              
                              // Subtitle
                              Padding(
                                padding: AppSpacing.horizontalLG,
                                child: Text(
                                  'Connecting communities to fresh, local produce through smart marketplace solutions',
                                  style: context.textTheme.bodyMedium?.copyWith(
                                    color: context.colors.textSecondary,
                                    height: 1.4,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                  
                  const Spacer(flex: 2),
                  
                  // Loading Progress
                  AnimatedBuilder(
                    animation: _progressController,
                    builder: (context, child) {
                      return Column(
                        children: [
                          // Progress Bar
                          Container(
                            width: 200,
                            height: 4,
                            decoration: BoxDecoration(
                              color: context.colors.surfaceColor.withOpacity(0.3),
                              borderRadius: AppRadius.radiusPill,
                            ),
                            child: FractionallySizedBox(
                              alignment: Alignment.centerLeft,
                              widthFactor: _progressValue.value,
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      context.colors.freshGreen,
                                      context.colors.organicGreen,
                                    ],
                                  ),
                                  borderRadius: AppRadius.radiusPill,
                                ),
                              ),
                            ),
                          ),
                          
                          const SizedBox(height: AppSpacing.md),
                          
                          // Loading Text
                          FadeTransition(
                            opacity: _textOpacity,
                            child: Text(
                              'Initializing Fresh Marikiti...',
                              style: context.textTheme.bodySmall?.copyWith(
                                color: context.colors.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  
                  const SizedBox(height: AppSpacing.xxl),
                  
                  // Version and Copyright
                  FadeTransition(
                    opacity: _textOpacity,
                    child: Column(
                      children: [
                        Text(
                          'Version 1.0.0',
                          style: context.textTheme.bodySmall?.copyWith(
                            color: context.colors.textSecondary.withOpacity(0.7),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          '© 2024 Fresh Marikiti. All rights reserved.',
                          style: context.textTheme.bodySmall?.copyWith(
                            color: context.colors.textSecondary.withOpacity(0.5),
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: AppSpacing.lg),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
} 