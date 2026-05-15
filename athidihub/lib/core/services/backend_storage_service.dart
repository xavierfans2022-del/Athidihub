import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../network/dio_provider.dart';

class BackendStorageService {
  BackendStorageService(this._dio);

  final Dio _dio;

  /// Upload user profile avatar
  /// Returns the public URL of the uploaded avatar
  Future<String> uploadAvatar({
    required Uint8List bytes,
    required String fileName,
    String? mimeType,
  }) {
    return _upload(
      '/storage/avatar',
      bytes: bytes,
      fileName: fileName,
      mimeType: mimeType,
    );
  }

  /// Upload organization logo
  /// Optional organizationId: if provided, saves to database; otherwise just returns URL
  /// Useful for both onboarding (org not yet created) and updates (org exists)
  /// Returns the public URL of the uploaded logo
  Future<String> uploadOrganizationLogo({
    required Uint8List bytes,
    required String fileName,
    String? organizationId,
    String? mimeType,
  }) {
    return _upload(
      '/storage/organization-logo',
      bytes: bytes,
      fileName: fileName,
      mimeType: mimeType,
      extraFields: {
        if (organizationId != null) 'organizationId': organizationId,
      },
    );
  }

  /// Upload tenant document (KYC or profile avatar)
  /// Supports document types: AADHAAR_FRONT, AADHAAR_BACK, PAN, SELFIE, AVATAR
  /// Returns the public URL of the uploaded document
  Future<String> uploadTenantDocument({
    required String tenantId,
    required String documentType,
    required Uint8List bytes,
    required String fileName,
    String? mimeType,
  }) {
    return _upload(
      '/storage/tenant-document',
      bytes: bytes,
      fileName: fileName,
      mimeType: mimeType,
      extraFields: {
        'tenantId': tenantId,
        'documentType': documentType,
      },
    );
  }

  Future<String> _upload(
    String path, {
    required Uint8List bytes,
    required String fileName,
    String? mimeType,
    Map<String, dynamic>? extraFields,
  }) async {
    final resolvedMimeType = mimeType ?? _inferMimeType(fileName);
    final formData = FormData.fromMap({
      ...?extraFields,
      'mimeType': resolvedMimeType,
      'file': MultipartFile.fromBytes(bytes, filename: fileName),
    });

    final response = await _dio.post(
      path,
      data: formData,
      options: Options(contentType: 'multipart/form-data'),
    );

    final data = response.data;
    if (data is Map<String, dynamic> && data['publicUrl'] is String) {
      return data['publicUrl'] as String;
    }

    throw DioException(
      requestOptions: response.requestOptions,
      response: response,
      type: DioExceptionType.badResponse,
      error: 'Invalid storage upload response',
    );
  }

  String _inferMimeType(String fileName) {
    final lowerName = fileName.toLowerCase();
    if (lowerName.endsWith('.png')) {
      return 'image/png';
    }
    if (lowerName.endsWith('.webp')) {
      return 'image/webp';
    }
    if (lowerName.endsWith('.pdf')) {
      return 'application/pdf';
    }
    return 'image/jpeg';
  }
}

final backendStorageServiceProvider = Provider<BackendStorageService>((ref) {
  return BackendStorageService(ref.watch(dioProvider));
});