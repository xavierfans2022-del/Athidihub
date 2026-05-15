import { Injectable, BadRequestException, NotFoundException, ConflictException, Logger } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { Prisma, KYCVerificationStatus, KYCVerificationProvider, AuditActionType, KYCDocumentType } from '@prisma/client';
import { CryptoService } from '../common/crypto/crypto.service';
import * as crypto from 'crypto';
import axios from 'axios';

interface VerificationProvider {
  initiateVerification(
    kycVerificationId: string,
    tenantData: any,
    redirectUrl: string,
  ): Promise<{ verificationUrl: string; sessionId: string; expiryInSeconds: number }>;
  validateWebhook(payload: any, signature: string): boolean;
  parseWebhookPayload(payload: any): Promise<any>;
  fetchDocuments(sessionId: string): Promise<any>;
}

@Injectable()
export class KYCService {
  private logger = new Logger('KYCService');
  private providers: Map<string, VerificationProvider> = new Map();

  constructor(
    private prisma: PrismaService,
    private cryptoService: CryptoService,
  ) {
    this.initializeProviders();
  }

  private initializeProviders() {
    // Primary provider is DigiLocker via Sandbox
    this.providers.set(KYCVerificationProvider.DIGILOCKER, new DigiLockerProvider(this.logger));
  }

  // ─── VERIFICATION INITIATION ──────────────────────────────

  async initiateKYCVerification(
    tenantId: string,
    organizationId: string | undefined,
    provider: KYCVerificationProvider = KYCVerificationProvider.DIGILOCKER,
    redirectUrl: string,
    sandboxMode = true,
  ) {
    // Only DigiLocker is supported for automated verification
    if (provider !== KYCVerificationProvider.DIGILOCKER) {
      throw new BadRequestException('Currently only DigiLocker (Aadhaar) verification is supported.');
    }

    if (!this.isSandboxConfigured()) {
      throw new BadRequestException(
        'Sandbox configuration missing: set SANDBOX_CLIENT_ID and SANDBOX_CLIENT_SECRET.',
      );
    }

    // Check if tenant exists and is assigned to a bed
    const tenant = await this.prisma.tenant.findUnique({
      where: { id: tenantId },
      include: {
        assignments: {
          where: { isActive: true },
          take: 1,
        },
        kycVerification: true,
      },
    });

    if (!tenant) {
      throw new NotFoundException('Tenant not found');
    }

    if (tenant.assignments.length === 0) {
      throw new BadRequestException('Tenant must be assigned to a bed before KYC verification');
    }

    // Check if KYC already exists
    if (tenant.kycVerification) {
      const existingStatus = tenant.kycVerification.status;

      // Allow reuse of in-progress session if not expired
      if (
        (existingStatus === KYCVerificationStatus.PENDING ||
        existingStatus === KYCVerificationStatus.IN_PROGRESS) &&
        tenant.kycVerification.expiresAt && 
        tenant.kycVerification.expiresAt > new Date()
      ) {
        const existing = tenant.kycVerification;
        const sessionId = existing.digilockerSessionId || existing.providerTransactionId;
        const verificationUrl = existing.verificationUrl;

        if (sessionId && verificationUrl) {
          return {
            kycVerificationId: existing.id,
            sessionId,
            verificationUrl,
            expiryInSeconds: Math.max(0, Math.floor((tenant.kycVerification.expiresAt!.getTime() - Date.now()) / 1000)),
            status: existing.status,
          };
        }
      }

      if (
        existingStatus === KYCVerificationStatus.VERIFIED ||
        existingStatus === KYCVerificationStatus.MANUAL_REVIEW
      ) {
        throw new ConflictException('KYC verification already completed or under review');
      }
    }

    const resolvedOrganizationId = organizationId ?? tenant.organizationId;
    if (!resolvedOrganizationId) {
      throw new BadRequestException('Tenant organization is required for KYC verification');
    }

    // Create or update KYC verification record
    const kycVerification = await this.prisma.kYCVerification.upsert({
      where: { tenantId },
      update: {
        status: KYCVerificationStatus.PENDING,
        provider: KYCVerificationProvider.DIGILOCKER,
        failureCount: 0,
        organizationId: resolvedOrganizationId,
      },
      create: {
        status: KYCVerificationStatus.PENDING,
        provider: KYCVerificationProvider.DIGILOCKER,
        failureCount: 0,
        tenantId,
        organizationId: resolvedOrganizationId,
      },
    });

    // Get provider implementation
    const providerImpl = this.providers.get(KYCVerificationProvider.DIGILOCKER);
    if (!providerImpl) {
      throw new BadRequestException('DigiLocker provider not initialized');
    }

    try {
      // Initiate verification with Sandbox API
      const verificationData = await providerImpl.initiateVerification(
        kycVerification.id,
        {
          tenantId,
          name: tenant.name,
          email: tenant.email,
          phone: tenant.phone,
        },
        redirectUrl,
      );

      // Update KYC with provider session info
      await this.prisma.kYCVerification.update({
        where: { id: kycVerification.id },
        data: {
          status: KYCVerificationStatus.IN_PROGRESS,
          providerTransactionId: verificationData.sessionId,
          digilockerSessionId: verificationData.sessionId,
          verificationUrl: verificationData.verificationUrl,
          expiresAt: new Date(Date.now() + verificationData.expiryInSeconds * 1000),
        },
      });

      // Log audit
      await this.logAudit(
        kycVerification.id,
        AuditActionType.VERIFICATION_INITIATED,
        'SYSTEM',
        { provider: KYCVerificationProvider.DIGILOCKER, sessionId: verificationData.sessionId },
      );

      return {
        kycVerificationId: kycVerification.id,
        sessionId: verificationData.sessionId,
        verificationUrl: verificationData.verificationUrl,
        expiryInSeconds: verificationData.expiryInSeconds,
        status: KYCVerificationStatus.IN_PROGRESS,
      };
    } catch (error: unknown) {
      const message = error instanceof Error ? error.message : String(error);
      this.logger.error(`Failed to initiate KYC: ${message}`);
      throw new BadRequestException(`Verification initiation failed: ${message}`);
    }
  }

