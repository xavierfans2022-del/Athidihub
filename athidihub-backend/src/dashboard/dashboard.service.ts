import { Injectable, BadRequestException, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';

type DashboardMonthPoint = {
  month: number;
  year: number;
  label: string;
  revenue: number;
  paidCount: number;
};

@Injectable()
export class DashboardService {
  constructor(private readonly prisma: PrismaService) {}

  async getSummary(organizationId: string) {
    if (!organizationId) {
      throw new BadRequestException('organizationId is required');
    }

    const organization = await this.prisma.organization.findUnique({
      where: { id: organizationId },
      select: { id: true, name: true, logoUrl: true },
    });

    if (!organization) {
      throw new BadRequestException('Organization not found');
    }

    const propertyIds = await this.prisma.property.findMany({
      where: { organizationId, isActive: true },
      select: { id: true },
    });

    const propertyIdList = propertyIds.map((item) => item.id);

    const now = new Date();
    const months = this.getLastMonths(6, now);
    const monthFilter = months.map((m) => ({ month: m.month, year: m.year }));

    const [
      propertyCount,
      roomCount,
      bedCount,
      availableBedCount,
      occupiedBedCount,
      tenantCount,
      activeTenantCount,
      activeAssignmentCount,
      openMaintenanceCount,
      monthlyPaid,
      pendingSummary,
      overdueSummary,
      totalCollectedSummary,
      totalBilledSummary,
      recentPayments,
      recentInvoices,
      recentMaintenance,
      revenueGroups,
    ] = await Promise.all([
      this.prisma.property.count({ where: { organizationId, isActive: true } }),
      this.prisma.room.count({ where: { property: { organizationId } } }),
      this.prisma.bed.count({ where: { room: { property: { organizationId } } } }),
      this.prisma.bed.count({ where: { status: 'AVAILABLE', room: { property: { organizationId } } } }),
      this.prisma.bed.count({ where: { status: 'OCCUPIED', room: { property: { organizationId } } } }),
      this.prisma.tenant.count({ where: { organizationId } }),
      this.prisma.tenant.count({ where: { organizationId, isActive: true } }),
      this.prisma.assignment.count({ where: { isActive: true, tenant: { organizationId } } }),
      this.prisma.maintenanceRequest.count({ where: { propertyId: { in: propertyIdList }, status: { in: ['PENDING', 'IN_PROGRESS'] } } }),
      this.prisma.invoice.aggregate({
        where: { organizationId, status: 'PAID', month: now.getMonth() + 1, year: now.getFullYear() },
        _sum: { totalAmount: true },
        _count: true,
      }),
      this.prisma.invoice.aggregate({
        where: { organizationId, status: 'PENDING' },
        _sum: { totalAmount: true },
        _count: true,
      }),
      this.prisma.invoice.aggregate({
        where: { organizationId, status: 'OVERDUE' },
        _sum: { totalAmount: true },
        _count: true,
      }),
      this.prisma.payment.aggregate({
        where: { status: 'SUCCESS', invoice: { organizationId } },
        _sum: { amount: true },
        _count: true,
      }),
      this.prisma.invoice.aggregate({
        where: { organizationId },
        _sum: { totalAmount: true },
        _count: true,
      }),
      this.prisma.payment.findMany({
        where: { invoice: { organizationId } },
        include: { invoice: { include: { tenant: true } } },
        orderBy: { createdAt: 'desc' },
        take: 5,
      }),
      this.prisma.invoice.findMany({
        where: { organizationId },
        include: { tenant: true, payment: true },
        orderBy: { createdAt: 'desc' },
        take: 5,
      }),
      this.prisma.maintenanceRequest.findMany({
        where: { propertyId: { in: propertyIdList } },
        orderBy: { createdAt: 'desc' },
        take: 5,
      }),
      this.prisma.invoice.groupBy({
        by: ['month', 'year'],
        where: { organizationId, status: 'PAID', OR: monthFilter },
        _sum: { totalAmount: true },
        _count: true,
      }),
    ]);

    const series: DashboardMonthPoint[] = months.map((month) => {
      const match = revenueGroups.find((entry) => entry.month === month.month && entry.year === month.year);
      return {
        ...month,
        revenue: Number(match?._sum.totalAmount ?? 0),
        paidCount: typeof match?._count === 'number' ? match._count : (match?._count as unknown as { _all?: number })?._all ?? 0,
      };
    });

    const extractCount = (c: any) => (typeof c === 'number' ? c : (c as any)?._all ?? 0);
    const totalBeds = bedCount || 0;
    const occupancyRate = totalBeds > 0 ? Math.round((occupiedBedCount / totalBeds) * 1000) / 10 : 0;

    return {
      organization,
      overview: {
        propertyCount,
        roomCount,
        bedCount,
        occupiedBedCount,
        availableBedCount,
        tenantCount,
        activeTenantCount,
        activeAssignmentCount,
        openMaintenanceCount,
        occupancyRate,
      },
      finance: {
        monthlyRevenue: Number(monthlyPaid._sum.totalAmount ?? 0),
        paidCount: extractCount(monthlyPaid._count),
        pendingAmount: Number(pendingSummary._sum.totalAmount ?? 0),
        pendingCount: extractCount(pendingSummary._count),
        overdueAmount: Number(overdueSummary._sum.totalAmount ?? 0),
        overdueCount: extractCount(overdueSummary._count),
        totalCollected: Number(totalCollectedSummary._sum.amount ?? 0),
        totalBilled: Number(totalBilledSummary._sum.totalAmount ?? 0),
        collectionRate:
          Number(totalBilledSummary._sum.totalAmount ?? 0) > 0
            ? Math.round((Number(totalCollectedSummary._sum.amount ?? 0) / Number(totalBilledSummary._sum.totalAmount ?? 0)) * 1000) / 10
            : 0,
      },
      monthlySeries: series,
      recentPayments: recentPayments.map((payment) => ({
        id: payment.id,
        invoiceId: payment.invoiceId,
        tenantName: payment.invoice.tenant.name,
        amount: Number(payment.amount),
        method: payment.method,
        status: payment.status,
        paidAt: payment.paidAt,
        createdAt: payment.createdAt,
      })),
      recentInvoices: recentInvoices.map((invoice) => ({
        id: invoice.id,
        tenantName: invoice.tenant.name,
        totalAmount: Number(invoice.totalAmount),
        status: invoice.status,
        dueDate: invoice.dueDate,
        createdAt: invoice.createdAt,
      })),
      recentMaintenance: recentMaintenance.map((item) => ({
        id: item.id,
        category: item.category,
        status: item.status,
        propertyId: item.propertyId,
        createdAt: item.createdAt,
      })),
    };
  }

  private getLastMonths(count: number, now: Date): DashboardMonthPoint[] {
    const months: DashboardMonthPoint[] = [];
    for (let index = count - 1; index >= 0; index -= 1) {
      const date = new Date(now.getFullYear(), now.getMonth() - index, 1);
      months.push({
        month: date.getMonth() + 1,
        year: date.getFullYear(),
        label: date.toLocaleString('en-US', { month: 'short' }),
        revenue: 0,
        paidCount: 0,
      });
    }
    return months;
  }

  async getUserProfileWithNavigation(userId: string) {
    const [profile, orgCount, tenant] = await Promise.all([
      this.prisma.profile.findUnique({ where: { id: userId } }),
      this.prisma.organization.count({ where: { ownerId: userId, isActive: true } }),
      this.prisma.tenant.findUnique({
        where: { profileId: userId },
        select: { id: true, assignments: { where: { isActive: true }, take: 1, select: { id: true } } },
      }),
    ]);

    if (!profile) throw new NotFoundException('Profile not found');

    // Role is the single source of truth — Tenant record is secondary confirmation
    const profileRole = (profile as any).role as string;
    const isTenant = profileRole === 'TENANT' || !!tenant;
    const hasOrganization = orgCount > 0;
    const hasAssignment = (tenant?.assignments?.length ?? 0) > 0;

    let route: string;
    let onboardingProgress = null;

    if (isTenant) {
      route = '/tenant/home';
    } else {
      route = hasOrganization ? '/dashboard' : '/onboarding';
      if (!hasOrganization) {
        onboardingProgress = await this.getOnboardingProgress(userId);
      }
    }

    return {
      profile: {
        id: profile.id,
        phone: profile.phone,
        fullName: profile.fullName,
        avatarUrl: (profile as any).avatarUrl ?? null,
        isActive: profile.isActive,
        createdAt: profile.createdAt,
        role: profileRole ?? (isTenant ? 'TENANT' : 'OWNER'),
      },
      navigation: {
        route,
        isTenant,
        isOwner: !isTenant,
        hasOrganization,
        hasAssignment,
        onboardingProgress,
      },
    };
  }

  async getNavigationData(userId: string) {
    const data = await this.getUserProfileWithNavigation(userId);
    return data.navigation;
  }

  async getOnboardingProgress(userId: string) {
    // Use $queryRaw to avoid TS errors before migration runs
    const rows: any[] = await this.prisma.$queryRaw`
      SELECT * FROM "OnboardingProgress" WHERE "profileId" = ${userId} LIMIT 1
    `;

    if (rows.length > 0) return rows[0];

    const created: any[] = await this.prisma.$queryRaw`
      INSERT INTO "OnboardingProgress" ("id", "profileId", "currentStep", "onboardingStatus",
        "organizationCreated", "propertyCreated", "roomCreated", "bedCreated",
        "createdAt", "updatedAt")
      VALUES (gen_random_uuid(), ${userId}, 0, 'NOT_STARTED',
        false, false, false, false, NOW(), NOW())
      RETURNING *
    `;

    return created[0];
  }

  async updateOnboardingStep(
    userId: string,
    data: { step: number; organizationId?: string; propertyId?: string; roomId?: string },
  ) {
    const progress = await this.getOnboardingProgress(userId);

    const orgCreated = data.step >= 1 && !!data.organizationId;
    const propCreated = data.step >= 2 && !!data.propertyId;
    const roomCreated = data.step >= 3 && !!data.roomId;
    const bedCreated = data.step >= 4;

    const rows: any[] = await this.prisma.$queryRaw`
      UPDATE "OnboardingProgress" SET
        "currentStep" = ${data.step},
        "onboardingStatus" = 'IN_PROGRESS',
        "organizationCreated" = CASE WHEN ${orgCreated} THEN true ELSE "organizationCreated" END,
        "organizationId"     = CASE WHEN ${!!data.organizationId} THEN ${data.organizationId ?? null}::text ELSE "organizationId" END,
        "propertyCreated"    = CASE WHEN ${propCreated} THEN true ELSE "propertyCreated" END,
        "propertyId"         = CASE WHEN ${!!data.propertyId} THEN ${data.propertyId ?? null}::text ELSE "propertyId" END,
        "roomCreated"        = CASE WHEN ${roomCreated} THEN true ELSE "roomCreated" END,
        "roomId"             = CASE WHEN ${!!data.roomId} THEN ${data.roomId ?? null}::text ELSE "roomId" END,
        "bedCreated"         = CASE WHEN ${bedCreated} THEN true ELSE "bedCreated" END,
        "updatedAt"          = NOW()
      WHERE "id" = ${progress.id}
      RETURNING *
    `;

    return rows[0];
  }

  async completeOnboarding(userId: string) {
    const progress = await this.getOnboardingProgress(userId);

    const rows: any[] = await this.prisma.$queryRaw`
      UPDATE "OnboardingProgress" SET
        "onboardingStatus" = 'COMPLETED',
        "completedAt" = NOW(),
        "updatedAt" = NOW()
      WHERE "id" = ${progress.id}
      RETURNING *
    `;

    return rows[0];
  }
}
