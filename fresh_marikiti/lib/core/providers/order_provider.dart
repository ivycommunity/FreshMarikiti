import 'package:flutter/material.dart';
import 'package:fresh_marikiti/core/models/order_model.dart';
import 'package:fresh_marikiti/core/models/cart_model.dart';
import 'package:fresh_marikiti/core/services/order_service.dart';
import 'package:fresh_marikiti/core/services/logger_service.dart';
import 'dart:async';

class OrderProvider with ChangeNotifier {
  List<Order> _orders = [];
  List<Order> _activeOrders = [];
  Order? _currentOrder;
  
  bool _isLoading = false;
  bool _isPlacingOrder = false;
  bool _isUpdatingStatus = false;
  String? _error;
  
  // Order filters
  String _statusFilter = 'all';
  DateTime? _dateFilter;
  
  // Pagination
  int _currentPage = 1;
  int _totalPages = 1;
  bool _hasMoreOrders = true;

  // Getters
  List<Order> get orders => List.unmodifiable(_orders);
  List<Order> get activeOrders => List.unmodifiable(_activeOrders);
  Order? get currentOrder => _currentOrder;
  
  bool get isLoading => _isLoading;
  bool get isPlacingOrder => _isPlacingOrder;
  bool get isUpdatingStatus => _isUpdatingStatus;
  String? get error => _error;
  
  String get statusFilter => _statusFilter;
  DateTime? get dateFilter => _dateFilter;
  
  int get currentPage => _currentPage;
  int get totalPages => _totalPages;
  bool get hasMoreOrders => _hasMoreOrders;

  // Initialize provider
  Future<void> initialize() async {
    await loadOrders();
    await loadActiveOrders();
  }

