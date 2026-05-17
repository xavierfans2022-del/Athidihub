import { BadRequestException, ForbiddenException, Injectable, Logger } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { NotificationsService } from './notifications.service';
import { FcmNotificationsService } from './fcm-notifications.service';
import { InvoiceStatus } from '@prisma/client';

type ReminderMode = 'payment' | 'custom';

interface BulkReminderOptions {
  organizationId?: string;
  daysAhead?: number;
  includeOverdue?: boolean;
  message?: string;
  mode?: ReminderMode;
  force?: boolean;
  dryRun?: boolean;
  voiceCall?: boolean;
}

interface ReminderTenantGroup {
  tenantId: string;
  tenantName: string;
  phone?: string;
  profileId?: string;
  invoices: Array<{
    id: string;
    month: number;
    year: number;
    dueDate: Date;
    totalAmount: number;
    status: InvoiceStatus;
  }>;
}

@Injectable()
export class TenantRemindersService {
  private readonly logger = new Logger(TenantRemindersService.name);

  constructor(
    private readonly prisma: PrismaService,
    private readonly notificationsService: NotificationsService,
    private readonly fcmNotificationsService: FcmNotificationsService,
  ) {}

  async sendBulkReminders(options: BulkReminderOptions) {
    const mode = options.mode ?? 'payment';
    const voiceCall = options.voiceCall ?? process.env.REMINDER_VOICE_CALLS_ENABLED === 'true';
    if (mode === 'custom' && !options.message?.trim()) {
      throw new BadRequestException('message is required for custom reminders');
    }

    const orgIds = options.organizationId
      ? [options.organizationId]
      : (await this.prisma.organization.findMany({ select: { id: true } })).map((org) => org.id);

    const summary = {
      mode,
      organizationsProcessed: 0,
      remindersQueued: 0,
      remindersSkippedAlreadySent: 0,
      remindersSkippedNoPhone: 0,
      remindersSkippedNoWork: 0,
      errors: [] as Array<{ organizationId?: string; tenantId?: string; error: string }>,
    };

    for (const organizationId of orgIds) {
      summary.organizationsProcessed += 1;
      try {
        if (mode === 'custom') {
          const result = await this.sendCustomBroadcast({
            organizationId,
            message: options.message!,
            force: options.force ?? false,
            dryRun: options.dryRun ?? false,
            voiceCall,
          });
          summary.remindersQueued += result.queued;
          summary.remindersSkippedAlreadySent += result.skippedAlreadySent;
          summary.remindersSkippedNoPhone += result.skippedNoPhone;
          summary.remindersSkippedNoWork += result.skippedNoWork;
          continue;
        }

        const result = await this.sendPaymentRemindersForOrg({
          organizationId,
          daysAhead: options.daysAhead ?? 3,
          includeOverdue: options.includeOverdue ?? true,
          force: options.force ?? false,
          dryRun: options.dryRun ?? false,
          voiceCall,
        });
        summary.remindersQueued += result.queued;
        summary.remindersSkippedAlreadySent += result.skippedAlreadySent;
        summary.remindersSkippedNoPhone += result.skippedNoPhone;
        summary.remindersSkippedNoWork += result.skippedNoWork;
      } catch (error: any) {
        this.logger.error(`Reminder run failed for organization=${organizationId}: ${error?.message ?? error}`);
        summary.errors.push({ organizationId, error: String(error?.message ?? error) });
      }
    }

    return summary;
  }

