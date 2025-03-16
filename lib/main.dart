import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'package:marikiti/Homepage.dart';
import 'package:marikiti/core/constants/View/auth/signup.dart';
import 'package:marikiti/core/constants/View/auth/user_page.dart';
import 'package:marikiti/core/constants/providers/Checkoutprovider.dart';
import 'package:marikiti/core/constants/providers/Subscriptionprovider.dart';
import 'package:marikiti/core/constants/providers/Themeprovders.dart';
import 'package:marikiti/core/constants/providers/itemprovider.dart';
import 'package:marikiti/core/constants/providers/passwordprovider.dart';
import 'package:marikiti/core/constants/providers/signup_provider.dart';
import 'package:marikiti/firebase_options.dart';
import 'package:marikiti/models/cartmodel.dart';

import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Load environment variablesF

  //await dotenv.load(fileName: ".env");
  /*await FlutterMpesaSTK(
    MPESA_CONSUNMER_KEY, _consumerSecret, _stkPassword, _shortCode, _callbackURL, defaultMessage);
*/
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => Passwordprovider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => CheckoutProvider()),
        ChangeNotifierProvider(create: (_)=>Subscriptionprovider()),
        ChangeNotifierProvider(create: (_)=>ItemProvider(),),
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
      initialRoute: '/home',
      routes: {
        '/': (context) => SignUpScreen(),
        '/home': (context) => HomePage(),
      },
    );
  }
}
