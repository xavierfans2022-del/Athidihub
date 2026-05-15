import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:athidihub/core/network/dio_provider.dart';

final onboardingRepositoryProvider = Provider<OnboardingRepository>((ref) {
  return OnboardingRepository(ref.read(dioProvider));
});

class OnboardingRepository {
  final Dio _dio;
  OnboardingRepository(this._dio);

  Future<String> createOrganization(Map<String, dynamic> data) async {
    final response = await _dio.post('/organizations', data: data);
    return response.data['id'] as String;
  }

  Future<void> updateOrganization(String id, Map<String, dynamic> data) async {
    await _dio.patch('/organizations/$id', data: data);
  }

  Future<Map<String, dynamic>> fetchOrganization(String id) async {
    final response = await _dio.get('/organizations/$id');
    return response.data as Map<String, dynamic>;
  }

  Future<String> createProperty(Map<String, dynamic> data) async {
    final response = await _dio.post('/properties', data: data);
    return response.data['id'] as String;
  }

  Future<void> updateProperty(String id, Map<String, dynamic> data) async {
    await _dio.patch('/properties/$id', data: data);
  }

  Future<Map<String, dynamic>> fetchProperty(String id) async {
    final response = await _dio.get('/properties/$id');
    return response.data as Map<String, dynamic>;
  }

  Future<String> createRoom(Map<String, dynamic> data) async {
    final response = await _dio.post('/rooms', data: data);
    return response.data['id'] as String;
  }

  Future<void> updateRoom(String id, Map<String, dynamic> data) async {
    await _dio.patch('/rooms/$id', data: data);
  }

  Future<Map<String, dynamic>> fetchRoom(String id) async {
    final response = await _dio.get('/rooms/$id');
    return response.data as Map<String, dynamic>;
  }

  Future<String> createBed(Map<String, dynamic> data) async {
    final response = await _dio.post('/beds', data: data);
    return response.data['id'] as String;
  }
}
