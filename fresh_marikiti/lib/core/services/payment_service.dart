import 'dart:convert';
import 'dart:async';
import 'package:fresh_marikiti/core/services/api_service.dart';
import 'package:fresh_marikiti/core/services/logger_service.dart';
import 'package:fresh_marikiti/core/services/socket_service.dart';
import 'package:fresh_marikiti/core/models/payment_model.dart';

class PaymentService {
  static const String _baseUrl = '/payments';
  
  // Cache for transaction status monitoring
  static final Map<String, Timer> _statusMonitors = {};
  static final Map<String, StreamController<PaymentTransaction>> _transactionStreams = {};

  // =================== M-PESA STK PUSH INTEGRATION ===================

  /// Initiate M-Pesa STK Push payment
  static Future<Map<String, dynamic>> initiateMpesaPayment({
    required String phoneNumber,
    required double amount,
    required String orderId,
    String? description,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      LoggerService.info('Initiating M-Pesa payment for order: $orderId', tag: 'PaymentService');

      // Validate phone number
      if (!_isValidMpesaPhoneNumber(phoneNumber)) {
        return {
          'success': false,
          'message': 'Invalid phone number format',
        };
      }

      // Calculate fees
      final feeCalculation = await calculateTransactionFee(
        amount: amount,
        paymentMethod: PaymentMethod.mpesa,
      );

      final requestData = {
        'phoneNumber': _formatMpesaPhoneNumber(phoneNumber),
        'amount': amount,
        'orderId': orderId,
        'description': description ?? 'Payment for order $orderId',
        'metadata': metadata ?? {},
        'feeCalculation': feeCalculation,
      };

      final response = await ApiService.post('$_baseUrl/mpesa/initiate', requestData);
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        
        if (data['success']) {
          final transaction = PaymentTransaction.fromJson(data['transaction']);
          
          // Start monitoring transaction status
          _startTransactionMonitoring(transaction.id);
          
          LoggerService.info('M-Pesa payment initiated successfully: ${transaction.id}', tag: 'PaymentService');
          
          return {
            'success': true,
            'transaction': transaction,
            'checkoutRequestId': data['checkoutRequestId'],
            'customerMessage': data['customerMessage'],
          };
        } else {
          return {
            'success': false,
            'message': data['message'] ?? 'Failed to initiate payment',
          };
        }
      } else {
        final error = json.decode(response.body);
        return {
          'success': false,
          'message': error['message'] ?? 'Payment initiation failed',
        };
      }
    } catch (e) {
      LoggerService.error('Error initiating M-Pesa payment', error: e, tag: 'PaymentService');
      return {
        'success': false,
        'message': 'Network error: Failed to initiate payment',
      };
    }
  }

  /// Check M-Pesa payment status
  static Future<PaymentTransaction?> checkPaymentStatus(String transactionId) async {
    try {
      final response = await ApiService.get('$_baseUrl/status/$transactionId');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return PaymentTransaction.fromJson(data['transaction']);
      }
      return null;
    } catch (e) {
      LoggerService.error('Error checking payment status', error: e, tag: 'PaymentService');
      return null;
    }
  }

  /// Get real-time transaction status stream
  static Stream<PaymentTransaction>? getTransactionStatusStream(String transactionId) {
    if (!_transactionStreams.containsKey(transactionId)) {
      _transactionStreams[transactionId] = StreamController<PaymentTransaction>.broadcast();
      _startTransactionMonitoring(transactionId);
    }
    return _transactionStreams[transactionId]?.stream;
  }

  /// Start monitoring transaction status
  static void _startTransactionMonitoring(String transactionId) {
    if (_statusMonitors.containsKey(transactionId)) return;

    _statusMonitors[transactionId] = Timer.periodic(
      const Duration(seconds: 5),
      (timer) async {
        final transaction = await checkPaymentStatus(transactionId);
        if (transaction != null) {
          _transactionStreams[transactionId]?.add(transaction);
          
          // Stop monitoring if transaction is complete
          if (transaction.isCompleted || transaction.isFailed || transaction.isCancelled) {
            timer.cancel();
            _statusMonitors.remove(transactionId);
            _transactionStreams[transactionId]?.close();
            _transactionStreams.remove(transactionId);
          }
        }
      },
    );
  }

  // =================== TRANSACTION MANAGEMENT ===================

  /// Get user's transaction history
  static Future<List<PaymentTransaction>> getTransactionHistory({
    int page = 1,
    int limit = 20,
    PaymentStatus? status,
    PaymentMethod? method,
    TransactionType? type,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final queryParams = <String>[];
      queryParams.add('page=$page');
      queryParams.add('limit=$limit');
      
      if (status != null) {
        queryParams.add('status=${status.toString().split('.').last}');
      }
      if (method != null) {
        queryParams.add('method=${method.toString().split('.').last}');
      }
      if (type != null) {
        queryParams.add('type=${type.toString().split('.').last}');
      }
      if (startDate != null) {
        queryParams.add('startDate=${startDate.toIso8601String()}');
      }
      if (endDate != null) {
        queryParams.add('endDate=${endDate.toIso8601String()}');
      }

      final url = '$_baseUrl/history?${queryParams.join('&')}';
      final response = await ApiService.get(url);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final transactions = data['transactions'] ?? data['data'] ?? [];
        return transactions.map<PaymentTransaction>((json) => PaymentTransaction.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      LoggerService.error('Error fetching transaction history', error: e, tag: 'PaymentService');
      return [];
    }
  }

  /// Get transaction details by ID
  static Future<PaymentTransaction?> getTransactionDetails(String transactionId) async {
    try {
      final response = await ApiService.get('$_baseUrl/transaction/$transactionId');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return PaymentTransaction.fromJson(data['transaction']);
      }
      return null;
    } catch (e) {
      LoggerService.error('Error fetching transaction details', error: e, tag: 'PaymentService');
      return null;
    }
  }

  // =================== FEE CALCULATION ===================

  /// Calculate transaction fees
  static Future<PaymentFee> calculateTransactionFee({
    required double amount,
    required PaymentMethod paymentMethod,
  }) async {
    try {
      final requestData = {
        'amount': amount,
        'paymentMethod': paymentMethod.toString().split('.').last,
      };

      final response = await ApiService.post('$_baseUrl/calculate-fee', requestData);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return PaymentFee.fromJson(data['fee']);
      } else {
        // Fallback calculation if API fails
        return _calculateFeeOffline(amount, paymentMethod);
      }
    } catch (e) {
      LoggerService.error('Error calculating transaction fee', error: e, tag: 'PaymentService');
      return _calculateFeeOffline(amount, paymentMethod);
    }
  }

  /// Offline fee calculation fallback
  static PaymentFee _calculateFeeOffline(double amount, PaymentMethod method) {
    double feeAmount = 0.0;
    String description = '';

    switch (method) {
      case PaymentMethod.mpesa:
        // M-Pesa fee structure (simplified)
        if (amount <= 100) {
          feeAmount = 0.0;
        } else if (amount <= 500) {
          feeAmount = 7.0;
        } else if (amount <= 1000) {
          feeAmount = 13.0;
        } else if (amount <= 1500) {
          feeAmount = 23.0;
        } else if (amount <= 2500) {
          feeAmount = 33.0;
        } else if (amount <= 3500) {
          feeAmount = 53.0;
        } else if (amount <= 5000) {
          feeAmount = 57.0;
        } else {
          feeAmount = amount * 0.015; // 1.5% for higher amounts
        }
        description = 'M-Pesa transaction fee';
        break;
      
      case PaymentMethod.card:
        feeAmount = amount * 0.025; // 2.5% for card payments
        description = 'Card processing fee';
        break;
        
      case PaymentMethod.cash:
        feeAmount = 0.0;
        description = 'No fee for cash payments';
        break;
        
      case PaymentMethod.wallet:
        feeAmount = 0.0;
        description = 'No fee for wallet payments';
        break;
    }

    return PaymentFee(
      amount: amount,
      feeAmount: feeAmount,
      totalAmount: amount + feeAmount,
      description: description,
      breakdown: {
        'baseFee': feeAmount,
        'taxAmount': 0.0,
        'processingFee': 0.0,
      },
    );
  }

  // =================== REFUND MANAGEMENT ===================

  /// Request refund
  static Future<Map<String, dynamic>> requestRefund({
    required String transactionId,
    required double amount,
    required String reason,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final requestData = {
        'transactionId': transactionId,
        'amount': amount,
        'reason': reason,
        'metadata': metadata ?? {},
        'timestamp': DateTime.now().toIso8601String(),
      };

      final response = await ApiService.post('$_baseUrl/refund/request', requestData);
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        return {
          'success': true,
          'refundRequest': RefundRequest.fromJson(data['refundRequest']),
        };
      } else {
        final error = json.decode(response.body);
        return {
          'success': false,
          'message': error['message'] ?? 'Failed to request refund',
        };
      }
    } catch (e) {
      LoggerService.error('Error requesting refund', error: e, tag: 'PaymentService');
      return {
        'success': false,
        'message': 'Network error: Failed to request refund',
      };
    }
  }

  /// Get refund requests
  static Future<List<RefundRequest>> getRefundRequests({
    int page = 1,
    int limit = 20,
    String? status,
  }) async {
    try {
      String url = '$_baseUrl/refund/requests?page=$page&limit=$limit';
      if (status != null) {
        url += '&status=$status';
      }

      final response = await ApiService.get(url);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final requests = data['refundRequests'] ?? data['data'] ?? [];
        return requests.map<RefundRequest>((json) => RefundRequest.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      LoggerService.error('Error fetching refund requests', error: e, tag: 'PaymentService');
      return [];
    }
  }

  /// Cancel transaction (before completion)
  static Future<Map<String, dynamic>> cancelTransaction({
    required String transactionId,
    required String reason,
  }) async {
    try {
      final requestData = {
        'transactionId': transactionId,
        'reason': reason,
        'timestamp': DateTime.now().toIso8601String(),
      };

      final response = await ApiService.post('$_baseUrl/cancel', requestData);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'success': true,
          'message': data['message'] ?? 'Transaction cancelled successfully',
        };
      } else {
        final error = json.decode(response.body);
        return {
          'success': false,
          'message': error['message'] ?? 'Failed to cancel transaction',
        };
      }
    } catch (e) {
      LoggerService.error('Error cancelling transaction', error: e, tag: 'PaymentService');
      return {
        'success': false,
        'message': 'Network error: Failed to cancel transaction',
      };
    }
  }

  // =================== PAYMENT ANALYTICS ===================

  /// Get payment analytics
  static Future<PaymentAnalytics?> getPaymentAnalytics({
    DateTime? startDate,
    DateTime? endDate,
    String? groupBy = 'day', // day, week, month
  }) async {
    try {
      final queryParams = <String>[];
      if (startDate != null) {
        queryParams.add('startDate=${startDate.toIso8601String()}');
      }
      if (endDate != null) {
        queryParams.add('endDate=${endDate.toIso8601String()}');
      }
      if (groupBy != null) {
        queryParams.add('groupBy=$groupBy');
      }

      final url = '$_baseUrl/analytics?${queryParams.join('&')}';
      final response = await ApiService.get(url);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return PaymentAnalytics.fromJson(data['analytics']);
      }
      return null;
    } catch (e) {
      LoggerService.error('Error fetching payment analytics', error: e, tag: 'PaymentService');
      return null;
    }
  }

  // =================== RECEIPT MANAGEMENT ===================

  /// Get payment receipt
  static Future<Map<String, dynamic>?> getPaymentReceipt(String transactionId) async {
    try {
      final response = await ApiService.get('$_baseUrl/receipt/$transactionId');
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return null;
    } catch (e) {
      LoggerService.error('Error fetching payment receipt', error: e, tag: 'PaymentService');
      return null;
    }
  }

  /// Send receipt via email or SMS
  static Future<bool> sendReceipt({
    required String transactionId,
    String? email,
    String? phoneNumber,
  }) async {
    try {
      final requestData = {
        'transactionId': transactionId,
        'email': email,
        'phoneNumber': phoneNumber,
      };

      final response = await ApiService.post('$_baseUrl/receipt/send', requestData);
      return response.statusCode == 200;
    } catch (e) {
      LoggerService.error('Error sending receipt', error: e, tag: 'PaymentService');
      return false;
    }
  }

  // =================== PAYMENT METHODS ===================

  /// Get supported payment methods
  static Future<List<Map<String, dynamic>>> getSupportedPaymentMethods() async {
    try {
      final response = await ApiService.get('$_baseUrl/methods');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return List<Map<String, dynamic>>.from(data['methods'] ?? []);
      }
      return [];
    } catch (e) {
      LoggerService.error('Error fetching payment methods', error: e, tag: 'PaymentService');
      return [];
    }
  }

  // =================== UTILITY METHODS ===================

  /// Validate M-Pesa phone number (public method)
  static bool isValidMpesaPhoneNumber(String phoneNumber) {
    return _isValidMpesaPhoneNumber(phoneNumber);
  }

  /// Validate M-Pesa phone number
  static bool _isValidMpesaPhoneNumber(String phoneNumber) {
    final cleanNumber = phoneNumber.replaceAll(RegExp(r'[^\d]'), '');
    
    // Check Kenyan mobile number formats
    if (cleanNumber.length == 10 && cleanNumber.startsWith('07')) {
      return true;
    } else if (cleanNumber.length == 12 && cleanNumber.startsWith('254')) {
      return true;
    } else if (cleanNumber.length == 13 && cleanNumber.startsWith('+254')) {
      return true;
    }
    
    return false;
  }

  /// Format phone number for M-Pesa
  static String _formatMpesaPhoneNumber(String phoneNumber) {
    String cleanNumber = phoneNumber.replaceAll(RegExp(r'[^\d]'), '');
    
    if (cleanNumber.startsWith('0') && cleanNumber.length == 10) {
      return '254${cleanNumber.substring(1)}';
    } else if (cleanNumber.startsWith('254') && cleanNumber.length == 12) {
      return cleanNumber;
    }
    
    throw ArgumentError('Invalid phone number format: $phoneNumber');
  }

  /// Validate payment amount
  static bool isValidPaymentAmount(double amount) {
    return amount > 0 && amount <= 300000; // M-Pesa daily limit
  }

  /// Get payment method icon
  static String getPaymentMethodIcon(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.mpesa:
        return '📱';
      case PaymentMethod.card:
        return '💳';
      case PaymentMethod.cash:
        return '💵';
      case PaymentMethod.wallet:
        return '👛';
    }
  }

  /// Get payment status color
  static String getPaymentStatusColor(PaymentStatus status) {
    switch (status) {
      case PaymentStatus.completed:
        return '#4CAF50'; // Green
      case PaymentStatus.pending:
      case PaymentStatus.processing:
        return '#FF9800'; // Orange
      case PaymentStatus.failed:
      case PaymentStatus.cancelled:
      case PaymentStatus.expired:
        return '#F44336'; // Red
      case PaymentStatus.refunded:
        return '#9C27B0'; // Purple
    }
  }

  // =================== REAL-TIME NOTIFICATIONS ===================

  /// Setup real-time payment notifications
  static void setupPaymentNotifications() {
    final socketService = SocketService.instance;
    
    socketService.addEventListener('payment_status_update', (data) {
      final transactionId = data['transactionId'];
      final transaction = PaymentTransaction.fromJson(data['transaction']);
      
      // Update stream if monitoring
      if (_transactionStreams.containsKey(transactionId)) {
        _transactionStreams[transactionId]?.add(transaction);
      }
      
      LoggerService.info('Payment status updated: $transactionId -> ${transaction.status}', tag: 'PaymentService');
    });

    socketService.addEventListener('payment_completed', (data) {
      final transaction = PaymentTransaction.fromJson(data['transaction']);
      LoggerService.info('Payment completed: ${transaction.id}', tag: 'PaymentService');
    });

    socketService.addEventListener('payment_failed', (data) {
      final transaction = PaymentTransaction.fromJson(data['transaction']);
      LoggerService.warning('Payment failed: ${transaction.id} - ${transaction.failureReason}', tag: 'PaymentService');
    });
  }

  /// Cleanup resources
  static void dispose() {
    for (final timer in _statusMonitors.values) {
      timer.cancel();
    }
    _statusMonitors.clear();
    
    for (final controller in _transactionStreams.values) {
      controller.close();
    }
    _transactionStreams.clear();
  }
} 