import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:athidihub/core/cache/cache_provider.dart';
import 'package:athidihub/core/logging/app_logger.dart';
import 'package:athidihub/features/dashboard/providers/dashboard_provider.dart';

/// Production-ready refresh mixin for Riverpod providers
/// 
/// Usage example:
/// ```dart
/// // In your ConsumerState or ConsumerStatefulWidget:
/// Future<void> _refreshData() async {
///   await RefreshHelpers.refreshDashboard(ref, orgId);
/// }
/// ```
class RefreshHelpers {
  /// Refresh dashboard analytics data
  static Future<void> refreshDashboard(WidgetRef ref, String orgId) async {
    try {
      final cacheService = ref.read(cacheServiceProvider);
      final cacheKey = 'dashboard_analytics_$orgId';
      
      // Clear cache
      await cacheService.remove(cacheKey);
      
      // Invalidate provider to trigger refetch
      ref.invalidate(dashboardAnalyticsProvider);
      
      AppLogger.info('Dashboard refreshed', data: {'orgId': orgId});
    } catch (e) {
      AppLogger.error('Dashboard refresh failed', error: e);
      rethrow;
    }
  }

  /// Refresh organizations list
  static Future<void> refreshOrganizations(WidgetRef ref) async {
    try {
      final cacheService = ref.read(cacheServiceProvider);
      
      // Clear organizations cache
      await cacheService.remove('organizations');
      
      // Invalidate provider
      ref.invalidate(userOrganizationsProvider);
      
      AppLogger.info('Organizations refreshed');
    } catch (e) {
      AppLogger.error('Organizations refresh failed', error: e);
      rethrow;
    }
  }

  /// Refresh properties list for an organization
  static Future<void> refreshProperties(WidgetRef ref, String orgId) async {
    try {
      final cacheService = ref.read(cacheServiceProvider);
      final cacheKey = 'properties_$orgId';
      
      // Clear cache
      await cacheService.remove(cacheKey);
      
      // Invalidate provider if it exists
      // ref.invalidate(propertiesProvider); // Update based on your actual provider
      
      AppLogger.info('Properties refreshed', data: {'orgId': orgId});
    } catch (e) {
      AppLogger.error('Properties refresh failed', error: e);
      rethrow;
    }
  }

  /// Check rate limit before allowing refresh
  static bool checkRefreshRateLimit(WidgetRef ref, String key, {Duration window = const Duration(seconds: 2)}) {
    try {
      final cacheService = ref.read(cacheServiceProvider);
      return cacheService.checkRateLimit('refresh_$key', window: window);
    } catch (e) {
      AppLogger.warning('Rate limit check failed', error: e);
      return true; // Allow on error
    }
  }

  /// Get cache statistics (for debugging)
  static Map<String, dynamic> getCacheStats(WidgetRef ref) {
    try {
      final cacheService = ref.read(cacheServiceProvider);
      return cacheService.getStats();
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  /// Clear all cache (typically called on logout)
  static Future<void> clearAllCache(WidgetRef ref) async {
    try {
      final cacheService = ref.read(cacheServiceProvider);
      await cacheService.clearAll();
      AppLogger.info('All cache cleared');
    } catch (e) {
      AppLogger.error('Clear cache failed', error: e);
      rethrow;
    }
  }
}
