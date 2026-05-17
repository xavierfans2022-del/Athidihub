import { Process, Processor } from '@nestjs/bull';
import type { Job } from 'bull';
import { Injectable, Logger } from '@nestjs/common';
import { NotificationsService } from './notifications.service';

@Processor('notifications')
@Injectable()
export class NotificationsProcessor {
  private readonly logger = new Logger(NotificationsProcessor.name);

  constructor(private readonly notificationsService: NotificationsService) {}

  @Process('send')
  async handleSend(job: Job<{ notificationLogId: string }>) {
    const { notificationLogId } = job.data;
    this.logger.debug(`[NotificationProcessor] Processing job for notificationLogId=${notificationLogId}`);

    try {
      await this.notificationsService.processNotificationLog(notificationLogId);
    } catch (err: any) {
      this.logger.error(`[NotificationProcessor] Error processing job: ${err?.message ?? err}`, err?.stack);
      throw err;
    }
  }
}