  private isSandboxConfigured(): boolean {
    return (
      !!process.env.SANDBOX_CLIENT_ID &&
      !!process.env.SANDBOX_CLIENT_SECRET
    );
  }

  // ─── WEBHOOK HANDLING ─────────────────────────────────────

  async handleWebhookCallback(
    provider: string,
    payload: any,
    signature: string,
    timestamp: string,
  ) {
    try {
      // Log webhook raw data
      const webhookLog = await this.logWebhook(provider, 'verification_callback', payload, true);

      // Find KYC verification record
      const sessionId = payload.session_id || payload.state || payload.request_id;
      if (!sessionId) {
        throw new BadRequestException('No session ID found in webhook payload');
      }

      const kycVerification = await this.prisma.kYCVerification.findFirst({
        where: {
          OR: [
            { providerTransactionId: sessionId },
            { digilockerSessionId: sessionId },
          ],
        },
      });

      if (!kycVerification) {
        this.logger.warn(`No KYC record found for session: ${sessionId}`);
        return { success: false, message: 'KYC record not found' };
      }

      // Check status with Sandbox API (Production-level verification)
      const providerImpl = this.providers.get(provider as KYCVerificationProvider);
      if (!providerImpl) {
        throw new BadRequestException(`Unknown provider: ${provider}`);
      }

      // Fetch actual data from Sandbox
      const documents = await providerImpl.fetchDocuments(sessionId);
      const aadhaarDoc = documents.find((d: any) => d.type === 'aadhaar' || d.doc_type === 'aadhaar');

      if (aadhaarDoc && aadhaarDoc.data) {
        const result = {
          success: true,
          sessionId,
          fullName: aadhaarDoc.data.name || aadhaarDoc.data.full_name,
          aadhaarNumber: aadhaarDoc.data.masked_number || aadhaarDoc.data.aadhaar_number,
          dob: aadhaarDoc.data.dob || aadhaarDoc.data.date_of_birth,
          address: aadhaarDoc.data.address,
          email: aadhaarDoc.data.email,
          phone: aadhaarDoc.data.phone,
        };
        await this.completeVerification(kycVerification.id, result);
      } else {
        await this.failVerification(
          kycVerification.id,
          'Aadhaar document not found in session',
          payload,
        );
      }

      // Mark webhook as processed
      await this.prisma.kYCWebhookLog.update({
        where: { id: webhookLog.id },
        data: { processedAt: new Date() },
      });

      return { success: true, message: 'Webhook processed successfully' };
    } catch (error: unknown) {
      const message = error instanceof Error ? error.message : String(error);
      this.logger.error(`Webhook processing failed: ${message}`);
      throw error;
    }
  }

