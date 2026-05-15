import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:athidihub/core/network/dio_provider.dart';
import 'package:athidihub/features/organizations/data/models/organization_model.dart';

// ── Repository ────────────────────────────────────────────────────────────────

final organizationRepositoryProvider = Provider<OrganizationRepository>((ref) {
  return OrganizationRepository(ref.watch(dioProvider));
});

class OrganizationRepository {
  final Dio _dio;
  OrganizationRepository(this._dio);

  Future<List<OrganizationModel>> getOrganizations() async {
    try {
      final response = await _dio.get('/organizations');
      final data = response.data as List?;
      if (data == null) return [];
      return data.map((json) => OrganizationModel.fromJson(json as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw Exception('Failed to fetch organizations: ${e.message}');
    }
  }

  Future<OrganizationModel> getOrganization(String id) async {
    try {
      final response = await _dio.get('/organizations/$id');
      return OrganizationModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw Exception('Failed to fetch organization: ${e.message}');
    }
  }

  Future<OrganizationModel> updateOrganization(
    String id,
    Map<String, dynamic> updates,
  ) async {
    try {
      final response = await _dio.put('/organizations/$id', data: updates);
      return OrganizationModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw Exception('Failed to update organization: ${e.message}');
    }
  }

  Future<void> deleteOrganization(String id) async {
    try {
      await _dio.delete('/organizations/$id');
    } on DioException catch (e) {
      throw Exception('Failed to delete organization: ${e.message}');
    }
  }
}

// ── Providers ──────────────────────────────────────────────────────────────────

final organizationsListProvider = FutureProvider<List<OrganizationModel>>((ref) async {
  final repo = ref.watch(organizationRepositoryProvider);
  return repo.getOrganizations();
});

final primaryOrganizationProvider = FutureProvider<OrganizationModel?>((ref) async {
  final orgs = await ref.watch(organizationsListProvider.future);
  return orgs.isNotEmpty ? orgs.first : null;
});

final organizationDetailProvider = FutureProvider.family<OrganizationModel, String>((ref, id) async {
  // Handle special case for 'primary' - fetch first organization
  if (id == 'primary') {
    final org = await ref.watch(primaryOrganizationProvider.future);
    if (org == null) throw Exception('No organization found for user');
    return org;
  }
  
  final repo = ref.watch(organizationRepositoryProvider);
  return repo.getOrganization(id);
});

final organizationUpdateProvider = StateNotifierProvider.family<
    OrganizationUpdateNotifier,
    AsyncValue<OrganizationModel?>,
    String>((ref, orgId) {
  final repo = ref.watch(organizationRepositoryProvider);
  return OrganizationUpdateNotifier(repo, orgId);
});

class OrganizationUpdateNotifier extends StateNotifier<AsyncValue<OrganizationModel?>> {
  final OrganizationRepository _repo;
  final String _orgId;

  OrganizationUpdateNotifier(this._repo, this._orgId)
      : super(const AsyncValue.data(null));

  Future<void> updateOrganization(Map<String, dynamic> updates) async {
    state = const AsyncValue.loading();
    try {
      final updated = await _repo.updateOrganization(_orgId, updates);
      state = AsyncValue.data(updated);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }
}

final organizationDeleteProvider = StateNotifierProvider.family<
    OrganizationDeleteNotifier,
    AsyncValue<bool>,
    String>((ref, orgId) {
  final repo = ref.watch(organizationRepositoryProvider);
  return OrganizationDeleteNotifier(repo, orgId);
});

class OrganizationDeleteNotifier extends StateNotifier<AsyncValue<bool>> {
  final OrganizationRepository _repo;
  final String _orgId;

  OrganizationDeleteNotifier(this._repo, this._orgId)
      : super(const AsyncValue.data(false));

  Future<void> deleteOrganization() async {
    state = const AsyncValue.loading();
    try {
      await _repo.deleteOrganization(_orgId);
      state = const AsyncValue.data(true);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }
}
