import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:athidihub/core/network/dio_provider.dart';

final maintenanceRepositoryProvider = Provider<MaintenanceRepository>((ref) {
  return MaintenanceRepository(ref.read(dioProvider));
});

class MaintenanceRepository {
  final Dio _dio;
  MaintenanceRepository(this._dio);

  Future<String> createRequest(Map<String, dynamic> data) async {
    final response = await _dio.post('/maintenance', data: data);
    return response.data['id'] as String;
  }

  Future<List<dynamic>> getRequests(String propertyId) async {
    final response = await _dio.get('/maintenance', queryParameters: {
      'propertyId': propertyId,
    });
    return response.data as List<dynamic>;
  }
}
