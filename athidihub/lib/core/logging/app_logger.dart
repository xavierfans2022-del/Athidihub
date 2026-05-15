import 'dart:developer' as developer;
import 'package:athidihub/core/observability/observability.dart';

import 'package:flutter/foundation.dart';

class AppLogger {
  AppLogger._();

  static bool get enabled => !kReleaseMode;

  static void debug(String message, {Object? data, Object? error, StackTrace? stackTrace}) {
    _log('DEBUG', message, data: data, error: error, stackTrace: stackTrace);
  }

  static void info(String message, {Object? data}) {
    _log('INFO', message, data: data);
  }

  static void warning(String message, {Object? data, Object? error, StackTrace? stackTrace}) {
    _log('WARN', message, data: data, error: error, stackTrace: stackTrace);
  }

  static void error(
    String message, {
    Object? data,
    Object? error,
    StackTrace? stackTrace,
  }) {
    _log('ERROR', message, data: data, error: error, stackTrace: stackTrace);
    try {
      Observability.logError(error ?? message, stackTrace);
    } catch (_) {}
  }

  static void apiRequest({
    required String method,
    required String path,
    Object? data,
  }) {
    _log('INFO', 'API request', data: {
      'method': method,
      'path': path,
      if (data != null) 'body': sanitize(data),
    });
  }

  static void apiResponse({
    required String method,
    required String path,
    required int statusCode,
    required int durationMs,
    Object? data,
  }) {
    _log('INFO', 'API response', data: {
      'method': method,
      'path': path,
      'statusCode': statusCode,
      'durationMs': durationMs,
      if (data != null) 'body': sanitize(data),
    });
  }

  static void apiError({
    required String method,
    required String path,
    required int? statusCode,
    required int durationMs,
    Object? error,
    StackTrace? stackTrace,
    Object? data,
  }) {
    _log('ERROR', 'API error', data: {
      'method': method,
      'path': path,
      'statusCode': statusCode,
      'durationMs': durationMs,
      if (data != null) 'body': sanitize(data),
    }, error: error, stackTrace: stackTrace);
  }

  static void authEvent(String event, {Object? data}) {
    _log('INFO', 'Supabase auth event: $event', data: data);
  }

  static void _log(
    String level,
    String message, {
    Object? data,
    Object? error,
    StackTrace? stackTrace,
  }) {
    if (!enabled) {
      return;
    }

    final buffer = StringBuffer('[$level] $message');
    if (data != null) {
      buffer.write(' | data=${_stringify(sanitize(data))}');
    }
    if (error != null) {
      buffer.write(' | error=$error');
    }
    if (stackTrace != null) {
      buffer.write('\n$stackTrace');
    }

    developer.log(
      buffer.toString(),
      name: 'athidihub',
      error: error,
      stackTrace: stackTrace,
      level: level == 'ERROR' ? 1000 : level == 'WARN' ? 900 : 800,
    );
  }

  static Object? sanitize(Object? value) {
    if (value == null) {
      return null;
    }

    if (value is Map) {
      return value.map((key, dynamic nestedValue) {
        final keyName = key.toString();
        if (_isSensitiveKey(keyName)) {
          return MapEntry(key, '***');
        }
        if (_looksLikeEmailKey(keyName) && nestedValue is String) {
          return MapEntry(key, _maskEmail(nestedValue));
        }
        if (_looksLikePhoneKey(keyName) && nestedValue is String) {
          return MapEntry(key, _maskPhone(nestedValue));
        }
        return MapEntry(key, sanitize(nestedValue));
      });
    }

    if (value is Iterable) {
      return value.map(sanitize).toList();
    }

    if (value is DateTime) {
      return value.toIso8601String();
    }

    if (value is String) {
      return _truncate(value);
    }

    return value.toString();
  }

  static String maskEmail(String email) {
    return _maskEmail(email);
  }

  static String maskPhone(String phone) {
    return _maskPhone(phone);
  }

  static String _stringify(Object? value) {
    if (value == null) {
      return 'null';
    }

    return value.toString();
  }

  static bool _isSensitiveKey(String key) {
    final lower = key.toLowerCase();
    return lower.contains('password') ||
        lower.contains('refresh') ||
        lower.contains('access_token') ||
        lower.contains('accesstoken') ||
        lower.contains('token') ||
        lower.contains('secret') ||
        lower.contains('authorization') ||
        lower.contains('api_key') ||
        lower.contains('apikey');
  }

  static bool _looksLikeEmailKey(String key) {
    final lower = key.toLowerCase();
    return lower.contains('email');
  }

  static bool _looksLikePhoneKey(String key) {
    final lower = key.toLowerCase();
    return lower.contains('phone') || lower.contains('mobile');
  }

  static String _maskEmail(String email) {
    final parts = email.split('@');
    if (parts.length != 2 || parts.first.isEmpty) {
      return _truncate(email);
    }

    final local = parts.first;
    final visible = local.length <= 2 ? local : local.substring(0, 2);
    return '$visible***@${parts.last}';
  }

  static String _maskPhone(String phone) {
    final digitsOnly = phone.replaceAll(RegExp(r'\D'), '');
    if (digitsOnly.length <= 4) {
      return '***';
    }

    return '***${digitsOnly.substring(digitsOnly.length - 4)}';
  }

  static String _truncate(String value, [int maxLength = 1200]) {
    if (value.length <= maxLength) {
      return value;
    }

    return '${value.substring(0, maxLength)}…';
  }
}