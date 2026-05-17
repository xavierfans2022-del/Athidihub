import { Injectable, ForbiddenException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { CreateTenantDto } from './dto/create-tenant.dto';
import { UpdateTenantDto } from './dto/update-tenant.dto';
import { v4 as uuidv4 } from 'uuid';

@Injectable()
export class TenantsService {
  constructor(private readonly prisma: PrismaService) {}

  async create(createTenantDto: CreateTenantDto) {
    const joiningDate = new Date(createTenantDto.joiningDate);

    if (Number.isNaN(joiningDate.getTime())) {
      throw new Error(`Invalid joiningDate: ${createTenantDto.joiningDate}`);
    }

    let profile = await this.prisma.profile.findUnique({
      where: { phone: createTenantDto.phone },
    });

    if (!profile) {
      profile = await this.prisma.profile.create({
        data: {
          id: uuidv4(),
          phone: createTenantDto.phone,
          fullName: createTenantDto.name,
        },
      });
    }

    const existingTenant = await this.prisma.tenant.findUnique({
      where: { profileId: profile.id },
      include: { profile: true },
    });

    if (existingTenant) {
      return existingTenant;
    }

    return this.prisma.tenant.create({
      data: {
        ...createTenantDto,
        joiningDate,
        profileId: profile.id,
      },
      include: { profile: true },
    });
  }

  async findAll(params: {
    organizationId?: string;
    userId?: string;
    search?: string;
    status?: string;
    page?: number;
    limit?: number;
  }) {
    const { organizationId, userId, search, status, page = 1, limit = 20 } = params;
    const skip = (page - 1) * limit;

    // Build where clause
    const where: any = {};

    // Status filter
    if (status === 'active') where.isActive = true;
    else if (status === 'inactive') where.isActive = false;
    else where.isActive = true; // default: active only

    // Search filter (name, phone, email)
    if (search?.trim()) {
      where.OR = [
        { name: { contains: search.trim(), mode: 'insensitive' } },
        { phone: { contains: search.trim() } },
        { email: { contains: search.trim(), mode: 'insensitive' } },
      ];
    }

    // Scope by organization
    if (organizationId) {
      if (userId) {
        const org = await this.prisma.organization.findUnique({ where: { id: organizationId }, include: { members: true } });
        if (!org) throw new ForbiddenException('Organization not found');
        const isMember = org.ownerId === userId || org.members.some((m) => m.profileId === userId);
        if (!isMember) throw new ForbiddenException('Access denied');
      }
      where.organizationId = organizationId;
    } else if (userId) {
      const orgs = await this.prisma.organization.findMany({
        where: { OR: [{ ownerId: userId }, { members: { some: { profileId: userId } } }] },
        select: { id: true },
      });
      const orgIds = orgs.map((o) => o.id);
      if (orgIds.length === 0) return { data: [], total: 0, page, limit, hasMore: false };
      where.organizationId = { in: orgIds };
    }

    const [data, total] = await Promise.all([
      this.prisma.tenant.findMany({
        where,
        include: { profile: true, assignments: { include: { bed: { include: { room: true } } } } },
        orderBy: { createdAt: 'desc' },
        skip,
        take: limit,
      }),
      this.prisma.tenant.count({ where }),
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
    const tenant = await this.prisma.tenant.findUnique({
      where: { id },
      include: {
        profile: true,
        assignments: { include: { bed: { include: { room: true } } } },
      },
    });

    if (!tenant) {
      return null;
    }

    const invoices = await this.prisma.invoice.findMany({
      where: { tenantId: id },
      orderBy: { createdAt: 'desc' },
      take: 5,
      include: { payment: true },
    });

    return {
      ...tenant,
      invoices,
    };
  }

  async update(id: string, updateTenantDto: UpdateTenantDto) {
    return this.prisma.tenant.update({
      where: { id },
      data: updateTenantDto,
    });
  }

  async remove(id: string) {
    // Soft delete
    return this.prisma.tenant.update({
      where: { id },
      data: { isActive: false },
    });
  }
}
