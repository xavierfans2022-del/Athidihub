import { BadRequestException, HttpException, HttpStatus, Injectable, Logger, UnauthorizedException } from '@nestjs/common';
import { Prisma, Profile } from '@prisma/client';
import { pbkdf2Sync, randomBytes, timingSafeEqual } from 'crypto';
import { PrismaService } from '../prisma/prisma.service';

export type SupabaseJwtPayload = {
  sub?: string;
  phone?: string | null;
  aud?: string;
  exp?: number;
  user_metadata?: {
    name?: string | null;
    full_name?: string | null;
    phone?: string | null;
    role?: string | null;
  };
  app_metadata?: {
    provider?: string | null;
    role?: string | null;
    phone?: string | null;
  };
};

export type MpinProfileUpsert = {
  pin: string;
  fullName?: string;
  role?: 'OWNER' | 'TENANT';
};

@Injectable()
export class AuthService {
  private readonly logger = new Logger(AuthService.name);
  private readonly pinIterations = 120000;
  private readonly pinKeyLength = 64;
  private readonly maxFailedAttempts = 5;
  private readonly lockMinutes = 15;

  constructor(private readonly prisma: PrismaService) {}

  private normalizePhone(value?: string | null): string | null {
    if (!value) return null;
    const digits = value.replace(/\D+/g, '');
    return digits.length > 0 ? digits : null;
  }

  private normalizeRole(value?: string | null): 'OWNER' | 'TENANT' {
    return value?.trim().toUpperCase() === 'TENANT' ? 'TENANT' : 'OWNER';
  }

  private normalizeMpin(pin: string): string {
    const digits = pin.replace(/\D+/g, '');
    if (!/^\d{4,6}$/.test(digits)) {
      throw new BadRequestException('MPIN must be 4 to 6 digits');
    }
    return digits;
  }

  private hashMpin(pin: string): string {
    const salt = randomBytes(16).toString('hex');
    const derived = pbkdf2Sync(pin, salt, this.pinIterations, this.pinKeyLength, 'sha512').toString('hex');
    return `pbkdf2$sha512$${this.pinIterations}$${salt}$${derived}`;
  }

  private verifyMpinHash(pin: string, storedHash: string): boolean {
    const [scheme, algorithm, iterationsValue, salt, expected] = storedHash.split('$');
    if (scheme !== 'pbkdf2' || algorithm !== 'sha512' || !iterationsValue || !salt || !expected) {
      return false;
    }

    const iterations = Number(iterationsValue);
    if (!Number.isFinite(iterations) || iterations <= 0) {
      return false;
    }

    const actual = pbkdf2Sync(pin, salt, iterations, expected.length / 2, 'sha512').toString('hex');
    const actualBuffer = Buffer.from(actual, 'hex');
    const expectedBuffer = Buffer.from(expected, 'hex');
    if (actualBuffer.length !== expectedBuffer.length) {
      return false;
    }
    return timingSafeEqual(actualBuffer, expectedBuffer);
  }

  async syncProfileFromJwt(payload: SupabaseJwtPayload): Promise<Profile> {
    const userId = payload.sub;
    if (!userId) {
      throw new UnauthorizedException('Authentication failed');
    }

    const tenantRecord = await this.prisma.tenant.findUnique({ where: { profileId: userId } });
    const phone = this.normalizePhone(payload.phone ?? payload.user_metadata?.phone ?? payload.app_metadata?.phone ?? null);
    const fullName = payload.user_metadata?.full_name ?? payload.user_metadata?.name ?? null;
    const role = tenantRecord ? 'TENANT' : this.normalizeRole(payload.user_metadata?.role ?? payload.app_metadata?.role);

    let profile = await this.prisma.profile.findUnique({ where: { id: userId } });

    if (!profile) {
      this.logger.debug(`Creating profile for userId=${userId} role=${role}`);
      profile = await this.prisma.profile.create({
        data: {
          id: userId,
          phone,
          fullName,
          role: role as any,
        },
      });
      return profile;
    }

    const updates: Prisma.ProfileUpdateInput = {};
    if (phone && phone !== profile.phone) updates.phone = phone;
    if (fullName && fullName !== profile.fullName) updates.fullName = fullName;
    if ((profile as any).role !== role) updates.role = role as any;

    if (Object.keys(updates).length > 0) {
      profile = await this.prisma.profile.update({ where: { id: userId }, data: updates });
    }

    if ((profile as any).role === 'OWNER') {
      const tenantRecordForProfile = await this.prisma.tenant.findUnique({ where: { profileId: userId } });
      if (tenantRecordForProfile) {
        profile = await this.prisma.profile.update({
          where: { id: userId },
          data: { role: 'TENANT' as any },
        });
      }
    }

    return profile;
  }

  async setupMpin(userId: string, payload: MpinProfileUpsert): Promise<Profile> {
    const profile = await this.prisma.profile.findUnique({ where: { id: userId } });
    if (!profile) {
      throw new UnauthorizedException('Authentication failed');
    }

    const normalizedPin = this.normalizeMpin(payload.pin);
    const hashedPin = this.hashMpin(normalizedPin);

    return this.prisma.profile.update({
      where: { id: userId },
      data: {
        fullName: payload.fullName?.trim() || profile.fullName,
        role: payload.role ? (payload.role as any) : profile.role,
        mpinHash: hashedPin,
        mpinUpdatedAt: new Date(),
        mpinFailedAttempts: 0,
        mpinLockedUntil: null,
      },
    });
  }

  async verifyMpin(userId: string, pin: string): Promise<Profile> {
    const profile = await this.prisma.profile.findUnique({ where: { id: userId } });
    if (!profile) {
      throw new UnauthorizedException('Authentication failed');
    }

    if (!profile.mpinHash) {
      throw new BadRequestException('MPIN is not configured');
    }

    if (profile.mpinLockedUntil && profile.mpinLockedUntil.getTime() > Date.now()) {
      throw new HttpException('MPIN is temporarily locked. Try again later.', HttpStatus.TOO_MANY_REQUESTS);
    }

    const normalizedPin = this.normalizeMpin(pin);
    if (!this.verifyMpinHash(normalizedPin, profile.mpinHash)) {
      const failedAttempts = (profile.mpinFailedAttempts ?? 0) + 1;
      const lockedUntil = failedAttempts >= this.maxFailedAttempts
        ? new Date(Date.now() + this.lockMinutes * 60 * 1000)
        : null;

      await this.prisma.profile.update({
        where: { id: userId },
        data: {
          mpinFailedAttempts: lockedUntil ? 0 : failedAttempts,
          mpinLockedUntil: lockedUntil,
        },
      });

      throw new UnauthorizedException('Invalid MPIN');
    }

    return this.prisma.profile.update({
      where: { id: userId },
      data: {
        mpinFailedAttempts: 0,
        mpinLockedUntil: null,
      },
    });
  }
}