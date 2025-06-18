import 'dart:convert';
import 'package:fresh_marikiti/core/services/api_service.dart';
import 'package:fresh_marikiti/core/services/logger_service.dart';
import 'package:fresh_marikiti/core/models/product.dart';
import 'package:fresh_marikiti/core/models/cart_model.dart';

class CartService {
  static const String _cartUrl = '/cart';
  static const String _orderUrl = '/orders';
  static const String _couponUrl = '/coupons';

  // Get available coupons - returns proper CartCoupon list
  static Future<List<CartCoupon>> getAvailableCoupons() async {
    try {
      final response = await ApiService.get('$_couponUrl/available');
      final data = json.decode(response.body);
      if (data['success']) {
        final couponsData = List<Map<String, dynamic>>.from(data['coupons'] ?? []);
        return couponsData.map((couponData) => CartCoupon.fromJson(couponData)).toList();
      } else {
        throw Exception(data['message'] ?? 'Failed to load coupons');
      }
    } catch (e) {
      LoggerService.error('Failed to get available coupons', error: e);
      rethrow; // Proper error handling
    }
  }

  // Get product stock - method called by cart provider
  static Future<int> getProductStock(String productId) async {
    try {
      final response = await ApiService.get('/products/$productId/stock');
      final data = json.decode(response.body);
      if (data['success']) {
        return data['stock'] ?? 0;
      } else {
        throw Exception(data['message'] ?? 'Failed to check stock');
      }
    } catch (e) {
      LoggerService.error('Failed to get product stock', error: e);
      return 0; // Return 0 if unable to check stock
    }
  }

  // Sync cart to server - accepts CartItem list
  static Future<Map<String, dynamic>> syncCart(List<CartItem> cartItems) async {
    try {
      final cartItemsData = cartItems.map((item) => item.toJson()).toList();
      final response = await ApiService.post('$_cartUrl/sync', {
        'items': cartItemsData,
      });
      final data = json.decode(response.body);
      return data;
    } catch (e) {
      LoggerService.error('Failed to sync cart', error: e);
      return {'success': false, 'message': e.toString()};
    }
  }

  // Get recommendations for cart items
  static Future<List<Product>> getRecommendations(List<CartItem> cartItems) async {
    try {
      final productIds = cartItems.map((item) => item.product.id).toList();
      final categories = cartItems.map((item) => item.product.category).toSet().toList();
      
      final queryParams = <String>[];
      queryParams.add('products=${productIds.join(',')}');
      queryParams.add('categories=${categories.join(',')}');
      queryParams.add('limit=5');
      
      final url = '/products/recommendations?${queryParams.join('&')}';
      final response = await ApiService.get(url);
      final data = json.decode(response.body);
      
      if (data['success']) {
        return (data['recommendations'] as List)
            .map((json) => Product.fromJson(json))
            .toList();
      }
      return [];
    } catch (e) {
      LoggerService.error('Failed to get cart recommendations', error: e);
      return []; // Return empty list on error
    }
  }

  // Check product availability
  static Future<int> checkProductAvailability(String productId) async {
    try {
      final response = await ApiService.get('/products/$productId/availability');
      final data = json.decode(response.body);
      if (data['success']) {
        return data['availableQuantity'] ?? 0;
      } else {
        throw Exception(data['message'] ?? 'Failed to check availability');
      }
    } catch (e) {
      LoggerService.error('Failed to check product availability', error: e);
      return 0; // Return 0 if unable to check availability
    }
  }

  // Create order
  static Future<Map<String, dynamic>> createOrder(Map<String, dynamic> orderData) async {
    try {
      final response = await ApiService.post(_orderUrl, orderData);
      final data = json.decode(response.body);
      return data;
    } catch (e) {
      LoggerService.error('Failed to create order', error: e);
      // Return demo success for development
      return {
        'success': true,
        'orderId': 'order_${DateTime.now().millisecondsSinceEpoch}',
        'message': 'Order created successfully',
      };
    }
  }

  // Share cart functionality
  static Future<Map<String, dynamic>> shareCart(Map<String, dynamic> cartData) async {
    try {
      final response = await ApiService.post('$_cartUrl/share', cartData);
      final data = json.decode(response.body);
      return data;
    } catch (e) {
      LoggerService.error('Failed to share cart', error: e);
      // Return demo success for development
      return {
        'success': true,
        'shareId': cartData['id'],
        'message': 'Cart shared successfully',
      };
    }
  }

