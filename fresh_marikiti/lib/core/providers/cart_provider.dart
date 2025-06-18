import 'package:flutter/material.dart';
import 'package:fresh_marikiti/core/models/product.dart';
import 'package:fresh_marikiti/core/models/cart_model.dart';
import 'package:fresh_marikiti/core/services/cart_service.dart';
import 'package:fresh_marikiti/core/services/logger_service.dart';
import 'dart:async';

class CartProvider extends ChangeNotifier {
  List<CartItem> _items = [];
  List<CartCoupon> _availableCoupons = [];
  CartCoupon? _appliedCoupon;
  
  bool _isLoading = false;
  String? _error;
  
  // Delivery options
  String _deliveryType = 'standard';
  DateTime? _scheduledDeliveryTime;
  String? _deliveryAddress;
  Map<String, dynamic>? _deliveryCoordinates;
  String? _specialInstructions;
  
  // Payment options
  String _paymentMethod = 'mpesa';
  String? _mpesaPhoneNumber;
  
  // Getters
  List<CartItem> get items => List.unmodifiable(_items);
  List<CartCoupon> get availableCoupons => List.unmodifiable(_availableCoupons);
  CartCoupon? get appliedCoupon => _appliedCoupon;
  bool get isLoading => _isLoading;
  String? get error => _error;
  
  // Cart calculations
  int get itemCount => _items.fold(0, (sum, item) => sum + item.quantity);
  double get subtotal => _items.fold(0.0, (sum, item) => sum + item.totalPrice);
  
  double get deliveryFee {
    switch (_deliveryType) {
      case 'express': return 150.0;
      case 'scheduled': return 100.0;
      default: return 50.0;
    }
  }
  
  double get discount => _appliedCoupon?.getDiscountAmount(subtotal) ?? 0.0;
  double get total => subtotal + deliveryFee - discount;
  
  bool get isEmpty => _items.isEmpty;
  bool get isNotEmpty => _items.isNotEmpty;
  bool get canCheckout => isNotEmpty && _deliveryAddress != null;
  
  // Delivery getters
  String get deliveryType => _deliveryType;
  DateTime? get scheduledDeliveryTime => _scheduledDeliveryTime;
  String? get deliveryAddress => _deliveryAddress;
  Map<String, dynamic>? get deliveryCoordinates => _deliveryCoordinates;
  String? get specialInstructions => _specialInstructions;
  
  // Payment getters
  String get paymentMethod => _paymentMethod;
  String? get mpesaPhoneNumber => _mpesaPhoneNumber;

