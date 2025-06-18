import 'package:flutter/foundation.dart';

enum LogLevel { debug, info, warning, error }

class LoggerService {
  static const String _tag = 'FreshMarikiti';
  
  static void debug(String message, {String? tag}) {
    _log(LogLevel.debug, message, tag: tag);
  }
  
  static void info(String message, {String? tag}) {
    _log(LogLevel.info, message, tag: tag);
  }
  
  static void warning(String message, {String? tag}) {
    _log(LogLevel.warning, message, tag: tag);
  }
  
  static void error(String message, {String? tag, Object? error, StackTrace? stackTrace}) {
    _log(LogLevel.error, message, tag: tag);
    if (error != null && kDebugMode) {
      debugPrint('Error: $error');
    }
    if (stackTrace != null && kDebugMode) {
      debugPrint('StackTrace: $stackTrace');
    }
  }
  
  static void _log(LogLevel level, String message, {String? tag}) {
    if (kDebugMode) {
      final timestamp = DateTime.now().toIso8601String();
      final logTag = tag ?? _tag;
      final levelStr = level.toString().split('.').last.toUpperCase();
      debugPrint('[$timestamp] [$levelStr] [$logTag] $message');
    }
  }
  
  // Network logging helpers
  static void networkRequest(String method, String url, {Map<String, dynamic>? body}) {
    if (kDebugMode) {
      debug('$method $url${body != null ? ' - Body: $body' : ''}', tag: 'Network');
    }
  }
  
  static void networkResponse(int statusCode, String url, {String? response}) {
    if (kDebugMode) {
      debug('Response $statusCode - $url${response != null ? ' - $response' : ''}', tag: 'Network');
    }
  }
  
  static void networkError(String url, Object error) {
    if (kDebugMode) {
      LoggerService.error('Network error for $url: $error', tag: 'Network');
    }
  }
} 