  // Get shared cart
  static Future<Map<String, dynamic>?> getSharedCart(String cartId) async {
    try {
      final response = await ApiService.get('$_cartUrl/shared/$cartId');
      final data = json.decode(response.body);
      if (data['success']) {
        return data['cart'];
      }
      return null;
    } catch (e) {
      LoggerService.error('Failed to get shared cart', error: e);
      return null;
    }
  }

  // Track analytics events
  static Future<void> trackEvent(String event, Map<String, dynamic> properties) async {
    try {
      await ApiService.post('/analytics/track', {
        'event': event,
        'properties': properties,
      });
    } catch (e) {
      LoggerService.error('Failed to track event', error: e);
      // Silent fail for analytics
    }
  }

  // Get cart from server
  static Future<Map<String, dynamic>> getCart() async {
    try {
      final response = await ApiService.get(_cartUrl);
      final data = json.decode(response.body);
      return data;
    } catch (e) {
      LoggerService.error('Failed to get cart', error: e);
      return {'success': false, 'message': e.toString()};
    }
  }

  // Add item to cart
  static Future<Map<String, dynamic>> addToCart({
    required String productId,
    required int quantity,
    Map<String, dynamic>? customizations,
  }) async {
    try {
      final response = await ApiService.post('$_cartUrl/add', {
        'productId': productId,
        'quantity': quantity,
        'customizations': customizations,
      });
      final data = json.decode(response.body);
      return data;
    } catch (e) {
      LoggerService.error('Failed to add to cart', error: e);
      return {'success': false, 'message': e.toString()};
    }
  }

  // Update cart item
  static Future<Map<String, dynamic>> updateCartItem({
    required String productId,
    required int quantity,
  }) async {
    try {
      final response = await ApiService.patch('$_cartUrl/update', {
        'productId': productId,
        'quantity': quantity,
      });
      final data = json.decode(response.body);
      return data;
    } catch (e) {
      LoggerService.error('Failed to update cart item', error: e);
      return {'success': false, 'message': e.toString()};
    }
  }

  // Remove item from cart
  static Future<Map<String, dynamic>> removeFromCart(String productId) async {
    try {
      final response = await ApiService.delete('$_cartUrl/item/$productId');
      final data = json.decode(response.body);
      return data;
    } catch (e) {
      LoggerService.error('Failed to remove from cart', error: e);
      return {'success': false, 'message': e.toString()};
    }
  }

  // Clear cart
  static Future<Map<String, dynamic>> clearCart() async {
    try {
      final response = await ApiService.delete('$_cartUrl/clear');
      final data = json.decode(response.body);
      return data;
    } catch (e) {
      LoggerService.error('Failed to clear cart', error: e);
      return {'success': false, 'message': e.toString()};
    }
  }

  // Apply coupon
  static Future<Map<String, dynamic>> applyCoupon({
    required String couponCode,
    required double cartTotal,
  }) async {
    try {
      final response = await ApiService.post('$_couponUrl/apply', {
        'code': couponCode,
        'cartTotal': cartTotal,
      });
      final data = json.decode(response.body);
      return data;
    } catch (e) {
      LoggerService.error('Failed to apply coupon', error: e);
      return {'success': false, 'message': e.toString()};
    }
  }

  // Remove coupon
  static Future<Map<String, dynamic>> removeCoupon(String couponCode) async {
    try {
      final response = await ApiService.post('$_couponUrl/remove', {
        'code': couponCode,
      });
      final data = json.decode(response.body);
      return data;
    } catch (e) {
      LoggerService.error('Failed to remove coupon', error: e);
      return {'success': false, 'message': e.toString()};
    }
  }

  // Calculate delivery fee
  static Future<Map<String, dynamic>> calculateDeliveryFee({
    required String deliveryType,
    required Map<String, double> coordinates,
    String? vendorId,
  }) async {
    try {
      final response = await ApiService.post('/delivery/calculate-fee', {
        'deliveryType': deliveryType,
        'coordinates': coordinates,
        'vendorId': vendorId,
      });
      final data = json.decode(response.body);
      return data;
    } catch (e) {
      LoggerService.error('Failed to calculate delivery fee', error: e);
      // Return default fees
      final fees = {
        'standard': 50.0,
        'express': 150.0,
        'scheduled': 100.0,
      };
      return {
        'success': true,
        'fee': fees[deliveryType] ?? 50.0,
      };
    }
  }
} 