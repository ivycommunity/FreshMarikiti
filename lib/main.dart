import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:marikiti/Widgets/splash_screen.dart';
import 'package:marikiti/core/constants/providers/product_provider.dart';
import 'package:marikiti/core/constants/providers/splash_provider.dart';

import 'package:marikiti/homepage.dart';
import 'package:marikiti/core/constants/View/auth/signup.dart';
import 'package:marikiti/core/constants/View/auth/user_page.dart';
import 'package:marikiti/core/constants/providers/Checkoutprovider.dart';
import 'package:marikiti/core/constants/providers/Subscriptionprovider.dart';
import 'package:marikiti/core/constants/providers/theme_provider.dart';
import 'package:marikiti/core/constants/providers/itemprovider.dart';
import 'package:marikiti/core/constants/providers/orderprovider.dart';
import 'package:marikiti/core/constants/providers/passwordprovider.dart';
import 'package:marikiti/core/constants/providers/user_provider.dart';
import 'package:marikiti/models/cartmodel.dart';

import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Load environment variablesF

  //await dotenv.load(fileName: ".env");
  /*await FlutterMpesaSTK(
    MPESA_CONSUNMER_KEY, _consumerSecret, _stkPassword, _shortCode, _callbackURL, defaultMessage);
*/

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => Passwordprovider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => CheckoutProvider()),
        ChangeNotifierProvider(create: (_) => Subscriptionprovider()),
        ChangeNotifierProvider(create: (_) => OrderProvider()),
        ChangeNotifierProvider(create: (_) => ProductProvider()),
        ChangeNotifierProvider(
          create: (_) => ItemProvider(),
        ),
        ChangeNotifierProvider(create: (_) => SplashProvider()),
      ],
      child: const Marikiti(),
    ),
  );
}

class Marikiti extends StatelessWidget {
  const Marikiti({super.key});

  @override
  Widget build(BuildContext context) {
    final themeprovider = Provider.of<ThemeProvider>(context);
    return MaterialApp(
      supportedLocales: const [
        Locale('en', ''),
        Locale('sw', ''),
      ],
      localizationsDelegates: const[
        
          
      ],
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      themeMode: themeprovider.themeMode,
      debugShowCheckedModeBanner: false,
      initialRoute: '/splash_screen',
      routes: {
        '/': (context) => SignUpScreen(),
        '/home': (context) => HomePage(),
        '/splash_screen': (context) => SplashScreen()
      },
    );
  }
}