  // ─── VERIFICATION COMPLETION ──────────────────────────────

  private async completeVerification(kycVerificationId: string, result: any) {
    const encryptedFullName = this.cryptoService.encrypt(result.fullName || 'Verified User');
    const encryptedAddress = this.cryptoService.encrypt(result.address || '');
    const encryptedEmail = this.cryptoService.encrypt(result.email || '');
    const encryptedPhone = this.cryptoService.encrypt(result.phone || '');

    const maskedAadhaar = result.aadhaarNumber
      ? (result.aadhaarNumber.length > 4 ? `****${result.aadhaarNumber.slice(-4)}` : result.aadhaarNumber)
      : null;

    const updated = await this.prisma.kYCVerification.update({
      where: { id: kycVerificationId },
      data: {
        status: KYCVerificationStatus.VERIFIED,
        verifiedFullName: encryptedFullName,
        verifiedEmail: encryptedEmail,
        verifiedPhone: encryptedPhone,
        verifiedDOB: result.dob ? new Date(result.dob) : null,
        verifiedAddress: encryptedAddress,
        maskedAadhaarNumber: maskedAadhaar,
        verificationReferenceId: result.sessionId,
        digilockerSessionId: result.sessionId,
        consentGrantedAt: new Date(),
        failureCount: 0,
      },
      include: { tenant: true }
    });

    await this.prisma.tenant.update({
      where: { id: updated.tenantId },
      data: {
        aadhaarVerified: true,
        aadhaarDetails: {
          name: result.fullName,
          maskedAadhaar: maskedAadhaar,
          dob: result.dob,
          address: result.address
        }
      }
    });

    await this.logAudit(kycVerificationId, AuditActionType.VERIFICATION_COMPLETED, 'SYSTEM', { result });
    await this.notifyVerificationComplete(updated.tenantId, true);

    return updated;
  }

  private async failVerification(kycVerificationId: string, reason: string, result?: any) {
    const kyc = await this.prisma.kYCVerification.findUnique({ where: { id: kycVerificationId } });
    const failureCount = (kyc?.failureCount || 0) + 1;
    const maxRetries = 3;

    let nextStatus: KYCVerificationStatus = KYCVerificationStatus.RETRY;
    let nextRetryTime = null;

    if (failureCount >= maxRetries) {
      nextStatus = KYCVerificationStatus.REJECTED;
    } else {
      nextRetryTime = new Date(Date.now() + 30 * 60 * 1000); // 30 mins
    }

    const updated = await this.prisma.kYCVerification.update({
      where: { id: kycVerificationId },
      data: {
        status: nextStatus,
        failureReason: reason,
        failureCount,
        lastFailureAt: new Date(),
        nextRetryAt: nextRetryTime,
      },
    });

    await this.logAudit(kycVerificationId, AuditActionType.VERIFICATION_FAILED, 'SYSTEM', { reason, failureCount });
    await this.notifyVerificationFailed(updated.tenantId, reason, failureCount >= maxRetries);

    return updated;
  }

