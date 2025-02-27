import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:marikiti/Homepage.dart';
import 'package:marikiti/core/constants/View/auth/signup.dart';
import 'package:marikiti/core/constants/providers/google_sign_in_provider.dart';
import 'package:marikiti/core/constants/providers/passwordprovider.dart';
import 'package:marikiti/core/constants/providers/signup_%7F%7Fprovider.dart';
import 'package:marikiti/firebase_options.dart';

import 'package:provider/provider.dart';

void main() async{
  WidgetsFlutterBinding.ensureInitialized();
    await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
         
    );
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create:(_)=>GoogleSignInProvider()),
         ChangeNotifierProvider(create: (_)=>Passwordprovider()),
      ],
      child: const Marikiti(),
    ),
  );
}

class Marikiti extends StatelessWidget {
  const Marikiti({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      routes: {
        '/': (context) =>  SignUpScreen(),
        '/home': (context) => const Homepage(),
      },
    );
  }
}
