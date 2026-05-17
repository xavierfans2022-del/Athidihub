import { CanActivate, ExecutionContext, Injectable, Logger, UnauthorizedException } from '@nestjs/common';
import { createRemoteJWKSet, jwtVerify } from 'jose';
import { AuthService, SupabaseJwtPayload } from './auth.service';

@Injectable()
export class JwtAuthGuard implements CanActivate {
  private readonly logger = new Logger(JwtAuthGuard.name);

  private jwks: ReturnType<typeof createRemoteJWKSet> | null = null;

  constructor(private readonly authService: AuthService) {}

  private normalizeSupabaseUrl(value: string): string {
    const cleaned = value.trim().replace(/[;"']+$/g, '');
    return cleaned;
  }

  async canActivate(context: ExecutionContext) {
    const request = context.switchToHttp().getRequest();
    const authorization = request.headers?.authorization;
    const token = typeof authorization === 'string' && authorization.startsWith('Bearer ')
      ? authorization.slice(7)
      : null;

    this.logger.debug(`Auth header present=${Boolean(authorization)} tokenPresent=${Boolean(token)} tokenLength=${token?.length ?? 0}`);
    if (token) {
      this.logger.debug(`Auth token snapshot=${token.slice(0, 12)}...${token.slice(-8)}`);
    }

    if (!token) {
      throw new UnauthorizedException('Authentication failed');
    }

    const supabaseUrl = process.env.SUPABASE_URL;
    if (!supabaseUrl) {
      this.logger.error('SUPABASE_URL is not configured for JWT verification');
      throw new UnauthorizedException('Authentication failed');
    }

    const normalizedSupabaseUrl = this.normalizeSupabaseUrl(supabaseUrl);

    try {
      if (!this.jwks) {
        const jwksUrl = new URL('/auth/v1/.well-known/jwks.json', normalizedSupabaseUrl);
        this.jwks = createRemoteJWKSet(jwksUrl);
        this.logger.debug(`Using Supabase JWKS from ${jwksUrl.toString()}`);
      }

      const { payload, protectedHeader } = await jwtVerify(token, this.jwks);
      const claims = payload as SupabaseJwtPayload;
      this.logger.debug(
        `JWT verified alg=${protectedHeader.alg} kid=${protectedHeader.kid ?? 'missing'} sub=${claims.sub ?? 'missing'} phone=${claims.phone ?? 'missing'} exp=${claims.exp ?? 'missing'} aud=${claims.aud ?? 'missing'}`,
      );

      const profile = await this.authService.syncProfileFromJwt(claims);

      request.user = profile;
      this.logger.debug(`JWT guard authenticated userId=${profile.id}`);
      return true;
    } catch (error) {
      this.logger.warn(`JWT verification failed: ${error instanceof Error ? error.message : String(error)}`);
      throw new UnauthorizedException('Authentication failed');
    }
  }
}
