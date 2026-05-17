import { Injectable, Logger } from '@nestjs/common';
import { InjectQueue } from '@nestjs/bull';
import type { Queue } from 'bull';
import { PrismaService } from '../prisma/prisma.service';
import { v4 as uuidv4 } from 'uuid';
import { NOTIFICATIONS_QUEUE } from './notifications.constants';
import { TwilioWhatsAppProvider } from './providers/twilio-whatsapp.provider';
import { TwilioVoiceProvider } from './providers/twilio-voice.provider';

@Injectable()
export class NotificationsService {
  private readonly logger = new Logger(NotificationsService.name);
  private readonly provider = new TwilioWhatsAppProvider();
  private readonly voiceProvider = new TwilioVoiceProvider();
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
    return this.enqueueNotification({ ...payload, provider: 'twilio-whatsapp' });
  }

  async enqueueVoiceCallNotification(payload: { organizationId?: string; tenantId?: string; invoiceId?: string; type: string; data?: any }) {
    return this.enqueueNotification({ ...payload, provider: 'twilio-voice' });
  }

  private async enqueueNotification(payload: { organizationId?: string; tenantId?: string; invoiceId?: string; type: string; provider: string; data?: any }) {
    this.logger.debug(`[NotificationsService] Enqueueing ${payload.type} for tenant=${payload.tenantId} provider=${payload.provider}`);
    const log = await this.prisma.notificationLog.create({
      data: {
        organizationId: payload.organizationId,
        tenantId: payload.tenantId,
        invoiceId: payload.invoiceId,
        type: payload.type,
        provider: payload.provider,
        payload: payload.data ?? null,
      },
    });

    this.logger.debug(`[NotificationsService] Created notificationLog id=${log.id}`);

    // In dev mode, always send synchronously without queue.
    if (this.isDev || !this.queueEnabled) {
      this.logger.debug(`[NotificationsService] Queue bypass enabled: sending notification synchronously`);
      this.processNotificationLog(log.id).catch((err) => this.logger.error('Direct send failed', err));
    } else if (this.queue) {
      this.logger.debug(`[NotificationsService] Production mode: adding to queue`);
      try {
        await this.queue.add('send', { notificationLogId: log.id });
      } catch (error: any) {
        // Fall back to direct delivery when Redis is unavailable to prevent bulk reminder runs from failing.
        this.logger.error(
          `[NotificationsService] Queue add failed, falling back to direct send: ${error?.message ?? error}`,
        );
        this.processNotificationLog(log.id).catch((err) => this.logger.error('Direct send failed', err));
      }
    } else {
      this.logger.warn('[NotificationsService] Queue provider unavailable, falling back to direct send');
      this.processNotificationLog(log.id).catch((err) => this.logger.error('Direct send failed', err));
    }

    return log;
  }

  async processNotificationLog(notificationLogId: string) {
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
        voiceText?: string;
        voice?: string;
        language?: string;
        template?: { name: string; language: { code: string }; components?: Array<Record<string, unknown>> };
      };

      if (!phone) {
        this.logger.warn(`[NotificationsService] No phone for tenant ${log.tenantId}`);
        await this.markAsFailed(log.id, 'No phone number for tenant');
        return;
      }

      if (log.provider === 'twilio-voice' || log.type.endsWith('_call')) {
        const callMessage = payload.voiceText ?? payload.text ?? `Reminder from ${log.type}`;
        this.logger.debug(`[NotificationsService] Calling voice provider for ${phone.slice(-4)}`);

        const res = await this.voiceProvider.sendCall({
          phone,
          message: callMessage,
          voice: payload.voice,
          language: payload.language,
        });
        const providerMessageId = res?.sid ?? res?.id ?? JSON.stringify(res);
        this.logger.debug(`[NotificationsService] Call placed. providerMessageId=${providerMessageId}`);
        await this.markAsSent(log.id, String(providerMessageId));
        return;
      }

      const text = payload.text ?? `Notification: ${log.type}`;
      const media = payload.mediaUrl;

      this.logger.debug(`[NotificationsService] Calling WhatsApp provider for ${phone.slice(-4)}`);

      try {
        const res = await this.provider.sendMessage({ phone, text, mediaUrl: media, template: payload.template });
        const providerMessageId = res?.sid ?? res?.id ?? JSON.stringify(res);
        this.logger.debug(`[NotificationsService] Message sent. providerMessageId=${providerMessageId}`);
        await this.markAsSent(log.id, String(providerMessageId));
      } catch (sendErr: any) {
        const errMsg = String(sendErr?.message ?? sendErr);
        const isOutsideWindow = sendErr?.code === 63016 || errMsg.includes('63016') || errMsg.toLowerCase().includes('outside messaging window');

        if (isOutsideWindow) {
          this.logger.warn(`[NotificationsService] Provider reported outside messaging window for ${phone.slice(-4)}: ${errMsg}`);

          if (payload.template) {
            this.logger.debug(`[NotificationsService] Attempting template send for notificationLog=${log.id}`);
            try {
              const tRes = await this.provider.sendTemplate(phone, payload.template);
              const tId = tRes?.sid ?? tRes?.id ?? JSON.stringify(tRes);
              this.logger.debug(`[NotificationsService] Template sent. providerMessageId=${tId}`);
              await this.markAsSent(log.id, String(tId));
              return;
            } catch (tErr: any) {
              this.logger.error(`[NotificationsService] Template send failed: ${String(tErr?.message ?? tErr)}`);
              await this.markAsFailed(log.id, `Template send failed: ${String(tErr?.message ?? tErr)}`);
              return;
            }
          }

          await this.markAsFailed(log.id, 'Outside messaging window (63016): template required for business-initiated WhatsApp messages');
          return;
        }

        this.logger.error(`[NotificationsService] Send error: ${errMsg}`);
        await this.markAsFailed(log.id, errMsg);
      }
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
