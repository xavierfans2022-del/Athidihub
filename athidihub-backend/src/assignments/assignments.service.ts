import { Injectable, BadRequestException } from '@nestjs/common';
import { CreateAssignmentDto } from './dto/create-assignment.dto';
import { UpdateAssignmentDto } from './dto/update-assignment.dto';
import { PrismaService } from '../prisma/prisma.service';

@Injectable()
export class AssignmentsService {
  constructor(private readonly prisma: PrismaService) {}

  async create(createAssignmentDto: CreateAssignmentDto) {
    return this.prisma.$transaction(async (tx) => {
      const startDate = new Date(createAssignmentDto.startDate);
      if (Number.isNaN(startDate.getTime())) {
        throw new BadRequestException(`Invalid startDate: ${createAssignmentDto.startDate}`);
      }

      const endDate = createAssignmentDto.endDate ? new Date(createAssignmentDto.endDate) : undefined;
      if (createAssignmentDto.endDate && Number.isNaN(endDate!.getTime())) {
        throw new BadRequestException(`Invalid endDate: ${createAssignmentDto.endDate}`);
      }

      const bed = await tx.bed.findUnique({
        where: { id: createAssignmentDto.bedId },
        include: { room: true },
      });

      if (!bed) throw new BadRequestException('Bed not found');
      if (bed.status !== 'AVAILABLE') throw new BadRequestException('Selected bed is not available');

      // Use provided overrides or fall back to room defaults
      const monthlyRent = createAssignmentDto.monthlyRent ?? Number(bed.room.monthlyRent);
      const securityDeposit = createAssignmentDto.securityDeposit ?? Number(bed.room.securityDeposit);

      // Close existing active assignment for this tenant
      const existing = await tx.assignment.findFirst({
        where: { tenantId: createAssignmentDto.tenantId, isActive: true },
        include: { bed: true },
      });

      if (existing) {
        await tx.assignment.update({
          where: { id: existing.id },
          data: { isActive: false, endDate: startDate },
        });
        await tx.bed.update({
          where: { id: existing.bed.id },
          data: { status: 'AVAILABLE' },
        });
      }

      const assignment = await tx.assignment.create({
        data: {
          tenantId: createAssignmentDto.tenantId,
          bedId: createAssignmentDto.bedId,
          startDate,
          ...(endDate ? { endDate } : {}),
          monthlyRent,
          securityDeposit,
        },
        include: {
          bed: { include: { room: true } },
          tenant: true,
        },
      });

      await tx.bed.update({
        where: { id: createAssignmentDto.bedId },
        data: { status: 'OCCUPIED' },
      });

      return assignment;
    });
  }

  async findAll() {
    return this.prisma.assignment.findMany({
      include: {
        tenant: true,
        bed: { include: { room: true } },
      },
    });
  }

  async findOne(id: string) {
    return this.prisma.assignment.findUnique({
      where: { id },
      include: {
        tenant: true,
        bed: { include: { room: true } },
      },
    });
  }

  async update(id: string, updateAssignmentDto: UpdateAssignmentDto) {
    return this.prisma.assignment.update({
      where: { id },
      data: updateAssignmentDto,
    });
  }

  async remove(id: string) {
    const assignment = await this.prisma.assignment.delete({ where: { id } });
    await this.prisma.bed.update({
      where: { id: assignment.bedId },
      data: { status: 'AVAILABLE' },
    });
    return assignment;
  }

  // Returns room's default rent/deposit for a given bed — used by frontend to pre-fill
  async getRoomRentForBed(bedId: string) {
    const bed = await this.prisma.bed.findUnique({
      where: { id: bedId },
      include: { room: true },
    });
    if (!bed) throw new BadRequestException('Bed not found');
    return {
      monthlyRent: Number(bed.room.monthlyRent),
      securityDeposit: Number(bed.room.securityDeposit),
      roomNumber: bed.room.roomNumber,
      roomType: bed.room.roomType,
    };
  }
}
