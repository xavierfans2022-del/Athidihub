import {
  Controller,
  Post,
  Get,
  Patch,
  Body,
  Param,
  Query,
  UseGuards,
  Request,
  Res,
  BadRequestException,
  Logger,
} from '@nestjs/common';
import type { Response } from 'express';
import { ApiBearerAuth, ApiOperation, ApiParam, ApiResponse } from '@nestjs/swagger';
import { KYCService } from './kyc.service';
import {
  InitiateKYCVerificationDto,
  VerifyDocumentUploadDto,
  AdminApproveKYCDto,
  AdminRejectKYCDto,
  DigiLockerSandboxCallbackDto,
  RetryKYCVerificationDto,
  KYCVerificationResponseDto,
  KYCStatusResponseDto,
  InitiateKYCResponseDto,
  KYCUploadResponseDto,
  AdminKYCReviewListDto,
  AdminKYCDetailDto,
  AdminApprovalResponseDto,
} from './dto/kyc.dto';
import { JwtGuard } from '../auth/guards/jwt.guard';
import { RolesGuard } from '../common/guards/roles.guard';
import { Roles } from '../common/decorators/roles.decorator';

@Controller('kyc')
export class KYCController {
  private logger = new Logger('KYCController');

  constructor(private kycService: KYCService) {}

  // ─── TENANT KYC ENDPOINTS ─────────────────────────────────

  @Post('initiate')
  @UseGuards(JwtGuard)
  async initiateVerification(
    @Body() dto: InitiateKYCVerificationDto,
    @Request() req: any,
  ): Promise<InitiateKYCResponseDto> {
    const organizationId = req.user.organizationId;
    // Use the specific callback path for DigiLocker
    const baseUrl = process.env.API_BASE_URL || 'http://localhost:8080';
    const redirectUrl = `${baseUrl.endsWith('/') ? baseUrl.slice(0, -1) : baseUrl}/kyc/callback/digilocker`;

    return this.kycService.initiateKYCVerification(
      dto.tenantId,
      organizationId,
      dto.provider || 'DIGILOCKER',
      redirectUrl,
      dto.sandboxMode ?? true,
    );
  }

  @Get('status/:tenantId')
  @UseGuards(JwtGuard)
  async getVerificationStatus(@Param('tenantId') tenantId: string): Promise<KYCStatusResponseDto> {
    return this.kycService.getKYCStatus(tenantId);
  }

  @Get('details/:tenantId')
  @UseGuards(JwtGuard)
  async getVerificationDetails(@Param('tenantId') tenantId: string): Promise<AdminKYCDetailDto> {
    return this.kycService.getKYCDetails(tenantId);
  }

  @Post('upload-document')
  @UseGuards(JwtGuard)
  async uploadDocument(
    @Body() dto: VerifyDocumentUploadDto,
    @Request() req: any,
  ): Promise<KYCUploadResponseDto> {
    try {
      const document = await this.kycService.uploadDocument(
        dto.tenantId,
        dto.documentType,
        dto.fileData,
        dto.fileName || `${dto.documentType}-${Date.now()}`,
        dto.mimeType || 'application/octet-stream',
        dto.fileSize,
      );

      return {
        success: true,
        documentId: document.id,
        document: {
          id: document.id,
          documentType: document.documentType,
          verified: document.verified,
          verificationScore: document.verificationScore || undefined,
          rejectionReason: document.rejectionReason || undefined,
          uploadedAt: document.uploadedAt.toISOString(),
          verifiedAt: document.verifiedAt?.toISOString(),
        },
        message: 'Document uploaded successfully',
      };
    } catch (error: unknown) {
      const message = error instanceof Error ? error.message : String(error);
      this.logger.error(`Document upload failed: ${message}`);
      throw error;
    }
  }

  @Post('retry')
  @UseGuards(JwtGuard)
  async retryVerification(
    @Body() dto: RetryKYCVerificationDto,
    @Request() req: any,
  ): Promise<KYCVerificationResponseDto> {
    const verification = await this.kycService.retryVerification(dto.tenantId, dto.reason);

    return {
      id: verification.id,
      tenantId: verification.tenantId,
      status: verification.status,
      provider: verification.provider,
      verifiedFullName: verification.verifiedFullName ? '[ENCRYPTED]' : undefined,
      verifiedEmail: verification.verifiedEmail ? '[ENCRYPTED]' : undefined,
      verifiedDOB: verification.verifiedDOB?.toISOString(),
      maskedAadhaarNumber: verification.maskedAadhaarNumber || undefined,
      verificationReferenceId: verification.verificationReferenceId || undefined,
      digilockerSessionId: verification.digilockerSessionId || undefined,
      digilockerReferenceId: verification.digilockerReferenceId || undefined,
      verificationUrl: verification.verificationUrl || undefined,
      consentTimestamp: verification.consentTimestamp?.toISOString(),
      failureReason: verification.failureReason || undefined,
      failureCount: verification.failureCount,
      nextRetryAt: verification.nextRetryAt?.toISOString(),
      expiresAt: verification.expiresAt?.toISOString(),
      createdAt: verification.createdAt.toISOString(),
      updatedAt: verification.updatedAt.toISOString(),
    };
  }

