import { Injectable, NotFoundException, BadRequestException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { CreateInvoiceDto } from './dto/create-invoice.dto';
import { UpdateInvoiceDto } from './dto/update-invoice.dto';
import { InvoiceStatus } from '@prisma/client';
import { StorageService } from '../storage/storage.service';

@Injectable()

export class InvoicesService {
  constructor(private readonly prisma: PrismaService, private readonly storageService: StorageService) {}

  private invoiceInclude = {
    tenant: {
      include: {
        organization: {
          select: {
            id: true,
            name: true,
            logoUrl: true,
          },
        },
      },
    },
    payment: true,
  };

  async create(createInvoiceDto: CreateInvoiceDto) {
    return this.prisma.invoice.create({
      data: createInvoiceDto,
      include: this.invoiceInclude,
    });
  }

  async generateForTenant(payload: {
    tenantId: string;
    month: number;
    year: number;
    utilityCharges?: number;
    foodCharges?: number;
    lateFee?: number;
    discount?: number;
    dueDate?: string;
  }) {
    const { tenantId, month, year, utilityCharges = 0, foodCharges = 0, lateFee = 0, discount = 0, dueDate } = payload;

    // Check for duplicate invoice
    const existing = await this.prisma.invoice.findFirst({
      where: { tenantId, month, year },
    });
    if (existing) throw new BadRequestException(`Invoice for ${month}/${year} already exists for this tenant`);

    // Use assignment's monthlyRent (per-tenant override) not room's default
    const assignment = await this.prisma.assignment.findFirst({
      where: { tenantId, isActive: true },
      include: { bed: { include: { room: { include: { property: true } } } } },
    });

    if (!assignment) throw new BadRequestException('Tenant has no active assignment');

    const property = assignment.bed?.room?.property;
    if (!property) throw new BadRequestException('Related property not found');

    // Use assignment-level rent (tenant-specific override)
    const baseRent = Number(assignment.monthlyRent);
    const totalAmount = baseRent + utilityCharges + foodCharges + lateFee - discount;

    return this.create({
      tenantId,
      organizationId: property.organizationId,
      month,
      year,
      baseRent,
      utilityCharges,
      foodCharges,
      lateFee,
      discount,
      totalAmount,
      dueDate: dueDate ? new Date(dueDate) : new Date(new Date().getFullYear(), new Date().getMonth() + 1, 5),
    } as any);
  }

  // Generate invoices for ALL active tenants in an org for a given month
  async generateBulkForOrg(organizationId: string, month: number, year: number) {
    const tenants = await this.prisma.tenant.findMany({
      where: { organizationId, isActive: true },
      select: { id: true },
    });

    const results = await Promise.allSettled(
      tenants.map((t) => this.generateForTenant({ tenantId: t.id, month, year })),
    );

    const succeeded = results.filter((r) => r.status === 'fulfilled').length;
    const skipped = results.filter(
      (r) => r.status === 'rejected' && (r as PromiseRejectedResult).reason?.message?.includes('already exists'),
    ).length;
    const failed = results.length - succeeded - skipped;

    return { total: tenants.length, succeeded, skipped, failed };
  }

  async findAll(
    params: {
      organizationId?: string;
      tenantId?: string;
      status?: InvoiceStatus;
      search?: string;
      month?: number;
      year?: number;
      page?: number;
      limit?: number;
    } = {},
  ) {
    const { organizationId, tenantId, status, search, month, year, page = 1, limit = 20 } = params;
    const skip = (page - 1) * limit;

    const where: any = {
      ...(organizationId && { organizationId }),
      ...(tenantId && { tenantId }),
      ...(status && { status }),
      ...(month && { month }),
      ...(year && { year }),
      ...(search && {
        tenant: {
          OR: [
            { name: { contains: search, mode: 'insensitive' } },
            { email: { contains: search, mode: 'insensitive' } },
            { phone: { contains: search, mode: 'insensitive' } },
          ],
        },
      }),
    };

    const [data, total] = await Promise.all([
      this.prisma.invoice.findMany({
        where,
        include: this.invoiceInclude,
        orderBy: { createdAt: 'desc' },
        skip,
        take: limit,
      }),
      this.prisma.invoice.count({ where }),
    ]);

    return {
      data,
      total,
      page,
      limit,
      hasMore: skip + data.length < total,
    };
  }

  async findOne(id: string) {
    return this.prisma.invoice.findUnique({
      where: { id },
      include: this.invoiceInclude,
    });
  }

  async update(id: string, updateInvoiceDto: UpdateInvoiceDto) {
    return this.prisma.invoice.update({
      where: { id },
      data: updateInvoiceDto,
    });
  }

  async remove(id: string) {
    return this.prisma.invoice.delete({ where: { id } });
  }

  // Analytics: revenue summary for an org
  async getOrgRevenueSummary(organizationId: string) {
    const currentMonth = new Date().getMonth() + 1;
    const currentYear = new Date().getFullYear();

    const [paid, pending, overdue] = await Promise.all([
      this.prisma.invoice.aggregate({
        where: { organizationId, status: 'PAID', month: currentMonth, year: currentYear },
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
    ]);

    return {
      monthlyRevenue: paid._sum.totalAmount ?? 0,
      paidCount: paid._count,
      pendingAmount: pending._sum.totalAmount ?? 0,
      pendingCount: pending._count,
      overdueAmount: overdue._sum.totalAmount ?? 0,
      overdueCount: overdue._count,
    };
  }

  /**
   * Generate a neat PDF for the invoice and upload to storage. Returns public URL.
   */
  async generateInvoicePdf(invoiceId: string) {
    const invoice = await this.prisma.invoice.findUnique({
      where: { id: invoiceId },
      include: { tenant: { include: { organization: true } } },
    });

    if (!invoice) throw new NotFoundException('Invoice not found');

    // lazy-require to avoid startup dependency issues
    // pdfkit is lightweight and works without headless browser
    // eslint-disable-next-line @typescript-eslint/no-var-requires
    const PDFDocument = require('pdfkit');

    const doc = new PDFDocument({ size: 'A4', margin: 40 });
    const chunks: Buffer[] = [];
    doc.on('data', (c: Buffer) => chunks.push(c));

    const endPromise = new Promise<Buffer>((resolve) => doc.on('end', () => resolve(Buffer.concat(chunks))));

    const org = invoice.tenant?.organization;
    // Header
    if (org?.logoUrl) {
      try {
        // fetch logo if available — node global fetch should exist on modern Node
        // ignore failures
        // eslint-disable-next-line no-undef
        const resp = await fetch(org.logoUrl);
        if (resp && resp.ok) {
          const arr = await resp.arrayBuffer();
          const imgBuf = Buffer.from(arr);
          doc.image(imgBuf, 40, 40, { width: 90 });
        }
      } catch (e) {
        // ignore
      }
    }

    doc.fontSize(18).text(org?.name ?? 'Invoice', 0, 50, { align: 'right' });
    doc.moveDown();

    // Tenant & Invoice meta
    doc.fontSize(10);
    doc.text(`Invoice ID: ${invoice.id}`, { continued: true }).text(``, { align: 'right' });
    doc.text(`Tenant: ${invoice.tenant?.name ?? ''}`);
    doc.text(`Month: ${invoice.month}/${invoice.year}`);
    doc.text(`Due Date: ${invoice.dueDate?.toDateString() ?? ''}`);
    doc.moveDown();

    // Table-like presentation
    const items = [
      { label: 'Base Rent', amount: Number(invoice.baseRent || 0) },
      { label: 'Utility Charges', amount: Number(invoice.utilityCharges || 0) },
      { label: 'Food Charges', amount: Number(invoice.foodCharges || 0) },
      { label: 'Late Fee', amount: Number(invoice.lateFee || 0) },
      { label: 'Discount', amount: -Math.abs(Number(invoice.discount || 0)) },
    ];

    const startX = 40;
    let y = doc.y;
    doc.fontSize(11).text('Description', startX, y);
    doc.text('Amount (INR)', 420, y, { width: 100, align: 'right' });
    y += 20;
    doc.moveTo(startX, y - 5).lineTo(555, y - 5).stroke();

    for (const it of items) {
      doc.fontSize(11).text(it.label, startX, y);
      doc.text(it.amount.toLocaleString('en-IN', { maximumFractionDigits: 2 }), 420, y, { width: 100, align: 'right' });
      y += 18;
    }

    doc.moveTo(startX, y - 5).lineTo(555, y - 5).stroke();
    y += 10;

    doc.fontSize(12).text('Total', startX, y);
    doc.font('Helvetica-Bold').text(Number(invoice.totalAmount || 0).toLocaleString('en-IN', { maximumFractionDigits: 2 }), 420, y, {
      width: 100,
      align: 'right',
    });
    doc.font('Helvetica');

    doc.moveDown(2);
    doc.fontSize(10).text('Notes:', { underline: true });
    const notes = (invoice as any).notes;
    if (notes) {
      doc.text(notes as string);
    } else {
      doc.text('Please pay by the due date to avoid late fees.');
    }

    doc.moveDown(2);
    doc.fontSize(9).text(`Generated: ${new Date().toLocaleString()}`);

    doc.end();

    const pdfBuffer = await endPromise;

    // Upload to storage
    const objectPath = `invoices/${invoice.id}.pdf`;
    const uploadResp = await this.storageService.uploadFileBuffer('documents', objectPath, pdfBuffer, 'application/pdf', `invoice_${invoice.id}.pdf`);

    // Persist pdfUrl on invoice record
    await this.prisma.invoice.update({ where: { id: invoice.id }, data: { pdfUrl: uploadResp.publicUrl } });

    return uploadResp.publicUrl;
  }

}
