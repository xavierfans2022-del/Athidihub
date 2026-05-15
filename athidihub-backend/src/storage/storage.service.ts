import { BadRequestException, Injectable, InternalServerErrorException, Logger } from '@nestjs/common';
import { createClient, SupabaseClient } from '@supabase/supabase-js';
import { PrismaService } from '../prisma/prisma.service';
import { OrganizationsService } from '../organizations/organizations.service';
import * as path from 'path';

type UploadFile = {
  buffer: Buffer;
  mimetype: string;
  originalname: string;
};

type StorageUploadResponse = {
  bucket: string;
  path: string;
  publicUrl: string;
};

type AvatarUploadResponse = StorageUploadResponse & {
  avatarUrl: string;
  updatedAt: Date;
};

type OrgLogoUploadResponse = StorageUploadResponse & {
  logoUrl: string;
  updatedAt: Date;
};

type KYCDocumentUploadResponse = StorageUploadResponse & {
  fileUrl: string;
  documentType: string;
  uploadedAt: Date;
};

@Injectable()
export class StorageService {
  private supabaseAdminClient: SupabaseClient | null = null;
  private readonly logger = new Logger(StorageService.name);

  constructor(private readonly prisma: PrismaService, private readonly organizationsService: OrganizationsService) {}

  /**
   * Upload avatar for a user (Profile) and persist to database
   * @param userId The profile ID
   * @param file The image file
   * @param mimeType Optional MIME type override
   * @returns Avatar response with updated database record
   */
  async uploadAvatar(userId: string, file: UploadFile, mimeType?: string): Promise<AvatarUploadResponse> {
    this.ensureAllowedMimeType(file, mimeType, ['image/jpeg', 'image/jpg', 'image/png', 'image/webp']);
    const extension = this.resolveExtension(file, mimeType, '.jpg');
    const objectPath = `avatars/${userId}${extension}`;

    try {
      // Step 1: Upload to Supabase Storage
      const uploadResponse = await this.upload('avatars', objectPath, file, mimeType);

      // Step 2: Update database atomically
      const updatedProfile = await this.prisma.profile.update({
        where: { id: userId },
        data: { avatarUrl: uploadResponse.publicUrl },
        select: { id: true, avatarUrl: true },
      });

      this.logger.debug(`Avatar uploaded and persisted for user ${userId}`);

      return {
        ...uploadResponse,
        avatarUrl: updatedProfile.avatarUrl || '',
        updatedAt: new Date(),
      };
    } catch (error) {
      this.logger.error(`Failed to upload avatar for user ${userId}: ${error.message}`);
      // Attempt cleanup if DB update failed but storage succeeded
      await this.deleteFromStorage('avatars', objectPath).catch(() => {
        this.logger.warn(`Cleanup failed for ${objectPath} after upload error`);
      });
      throw error;
    }
  }