  // ─── WEBHOOK CALLBACKS ────────────────────────────────────

  @Get('callback/digilocker')
  async handleDigiLockerCallback(
    @Res() res: any,
    @Query('session_id') sessionId?: string,
    @Query('request_id') requestId?: string,
    @Query('state') state?: string,
    @Query('code') code?: string,
  ) {
    const actualSessionId = sessionId || requestId || state || code;
    try {
      this.logger.log(`Received DigiLocker callback for session: ${actualSessionId}`);
      
      if (actualSessionId) {
        this.kycService.handleWebhookCallback(
          'DIGILOCKER',
          { session_id: actualSessionId, status: 'success' },
          '',
          '',
        ).catch(err => this.logger.error(`Background callback processing failed: ${err.message}`));
      }
      
      const baseUrl = process.env.API_BASE_URL || 'http://localhost:8080';
      const successUrl = `${baseUrl.endsWith('/') ? baseUrl.slice(0, -1) : baseUrl}/kyc/success?session_id=${actualSessionId}`;
      return res.redirect(successUrl);
    } catch (error) {
      this.logger.error(`Callback handling failed: ${error}`);
      const baseUrl = process.env.API_BASE_URL || 'http://localhost:8080';
      const failureUrl = `${baseUrl.endsWith('/') ? baseUrl.slice(0, -1) : baseUrl}/kyc/failure?session_id=${actualSessionId}`;
      return res.redirect(failureUrl);
    }
  }

  @Get('success')
  async showSuccessPage(@Res() res: Response) {
    return res.send(`
      <html>
        <body style="font-family: sans-serif; display: flex; flex-direction: column; align-items: center; justify-content: center; height: 100vh; margin: 0; background-color: #f0fdf4;">
          <div style="text-align: center; padding: 40px; background: white; border-radius: 16px; box-shadow: 0 4px 6px -1px rgb(0 0 0 / 0.1);">
            <div style="font-size: 48px; margin-bottom: 20px;">✅</div>
            <h1 style="color: #166534; margin: 0 0 10px 0;">Verification Complete!</h1>
            <p style="color: #15803d;">You can now safely close this window and return to the Athidihub app.</p>
          </div>
        </body>
      </html>
    `);
  }

  @Get('failure')
  async showFailurePage(@Res() res: Response) {
    return res.send(`
      <html>
        <body style="font-family: sans-serif; display: flex; flex-direction: column; align-items: center; justify-content: center; height: 100vh; margin: 0; background-color: #fef2f2;">
          <div style="text-align: center; padding: 40px; background: white; border-radius: 16px; box-shadow: 0 4px 6px -1px rgb(0 0 0 / 0.1);">
            <div style="font-size: 48px; margin-bottom: 20px;">❌</div>
            <h1 style="color: #991b1b; margin: 0 0 10px 0;">Verification Failed</h1>
            <p style="color: #b91c1c;">Something went wrong. Please return to the app and try again.</p>
          </div>
        </body>
      </html>
    `);
  }

  @Post('webhook/:provider')
  async handleWebhookCallback(
    @Param('provider') provider: string,
    @Body() payload: any,
    @Query('signature') signature?: string,
    @Query('timestamp') timestamp?: string,
  ): Promise<{ success: boolean; message: string }> {
    try {
      return await this.kycService.handleWebhookCallback(
        provider,
        payload,
        signature || payload.signature || '',
        timestamp || payload.timestamp || '',
      );
    } catch (error: unknown) {
      const message = error instanceof Error ? error.message : String(error);
      this.logger.error(`Webhook processing error: ${message}`);
      throw error;
    }
  }

