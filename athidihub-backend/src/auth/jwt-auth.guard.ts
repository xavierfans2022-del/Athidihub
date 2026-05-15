import { CanActivate, ExecutionContext, Injectable, Logger, UnauthorizedException } from '@nestjs/common';
import { Prisma } from '@prisma/client';
import { createRemoteJWKSet, jwtVerify } from 'jose';
import { PrismaService } from '../prisma/prisma.service';

type SupabaseJwtPayload = {
  sub?: string;
  email?: string;
  phone?: string | null;
  aud?: string;
  exp?: number;
  user_metadata?: {
    name?: string | null;
  };
};

@Injectable()
export class JwtAuthGuard implements CanActivate {
  private readonly logger = new Logger(JwtAuthGuard.name);

  private jwks: ReturnType<typeof createRemoteJWKSet> | null = null;

  constructor(private readonly prisma: PrismaService) {}

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
        `JWT verified alg=${protectedHeader.alg} kid=${protectedHeader.kid ?? 'missing'} sub=${claims.sub ?? 'missing'} email=${claims.email ?? 'missing'} exp=${claims.exp ?? 'missing'} aud=${claims.aud ?? 'missing'}`,
      );

      const userId = claims.sub;
      if (!userId) {
        throw new UnauthorizedException('Authentication failed');
      }

      // Normalize incoming identifiers for consistent lookups
      const normalizeEmail = (e?: string) => (e ? e.trim().toLowerCase() : undefined);
      const normalizePhone = (p?: string | null) => (p ? p.replace(/\D+/g, '') : undefined);

      const emailNorm = normalizeEmail(claims.email);
      const phoneNorm = normalizePhone(claims.phone ?? undefined);

      let profile = await this.prisma.profile.findUnique({ where: { id: userId } });

      if (!profile && emailNorm) {
        profile = await this.prisma.profile.findUnique({ where: { email: emailNorm } });
        if (profile) {
          this.logger.debug(`Profile found by email for userId=${userId}`);
        }
      }

      if (!profile && phoneNorm) {
        profile = await this.prisma.profile.findUnique({ where: { phone: phoneNorm } });
        if (profile) {
          this.logger.debug(`Profile found by phone for userId=${userId}`);
        }
      }

      // If profile still not found and claims exist, attempt a broader search (handles formatting differences)
      if (!profile && (emailNorm || phoneNorm)) {
        profile = await this.prisma.profile.findFirst({
          where: {
            OR: [
              ...(emailNorm ? [{ email: emailNorm }] : []),
              ...(phoneNorm ? [{ phone: phoneNorm }] : []),
            ],
          },
        });
        if (profile) {
          this.logger.debug(`Profile found by broader lookup for userId=${userId}`);
        }
      }

      if (!profile) {
        this.logger.debug(`Creating profile for userId=${userId}`);
        try {
          profile = await this.prisma.profile.create({
            data: {
              id: userId,
              email: emailNorm || `${userId}@placeholder.com`,
              phone: phoneNorm ?? null,
              fullName: claims.user_metadata?.name ?? null,
            },
          });
        } catch (createError: unknown) {
          // Handle Prisma unique constraint errors (P2002) explicitly to recover gracefully
          if (createError instanceof Prisma.PrismaClientKnownRequestError && createError.code === 'P2002') {
            this.logger.debug(`Prisma unique constraint (P2002) on create for userId=${userId}: ${JSON.stringify(createError.meta)}`);
            // Determine which field(s) caused the conflict and attempt targeted recovery
            const targets: string[] = Array.isArray(createError.meta?.target) ? (createError.meta!.target as string[]) : [];
            let recovered: any = null;
            if (targets.includes('email') && emailNorm) {
              recovered = await this.prisma.profile.findUnique({ where: { email: emailNorm } });
            }
            if (!recovered && targets.includes('phone') && phoneNorm) {
              recovered = await this.prisma.profile.findUnique({ where: { phone: phoneNorm } });
            }
            // As a last resort, try a broader OR search using normalized values
            if (!recovered && (emailNorm || phoneNorm)) {
              recovered = await this.prisma.profile.findFirst({
                where: {
                  OR: [
                    ...(emailNorm ? [{ email: emailNorm }] : []),
                    ...(phoneNorm ? [{ phone: phoneNorm }] : []),
                  ],
                },
              });
            }

            if (recovered) {
              profile = recovered;
              this.logger.debug(`Profile recovered after P2002 conflict for userId=${userId}, using id=${recovered.id}`);
            } else {
              // If still not found, rethrow original error so caller sees the problem
              throw createError;
            }
          }
          // Fallback: preserve original behavior for unknown errors
          throw createError;
        }
      } else {
        this.logger.debug(`Profile found for userId=${userId}`);

        if (profile.id !== userId) {
          this.logger.warn(
            `Existing profile email matches but id differs. Using profile id=${profile.id} for authenticated userId=${userId}`,
          );
        }
      }

      // Ensure profile is available after create/recovery attempts
      if (!profile) {
        this.logger.error(`Profile creation/recovery failed for userId=${userId}`);
        throw new UnauthorizedException('Authentication failed');
      }

      request.user = profile;
      this.logger.debug(`JWT guard authenticated userId=${profile.id}`);
      return true;
    } catch (error) {
      this.logger.warn(`JWT verification failed: ${error instanceof Error ? error.message : String(error)}`);
      throw new UnauthorizedException('Authentication failed');
    }
  }
}