  async sendPaymentRemindersForOrg(options: {
    organizationId: string;
    daysAhead?: number;
    includeOverdue?: boolean;
    force?: boolean;
    dryRun?: boolean;
    voiceCall?: boolean;
  }) {
    const daysAhead = Math.max(0, options.daysAhead ?? 3);
    const now = new Date();
    const cutoff = new Date(now.getTime() + daysAhead * 24 * 60 * 60 * 1000);
    const startOfDay = new Date(now);
    startOfDay.setHours(0, 0, 0, 0);

    const organization = await this.prisma.organization.findUnique({
      where: { id: options.organizationId },
      select: { id: true, name: true },
    });

    if (!organization) {
      throw new BadRequestException('Organization not found');
    }

    const invoices = await this.prisma.invoice.findMany({
      where: {
        organizationId: options.organizationId,
        OR: [
          {
            status: InvoiceStatus.PENDING,
            dueDate: { lte: cutoff },
          },
          ...(options.includeOverdue ? [{ status: InvoiceStatus.OVERDUE }] : []),
        ],
      },
      orderBy: [{ dueDate: 'asc' }, { createdAt: 'asc' }],
      include: {
        tenant: { include: { profile: true } },
      },
    });

    const grouped = new Map<string, ReminderTenantGroup>();
    for (const invoice of invoices) {
      const tenantId = invoice.tenantId;
      const tenantName = invoice.tenant?.name ?? 'Tenant';
      const phone = invoice.tenant?.profile?.phone ?? undefined;
      const profileId = invoice.tenant?.profile?.id ?? undefined;

      if (!grouped.has(tenantId)) {
        grouped.set(tenantId, { tenantId, tenantName, phone, profileId, invoices: [] });
      }
      grouped.get(tenantId)!.invoices.push({
        id: invoice.id,
        month: invoice.month,
        year: invoice.year,
        dueDate: invoice.dueDate,
        totalAmount: Number(invoice.totalAmount),
        status: invoice.status,
      });
    }

    const summary = {
      organizationId: organization.id,
      organizationName: organization.name,
      queued: 0,
      skippedAlreadySent: 0,
      skippedNoPhone: 0,
      skippedNoWork: 0,
      reminders: [] as Array<{ tenantId: string; tenantName: string; status: 'queued' | 'skipped'; reason?: string }>,
    };

    for (const group of grouped.values()) {
      if (!group.invoices.length) {
        summary.skippedNoWork += 1;
        summary.reminders.push({ tenantId: group.tenantId, tenantName: group.tenantName, status: 'skipped', reason: 'no_due_invoices' });
        continue;
      }

      if (!group.phone) {
        summary.skippedNoPhone += 1;
        summary.reminders.push({ tenantId: group.tenantId, tenantName: group.tenantName, status: 'skipped', reason: 'no_phone' });
        continue;
      }

      const alreadySent = await this.prisma.notificationLog.findFirst({
        where: {
          organizationId: organization.id,
          tenantId: group.tenantId,
          type: 'payment_reminder',
          createdAt: { gte: startOfDay },
          status: { in: ['queued', 'sent'] },
        },
        orderBy: { createdAt: 'desc' },
      });

      // Already-sent guard disabled per request: always send notifications
      // if (alreadySent && !options.force) {
      //   summary.skippedAlreadySent += 1;
      //   summary.reminders.push({ tenantId: group.tenantId, tenantName: group.tenantName, status: 'skipped', reason: 'already_sent_today' });
      //   continue;
      // }

      const overdueInvoices = group.invoices.filter((invoice) => invoice.status === InvoiceStatus.OVERDUE || invoice.dueDate < now);
      const dueInvoices = group.invoices.filter((invoice) => invoice.status === InvoiceStatus.PENDING && invoice.dueDate >= now);
      const totalDue = group.invoices.reduce((sum, invoice) => sum + invoice.totalAmount, 0);
      const earliestDue = group.invoices.slice().sort((a, b) => a.dueDate.getTime() - b.dueDate.getTime())[0]?.dueDate;
      const monthsText = group.invoices
        .slice(0, 3)
        .map((invoice) => `${this.monthName(invoice.month)} ${invoice.year}`)
        .join(', ');

      const message = [
        `*Rent Reminder - ${organization.name}*`,
        `Hi ${group.tenantName},`,
        overdueInvoices.length > 0
          ? `⚠️ You have ${overdueInvoices.length} overdue rent payment${overdueInvoices.length > 1 ? 's' : ''}.`
          : `👋 This is a friendly reminder for your upcoming rent.`,
        ``,
        `*Total Pending:* ₹${totalDue.toLocaleString('en-IN')}`,
        `*Invoices:* ${group.invoices.length}`,
        monthsText ? `*Period:* ${monthsText}` : null,
        earliestDue ? `*Oldest Due:* ${earliestDue.toLocaleDateString('en-IN')}` : null,
        ``,
        `Please clear your dues at the earliest to avoid late fees. You can pay via the Athidihub app.`,
        `If you have already paid, please ignore this message.`
      ]
        .filter((line) => line !== null)
        .join('\n');

      if (!options.dryRun) {
        await this.notificationsService.enqueueWhatsAppNotification({
          organizationId: organization.id,
          tenantId: group.tenantId,
          type: overdueInvoices.length > 0 ? 'payment_overdue_reminder' : 'payment_reminder',
          data: {
            text: message,
            reminderKind: overdueInvoices.length > 0 ? 'overdue' : 'due',
            invoiceIds: group.invoices.map((invoice) => invoice.id),
            totalDue,
            pendingCount: group.invoices.length,
            overdueCount: overdueInvoices.length,
            dueWindowDays: daysAhead,
          },
        });

        if (options.voiceCall) {
          const callType = overdueInvoices.length > 0 ? 'payment_overdue_reminder_call' : 'payment_reminder_call';
          const alreadySentCall = await this.prisma.notificationLog.findFirst({
            where: {
              organizationId: organization.id,
              tenantId: group.tenantId,
              type: callType,
              provider: 'twilio-voice',
              createdAt: { gte: startOfDay },
              status: { in: ['queued', 'sent'] },
            },
            orderBy: { createdAt: 'desc' },
          });

          // Always enqueue voice calls (disable already-sent guard)
          await this.notificationsService.enqueueVoiceCallNotification({
            organizationId: organization.id,
            tenantId: group.tenantId,
            type: callType,
            data: {
              voiceText: overdueInvoices.length > 0
                ? `Hello ${group.tenantName}. This is an automated rent reminder from ${organization.name}. You have ${overdueInvoices.length} overdue rent payment${overdueInvoices.length > 1 ? 's' : ''}, totaling rupees ${Math.round(totalDue).toLocaleString('en-IN')}. Please clear your dues as soon as possible. Thank you.`
                : `Hello ${group.tenantName}. This is an automated rent reminder from ${organization.name}. You have rent due soon, totaling rupees ${Math.round(totalDue).toLocaleString('en-IN')}. Please review your payment details in the Athidihub app. Thank you.`,
              voice: 'alice',
              language: 'en-IN',
            },
          });
        }

        if (group.profileId) {
          await this.fcmNotificationsService.sendToProfile(group.profileId, {
            title: `Rent reminder - ${organization.name}`,
            body: overdueInvoices.length > 0
              ? `${group.tenantName}, you have ${overdueInvoices.length} overdue rent payment${overdueInvoices.length > 1 ? 's' : ''}.`
              : `${group.tenantName}, you have an upcoming rent reminder from ${organization.name}.`,
            data: {
              type: overdueInvoices.length > 0 ? 'payment_overdue_reminder' : 'payment_reminder',
              organizationId: organization.id,
              tenantId: group.tenantId,
              dueWindowDays: daysAhead,
              route: '/tenant-portal/documents',
            },
          });
        }
      }

      summary.queued += 1;
      summary.reminders.push({ tenantId: group.tenantId, tenantName: group.tenantName, status: 'queued' });
    }

    return summary;
  }

