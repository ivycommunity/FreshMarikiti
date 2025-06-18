import 'dart:convert';
import 'dart:io';
import 'package:fresh_marikiti/core/models/user.dart';
import 'package:fresh_marikiti/core/services/api_service.dart';
import 'package:fresh_marikiti/core/services/logger_service.dart';
import 'package:fresh_marikiti/core/services/storage_service.dart';
import 'package:http/http.dart' as http;

class UserService {
  
  // =================== PROFILE MANAGEMENT FOR ALL ROLES ===================

  /// Get current user profile
  static Future<User?> getCurrentUser() async {
    try {
      LoggerService.info('Fetching current user profile', tag: 'UserService');

      final response = await ApiService.get('/users/profile');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return User.fromJson(data['user'] ?? data);
      } else {
        LoggerService.error('Failed to fetch user profile: ${response.statusCode}', tag: 'UserService');
        return null;
      }
    } catch (e) {
      LoggerService.error('Error fetching user profile', error: e, tag: 'UserService');
      return null;
    }
  }

  /// Update user profile (common fields for all roles)
  static Future<Map<String, dynamic>> updateProfile({
    String? name,
    String? email,
    String? phoneNumber,
    String? location,
    Map<String, double>? coordinates,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      LoggerService.info('Updating user profile', tag: 'UserService');

      final updateData = <String, dynamic>{};
      if (name != null) updateData['name'] = name;
      if (email != null) updateData['email'] = email;
      if (phoneNumber != null) updateData['phoneNumber'] = phoneNumber;
      if (location != null) updateData['location'] = location;
      if (coordinates != null) updateData['coordinates'] = coordinates;
      if (additionalData != null) updateData.addAll(additionalData);

      final response = await ApiService.put('/users/profile', updateData);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        LoggerService.info('Profile updated successfully', tag: 'UserService');
        return {
          'success': true,
          'user': User.fromJson(data['user'] ?? data),
        };
      } else {
        final error = json.decode(response.body);
        LoggerService.error('Profile update failed: ${error['message']}', tag: 'UserService');
        return {
          'success': false,
          'message': error['message'] ?? 'Failed to update profile',
        };
      }
    } catch (e) {
      LoggerService.error('Error updating profile', error: e, tag: 'UserService');
      return {
        'success': false,
        'message': 'Network error: Failed to update profile',
      };
    }
  }

  /// Upload profile picture
  static Future<Map<String, dynamic>> uploadProfilePicture(File imageFile) async {
    try {
      LoggerService.info('Uploading profile picture', tag: 'UserService');

      final token = await StorageService.getToken();
      final request = http.MultipartRequest(
        'POST', 
        Uri.parse('${ApiService.baseUrl}/users/profile/picture')
      );
      
      if (token != null) {
        request.headers['Authorization'] = 'Bearer $token';
      }

      request.files.add(await http.MultipartFile.fromPath('profilePicture', imageFile.path));

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        LoggerService.info('Profile picture uploaded successfully', tag: 'UserService');
        return {
          'success': true,
          'imageUrl': data['imageUrl'],
        };
      } else {
        LoggerService.error('Failed to upload profile picture: ${response.statusCode}', tag: 'UserService');
        return {
          'success': false,
          'message': 'Failed to upload profile picture',
        };
      }
    } catch (e) {
      LoggerService.error('Error uploading profile picture', error: e, tag: 'UserService');
      return {
        'success': false,
        'message': 'Network error: Failed to upload profile picture',
      };
    }
  }

  // =================== VENDOR-SPECIFIC METHODS ===================

  /// Update vendor business information
  static Future<Map<String, dynamic>> updateVendorProfile({
    String? businessName,
    String? businessDescription,
    String? businessLicense,
    String? businessAddress,
    Map<String, double>? businessCoordinates,
    List<String>? businessCategories,
    Map<String, dynamic>? businessHours,
    String? bankAccountInfo,
  }) async {
    try {
      LoggerService.info('Updating vendor business profile', tag: 'UserService');

      final updateData = <String, dynamic>{};
      if (businessName != null) updateData['businessName'] = businessName;
      if (businessDescription != null) updateData['businessDescription'] = businessDescription;
      if (businessLicense != null) updateData['businessLicense'] = businessLicense;
      if (businessAddress != null) updateData['businessAddress'] = businessAddress;
      if (businessCoordinates != null) updateData['businessCoordinates'] = businessCoordinates;
      if (businessCategories != null) updateData['businessCategories'] = businessCategories;
      if (businessHours != null) updateData['businessHours'] = businessHours;
      if (bankAccountInfo != null) updateData['bankAccountInfo'] = bankAccountInfo;

      final response = await ApiService.put('/users/vendor/profile', updateData);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'success': true,
          'user': User.fromJson(data['user'] ?? data),
        };
      } else {
        final error = json.decode(response.body);
        return {
          'success': false,
          'message': error['message'] ?? 'Failed to update vendor profile',
        };
      }
    } catch (e) {
      LoggerService.error('Error updating vendor profile', error: e, tag: 'UserService');
      return {
        'success': false,
        'message': 'Network error: Failed to update vendor profile',
      };
    }
  }

  // =================== RIDER-SPECIFIC METHODS ===================

  /// Update rider vehicle and license information
  static Future<Map<String, dynamic>> updateRiderProfile({
    String? vehicleType,
    String? vehicleModel,
    String? vehiclePlateNumber,
    String? licenseNumber,
    DateTime? licenseExpiryDate,
    String? insuranceInfo,
    List<String>? serviceAreas,
    bool? isAvailable,
  }) async {
    try {
      LoggerService.info('Updating rider profile', tag: 'UserService');

      final updateData = <String, dynamic>{};
      if (vehicleType != null) updateData['vehicleType'] = vehicleType;
      if (vehicleModel != null) updateData['vehicleModel'] = vehicleModel;
      if (vehiclePlateNumber != null) updateData['vehiclePlateNumber'] = vehiclePlateNumber;
      if (licenseNumber != null) updateData['licenseNumber'] = licenseNumber;
      if (licenseExpiryDate != null) updateData['licenseExpiryDate'] = licenseExpiryDate.toIso8601String();
      if (insuranceInfo != null) updateData['insuranceInfo'] = insuranceInfo;
      if (serviceAreas != null) updateData['serviceAreas'] = serviceAreas;
      if (isAvailable != null) updateData['isAvailable'] = isAvailable;

      final response = await ApiService.put('/users/rider/profile', updateData);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'success': true,
          'user': User.fromJson(data['user'] ?? data),
        };
      } else {
        final error = json.decode(response.body);
        return {
          'success': false,
          'message': error['message'] ?? 'Failed to update rider profile',
        };
      }
    } catch (e) {
      LoggerService.error('Error updating rider profile', error: e, tag: 'UserService');
      return {
        'success': false,
        'message': 'Network error: Failed to update rider profile',
      };
    }
  }

  /// Update rider availability status
  static Future<bool> updateRiderAvailability(bool isAvailable) async {
    try {
      final response = await ApiService.patch('/users/rider/availability', {
        'isAvailable': isAvailable,
        'updatedAt': DateTime.now().toIso8601String(),
      });

      return response.statusCode == 200;
    } catch (e) {
      LoggerService.error('Error updating rider availability', error: e, tag: 'UserService');
      return false;
    }
  }

  /// Update rider location for real-time tracking
  static Future<bool> updateRiderLocation(double latitude, double longitude) async {
    try {
      final response = await ApiService.patch('/users/rider/location', {
        'coordinates': {
          'latitude': latitude,
          'longitude': longitude,
        },
        'lastLocationUpdate': DateTime.now().toIso8601String(),
      });

      return response.statusCode == 200;
    } catch (e) {
      LoggerService.error('Error updating rider location', error: e, tag: 'UserService');
      return false;
    }
  }

  // =================== CONNECTOR-SPECIFIC METHODS ===================

  /// Update connector market and service information
  static Future<Map<String, dynamic>> updateConnectorProfile({
    String? marketArea,
    List<String>? expertiseCategories,
    List<String>? serviceAreas,
    Map<String, dynamic>? workingHours,
    double? commissionRate,
    bool? isAvailable,
  }) async {
    try {
      LoggerService.info('Updating connector profile', tag: 'UserService');

      final updateData = <String, dynamic>{};
      if (marketArea != null) updateData['marketArea'] = marketArea;
      if (expertiseCategories != null) updateData['expertiseCategories'] = expertiseCategories;
      if (serviceAreas != null) updateData['serviceAreas'] = serviceAreas;
      if (workingHours != null) updateData['workingHours'] = workingHours;
      if (commissionRate != null) updateData['commissionRate'] = commissionRate;
      if (isAvailable != null) updateData['isAvailable'] = isAvailable;

      final response = await ApiService.put('/users/connector/profile', updateData);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'success': true,
          'user': User.fromJson(data['user'] ?? data),
        };
      } else {
        final error = json.decode(response.body);
        return {
          'success': false,
          'message': error['message'] ?? 'Failed to update connector profile',
        };
      }
    } catch (e) {
      LoggerService.error('Error updating connector profile', error: e, tag: 'UserService');
      return {
        'success': false,
        'message': 'Network error: Failed to update connector profile',
      };
    }
  }

  // =================== ECO POINTS MANAGEMENT ===================

  /// Get user's eco points history
  static Future<Map<String, dynamic>> getEcoPointsHistory({
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final response = await ApiService.get('/users/eco-points/history?page=$page&limit=$limit');

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        return {};
      }
    } catch (e) {
      LoggerService.error('Error fetching eco points history', error: e, tag: 'UserService');
      return {};
    }
  }

  /// Redeem eco points
  static Future<Map<String, dynamic>> redeemEcoPoints({
    required int points,
    required String rewardType,
    Map<String, dynamic>? rewardDetails,
  }) async {
    try {
      final response = await ApiService.post('/users/eco-points/redeem', {
        'points': points,
        'rewardType': rewardType,
        'rewardDetails': rewardDetails,
        'timestamp': DateTime.now().toIso8601String(),
      });

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'success': true,
          'transaction': data,
        };
      } else {
        final error = json.decode(response.body);
        return {
          'success': false,
          'message': error['message'] ?? 'Failed to redeem eco points',
        };
      }
    } catch (e) {
      LoggerService.error('Error redeeming eco points', error: e, tag: 'UserService');
      return {
        'success': false,
        'message': 'Network error: Failed to redeem eco points',
      };
    }
  }

  // =================== WALLET MANAGEMENT ===================

  /// Get wallet balance and transactions
  static Future<Map<String, dynamic>> getWalletInfo() async {
    try {
      final response = await ApiService.get('/users/wallet');

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        return {};
      }
    } catch (e) {
      LoggerService.error('Error fetching wallet info', error: e, tag: 'UserService');
      return {};
    }
  }

  /// Add money to wallet
  static Future<Map<String, dynamic>> addMoneyToWallet({
    required double amount,
    required String paymentMethod,
    Map<String, dynamic>? paymentDetails,
  }) async {
    try {
      final response = await ApiService.post('/users/wallet/add-money', {
        'amount': amount,
        'paymentMethod': paymentMethod,
        'paymentDetails': paymentDetails,
        'timestamp': DateTime.now().toIso8601String(),
      });

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'success': true,
          'transaction': data,
        };
      } else {
        final error = json.decode(response.body);
        return {
          'success': false,
          'message': error['message'] ?? 'Failed to add money to wallet',
        };
      }
    } catch (e) {
      LoggerService.error('Error adding money to wallet', error: e, tag: 'UserService');
      return {
        'success': false,
        'message': 'Network error: Failed to add money to wallet',
      };
    }
  }

  // =================== RATINGS AND REVIEWS ===================

  /// Get user ratings and reviews
  static Future<Map<String, dynamic>> getUserRatings() async {
    try {
      final response = await ApiService.get('/users/ratings');

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        return {};
      }
    } catch (e) {
      LoggerService.error('Error fetching user ratings', error: e, tag: 'UserService');
      return {};
    }
  }

  // =================== ADMIN METHODS ===================

  /// Get all users (Admin only)
  static Future<List<User>> getAllUsers({
    UserRole? role,
    String? search,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      String url = '/admin/users?page=$page&limit=$limit';
      if (role != null) {
        url += '&role=${role.toString().split('.').last}';
      }
      if (search != null && search.isNotEmpty) {
        url += '&search=${Uri.encodeComponent(search)}';
      }

      final response = await ApiService.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final users = (data['users'] ?? data['data'] ?? [])
            .map<User>((json) => User.fromJson(json))
            .toList();
        return users;
      }
      return [];
    } catch (e) {
      LoggerService.error('Error fetching all users', error: e, tag: 'UserService');
      return [];
    }
  }

  /// Update user status (Admin only)
  static Future<bool> updateUserStatus(String userId, bool isActive) async {
    try {
      final response = await ApiService.patch('/admin/users/$userId/status', {
        'isActive': isActive,
        'updatedAt': DateTime.now().toIso8601String(),
      });

      return response.statusCode == 200;
    } catch (e) {
      LoggerService.error('Error updating user status', error: e, tag: 'UserService');
      return false;
    }
  }

  // =================== ANALYTICS METHODS ===================

  /// Get user analytics
  static Future<Map<String, dynamic>> getUserAnalytics({String period = 'month'}) async {
    try {
      final response = await ApiService.get('/users/analytics?period=$period');

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        return {};
      }
    } catch (e) {
      LoggerService.error('Error fetching user analytics', error: e, tag: 'UserService');
      return {};
    }
  }

  // =================== NOTIFICATION PREFERENCES ===================

  /// Update notification preferences
  static Future<bool> updateNotificationPreferences(Map<String, bool> preferences) async {
    try {
      final response = await ApiService.put('/users/notifications/preferences', {
        'preferences': preferences,
        'updatedAt': DateTime.now().toIso8601String(),
      });

      return response.statusCode == 200;
    } catch (e) {
      LoggerService.error('Error updating notification preferences', error: e, tag: 'UserService');
      return false;
    }
  }

  /// Update FCM token
  static Future<bool> updateFcmToken(String fcmToken) async {
    try {
      final response = await ApiService.patch('/users/fcm-token', {
        'fcmToken': fcmToken,
        'updatedAt': DateTime.now().toIso8601String(),
      });

      return response.statusCode == 200;
    } catch (e) {
      LoggerService.error('Error updating FCM token', error: e, tag: 'UserService');
      return false;
    }
  }
} 