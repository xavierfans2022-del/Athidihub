import { Module } from '@nestjs/common';
import { BullModule } from '@nestjs/bull';
import { NotificationsService } from './notifications.service';
import { NotificationsProcessor } from './notifications.processor';
import { NotificationsController } from './notifications.controller';
import { TenantRemindersService } from './tenant-reminders.service';
import { FcmNotificationsService } from './fcm-notifications.service';
import { NOTIFICATIONS_QUEUE } from './notifications.constants';
import { PrismaService } from '../prisma/prisma.service';

@Module({
  imports: [
    BullModule.registerQueue({
      name: NOTIFICATIONS_QUEUE,
      defaultJobOptions: { attempts: 3, backoff: { type: 'exponential', delay: 2000 } },
      settings: {
        maxStalledCount: 2,
        lockDuration: 30000,
        lockRenewTime: 15000,
      },
    }),
  ],
  controllers: [NotificationsController],
  providers: [NotificationsService, NotificationsProcessor, TenantRemindersService, FcmNotificationsService, PrismaService],
  exports: [NotificationsService],
})
export class NotificationsModule {}