  @Post('callback/process')
  @UseGuards(JwtGuard)
  async processOAuthCallback(
    @Body() dto: any,
    @Request() req: any,
  ): Promise<any> {
    const { tenantId, code, verificationId, state, sessionId } = dto;

    if (!tenantId || !code || !verificationId) {
      throw new BadRequestException('Missing required fields: tenantId, code, verificationId');
    }

    try {
      this.logger.debug(`Processing OAuth callback from app for verification: ${verificationId}`);
      const result = await this.kycService.processOAuthCallback(
        tenantId,
        code,
        verificationId,
        state,
        sessionId,
      );
      return result;
    } catch (error: unknown) {
      const message = error instanceof Error ? error.message : String(error);
      this.logger.error(`OAuth callback processing error: ${message}`);
      throw error;
    }
  }

  // ─── ADMIN ENDPOINTS ──────────────────────────────────────

  @Get('admin/pending-reviews')
  @UseGuards(JwtGuard, RolesGuard)
  @Roles('ADMIN', 'OWNER', 'MANAGER')
  async getPendingReviews(
    @Query('skip') skip = 0,
    @Query('take') take = 10,
    @Request() req: any,
  ): Promise<AdminKYCReviewListDto> {
    const skipInt = Number.isFinite(Number(skip)) ? Math.max(0, Number(skip)) : 0;
    const takeInt = Number.isFinite(Number(take)) ? Math.min(100, Math.max(1, Number(take))) : 10;
    const organizationId = req.user.organizationId ?? req.user.orgId ?? req.user.organization?.id;
    const reviewerProfileId = req.user.id ?? req.user.profileId ?? req.user.sub;

    return this.kycService.getPendingReviews(organizationId, skipInt, takeInt, reviewerProfileId);
  }

  @Get('admin/details/:tenantId')
  @UseGuards(JwtGuard, RolesGuard)
  @Roles('ADMIN', 'OWNER', 'MANAGER')
  @ApiBearerAuth()
  @ApiParam({ name: 'tenantId', description: 'Tenant ID' })
  @ApiOperation({ summary: 'Get detailed KYC information for admin review' })
  @ApiResponse({ status: 200, type: AdminKYCDetailDto })
  async getAdminKYCDetails(
    @Param('tenantId') tenantId: string,
    @Request() req: any,
  ): Promise<AdminKYCDetailDto> {
    return this.kycService.getKYCDetails(tenantId);
  }

  @Patch('admin/approve/:tenantId')
  @UseGuards(JwtGuard, RolesGuard)
  @Roles('ADMIN', 'OWNER', 'MANAGER')
  @ApiBearerAuth()
  @ApiParam({ name: 'tenantId', description: 'Tenant ID' })
  @ApiOperation({ summary: 'Approve KYC verification' })
  @ApiResponse({ status: 200, type: AdminApprovalResponseDto })
  async approveKYC(
    @Param('tenantId') tenantId: string,
    @Body() dto: AdminApproveKYCDto,
    @Request() req: any,
  ): Promise<AdminApprovalResponseDto> {
    const adminId = req.user.id;

    const verification = await this.kycService.approveKYC(
      tenantId,
      adminId,
      dto.adminNotes,
      dto.flaggedForSuspicion,
      dto.suspicionReason,
    );

    return {
      success: true,
      status: verification.status,
      message: `KYC verification ${verification.status.toLowerCase()}`,
      canProceedWithCheckIn: verification.status === 'VERIFIED',
    };
  }

  @Patch('admin/reject/:tenantId')
  @UseGuards(JwtGuard, RolesGuard)
  @Roles('ADMIN', 'OWNER', 'MANAGER')
  @ApiBearerAuth()
  @ApiParam({ name: 'tenantId', description: 'Tenant ID' })
  @ApiOperation({ summary: 'Reject KYC verification' })
  @ApiResponse({ status: 200, type: AdminApprovalResponseDto })
  async rejectKYC(
    @Param('tenantId') tenantId: string,
    @Body() dto: AdminRejectKYCDto,
    @Request() req: any,
  ): Promise<AdminApprovalResponseDto> {
    const adminId = req.user.id;

    const verification = await this.kycService.rejectKYC(
      tenantId,
      adminId,
      dto.rejectionReason,
      dto.adminNotes,
      dto.allowRetry,
    );

    return {
      success: true,
      status: verification.status,
      message: `KYC verification ${verification.status.toLowerCase()}${dto.allowRetry ? ' (retry allowed)' : ''}`,
      canProceedWithCheckIn: false,
    };
  }

  // ─── HEALTH CHECK ────────────────────────────────────────

  @Get('health')
  @ApiOperation({ summary: 'KYC service health check' })
  @ApiResponse({ status: 200 })
  async healthCheck(): Promise<{ status: string }> {
    return { status: 'ok' };
  }
}
