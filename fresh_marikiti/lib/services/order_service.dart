import 'dart:convert';
import 'package:fresh_marikiti/providers/cart_provider.dart';
import 'api_service.dart';

class OrderService {
  static Future<Map<String, dynamic>> placeOrder({
    required List<CartItem> cartItems,
    required String deliveryAddress,
    required String phoneNumber,
  }) async {
    final products = cartItems.map((item) => {
      'productId': item.product.id,
      'quantity': item.quantity,
    }).toList();
    final totalAmount = cartItems.fold(0.0, (sum, item) => sum + item.product.price * item.quantity);
    final body = {
      'products': products,
      'totalAmount': totalAmount,
      'deliveryAddress': deliveryAddress,
      'phoneNumber': phoneNumber,
    };
    final response = await ApiService.post('/orders', body);
    if (response.statusCode == 201 || response.statusCode == 200) {
      return {'success': true, 'order': json.decode(response.body)};
    } else {
      return {'success': false, 'message': json.decode(response.body)['message'] ?? 'Order failed'};
    }
  }

  static Future<List<Map<String, dynamic>>> fetchOrders() async {
    final response = await ApiService.get('/orders');
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.cast<Map<String, dynamic>>();
    } else {
      throw Exception('Failed to load orders');
    }
  }

  static Future<Map<String, dynamic>> initiateMpesaPayment({
    required String phoneNumber,
    required double amount,
    required String orderId,
  }) async {
    final body = {
      'phoneNumber': phoneNumber,
      'amount': amount,
      'orderId': orderId,
    };
    final response = await ApiService.post('/payments/mpesa/pay', body);
    if (response.statusCode == 200) {
      return {'success': true, 'response': json.decode(response.body)};
    } else {
      return {'success': false, 'message': json.decode(response.body)['message'] ?? 'Payment initiation failed'};
    }
  }

  static Future<List<Map<String, dynamic>>> fetchVendorOrders() async {
    final response = await ApiService.get('/orders/my');
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.cast<Map<String, dynamic>>();
    } else {
      throw Exception('Failed to load vendor orders');
    }
  }

  static Future<bool> updateOrderStatus(String orderId, String status) async {
    final response = await ApiService.patch('/orders/$orderId/status', {'status': status});
    if (response.statusCode == 200) {
      return true;
    } else {
      return false;
    }
  }
} 