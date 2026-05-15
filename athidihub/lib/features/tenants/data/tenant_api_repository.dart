import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:athidihub/core/network/dio_provider.dart';

final tenantApiRepositoryProvider = Provider<TenantApiRepository>((ref) {
  return TenantApiRepository(ref.read(dioProvider));
});

class TenantModel {
  final String id;
  final String name;
  final String phone;
  final String email;
  final String organizationId;
  final String emergencyContact;
  final String joiningDate;
  final bool isActive;
  final List<TenantAssignmentModel> assignments;

  TenantModel({
    required this.id,
    required this.name,
    required this.phone,
    required this.email,
    required this.organizationId,
    required this.emergencyContact,
    required this.joiningDate,
    required this.isActive,
    required this.assignments,
  });

  static double _parseDouble(dynamic value) {
    if (value == null) {
      return 0;
    }

    if (value is double) {
      return value;
    }

    if (value is int) {
      return value.toDouble();
    }

    if (value is String) {
      return double.tryParse(value) ?? 0;
    }

    return double.tryParse(value.toString()) ?? 0;
  }

  static String _parseString(dynamic value) {
    if (value == null) {
      return '';
    }

    return value.toString();
  }

  factory TenantModel.fromJson(Map<String, dynamic> json) {
    final rawAssignments = json['assignments'];
    final assignments = rawAssignments is List
        ? rawAssignments
            .whereType<Map>()
            .map((item) => TenantAssignmentModel.fromJson(item.cast<String, dynamic>()))
            .toList()
        : <TenantAssignmentModel>[];

    return TenantModel(
      id: _parseString(json['id']),
      name: _parseString(json['name']),
      phone: _parseString(json['phone']),
      email: _parseString(json['email']),
      organizationId: _parseString(json['organizationId']),
      emergencyContact: _parseString(json['emergencyContact']),
      joiningDate: _parseString(json['joiningDate']),
      isActive: json['isActive'] ?? true,
      assignments: assignments,
    );
  }

  String get initials {
    final parts = name.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  bool get hasActiveAssignment => assignments.any((assignment) => assignment.isActive);

  TenantAssignmentModel? get activeAssignment {
    for (final assignment in assignments) {
      if (assignment.isActive) {
        return assignment;
      }
    }
    return assignments.isNotEmpty ? assignments.first : null;
  }
}

class TenantAssignmentModel {
  final String id;
  final bool isActive;
  final double monthlyRent;
  final double securityDeposit;
  final TenantBedModel? bed;

  TenantAssignmentModel({
    required this.id,
    required this.isActive,
    required this.monthlyRent,
    required this.securityDeposit,
    this.bed,
  });

  factory TenantAssignmentModel.fromJson(Map<String, dynamic> json) {
    final bedData = json['bed'];
    return TenantAssignmentModel(
      id: TenantModel._parseString(json['id']),
      isActive: json['isActive'] ?? false,
      monthlyRent: TenantModel._parseDouble(json['monthlyRent']),
      securityDeposit: TenantModel._parseDouble(json['securityDeposit']),
      bed: bedData is Map ? TenantBedModel.fromJson(bedData.cast<String, dynamic>()) : null,
    );
  }
}

class TenantBedModel {
  final String id;
  final String bedNumber;
  final TenantRoomModel? room;

  TenantBedModel({
    required this.id,
    required this.bedNumber,
    this.room,
  });

  factory TenantBedModel.fromJson(Map<String, dynamic> json) {
    final roomData = json['room'];
    return TenantBedModel(
      id: TenantModel._parseString(json['id']),
      bedNumber: TenantModel._parseString(json['bedNumber']),
      room: roomData is Map ? TenantRoomModel.fromJson(roomData.cast<String, dynamic>()) : null,
    );
  }
}

class TenantRoomModel {
  final String id;
  final String roomNumber;

  TenantRoomModel({required this.id, required this.roomNumber});

  factory TenantRoomModel.fromJson(Map<String, dynamic> json) {
    return TenantRoomModel(
      id: TenantModel._parseString(json['id']),
      roomNumber: TenantModel._parseString(json['roomNumber']),
    );
  }
}

// Paginated response wrapper
class TenantPage {
  final List<TenantModel> data;
  final int total;
  final int page;
  final int limit;
  final bool hasMore;

  const TenantPage({
    required this.data,
    required this.total,
    required this.page,
    required this.limit,
    required this.hasMore,
  });

  factory TenantPage.fromJson(Map<String, dynamic> json) {
    final rawData = json['data'] as List? ?? [];
    return TenantPage(
      data: rawData.map((j) => TenantModel.fromJson(j as Map<String, dynamic>)).toList(),
      total: (json['total'] as num?)?.toInt() ?? 0,
      page: (json['page'] as num?)?.toInt() ?? 1,
      limit: (json['limit'] as num?)?.toInt() ?? 20,
      hasMore: json['hasMore'] as bool? ?? false,
    );
  }
}

class TenantApiRepository {
  final Dio _dio;
  TenantApiRepository(this._dio);

  Future<TenantPage> getTenants({
    String? organizationId,
    String? search,
    String? status,
    int page = 1,
    int limit = 20,
  }) async {
    final response = await _dio.get('/tenants', queryParameters: {
      if (organizationId != null) 'organizationId': organizationId,
      if (search != null && search.isNotEmpty) 'search': search,
      if (status != null && status != 'all') 'status': status,
      'page': page,
      'limit': limit,
    });
    return TenantPage.fromJson(response.data as Map<String, dynamic>);
  }

  Future<TenantModel> getTenant(String id) async {
    final response = await _dio.get('/tenants/$id');
    return TenantModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<TenantModel> createTenant(Map<String, dynamic> data) async {
    final response = await _dio.post('/tenants', data: data);
    return TenantModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<TenantModel> updateTenant(String id, Map<String, dynamic> data) async {
    final response = await _dio.patch('/tenants/$id', data: data);
    return TenantModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> deleteTenant(String id) async {
    await _dio.delete('/tenants/$id');
  }

  Future<void> testTenantWhatsApp(String id) async {
    await _dio.post('/tenants/$id/test-whatsapp');
  }
}
