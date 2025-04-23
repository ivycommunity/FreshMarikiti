import 'package:flutter/material.dart';
import 'package:marikiti/core/constants/providers/splash_provider.dart';
import 'package:provider/provider.dart';

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => Provider.of<SplashProvider>(context, listen: false)
        .startAnimation(context));
  }

  @override
  Widget build(BuildContext context) {
    final splashProvider = Provider.of<SplashProvider>(context);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // **Animated Logo**
            AnimatedOpacity(
              duration: Duration(seconds: 2),
              opacity: splashProvider.isVisible ? 1.0 : 0.0,
              child: Image.asset(
                "assets/logo.png", // ✅ Make sure the path is correct
                width: 200,
                height: 200,
              ),
            ),
            SizedBox(height: 20),

            // **Slogan Text**
            Text(
              "From city to city, trust Marikiti",
              style: TextStyle(
                fontSize: 16,
                fontStyle: FontStyle.italic,
                fontWeight: FontWeight.bold,
                color: Colors.green[800],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
