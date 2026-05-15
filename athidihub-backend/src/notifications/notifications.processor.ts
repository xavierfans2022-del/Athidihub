import { Process, Processor } from '@nestjs/bull';
import type { Job } from 'bull';
import { Injectable, Logger } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { TwilioWhatsAppProvider } from './providers/twilio-whatsapp.provider';
import { NotificationsService } from './notifications.service';

@Processor('notifications')
@Injectable()
export class NotificationsProcessor {
  private readonly logger = new Logger(NotificationsProcessor.name);

  private provider = new TwilioWhatsAppProvider();

  constructor(private readonly prisma: PrismaService, private readonly notificationsService: NotificationsService) {}

  @Process('send')
  async handleSend(job: Job<{ notificationLogId: string }>) {
    const { notificationLogId } = job.data;
    this.logger.debug(`[NotificationProcessor] Processing job for notificationLogId=${notificationLogId}`);

    const log = await this.prisma.notificationLog.findUnique({ where: { id: notificationLogId } });
    if (!log) {
      this.logger.warn(`[NotificationProcessor] NotificationLog not found: ${notificationLogId}`);
      return;
    }

    try {
      this.logger.debug(`[NotificationProcessor] Processing notification type=${log.type}, status=${log.status}`);

      // Resolve tenant phone if present
      let phone: string | undefined;
      if (log.tenantId) {
        const tenant = await this.prisma.tenant.findUnique({ where: { id: log.tenantId }, include: { profile: true } });
        phone = tenant?.profile?.phone ?? undefined;
        this.logger.debug(`[NotificationProcessor] Tenant phone resolved: ${phone ? phone.slice(-4) : 'none'}`);
      }

      // For invoice notifications we might include pdf link or invoice id
      const payload = (log.payload ?? {}) as {
        text?: string;
        mediaUrl?: string;
        template?: { name: string; language: { code: string }; components?: Array<Record<string, unknown>> };
      };

      if (!phone) {
        this.logger.warn(`[NotificationProcessor] No phone for tenant ${log.tenantId}`);
        await this.notificationsService.markAsFailed(log.id, 'No phone number for tenant');
        return;
      }

      // Very simple templating; in production use template service
      const text = payload.text ?? `Notification: ${log.type}`;
      const media = payload.mediaUrl;

      this.logger.debug(`[NotificationProcessor] Sending to ${phone.slice(-4)} via ${log.provider}`);
      const res = await this.provider.sendMessage({
        phone,
        text,
        mediaUrl: media,
        template: payload.template,
      });
      const providerMessageId = res?.sid ?? res?.id ?? JSON.stringify(res);

      this.logger.debug(`[NotificationProcessor] Sent successfully. providerMessageId=${providerMessageId}`);
      await this.notificationsService.markAsSent(log.id, String(providerMessageId));
    } catch (err: any) {
      this.logger.error(`[NotificationProcessor] Error processing job: ${err?.message ?? err}`, err?.stack);
      await this.notificationsService.markAsFailed(log.id, String(err?.message ?? err));
      throw err;
    }
  }
}
