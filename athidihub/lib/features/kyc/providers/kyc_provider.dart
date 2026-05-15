import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/logging/app_logger.dart';
import '../../../core/network/dio_provider.dart';
import '../models/kyc_models.dart';
import '../services/kyc_service.dart';

// ─── KYC SERVICE PROVIDER ──────────────────────────────────

final kycServiceProvider = Provider((ref) {
  final dio = ref.watch(dioProvider);
  final baseUrl = ref.watch(apiBaseUrlProvider);
  return KYCService(dio: dio, baseUrl: baseUrl);
});

// Base URL provider
final apiBaseUrlProvider = Provider((ref) => AppConstants.baseUrl);

// ─── KYC VERIFICATION STATE ───────────────────────────────

final kycVerificationProvider = StateNotifierProvider.family<
    KYCVerificationNotifier,
    AsyncValue<InitiateKYCResponse?>,
    String>((ref, tenantId) {
  final kycService = ref.watch(kycServiceProvider);
  return KYCVerificationNotifier(kycService, tenantId);
});

class KYCVerificationNotifier extends StateNotifier<AsyncValue<InitiateKYCResponse?>> {
  final KYCService _kycService;
  final String _tenantId;

  KYCVerificationNotifier(this._kycService, this._tenantId)
      : super(const AsyncValue.data(null));

  Future<void> initiateVerification({String provider = 'DIGILOCKER', bool sandboxMode = true}) async {
    state = const AsyncValue.loading();
    final providersToTry = sandboxMode ? <String>[provider] : <String>{provider, 'SETU'}.toList();

    for (final candidate in providersToTry) {
      try {
        final response = await _kycService.initiateVerification(
          tenantId: _tenantId,
          provider: candidate,
          sandboxMode: sandboxMode,
        );
        state = AsyncValue.data(response);
        return;
      } on DioException catch (error, stackTrace) {
        if (_isMissingProviderConfig(error) && candidate != providersToTry.last) {
          continue;
        }
        state = AsyncValue.error(error, stackTrace);
        return;
      } catch (error, stackTrace) {
        state = AsyncValue.error(error, stackTrace);
        return;
      }
    }

  }

  bool _isMissingProviderConfig(DioException error) {
    final data = error.response?.data;
    final message = data is Map<String, dynamic> ? data['message']?.toString() : null;
    return message != null && message.contains('KYC provider configuration missing');
  }

  void reset() {
    state = const AsyncValue.data(null);
  }
}

// ─── KYC STATUS PROVIDER ──────────────────────────────────

final kycStatusProvider =
    FutureProvider.family<KYCStatus, String>((ref, tenantId) async {
  final kycService = ref.watch(kycServiceProvider);
  try {
    final status = await kycService.getVerificationStatus(tenantId: tenantId);

    // If verification is in progress, poll every 5 seconds
    if (status.status == KYCVerificationStatus.inProgress) {
      final timer = Timer(const Duration(seconds: 5), () {
        ref.invalidateSelf();
      });
      ref.onDispose(() => timer.cancel());
    }

    return status;
  } on DioException catch (error) {
    if (error.response?.statusCode == 404) {
      return KYCStatus(
        status: KYCVerificationStatus.pending,
        completionPercentage: 0,
        documents: const [],
        verification: null,
        errorMessage: null,
        nextAction: 'Start KYC verification',
      );
    }
    rethrow;
  }
});

// ─── KYC DETAILS PROVIDER ─────────────────────────────────

final kycDetailsProvider =
    FutureProvider.family<KYCDetails?, String>((ref, tenantId) async {
  final kycService = ref.watch(kycServiceProvider);
  try {
    return await kycService.getKYCDetails(tenantId: tenantId);
  } on DioException catch (error) {
    if (error.response?.statusCode == 404) {
      return null;
    }
    rethrow;
  }
});

// ─── KYC DOCUMENT UPLOAD STATE ────────────────────────────

final kycDocumentUploadProvider =
    StateNotifierProvider.family<KYCDocumentUploadNotifier, AsyncValue<KYCUploadResponse?>, String>(
        (ref, tenantId) {
  final kycService = ref.watch(kycServiceProvider);
  return KYCDocumentUploadNotifier(kycService, tenantId);
});

