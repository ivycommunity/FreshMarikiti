import 'package:flutter/material.dart';
import 'package:fresh_marikiti/core/models/user.dart';
import 'package:fresh_marikiti/core/services/auth_service.dart';
import 'package:fresh_marikiti/core/services/logger_service.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  User? _user;
  bool _isLoading = false;
  String? _error;

  // Getters
  User? get user => _user;
  bool get isAuthenticated => _user != null;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Role-based getters
  bool get isCustomer => _user?.role == UserRole.customer;
  bool get isVendor => _user?.role == UserRole.vendor;
  bool get isRider => _user?.role == UserRole.rider;
  bool get isConnector => _user?.role == UserRole.connector;
  bool get isVendorAdmin => _user?.role == UserRole.vendorAdmin;
  bool get isSystemAdmin => _user?.role == UserRole.admin;
  
  // Admin role checks
  bool get isAnyAdmin => isVendorAdmin || isSystemAdmin;
  bool get canAccessVendorFeatures => isVendor || isVendorAdmin;
  bool get canAccessAdminFeatures => isSystemAdmin;

  /// Initialize auth provider
  AuthProvider() {
    _loadUser();
  }

  /// Load user from stored token
  Future<void> _loadUser() async {
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
      LoggerService.error('Failed to load user', error: e, tag: 'AuthProvider');
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Login user
  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _authService.login(email, password);
      
      if (result['success'] == true) {
        _user = result['user'];
        LoggerService.info('User logged in: ${_user?.email} as ${_user?.role}', tag: 'AuthProvider');
        notifyListeners();
        return true;
      } else {
        _error = result['message'] ?? 'Login failed';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Login failed: ${e.toString()}';
      LoggerService.error('Login error', error: e, tag: 'AuthProvider');
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Register new user
  Future<bool> register({
    required String email,
    required String password,
    required String name,
    required String phoneNumber,
    required UserRole role,
    Map<String, dynamic>? additionalData,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Basic validation
      if (email.isEmpty || password.isEmpty || name.isEmpty || phoneNumber.isEmpty) {
        _error = 'All fields are required';
        notifyListeners();
        return false;
      }

      final registrationData = {
        'email': email,
        'password': password,
        'name': name,
        'phoneNumber': phoneNumber,
        'role': role.toString().split('.').last,
        ...?additionalData,
      };

      final result = await _authService.registerCustomer(registrationData);
      
      if (result['success'] == true) {
        _user = result['user'];
        LoggerService.info('User registered: $email as $role', tag: 'AuthProvider');
        notifyListeners();
        return true;
      } else {
        _error = result['message'] ?? 'Registration failed';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Registration failed: ${e.toString()}';
      LoggerService.error('Registration error', error: e, tag: 'AuthProvider');
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Get home route based on user role
  String getHomeRoute() {
    if (_user == null) return '/login';
    
    switch (_user!.role) {
      case UserRole.customer:
        return '/customer/home';
      case UserRole.vendor:
        return '/vendor/home';
      case UserRole.rider:
        return '/rider/home';
      case UserRole.connector:
        return '/connector/home';
      case UserRole.vendorAdmin:
        return '/vendor-admin/home';
      case UserRole.admin:
        return '/admin/home';
    }
  }

  /// Check if user has permission for specific feature
  bool hasPermission(String permission) {
    if (_user == null) return false;
    
    // Define role-based permissions
    final rolePermissions = {
      UserRole.customer: ['place_order', 'view_products', 'chat_connector'],
      UserRole.vendor: ['manage_products', 'view_orders', 'update_inventory'],
      UserRole.rider: ['view_deliveries', 'update_location', 'complete_delivery'],
      UserRole.connector: ['view_assignments', 'chat_customer', 'manage_shopping'],
      UserRole.vendorAdmin: ['manage_vendors', 'view_analytics', 'manage_products'],
      UserRole.admin: ['manage_all', 'view_all_analytics', 'manage_users'],
    };
    
    final userPermissions = rolePermissions[_user!.role] ?? [];
    return userPermissions.contains(permission) || _user!.role == UserRole.admin;
  }

  /// Update user profile
  Future<bool> updateProfile({
    String? name,
    String? email,
    String? phoneNumber,
    Map<String, dynamic>? additionalData,
  }) async {
    if (_user == null) return false;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _authService.updateProfile(
        userId: _user!.id,
        name: name,
        email: email,
        phoneNumber: phoneNumber,
      );
      
      if (result['success'] == true) {
        _user = result['user'] ?? _user;
        notifyListeners();
        return true;
      } else {
        _error = result['message'] ?? 'Failed to update profile';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Update failed: ${e.toString()}';
      LoggerService.error('Profile update error', error: e, tag: 'AuthProvider');
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Logout user
  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _authService.logout();
      _user = null;
      LoggerService.info('User logged out', tag: 'AuthProvider');
    } catch (e) {
      LoggerService.error('Logout error', error: e, tag: 'AuthProvider');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Refresh user data
  Future<void> refreshUser() async {
    if (_user != null) {
      await _loadUser();
    }
  }

  /// Update user locally
  void updateUser(User updatedUser) {
    _user = updatedUser;
    notifyListeners();
  }

  /// Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
} 