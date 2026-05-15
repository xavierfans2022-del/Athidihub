import 'package:shared_preferences/shared_preferences.dart';
import 'package:athidihub/core/logging/app_logger.dart';
import 'dart:convert';

/// Production-level cache service with TTL, rate limiting, and clear-on-logout support
class CacheService {
  static const String _prefix = 'athidihub_cache_';
  static const String _ttlSuffix = '_ttl';
  static const String _rateLimitSuffix = '_ratelimit';

  final SharedPreferences _prefs;

  CacheService(this._prefs);

  /// Set a value with optional TTL (in minutes, default 60)
  Future<void> set(
    String key,
    dynamic value, {
    int ttlMinutes = 60,
  }) async {
    try {
      final prefixedKey = '$_prefix$key';
      final jsonString = jsonEncode(value);
      
      await _prefs.setString(prefixedKey, jsonString);
      
      // Store TTL as expiration timestamp
      final expiresAt = DateTime.now().add(Duration(minutes: ttlMinutes)).millisecondsSinceEpoch;
      await _prefs.setInt('$prefixedKey$_ttlSuffix', expiresAt);
      
      AppLogger.info(
        'Cache set',
        data: {
          'key': key,
          'ttlMinutes': ttlMinutes,
          'expiresAt': DateTime.fromMillisecondsSinceEpoch(expiresAt).toIso8601String(),
        },
      );
    } catch (e, st) {
      AppLogger.error('Cache set failed', error: e, stackTrace: st, data: {'key': key});
    }
  }

  /// Get a value if not expired
  dynamic get(String key) {
    try {
      final prefixedKey = '$_prefix$key';
      final ttlKey = '$prefixedKey$_ttlSuffix';
      
      // Check TTL
      final expiresAt = _prefs.getInt(ttlKey);
      if (expiresAt != null && DateTime.now().millisecondsSinceEpoch > expiresAt) {
        // Cache expired
        AppLogger.info('Cache expired', data: {'key': key});
        _prefs.remove(prefixedKey);
        _prefs.remove(ttlKey);
        return null;
      }
      
      final jsonString = _prefs.getString(prefixedKey);
      if (jsonString == null) return null;
      
      final decoded = jsonDecode(jsonString);
      AppLogger.info('Cache hit', data: {'key': key});
      return decoded;
    } catch (e, st) {
      AppLogger.error('Cache get failed', error: e, stackTrace: st, data: {'key': key});
      return null;
    }
  }

  /// Check rate limit for a key (returns true if allowed)
  bool checkRateLimit(String key, {Duration window = const Duration(seconds: 2)}) {
    try {
      final rateLimitKey = '$_prefix$key$_rateLimitSuffix';
      final lastCall = _prefs.getInt(rateLimitKey);
      final now = DateTime.now().millisecondsSinceEpoch;
      
      if (lastCall == null || (now - lastCall) >= window.inMilliseconds) {
        _prefs.setInt(rateLimitKey, now);
        return true;
      }
      
      AppLogger.info('Rate limit exceeded', data: {
        'key': key,
        'windowMs': window.inMilliseconds,
        'timeSinceLastCallMs': now - lastCall,
      });
      return false;
    } catch (e, st) {
      AppLogger.error('Rate limit check failed', error: e, stackTrace: st, data: {'key': key});
      return true; // Allow on error
    }
  }

  /// Remove a specific cache entry
  Future<void> remove(String key) async {
    try {
      final prefixedKey = '$_prefix$key';
      await _prefs.remove(prefixedKey);
      await _prefs.remove('$prefixedKey$_ttlSuffix');
      await _prefs.remove('$prefixedKey$_rateLimitSuffix');
      AppLogger.info('Cache removed', data: {'key': key});
    } catch (e, st) {
      AppLogger.error('Cache remove failed', error: e, stackTrace: st, data: {'key': key});
    }
  }

  /// Clear all cache entries (call on sign-out)
  Future<void> clearAll() async {
    try {
      final keys = _prefs.getKeys();
      final cacheKeys = keys.where((k) => k.startsWith(_prefix)).toList();
      
      for (final key in cacheKeys) {
        await _prefs.remove(key);
      }
      
      AppLogger.info('All cache cleared', data: {'keysCleared': cacheKeys.length});
    } catch (e, st) {
      AppLogger.error('Clear all cache failed', error: e, stackTrace: st);
    }
  }

  /// Get cache stats for debugging
  Map<String, dynamic> getStats() {
    try {
      final keys = _prefs.getKeys();
      final cacheKeys = keys.where((k) => k.startsWith(_prefix)).toList();
      int expiredCount = 0;
      int validCount = 0;
      
      for (final key in cacheKeys) {
        if (!key.endsWith(_ttlSuffix) && !key.endsWith(_rateLimitSuffix)) {
          final ttlKey = '${key}_ttl';
          final expiresAt = _prefs.getInt(ttlKey);
          if (expiresAt != null && DateTime.now().millisecondsSinceEpoch > expiresAt) {
            expiredCount++;
          } else {
            validCount++;
          }
        }
      }
      
      return {
        'totalKeys': cacheKeys.length,
        'validEntries': validCount,
        'expiredEntries': expiredCount,
        'keys': cacheKeys.map((k) => k.replaceFirst(_prefix, '')).toList(),
      };
    } catch (e) {
      return {'error': e.toString()};
    }
  }
}
