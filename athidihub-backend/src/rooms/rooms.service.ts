import { Injectable } from '@nestjs/common';
import { RoomType } from '@prisma/client';
import { CreateRoomDto } from './dto/create-room.dto';
import { UpdateRoomDto } from './dto/update-room.dto';
import { PrismaService } from '../prisma/prisma.service';

@Injectable()
export class RoomsService {
  constructor(private readonly prisma: PrismaService) {}

  async create(createRoomDto: CreateRoomDto) {
    return this.prisma.room.create({
      data: createRoomDto,
    });
  }

  async findAll(params: {
    propertyId?: string;
    search?: string;
    roomType?: string;
    isAC?: boolean;
    page?: number;
    limit?: number;
  }) {
    const { propertyId, search, roomType, isAC, page = 1, limit = 20 } = params;
    const skip = (page - 1) * limit;

    const where: any = {};

    if (propertyId) where.propertyId = propertyId;
    if (roomType) {
      const parsedRoomType = this.parseRoomType(roomType);
      if (parsedRoomType) where.roomType = parsedRoomType;
    }
    if (isAC !== undefined) where.isAC = isAC;

    if (search?.trim()) {
      const trimmedSearch = search.trim();
      const normalizedSearch = trimmedSearch
        .replace(/[\s-]+/g, '_')
        .toLowerCase();
      const matchingRoomTypes = Object.values(RoomType).filter((type) =>
        type.toLowerCase().includes(normalizedSearch),
      );

      where.OR = [
        { roomNumber: { contains: trimmedSearch, mode: 'insensitive' } },
        ...(matchingRoomTypes.length > 0
          ? [{ roomType: { in: matchingRoomTypes } }]
          : []),
      ];
    }

    const [data, total] = await Promise.all([
      this.prisma.room.findMany({
        where,
        include: { beds: true },
        orderBy: { roomNumber: 'asc' },
        skip,
        take: limit,
      }),
      this.prisma.room.count({ where }),
    ]);

    return { data, total, page, limit, hasMore: skip + data.length < total };
  }

  async findOne(id: string) {
    return this.prisma.room.findUnique({
      where: { id },
      include: { beds: true },
    });
  }

  async update(id: string, updateRoomDto: UpdateRoomDto) {
    return this.prisma.room.update({
      where: { id },
      data: updateRoomDto,
    });
  }

  async remove(id: string) {
    return this.prisma.room.delete({
      where: { id },
    });
  }

  private parseRoomType(value: string): RoomType | undefined {
    const normalized = value.trim().replace(/[\s-]+/g, '_').toUpperCase();
    return Object.values(RoomType).includes(normalized as RoomType)
      ? (normalized as RoomType)
      : undefined;
  }
}