  // ─── DOCUMENT UPLOAD (FALLBACK) ───────────────────────────

  async uploadDocument(
    tenantId: string,
    documentType: KYCDocumentType,
    fileData: string,
    fileName: string,
    mimeType: string,
    fileSize?: number,
  ) {
    let kycVerification = await this.prisma.kYCVerification.findUnique({ where: { tenantId } });

    if (!kycVerification) {
      const tenant = await this.prisma.tenant.findUnique({
        where: { id: tenantId },
        select: { organizationId: true },
      });

      if (!tenant?.organizationId) {
        throw new BadRequestException('Tenant organization not found');
      }

      kycVerification = await this.prisma.kYCVerification.create({
        data: {
          tenantId,
          organizationId: tenant.organizationId,
          status: KYCVerificationStatus.PENDING,
          provider: KYCVerificationProvider.MANUAL,
          failureCount: 0,
        },
      });
    }

    const fileUrl = this.resolveDocumentUrl(fileData);

    const document = await this.prisma.kYCDocument.create({
      data: {
        kycVerificationId: kycVerification.id,
        documentType,
        fileUrl,
        fileName,
        fileSize: fileSize ?? 0,
        mimeType,
      },
    });

    if (kycVerification.status !== KYCVerificationStatus.VERIFIED) {
      await this.prisma.kYCVerification.update({
        where: { id: kycVerification.id },
        data: { status: KYCVerificationStatus.MANUAL_REVIEW },
      });
    }

    return document;
  }

  // ─── OAUTH CALLBACK PROCESSING ────────────────────────────

  /// Process OAuth authorization code from DigiLocker callback (for app flow)
  async processOAuthCallback(
    tenantId: string,
    code: string,
    verificationId: string,
    state?: string,
    sessionId?: string,
  ): Promise<{ success: boolean; status: KYCVerificationStatus; message: string }> {
    this.logger.debug(`Processing OAuth callback for verification: ${verificationId}`);

    // Find KYC record
    const kycVerification = await this.prisma.kYCVerification.findUnique({
      where: { id: verificationId },
      include: { tenant: true },
    });

    if (!kycVerification) {
      throw new NotFoundException('KYC verification record not found');
    }

    if (kycVerification.tenantId !== tenantId) {
      throw new BadRequestException('Tenant ID mismatch');
    }

    if (kycVerification.status !== KYCVerificationStatus.IN_PROGRESS) {
      throw new BadRequestException(`Cannot process callback for status: ${kycVerification.status}`);
    }

    try {
      // Exchange authorization code for access token
      const providerImpl = this.providers.get(KYCVerificationProvider.DIGILOCKER);
      if (!providerImpl) {
        throw new BadRequestException('DigiLocker provider not initialized');
      }

      // Process the OAuth code with provider (this is handled by webhook internally)
      // For now, we'll mark it as verified and trigger webhook processing
      const webhookPayload = {
        session_id: kycVerification.digilockerSessionId || sessionId,
        reference_id: kycVerification.digilockerReferenceId,
        code,
        state,
        status: 'success',
      };

      // Process webhook asynchronously
      this.handleWebhookCallback(
        'DIGILOCKER',
        webhookPayload,
        '',
        '',
      ).catch((err) => this.logger.error(`Background webhook processing failed: ${err.message}`));

      // Update KYC status
      const updatedKyc = await this.prisma.kYCVerification.update({
        where: { id: verificationId },
        data: {
          status: KYCVerificationStatus.MANUAL_REVIEW,
          verificationReferenceId: code,
        },
      });

      await this.logAudit(verificationId, AuditActionType.VERIFICATION_INITIATED, 'APP', {
        provider: 'DIGILOCKER',
        method: 'OAUTH',
        code: code.substring(0, 10) + '***',
      });

      this.logger.log(`OAuth callback processed successfully for: ${verificationId}`);

      return {
        success: true,
        status: updatedKyc.status,
        message: 'Verification initiated. Please wait for approval.',
      };
    } catch (error: unknown) {
      const message = error instanceof Error ? error.message : String(error);
      this.logger.error(`OAuth callback processing failed: ${message}`);

      // Update KYC with failure
      await this.prisma.kYCVerification.update({
        where: { id: verificationId },
        data: {
          status: KYCVerificationStatus.REJECTED,
          failureReason: message,
          failureCount: { increment: 1 },
        },
      });

      await this.logAudit(verificationId, AuditActionType.VERIFICATION_FAILED, 'APP', {
        error: message,
      });

      throw error;
    }
  }

