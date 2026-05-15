import { Injectable } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { CreateMaintenanceDto } from './dto/create-maintenance.dto';
import { UpdateMaintenanceDto } from './dto/update-maintenance.dto';

@Injectable()
export class MaintenanceService {
  constructor(private readonly prisma: PrismaService) {}

  async create(createMaintenanceDto: CreateMaintenanceDto) {
    return this.prisma.maintenanceRequest.create({
      data: {
        tenantId: createMaintenanceDto.tenantId,
        propertyId: createMaintenanceDto.propertyId,
        category: createMaintenanceDto.category,
        description: createMaintenanceDto.description,
        imageUrls: createMaintenanceDto.imageUrls ?? [],
      },
    });
  }

  async findAll(propertyId?: string) {
    return this.prisma.maintenanceRequest.findMany({
      where: propertyId ? { propertyId } : {},
      orderBy: { createdAt: 'desc' },
    });
  }

  async findOne(id: string) {
    return this.prisma.maintenanceRequest.findUnique({ where: { id } });
  }

  async update(id: string, updateMaintenanceDto: UpdateMaintenanceDto) {
    const data: any = { ...updateMaintenanceDto };
    if (updateMaintenanceDto.status === 'COMPLETED') {
      data.resolvedAt = new Date();
    }
    return this.prisma.maintenanceRequest.update({
      where: { id },
      data,
    });
  }

  async remove(id: string) {
    return this.prisma.maintenanceRequest.delete({ where: { id } });
  }
}
