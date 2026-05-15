import 'package:dio/dio.dart';
import '../models/kyc_models.dart';

class KYCService {
  final Dio _dio;
  final String _baseUrl;

  KYCService({required Dio dio, required String baseUrl})
      : _dio = dio,
        _baseUrl = baseUrl;

  /// Initiate KYC verification with specified provider
  Future<InitiateKYCResponse> initiateVerification({
    required String tenantId,
    String provider = 'DIGILOCKER',
    bool sandboxMode = true,
  }) async {
    try {
      final response = await _dio.post(
        '$_baseUrl/kyc/initiate',
        data: {
          'tenantId': tenantId,
          'provider': provider,
          'redirectUrl': '${_baseUrl}/kyc/callback',
          'sandboxMode': sandboxMode,
        },
      );

      return InitiateKYCResponse.fromJson(response.data);
    } catch (e) {
      rethrow;
    }
  }

  /// Get current KYC verification status
  Future<KYCStatus> getVerificationStatus({required String tenantId}) async {
    try {
      final response = await _dio.get('$_baseUrl/kyc/status/$tenantId');
      return KYCStatus.fromJson(response.data);
    } catch (e) {
      rethrow;
    }
  }

  /// Get detailed KYC information
  Future<KYCDetails> getKYCDetails({required String tenantId}) async {
    try {
      final response = await _dio.get('$_baseUrl/kyc/details/$tenantId');
      return KYCDetails.fromJson(response.data);
    } catch (e) {
      rethrow;
    }
  }

  /// Upload KYC document (fallback)
  Future<KYCUploadResponse> uploadDocument({
    required String tenantId,
    required KYCDocumentType documentType,
    required String fileData,
    String? fileName,
    String? mimeType,
    int? fileSize,
  }) async {
    try {
      final response = await _dio.post(
        '$_baseUrl/kyc/upload-document',
        data: {
          'tenantId': tenantId,
          'documentType': _documentTypeToString(documentType),
          'fileData': fileData,
          'fileName': fileName ?? '${_documentTypeToString(documentType)}-${DateTime.now().millisecondsSinceEpoch}',
          'mimeType': mimeType ?? 'application/octet-stream',
          if (fileSize != null) 'fileSize': fileSize,
        },
      );

      return KYCUploadResponse.fromJson(response.data);
    } catch (e) {
      rethrow;
    }
  }

  /// Retry KYC verification
  Future<KYCVerification> retryVerification({
    required String tenantId,
    String? reason,
  }) async {
    try {
      final response = await _dio.post(
        '$_baseUrl/kyc/retry',
        data: {
          'tenantId': tenantId,
          if (reason != null) 'reason': reason,
        },
      );

      return KYCVerification.fromJson(response.data);
    } catch (e) {
      rethrow;
    }
  }

  /// Process OAuth callback from Digilocker
  Future<Map<String, dynamic>> processOAuthCallback({
    required String tenantId,
    required String code,
    required String verificationId,
    String? state,
    String? sessionId,
  }) async {
    try {
      final response = await _dio.post(
        '$_baseUrl/kyc/callback/process',
        data: {
          'tenantId': tenantId,
          'code': code,
          'verificationId': verificationId,
          if (state != null) 'state': state,
          if (sessionId != null) 'sessionId': sessionId,
        },
      );

      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  /// Get list of documents for a KYC verification
  Future<List<KYCDocument>> getDocuments({required String kycVerificationId}) async {
    try {
      final response = await _dio.get('$_baseUrl/kyc/documents/$kycVerificationId');
      final data = response.data as Map<String, dynamic>;
      final documents = (data['documents'] as List)
          .map((doc) => KYCDocument.fromJson(doc as Map<String, dynamic>))
          .toList();
      return documents;
    } catch (e) {
      rethrow;
    }
  }

  /// Admin: Get pending KYC reviews
  Future<Map<String, dynamic>> getPendingReviews({int skip = 0, int take = 10}) async {
    try {
      final response = await _dio.get(
        '$_baseUrl/kyc/admin/pending-reviews',
        queryParameters: {'skip': skip, 'take': take},
      );
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  /// Admin: Get KYC details for review
  Future<KYCDetails> getAdminKYCDetails({required String tenantId}) async {
    try {
      final response = await _dio.get('$_baseUrl/kyc/admin/details/$tenantId');
      return KYCDetails.fromJson(response.data);
    } catch (e) {
      rethrow;
    }
  }

  /// Admin: Approve KYC verification
  Future<Map<String, dynamic>> approveKYC({
    required String tenantId,
    required String adminNotes,
    bool flaggedForSuspicion = false,
    String? suspicionReason,
  }) async {
    try {
      final response = await _dio.patch(
        '$_baseUrl/kyc/admin/approve/$tenantId',
        data: {
          'adminNotes': adminNotes,
          'flaggedForSuspicion': flaggedForSuspicion,
          if (suspicionReason != null) 'suspicionReason': suspicionReason,
        },
      );
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  /// Admin: Reject KYC verification
  Future<Map<String, dynamic>> rejectKYC({
    required String tenantId,
    required String rejectionReason,
    String? adminNotes,
    bool allowRetry = true,
  }) async {
    try {
      final response = await _dio.patch(
        '$_baseUrl/kyc/admin/reject/$tenantId',
        data: {
          'rejectionReason': rejectionReason,
          if (adminNotes != null) 'adminNotes': adminNotes,
          'allowRetry': allowRetry,
        },
      );
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  static String _documentTypeToString(KYCDocumentType type) {
    switch (type) {
      case KYCDocumentType.aadhaarFront:
        return 'AADHAAR_FRONT';
      case KYCDocumentType.aadhaarBack:
        return 'AADHAAR_BACK';
      case KYCDocumentType.pan:
        return 'PAN';
      case KYCDocumentType.selfie:
        return 'SELFIE';
    }
  }
}
