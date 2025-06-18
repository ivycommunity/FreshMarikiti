import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fresh_marikiti/core/models/user.dart';
import 'dart:convert';

class StorageService {
  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
  );

  static SharedPreferences? _prefs;
  
  // Storage keys
  static const String _cartDataKey = 'cart_data';
  static const String _themeDataKey = 'theme_data';

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  static SharedPreferences get _instance {
    if (_prefs == null) {
      throw Exception('StorageService not initialized. Call StorageService.init() first.');
    }
    return _prefs!;
  }

  // Token management
  static Future<void> saveToken(String token) async {
    await _secureStorage.write(key: 'access_token', value: token);
  }

  static Future<String?> getToken() async {
    return await _secureStorage.read(key: 'access_token');
  }

  static Future<void> saveRefreshToken(String refreshToken) async {
    await _secureStorage.write(key: 'refresh_token', value: refreshToken);
  }

  static Future<String?> getRefreshToken() async {
    return await _secureStorage.read(key: 'refresh_token');
  }

  static Future<void> clearTokens() async {
    await _secureStorage.delete(key: 'access_token');
    await _secureStorage.delete(key: 'refresh_token');
  }

  // User data management
  static Future<void> saveUser(User user) async {
    await _secureStorage.write(key: 'user_data', value: json.encode(user.toJson()));
  }

  static Future<User?> getUser() async {
    final userData = await _secureStorage.read(key: 'user_data');
    if (userData != null) {
      return User.fromJson(json.decode(userData));
    }
    return null;
  }

  static Future<void> clearUser() async {
    await _secureStorage.delete(key: 'user_data');
  }

  // App preferences
  static Future<void> saveBool(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  static Future<bool> getBool(String key, {bool defaultValue = false}) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(key) ?? defaultValue;
  }

  static Future<void> saveString(String key, String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, value);
  }

  static Future<String?> getString(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(key);
  }

  static Future<void> saveInt(String key, int value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(key, value);
  }

  static Future<int> getInt(String key, {int defaultValue = 0}) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(key) ?? defaultValue;
  }

  // Cart data management
  static Future<void> saveCartData(Map<String, dynamic> cartData) async {
    await _secureStorage.write(key: 'cart_data', value: json.encode(cartData));
  }

  static Future<Map<String, dynamic>?> getCartData() async {
    final cartData = await _secureStorage.read(key: 'cart_data');
    if (cartData != null) {
      return json.decode(cartData);
    }
    return null;
  }

  static Future<void> clearCartData() async {
    await _secureStorage.delete(key: 'cart_data');
  }

  // Settings management
  static Future<void> saveSettings(Map<String, dynamic> settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('app_settings', json.encode(settings));
  }

  static Future<Map<String, dynamic>> getSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final settingsJson = prefs.getString('app_settings');
    if (settingsJson != null) {
      return json.decode(settingsJson);
    }
    return {};
  }

  // Location data
  static Future<void> saveLastLocation(double latitude, double longitude) async {
    await _secureStorage.write(key: 'last_location', value: json.encode({
      'latitude': latitude,
      'longitude': longitude,
      'timestamp': DateTime.now().toIso8601String(),
    }));
  }

  static Future<Map<String, dynamic>?> getLastLocation() async {
    final locationData = await _secureStorage.read(key: 'last_location');
    if (locationData != null) {
      return json.decode(locationData);
    }
    return null;
  }

  // Onboarding status
  static Future<void> setOnboardingCompleted() async {
    await saveBool('onboarding_completed', true);
  }

  static Future<bool> isOnboardingCompleted() async {
    return await getBool('onboarding_completed');
  }

  // Biometric settings
  static Future<void> setBiometricEnabled(bool enabled) async {
    await saveBool('biometric_enabled', enabled);
  }

  static Future<bool> isBiometricEnabled() async {
    return await getBool('biometric_enabled');
  }

  // Notification settings
  static Future<void> saveNotificationToken(String token) async {
    await _secureStorage.write(key: 'fcm_token', value: token);
  }

  static Future<String?> getNotificationToken() async {
    return await _secureStorage.read(key: 'fcm_token');
  }

  // Clear all data (logout)
  static Future<void> clearAllData() async {
    await _secureStorage.deleteAll();
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  // Check if user is logged in
  static Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  // Session management
  static Future<void> saveLastActiveTime() async {
    await saveString('last_active', DateTime.now().toIso8601String());
  }

  static Future<DateTime?> getLastActiveTime() async {
    final timeString = await getString('last_active');
    if (timeString != null) {
      return DateTime.tryParse(timeString);
    }
    return null;
  }

  // Analytics opt-out
  static Future<void> setAnalyticsEnabled(bool enabled) async {
    await saveBool('analytics_enabled', enabled);
  }

  static Future<bool> isAnalyticsEnabled() async {
    return await getBool('analytics_enabled', defaultValue: true);
  }

  // Theme-specific methods
  static Future<Map<String, dynamic>?> getThemeData() async {
    try {
      final themeDataString = _instance.getString(_themeDataKey);
      if (themeDataString != null) {
        return json.decode(themeDataString) as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  static Future<bool> saveThemeData(Map<String, dynamic> themeData) async {
    try {
      final themeDataString = json.encode(themeData);
      return await _instance.setString(_themeDataKey, themeDataString);
    } catch (e) {
      return false;
    }
  }

  // String operations
  static Future<bool> setString(String key, String value) async {
    return await _instance.setString(key, value);
  }

  // Integer operations
  static Future<bool> setInt(String key, int value) async {
    return await _instance.setInt(key, value);
  }

  // Boolean operations
  static Future<bool> setBool(String key, bool value) async {
    return await _instance.setBool(key, value);
  }

  // Double operations
  static Future<bool> setDouble(String key, double value) async {
    return await _instance.setDouble(key, value);
  }

  // List operations
  static Future<bool> setStringList(String key, List<String> value) async {
    return await _instance.setStringList(key, value);
  }

  static List<String>? getStringList(String key) {
    return _instance.getStringList(key);
  }

  // Remove operations
  static Future<bool> remove(String key) async {
    return await _instance.remove(key);
  }

  static Future<bool> clear() async {
    return await _instance.clear();
  }

  // Check if key exists
  static bool containsKey(String key) {
    return _instance.containsKey(key);
  }

  // Get all keys
  static Set<String> getKeys() {
    return _instance.getKeys();
  }
} 