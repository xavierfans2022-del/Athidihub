import { Controller, Get, Post, Body, Patch, Param, Delete, UseGuards, Query, ForbiddenException } from '@nestjs/common';
import { InvoicesService } from './invoices.service';
import { CreateInvoiceDto } from './dto/create-invoice.dto';
import { UpdateInvoiceDto } from './dto/update-invoice.dto';
import { GenerateInvoiceDto } from './dto/generate-invoice.dto';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { CurrentUser } from '../auth/current-user.decorator';
import type { Profile } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';
import { InvoiceStatus } from '@prisma/client';

@UseGuards(JwtAuthGuard)
@Controller('invoices')
export class InvoicesController {
  constructor(private readonly invoicesService: InvoicesService, private readonly prisma: PrismaService) {}

  @Post()
  create(@Body() createInvoiceDto: CreateInvoiceDto) {
    return this.invoicesService.create(createInvoiceDto);
  }

  @Post('generate')
  generate(@Body() generateDto: GenerateInvoiceDto) {
    return this.invoicesService.generateForTenant({
      tenantId: generateDto.tenantId,
      month: generateDto.month,
      year: generateDto.year,
      utilityCharges: generateDto.utilityCharges,
      foodCharges: generateDto.foodCharges,
      lateFee: generateDto.lateFee,
      discount: generateDto.discount,
      dueDate: generateDto.dueDate,
    });
  }

  @Post('generate-bulk')
  async generateBulk(@Body() body: { organizationId: string; month: number; year: number }) {
    return this.invoicesService.generateBulkForOrg(body.organizationId, body.month, body.year);
  }

  @Get()
  findAll(
    @Query('organizationId') organizationId?: string,
    @Query('tenantId') tenantId?: string,
    @Query('status') status?: InvoiceStatus,
    @Query('search') search?: string,
    @Query('month') month?: string,
    @Query('year') year?: string,
    @Query('page') page?: string,
    @Query('limit') limit?: string,
  ) {
    return this.invoicesService.findAll({
      organizationId,
      tenantId,
      status,
      search,
      month: month ? parseInt(month) : undefined,
      year: year ? parseInt(year) : undefined,
      page: page ? parseInt(page) : 1,
      limit: limit ? parseInt(limit) : 20,
    });
  }

  @Get('analytics/:orgId')
  async getAnalytics(@Param('orgId') orgId: string, @CurrentUser() user?: Profile) {
    // verify user has access to the organization
    const org = await this.prisma.organization.findUnique({ where: { id: orgId }, include: { members: true } });
    if (!org) throw new ForbiddenException('Organization not found');
    const isMember = user && (org.ownerId === user.id || org.members.some((m) => m.profileId === user.id));
    if (!isMember) throw new ForbiddenException('Access denied');

    return this.invoicesService.getOrgRevenueSummary(orgId);
  }

  @Get(':id')
  findOne(@Param('id') id: string) {
    return this.invoicesService.findOne(id);
  }

  @Get(':id/pdf')
  async getPdf(@Param('id') id: string) {
    return { pdfUrl: await this.invoicesService.generateInvoicePdf(id) };
  }

  @Patch(':id')
  update(@Param('id') id: string, @Body() updateInvoiceDto: UpdateInvoiceDto) {
    return this.invoicesService.update(id, updateInvoiceDto);
  }

  @Delete(':id')
  remove(@Param('id') id: string) {
    return this.invoicesService.remove(id);
  }
}