  // Load user orders
  Future<void> loadOrders({bool refresh = false}) async {
    if (refresh || _orders.isEmpty) {
      _isLoading = true;
      _error = null;
      notifyListeners();
      
      try {
        final orders = await OrderService.getCustomerOrders(page: _currentPage);
        _orders = orders;
        _totalPages = 1; // Simplified for now
        _error = null;
      } catch (e) {
        LoggerService.error('Error loading orders', error: e, tag: 'OrderProvider');
        _error = e.toString();
        _orders = [];
      } finally {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  // Load active orders (in progress)
  Future<void> loadActiveOrders() async {
    try {
      _activeOrders = _orders.where((order) => 
          order.status != OrderStatus.delivered && 
          order.status != OrderStatus.cancelled
      ).toList();
      notifyListeners();
    } catch (e) {
      LoggerService.error('Failed to load active orders', error: e, tag: 'OrderProvider');
    }
  }

  // Place new order
  Future<bool> placeOrder({
    required List<CartItem> cartItems,
    required String deliveryAddress,
    required String phoneNumber,
    required Map<String, double> deliveryCoordinates,
    String? specialInstructions,
  }) async {
    _isPlacingOrder = true;
    _error = null;
    notifyListeners();

    try {
      final result = await OrderService.placeOrder(
        cartItems: cartItems,
        deliveryAddress: deliveryAddress,
        phoneNumber: phoneNumber,
        deliveryCoordinates: deliveryCoordinates,
        specialInstructions: specialInstructions,
      );

      if (result['success'] == true) {
        final newOrder = Order.fromJson(result['order']);
        _orders.insert(0, newOrder);
        _activeOrders.add(newOrder);
        _currentOrder = newOrder;
        notifyListeners();
        return true;
      } else {
        _error = result['message'] ?? 'Failed to place order';
        notifyListeners();
        return false;
      }
    } catch (e) {
      LoggerService.error('Failed to place order', error: e, tag: 'OrderProvider');
      _error = 'Failed to place order: ${e.toString()}';
      notifyListeners();
      return false;
    } finally {
      _isPlacingOrder = false;
      notifyListeners();
    }
  }

  // Update order status
  Future<bool> updateOrderStatus(String orderId, String status) async {
    try {
      // For now, just update locally until backend methods are confirmed
      final orderIndex = _orders.indexWhere((order) => order.id == orderId);
      if (orderIndex != -1) {
        _orders[orderIndex] = _orders[orderIndex].copyWith(status: parseOrderStatus(status));
      }
      
      final activeOrderIndex = _activeOrders.indexWhere((order) => order.id == orderId);
      if (activeOrderIndex != -1) {
        _activeOrders[activeOrderIndex] = _activeOrders[activeOrderIndex].copyWith(status: parseOrderStatus(status));
        
        // Remove from active orders if completed or cancelled
        final statusEnum = parseOrderStatus(status);
        if (statusEnum == OrderStatus.delivered || statusEnum == OrderStatus.cancelled) {
          _activeOrders.removeAt(activeOrderIndex);
        }
      }
      
      if (_currentOrder?.id == orderId) {
        _currentOrder = _currentOrder!.copyWith(status: parseOrderStatus(status));
      }
      
      notifyListeners();
      return true;
    } catch (e) {
      LoggerService.error('Failed to update order status', error: e, tag: 'OrderProvider');
      return false;
    }
  }

  // Cancel order
  Future<bool> cancelOrder(String orderId, {String? reason}) async {
    try {
      // For now, just update locally
      await updateOrderStatus(orderId, 'cancelled');
      return true;
    } catch (e) {
      LoggerService.error('Failed to cancel order', error: e, tag: 'OrderProvider');
      return false;
    }
  }

  // Get order details
  Future<Order?> getOrderDetails(String orderId) async {
    try {
      // Try to find in local orders first
      final localOrder = getOrderById(orderId);
      if (localOrder != null) {
        return localOrder;
      }
      
      // For now, return null if not found locally
      // In future, implement API call to get order details
      return null;
    } catch (e) {
      LoggerService.error('Failed to get order details', error: e);
      return null;
    }
  }

  // Set current order
  void setCurrentOrder(Order order) {
    _currentOrder = order;
    notifyListeners();
  }

  // Clear current order
  void clearCurrentOrder() {
    _currentOrder = null;
    notifyListeners();
  }

  // Filter methods
  void setStatusFilter(String status) {
    _statusFilter = status;
    _currentPage = 1;
    loadOrders(refresh: true);
  }

  void setDateFilter(DateTime? date) {
    _dateFilter = date;
    _currentPage = 1;
    loadOrders(refresh: true);
  }

  void clearFilters() {
    _statusFilter = 'all';
    _dateFilter = null;
    _currentPage = 1;
    loadOrders(refresh: true);
  }

  // Load more orders (pagination)
  Future<void> loadMoreOrders() async {
    if (!_hasMoreOrders || _isLoading) return;
    
    _isLoading = true;
    notifyListeners();
    
    try {
      _currentPage++;
      final newOrders = await OrderService.getCustomerOrders(page: _currentPage);
      
      _orders.addAll(newOrders);
      _hasMoreOrders = newOrders.isNotEmpty;
    } catch (e) {
      _currentPage--; // Revert on error
      LoggerService.error('Failed to load more orders', error: e, tag: 'OrderProvider');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Get order by ID
  Order? getOrderById(String id) {
    try {
      return _orders.firstWhere((order) => order.id == id);
    } catch (e) {
      return null;
    }
  }

  // Get orders by status
  List<Order> getOrdersByStatus(String status) {
    final statusEnum = parseOrderStatus(status);
    return _orders.where((order) => order.status == statusEnum).toList();
  }

  // Get order statistics
  Map<String, dynamic> getOrderStatistics() {
    final totalOrders = _orders.length;
    final completedOrders = _orders.where((o) => o.status == OrderStatus.delivered).length;
    final cancelledOrders = _orders.where((o) => o.status == OrderStatus.cancelled).length;
    final activeOrdersCount = _activeOrders.length;
    
    final totalSpent = _orders
        .where((o) => o.status == OrderStatus.delivered)
        .fold(0.0, (sum, order) => sum + order.total);
    
    return {
      'totalOrders': totalOrders,
      'completedOrders': completedOrders,
      'cancelledOrders': cancelledOrders,
      'activeOrders': activeOrdersCount,
      'totalSpent': totalSpent,
      'averageOrderValue': completedOrders > 0 ? totalSpent / completedOrders : 0.0,
    };
  }

  // Refresh all data
  Future<void> refresh() async {
    _currentPage = 1;
    _hasMoreOrders = true;
    await loadOrders(refresh: true);
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
} 