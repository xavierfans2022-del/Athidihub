import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:athidihub/core/network/dio_provider.dart';
import 'package:athidihub/features/beds/data/models/bed_model.dart';

final bedRepositoryProvider = Provider<BedRepository>((ref) {
  return BedRepository(ref.watch(dioProvider));
});

final bedsByRoomProvider = FutureProvider.family<List<BedModel>, String>((ref, roomId) async {
  final repository = ref.watch(bedRepositoryProvider);
  return repository.getBedsByRoom(roomId);
});

final bedDetailProvider = FutureProvider.family<BedModel, String>((ref, bedId) async {
  final repository = ref.watch(bedRepositoryProvider);
  return repository.getBedDetail(bedId);
});

final createBedProvider = FutureProvider.family<BedModel, Map<String, dynamic>>((ref, data) async {
  final repository = ref.watch(bedRepositoryProvider);
  return repository.createBed(data);
});

final updateBedProvider = FutureProvider.family<BedModel, (String, Map<String, dynamic>)>((ref, params) async {
  final repository = ref.watch(bedRepositoryProvider);
  return repository.updateBed(params.$1, params.$2);
});

final deleteBedProvider = FutureProvider.family<void, String>((ref, bedId) async {
  final repository = ref.watch(bedRepositoryProvider);
  await repository.deleteBed(bedId);
});

class BedRepository {
  final Dio _dio;
  BedRepository(this._dio);

  Future<List<BedModel>> getBedsByRoom(String roomId) async {
    final response = await _dio.get('/beds', queryParameters: {'roomId': roomId});
    if (response.statusCode == 200) {
      final data = response.data;
      if (data is List) {
        return data
            .whereType<Map>()
            .map((json) => BedModel.fromJson(json.cast<String, dynamic>()))
            .toList();
      }
      throw Exception('Unexpected bed response format');
    }
    throw Exception('Failed to load beds');
  }

  Future<BedModel> getBedDetail(String bedId) async {
    final response = await _dio.get('/beds/$bedId');
    if (response.statusCode == 200) {
      return BedModel.fromJson(response.data);
    }
    throw Exception('Failed to load bed details');
  }

  Future<BedModel> createBed(Map<String, dynamic> data) async {
    final response = await _dio.post('/beds', data: data);
    if (response.statusCode == 201 || response.statusCode == 200) {
      return BedModel.fromJson(response.data);
    }
    throw Exception('Failed to create bed');
  }

  Future<BedModel> updateBed(String bedId, Map<String, dynamic> data) async {
    final response = await _dio.patch('/beds/$bedId', data: data);
    if (response.statusCode == 200) {
      return BedModel.fromJson(response.data);
    }
    throw Exception('Failed to update bed');
  }

  Future<void> deleteBed(String bedId) async {
    final response = await _dio.delete('/beds/$bedId');
    if (response.statusCode != 200) {
      throw Exception('Failed to delete bed');
    }
  }
}
