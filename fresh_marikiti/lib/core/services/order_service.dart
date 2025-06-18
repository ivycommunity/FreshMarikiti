import 'dart:convert';
import 'package:fresh_marikiti/core/services/api_service.dart';
import 'package:fresh_marikiti/core/services/logger_service.dart';
import 'package:fresh_marikiti/core/models/cart_model.dart';
import 'package:fresh_marikiti/core/models/order_model.dart';
import 'package:fresh_marikiti/core/models/user.dart';

class OrderService {
  // =================== CUSTOMER METHODS ===================

  /// Place order - Customer creates order
  static Future<Map<String, dynamic>> placeOrder({
    required List<CartItem> cartItems,
    required String deliveryAddress,
    required String phoneNumber,
    required Map<String, double> deliveryCoordinates,
    String? specialInstructions,
    PaymentMethod paymentMethod = PaymentMethod.mpesa,
  }) async {
    try {
      LoggerService.info('Placing order with ${cartItems.length} items', tag: 'OrderService');

      final products = cartItems.map((item) => {
        'productId': item.product.id,
        'quantity': item.quantity,
        'price': item.product.price,
        'vendorId': item.product.vendorId,
      }).toList();

      // Calculate totals
      final subtotal = cartItems.fold(0.0, (sum, item) => sum + (item.product.price * item.quantity));
      final deliveryFee = _calculateDeliveryFee(deliveryCoordinates);
      final total = subtotal + deliveryFee;

      final orderData = {
        'items': products,
        'deliveryAddress': {
          'fullAddress': deliveryAddress,
          'coordinates': {
            'latitude': deliveryCoordinates['latitude'],
            'longitude': deliveryCoordinates['longitude'],
          }
        },
        'customerPhone': phoneNumber,
        'specialInstructions': specialInstructions,
        'paymentMethod': paymentMethod.toString().split('.').last,
        'totalAmount': total,
        'subtotal': subtotal,
        'deliveryFee': deliveryFee,
        'status': 'pending',
      };

      final response = await ApiService.post('/orders', orderData);
      
      if (response.statusCode == 201 || response.statusCode == 200) {
        final responseData = json.decode(response.body);
        LoggerService.info('Order placed successfully: ${responseData['orderId'] ?? responseData['id']}', tag: 'OrderService');
        return {
          'success': true,
          'order': responseData,
          'orderId': responseData['orderId'] ?? responseData['id'],
        };
      } else {
        final error = json.decode(response.body);
        LoggerService.error('Order placement failed: ${error['message']}', tag: 'OrderService');
        return {
          'success': false,
          'message': error['message'] ?? 'Failed to place order',
        };
      }
    } catch (e) {
      LoggerService.error('Error placing order', error: e, tag: 'OrderService');
      return {
        'success': false,
        'message': 'Network error: Failed to place order',
      };
    }
  }