class KYCDocumentUploadNotifier extends StateNotifier<AsyncValue<KYCUploadResponse?>> {
  final KYCService _kycService;
  final String _tenantId;

  KYCDocumentUploadNotifier(this._kycService, this._tenantId)
      : super(const AsyncValue.data(null));

  Future<void> uploadDocument({
    required KYCDocumentType documentType,
    required String fileData,
    String? fileName,
    String? mimeType,
    int? fileSize,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _kycService.uploadDocument(
          tenantId: _tenantId,
          documentType: documentType,
          fileData: fileData,
          fileName: fileName,
          mimeType: mimeType,
          fileSize: fileSize,
        ));
  }

  void reset() {
    state = const AsyncValue.data(null);
  }
}

// ─── KYC RETRY PROVIDER ───────────────────────────────────

final kycRetryProvider =
    StateNotifierProvider.family<KYCRetryNotifier, AsyncValue<KYCVerification?>, String>(
        (ref, tenantId) {
  final kycService = ref.watch(kycServiceProvider);
  return KYCRetryNotifier(kycService, tenantId);
});

class KYCRetryNotifier extends StateNotifier<AsyncValue<KYCVerification?>> {
  final KYCService _kycService;
  final String _tenantId;

  KYCRetryNotifier(this._kycService, this._tenantId) : super(const AsyncValue.data(null));

  Future<void> retryVerification({String? reason}) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() =>
        _kycService.retryVerification(tenantId: _tenantId, reason: reason));
  }

  void reset() {
    state = const AsyncValue.data(null);
  }
}

// ─── KYC ADMIN PENDING REVIEWS PROVIDER ────────────────────

final kycAdminPendingReviewsProvider = FutureProvider.family<
    Map<String, dynamic>,
    ({int skip, int take})>((ref, params) async {
  final kycService = ref.watch(kycServiceProvider);
  return kycService.getPendingReviews(skip: params.skip, take: params.take);
});

// ─── KYC ADMIN APPROVAL PROVIDER ───────────────────────────

final kycAdminApprovalProvider = StateNotifierProvider.family<
    KYCAdminApprovalNotifier,
    AsyncValue<Map<String, dynamic>?>,
    String>((ref, tenantId) {
  final kycService = ref.watch(kycServiceProvider);
  return KYCAdminApprovalNotifier(kycService, tenantId);
});

class KYCAdminApprovalNotifier extends StateNotifier<AsyncValue<Map<String, dynamic>?>> {
  final KYCService _kycService;
  final String _tenantId;

  KYCAdminApprovalNotifier(this._kycService, this._tenantId)
      : super(const AsyncValue.data(null));

  Future<void> approveKYC({
    required String adminNotes,
    bool flaggedForSuspicion = false,
    String? suspicionReason,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _kycService.approveKYC(
          tenantId: _tenantId,
          adminNotes: adminNotes,
          flaggedForSuspicion: flaggedForSuspicion,
          suspicionReason: suspicionReason,
        ));
  }

  void reset() {
    state = const AsyncValue.data(null);
  }
}

// ─── KYC ADMIN REJECTION PROVIDER ──────────────────────────

final kycAdminRejectionProvider = StateNotifierProvider.family<
    KYCAdminRejectionNotifier,
    AsyncValue<Map<String, dynamic>?>,
    String>((ref, tenantId) {
  final kycService = ref.watch(kycServiceProvider);
  return KYCAdminRejectionNotifier(kycService, tenantId);
});

class KYCAdminRejectionNotifier extends StateNotifier<AsyncValue<Map<String, dynamic>?>> {
  final KYCService _kycService;
  final String _tenantId;

  KYCAdminRejectionNotifier(this._kycService, this._tenantId)
      : super(const AsyncValue.data(null));

  Future<void> rejectKYC({
    required String rejectionReason,
    String? adminNotes,
    bool allowRetry = true,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _kycService.rejectKYC(
          tenantId: _tenantId,
          rejectionReason: rejectionReason,
          adminNotes: adminNotes,
          allowRetry: allowRetry,
        ));
  }

  void reset() {
    state = const AsyncValue.data(null);
  }
}

// ─── COMBINED STATE FOR KYC FLOW ──────────────────────────

