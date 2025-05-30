import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:fresh_marikiti/models/user.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AuthService {
  static const storage = FlutterSecureStorage();
  static const String _tokenKey = 'auth_token';
  static const String _userKey = 'user_data';
  
  final String baseUrl = dotenv.env['API_URL'] ?? 'http://localhost:5000/api';

  // Login user
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': email,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        await _saveAuthData(data['token'], data['user']);
        return {'success': true, 'user': User.fromJson(data['user'])};
      } else {
        final error = json.decode(response.body);
        return {'success': false, 'message': error['message'] ?? 'Login failed'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error occurred'};
    }
  }

  // Register customer
  Future<Map<String, dynamic>> registerCustomer(Map<String, dynamic> userData) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(userData),
      );

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        await _saveAuthData(data['token'], data['user']);
        return {'success': true, 'user': User.fromJson(data['user'])};
      } else {
        final error = json.decode(response.body);
        return {'success': false, 'message': error['message'] ?? 'Registration failed'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error occurred'};
    }
  }

  // Logout
  Future<void> logout() async {
    await storage.delete(key: _tokenKey);
    await storage.delete(key: _userKey);
  }

  // Get stored token
  Future<String?> getToken() async {
    return await storage.read(key: _tokenKey);
  }

  // Get stored user
  Future<User?> getStoredUser() async {
    try {
      final userStr = await storage.read(key: _userKey);
      if (userStr != null) {
        return User.fromJson(json.decode(userStr));
      }
    } catch (e) {
      print('Error reading stored user: $e');
    }
    return null;
  }

  // Save authentication data
  Future<void> _saveAuthData(String token, Map<String, dynamic> userData) async {
    await storage.write(key: _tokenKey, value: token);
    await storage.write(key: _userKey, value: json.encode(userData));
  }

  // Verify token
  Future<bool> verifyToken(String token) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/auth/verify'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
} 