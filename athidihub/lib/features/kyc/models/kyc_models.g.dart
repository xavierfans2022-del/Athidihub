// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'kyc_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

KYCVerification _$KYCVerificationFromJson(Map<String, dynamic> json) =>
    KYCVerification(
      id: json['id'] as String,
      tenantId: json['tenantId'] as String,
      status: $enumDecode(_$KYCVerificationStatusEnumMap, json['status']),
      provider: $enumDecode(_$KYCVerificationProviderEnumMap, json['provider']),
      verifiedFullName: json['verifiedFullName'] as String?,
      verifiedEmail: json['verifiedEmail'] as String?,
      verifiedDOB: json['verifiedDOB'] == null
          ? null
          : DateTime.parse(json['verifiedDOB'] as String),
      maskedAadhaarNumber: json['maskedAadhaarNumber'] as String?,
      verificationReferenceId: json['verificationReferenceId'] as String?,
        digilockerSessionId: json['digilockerSessionId'] as String?,
        digilockerReferenceId: json['digilockerReferenceId'] as String?,
        verificationUrl: json['verificationUrl'] as String?,
      consentTimestamp: json['consentTimestamp'] == null
          ? null
          : DateTime.parse(json['consentTimestamp'] as String),
      failureReason: json['failureReason'] as String?,
      failureCount: (json['failureCount'] as num).toInt(),
      nextRetryAt: json['nextRetryAt'] == null
          ? null
          : DateTime.parse(json['nextRetryAt'] as String),
      expiresAt: json['expiresAt'] == null
          ? null
          : DateTime.parse(json['expiresAt'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$KYCVerificationToJson(KYCVerification instance) =>
    <String, dynamic>{
      'id': instance.id,
      'tenantId': instance.tenantId,
      'status': _$KYCVerificationStatusEnumMap[instance.status]!,
      'provider': _$KYCVerificationProviderEnumMap[instance.provider]!,
      'verifiedFullName': instance.verifiedFullName,
      'verifiedEmail': instance.verifiedEmail,
      'verifiedDOB': instance.verifiedDOB?.toIso8601String(),
      'maskedAadhaarNumber': instance.maskedAadhaarNumber,
      'verificationReferenceId': instance.verificationReferenceId,
      'digilockerSessionId': instance.digilockerSessionId,
      'digilockerReferenceId': instance.digilockerReferenceId,
      'verificationUrl': instance.verificationUrl,
      'consentTimestamp': instance.consentTimestamp?.toIso8601String(),
      'failureReason': instance.failureReason,
      'failureCount': instance.failureCount,
      'nextRetryAt': instance.nextRetryAt?.toIso8601String(),
      'expiresAt': instance.expiresAt?.toIso8601String(),
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
    };

const _$KYCVerificationStatusEnumMap = {
  KYCVerificationStatus.pending: 'PENDING',
  KYCVerificationStatus.inProgress: 'IN_PROGRESS',
  KYCVerificationStatus.verified: 'VERIFIED',
  KYCVerificationStatus.rejected: 'REJECTED',
  KYCVerificationStatus.manualReview: 'MANUAL_REVIEW',
  KYCVerificationStatus.expired: 'EXPIRED',
  KYCVerificationStatus.retry: 'RETRY',
};

const _$KYCVerificationProviderEnumMap = {
  KYCVerificationProvider.digilocker: 'DIGILOCKER',
  KYCVerificationProvider.setu: 'SETU',
  KYCVerificationProvider.signzy: 'SIGNZY',
  KYCVerificationProvider.hyperverge: 'HYPERVERGE',
  KYCVerificationProvider.manual: 'MANUAL',
};

KYCDocument _$KYCDocumentFromJson(Map<String, dynamic> json) => KYCDocument(
      id: json['id'] as String,
      documentType: $enumDecode(_$KYCDocumentTypeEnumMap, json['documentType']),
  fileUrl: json['fileUrl'] as String?,
      verified: json['verified'] as bool,
      verificationScore: (json['verificationScore'] as num?)?.toInt(),
      rejectionReason: json['rejectionReason'] as String?,
      uploadedAt: DateTime.parse(json['uploadedAt'] as String),
      verifiedAt: json['verifiedAt'] == null
          ? null
          : DateTime.parse(json['verifiedAt'] as String),
    );

Map<String, dynamic> _$KYCDocumentToJson(KYCDocument instance) =>
    <String, dynamic>{
      'id': instance.id,
      'documentType': _$KYCDocumentTypeEnumMap[instance.documentType]!,
  'fileUrl': instance.fileUrl,
      'verified': instance.verified,
      'verificationScore': instance.verificationScore,
      'rejectionReason': instance.rejectionReason,
      'uploadedAt': instance.uploadedAt.toIso8601String(),
      'verifiedAt': instance.verifiedAt?.toIso8601String(),
    };

const _$KYCDocumentTypeEnumMap = {
  KYCDocumentType.aadhaarFront: 'AADHAAR_FRONT',
  KYCDocumentType.aadhaarBack: 'AADHAAR_BACK',
  KYCDocumentType.pan: 'PAN',
  KYCDocumentType.selfie: 'SELFIE',
};

KYCStatus _$KYCStatusFromJson(Map<String, dynamic> json) => KYCStatus(
      status: $enumDecode(_$KYCVerificationStatusEnumMap, json['status']),
      completionPercentage: (json['completionPercentage'] as num).toInt(),
      documents: (json['documents'] as List<dynamic>)
          .map((e) => KYCDocument.fromJson(e as Map<String, dynamic>))
          .toList(),
      verification: json['verification'] == null
          ? null
          : KYCVerification.fromJson(
              json['verification'] as Map<String, dynamic>),
      errorMessage: json['errorMessage'] as String?,
      nextAction: json['nextAction'] as String?,
    );

Map<String, dynamic> _$KYCStatusToJson(KYCStatus instance) => <String, dynamic>{
      'status': _$KYCVerificationStatusEnumMap[instance.status]!,
      'completionPercentage': instance.completionPercentage,
      'documents': instance.documents.map((e) => e.toJson()).toList(),
      'verification': instance.verification?.toJson(),
      'errorMessage': instance.errorMessage,
      'nextAction': instance.nextAction,
    };

InitiateKYCResponse _$InitiateKYCResponseFromJson(Map<String, dynamic> json) =>
    InitiateKYCResponse(
      kycVerificationId: json['kycVerificationId'] as String,
      sessionId: json['sessionId'] as String,
      verificationUrl: json['verificationUrl'] as String,
      webViewUrl: json['webViewUrl'] as String?,
      expiryInSeconds: (json['expiryInSeconds'] as num).toInt(),
      status: $enumDecode(_$KYCVerificationStatusEnumMap, json['status']),
    );

Map<String, dynamic> _$InitiateKYCResponseToJson(
        InitiateKYCResponse instance) =>
    <String, dynamic>{
      'kycVerificationId': instance.kycVerificationId,
      'sessionId': instance.sessionId,
      'verificationUrl': instance.verificationUrl,
      'webViewUrl': instance.webViewUrl,
      'expiryInSeconds': instance.expiryInSeconds,
      'status': _$KYCVerificationStatusEnumMap[instance.status]!,
    };

KYCUploadResponse _$KYCUploadResponseFromJson(Map<String, dynamic> json) =>
    KYCUploadResponse(
      success: json['success'] as bool,
      documentId: json['documentId'] as String,
      document: KYCDocument.fromJson(json['document'] as Map<String, dynamic>),
      message: json['message'] as String,
    );

Map<String, dynamic> _$KYCUploadResponseToJson(KYCUploadResponse instance) =>
    <String, dynamic>{
      'success': instance.success,
      'documentId': instance.documentId,
      'document': instance.document.toJson(),
      'message': instance.message,
    };

KYCAuditLog _$KYCAuditLogFromJson(Map<String, dynamic> json) => KYCAuditLog(
      id: json['id'] as String,
      action: json['action'] as String,
      actor: json['actor'] == null
          ? null
          : AuditActor.fromJson(json['actor'] as Map<String, dynamic>),
      createdAt: DateTime.parse(json['createdAt'] as String),
      details: json['details'] as Map<String, dynamic>?,
    );

Map<String, dynamic> _$KYCAuditLogToJson(KYCAuditLog instance) =>
    <String, dynamic>{
      'id': instance.id,
      'action': instance.action,
      'actor': instance.actor?.toJson(),
      'createdAt': instance.createdAt.toIso8601String(),
      'details': instance.details,
    };

AuditActor _$AuditActorFromJson(Map<String, dynamic> json) => AuditActor(
      id: json['id'] as String,
      role: json['role'] as String,
    );

Map<String, dynamic> _$AuditActorToJson(AuditActor instance) =>
    <String, dynamic>{
      'id': instance.id,
      'role': instance.role,
    };

KYCDetails _$KYCDetailsFromJson(Map<String, dynamic> json) => KYCDetails(
      verification: KYCVerification.fromJson(
          json['verification'] as Map<String, dynamic>),
      documents: (json['documents'] as List<dynamic>)
          .map((e) => KYCDocument.fromJson(e as Map<String, dynamic>))
          .toList(),
      auditLogs: (json['auditLogs'] as List<dynamic>)
          .map((e) => KYCAuditLog.fromJson(e as Map<String, dynamic>))
          .toList(),
      tenantInfo: json['tenantInfo'] == null
          ? null
          : TenantInfo.fromJson(json['tenantInfo'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$KYCDetailsToJson(KYCDetails instance) =>
    <String, dynamic>{
      'verification': instance.verification.toJson(),
      'documents': instance.documents.map((e) => e.toJson()).toList(),
      'auditLogs': instance.auditLogs.map((e) => e.toJson()).toList(),
      'tenantInfo': instance.tenantInfo?.toJson(),
    };

TenantInfo _$TenantInfoFromJson(Map<String, dynamic> json) => TenantInfo(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      phone: json['phone'] as String,
      organizationId: json['organizationId'] as String,
    );

Map<String, dynamic> _$TenantInfoToJson(TenantInfo instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'email': instance.email,
      'phone': instance.phone,
      'organizationId': instance.organizationId,
    };