  /// Get customer orders
  static Future<List<Order>> getCustomerOrders({
    String? status,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      String url = '/orders/my?page=$page&limit=$limit';
      if (status != null && status != 'all') {
        url += '&status=$status';
      }

      final response = await ApiService.get(url);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final orders = data['orders'] ?? data['data'] ?? [];
        return orders.map<Order>((json) => Order.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      LoggerService.error('Error fetching customer orders', error: e, tag: 'OrderService');
      return [];
    }
  }

  // =================== CONNECTOR METHODS ===================

  /// Get orders assigned to connector
  static Future<List<Order>> getConnectorOrders({
    String? status,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      String url = '/orders/connector/assigned?page=$page&limit=$limit';
      if (status != null && status != 'all') {
        url += '&status=$status';
      }

      final response = await ApiService.get(url);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final orders = data['orders'] ?? data['data'] ?? [];
        return orders.map<Order>((json) => Order.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      LoggerService.error('Error fetching connector orders', error: e, tag: 'OrderService');
      return [];
    }
  }

  /// Accept order assignment (Connector)
  static Future<bool> acceptOrderAssignment(String orderId) async {
    try {
      final response = await ApiService.patch('/orders/$orderId/assign-connector', {
        'status': 'assigned',
        'timestamp': DateTime.now().toIso8601String(),
      });
      return response.statusCode == 200;
    } catch (e) {
      LoggerService.error('Error accepting order assignment', error: e, tag: 'OrderService');
      return false;
    }
  }

  /// Start shopping (Connector begins market shopping)
  static Future<bool> startShopping(String orderId) async {
    try {
      final response = await ApiService.patch('/orders/$orderId/status', {
        'status': 'shopping',
        'timestamp': DateTime.now().toIso8601String(),
        'notes': 'Connector started shopping at market',
      });
      return response.statusCode == 200;
    } catch (e) {
      LoggerService.error('Error starting shopping', error: e, tag: 'OrderService');
      return false;
    }
  }

  /// Complete shopping and hand over to rider
  static Future<bool> completeShoppingAndHandover(String orderId, String riderId) async {
    try {
      final response = await ApiService.patch('/orders/$orderId/handover', {
        'status': 'picked_up',
        'riderId': riderId,
        'timestamp': DateTime.now().toIso8601String(),
        'notes': 'Order handed over to rider',
      });
      return response.statusCode == 200;
    } catch (e) {
      LoggerService.error('Error completing handover', error: e, tag: 'OrderService');
      return false;
    }
  }

  // =================== VENDOR METHODS ===================

  /// Get vendor orders
  static Future<List<Order>> getVendorOrders({
    String? status,
    String? date,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      String url = '/orders/vendor/my?page=$page&limit=$limit';
      if (status != null && status != 'all') {
        url += '&status=$status';
      }
      if (date != null) {
        url += '&date=$date';
      }

      final response = await ApiService.get(url);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final orders = data['orders'] ?? data['data'] ?? [];
        return orders.map<Order>((json) => Order.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      LoggerService.error('Error fetching vendor orders', error: e, tag: 'OrderService');
      return [];
    }
  }

  /// Confirm order (Vendor confirms they have the items)
  static Future<bool> confirmOrder(String orderId) async {
    try {
      final response = await ApiService.patch('/orders/$orderId/status', {
        'status': 'confirmed',
        'timestamp': DateTime.now().toIso8601String(),
        'notes': 'Vendor confirmed order availability',
      });
      return response.statusCode == 200;
    } catch (e) {
      LoggerService.error('Error confirming order', error: e, tag: 'OrderService');
      return false;
    }
  }

  /// Mark order as ready for pickup
  static Future<bool> markOrderReady(String orderId) async {
    try {
      final response = await ApiService.patch('/orders/$orderId/status', {
        'status': 'ready',
        'timestamp': DateTime.now().toIso8601String(),
        'notes': 'Order ready for connector pickup',
      });
      return response.statusCode == 200;
    } catch (e) {
      LoggerService.error('Error marking order ready', error: e, tag: 'OrderService');
      return false;
    }
  }

  // =================== RIDER METHODS ===================

  /// Get rider assigned deliveries
  static Future<List<Order>> getRiderDeliveries({
    String? status,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      String url = '/orders/rider/assigned?page=$page&limit=$limit';
      if (status != null && status != 'all') {
        url += '&status=$status';
      }

      final response = await ApiService.get(url);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final orders = data['orders'] ?? data['data'] ?? [];
        return orders.map<Order>((json) => Order.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      LoggerService.error('Error fetching rider deliveries', error: e, tag: 'OrderService');
      return [];
    }
  }

  /// Start delivery (Rider begins delivery)
  static Future<bool> startDelivery(String orderId) async {
    try {
      final response = await ApiService.patch('/orders/$orderId/status', {
        'status': 'out_for_delivery',
        'timestamp': DateTime.now().toIso8601String(),
        'notes': 'Rider started delivery',
      });
      return response.statusCode == 200;
    } catch (e) {
      LoggerService.error('Error starting delivery', error: e, tag: 'OrderService');
      return false;
    }
  }

  /// Complete delivery
  static Future<bool> completeDelivery(String orderId, {String? deliveryNotes}) async {
    try {
      final response = await ApiService.patch('/orders/$orderId/status', {
        'status': 'delivered',
        'timestamp': DateTime.now().toIso8601String(),
        'notes': deliveryNotes ?? 'Order delivered successfully',
        'deliveredAt': DateTime.now().toIso8601String(),
      });
      return response.statusCode == 200;
    } catch (e) {
      LoggerService.error('Error completing delivery', error: e, tag: 'OrderService');
      return false;
    }
  }

  // =================== REAL-TIME TRACKING ===================

  /// Get order tracking details
  static Future<Order?> getOrderDetails(String orderId) async {
    try {
      final response = await ApiService.get('/orders/$orderId');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return Order.fromJson(data['order'] ?? data);
      }
      return null;
    } catch (e) {
      LoggerService.error('Error fetching order details', error: e, tag: 'OrderService');
      return null;
    }
  }

  /// Update rider location for tracking
  static Future<bool> updateRiderLocation(
    double latitude, 
    double longitude, {
    String? orderId,
  }) async {
    try {
      String endpoint = orderId != null ? '/orders/$orderId/location' : '/rider/location';
      
      final response = await ApiService.patch(endpoint, {
        'latitude': latitude,
        'longitude': longitude,
        'timestamp': DateTime.now().toIso8601String(),
      });
      return response.statusCode == 200;
    } catch (e) {
      LoggerService.error('Error updating rider location', error: e, tag: 'OrderService');
      return false;
    }
  }

  /// Accept delivery assignment (Rider accepts delivery)
  static Future<bool> acceptDeliveryAssignment(String orderId) async {
    try {
      final response = await ApiService.patch('/orders/$orderId/accept-delivery', {
        'status': 'picked_up',
        'timestamp': DateTime.now().toIso8601String(),
        'notes': 'Rider accepted delivery assignment',
      });
      return response.statusCode == 200;
    } catch (e) {
      LoggerService.error('Error accepting delivery assignment', error: e, tag: 'OrderService');
      return false;
    }
  }

  // =================== ADMIN METHODS ===================

  /// Get all orders (Admin)
  static Future<List<Order>> getAllOrders({
    String? status,
    String? role,
    String? date,
    int page = 1,
    int limit = 50,
  }) async {
    try {
      String url = '/orders/admin/all?page=$page&limit=$limit';
      if (status != null && status != 'all') {
        url += '&status=$status';
      }
      if (role != null) {
        url += '&role=$role';
      }
      if (date != null) {
        url += '&date=$date';
      }

      final response = await ApiService.get(url);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final orders = data['orders'] ?? data['data'] ?? [];
        return orders.map<Order>((json) => Order.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      LoggerService.error('Error fetching all orders', error: e, tag: 'OrderService');
      return [];
    }
  }

  // =================== HELPER METHODS ===================

  /// Calculate delivery fee based on distance
  static double _calculateDeliveryFee(Map<String, double> coordinates) {
    // Simple calculation: base fee + distance-based fee
    // In production, this would be more sophisticated
    const baseFee = 50.0; // KES 50 base fee
    const perKmRate = 10.0; // KES 10 per km
    
    // Mock distance calculation (in production, use Google Maps API)
    final distance = 2.5; // km
    
    return baseFee + (distance * perKmRate);
  }

  /// Cancel order
  static Future<bool> cancelOrder(String orderId, {String? reason}) async {
    try {
      final response = await ApiService.patch('/orders/$orderId/cancel', {
        'status': 'cancelled',
        'reason': reason ?? 'Order cancelled by user',
        'timestamp': DateTime.now().toIso8601String(),
      });
      return response.statusCode == 200;
    } catch (e) {
      LoggerService.error('Error cancelling order', error: e, tag: 'OrderService');
      return false;
    }
  }

  /// Rate order
  static Future<bool> rateOrder(
    String orderId, {
    required int vendorRating,
    required int riderRating,
    int? connectorRating,
    String? comment,
  }) async {
    try {
      final response = await ApiService.post('/orders/$orderId/rating', {
        'vendorRating': vendorRating,
        'riderRating': riderRating,
        if (connectorRating != null) 'connectorRating': connectorRating,
        if (comment != null) 'comment': comment,
        'timestamp': DateTime.now().toIso8601String(),
      });
      return response.statusCode == 200;
    } catch (e) {
      LoggerService.error('Error rating order', error: e, tag: 'OrderService');
      return false;
    }
  }

  /// Get order analytics
  static Future<Map<String, dynamic>> getOrderAnalytics({
    String? period = 'month',
    String? userId,
  }) async {
    try {
      String url = '/orders/analytics?period=$period';
      if (userId != null) {
        url += '&userId=$userId';
      }

      final response = await ApiService.get(url);
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return {};
    } catch (e) {
      LoggerService.error('Error fetching order analytics', error: e, tag: 'OrderService');
      return {};
    }
  }

  // Reject order with reason (vendor only)
  static Future<bool> rejectOrder(String orderId, String reason) async {
    try {
      await ApiService.post('/orders/$orderId/reject', {
        'reason': reason,
        'timestamp': DateTime.now().toIso8601String(),
      });
      return true;
    } catch (e) {
      print('Error rejecting order: $e');
      return false;
    }
  }
} 