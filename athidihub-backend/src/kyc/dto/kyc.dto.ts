import { IsString, IsEnum, IsOptional, IsEmail, IsPhoneNumber, IsDateString, IsArray, Min, Max, IsNumber, IsBoolean } from 'class-validator';
import { KYCVerificationStatus, KYCVerificationProvider, KYCDocumentType } from '@prisma/client';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';

// ─── KYC VERIFICATION REQUESTS ────────────────────────────

export class InitiateKYCVerificationDto {
  @ApiProperty({ description: 'Tenant ID' })
  @IsString()
  tenantId: string;

  @ApiPropertyOptional({
    description: 'Preferred verification provider',
    enum: KYCVerificationProvider,
  })
  @IsEnum(KYCVerificationProvider)
  @IsOptional()
  provider?: KYCVerificationProvider = KYCVerificationProvider.DIGILOCKER;

  @ApiPropertyOptional({ description: 'Redirect URL after verification' })
  @IsString()
  @IsOptional()
  redirectUrl?: string;

  @ApiPropertyOptional({
    description: 'Force the DigiLocker sandbox initiation flow and skip provider fallback',
    default: true,
  })
  @IsBoolean()
  @IsOptional()
  sandboxMode?: boolean = true;
}

export class RetryKYCVerificationDto {
  @ApiProperty({ description: 'Tenant ID to retry verification' })
  @IsString()
  tenantId: string;

  @ApiPropertyOptional({ description: 'Manual notes on retry reason' })
  @IsString()
  @IsOptional()
  reason?: string;
}

export class VerifyDocumentUploadDto {
  @ApiProperty({ description: 'Tenant ID' })
  @IsString()
  tenantId: string;

  @ApiProperty({ description: 'Document type', enum: KYCDocumentType })
  @IsEnum(KYCDocumentType)
  documentType: KYCDocumentType;

  @ApiProperty({ description: 'Base64 encoded file or file URL' })
  @IsString()
  fileData: string;

  @ApiPropertyOptional({ description: 'Original file size in bytes' })
  @IsNumber()
  @IsOptional()
  fileSize?: number;

  @ApiPropertyOptional({ description: 'File name' })
  @IsString()
  @IsOptional()
  fileName?: string;

  @ApiPropertyOptional({ description: 'MIME type' })
  @IsString()
  @IsOptional()
  mimeType?: string = 'application/octet-stream';
}

export class AdminApproveKYCDto {
  @ApiPropertyOptional({ description: 'Admin notes/reason for approval' })
  @IsString()
  @IsOptional()
  adminNotes?: string;

  @ApiPropertyOptional({ description: 'Whether to flag for suspension' })
  @IsBoolean()
  @IsOptional()
  flaggedForSuspicion?: boolean = false;

  @ApiPropertyOptional({ description: 'Reason for flagging if applicable' })
  @IsString()
  @IsOptional()
  suspicionReason?: string;
}

export class AdminRejectKYCDto {
  @ApiProperty({ description: 'Rejection reason (required for audit)' })
  @IsString()
  rejectionReason: string;

  @ApiPropertyOptional({ description: 'Admin notes' })
  @IsString()
  @IsOptional()
  adminNotes?: string;

  @ApiPropertyOptional({ description: 'Whether to allow retry' })
  @IsBoolean()
  @IsOptional()
  allowRetry?: boolean = true;
}

export class DigiLockerSandboxCallbackDto {
  @ApiProperty({ description: 'Webhook event type' })
  @IsString()
  event: string;

  @ApiProperty({ description: 'Verification status reported by DigiLocker' })
  @IsString()
  status: string;

  @ApiProperty({ description: 'Sandbox session state returned by DigiLocker' })
  @IsString()
  state: string;

  @ApiPropertyOptional({ description: 'Provider request ID' })
  @IsString()
  @IsOptional()
  request_id?: string;

  @ApiPropertyOptional({ description: 'Provider reference ID' })
  @IsString()
  @IsOptional()
  reference_id?: string;

  @ApiPropertyOptional({ description: 'Verified full name' })
  @IsString()
  @IsOptional()
  name?: string;