  async sendCustomBroadcast(options: {
    organizationId: string;
    message: string;
    force?: boolean;
    dryRun?: boolean;
    voiceCall?: boolean;
  }) {
    const organization = await this.prisma.organization.findUnique({
      where: { id: options.organizationId },
      select: { id: true, name: true },
    });

    if (!organization) {
      throw new BadRequestException('Organization not found');
    }

    const tenants = await this.prisma.tenant.findMany({
      where: { organizationId: options.organizationId, isActive: true },
      include: { profile: true },
      orderBy: { createdAt: 'desc' },
    });

    const summary = {
      organizationId: organization.id,
      organizationName: organization.name,
      queued: 0,
      skippedAlreadySent: 0,
      skippedNoPhone: 0,
      skippedNoWork: 0,
      reminders: [] as Array<{ tenantId: string; tenantName: string; status: 'queued' | 'skipped'; reason?: string }>,
    };

    const startOfDay = new Date();
    startOfDay.setHours(0, 0, 0, 0);

    for (const tenant of tenants) {
      const phone = tenant.profile?.phone ?? undefined;
      const profileId = tenant.profile?.id ?? undefined;
      if (!phone) {
        summary.skippedNoPhone += 1;
        summary.reminders.push({ tenantId: tenant.id, tenantName: tenant.name, status: 'skipped', reason: 'no_phone' });
        continue;
      }

      const alreadySent = await this.prisma.notificationLog.findFirst({
        where: {
          organizationId: organization.id,
          tenantId: tenant.id,
          type: 'custom_tenant_reminder',
          createdAt: { gte: startOfDay },
          status: { in: ['queued', 'sent'] },
        },
        orderBy: { createdAt: 'desc' },
      });

      // Already-sent guard disabled per request: always send custom reminders
      // if (alreadySent && !options.force) {
      //   summary.skippedAlreadySent += 1;
      //   summary.reminders.push({ tenantId: tenant.id, tenantName: tenant.name, status: 'skipped', reason: 'already_sent_today' });
      //   continue;
      // }

      if (!options.dryRun) {
        await this.notificationsService.enqueueWhatsAppNotification({
          organizationId: organization.id,
          tenantId: tenant.id,
          type: 'custom_tenant_reminder',
          data: {
            text: options.message,
            reminderKind: 'custom',
            customMessage: options.message,
          },
        });

        if (options.voiceCall) {
          // Already-sent guard disabled for custom voice calls; always enqueue
          await this.notificationsService.enqueueVoiceCallNotification({
            organizationId: organization.id,
            tenantId: tenant.id,
            type: 'custom_tenant_reminder_call',
            data: {
              voiceText: `Hello ${tenant.name}. This is an automated notice from ${organization.name}. ${options.message}`,
              voice: 'alice',
              language: 'en-IN',
            },
          });
        }

        if (profileId) {
          await this.fcmNotificationsService.sendToProfile(profileId, {
            title: `Notice from ${organization.name}`,
            body: options.message,
            data: {
              type: 'custom_tenant_reminder',
              organizationId: organization.id,
              tenantId: tenant.id,
              route: '/tenant-portal/documents',
            },
          });
        }
      }

      summary.queued += 1;
      summary.reminders.push({ tenantId: tenant.id, tenantName: tenant.name, status: 'queued' });
    }

    return summary;
  }

  async runCronPaymentReminders(options: { daysAhead?: number; includeOverdue?: boolean; voiceCall?: boolean }) {
    return this.sendBulkReminders({
      mode: 'payment',
      daysAhead: options.daysAhead ?? 3,
      includeOverdue: options.includeOverdue ?? true,
      voiceCall: options.voiceCall ?? process.env.REMINDER_VOICE_CALLS_ENABLED === 'true',
    });
  }

  async ensureOwnerAccess(organizationId: string, userId: string) {
    const organization = await this.prisma.organization.findUnique({
      where: { id: organizationId },
      include: { members: true },
    });

    if (!organization) {
      throw new BadRequestException('Organization not found');
    }

    const hasAccess = organization.ownerId === userId || organization.members.some((member) => member.profileId === userId);
    if (!hasAccess) {
      throw new ForbiddenException('Access denied');
    }

    return organization;
  }

  private monthName(month: number) {
    return new Date(2000, Math.max(0, month - 1), 1).toLocaleString('en-US', { month: 'short' });
  }
}