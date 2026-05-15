import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:athidihub/core/cache/cache_service.dart';

/// Riverpod provider for the cache service
final cacheServiceProvider = Provider<CacheService>((ref) {
  throw UnimplementedError('Cache service must be initialized in main.dart');
});

/// Initialize cache service (call from main.dart after SharedPreferences is ready)
Future<CacheService> initializeCacheService() async {
  final prefs = await SharedPreferences.getInstance();
  return CacheService(prefs);
}
