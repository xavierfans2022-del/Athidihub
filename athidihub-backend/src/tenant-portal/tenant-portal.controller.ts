import {
  Controller,
  Get,
  Patch,
  Post,
  Delete,
  Body,
  Query,
  UseGuards,
  ParseIntPipe,
  Optional,
} from '@nestjs/common';
import { TenantPortalService } from './tenant-portal.service';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { CurrentUser } from '../auth/current-user.decorator';
import type { Profile } from '@prisma/client';

@UseGuards(JwtAuthGuard)
@Controller('tenant-portal')
export class TenantPortalController {
  constructor(private readonly svc: TenantPortalService) {}

  /** GET /tenant-portal/me — basic tenant identity */
  @Get('me')
  getMe(@CurrentUser() user: Profile) {
    return this.svc.findByProfileId(user.id);
  }

  /** GET /tenant-portal/me/dashboard */
  @Get('me/dashboard')
  getDashboard(@CurrentUser() user: Profile) {
    return this.svc.getDashboard(user.id);
  }

  /** GET /tenant-portal/me/invoices?month=5&year=2026&page=1&limit=12 */
  @Get('me/invoices')
  getInvoices(
    @CurrentUser() user: Profile,
    @Query('month') month?: string,
    @Query('year') year?: string,
    @Query('page') page?: string,
    @Query('limit') limit?: string,
  ) {
    return this.svc.getInvoices(user.id, {
      month: month ? parseInt(month, 10) : undefined,
      year: year ? parseInt(year, 10) : undefined,
      page: page ? parseInt(page, 10) : 1,
      limit: limit ? parseInt(limit, 10) : 12,
    });
  }

  /** GET /tenant-portal/me/payments?month=5&year=2026 */
  @Get('me/payments')
  getPayments(
    @CurrentUser() user: Profile,
    @Query('month') month?: string,
    @Query('year') year?: string,
    @Query('page') page?: string,
    @Query('limit') limit?: string,
  ) {
    return this.svc.getPaymentHistory(user.id, {
      month: month ? parseInt(month, 10) : undefined,
      year: year ? parseInt(year, 10) : undefined,
      page: page ? parseInt(page, 10) : 1,
      limit: limit ? parseInt(limit, 10) : 12,
    });
  }

  /** PATCH /tenant-portal/me/aadhaar — submit Aadhaar doc URL */
  @Patch('me/aadhaar')
  submitAadhaar(@CurrentUser() user: Profile, @Body() body: { aadhaarUrl: string }) {
    return this.svc.verifyAadhaar(user.id, body.aadhaarUrl);
  }

  /** DELETE /tenant-portal/me/aadhaar — delete/reset unverified Aadhaar */
  @Delete('me/aadhaar')
  deleteAadhaar(@CurrentUser() user: Profile) {
    return this.svc.deleteAadhaar(user.id);
  }

  /** GET /tenant-portal/me/digilocker/initiate */
  @Get('me/digilocker/initiate')
  initiateDigiLocker(@CurrentUser() user: Profile) {
    return this.svc.getDigiLockerUrl(user.id);
  }

  /** POST /tenant-portal/me/digilocker/verify */
  @Post('me/digilocker/verify')
  verifyDigiLocker(
    @CurrentUser() user: Profile,
    @Body() body: { code: string; state: string }
  ) {
    return this.svc.verifyDigiLockerCallback(user.id, body.code, body.state);
  }

  /** POST /tenant-portal/me/checkin — complete digital check-in */
  @Post('me/checkin')
  checkIn(@CurrentUser() user: Profile) {
    return this.svc.completeCheckIn(user.id);
  }

  /** PATCH /tenant-portal/me/profile — update name, phone, emergency contact */
  @Patch('me/profile')
  updateProfile(
    @CurrentUser() user: Profile,
    @Body() body: { name?: string; phone?: string; emergencyContact?: string },
  ) {
    return this.svc.updateProfile(user.id, body);
  }
}
