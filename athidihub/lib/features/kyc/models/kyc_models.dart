import 'package:json_annotation/json_annotation.dart';

part 'kyc_models.g.dart';

enum KYCVerificationStatus {
  @JsonValue('PENDING')
  pending,
  @JsonValue('IN_PROGRESS')
  inProgress,
  @JsonValue('VERIFIED')
  verified,
  @JsonValue('REJECTED')
  rejected,
  @JsonValue('MANUAL_REVIEW')
  manualReview,
  @JsonValue('EXPIRED')
  expired,
  @JsonValue('RETRY')
  retry,
}

enum KYCVerificationProvider {
  @JsonValue('DIGILOCKER')
  digilocker,
  @JsonValue('SETU')
  setu,
  @JsonValue('SIGNZY')
  signzy,
  @JsonValue('HYPERVERGE')
  hyperverge,
  @JsonValue('MANUAL')
  manual,
}

enum KYCDocumentType {
  @JsonValue('AADHAAR_FRONT')
  aadhaarFront,
  @JsonValue('AADHAAR_BACK')
  aadhaarBack,
  @JsonValue('PAN')
  pan,
  @JsonValue('SELFIE')
  selfie,
}

@JsonSerializable(explicitToJson: true)
class KYCVerification {
  final String id;
  final String tenantId;
  final KYCVerificationStatus status;
  final KYCVerificationProvider provider;
  final String? verifiedFullName;
  final String? verifiedEmail;
  final DateTime? verifiedDOB;
  final String? maskedAadhaarNumber;
  final String? verificationReferenceId;
  final String? digilockerSessionId;
  final String? digilockerReferenceId;
  final String? verificationUrl;
  final DateTime? consentTimestamp;
  final String? failureReason;
  final int failureCount;
  final DateTime? nextRetryAt;
  final DateTime? expiresAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  KYCVerification({
    required this.id,
    required this.tenantId,
    required this.status,
    required this.provider,
    this.verifiedFullName,
    this.verifiedEmail,
    this.verifiedDOB,
    this.maskedAadhaarNumber,
    this.verificationReferenceId,
    this.digilockerSessionId,
    this.digilockerReferenceId,
    this.verificationUrl,
    this.consentTimestamp,
    this.failureReason,
    required this.failureCount,
    this.nextRetryAt,
    this.expiresAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory KYCVerification.fromJson(Map<String, dynamic> json) => _$KYCVerificationFromJson(json);
  Map<String, dynamic> toJson() => _$KYCVerificationToJson(this);

  bool get isVerified => status == KYCVerificationStatus.verified;
  bool get isPending => status == KYCVerificationStatus.pending;
  bool get isInProgress => status == KYCVerificationStatus.inProgress;
  bool get isRejected => status == KYCVerificationStatus.rejected;
  bool get needsManualReview => status == KYCVerificationStatus.manualReview;
  bool get canRetry => status == KYCVerificationStatus.retry || status == KYCVerificationStatus.rejected;
  bool get isExpired => status == KYCVerificationStatus.expired;
}

@JsonSerializable(explicitToJson: true)
class KYCDocument {
  final String id;
  final KYCDocumentType documentType;
  final String? fileUrl;
  final bool verified;
  final int? verificationScore;
  final String? rejectionReason;
  final DateTime uploadedAt;
  final DateTime? verifiedAt;

  KYCDocument({
    required this.id,
    required this.documentType,
    this.fileUrl,
    required this.verified,
    this.verificationScore,
    this.rejectionReason,
    required this.uploadedAt,
    this.verifiedAt,
  });

  factory KYCDocument.fromJson(Map<String, dynamic> json) => _$KYCDocumentFromJson(json);
  Map<String, dynamic> toJson() => _$KYCDocumentToJson(this);
}

@JsonSerializable(explicitToJson: true)
class KYCStatus {
  final KYCVerificationStatus status;
  final int completionPercentage;
  final List<KYCDocument> documents;
  final KYCVerification? verification;
  final String? errorMessage;
  final String? nextAction;

  KYCStatus({
    required this.status,
    required this.completionPercentage,
    required this.documents,
    this.verification,
    this.errorMessage,
    this.nextAction,
  });

  factory KYCStatus.fromJson(Map<String, dynamic> json) => _$KYCStatusFromJson(json);
  Map<String, dynamic> toJson() => _$KYCStatusToJson(this);
}

@JsonSerializable(explicitToJson: true)
class InitiateKYCResponse {
  final String kycVerificationId;
  final String sessionId;
  final String verificationUrl;
  final String? webViewUrl;
  final int expiryInSeconds;
  final KYCVerificationStatus status;

  InitiateKYCResponse({
    required this.kycVerificationId,
    required this.sessionId,
    required this.verificationUrl,
    this.webViewUrl,
    required this.expiryInSeconds,
    required this.status,
  });

  factory InitiateKYCResponse.fromJson(Map<String, dynamic> json) =>
      _$InitiateKYCResponseFromJson(json);
  Map<String, dynamic> toJson() => _$InitiateKYCResponseToJson(this);
}

@JsonSerializable(explicitToJson: true)
class KYCUploadResponse {
  final bool success;
  final String documentId;
  final KYCDocument document;
  final String message;

  KYCUploadResponse({
    required this.success,
    required this.documentId,
    required this.document,
    required this.message,
  });

  factory KYCUploadResponse.fromJson(Map<String, dynamic> json) =>
      _$KYCUploadResponseFromJson(json);
  Map<String, dynamic> toJson() => _$KYCUploadResponseToJson(this);
}

@JsonSerializable(explicitToJson: true)
class KYCAuditLog {
  final String id;
  final String action;
  final AuditActor? actor;
  final DateTime createdAt;
  final Map<String, dynamic>? details;

  KYCAuditLog({
    required this.id,
    required this.action,
    this.actor,
    required this.createdAt,
    this.details,
  });

  factory KYCAuditLog.fromJson(Map<String, dynamic> json) => _$KYCAuditLogFromJson(json);
  Map<String, dynamic> toJson() => _$KYCAuditLogToJson(this);
}

@JsonSerializable()
class AuditActor {
  final String id;
  final String role;

  AuditActor({required this.id, required this.role});

  factory AuditActor.fromJson(Map<String, dynamic> json) => _$AuditActorFromJson(json);
  Map<String, dynamic> toJson() => _$AuditActorToJson(this);
}

@JsonSerializable(explicitToJson: true)
class KYCDetails {
  final KYCVerification verification;
  final List<KYCDocument> documents;
  final List<KYCAuditLog> auditLogs;
  final TenantInfo? tenantInfo;

  KYCDetails({
    required this.verification,
    required this.documents,
    required this.auditLogs,
    this.tenantInfo,
  });

  factory KYCDetails.fromJson(Map<String, dynamic> json) => _$KYCDetailsFromJson(json);
  Map<String, dynamic> toJson() => _$KYCDetailsToJson(this);
}

@JsonSerializable()
class TenantInfo {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String organizationId;

  TenantInfo({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.organizationId,
  });

  factory TenantInfo.fromJson(Map<String, dynamic> json) => _$TenantInfoFromJson(json);
  Map<String, dynamic> toJson() => _$TenantInfoToJson(this);
}