  @ApiPropertyOptional({ description: 'Masked or full Aadhaar number' })
  @IsString()
  @IsOptional()
  aadhaar_number?: string;

  @ApiPropertyOptional({ description: 'Date of birth' })
  @IsString()
  @IsOptional()
  dob?: string;

  @ApiPropertyOptional({ description: 'Address returned by DigiLocker' })
  @IsString()
  @IsOptional()
  address?: string;

  @ApiPropertyOptional({ description: 'Email returned by DigiLocker' })
  @IsString()
  @IsOptional()
  email?: string;

  @ApiPropertyOptional({ description: 'Phone number returned by DigiLocker' })
  @IsString()
  @IsOptional()
  phone?: string;

  @ApiPropertyOptional({ description: 'Consent timestamp returned by DigiLocker' })
  @IsString()
  @IsOptional()
  consent_timestamp?: string;

  @ApiPropertyOptional({ description: 'Callback timestamp' })
  @IsString()
  @IsOptional()
  timestamp?: string;

  @ApiPropertyOptional({ description: 'Callback signature' })
  @IsString()
  @IsOptional()
  signature?: string;
}

// ─── KYC VERIFICATION RESPONSES ───────────────────────────

export class KYCVerificationResponseDto {
  @ApiProperty({ description: 'KYC Verification ID' })
  id: string;

  @ApiProperty({ description: 'Tenant ID' })
  tenantId: string;

  @ApiProperty({ description: 'Current verification status', enum: KYCVerificationStatus })
  status: KYCVerificationStatus;

  @ApiProperty({ description: 'Verification provider', enum: KYCVerificationProvider })
  provider: KYCVerificationProvider;

  @ApiPropertyOptional({ description: 'Verified full name' })
  verifiedFullName?: string;

  @ApiPropertyOptional({ description: 'Verified email' })
  verifiedEmail?: string;

  @ApiPropertyOptional({ description: 'Verified date of birth' })
  verifiedDOB?: string;

  @ApiPropertyOptional({ description: 'Masked Aadhaar (last 4 digits)' })
  maskedAadhaarNumber?: string;

  @ApiPropertyOptional({ description: 'Verification reference ID' })
  verificationReferenceId?: string;

  @ApiPropertyOptional({ description: 'Stored DigiLocker session ID' })
  digilockerSessionId?: string;

  @ApiPropertyOptional({ description: 'Stored DigiLocker callback reference ID' })
  digilockerReferenceId?: string;

  @ApiPropertyOptional({ description: 'Stored verification URL' })
  verificationUrl?: string;

  @ApiPropertyOptional({ description: 'Consent timestamp' })
  consentTimestamp?: string;

  @ApiPropertyOptional({ description: 'Failure reason if applicable' })
  failureReason?: string;

  @ApiProperty({ description: 'Failure count' })
  failureCount: number;

  @ApiPropertyOptional({ description: 'Next retry available at' })
  nextRetryAt?: string;

  @ApiPropertyOptional({ description: 'Verification expires at' })
  expiresAt?: string;

  @ApiProperty({ description: 'Created at timestamp' })
  createdAt: string;

  @ApiProperty({ description: 'Last updated at timestamp' })
  updatedAt: string;
}

export class KYCStatusResponseDto {
  @ApiProperty({ description: 'Overall KYC verification status' })
  status: KYCVerificationStatus;

  @ApiProperty({ description: 'Percentage of KYC completion (0-100)' })
  completionPercentage: number;

  @ApiProperty({ description: 'List of uploaded documents' })
  documents: KYCDocumentResponseDto[];

  @ApiPropertyOptional({ description: 'Detailed verification info if available' })
  verification?: KYCVerificationResponseDto;

  @ApiPropertyOptional({ description: 'Error message if applicable' })
  errorMessage?: string;

  @ApiPropertyOptional({ description: 'Next action required' })
  nextAction?: string;
}

export class KYCDocumentResponseDto {
  @ApiProperty({ description: 'Document ID' })
  id: string;

  @ApiProperty({ description: 'Document type', enum: KYCDocumentType })
  documentType: KYCDocumentType;

  @ApiPropertyOptional({ description: 'Public URL or secure reference for the uploaded document' })
  fileUrl?: string;

