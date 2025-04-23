import 'package:flutter/material.dart';

class SplashProvider with ChangeNotifier {
  bool _isVisible = false;
  bool get isVisible => _isVisible;

  void startAnimation(BuildContext context) {
    Future.delayed(Duration(milliseconds: 500), () {
      _isVisible = true;
      notifyListeners(); // Notify UI to update the fade-in effect
    });

    Future.delayed(Duration(seconds: 3), () {
      Navigator.pushReplacementNamed(context, "/home");
    });
  }
}
