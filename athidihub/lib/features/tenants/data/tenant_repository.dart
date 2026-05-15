import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:athidihub/core/network/dio_provider.dart';

final tenantRepositoryProvider = Provider<TenantRepository>((ref) {
  return TenantRepository(ref.read(dioProvider));
});

class TenantRepository {
  final Dio _dio;
  TenantRepository(this._dio);

  Future<String> createTenant(Map<String, dynamic> data) async {
    final response = await _dio.post('/tenants', data: data);
    return response.data['id'] as String;
  }

  Future<List<dynamic>> getTenants(String organizationId) async {
    final response = await _dio.get('/tenants', queryParameters: {
      'organizationId': organizationId,
    });
    return response.data as List<dynamic>;
  }
}