  // ─── UTILITIES ───────────────────────────────────────────

  private resolveDocumentUrl(fileData: string): string {
    const trimmed = fileData.trim();

    if (/^https?:\/\//i.test(trimmed)) {
      return trimmed;
    }

    throw new BadRequestException(
      'fileData must be a public Supabase URL for KYC document uploads',
    );
  }

  private async logAudit(kycId: string, action: AuditActionType, role: string, details?: any) {
    return this.prisma.kYCAuditLog.create({
      data: { kycVerificationId: kycId, action, actorRole: role, details },
    });
  }

  private async logWebhook(provider: string, event: string, payload: any, signatureValid: boolean) {
    const sessionId = payload.session_id || payload.state || payload.request_id;
    const kyc = await this.prisma.kYCVerification.findFirst({
      where: { OR: [{ providerTransactionId: sessionId }, { digilockerSessionId: sessionId }] },
    });

    return this.prisma.kYCWebhookLog.create({
      data: {
        kycVerificationId: kyc?.id || '',
        provider: provider as KYCVerificationProvider,
        webhookEvent: event,
        webhookPayload: payload,
        signatureValid,
      },
    });
  }

  async getKYCStatus(tenantId: string) {
    const kyc = await this.prisma.kYCVerification.findUnique({
      where: { tenantId },
      include: { documents: true },
    });

    if (!kyc) {
      return { status: KYCVerificationStatus.PENDING, completionPercentage: 0, documents: [] };
    }

    const completion = kyc.status === KYCVerificationStatus.VERIFIED ? 100 : (kyc.status === KYCVerificationStatus.MANUAL_REVIEW ? 50 : 0);

    return {
      status: kyc.status,
      completionPercentage: completion,
      documents: kyc.documents.map(doc => ({
        id: doc.id,
        documentType: doc.documentType,
        fileUrl: doc.fileUrl,
        verified: doc.verified,
        verificationScore: doc.verificationScore ?? undefined,
        rejectionReason: doc.rejectionReason ?? undefined,
        uploadedAt: doc.uploadedAt.toISOString(),
        verifiedAt: doc.verifiedAt?.toISOString(),
      })),
      verification: {
        id: kyc.id,
        tenantId: kyc.tenantId,
        status: kyc.status,
        provider: kyc.provider,
        verifiedFullName: kyc.verifiedFullName || undefined,
        verifiedEmail: kyc.verifiedEmail || undefined,
        verifiedDOB: kyc.verifiedDOB?.toISOString(),
        maskedAadhaarNumber: kyc.maskedAadhaarNumber || undefined,
        verificationReferenceId: kyc.verificationReferenceId || undefined,
        digilockerSessionId: kyc.digilockerSessionId || undefined,
        digilockerReferenceId: kyc.digilockerReferenceId || undefined,
        verificationUrl: kyc.verificationUrl || undefined,
        consentTimestamp: kyc.consentTimestamp?.toISOString(),
        failureReason: kyc.failureReason || undefined,
        failureCount: kyc.failureCount,
        nextRetryAt: kyc.nextRetryAt?.toISOString(),
        expiresAt: kyc.expiresAt?.toISOString(),
        createdAt: kyc.createdAt.toISOString(),
        updatedAt: kyc.updatedAt.toISOString(),
      },
    };
  }

