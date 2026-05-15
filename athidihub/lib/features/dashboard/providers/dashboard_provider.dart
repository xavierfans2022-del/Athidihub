import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:athidihub/core/constants/app_constants.dart';
import 'package:athidihub/core/network/dio_provider.dart';
import 'package:athidihub/core/cache/cache_provider.dart';
import 'package:athidihub/features/dashboard/data/models/dashboard_analytics_model.dart';

final dashboardRepositoryProvider = Provider<DashboardRepository>((ref) {
  return DashboardRepository(ref.watch(dioProvider), ref.watch(cacheServiceProvider));
});

final userOrganizationsProvider = FutureProvider<List<dynamic>>((ref) async {
  final dio = ref.watch(dioProvider);
  final cacheService = ref.watch(cacheServiceProvider);
  const cacheKey = 'organizations';

  try {
    // Always fetch fresh from backend — cache is only offline fallback
    final response = await dio.get('/organizations');
    if (response.statusCode == 200) {
      final data = response.data as List<dynamic>;
      await cacheService.set(cacheKey, data, ttlMinutes: 30);
      return data;
    }
    return const <dynamic>[];
  } on DioException catch (error) {
    if (error.response?.statusCode == 401) {
      return const <dynamic>[];
    }
    // Offline — return stale cache as fallback only
    if (error.type == DioExceptionType.connectionError ||
        error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.sendTimeout) {
      final cached = cacheService.get(cacheKey);
      if (cached != null) return List<dynamic>.from(cached as List);
    }
    return const <dynamic>[];
  }
});

final selectedOrganizationIdProvider = FutureProvider<String?>((ref) async {
  final organizations = await ref.watch(userOrganizationsProvider.future);
  final prefs = await SharedPreferences.getInstance();
  final storedOrgId = prefs.getString(AppConstants.keySelectedOrg);

  if (organizations.isEmpty) {
    // No orgs from backend — clear stale cache
    await prefs.remove(AppConstants.keySelectedOrg);
    return null;
  }

  // Always validate stored ID against the live org list from backend
  if (storedOrgId != null && storedOrgId.isNotEmpty) {
    final isValid = organizations.any(
      (org) => (org as Map<String, dynamic>)['id']?.toString() == storedOrgId,
    );
    if (isValid) return storedOrgId;
    // Stored ID is stale — clear it
    await prefs.remove(AppConstants.keySelectedOrg);
  }

  // Fall back to first org from backend
  final firstId = (organizations.first as Map<String, dynamic>)['id']?.toString();
  if (firstId != null && firstId.isNotEmpty) {
    await prefs.setString(AppConstants.keySelectedOrg, firstId);
    return firstId;
  }

  return null;
});

final dashboardAnalyticsProvider = FutureProvider<DashboardAnalyticsModel>((ref) async {
  final orgId = await ref.watch(selectedOrganizationIdProvider.future);
  if (orgId == null || orgId.isEmpty) {
    return DashboardAnalyticsModel.empty();
  }
  final repository = ref.watch(dashboardRepositoryProvider);
  try {
    return await repository.getAnalytics(orgId);
  } on DioException catch (error) {
    if (error.response?.statusCode == 401) {
      return DashboardAnalyticsModel.empty();
    }
    if (error.response?.statusCode == 403 || error.response?.statusCode == 404) {
      // Org ID is invalid for this user — clear stale cache and reset
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(AppConstants.keySelectedOrg);
      ref.invalidate(selectedOrganizationIdProvider);
      ref.invalidate(userOrganizationsProvider);
      return DashboardAnalyticsModel.empty();
    }
    if (error.type == DioExceptionType.connectionError ||
        error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.sendTimeout) {
      return DashboardAnalyticsModel.empty();
    }
    rethrow;
  }
});

class DashboardRepository {
  final Dio _dio;
  final _cacheService;
  DashboardRepository(this._dio, this._cacheService);

  Future<DashboardAnalyticsModel> getAnalytics(String orgId) async {
    final cacheKey = 'dashboard_analytics_$orgId';
    final cached = _cacheService.get(cacheKey);
    if (cached != null) {
      return DashboardAnalyticsModel.fromJson(Map<String, dynamic>.from(cached as Map));
    }

    final response = await _dio.get('/dashboard/summary/$orgId');
    if (response.statusCode == 200) {
      final model = DashboardAnalyticsModel.fromJson(response.data);
      await _cacheService.set(cacheKey, response.data, ttlMinutes: 10);
      return model;
    }
    throw Exception('Failed to load dashboard analytics');
  }
}
