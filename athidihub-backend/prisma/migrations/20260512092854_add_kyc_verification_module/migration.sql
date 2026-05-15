-- CreateEnum
CREATE TYPE "KYCVerificationStatus" AS ENUM ('PENDING', 'IN_PROGRESS', 'VERIFIED', 'REJECTED', 'MANUAL_REVIEW', 'EXPIRED', 'RETRY');

-- CreateEnum
CREATE TYPE "KYCVerificationProvider" AS ENUM ('DIGILOCKER', 'SETU', 'SIGNZY', 'HYPERVERGE', 'MANUAL');

-- CreateEnum
CREATE TYPE "KYCDocumentType" AS ENUM ('AADHAAR_FRONT', 'AADHAAR_BACK', 'PAN', 'SELFIE');

-- CreateEnum
CREATE TYPE "AuditActionType" AS ENUM ('VERIFICATION_INITIATED', 'VERIFICATION_COMPLETED', 'VERIFICATION_FAILED', 'VERIFICATION_APPROVED', 'VERIFICATION_REJECTED', 'DOCUMENT_UPLOADED', 'DOCUMENT_VERIFIED', 'DOCUMENT_REJECTED', 'ADMIN_REVIEW_ASSIGNED', 'ADMIN_APPROVED', 'ADMIN_REJECTED', 'CONSENT_GRANTED', 'CONSENT_REVOKED', 'VERIFICATION_RETRIED');

-- CreateTable
CREATE TABLE "KYCVerification" (
    "id" TEXT NOT NULL,
    "tenantId" TEXT NOT NULL,
    "organizationId" TEXT NOT NULL,
    "status" "KYCVerificationStatus" NOT NULL DEFAULT 'PENDING',
    "provider" "KYCVerificationProvider" NOT NULL DEFAULT 'DIGILOCKER',
    "verifiedFullName" TEXT,
    "verifiedEmail" TEXT,
    "verifiedPhone" TEXT,
    "verifiedDOB" TIMESTAMP(3),
    "verifiedAddress" TEXT,
    "maskedAadhaarNumber" TEXT,
    "verificationReferenceId" TEXT,
    "providerTransactionId" TEXT,
    "consentTimestamp" TIMESTAMP(3),
    "consentGrantedAt" TIMESTAMP(3),
    "consentRevokedAt" TIMESTAMP(3),
    "failureReason" TEXT,
    "failureCount" INTEGER NOT NULL DEFAULT 0,
    "lastFailureAt" TIMESTAMP(3),
    "nextRetryAt" TIMESTAMP(3),
    "reviewedBy" TEXT,
    "reviewedAt" TIMESTAMP(3),
    "adminNotes" TEXT,
    "flaggedForSuspicion" BOOLEAN NOT NULL DEFAULT false,
    "suspicionReason" TEXT,
    "expiresAt" TIMESTAMP(3),
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "KYCVerification_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "KYCDocument" (
    "id" TEXT NOT NULL,
    "kycVerificationId" TEXT NOT NULL,
    "documentType" "KYCDocumentType" NOT NULL,
    "fileUrl" TEXT NOT NULL,
    "fileName" TEXT NOT NULL,
    "fileSize" INTEGER NOT NULL,
    "mimeType" TEXT NOT NULL,
    "uploadedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "verified" BOOLEAN NOT NULL DEFAULT false,
    "verificationScore" INTEGER,
    "verifiedAt" TIMESTAMP(3),
    "rejectionReason" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "KYCDocument_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "KYCAuditLog" (
    "id" TEXT NOT NULL,
    "kycVerificationId" TEXT NOT NULL,
    "action" "AuditActionType" NOT NULL,
    "actorId" TEXT,
    "actorRole" TEXT,
    "details" JSONB,
    "reason" TEXT,
    "ipAddress" TEXT,
    "userAgent" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "KYCAuditLog_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "KYCWebhookLog" (
    "id" TEXT NOT NULL,
    "kycVerificationId" TEXT NOT NULL,
    "provider" "KYCVerificationProvider" NOT NULL,
    "webhookEvent" TEXT NOT NULL,
    "webhookPayload" JSONB NOT NULL,
    "signatureValid" BOOLEAN NOT NULL DEFAULT false,
    "processedAt" TIMESTAMP(3),
    "errorMessage" TEXT,
    "retryCount" INTEGER NOT NULL DEFAULT 0,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "KYCWebhookLog_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "KYCVerification_tenantId_key" ON "KYCVerification"("tenantId");

-- AddForeignKey
ALTER TABLE "KYCVerification" ADD CONSTRAINT "KYCVerification_tenantId_fkey" FOREIGN KEY ("tenantId") REFERENCES "Tenant"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "KYCVerification" ADD CONSTRAINT "KYCVerification_organizationId_fkey" FOREIGN KEY ("organizationId") REFERENCES "Organization"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "KYCDocument" ADD CONSTRAINT "KYCDocument_kycVerificationId_fkey" FOREIGN KEY ("kycVerificationId") REFERENCES "KYCVerification"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "KYCAuditLog" ADD CONSTRAINT "KYCAuditLog_kycVerificationId_fkey" FOREIGN KEY ("kycVerificationId") REFERENCES "KYCVerification"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "KYCWebhookLog" ADD CONSTRAINT "KYCWebhookLog_kycVerificationId_fkey" FOREIGN KEY ("kycVerificationId") REFERENCES "KYCVerification"("id") ON DELETE CASCADE ON UPDATE CASCADE;
