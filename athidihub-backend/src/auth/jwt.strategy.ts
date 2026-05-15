import { ExtractJwt, Strategy } from 'passport-jwt';
import { PassportStrategy } from '@nestjs/passport';
import { Injectable, Logger } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';

@Injectable()
export class JwtStrategy extends PassportStrategy(Strategy) {
  private readonly logger = new Logger(JwtStrategy.name);

  constructor(private prisma: PrismaService) {
    super({
      jwtFromRequest: ExtractJwt.fromAuthHeaderAsBearerToken(),
      ignoreExpiration: false,
      secretOrKey: process.env.SUPABASE_JWT_SECRET || 'your-super-secret-jwt-token-with-at-least-32-characters-long',
    });
  }

  async validate(payload: any) {
    this.logger.debug(
      `JWT payload sub=${payload?.sub ?? 'missing'} email=${payload?.email ?? 'missing'} role=${payload?.user_metadata?.role ?? 'none'}`,
    );

    const userId = payload.sub;

    let profile = await this.prisma.profile.findUnique({ where: { id: userId } });

    if (!profile) {
      // Determine role: check if a Tenant record exists for this user
      const tenantRecord = await this.prisma.tenant.findUnique({ where: { profileId: userId } });
      const role = tenantRecord ? 'TENANT' : (payload.user_metadata?.role?.toUpperCase() === 'TENANT' ? 'TENANT' : 'OWNER');

      this.logger.debug(`Creating profile for userId=${userId} role=${role}`);
      profile = await this.prisma.profile.create({
        data: {
          id: userId,
          email: payload.email || `${userId}@placeholder.com`,
          phone: payload.phone ?? null,
          fullName: payload.user_metadata?.full_name ?? payload.user_metadata?.name ?? null,
          role: role as any,
        },
      });
    } else {
      // Sync email/phone/name if changed in Supabase
      const updates: any = {};
      if (payload.email && payload.email !== profile.email) updates.email = payload.email;
      if (payload.phone && payload.phone !== profile.phone) updates.phone = payload.phone;
      if (Object.keys(updates).length > 0) {
        profile = await this.prisma.profile.update({ where: { id: userId }, data: updates });
      }

      // Fix role: if Tenant record exists but profile says OWNER, correct it
      if ((profile as any).role === 'OWNER') {
        const tenantRecord = await this.prisma.tenant.findUnique({ where: { profileId: userId } });
        if (tenantRecord) {
          profile = await this.prisma.profile.update({
            where: { id: userId },
            data: { role: 'TENANT' as any },
          });
          this.logger.debug(`Corrected role to TENANT for userId=${userId}`);
        }
      }
    }

    return profile;
  }
}
