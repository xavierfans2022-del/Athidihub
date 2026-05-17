import { ExtractJwt, Strategy } from 'passport-jwt';
import { PassportStrategy } from '@nestjs/passport';
import { Injectable, Logger } from '@nestjs/common';
import { AuthService } from './auth.service';

@Injectable()
export class JwtStrategy extends PassportStrategy(Strategy) {
  private readonly logger = new Logger(JwtStrategy.name);

  constructor(private readonly authService: AuthService) {
    super({
      jwtFromRequest: ExtractJwt.fromAuthHeaderAsBearerToken(),
      ignoreExpiration: false,
      secretOrKey: process.env.SUPABASE_JWT_SECRET || 'your-super-secret-jwt-token-with-at-least-32-characters-long',
    });
  }

  async validate(payload: any) {
    this.logger.debug(
      `JWT payload sub=${payload?.sub ?? 'missing'} phone=${payload?.phone ?? 'missing'} role=${payload?.user_metadata?.role ?? 'none'}`,
    );

    return this.authService.syncProfileFromJwt(payload);
  }
}
