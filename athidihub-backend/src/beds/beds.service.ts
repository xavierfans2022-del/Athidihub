import { Injectable } from '@nestjs/common';
import { CreateBedDto } from './dto/create-bed.dto';
import { UpdateBedDto } from './dto/update-bed.dto';
import { PrismaService } from '../prisma/prisma.service';

@Injectable()
export class BedsService {
  constructor(private readonly prisma: PrismaService) {}

  async create(createBedDto: CreateBedDto) {
    return this.prisma.bed.create({
      data: createBedDto,
    });
  }

  async findAll(roomId?: string) {
    if (roomId) {
      return this.prisma.bed.findMany({
        where: { roomId },
        orderBy: { bedNumber: 'asc' },
        include: {
          assignments: {
            where: { isActive: true },
            orderBy: { startDate: 'desc' },
            take: 1,
            include: { tenant: true },
          },
        },
      });
    }
    return this.prisma.bed.findMany({
      orderBy: [{ roomId: 'asc' }, { bedNumber: 'asc' }],
      include: {
        assignments: {
          where: { isActive: true },
          orderBy: { startDate: 'desc' },
          take: 1,
          include: { tenant: true },
        },
      },
    });
  }

  async findOne(id: string) {
    return this.prisma.bed.findUnique({
      where: { id },
      include: {
        room: true,
        assignments: {
          where: { isActive: true },
          orderBy: { startDate: 'desc' },
          take: 1,
          include: {
            tenant: {
              include: {
                invoices: {
                  orderBy: { createdAt: 'desc' },
                  take: 5,
                  include: { payment: true },
                },
              },
            },
          },
        },
      },
    });
  }

  async update(id: string, updateBedDto: UpdateBedDto) {
    return this.prisma.bed.update({
      where: { id },
      data: updateBedDto,
    });
  }

  async remove(id: string) {
    return this.prisma.bed.delete({
      where: { id },
    });
  }
}
