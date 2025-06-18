import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:fresh_marikiti/core/models/user.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:fresh_marikiti/core/services/logger_service.dart';

class AuthService {
  static const FlutterSecureStorage _storage = FlutterSecureStorage();
  static const String _tokenKey = 'auth_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _userKey = 'user_data';
  
  // Dynamic base URL that works for both emulator and physical device
  String get baseUrl {
    final envUrl = dotenv.env['API_BASE_URL'];
    if (envUrl != null && envUrl.isNotEmpty) {
      return envUrl;
    }
    
    // Default fallback based on platform
    if (Platform.isAndroid) {
      // For Android emulator, use 10.0.2.2
      // For physical device, this should be set in .env to your computer's IP
      return 'http://10.0.2.2:5000/api';
    } else {
      // For iOS simulator
      return 'http://localhost:5000/api';
    }
  }

  // Login user
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      LoggerService.info('Attempting login to $baseUrl/auth/login', tag: 'AuthService');
      
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: const {'Content-Type': 'application/json'},
        body: json.encode({
          'email': email,
          'password': password,
        }),
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Connection timeout. Please check your network.');
        },
      );

      LoggerService.info('Login response: ${response.statusCode}', tag: 'AuthService');
      LoggerService.info('Login response body: ${response.body}', tag: 'AuthService');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        
        // Handle the correct backend response structure
        if (responseData['success'] == true && responseData['data'] != null) {
          final data = responseData['data'];
          final token = data['token'];
          final refreshToken = data['refreshToken'];
          final user = data['user'];
          
          if (token == null || user == null) {
            LoggerService.error('Missing token or user in response', tag: 'AuthService');
            return const {'success': false, 'message': 'Invalid response from server'};
          }

          await _saveAuthData(token, refreshToken, user);
          return {'success': true, 'user': User.fromJson(user)};
        } else {
          final message = responseData['message'] ?? 'Login failed';
          return {'success': false, 'message': message};
        }
      } else {
        String errorMessage;
        try {
          final error = json.decode(response.body);
          errorMessage = error['message'] ?? 'Login failed';
        } catch (e) {
          errorMessage = response.reasonPhrase ?? 'Login failed';
        }
        return {'success': false, 'message': errorMessage};
      }
    } catch (e) {
      LoggerService.error('Login error', tag: 'AuthService', error: e);
      String errorMessage = 'Network error occurred';
      
      if (e.toString().contains('timeout')) {
        errorMessage = 'Connection timeout. Please check your network.';
      } else if (e.toString().contains('SocketException')) {
        errorMessage = 'Cannot connect to server. Please check your internet connection.';
      }
      
      return {'success': false, 'message': errorMessage};
    }
  }

  // Register customer
  Future<Map<String, dynamic>> registerCustomer(Map<String, dynamic> userData) async {
    try {
      LoggerService.info('Attempting registration to $baseUrl/auth/register', tag: 'AuthService');
      
      final response = await http.post(
        Uri.parse('$baseUrl/auth/register'),
        headers: const {'Content-Type': 'application/json'},
        body: json.encode(userData),
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Connection timeout. Please check your network.');
        },
      );

      LoggerService.info('Register response: ${response.statusCode}', tag: 'AuthService');

      if (response.statusCode == 201) {
        final responseData = json.decode(response.body);
        
        // Handle the correct backend response structure
        if (responseData['success'] == true && responseData['data'] != null) {
          final data = responseData['data'];
          final token = data['token'];
          final refreshToken = data['refreshToken'];
          final user = data['user'];
          
          if (token == null || user == null) {
            return const {'success': false, 'message': 'Invalid response from server'};
          }

          await _saveAuthData(token, refreshToken, user);
          return {'success': true, 'user': User.fromJson(user)};
        } else {
          final message = responseData['message'] ?? 'Registration failed';
          return {'success': false, 'message': message};
        }
      } else {
        String errorMessage;
        try {
          final error = json.decode(response.body);
          errorMessage = error['message'] ?? 'Registration failed';
        } catch (e) {
          errorMessage = response.reasonPhrase ?? 'Registration failed';
        }
        return {'success': false, 'message': errorMessage};
      }
    } catch (e) {
      LoggerService.error('Registration error', tag: 'AuthService', error: e);
      String errorMessage = 'Network error occurred';
      
      if (e.toString().contains('timeout')) {
        errorMessage = 'Connection timeout. Please check your network.';
      } else if (e.toString().contains('SocketException')) {
        errorMessage = 'Cannot connect to server. Please check your internet connection.';
      }
      
      return {'success': false, 'message': errorMessage};
    }
  }

  // Save authentication data
  Future<void> _saveAuthData(String token, String? refreshToken, Map<String, dynamic> userData) async {
    await _storage.write(key: _tokenKey, value: token);
    if (refreshToken != null) {
      await _storage.write(key: _refreshTokenKey, value: refreshToken);
    }
    await _storage.write(key: _userKey, value: json.encode(userData));
  }

  // Get stored token
  Future<String?> getToken() async {
    return await _storage.read(key: _tokenKey);
  }

  // Get stored refresh token
  Future<String?> getRefreshToken() async {
    return await _storage.read(key: _refreshTokenKey);
  }

  // Refresh access token
  Future<bool> refreshToken() async {
    try {
      final refreshToken = await getRefreshToken();
      if (refreshToken == null) return false;

      final response = await http.post(
        Uri.parse('$baseUrl/auth/refresh'),
        headers: const {'Content-Type': 'application/json'},
        body: json.encode({'refreshToken': refreshToken}),
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData['success'] == true && responseData['data'] != null) {
          final data = responseData['data'];
          final newToken = data['token'];
          final newRefreshToken = data['refreshToken'];
          
          if (newToken != null) {
            await _storage.write(key: _tokenKey, value: newToken);
            if (newRefreshToken != null) {
              await _storage.write(key: _refreshTokenKey, value: newRefreshToken);
            }
            return true;
          }
        }
      }
      return false;
    } catch (e) {
      LoggerService.error('Token refresh error', tag: 'AuthService', error: e);
      return false;
    }
  }

  // Verify token
  Future<bool> verifyToken(String token) async {
    try {
      final url = '$baseUrl/auth/verify';
      LoggerService.info('Attempting token verification to $url', tag: 'AuthService');
      
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );
      
      LoggerService.info('Token verification response: ${response.statusCode}', tag: 'AuthService');
      
      if (response.statusCode != 200) {
        LoggerService.error('Token verification failed: ${response.body}', tag: 'AuthService');
      }
      
      return response.statusCode == 200;
    } catch (e) {
      LoggerService.error('Token verification error', tag: 'AuthService', error: e);
      return false;
    }
  }

  // Get stored user
  Future<User?> getStoredUser() async {
    final userData = await _storage.read(key: _userKey);
    if (userData != null) {
      return User.fromJson(json.decode(userData));
    }
    return null;
  }

  // Logout
  Future<void> logout() async {
    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _refreshTokenKey);
    await _storage.delete(key: _userKey);
  }

  // Store user data
  Future<void> storeUser(User user) async {
    await _storage.write(key: _userKey, value: json.encode(user.toJson()));
  }

  // Update user profile
  Future<Map<String, dynamic>> updateProfile({
    required String userId,
    String? name,
    String? email,
    String? phoneNumber,
  }) async {
    try {
      final token = await getToken();
      if (token == null) {
        return const {'success': false, 'message': 'Not authenticated'};
      }

      final updateData = <String, dynamic>{};
      if (name != null) updateData['name'] = name;
      if (email != null) updateData['email'] = email;
      if (phoneNumber != null) updateData['phoneNumber'] = phoneNumber;

      final response = await http.put(
        Uri.parse('$baseUrl/users/$userId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(updateData),
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData['success'] == true && responseData['data'] != null) {
          final user = responseData['data']['user'];
          if (user != null) {
            await storeUser(User.fromJson(user));
            return {'success': true, 'user': User.fromJson(user)};
          }
        }
        return {'success': false, 'message': 'Invalid response structure'};
      } else {
        final error = json.decode(response.body);
        return {'success': false, 'message': error['message'] ?? 'Update failed'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // Logout from all devices
  Future<void> logoutAllDevices() async {
    try {
      final token = await getToken();
      if (token != null) {
        await http.post(
          Uri.parse('$baseUrl/auth/logout-all'),
          headers: {
            'Authorization': 'Bearer $token',
          },
        );
      }
    } catch (e) {
      LoggerService.error('Logout all devices error', tag: 'AuthService', error: e);
    } finally {
      // Clear local storage regardless
      await logout();
    }
  }

  // Delete account permanently
  Future<void> deleteAccount() async {
    try {
      final token = await getToken();
      if (token != null) {
        await http.delete(
          Uri.parse('$baseUrl/users/account'),
          headers: {
            'Authorization': 'Bearer $token',
          },
        );
      }
    } catch (e) {
      LoggerService.error('Delete account error', tag: 'AuthService', error: e);
    } finally {
      // Clear local storage regardless
      await logout();
    }
  }
}