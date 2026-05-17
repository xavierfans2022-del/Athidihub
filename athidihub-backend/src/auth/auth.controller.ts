import { Body, Controller, Post, UseGuards } from '@nestjs/common';
import { AuthService } from './auth.service';
import { CurrentUser } from './current-user.decorator';
import { JwtAuthGuard } from './jwt-auth.guard';
import { SetupMpinDto } from './dto/setup-mpin.dto';
import { VerifyMpinDto } from './dto/verify-mpin.dto';

@Controller('auth')
@UseGuards(JwtAuthGuard)
export class AuthController {
  constructor(private readonly authService: AuthService) {}

  @Post('mpin/setup')
  async setupMpin(@CurrentUser() user: { id: string }, @Body() body: SetupMpinDto) {
    const profile = await this.authService.setupMpin(user.id, body);
    return {
      success: true,
      profile: {
        id: profile.id,
        phone: profile.phone,
        fullName: profile.fullName,
        role: profile.role,
      },
    };
  }

  @Post('mpin/verify')
  async verifyMpin(@CurrentUser() user: { id: string }, @Body() body: VerifyMpinDto) {
    await this.authService.verifyMpin(user.id, body.pin);
    return { success: true };
  }
}