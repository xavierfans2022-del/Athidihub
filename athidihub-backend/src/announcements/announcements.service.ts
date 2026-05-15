import { Injectable } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { CreateAnnouncementDto } from './dto/create-announcement.dto';
import { UpdateAnnouncementDto } from './dto/update-announcement.dto';

@Injectable()
export class AnnouncementsService {
  constructor(private readonly prisma: PrismaService) {}

  async create(createAnnouncementDto: CreateAnnouncementDto) {
    return this.prisma.announcement.create({
      data: {
        organizationId: createAnnouncementDto.organizationId,
        title: createAnnouncementDto.title,
        body: createAnnouncementDto.body,
        channels: createAnnouncementDto.channels ?? ['push'],
      },
    });
  }

  async findAll(organizationId?: string) {
    return this.prisma.announcement.findMany({
      where: organizationId ? { organizationId } : {},
      orderBy: { createdAt: 'desc' },
    });
  }

  async findOne(id: string) {
    return this.prisma.announcement.findUnique({ where: { id } });
  }

  async update(id: string, updateAnnouncementDto: UpdateAnnouncementDto) {
    return this.prisma.announcement.update({
      where: { id },
      data: updateAnnouncementDto,
    });
  }

  async remove(id: string) {
    return this.prisma.announcement.delete({ where: { id } });
  }
}
