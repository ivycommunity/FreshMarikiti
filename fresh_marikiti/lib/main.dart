import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:fresh_marikiti/core/providers/auth_provider.dart';
import 'package:fresh_marikiti/core/providers/theme_provider.dart';
import 'package:fresh_marikiti/core/providers/cart_provider.dart';
import 'package:fresh_marikiti/core/providers/product_provider.dart';
import 'package:fresh_marikiti/core/providers/order_provider.dart';
import 'package:fresh_marikiti/core/providers/notification_provider.dart';
import 'package:fresh_marikiti/core/providers/chat_provider.dart';
import 'package:fresh_marikiti/core/providers/location_provider.dart';
import 'package:fresh_marikiti/core/providers/rating_provider.dart';
import 'package:fresh_marikiti/core/services/firebase_setup_service.dart';
import 'package:fresh_marikiti/core/services/storage_service.dart';
import 'package:fresh_marikiti/core/config/theme_extensions.dart';
import 'package:fresh_marikiti/presentation/navigation/app_router.dart';
import 'package:fresh_marikiti/presentation/navigation/route_names.dart';
import 'package:fresh_marikiti/firebase_options.dart';
import 'package:fresh_marikiti/core/services/api_service.dart';
import 'package:fresh_marikiti/core/services/logger_service.dart';
import 'package:fresh_marikiti/core/services/navigation_service.dart';
import 'package:fresh_marikiti/core/config/app_config.dart';
import 'package:fresh_marikiti/core/services/integration_completion_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Set preferred orientations (portrait only for better UX)
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    // Load environment variables
    await dotenv.load(fileName: ".env");
    LoggerService.info('Environment variables loaded successfully',
        tag: 'Main');

    // Initialize core services
    await ApiService.initialize();
    await StorageService.init();

    LoggerService.info('Fresh Marikiti app starting...', tag: 'Main');

    // Initialize Firebase (non-blocking for offline functionality)
    _initializeFirebaseAsync();

    runApp(const FreshMarikitiApp());
  } catch (e) {
    LoggerService.error('Failed to initialize app', error: e, tag: 'Main');
    runApp(ErrorApp(error: e.toString()));
  }
}

/// Initialize Firebase asynchronously without blocking app startup
void _initializeFirebaseAsync() async {
  try {
    // Initialize Firebase
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // Initialize Firebase services
    await FirebaseSetupService.initializeFirebase();

    LoggerService.info('Firebase initialized successfully', tag: 'Main');
    LoggerService.info(
        'All integrations (Firebase + Google Maps) are now configured!',
        tag: 'Main');
  } catch (e) {
    LoggerService.warning(
        'Firebase initialization failed - app will work without push notifications',
        tag: 'Main');
    // App continues to work without Firebase features
  }
}

class FreshMarikitiApp extends StatefulWidget {
  const FreshMarikitiApp({super.key});

  @override
  State<FreshMarikitiApp> createState() => _FreshMarikitiAppState();
}