  @ApiProperty({ description: 'Whether document is verified' })
  verified: boolean;

  @ApiPropertyOptional({ description: 'Verification confidence score (0-100)' })
  verificationScore?: number;

  @ApiPropertyOptional({ description: 'Rejection reason if applicable' })
  rejectionReason?: string;

  @ApiProperty({ description: 'Upload timestamp' })
  uploadedAt: string;

  @ApiPropertyOptional({ description: 'Verification timestamp' })
  verifiedAt?: string;
}

export class InitiateKYCResponseDto {
  @ApiProperty({ description: 'KYC Verification ID' })
  kycVerificationId: string;

  @ApiProperty({ description: 'Verification session ID (for tracking)' })
  sessionId: string;

  @ApiProperty({ description: 'Verification provider URL for redirect' })
  verificationUrl: string;

  @ApiPropertyOptional({ description: 'WebView callback URL if applicable' })
  webViewUrl?: string;

  @ApiProperty({ description: 'Session expiry time in seconds' })
  expiryInSeconds: number;

  @ApiProperty({ description: 'Verification status' })
  status: KYCVerificationStatus;
}

export class KYCDocumentListResponseDto {
  @ApiProperty({ description: 'List of documents' })
  documents: KYCDocumentResponseDto[];

  @ApiProperty({ description: 'Total documents uploaded' })
  totalCount: number;

  @ApiProperty({ description: 'Verified documents count' })
  verifiedCount: number;

  @ApiProperty({ description: 'Pending verification count' })
  pendingCount: number;

  @ApiProperty({ description: 'Rejected documents count' })
  rejectedCount: number;
}

export class KYCUploadResponseDto {
  @ApiProperty({ description: 'Upload success status' })
  success: boolean;

  @ApiProperty({ description: 'Document ID' })
  documentId: string;

  @ApiProperty({ description: 'Uploaded document details' })
  document: KYCDocumentResponseDto;

  @ApiProperty({ description: 'Upload message' })
  message: string;
}

// ─── ADMIN RESPONSES ──────────────────────────────────────

export class KYCAuditLogResponseDto {
  @ApiProperty({ description: 'Audit log ID' })
  id: string;

  @ApiProperty({ description: 'Action performed' })
  action: string;

  @ApiPropertyOptional({ description: 'Actor information' })
  actor?: {
    id: string;
    role: string;
  };

  @ApiProperty({ description: 'Action timestamp' })
  createdAt: string;

  @ApiPropertyOptional({ description: 'Action details' })
  details?: Record<string, any>;
}

export class AdminKYCReviewListDto {
  @ApiProperty({ description: 'Pending KYC verifications for review' })
  pending: Array<{
    id: string;
    tenantId: string;
    tenantName: string;
    tenantEmail: string;
    organizationId: string;
    status: KYCVerificationStatus;
    failureCount: number;
    uploadedDocumentsCount: number;
    createdAt: string;
    lastUpdatedAt: string;
    flaggedForSuspicion: boolean;
  }>;

  @ApiProperty({ description: 'Total pending count' })
  totalPending: number;

  @ApiProperty({ description: 'Paginated offset' })
  skip: number;

  @ApiProperty({ description: 'Paginated limit' })
  take: number;
}

export class AdminKYCDetailDto {
  @ApiProperty({ description: 'KYC verification details' })
  verification: KYCVerificationResponseDto;

  @ApiProperty({ description: 'Uploaded documents' })
  documents: KYCDocumentResponseDto[];

  @ApiProperty({ description: 'Audit trail' })
  auditLogs: KYCAuditLogResponseDto[];

  @ApiPropertyOptional({ description: 'Tenant basic information' })
  tenantInfo?: {
    id: string;
    name: string;
    email: string;
    phone: string;
    organizationId: string;
  };
}

export class AdminApprovalResponseDto {
  @ApiProperty({ description: 'Success status' })
  success: boolean;

  @ApiProperty({ description: 'Updated verification status' })
  status: KYCVerificationStatus;

  @ApiProperty({ description: 'Status message' })
  message: string;

  @ApiProperty({ description: 'Tenant can proceed with check-in' })
  canProceedWithCheckIn: boolean;
}