  /**
   * Upload organization logo (with optional database persistence)
   * If organizationId is provided, saves to database; otherwise just returns URL
   * Useful for both onboarding (org not yet created) and updates (org exists)
   * @param userId The owner's profile ID (for authorization)
   * @param file The logo file
   * @param organizationId Optional - if provided, saves to db; if not, just returns URL
   * @param mimeType Optional MIME type override
   * @returns Logo upload response with optional database record
   */
  async uploadOrganizationLogo(
    userId: string,
    file: UploadFile,
    organizationId?: string,
    mimeType?: string,
  ): Promise<OrgLogoUploadResponse> {
    this.ensureAllowedMimeType(file, mimeType, ['image/jpeg', 'image/jpg', 'image/png', 'image/webp']);
    const extension = this.resolveExtension(file, mimeType, '.png');
    const objectPath = `organization-logos/org_logo_${Date.now()}_${this.sanitizeSegment(userId)}${extension}`;

    try {
      // Step 1: Upload to Supabase Storage
      const uploadResponse = await this.upload('organization-logos', objectPath, file, mimeType);

      let logoUrl = uploadResponse.publicUrl;
      let updatedAt = new Date();

      // Step 2: Update database if organizationId provided.
      // Treat common onboarding placeholder values (e.g. 'primary') as no-organization.
      const normalizedOrgId = (organizationId && String(organizationId).toLowerCase() === 'primary') ? undefined : organizationId;
      if (normalizedOrgId) {
        this.logger.debug(`uploadOrganizationLogo called by user ${userId} for organization ${normalizedOrgId}`);
        // Verify the user has access to update this organization (owner or member)
        const hasAccess = await this.organizationsService.userHasAccess(userId, normalizedOrgId);
        if (!hasAccess) {
          // Additional debug info: check if org exists at all
          const orgRecord = await this.prisma.organization.findUnique({ where: { id: normalizedOrgId }, select: { id: true, ownerId: true } });
          if (!orgRecord) {
            this.logger.warn(`uploadOrganizationLogo: organization ${normalizedOrgId} not found in DB (requested by user ${userId})`);
          } else {
            this.logger.warn(`uploadOrganizationLogo: user ${userId} does not have access to organization ${normalizedOrgId} (owner: ${orgRecord.ownerId})`);
          }
          throw new BadRequestException('Organization not found or access denied');
        }

        const updatedOrg = await this.prisma.organization.update({
          where: { id: normalizedOrgId },
          data: { logoUrl: uploadResponse.publicUrl },
          select: { logoUrl: true },
        });

        logoUrl = updatedOrg.logoUrl || '';
        updatedAt = new Date();

        this.logger.debug(`Organization logo uploaded and persisted for org ${normalizedOrgId}`);
      } else {
        this.logger.debug(`Organization logo uploaded (not persisted - onboarding/placeholder org id)`);
      }

      return {
        ...uploadResponse,
        logoUrl,
        updatedAt,
      };
    } catch (error) {
      this.logger.error(`Failed to upload logo: ${error.message}`);
      // Attempt cleanup if DB update failed but storage succeeded
      await this.deleteFromStorage('organization-logos', objectPath).catch(() => {
        this.logger.warn(`Cleanup failed for ${objectPath} after upload error`);
      });
      throw error;
    }
  }

  /**
   * Upload tenant document (KYC or profile avatar) and persist to database
   * @param userId The tenant's owner profile ID
   * @param tenantId The tenant ID
   * @param documentType The document type (AADHAAR_FRONT, AADHAAR_BACK, PAN, SELFIE, or AVATAR)
   * @param file The document file
   * @param mimeType Optional MIME type override
   * @returns Document upload response with updated database record
   */
  async uploadTenantDocument(
    userId: string,
    tenantId: string,
    documentType: string,
    file: UploadFile,
    mimeType?: string,
  ): Promise<StorageUploadResponse | AvatarUploadResponse> {
    // Verify tenant ownership
    const tenant = await this.prisma.tenant.findFirst({
      where: { id: tenantId, profileId: userId },
      select: { id: true, organizationId: true },
    });

    if (!tenant) {
      throw new BadRequestException('Tenant not found or access denied');
    }

    // Handle tenant avatar uploads separately
    if (documentType.toUpperCase() === 'AVATAR') {
      return this.uploadTenantAvatar(userId, tenantId, file, mimeType);
    }

    this.ensureAllowedMimeType(file, mimeType, ['image/jpeg', 'image/jpg', 'image/png', 'image/webp', 'application/pdf']);
    const safeDocumentType = this.sanitizeSegment(documentType);
    const extension = this.resolveExtension(file, mimeType, '.jpg');
    const objectPath = `documents/${tenantId}/${safeDocumentType}-${Date.now()}${extension}`;

    // Only upload to storage here. The KYC service owns document persistence so we do not
    // create duplicate KYCDocument rows from this shared upload endpoint.
    return this.upload('documents', objectPath, file, mimeType);
  }

  /**
   * Upload tenant avatar (different from tenant profile picture in general documents)
   * @param userId The tenant's owner profile ID
   * @param tenantId The tenant ID
   * @param file The avatar file
   * @param mimeType Optional MIME type override
   * @returns Avatar response with updated database record
   */
  private async uploadTenantAvatar(
    userId: string,
    tenantId: string,
    file: UploadFile,
    mimeType?: string,
  ): Promise<AvatarUploadResponse> {
    this.ensureAllowedMimeType(file, mimeType, ['image/jpeg', 'image/jpg', 'image/png', 'image/webp']);
    const extension = this.resolveExtension(file, mimeType, '.jpg');
    const objectPath = `avatars/tenant_${tenantId}${extension}`;

    try {
      // Step 1: Upload to Supabase Storage
      const uploadResponse = await this.upload('avatars', objectPath, file, mimeType);

      // Step 2: Update tenant avatar URL in database
      const updatedTenant = await this.prisma.tenant.update({
        where: { id: tenantId },
        data: { avatarUrl: uploadResponse.publicUrl },
        select: { id: true, avatarUrl: true },
      });

      this.logger.debug(`Tenant avatar uploaded and persisted for tenant ${tenantId}`);

      return {
        ...uploadResponse,
        avatarUrl: updatedTenant.avatarUrl || '',
        updatedAt: new Date(),
      };
    } catch (error) {
      this.logger.error(`Failed to upload tenant avatar for ${tenantId}: ${error.message}`);
      // Attempt cleanup if DB update failed but storage succeeded
      await this.deleteFromStorage('avatars', objectPath).catch(() => {
        this.logger.warn(`Cleanup failed for ${objectPath} after upload error`);
      });
      throw error;
    }
  }