class _FreshMarikitiAppState extends State<FreshMarikitiApp>
    with WidgetsBindingObserver {
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangePlatformBrightness() {
    // Handle system theme changes
    final themeProvider = context.read<ThemeProvider>();
    if (themeProvider.useSystemTheme) {
      final brightness =
          WidgetsBinding.instance.platformDispatcher.platformBrightness;
      themeProvider.updateFromSystem(brightness);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Core providers - Theme provider first for proper initialization
        ChangeNotifierProvider(
          create: (_) => ThemeProvider(),
        ),
        ChangeNotifierProvider(
          create: (_) => AuthProvider(),
        ),

        // Feature providers
        ChangeNotifierProvider(
          create: (_) => ProductProvider(),
        ),
        ChangeNotifierProvider(
          create: (_) => CartProvider(),
        ),
        ChangeNotifierProvider(
          create: (_) => OrderProvider(),
        ),
        ChangeNotifierProvider(
          create: (_) => NotificationProvider(),
        ),
        // ChangeNotifierProvider(
        //   create: (_) => ChatProvider(),
        // ),
        ChangeNotifierProvider(
          create: (_) => LocationProvider(),
        ),
        // ChangeNotifierProvider(
        //   create: (_) => RatingProvider(),
        // ),
      ],
      child: Builder(
        builder: (context) {
          // Initialize providers after they're created
          if (!_isInitialized) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _initializeProviders(context);
            });
            _isInitialized = true;
          }

          return Consumer<ThemeProvider>(
            builder: (context, themeProvider, child) {
              return AnnotatedRegion<SystemUiOverlayStyle>(
                value: _getSystemUiOverlayStyle(themeProvider),
                child: MaterialApp(
                  title: AppConfig.appName,
                  debugShowCheckedModeBanner: false,

                  // Theme configuration
                  theme: themeProvider.lightTheme,
                  darkTheme: themeProvider.darkTheme,
                  themeMode: themeProvider.themeMode,

                  // Accessibility
                  supportedLocales: const [
                    Locale('en', 'US'), // English
                    Locale('sw', 'KE'), // Swahili for Kenya
                  ],

                  // Navigation
                  navigatorKey: NavigationService.navigatorKey,
                  initialRoute: RouteNames.splash,
                  onGenerateRoute: AppRouter.generateRoute,
                  onUnknownRoute: (settings) => AppRouter.generateRoute(
                    RouteSettings(name: RouteNames.splash),
                  ),

                  // Performance optimizations
                  builder: (context, child) {
                    return MediaQuery(
                      // Prevent font scaling beyond reasonable limits
                      data: MediaQuery.of(context).copyWith(
                        textScaler: MediaQuery.of(context)
                            .textScaler
                            .clamp(minScaleFactor: 0.8, maxScaleFactor: 1.4),
                      ),
                      child: child!,
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }

  /// Get appropriate theme mode based on theme provider settings
  ThemeMode _getThemeMode(ThemeProvider themeProvider) {
    if (themeProvider.useSystemTheme) {
      return ThemeMode.system;
    }
    return themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light;
  }

  /// Get system UI overlay style for status bar and navigation bar
  SystemUiOverlayStyle _getSystemUiOverlayStyle(ThemeProvider themeProvider) {
    final isDark = themeProvider.isDarkMode;

    return SystemUiOverlayStyle(
      // Status bar
      statusBarColor: Colors.transparent,
      statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
      statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,

      // Navigation bar (Android)
      systemNavigationBarColor: isDark ? const Color(0xFF121212) : Colors.white,
      systemNavigationBarIconBrightness:
          isDark ? Brightness.light : Brightness.dark,
      systemNavigationBarDividerColor: Colors.transparent,
    );
  }

  /// Initialize all providers in proper order
  Future<void> _initializeProviders(BuildContext context) async {
    final stopwatch = Stopwatch()..start();

    try {
      LoggerService.info('Initializing providers...', tag: 'Main');

      // Initialize providers that don't depend on others first
      final futures = <Future<void>>[
        context.read<ProductProvider>().initialize(),
        context.read<NotificationProvider>().initialize(),
        context.read<LocationProvider>().initialize(),
      ];

      // Wait for independent providers
      await Future.wait(futures);

      // Initialize providers that might depend on others
      await context.read<CartProvider>().initialize();
      await context.read<ChatProvider>().initialize();
      await context.read<OrderProvider>().initialize();

      // Initialize rating provider with current user (or empty string if not logged in)
      final authProvider = context.read<AuthProvider>();
      final currentUserId = authProvider.user?.id ?? '';
      //await context.read<RatingProvider>().initialize(currentUserId);

      stopwatch.stop();
      LoggerService.info(
          'Providers initialized successfully in ${stopwatch.elapsedMilliseconds}ms',
          tag: 'Main');
    } catch (e) {
      LoggerService.error('Error initializing providers',
          error: e, tag: 'Main');
      // App continues with limited functionality
    }
  }
}

/// Error app with Fresh Marikiti branding
class ErrorApp extends StatelessWidget {
  final String error;

  const ErrorApp({super.key, required this.error});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Fresh Marikiti - Error',
      theme: ThemeData(
        primarySwatch: Colors.green,
        fontFamily: 'Poppins',
      ),
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Colors.grey.shade50,
        appBar: AppBar(
          title: const Text('Fresh Marikiti'),
          backgroundColor: const Color(0xFF2E7D32),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        body: SafeArea(
          child: Padding(
            padding: AppSpacing.paddingLG,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Error icon with Fresh Marikiti colors
                Container(
                  padding: AppSpacing.paddingXL,
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.error_outline_rounded,
                    size: AppIconSizes.xxl,
                    color: Colors.red.shade400,
                  ),
                ),

                const SizedBox(height: AppSpacing.lg),

                // Title
                const Text(
                  'Oops! Something went wrong',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1B5E20),
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: AppSpacing.sm),

                // Subtitle
                const Text(
                  'We\'re having trouble starting Fresh Marikiti',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: AppSpacing.lg),

                // Error details (collapsed by default)
                ExpansionTile(
                  title: const Text(
                    'Technical Details',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  children: [
                    Container(
                      width: double.infinity,
                      padding: AppSpacing.paddingMD,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: AppRadius.radiusMD,
                      ),
                      child: Text(
                        error,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 12,
                          color: Colors.red,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: AppSpacing.xl),

                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => SystemNavigator.pop(),
                        icon: const Icon(Icons.exit_to_app),
                        label: const Text('Exit'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          side: const BorderSide(color: Color(0xFF2E7D32)),
                          foregroundColor: const Color(0xFF2E7D32),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          // Restart app
                          main();
                        },
                        icon: const Icon(Icons.refresh),
                        label: const Text('Retry'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2E7D32),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: AppRadius.radiusMD,
                          ),
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
    );
  }
}
