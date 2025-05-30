import 'package:flutter/material.dart';
import 'package:fresh_marikiti/models/user.dart';
import 'package:fresh_marikiti/services/auth_service.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  User? _user;
  bool _isLoading = true;
  String? _error;

  User? get user => _user;
  bool get isAuthenticated => _user != null;
  bool get isLoading => _isLoading;
  String? get error => _error;

  AuthProvider() {
    loadUser();
  }

  Future<void> loadUser() async {
    _isLoading = true;
    notifyListeners();

    try {
      final token = await _authService.getToken();
      if (token != null) {
        final isValid = await _authService.verifyToken(token);
        if (isValid) {
          _user = await _authService.getStoredUser();
        } else {
          await _authService.logout();
        }
      }
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _authService.login(email, password);
      if (result['success']) {
        _user = result['user'];
        _error = null;
        notifyListeners();
        // Register FCM token for vendor roles
        if (_user != null && (_user!.role == UserRole.vendor || _user!.role == UserRole.vendorAdmin)) {
          await _registerFcmToken(_user!.id);
        }
        return true;
      } else {
        _error = result['message'];
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _registerFcmToken(String userId) async {
    try {
      final fcmToken = await FirebaseMessaging.instance.getToken();
      if (fcmToken != null) {
        final baseUrl = dotenv.env['API_BASE_URL'] ?? dotenv.env['API_URL'] ?? '';
        final url = Uri.parse('$baseUrl/users/$userId/fcm-token');
        await http.post(
          url,
          headers: {'Content-Type': 'application/json'},
          body: '{"fcmToken": "$fcmToken"}',
        );
      }
    } catch (e) {
      // Optionally log or handle error
    }
  }

  Future<bool> registerCustomer(Map<String, dynamic> userData) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _authService.registerCustomer(userData);
      if (result['success']) {
        _user = result['user'];
        _error = null;
        notifyListeners();
        return true;
      } else {
        _error = result['message'];
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();

    await _authService.logout();
    _user = null;
    _isLoading = false;
    notifyListeners();
  }

  void clearError() {
    _error = null;
        notifyListeners();
  }
}