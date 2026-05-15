import { Injectable, NotFoundException, ForbiddenException } from '@nestjs/common';
import { CreatePropertyDto } from './dto/create-property.dto';
import { UpdatePropertyDto } from './dto/update-property.dto';
import { PrismaService } from '../prisma/prisma.service';

@Injectable()
export class PropertiesService {
  constructor(private readonly prisma: PrismaService) {}

  async create(createPropertyDto: CreatePropertyDto) {
    return this.prisma.property.create({
      data: createPropertyDto,
    });
  }

  async findAll(userId: string, params: {
    organizationId?: string;
    search?: string;
    status?: string;
    page?: number;
    limit?: number;
  }) {
    if (!userId) throw new ForbiddenException('Unauthorized');

    const { organizationId, search, status, page = 1, limit = 20 } = params;
    const skip = (page - 1) * limit;

    const accessWhere = {
      OR: [
        { ownerId: userId },
        { members: { some: { profileId: userId } } },
      ],
    };

    // Resolve org IDs the user can access
    let orgIds: string[];
    if (organizationId) {
      const org = await this.prisma.organization.findFirst({
        where: { id: organizationId, ...accessWhere },
        select: { id: true },
      });
      if (!org) throw new ForbiddenException('Access denied');
      orgIds = [organizationId];
    } else {
      const orgs = await this.prisma.organization.findMany({
        where: accessWhere,
        select: { id: true },
      });
      orgIds = orgs.map((o) => o.id);
      if (orgIds.length === 0) return { data: [], total: 0, page, limit, hasMore: false };
    }

    // Build where clause
    const where: any = { organizationId: { in: orgIds } };

    if (status === 'active') where.isActive = true;
    else if (status === 'inactive') where.isActive = false;

    if (search?.trim()) {
      where.OR = [
        { name: { contains: search.trim(), mode: 'insensitive' } },
        { city: { contains: search.trim(), mode: 'insensitive' } },
        { state: { contains: search.trim(), mode: 'insensitive' } },
        { address: { contains: search.trim(), mode: 'insensitive' } },
      ];
    }

    const [data, total] = await Promise.all([
      this.prisma.property.findMany({
        where,
        include: { rooms: { include: { beds: true } } },
        orderBy: { createdAt: 'desc' },
        skip,
        take: limit,
      }),
      this.prisma.property.count({ where }),
    ]);

    return { data, total, page, limit, hasMore: skip + data.length < total };
  }

  async findOne(id: string) {
    const property = await this.prisma.property.findUnique({
      where: { id },
      include: { rooms: { include: { beds: true } } },
    });
    if (!property) throw new NotFoundException(`Property ${id} not found`);
    return property;
  }

  async update(id: string, updatePropertyDto: UpdatePropertyDto) {
    const { organizationId: _organizationId, ...data } = updatePropertyDto as Record<string, unknown>;
    return this.prisma.property.update({
      where: { id },
      data,
    });
  }

  async remove(id: string) {
    return this.prisma.property.delete({
      where: { id },
    });
  }
}