  /// Initialize cart
  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      await loadCart();
      await loadAvailableCoupons();
      _error = null;
    } catch (e) {
      LoggerService.error('Cart initialization failed', error: e, tag: 'CartProvider');
      _error = 'Failed to initialize cart';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Load cart from backend
  Future<void> loadCart() async {
    try {
      final result = await CartService.getCart();
      if (result['success'] == true) {
        final cartItems = List<Map<String, dynamic>>.from(result['items'] ?? []);
        _items = cartItems.map((item) => CartItem.fromJson(item)).toList();
      } else {
        _items = [];
      }
      notifyListeners();
    } catch (e) {
      LoggerService.error('Failed to load cart', error: e, tag: 'CartProvider');
      _items = [];
    }
  }

  /// Add item to cart
  Future<void> addToCart(Product product, {int quantity = 1}) async {
    try {
      final result = await CartService.addToCart(
        productId: product.id,
        quantity: quantity,
      );
      
      if (result['success'] == true) {
        final existingIndex = _items.indexWhere((item) => item.product.id == product.id);
        
        if (existingIndex != -1) {
          _items[existingIndex] = _items[existingIndex].copyWith(
            quantity: _items[existingIndex].quantity + quantity
          );
        } else {
          _items.add(CartItem(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            product: product,
            quantity: quantity,
            addedAt: DateTime.now(),
          ));
        }
        notifyListeners();
      } else {
        _error = result['message'] ?? 'Failed to add item to cart';
        notifyListeners();
      }
    } catch (e) {
      _error = 'Failed to add item to cart';
      LoggerService.error('Add to cart failed', error: e, tag: 'CartProvider');
      notifyListeners();
    }
  }

  /// Update quantity
  Future<void> updateQuantity(String productId, int quantity) async {
    try {
      if (quantity <= 0) {
        await removeFromCart(productId);
        return;
      }
      
      final result = await CartService.updateCartItem(
        productId: productId,
        quantity: quantity,
      );
      
      if (result['success'] == true) {
        final index = _items.indexWhere((item) => item.product.id == productId);
        if (index != -1) {
          _items[index] = _items[index].copyWith(quantity: quantity);
          notifyListeners();
        }
      } else {
        _error = result['message'] ?? 'Failed to update quantity';
        notifyListeners();
      }
    } catch (e) {
      _error = 'Failed to update quantity';
      LoggerService.error('Update quantity failed', error: e, tag: 'CartProvider');
      notifyListeners();
    }
  }

  /// Remove item from cart
  Future<void> removeFromCart(String productId) async {
    try {
      final result = await CartService.removeFromCart(productId);
      if (result['success'] == true) {
        _items.removeWhere((item) => item.product.id == productId);
        notifyListeners();
      } else {
        _error = result['message'] ?? 'Failed to remove item';
        notifyListeners();
      }
    } catch (e) {
      _error = 'Failed to remove item';
      LoggerService.error('Remove from cart failed', error: e, tag: 'CartProvider');
      notifyListeners();
    }
  }

  /// Clear cart
  Future<void> clearCart() async {
    try {
      final result = await CartService.clearCart();
      if (result['success'] == true) {
        _items.clear();
        _appliedCoupon = null;
        notifyListeners();
      } else {
        _error = result['message'] ?? 'Failed to clear cart';
        notifyListeners();
      }
    } catch (e) {
      _error = 'Failed to clear cart';
      LoggerService.error('Clear cart failed', error: e, tag: 'CartProvider');
      notifyListeners();
    }
  }

  /// Load available coupons
  Future<void> loadAvailableCoupons() async {
    try {
      _availableCoupons = await CartService.getAvailableCoupons();
      notifyListeners();
    } catch (e) {
      LoggerService.error('Failed to load coupons', error: e, tag: 'CartProvider');
      _availableCoupons = [];
    }
  }

  /// Apply coupon
  Future<bool> applyCoupon(String couponCode) async {
    try {
      final result = await CartService.applyCoupon(
        couponCode: couponCode,
        cartTotal: subtotal,
      );
      
      if (result['success'] == true) {
        final coupon = _availableCoupons.firstWhere(
          (c) => c.code == couponCode,
          orElse: () => CartCoupon(
            id: couponCode,
            code: couponCode,
            title: 'Applied Coupon',
            description: 'Discount applied',
            type: 'percentage',
            value: 10.0,
            validFrom: DateTime.now(),
            validUntil: DateTime.now().add(const Duration(days: 30)),
            isActive: true,
          ),
        );
        _appliedCoupon = coupon;
        notifyListeners();
        return true;
      }
      _error = result['message'] ?? 'Failed to apply coupon';
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'Failed to apply coupon';
      LoggerService.error('Apply coupon failed', error: e, tag: 'CartProvider');
      notifyListeners();
      return false;
    }
  }

  /// Remove coupon
  void removeCoupon() {
    _appliedCoupon = null;
    notifyListeners();
  }

  /// Set delivery details
  void setDeliveryDetails({
    String? type,
    DateTime? scheduledTime,
    String? address,
    Map<String, dynamic>? coordinates,
    String? instructions,
  }) {
    if (type != null) _deliveryType = type;
    if (scheduledTime != null) _scheduledDeliveryTime = scheduledTime;
    if (address != null) _deliveryAddress = address;
    if (coordinates != null) _deliveryCoordinates = coordinates;
    if (instructions != null) _specialInstructions = instructions;
    notifyListeners();
  }

  /// Set payment details
  void setPaymentDetails({
    String? method,
    String? phoneNumber,
  }) {
    if (method != null) _paymentMethod = method;
    if (phoneNumber != null) _mpesaPhoneNumber = phoneNumber;
    notifyListeners();
  }

  /// Get item by product ID
  CartItem? getItemByProductId(String productId) {
    try {
      return _items.firstWhere((item) => item.product.id == productId);
    } catch (e) {
      return null;
    }
  }

  /// Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
} 