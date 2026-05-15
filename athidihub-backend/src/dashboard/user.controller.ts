import { Controller, Get, Post, Body, Patch, UseGuards } from '@nestjs/common';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { CurrentUser } from '../auth/current-user.decorator';
import { DashboardService } from './dashboard.service';

@Controller('user')
@UseGuards(JwtAuthGuard)
export class UserController {
  constructor(private readonly dashboardService: DashboardService) {}

  @Get('profile')
  async getProfile(@CurrentUser() user: any) {
    return this.dashboardService.getUserProfileWithNavigation(user.sub);
  }

  @Get('navigation')
  async getNavigation(@CurrentUser() user: any) {
    return this.dashboardService.getNavigationData(user.sub);
  }

  @Get('onboarding')
  async getOnboarding(@CurrentUser() user: any) {
    return this.dashboardService.getOnboardingProgress(user.sub);
  }

  @Post('onboarding/step')
  async updateOnboardingStep(
    @CurrentUser() user: any,
    @Body() body: { step: number; organizationId?: string; propertyId?: string; roomId?: string },
  ) {
    return this.dashboardService.updateOnboardingStep(user.sub, body);
  }

  @Patch('onboarding/complete')
  async completeOnboarding(@CurrentUser() user: any) {
    return this.dashboardService.completeOnboarding(user.sub);
  }
}