  async getKYCDetails(tenantId: string) {
    const kyc = await this.prisma.kYCVerification.findUnique({
      where: { tenantId },
      include: { 
        documents: true, 
        auditLogs: true,
        tenant: true
      }
    });

    if (!kyc) {
      throw new NotFoundException('KYC verification not found');
    }

    return {
      verification: {
        id: kyc.id,
        tenantId: kyc.tenantId,
        status: kyc.status,
        provider: kyc.provider,
        verifiedFullName: kyc.verifiedFullName || undefined,
        verifiedEmail: kyc.verifiedEmail || undefined,
        verifiedDOB: kyc.verifiedDOB?.toISOString(),
        maskedAadhaarNumber: kyc.maskedAadhaarNumber || undefined,
        verificationReferenceId: kyc.verificationReferenceId || undefined,
        digilockerSessionId: kyc.digilockerSessionId || undefined,
        digilockerReferenceId: kyc.digilockerReferenceId || undefined,
        verificationUrl: kyc.verificationUrl || undefined,
        consentTimestamp: kyc.consentTimestamp?.toISOString(),
        failureReason: kyc.failureReason || undefined,
        failureCount: kyc.failureCount,
        nextRetryAt: kyc.nextRetryAt?.toISOString(),
        expiresAt: kyc.expiresAt?.toISOString(),
        createdAt: kyc.createdAt.toISOString(),
        updatedAt: kyc.updatedAt.toISOString(),
      },
      documents: kyc.documents.map(doc => ({
        id: doc.id,
        documentType: doc.documentType,
        fileUrl: doc.fileUrl,
        verified: doc.verified,
        verificationScore: doc.verificationScore ?? undefined,
        rejectionReason: doc.rejectionReason ?? undefined,
        uploadedAt: doc.uploadedAt.toISOString(),
        verifiedAt: doc.verifiedAt?.toISOString(),
      })),
      auditLogs: kyc.auditLogs.map(log => ({
        id: log.id,
        action: log.action,
        actor: log.actorId ? { id: log.actorId, role: log.actorRole || 'SYSTEM' } : undefined,
        createdAt: log.createdAt.toISOString(),
        details: log.details as any,
      })),
      tenantInfo: {
        id: kyc.tenant.id,
        name: kyc.tenant.name,
        email: kyc.tenant.email,
        phone: kyc.tenant.phone,
        organizationId: kyc.tenant.organizationId,
      }
    };
  }

  async getPendingReviews(organizationId?: string, skip = 0, take = 10, reviewerProfileId?: string) {
    const where: any = { status: KYCVerificationStatus.MANUAL_REVIEW };
    if (organizationId) where.organizationId = organizationId;

    const [pending, totalPending] = await Promise.all([
      this.prisma.kYCVerification.findMany({
        where,
        include: { 
          tenant: true,
          documents: { select: { id: true } }
        },
        skip,
        take,
        orderBy: { createdAt: 'desc' }
      }),
      this.prisma.kYCVerification.count({ where })
    ]);

    return {
      pending: pending.map(item => ({
        id: item.id,
        tenantId: item.tenantId,
        tenantName: item.tenant.name,
        tenantEmail: item.tenant.email,
        organizationId: item.organizationId,
        status: item.status,
        failureCount: item.failureCount,
        uploadedDocumentsCount: item.documents.length,
        createdAt: item.createdAt.toISOString(),
        lastUpdatedAt: item.updatedAt.toISOString(),
        flaggedForSuspicion: item.flaggedForSuspicion,
      })),
      totalPending,
      skip,
      take
    };
  }

