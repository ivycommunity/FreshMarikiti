import 'package:flutter/material.dart';

class Passwordprovider extends ChangeNotifier {
  bool _isPasswordVisible = true;
  bool get ispasswordvisisble => _isPasswordVisible;
  void viewPassword() {
    _isPasswordVisible = !_isPasswordVisible;
    notifyListeners();
  }
}
