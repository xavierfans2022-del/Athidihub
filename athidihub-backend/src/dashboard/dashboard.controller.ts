import { Controller, Get, Post, Body, Patch, Param, UseGuards, ForbiddenException } from '@nestjs/common';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { DashboardService } from './dashboard.service';
import { PrismaService } from '../prisma/prisma.service';
import { CurrentUser } from '../auth/current-user.decorator';
import type { Profile } from '@prisma/client';

@UseGuards(JwtAuthGuard)
@Controller('dashboard')
export class DashboardController {
  constructor(private readonly dashboardService: DashboardService, private readonly prisma: PrismaService) {}

  @Get('summary/:orgId')
  async getSummary(@Param('orgId') orgId: string, @CurrentUser() user?: Profile) {
    const org = await this.prisma.organization.findUnique({ where: { id: orgId }, include: { members: true } });
    if (!org) throw new ForbiddenException('Organization not found');
    const isMember = user && (org.ownerId === user.id || org.members.some((m) => m.profileId === user.id));
    if (!isMember) throw new ForbiddenException('Access denied');

    return this.dashboardService.getSummary(orgId);
  }

  @Get('user/profile')
  async getUserProfile(@CurrentUser() user: Profile) {
    return this.dashboardService.getUserProfileWithNavigation(user.id);
  }

  @Get('user/navigation')
  async getNavigation(@CurrentUser() user: Profile) {
    return this.dashboardService.getNavigationData(user.id);
  }

  @Get('user/onboarding')
  async getOnboarding(@CurrentUser() user: Profile) {
    return this.dashboardService.getOnboardingProgress(user.id);
  }

  @Post('user/onboarding/step')
  async updateOnboardingStep(
    @CurrentUser() user: Profile,
    @Body() body: { step: number; organizationId?: string; propertyId?: string; roomId?: string },
  ) {
    return this.dashboardService.updateOnboardingStep(user.id, body);
  }

  @Patch('user/onboarding/complete')
  async completeOnboarding(@CurrentUser() user: Profile) {
    return this.dashboardService.completeOnboarding(user.id);
  }
}