  async approveKYC(
    tenantId: string, 
    adminId: string, 
    adminNotes?: string,
    flaggedForSuspicion = false,
    suspicionReason?: string
  ) {
    return this.prisma.$transaction(async (tx) => {
      const kyc = await tx.kYCVerification.findUnique({ where: { tenantId } });
      if (!kyc) throw new NotFoundException('KYC not found');

      const updated = await tx.kYCVerification.update({
        where: { id: kyc.id },
        data: {
          status: KYCVerificationStatus.VERIFIED,
          reviewedBy: adminId,
          reviewedAt: new Date(),
          adminNotes,
          flaggedForSuspicion,
          suspicionReason,
        },
      });

      await tx.tenant.update({
        where: { id: tenantId },
        data: { aadhaarVerified: true },
      });

      return updated;
    });
  }

  async rejectKYC(
    tenantId: string, 
    adminId: string, 
    reason: string,
    adminNotes?: string,
    allowRetry = true
  ) {
    const kyc = await this.prisma.kYCVerification.findUnique({ where: { tenantId } });
    if (!kyc) throw new NotFoundException('KYC not found');

    return this.prisma.kYCVerification.update({
      where: { id: kyc.id },
      data: {
        status: allowRetry ? KYCVerificationStatus.RETRY : KYCVerificationStatus.REJECTED,
        failureReason: reason,
        adminNotes,
        reviewedBy: adminId,
        reviewedAt: new Date(),
      },
    });
  }

  async retryVerification(tenantId: string, reason?: string) {
    const kyc = await this.prisma.kYCVerification.findUnique({ where: { tenantId } });
    if (!kyc) throw new NotFoundException('KYC not found');

    return this.prisma.kYCVerification.update({
      where: { id: kyc.id },
      data: { 
        status: KYCVerificationStatus.PENDING, 
        failureReason: reason || null 
      },
    });
  }

  private async notifyVerificationComplete(tenantId: string, success: boolean) {
    this.logger.log(`Notify tenant ${tenantId}: Verification ${success ? 'completed' : 'failed'}`);
  }

  private async notifyVerificationFailed(tenantId: string, reason: string, isFinal: boolean) {
    this.logger.log(`Notify tenant ${tenantId}: Verification failed - ${reason}`);
  }
}

// ─── DIGILOCKER PROVIDER (SANDBOX.CO.IN) ───────────────────

class DigiLockerProvider implements VerificationProvider {
  private readonly baseUrl = process.env.SANDBOX_BASE_URL || 'https://api.sandbox.co.in';
  private accessToken: string | null = null;
  private tokenExpiry: number = 0;

  constructor(private readonly logger: Logger) {}

  private async getAuthToken(): Promise<string> {
    // Return cached token if valid (with 1-minute buffer)
    if (this.accessToken && Date.now() < this.tokenExpiry - 60000) {
      return this.accessToken!;
    }

    try {
      const clientId = process.env.SANDBOX_CLIENT_ID;
      const clientSecret = process.env.SANDBOX_CLIENT_SECRET;

      const response = await axios.post(
        `${this.baseUrl}/authenticate`,
        {},
        {
          headers: {
            'x-api-key': clientId,
            'x-api-secret': clientSecret,
            'x-api-version': '1.0',
          },
        }
      );

      if (!response.data.access_token) {
        throw new Error('Authentication failed: No access token received');
      }

      const token = response.data.access_token;
      this.accessToken = token;
      // Assume 24h expiry if not provided, or parse if available
      this.tokenExpiry = Date.now() + (response.data.expires_in || 86400) * 1000;
      
      return token;
    } catch (error: unknown) {
      const err = error as { response?: { data?: { message?: string } }; message?: string };
      const msg = err.response?.data?.message || err.message || String(error);
      this.logger.error(`Sandbox Auth Error: ${msg}`);
      throw new Error(`Failed to authenticate with Sandbox: ${msg}`);
    }
  }

