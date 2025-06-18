import 'dart:convert';
import 'package:fresh_marikiti/core/models/support_models.dart';
import 'package:fresh_marikiti/core/services/api_service.dart';
import 'package:fresh_marikiti/core/services/logger_service.dart';

class SupportService {
  static const String _baseUrl = '/support';

  // Get FAQs by category
  static Future<List<FAQ>> getFAQs({String? category}) async {
    try {
      final queryParams = <String>[];
      if (category != null && category != 'general') {
        queryParams.add('category=$category');
      }

      final endpoint = queryParams.isNotEmpty 
          ? '$_baseUrl/faqs?${queryParams.join('&')}'
          : '$_baseUrl/faqs';

      final response = await ApiService.get(endpoint);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return (data['data'] as List? ?? [])
            .map((faqJson) => FAQ.fromJson(faqJson))
            .toList();
      } else {
        throw Exception('Failed to fetch FAQs: ${response.statusCode}');
      }
    } catch (e) {
      LoggerService.error('Failed to fetch FAQs', error: e, tag: 'SupportService');
      throw Exception('Failed to fetch FAQs: $e');
    }
  }

  // Submit support request
  static Future<SupportTicket> submitSupportRequest({
    required String category,
    required String subject,
    required String message,
    List<String>? attachments,
  }) async {
    try {
      final requestBody = {
        'category': category,
        'subject': subject,
        'message': message,
        if (attachments != null) 'attachments': attachments,
      };

      final response = await ApiService.post('$_baseUrl/tickets', requestBody);
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        return SupportTicket.fromJson(data['data'] ?? data);
      } else {
        throw Exception('Failed to submit support request: ${response.statusCode}');
      }
    } catch (e) {
      LoggerService.error('Failed to submit support request', error: e, tag: 'SupportService');
      throw Exception('Failed to submit support request: $e');
    }
  }

  // Get user's support tickets
  static Future<List<SupportTicket>> getUserTickets({
    int page = 1,
    int limit = 20,
    String? status,
  }) async {
    try {
      final queryParams = <String>[];
      queryParams.add('page=$page');
      queryParams.add('limit=$limit');
      if (status != null) {
        queryParams.add('status=$status');
      }

      final endpoint = '$_baseUrl/tickets/my?${queryParams.join('&')}';
      final response = await ApiService.get(endpoint);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return (data['data'] as List? ?? [])
            .map((ticketJson) => SupportTicket.fromJson(ticketJson))
            .toList();
      } else {
        throw Exception('Failed to fetch support tickets: ${response.statusCode}');
      }
    } catch (e) {
      LoggerService.error('Failed to fetch support tickets', error: e, tag: 'SupportService');
      throw Exception('Failed to fetch support tickets: $e');
    }
  }

  // Get ticket details and conversation
  static Future<SupportTicketDetails> getTicketDetails(String ticketId) async {
    try {
      final response = await ApiService.get('$_baseUrl/tickets/$ticketId');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return SupportTicketDetails.fromJson(data['data'] ?? data);
      } else {
        throw Exception('Failed to fetch ticket details: ${response.statusCode}');
      }
    } catch (e) {
      LoggerService.error('Failed to fetch ticket details', error: e, tag: 'SupportService');
      throw Exception('Failed to fetch ticket details: $e');
    }
  }

  // Reply to a support ticket
  static Future<SupportMessage> replyToTicket({
    required String ticketId,
    required String message,
    List<String>? attachments,
  }) async {
    try {
      final requestBody = {
        'message': message,
        if (attachments != null) 'attachments': attachments,
      };

      final response = await ApiService.post('$_baseUrl/tickets/$ticketId/reply', requestBody);
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        return SupportMessage.fromJson(data['data'] ?? data);
      } else {
        throw Exception('Failed to reply to ticket: ${response.statusCode}');
      }
    } catch (e) {
      LoggerService.error('Failed to reply to ticket', error: e, tag: 'SupportService');
      throw Exception('Failed to reply to ticket: $e');
    }
  }

  // Rate support interaction
  static Future<void> rateSupport({
    required String ticketId,
    required int rating,
    String? feedback,
  }) async {
    try {
      final requestBody = {
        'rating': rating,
        if (feedback != null) 'feedback': feedback,
      };

      final response = await ApiService.post('$_baseUrl/tickets/$ticketId/rate', requestBody);
      
      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception('Failed to rate support: ${response.statusCode}');
      }
    } catch (e) {
      LoggerService.error('Failed to rate support', error: e, tag: 'SupportService');
      throw Exception('Failed to rate support: $e');
    }
  }

  // Get support categories
  static Future<List<SupportCategory>> getSupportCategories() async {
    try {
      final response = await ApiService.get('$_baseUrl/categories');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return (data['data'] as List? ?? [])
            .map((categoryJson) => SupportCategory.fromJson(categoryJson))
            .toList();
      } else {
        throw Exception('Failed to fetch support categories: ${response.statusCode}');
      }
    } catch (e) {
      LoggerService.error('Failed to fetch support categories', error: e, tag: 'SupportService');
      throw Exception('Failed to fetch support categories: $e');
    }
  }

  // Upload attachment for support
  static Future<String> uploadSupportAttachment(String filePath) async {
    try {
      final response = await ApiService.uploadFile(
        '$_baseUrl/attachments',
        filePath,
        'attachment',
      );
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        return data['url'] ?? data['data']['url'];
      } else {
        throw Exception('Failed to upload attachment: ${response.statusCode}');
      }
    } catch (e) {
      LoggerService.error('Failed to upload support attachment', error: e, tag: 'SupportService');
      throw Exception('Failed to upload attachment: $e');
    }
  }

  // Get support statistics (for admin)
  static Future<Map<String, dynamic>> getSupportStatistics() async {
    try {
      final response = await ApiService.get('$_baseUrl/statistics');
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to fetch support statistics: ${response.statusCode}');
      }
    } catch (e) {
      LoggerService.error('Failed to fetch support statistics', error: e, tag: 'SupportService');
      throw Exception('Failed to fetch support statistics: $e');
    }
  }
} 