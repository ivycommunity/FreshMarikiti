import 'package:flutter/material.dart';

class MariktiauthProvider extends ChangeNotifier {
  String? _email;
  String? _password;
  bool _isLoading = false;

  String? get email => _email;
  String? get password => _password;
  bool get isLoading => _isLoading;

  void setEmail(String value) {
    _email = value;
    notifyListeners();
  }

  void setPassword(String value) {
    _password = value;
    notifyListeners();
  }

  Future<void> login(BuildContext context) async {
    if (_email == null || _email!.isEmpty || _password == null || _password!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter email and password")),
      );
      return;
    }

    _isLoading = true;
    notifyListeners();

    // Simulate API call delay
    await Future.delayed(const Duration(seconds: 2));

    _isLoading = false;
    notifyListeners();

    // Navigate to Homepage after login
    Navigator.pushReplacementNamed(context, '/home');
  }
}