  private async getHeaders() {
    const token = await this.getAuthToken();
    const clientId = process.env.SANDBOX_CLIENT_ID;
    
    return {
      'Authorization': token, // No "Bearer " prefix as per Sandbox docs
      'x-api-key': clientId,
      'x-api-version': '1.0',
      'Content-Type': 'application/json',
    };
  }

  async initiateVerification(
    kycVerificationId: string,
    tenantData: any,
    redirectUrl: string,
  ): Promise<{ verificationUrl: string; sessionId: string; expiryInSeconds: number }> {
    try {
      const consentValidTill = Math.floor((Date.now() + (30 * 60 * 1000)) / 1000);
      this.logger.debug(
        `Initiating DigiLocker session for ${kycVerificationId} with consent_valid_till=${consentValidTill} (unix seconds)`,
      );

      const response = await axios.post(
        `${this.baseUrl}/kyc/digilocker/sessions/init`,
        {
          "@entity": "in.co.sandbox.kyc.digilocker.session.request",
          "flow": "signin",
          "doc_types": ["aadhaar"],
          "redirect_url": redirectUrl,
          "consent_valid_till": consentValidTill,
        },
        { headers: await this.getHeaders() }
      );

      const body = response.data;
      this.logger.debug(`Sandbox Initiation Response: ${JSON.stringify(body)}`);
      
      // Sandbox often wraps the actual result in a 'data' property
      const data = body.data || body;
      
      if (!data.session_id && !data.request_id) {
        throw new Error('Invalid response from Sandbox API: Missing session_id or request_id');
      }
      
      const sessionId = data.session_id || data.request_id;
      const verificationUrl = data.authorization_url || data.url;

      if (!sessionId || !verificationUrl) {
        throw new Error('Invalid response from Sandbox API: Missing required fields');
      }

      return {
        sessionId,
        verificationUrl,
        expiryInSeconds: 30 * 60, // 30 minutes
      };
    } catch (error: unknown) {
      const err = error as { response?: { data?: { message?: string } }; message?: string };
      const msg = err.response?.data?.message || err.message || String(error);
      if (msg.toLowerCase().includes('privilege') || msg.toLowerCase().includes('priveilege')) {
        throw new Error(`Sandbox Initiation Error: Insufficient privileges. Please ensure "KYC DigiLocker" is enabled in your Sandbox.co.in dashboard for this API key.`);
      }
      throw new Error(`Sandbox Initiation Error: ${msg}`);
    }
  }

  async fetchDocuments(sessionId: string): Promise<any[]> {
    try {
      // 1. Check status first
      const statusResponse = await axios.get(
        `${this.baseUrl}/kyc/digilocker/sessions/${sessionId}/status`,
        { headers: await this.getHeaders() }
      );

      if (statusResponse.data.status !== 'completed' && statusResponse.data.status !== 'success') {
        throw new Error(`Session not completed. Current status: ${statusResponse.data.status}`);
      }

      // 2. Fetch Aadhaar document
      const docResponse = await axios.get(
        `${this.baseUrl}/kyc/digilocker/sessions/${sessionId}/documents/aadhaar`,
        { headers: await this.getHeaders() }
      );

      return [{ type: 'aadhaar', data: docResponse.data }];
    } catch (error: unknown) {
      const err = error as { response?: { data?: { message?: string } }; message?: string };
      const msg = err.response?.data?.message || err.message || String(error);
      this.logger.error(`Sandbox Fetch Error: ${msg}`);
      throw new Error(`Document fetch failed: ${msg}`);
    }
  }

  validateWebhook(payload: any, signature: string): boolean {
    // Sandbox usually doesn't require HMAC validation for simple implementations, 
    // but we can add it if needed.
    return true;
  }

  async parseWebhookPayload(payload: any): Promise<any> {
    // This is now handled in fetchDocuments for better reliability
    return payload;
  }
}