  /**
   * Internal: Upload file to Supabase Storage without database persistence
   */
  private async upload(
    bucket: string,
    objectPath: string,
    file: UploadFile,
    mimeType?: string,
  ): Promise<StorageUploadResponse> {
    const client = this.getSupabaseAdminClient();
    const contentType = mimeType || file.mimetype || 'application/octet-stream';

    const { error } = await client.storage.from(bucket).upload(objectPath, file.buffer, {
      upsert: true,
      contentType,
    });

    if (error) {
      throw new BadRequestException(`Storage upload failed: ${error.message}`);
    }

    const { data } = client.storage.from(bucket).getPublicUrl(objectPath);

    return {
      bucket,
      path: objectPath,
      publicUrl: data.publicUrl,
    };
  }

  /**
   * Internal: Delete file from Supabase Storage (for cleanup on errors)
   */
  private async deleteFromStorage(bucket: string, objectPath: string): Promise<void> {
    try {
      const client = this.getSupabaseAdminClient();
      await client.storage.from(bucket).remove([objectPath]);
    } catch (error) {
      this.logger.warn(`Failed to delete ${objectPath} from ${bucket}: ${error.message}`);
    }
  }

  private getSupabaseAdminClient(): SupabaseClient {
    if (this.supabaseAdminClient) {
      return this.supabaseAdminClient;
    }

    const supabaseUrl = process.env.SUPABASE_URL;
    const serviceRoleKey = process.env.SUPABASE_SERVICE_ROLE_KEY;

    if (!supabaseUrl || !serviceRoleKey) {
      throw new BadRequestException('Supabase storage is not configured');
    }

    this.supabaseAdminClient = createClient(supabaseUrl, serviceRoleKey, {
      auth: {
        autoRefreshToken: false,
        persistSession: false,
      },
    });

    return this.supabaseAdminClient;
  }

  private ensureAllowedMimeType(
    file: UploadFile,
    mimeType: string | undefined,
    allowedMimeTypes: string[],
  ) {
    const resolvedMimeType = (mimeType || file.mimetype || '').toLowerCase();
    if (!allowedMimeTypes.includes(resolvedMimeType)) {
      throw new BadRequestException(`Unsupported file type: ${resolvedMimeType || 'unknown'}`);
    }
  }

  private resolveExtension(file: UploadFile, mimeType: string | undefined, fallback: string): string {
    const originalExtension = path.extname(file.originalname || '').toLowerCase();
    if (originalExtension) {
      return originalExtension;
    }

    const resolvedMimeType = (mimeType || file.mimetype || '').toLowerCase();
    switch (resolvedMimeType) {
      case 'image/jpeg':
      case 'image/jpg':
        return '.jpg';
      case 'image/png':
        return '.png';
      case 'image/webp':
        return '.webp';
      case 'application/pdf':
        return '.pdf';
      default:
        return fallback;
    }
  }

  private sanitizeSegment(value: string): string {
    const cleaned = value.trim().toLowerCase().replace(/[^a-z0-9_-]+/g, '-');
    return cleaned || 'document';
  }

  /**
   * Normalize document type to match KYCDocumentType enum
   */
  private normalizeDocumentType(documentType: string): string {
    const normalized = documentType
      .trim()
      .replace(/([a-z0-9])([A-Z])/g, '$1_$2')
      .replace(/[\s-]+/g, '_')
      .toUpperCase()
      .replace(/[^A-Z_]/g, '');
    const validTypes = ['AADHAAR_FRONT', 'AADHAAR_BACK', 'PAN', 'SELFIE'];
    return validTypes.includes(normalized) ? normalized : 'SELFIE';
  }
}