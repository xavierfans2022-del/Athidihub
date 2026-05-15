import { Body, Controller, Headers, Post, UnauthorizedException, UseGuards } from '@nestjs/common';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { CurrentUser } from '../auth/current-user.decorator';
import type { Profile } from '@prisma/client';
import { TenantRemindersService } from './tenant-reminders.service';
import { FcmNotificationsService } from './fcm-notifications.service';
import { RegisterFcmTokenDto } from './dto/register-fcm-token.dto';

interface BulkReminderDto {
  organizationId: string;
  daysAhead?: number;
  includeOverdue?: boolean;
  message?: string;
  force?: boolean;
  dryRun?: boolean;
}

interface CronReminderDto {
  daysAhead?: number;
  includeOverdue?: boolean;
}

@Controller('notifications')
export class NotificationsController {
  constructor(
    private readonly tenantRemindersService: TenantRemindersService,
    private readonly fcmNotificationsService: FcmNotificationsService,
  ) {}

  @Post('reminders/cron')
  async runCron(
    @Headers('x-cron-secret') cronSecret?: string,
    @Body() body: CronReminderDto = {},
  ) {
    const expectedSecret = process.env.SUPABASE_CRON_SECRET;
    if (!expectedSecret || cronSecret !== expectedSecret) {
      throw new UnauthorizedException('Invalid cron secret');
    }

    return this.tenantRemindersService.runCronPaymentReminders({
      daysAhead: body.daysAhead ?? 3,
      includeOverdue: body.includeOverdue ?? true,
    });
  }

  @UseGuards(JwtAuthGuard)
  @Post('reminders/bulk')
  async sendBulk(@CurrentUser() user: Profile, @Body() body: BulkReminderDto) {
    await this.tenantRemindersService.ensureOwnerAccess(body.organizationId, user.id);

    return this.tenantRemindersService.sendBulkReminders({
      organizationId: body.organizationId,
      daysAhead: body.daysAhead ?? 3,
      includeOverdue: body.includeOverdue ?? true,
      message: body.message,
      mode: body.message?.trim() ? 'custom' : 'payment',
      force: body.force ?? false,
      dryRun: body.dryRun ?? false,
    });
  }

  @UseGuards(JwtAuthGuard)
  @Post('fcm/register')
  async registerFcmToken(@CurrentUser() user: Profile, @Body() body: RegisterFcmTokenDto) {
    return this.fcmNotificationsService.registerToken(user.id, body);
  }

  @UseGuards(JwtAuthGuard)
  @Post('fcm/unregister')
  async unregisterFcmToken(@CurrentUser() user: Profile, @Body() body: { token: string }) {
    return this.fcmNotificationsService.unregisterToken(user.id, body.token);
  }
}