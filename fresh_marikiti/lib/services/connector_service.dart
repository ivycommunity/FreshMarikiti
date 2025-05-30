import 'package:http/http.dart' as http;
import 'api_service.dart';

class ConnectorService {
  // Orders Management
  static Future<dynamic> getAssignedOrders() async {
    final response = await ApiService.get('/connector/orders');
    return ApiService.decodeJson(response);
  }

  static Future<dynamic> updateOrderStatus(String orderId, String status) async {
    final response = await ApiService.patch('/connector/orders/$orderId', {
      'status': status,
    });
    return ApiService.decodeJson(response);
  }

  // Waste Collection
  static Future<dynamic> getWasteCollectionTasks() async {
    final response = await ApiService.get('/connector/waste-collection');
    return ApiService.decodeJson(response);
  }

  static Future<dynamic> updateWasteCollectionStatus(String taskId, String status) async {
    final response = await ApiService.patch('/connector/waste-collection/$taskId', {
      'status': status,
    });
    return ApiService.decodeJson(response);
  }

  static Future<dynamic> logWasteCollection(String vendorId, Map<String, dynamic> wasteData) async {
    final response = await ApiService.post('/connector/waste-collection/log', {
      'vendorId': vendorId,
      ...wasteData,
    });
    return ApiService.decodeJson(response);
  }

  // Eco Points
  static Future<dynamic> getEcoPointsHistory() async {
    final response = await ApiService.get('/connector/eco-points/history');
    return ApiService.decodeJson(response);
  }

  // Communication
  static Future<dynamic> sendMessageToCustomer(String customerId, String message) async {
    final response = await ApiService.post('/connector/messages', {
      'customerId': customerId,
      'message': message,
    });
    return ApiService.decodeJson(response);
  }

  static Future<dynamic> getMessages(String customerId) async {
    final response = await ApiService.get('/connector/messages/$customerId');
    return ApiService.decodeJson(response);
  }

  // Profile
  static Future<dynamic> getConnectorProfile() async {
    final response = await ApiService.get('/connector/profile');
    return ApiService.decodeJson(response);
  }

  static Future<dynamic> updateConnectorProfile(Map<String, dynamic> profileData) async {
    final response = await ApiService.patch('/connector/profile', profileData);
    return ApiService.decodeJson(response);
  }

  // Statistics
  static Future<dynamic> getConnectorStats() async {
    final response = await ApiService.get('/connector/stats');
    return ApiService.decodeJson(response);
  }
} 