final kycFlowStateProvider = StateNotifierProvider.family<
    KYCFlowStateNotifier,
    KYCFlowState,
    String>((ref, tenantId) {
  final kycService = ref.watch(kycServiceProvider);
  return KYCFlowStateNotifier(kycService, tenantId);
});

class KYCFlowState {
  final KYCVerificationStatus? status;
  final bool isLoading;
  final String? error;
  final InitiateKYCResponse? initiationResponse;
  final List<KYCDocument> uploadedDocuments;
  final bool verificationInProgress;

  KYCFlowState({
    this.status,
    this.isLoading = false,
    this.error,
    this.initiationResponse,
    this.uploadedDocuments = const [],
    this.verificationInProgress = false,
  });

  KYCFlowState copyWith({
    KYCVerificationStatus? status,
    bool? isLoading,
    String? error,
    InitiateKYCResponse? initiationResponse,
    List<KYCDocument>? uploadedDocuments,
    bool? verificationInProgress,
  }) {
    return KYCFlowState(
      status: status ?? this.status,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      initiationResponse: initiationResponse ?? this.initiationResponse,
      uploadedDocuments: uploadedDocuments ?? this.uploadedDocuments,
      verificationInProgress: verificationInProgress ?? this.verificationInProgress,
    );
  }
}

class KYCFlowStateNotifier extends StateNotifier<KYCFlowState> {
  final KYCService _kycService;
  final String _tenantId;

  KYCFlowStateNotifier(this._kycService, this._tenantId) : super(KYCFlowState());

  Future<void> startVerification({String provider = 'DIGILOCKER', bool sandboxMode = true}) async {
    AppLogger.info('[KYC Flow] startVerification called', data: {
      'tenantId': _tenantId,
      'provider': provider,
      'sandboxMode': sandboxMode,
    });

    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _kycService.initiateVerification(
        tenantId: _tenantId,
        provider: provider,
        sandboxMode: sandboxMode,
      );

      AppLogger.info('[KYC Flow] startVerification success', data: {
        'tenantId': _tenantId,
        'kycVerificationId': response.kycVerificationId,
        'sessionId': response.sessionId,
        'status': response.status.name,
        'verificationUrl': response.verificationUrl,
      });

      state = state.copyWith(
        isLoading: false,
        initiationResponse: response,
        status: response.status,
        verificationInProgress: true,
      );
    } catch (e) {
      AppLogger.error('[KYC Flow] startVerification failed', error: e);
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> addDocument({
    required KYCDocumentType documentType,
    required String fileData,
    int? fileSize,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _kycService.uploadDocument(
        tenantId: _tenantId,
        documentType: documentType,
        fileData: fileData,
        fileSize: fileSize,
      );
      state = state.copyWith(
        isLoading: false,
        uploadedDocuments: [...state.uploadedDocuments, response.document],
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> checkStatus() async {
    try {
      final status = await _kycService.getVerificationStatus(tenantId: _tenantId);
      state = state.copyWith(
        status: status.status,
        verificationInProgress: false,
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// Process OAuth callback from Digilocker WebView
  Future<void> processOAuthCallback({
    required String code,
    required String verificationId,
    String? state,
    String? sessionId,
  }) async {
    AppLogger.info('[KYC Flow] processOAuthCallback called', data: {
      'tenantId': _tenantId,
      'verificationId': verificationId,
      'sessionId': sessionId,
      'hasState': state != null,
    });

    this.state = this.state.copyWith(isLoading: true, error: null);
    try {
      await _kycService.processOAuthCallback(
        tenantId: _tenantId,
        code: code,
        verificationId: verificationId,
        state: state,
        sessionId: sessionId,
      );

      AppLogger.info('[KYC Flow] processOAuthCallback success', data: {
        'tenantId': _tenantId,
        'verificationId': verificationId,
      });

      this.state = this.state.copyWith(
        isLoading: false,
        status: KYCVerificationStatus.verified,
        verificationInProgress: false,
      );
    } catch (e) {
      AppLogger.error('[KYC Flow] processOAuthCallback failed', error: e);
      this.state = this.state.copyWith(
        isLoading: false,
        error: e.toString(),
        verificationInProgress: false,
      );
      rethrow;
    }
  }

  void reset() {
    state = KYCFlowState();
  }
}
