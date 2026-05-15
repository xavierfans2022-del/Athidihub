import {
  BadRequestException,
  Body,
  Controller,
  Post,
  UploadedFile,
  UseGuards,
  UseInterceptors,
} from '@nestjs/common';
import { FileInterceptor } from '@nestjs/platform-express';
import type { Profile } from '@prisma/client';
import { CurrentUser } from '../auth/current-user.decorator';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { StorageService } from './storage.service';

type UploadFile = {
  buffer: Buffer;
  mimetype: string;
  originalname: string;
};

@UseGuards(JwtAuthGuard)
@Controller('storage')
export class StorageController {
  constructor(private readonly storageService: StorageService) {}

  /**
   * Upload avatar for the authenticated user (Profile)
   * Returns the updated profile with avatar URL
   */
  @Post('avatar')
  @UseInterceptors(FileInterceptor('file', { limits: { fileSize: 5 * 1024 * 1024 } }))
  async uploadAvatar(
    @CurrentUser() user: Profile,
    @UploadedFile() file?: UploadFile,
    @Body('mimeType') mimeType?: string,
  ) {
    if (!file) {
      throw new BadRequestException('Avatar file is required');
    }

    return this.storageService.uploadAvatar(user.id, file, mimeType);
  }

  /**
   * Upload organization logo
   * Optional organizationId: if provided, saves to database; otherwise just returns URL (for onboarding)
   * Returns the logo URL and optional database update record
   */
  @Post('organization-logo')
  @UseInterceptors(FileInterceptor('file', { limits: { fileSize: 5 * 1024 * 1024 } }))
  async uploadOrganizationLogo(
    @CurrentUser() user: Profile,
    @Body('organizationId') organizationId?: string,
    @UploadedFile() file?: UploadFile,
    @Body('mimeType') mimeType?: string,
  ) {
    if (!file) {
      throw new BadRequestException('Organization logo file is required');
    }

    return this.storageService.uploadOrganizationLogo(user.id, file, organizationId, mimeType);
  }

  /**
   * Upload tenant document (KYC or profile avatar)
   * Requires tenantId and documentType in request body
   * Returns the file URL and document details
   */
  @Post('tenant-document')
  @UseInterceptors(FileInterceptor('file', { limits: { fileSize: 10 * 1024 * 1024 } }))
  async uploadTenantDocument(
    @CurrentUser() user: Profile,
    @Body('tenantId') tenantId?: string,
    @Body('documentType') documentType?: string,
    @UploadedFile() file?: UploadFile,
    @Body('mimeType') mimeType?: string,
  ) {
    if (!tenantId) {
      throw new BadRequestException('tenantId is required');
    }

    if (!documentType) {
      throw new BadRequestException('documentType is required');
    }

    if (!file) {
      throw new BadRequestException('Document file is required');
    }

    return this.storageService.uploadTenantDocument(user.id, tenantId, documentType, file, mimeType);
  }
}