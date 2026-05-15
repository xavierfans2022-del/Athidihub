import { Injectable } from '@nestjs/common';
import { CreateOrganizationDto } from './dto/create-organization.dto';
import { UpdateOrganizationDto } from './dto/update-organization.dto';
import { PrismaService } from '../prisma/prisma.service';

@Injectable()
export class OrganizationsService {
  constructor(private readonly prisma: PrismaService) {}

  async create(createOrganizationDto: CreateOrganizationDto, ownerId: string) {
    return this.prisma.organization.create({
      data: {
        ...createOrganizationDto,
        ownerId,
      },
    });
  }

  async findAll(userId?: string) {
    if (!userId) {
      return this.prisma.organization.findMany();
    }

    // Return organizations the user owns or is a member of
    return this.prisma.organization.findMany({
      where: {
        OR: [
          { ownerId: userId },
          { members: { some: { profileId: userId } } },
        ],
      },
      include: { properties: true },
      orderBy: { createdAt: 'desc' },
    });
  }

  async userHasAccess(userId: string, organizationId: string) {
    const org = await this.prisma.organization.findUnique({
      where: { id: organizationId },
      include: { members: true },
    });
    if (!org) return false;
    if (org.ownerId === userId) return true;
    return org.members.some((m) => m.profileId === userId);
  }

  async findOne(id: string) {
    return this.prisma.organization.findUnique({
      where: { id },
      include: { properties: true },
    });
  }

  async update(id: string, updateOrganizationDto: UpdateOrganizationDto) {
    return this.prisma.organization.update({
      where: { id },
      data: updateOrganizationDto,
    });
  }

  async remove(id: string) {
    return this.prisma.organization.delete({
      where: { id },
    });
  }
}
