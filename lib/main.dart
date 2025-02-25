import 'package:flutter/material.dart';
import 'package:marikiti/Homepage.dart';
import 'package:marikiti/login.dart';
import 'package:marikiti/models/authlogin.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(
  MultiProvider(providers: 
  [

      ChangeNotifierProvider(create: (_)=>MariktiauthProvider()),
  ]
  , 
  child: const Marikiti(),),

    
    
);
}

class Marikiti extends StatelessWidget {
  const Marikiti({super.key});

  @override
  Widget build(BuildContext context) {
    return  MaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
        routes: {
          '/':(context)=>const LoginScreen(), 
           '/home':(context)=>const Homepage(),
        },
        
      
    );
  }
}
