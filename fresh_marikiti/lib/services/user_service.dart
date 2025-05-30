import 'dart:convert';
import 'api_service.dart';

class UserService {
  static Future<List<Map<String, dynamic>>> fetchUsers({String? role}) async {
    final endpoint = role != null ? '/admin/users?role=$role' : '/admin/users';
    final response = await ApiService.get(endpoint);
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.cast<Map<String, dynamic>>();
    } else {
      throw Exception('Failed to load users');
    }
  }

  static Future<bool> updateUser(String userId, {bool? isActive, String? role}) async {
    final body = <String, dynamic>{};
    if (isActive != null) body['isActive'] = isActive;
    if (role != null) body['role'] = role;
    final response = await ApiService.put('/admin/users/$userId', body);
    return response.statusCode == 200;
  }
} 