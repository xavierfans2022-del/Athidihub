import { Controller, Get, Post, Body, Patch, Param, Delete, UseGuards, Query, ForbiddenException } from '@nestjs/common';
import { PropertiesService } from './properties.service';
import { CreatePropertyDto } from './dto/create-property.dto';
import { UpdatePropertyDto } from './dto/update-property.dto';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { CurrentUser } from '../auth/current-user.decorator';
import type { Profile } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';

@UseGuards(JwtAuthGuard)
@Controller('properties')
export class PropertiesController {
  constructor(
    private readonly propertiesService: PropertiesService,
    private readonly prisma: PrismaService,
  ) {}

  @Post()
  async create(@Body() createPropertyDto: CreatePropertyDto, @CurrentUser() user?: Profile) {
    const org = await this.prisma.organization.findFirst({
      where: {
        id: createPropertyDto.organizationId,
        OR: [
          { ownerId: user?.id },
          { members: { some: { profileId: user?.id } } },
        ],
      },
      select: { id: true },
    });

    if (!org) {
      throw new ForbiddenException('Access denied');
    }

    return this.propertiesService.create(createPropertyDto);
  }

  @Get()
  findAll(
    @CurrentUser() user: Profile,
    @Query('organizationId') organizationId?: string,
    @Query('search') search?: string,
    @Query('status') status?: string,
    @Query('page') page?: string,
    @Query('limit') limit?: string,
  ) {
    return this.propertiesService.findAll(user.id, {
      organizationId,
      search,
      status,
      page: page ? parseInt(page, 10) : 1,
      limit: limit ? parseInt(limit, 10) : 20,
    });
  }

  @Get(':id')
  findOne(@Param('id') id: string) {
    return this.propertiesService.findOne(id);
  }

  @Patch(':id')
  update(@Param('id') id: string, @Body() updatePropertyDto: UpdatePropertyDto) {
    return this.propertiesService.update(id, updatePropertyDto);
  }

  @Delete(':id')
  remove(@Param('id') id: string) {
    return this.propertiesService.remove(id);
  }
}
