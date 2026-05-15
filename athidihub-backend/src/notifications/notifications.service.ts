import { Injectable, Logger } from '@nestjs/common';
import { InjectQueue } from '@nestjs/bull';
import type { Queue } from 'bull';
import { PrismaService } from '../prisma/prisma.service';
import { v4 as uuidv4 } from 'uuid';
import { NOTIFICATIONS_QUEUE } from './notifications.constants';
import { TwilioWhatsAppProvider } from './providers/twilio-whatsapp.provider';

@Injectable()
export class NotificationsService {
  private readonly logger = new Logger(NotificationsService.name);
  private readonly provider = new TwilioWhatsAppProvider();
  private readonly isDev = process.env.NODE_ENV !== 'production';
  private readonly queueEnabled = process.env.NOTIFICATIONS_USE_QUEUE !== 'false';

  constructor(private readonly prisma: PrismaService, @InjectQueue(NOTIFICATIONS_QUEUE) private readonly queue?: Queue) {}

  async createWhatsAppLink(tenantId: string, expiresInSeconds = 60 * 60 * 24) {
    const token = uuidv4();
    const base = process.env.UPLOAD_BASE_URL || process.env.APP_BASE_URL || 'https://example.com';
    const url = `${base.replace(/\/$/, '')}/uploads/${token}`;
    const expiresAt = new Date(Date.now() + expiresInSeconds * 1000);

    const link = await this.prisma.whatsAppLink.create({
      data: { tenantId, url, expiresAt },
    });

    return link;
  }

  async enqueueWhatsAppNotification(payload: { organizationId?: string; tenantId?: string; invoiceId?: string; type: string; data?: any }) {
    this.logger.debug(`[NotificationsService] Enqueueing ${payload.type} for tenant=${payload.tenantId}`);
    const log = await this.prisma.notificationLog.create({
      data: {
        organizationId: payload.organizationId,
        tenantId: payload.tenantId,
        invoiceId: payload.invoiceId,
        type: payload.type,
        provider: process.env.WHATSAPP_PROVIDER || 'twilio',
        payload: payload.data ?? null,
      },
    });

    this.logger.debug(`[NotificationsService] Created notificationLog id=${log.id}`);

    // In dev mode, always send synchronously without queue.
    if (this.isDev || !this.queueEnabled) {
      this.logger.debug(`[NotificationsService] Queue bypass enabled: sending notification synchronously`);
      this.sendNotificationDirectly(log.id).catch((err) => this.logger.error('Direct send failed', err));
    } else if (this.queue) {
      this.logger.debug(`[NotificationsService] Production mode: adding to queue`);
      try {
        await this.queue.add('send', { notificationLogId: log.id });
      } catch (error: any) {
        // Fall back to direct delivery when Redis is unavailable to prevent bulk reminder runs from failing.
        this.logger.error(
          `[NotificationsService] Queue add failed, falling back to direct send: ${error?.message ?? error}`,
        );
        this.sendNotificationDirectly(log.id).catch((err) => this.logger.error('Direct send failed', err));
      }
    } else {
      this.logger.warn('[NotificationsService] Queue provider unavailable, falling back to direct send');
      this.sendNotificationDirectly(log.id).catch((err) => this.logger.error('Direct send failed', err));
    }

    return log;
  }

  private async sendNotificationDirectly(notificationLogId: string) {
    const log = await this.prisma.notificationLog.findUnique({ where: { id: notificationLogId } });
    if (!log) {
      this.logger.warn(`[NotificationsService] NotificationLog not found: ${notificationLogId}`);
      return;
    }

    try {
      this.logger.debug(`[NotificationsService] Sending notification type=${log.type}`);

      let phone: string | undefined;
      if (log.tenantId) {
        const tenant = await this.prisma.tenant.findUnique({ where: { id: log.tenantId }, include: { profile: true } });
        phone = tenant?.profile?.phone ?? undefined;
        this.logger.debug(`[NotificationsService] Tenant phone resolved: ${phone ? phone.slice(-4) : 'none'}`);
      }

      const payload = (log.payload ?? {}) as {
        text?: string;
        mediaUrl?: string;
        template?: { name: string; language: { code: string }; components?: Array<Record<string, unknown>> };
      };

      if (!phone) {
        this.logger.warn(`[NotificationsService] No phone for tenant ${log.tenantId}`);
        await this.markAsFailed(log.id, 'No phone number for tenant');
        return;
      }

      const text = payload.text ?? `Notification: ${log.type}`;
      const media = payload.mediaUrl;

      this.logger.debug(`[NotificationsService] Calling provider for ${phone.slice(-4)}`);
      const res = await this.provider.sendMessage({
        phone,
        text,
        mediaUrl: media,
        template: payload.template,
      });
      const providerMessageId = res?.sid ?? res?.id ?? JSON.stringify(res);

      this.logger.debug(`[NotificationsService] Message sent. providerMessageId=${providerMessageId}`);
      await this.markAsSent(log.id, String(providerMessageId));
    } catch (err: any) {
      this.logger.error(`[NotificationsService] Error: ${err?.message ?? err}`, err?.stack);
      await this.markAsFailed(log.id, String(err?.message ?? err));
    }
  }

  async markAsSent(id: string, providerMessageId?: string) {
    return this.prisma.notificationLog.update({ where: { id }, data: { status: 'sent', providerMessageId, sentAt: new Date() } });
  }

  async markAsFailed(id: string, error: string) {
    this.logger.warn(`Notification ${id} failed: ${error}`);
    return this.prisma.notificationLog.update({ where: { id }, data: { status: 'failed', error } });
  }
}
