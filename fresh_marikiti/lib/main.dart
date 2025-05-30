import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:fresh_marikiti/providers/auth_provider.dart';
import 'package:fresh_marikiti/providers/cart_provider.dart';
import 'package:fresh_marikiti/config/theme.dart';
import 'package:fresh_marikiti/config/router.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  await Firebase.initializeApp();
  await _initFirebaseMessaging();
  runApp(const MyApp());
}

Future<void> _initFirebaseMessaging() async {
  FirebaseMessaging messaging = FirebaseMessaging.instance;
  await messaging.requestPermission();
  // Optionally handle foreground/background messages here
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
      ],
      child: Consumer<AuthProvider>(
        builder: (context, authProvider, _) {
          final router = AppRouter(
            user: authProvider.user,
            isAuthenticated: authProvider.isAuthenticated,
          ).router;

          return MaterialApp.router(
        debugShowCheckedModeBanner: false,
        title: 'Fresh Marikiti',
            theme: AppTheme.lightTheme(),
            routerConfig: router,
          );
        },
      ),
    );
  }
}
