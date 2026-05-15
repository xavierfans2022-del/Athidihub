import { Controller, Get, Post, Body, Patch, Param, Delete, UseGuards, Query, ForbiddenException, NotFoundException } from '@nestjs/common';
import { TenantsService } from './tenants.service';
import { NotificationsService } from '../notifications/notifications.service';
import { CreateTenantDto } from './dto/create-tenant.dto';
import { UpdateTenantDto } from './dto/update-tenant.dto';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { PrismaService } from '../prisma/prisma.service';
import { CurrentUser } from '../auth/current-user.decorator';
import type { Profile } from '@prisma/client';

@UseGuards(JwtAuthGuard)
@Controller('tenants')
export class TenantsController {
  constructor(private readonly tenantsService: TenantsService, private readonly prisma: PrismaService, private readonly notificationsService: NotificationsService) {}

  @Post()
  async create(@Body() createTenantDto: CreateTenantDto, @CurrentUser() user?: Profile) {
    const org = await this.prisma.organization.findUnique({ where: { id: createTenantDto.organizationId }, include: { members: true } });
    if (!org) throw new ForbiddenException('Organization not found');
    const isMember = user && (org.ownerId === user.id || org.members.some((m) => m.profileId === user.id));
    if (!isMember) throw new ForbiddenException('Access denied');

    const tenant = await this.tenantsService.create(createTenantDto);

    // fire-and-forget: enqueue notification without blocking (async)
    this.notificationsService
      .enqueueWhatsAppNotification({
        organizationId: org.id,
        tenantId: tenant.id,
        type: 'tenant_upload_link',
        data: {
          template: {
            name: 'hello_world',
            language: { code: 'en_US' },
          },
          tenantId: tenant.id,
        },
      })
      .catch((e) => console.warn('Failed to enqueue tenant notification', e));

    return tenant;
  }

  @Get()
  findAll(
    @Query('organizationId') organizationId?: string,
    @Query('search') search?: string,
    @Query('status') status?: string,
    @Query('page') page?: string,
    @Query('limit') limit?: string,
    @CurrentUser() user?: Profile,
  ) {
    return this.tenantsService.findAll({
      organizationId,
      userId: user?.id,
      search,
      status,
      page: page ? parseInt(page, 10) : 1,
      limit: limit ? parseInt(limit, 10) : 20,
    });
  }

  @Get(':id')
  findOne(@Param('id') id: string) {
    return this.tenantsService.findOne(id);
  }

  @Post(':id/test-whatsapp')
  async testWhatsApp(@Param('id') id: string, @CurrentUser() user?: Profile) {
    const tenant = await this.prisma.tenant.findUnique({
      where: { id },
      include: { organization: { include: { members: true } } },
    });

    if (!tenant) {
      throw new NotFoundException('Tenant not found');
    }

    const organization = tenant.organization;
    const isAllowed = user && (organization.ownerId === user.id || organization.members.some((member) => member.profileId === user.id));
    if (!isAllowed) {
      throw new ForbiddenException('Access denied');
    }

    const log = await this.notificationsService.enqueueWhatsAppNotification({
      organizationId: organization.id,
      tenantId: tenant.id,
      type: 'tenant_whatsapp_test',
      data: {
        text: `Test WhatsApp message for ${tenant.name}`,
        tenantId: tenant.id,
        testMode: true,
      },
    });

    return {
      success: true,
      notificationLogId: log.id,
      tenantId: tenant.id,
      tenantName: tenant.name,
    };
  }

  @Patch(':id')
  update(@Param('id') id: string, @Body() updateTenantDto: UpdateTenantDto) {
    return this.tenantsService.update(id, updateTenantDto);
  }

  @Delete(':id')
  remove(@Param('id') id: string) {
    return this.tenantsService.remove(id);
  }
}
