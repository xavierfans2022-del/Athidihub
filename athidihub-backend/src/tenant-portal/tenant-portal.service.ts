import { Injectable, NotFoundException, BadRequestException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { Prisma } from '@prisma/client';

@Injectable()
export class TenantPortalService {
  constructor(private readonly prisma: PrismaService) {}

  /** Find a tenant record by the linked Supabase profile id */
  async findByProfileId(profileId: string) {
    const tenant = await this.prisma.tenant.findUnique({
      where: { profileId },
      include: {
        organization: true,
        assignments: {
          where: { isActive: true },
          include: {
            bed: {
              include: {
                room: {
                  include: { property: true },
                },
              },
            },
          },
        },
      },
    });
    if (!tenant) throw new NotFoundException('Tenant record not found for this account');
    return tenant;
  }

  /** Tenant self-dashboard: rent status, assignment, recent invoices */
  async getDashboard(profileId: string) {
    const tenant = await this.findByProfileId(profileId);

    const now = new Date();
    const month = now.getMonth() + 1;
    const year = now.getFullYear();

    const [currentInvoice, recentPayments, upcomingInvoices, maintenanceRequests] =
      await Promise.all([
        // Invoice for the current month
        this.prisma.invoice.findFirst({
          where: { tenantId: tenant.id, month, year },
          include: { payment: true },
        }),
        // Last 3 payments
        this.prisma.payment.findMany({
          where: { tenantId: tenant.id, status: 'SUCCESS' },
          orderBy: { paidAt: 'desc' },
          take: 3,
          include: { invoice: true },
        }),
        // All pending / overdue invoices
        this.prisma.invoice.findMany({
          where: { tenantId: tenant.id, status: { in: ['PENDING', 'OVERDUE'] } },
          orderBy: [{ status: 'desc' }, { dueDate: 'asc' }], // OVERDUE first
          take: 10,
          include: { payment: true },
        }),
        // Open maintenance requests
        this.prisma.maintenanceRequest.findMany({
          where: { tenantId: tenant.id, status: { in: ['PENDING', 'IN_PROGRESS'] } },
          orderBy: { createdAt: 'desc' },
          take: 3,
        }),
      ]);

    const activeAssignment = tenant.assignments[0] ?? null;
    const room = activeAssignment?.bed?.room ?? null;
    const property = room?.property ?? null;

    // Total paid amount (all time)
    const totalPaidAgg = await this.prisma.payment.aggregate({
      where: { tenantId: tenant.id, status: 'SUCCESS' },
      _sum: { amount: true },
    });

    return {
      tenant: {
        id: tenant.id,
        name: tenant.name,
        email: tenant.email,
        phone: tenant.phone,
        joiningDate: tenant.joiningDate,
        aadhaarVerified: tenant.aadhaarVerified,
        checkInCompleted: tenant.checkInCompleted,
        checkInDate: tenant.checkInDate,
        isActive: tenant.isActive,
      },
      assignment: activeAssignment
        ? {
            id: activeAssignment.id,
            startDate: activeAssignment.startDate,
            bedNumber: activeAssignment.bed?.bedNumber,
            bedType: activeAssignment.bed?.bedType,
            roomNumber: room?.roomNumber,
            floorNumber: room?.floorNumber,
            roomType: room?.roomType,
            monthlyRent: room?.monthlyRent,
            securityDeposit: activeAssignment.securityDeposit,
            propertyName: property?.name,
            propertyAddress: property?.address,
            propertyCity: property?.city,
          }
        : null,
      organization: {
        id: tenant.organization.id,
        name: tenant.organization.name,
        logoUrl: tenant.organization.logoUrl,
      },
      currentInvoice,
      overdueInvoices: upcomingInvoices.filter(inv => inv.status === 'OVERDUE'),
      upcomingInvoices: upcomingInvoices.filter(inv => inv.status === 'PENDING'),
      recentPayments,
      maintenanceOpen: maintenanceRequests.length,
      overdueCount: upcomingInvoices.filter(inv => inv.status === 'OVERDUE').length,
      totalPaid: totalPaidAgg._sum.amount ?? 0,
    };
  }

  /** Paginated invoice list with optional month/year filter */
  async getInvoices(
    profileId: string,
    params: { month?: number; year?: number; page?: number; limit?: number },
  ) {
    const tenant = await this.findByProfileId(profileId);
    const { month, year, page = 1, limit = 12 } = params;
    const skip = (page - 1) * limit;

    const where: any = { tenantId: tenant.id };
    if (month) where.month = month;
    if (year) where.year = year;

    const [data, total] = await Promise.all([
      this.prisma.invoice.findMany({
        where,
        include: { payment: true },
        orderBy: [{ year: 'desc' }, { month: 'desc' }],
        skip,
        take: limit,
      }),
      this.prisma.invoice.count({ where }),
    ]);

    return { data, total, page, limit, hasMore: skip + data.length < total };
  }

  /** Payment history — paid invoices with receipt links */
  async getPaymentHistory(
    profileId: string,
    params: { month?: number; year?: number; page?: number; limit?: number },
  ) {
    const tenant = await this.findByProfileId(profileId);
    const { month, year, page = 1, limit = 12 } = params;
    const skip = (page - 1) * limit;

    const invoiceWhere: any = { tenantId: tenant.id };
    if (month) invoiceWhere.month = month;
    if (year) invoiceWhere.year = year;

    const where: any = {
      tenantId: tenant.id,
      status: 'SUCCESS',
      invoice: invoiceWhere,
    };

    const [data, total] = await Promise.all([
      this.prisma.payment.findMany({
        where,
        include: { invoice: true },
        orderBy: { paidAt: 'desc' },
        skip,
        take: limit,
      }),
      this.prisma.payment.count({ where }),
    ]);

    return { data, total, page, limit, hasMore: skip + data.length < total };
  }

  /** Upload Aadhaar document URL (storage handled by Supabase client-side) */
  async verifyAadhaar(profileId: string, aadhaarUrl: string) {
    const tenant = await this.findByProfileId(profileId);
    return this.prisma.tenant.update({
      where: { id: tenant.id },
      data: { aadhaarUrl, aadhaarVerified: false }, // Admin verifies later; mark pending
    });
  }

  /** Mark Aadhaar as admin-verified (owner/manager only — called from admin side) */
  async adminApproveAadhaar(tenantId: string) {
    return this.prisma.tenant.update({
      where: { id: tenantId },
      data: { aadhaarVerified: true },
    });
  }

  /** Delete/Reset Aadhaar verification (if user wants to re-upload or owner rejects) */
  async deleteAadhaar(profileId: string) {
    const tenant = await this.findByProfileId(profileId);
    if (tenant.aadhaarVerified) {
      throw new BadRequestException('Cannot delete a verified Aadhaar. Contact management.');
    }
    return this.prisma.tenant.update({
      where: { id: tenant.id },
      data: { aadhaarUrl: null, aadhaarVerified: false, aadhaarDetails: Prisma.DbNull },
    });
  }

  /** Initiate DigiLocker Flow (sandbox or production authorize URL) */
  async getDigiLockerUrl(profileId: string) {
    const state = Buffer.from(profileId).toString('base64');
    const redirectUri = `${process.env.APP_BASE_URL ?? 'http://localhost:3000'}/tenant/digilocker-callback`;
    
    const baseUrl = process.env.DIGILOCKER_AUTHORIZE_URL || 'https://sandbox.co.in/digital-locker';
    const clientId = process.env.SANDBOX_CLIENT_ID || process.env.DIGILOCKER_CLIENT_ID || '';
    
    const url = new URL(baseUrl);
    url.searchParams.set('response_type', 'code');
    url.searchParams.set('client_id', clientId);
    url.searchParams.set('redirect_uri', redirectUri);
    url.searchParams.set('state', state);
    url.searchParams.set('scope', 'aadhaar');
    
    return { url: url.toString() };
  }

  /** Verify DigiLocker Callback (MOCK implementation) */
  async verifyDigiLockerCallback(profileId: string, code: string, state: string) {
    const tenant = await this.findByProfileId(profileId);

    // In production: Exchange `code` for token -> fetch Aadhaar XML from DigiLocker API
    // Here we mock the response from DigiLocker:
    const mockAadhaarDetails = {
      name: tenant.name,
      gender: 'M',
      dob: '01-01-1995',
      address: '123 Fake Street, Model Town, Mock City',
      verifiedVia: 'DigiLocker',
      verifiedAt: new Date().toISOString(),
    };

    return this.prisma.tenant.update({
      where: { id: tenant.id },
      data: {
        aadhaarVerified: true, // DigiLocker is an authoritative source, auto-verifies
        aadhaarDetails: mockAadhaarDetails as any,
      },
    });
  }

  /** Complete digital check-in */
  async completeCheckIn(profileId: string) {
    const tenant = await this.findByProfileId(profileId);
    if (!tenant.aadhaarVerified) {
      throw new BadRequestException('Aadhaar must be verified before check-in');
    }
    if (tenant.checkInCompleted) {
      throw new BadRequestException('Check-in already completed');
    }
    return this.prisma.tenant.update({
      where: { id: tenant.id },
      data: { checkInCompleted: true, checkInDate: new Date() },
    });
  }

  /** Update tenant profile fields (name, phone, emergency contact) */
  async updateProfile(
    profileId: string,
    dto: { name?: string; phone?: string; emergencyContact?: string },
  ) {
    const tenant = await this.findByProfileId(profileId);
    return this.prisma.tenant.update({
      where: { id: tenant.id },
      data: dto,
    });
  }
}
