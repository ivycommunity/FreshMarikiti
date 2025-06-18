import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:fresh_marikiti/core/services/storage_service.dart';
import 'package:fresh_marikiti/core/services/logger_service.dart';

class ApiService {
  static String get baseUrl => dotenv.env['API_BASE_URL'] ?? 'http://10.0.2.2:5000/api';
  static String get wsUrl => dotenv.env['WS_BASE_URL'] ?? 'ws://10.0.2.2:5000';
  static Duration get timeout => Duration(milliseconds: int.tryParse(dotenv.env['API_TIMEOUT'] ?? '') ?? 30000);
  static int get maxRetries => int.tryParse(dotenv.env['MAX_RETRIES'] ?? '') ?? 3;

  // Get authenticated headers
  static Future<Map<String, String>> _getHeaders({
    bool includeAuth = true,
    Map<String, String>? additionalHeaders,
  }) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'X-Client-Version': dotenv.env['APP_VERSION'] ?? '1.0.0',
      'X-Platform': Platform.isAndroid ? 'android' : 'ios',
      'X-Environment': dotenv.env['ENVIRONMENT'] ?? 'development',
    };

    if (includeAuth) {
      final token = await StorageService.getToken();
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }
    }

    if (additionalHeaders != null) {
      headers.addAll(additionalHeaders);
    }

    return headers;
  }

  // Generic HTTP request handler with retry logic
  static Future<http.Response> _makeRequest(
    String method,
    String endpoint,
    {
    Map<String, dynamic>? body,
    Map<String, String>? headers,
    bool includeAuth = true,
    int retryCount = 0,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl$endpoint');
      final requestHeaders = await _getHeaders(
        includeAuth: includeAuth,
        additionalHeaders: headers,
      );

      http.Response response;
      
      switch (method.toUpperCase()) {
        case 'GET':
          response = await http.get(uri, headers: requestHeaders).timeout(timeout);
          break;
        case 'POST':
          response = await http.post(
            uri,
            headers: requestHeaders,
            body: body != null ? json.encode(body) : null,
          ).timeout(timeout);
          break;
        case 'PUT':
          response = await http.put(
            uri,
            headers: requestHeaders,
            body: body != null ? json.encode(body) : null,
          ).timeout(timeout);
          break;
        case 'PATCH':
          response = await http.patch(
            uri,
            headers: requestHeaders,
            body: body != null ? json.encode(body) : null,
          ).timeout(timeout);
          break;
        case 'DELETE':
          response = await http.delete(uri, headers: requestHeaders).timeout(timeout);
          break;
        default:
          throw ArgumentError('Unsupported HTTP method: $method');
      }

      // Handle token expiration
      if (response.statusCode == 401) {
        await _handleTokenExpiration();
        if (retryCount < maxRetries) {
          return _makeRequest(
            method,
            endpoint,
            body: body,
            headers: headers,
            includeAuth: includeAuth,
            retryCount: retryCount + 1,
          );
        }
      }

      // Log request for debugging (only in development)
      if (dotenv.env['ENVIRONMENT'] != 'production') {
        LoggerService.info(
          '${method.toUpperCase()} $endpoint - Status: ${response.statusCode}',
          tag: 'ApiService',
        );
      }

      return response;
    } on SocketException {
      if (retryCount < maxRetries) {
        await Future.delayed(Duration(seconds: retryCount + 1));
        return _makeRequest(
          method,
          endpoint,
          body: body,
          headers: headers,
          includeAuth: includeAuth,
          retryCount: retryCount + 1,
        );
      }
      throw ApiException('No internet connection', 'NETWORK_ERROR');
    } on http.ClientException catch (e) {
      throw ApiException('Network error: ${e.message}', 'CLIENT_ERROR');
    } catch (e) {
      LoggerService.error('API request failed', error: e, tag: 'ApiService');
      if (retryCount < maxRetries) {
        await Future.delayed(Duration(seconds: retryCount + 1));
        return _makeRequest(
          method,
          endpoint,
          body: body,
          headers: headers,
          includeAuth: includeAuth,
          retryCount: retryCount + 1,
        );
      }
      throw ApiException('Request failed: ${e.toString()}', 'REQUEST_ERROR');
    }
  }

  // Public HTTP methods
  static Future<http.Response> get(
    String endpoint, {
    Map<String, String>? headers,
    bool includeAuth = true,
  }) {
    return _makeRequest('GET', endpoint, headers: headers, includeAuth: includeAuth);
  }

  static Future<http.Response> post(
    String endpoint,
    Map<String, dynamic> body, {
    Map<String, String>? headers,
    bool includeAuth = true,
  }) {
    return _makeRequest('POST', endpoint, body: body, headers: headers, includeAuth: includeAuth);
  }

  static Future<http.Response> put(
    String endpoint,
    Map<String, dynamic> body, {
    Map<String, String>? headers,
    bool includeAuth = true,
  }) {
    return _makeRequest('PUT', endpoint, body: body, headers: headers, includeAuth: includeAuth);
  }

  static Future<http.Response> patch(
    String endpoint,
    Map<String, dynamic> body, {
    Map<String, String>? headers,
    bool includeAuth = true,
  }) {
    return _makeRequest('PATCH', endpoint, body: body, headers: headers, includeAuth: includeAuth);
  }

  static Future<http.Response> delete(
    String endpoint, {
    Map<String, String>? headers,
    bool includeAuth = true,
  }) {
    return _makeRequest('DELETE', endpoint, headers: headers, includeAuth: includeAuth);
  }

  // File upload with progress tracking
  static Future<http.Response> uploadFile(
    String endpoint,
    String filePath,
    String fieldName, {
    Map<String, String>? fields,
    Map<String, String>? headers,
    void Function(int, int)? onProgress,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl$endpoint');
      final request = http.MultipartRequest('POST', uri);
      
      // Add headers
      final requestHeaders = await _getHeaders(additionalHeaders: headers);
      request.headers.addAll(requestHeaders);
      
      // Add file
      final file = await http.MultipartFile.fromPath(fieldName, filePath);
      request.files.add(file);
      
      // Add fields
      if (fields != null) {
        request.fields.addAll(fields);
      }
      
      final streamedResponse = await request.send().timeout(timeout);
      
      // Track progress if callback provided
      if (onProgress != null) {
        final contentLength = streamedResponse.contentLength ?? 0;
        int received = 0;
        
        final responseBytes = <int>[];
        await for (final chunk in streamedResponse.stream) {
          responseBytes.addAll(chunk);
          received += chunk.length;
          onProgress(received, contentLength);
        }
        
        return http.Response.bytes(responseBytes, streamedResponse.statusCode);
      }
      
      return await http.Response.fromStream(streamedResponse);
    } catch (e) {
      LoggerService.error('File upload failed', error: e, tag: 'ApiService');
      throw ApiException('File upload failed: ${e.toString()}', 'UPLOAD_ERROR');
    }
  }

  // Response parsing helpers
  static Map<String, dynamic> parseResponse(http.Response response) {
    try {
      if (response.body.isEmpty) {
        return {'success': response.statusCode >= 200 && response.statusCode < 300};
      }
      
      final data = json.decode(response.body) as Map<String, dynamic>;
      
      // Handle different response formats
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return {'success': true, ...data};
      } else {
        return {
          'success': false,
          'message': data['message'] ?? data['error'] ?? 'Request failed',
          'statusCode': response.statusCode,
          ...data,
        };
      }
    } catch (e) {
      LoggerService.error('Response parsing failed', error: e, tag: 'ApiService');
      return {
        'success': false,
        'message': 'Invalid response format',
        'statusCode': response.statusCode,
        'raw_body': response.body,
      };
    }
  }

  // Handle token expiration with refresh logic
  static Future<void> _handleTokenExpiration() async {
    try {
      LoggerService.warning('Token expired, attempting refresh', tag: 'ApiService');
      
      final refreshToken = await StorageService.getRefreshToken();
      if (refreshToken != null) {
        final response = await post('/auth/refresh', {
          'refreshToken': refreshToken,
        }, includeAuth: false);
        
        if (response.statusCode == 200) {
          final data = parseResponse(response);
          if (data['success']) {
            await StorageService.saveToken(data['accessToken'] ?? data['token']);
            if (data['refreshToken'] != null) {
              await StorageService.saveRefreshToken(data['refreshToken']);
            }
            LoggerService.info('Token refreshed successfully', tag: 'ApiService');
            return;
          }
        }
      }
      
      // If refresh fails, clear tokens and redirect to login
      await StorageService.clearTokens();
      LoggerService.warning('Token refresh failed, user needs to re-authenticate', tag: 'ApiService');
    } catch (e) {
      LoggerService.error('Token refresh error', error: e, tag: 'ApiService');
      await StorageService.clearTokens();
    }
  }

  // Health check with detailed response
  static Future<Map<String, dynamic>> healthCheck() async {
    try {
      final response = await get('/health', includeAuth: false);
      final data = parseResponse(response);
      
      return {
        'healthy': response.statusCode == 200,
        'status': response.statusCode,
        'data': data,
        'timestamp': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      LoggerService.error('Health check failed', error: e, tag: 'ApiService');
      return {
        'healthy': false,
        'error': e.toString(),
        'timestamp': DateTime.now().toIso8601String(),
      };
    }
  }

  // Batch requests for multiple API calls
  static Future<List<Map<String, dynamic>>> batchRequests(
    List<Map<String, dynamic>> requests,
  ) async {
    final results = <Map<String, dynamic>>[];
    
    for (final request in requests) {
      try {
        final method = request['method'] as String;
        final endpoint = request['endpoint'] as String;
        final body = request['body'] as Map<String, dynamic>?;
        final headers = request['headers'] as Map<String, String>?;
        
        final response = await _makeRequest(
          method,
          endpoint,
          body: body,
          headers: headers,
        );
        
        results.add({
          'success': true,
          'data': parseResponse(response),
          'statusCode': response.statusCode,
        });
      } catch (e) {
        results.add({
          'success': false,
          'error': e.toString(),
          'statusCode': null,
        });
      }
    }
    
    return results;
  }

  // Get API configuration for debugging
  static Map<String, dynamic> getConfiguration() {
    return {
      'baseUrl': baseUrl,
      'wsUrl': wsUrl,
      'timeout': timeout.inMilliseconds,
      'maxRetries': maxRetries,
      'environment': dotenv.env['ENVIRONMENT'] ?? 'development',
      'version': dotenv.env['APP_VERSION'] ?? '1.0.0',
    };
  }

  // Initialize API service
  static Future<void> initialize() async {
    try {
      await dotenv.load(fileName: ".env");
      LoggerService.info('API Service initialized with base URL: $baseUrl', tag: 'ApiService');
    } catch (e) {
      LoggerService.error('Failed to load .env file', error: e, tag: 'ApiService');
    }
  }
}

// Custom API Exception with enhanced error details
class ApiException implements Exception {
  final String message;
  final String code;
  final int? statusCode;
  final Map<String, dynamic>? details;
  final DateTime timestamp;

  ApiException(
    this.message,
    this.code, {
    this.statusCode,
    this.details,
  }) : timestamp = DateTime.now();

  @override
  String toString() => 'ApiException: $message (Code: $code)';

  Map<String, dynamic> toJson() => {
    'message': message,
    'code': code,
    'statusCode': statusCode,
    'details': details,
    'timestamp': timestamp.toIso8601String(),
  };

  bool get isNetworkError => code == 'NETWORK_ERROR';
  bool get isClientError => code == 'CLIENT_ERROR';
  bool get isServerError => statusCode != null && statusCode! >= 500;
  bool get isAuthError => statusCode == 401 || statusCode == 403;
}
