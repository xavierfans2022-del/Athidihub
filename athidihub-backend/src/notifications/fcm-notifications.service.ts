import { BadRequestException, Injectable, Logger } from '@nestjs/common';
import { FcmPlatform } from '@prisma/client';
import * as admin from 'firebase-admin';
import type { ServiceAccount } from 'firebase-admin';
import { PrismaService } from '../prisma/prisma.service';
import { RegisterFcmTokenDto } from './dto/register-fcm-token.dto';

interface PushPayload {
  title: string;
  body: string;
  data?: Record<string, string | number | boolean | null | undefined>;
}

@Injectable()
export class FcmNotificationsService {
  private readonly logger = new Logger(FcmNotificationsService.name);
  private readonly firebaseReady: boolean;

  constructor(private readonly prisma: PrismaService) {
    this.firebaseReady = this.initializeFirebaseAdmin();
  }

  async registerToken(profileId: string, dto: RegisterFcmTokenDto) {
    const token = dto.token.trim();
    if (!token) {
      throw new BadRequestException('token is required');
    }

    const platform = this.mapPlatform(dto.platform);
    const now = new Date();

    const record = await this.prisma.fcmDeviceToken.upsert({
      where: { token },
      update: {
        profileId,
        platform,
        deviceId: dto.deviceId ?? null,
        deviceName: dto.deviceName ?? null,
        appVersion: dto.appVersion ?? null,
        locale: dto.locale ?? null,
        timezone: dto.timezone ?? null,
        isActive: true,
        lastSeenAt: now,
      },
      create: {
        profileId,
        token,
        platform,
        deviceId: dto.deviceId ?? null,
        deviceName: dto.deviceName ?? null,
        appVersion: dto.appVersion ?? null,
        locale: dto.locale ?? null,
        timezone: dto.timezone ?? null,
        isActive: true,
        lastSeenAt: now,
      },
    });

    this.logger.debug(
      `Registered FCM token profileId=${profileId} platform=${platform} tokenSuffix=${token.slice(-8)}`,
    );

    return record;
  }

  async unregisterToken(profileId: string, token: string) {
    const sanitizedToken = token.trim();
    if (!sanitizedToken) {
      throw new BadRequestException('token is required');
    }

    const result = await this.prisma.fcmDeviceToken.updateMany({
      where: { profileId, token: sanitizedToken },
      data: { isActive: false, lastSeenAt: new Date() },
    });

    return { deactivated: result.count };
  }

  async sendToProfile(profileId: string, payload: PushPayload) {
    const tokens = await this.prisma.fcmDeviceToken.findMany({
      where: {
        profileId,
        isActive: true,
      },
      select: { id: true, token: true },
    });

    if (!tokens.length) {
      this.logger.debug(`No active FCM tokens found for profileId=${profileId}`);
      return { sent: 0, failed: 0, skipped: true };
    }

    if (!this.firebaseReady) {
      this.logger.warn(`Firebase Admin is not configured, skipping push send for profileId=${profileId}`);
      return { sent: 0, failed: tokens.length, skipped: true };
    }

    let sent = 0;
    let failed = 0;

    for (const chunk of this.chunk(tokens, 500)) {
      const response = await admin.messaging().sendEachForMulticast({
        tokens: chunk.map((entry) => entry.token),
        notification: {
          title: payload.title,
          body: payload.body,
        },
        data: this.normalizeData(payload.data),
      });

      sent += response.successCount;
      failed += response.failureCount;

      await this.deactivateInvalidTokens(chunk, response.responses);
    }

    return { sent, failed, skipped: false };
  }

  private initializeFirebaseAdmin(): boolean {
    if (admin.apps.length > 0) {
      return true;
    }

    const serviceAccountJson = process.env.FIREBASE_SERVICE_ACCOUNT_JSON;
    const projectId = process.env.FIREBASE_PROJECT_ID;
    const clientEmail = process.env.FIREBASE_CLIENT_EMAIL;
    const privateKey = process.env.FIREBASE_PRIVATE_KEY?.replace(/\\n/g, '\n');

    try {
      if (serviceAccountJson) {
        const serviceAccount = JSON.parse(serviceAccountJson) as ServiceAccount;
        admin.initializeApp({
          credential: admin.credential.cert(serviceAccount),
          projectId: serviceAccount.projectId ?? projectId,
        });
        this.logger.log('Initialized Firebase Admin from FIREBASE_SERVICE_ACCOUNT_JSON');
        return true;
      }

      if (projectId && clientEmail && privateKey) {
        admin.initializeApp({
          credential: admin.credential.cert({
            projectId,
            clientEmail,
            privateKey,
          } as ServiceAccount),
          projectId,
        });
        this.logger.log('Initialized Firebase Admin from environment credentials');
        return true;
      }

      this.logger.warn('Firebase Admin credentials are not configured. Push notifications will be skipped.');
      return false;
    } catch (error) {
      this.logger.error(
        'Failed to initialize Firebase Admin',
        error instanceof Error ? error.stack : String(error),
      );
      return false;
    }
  }

  private mapPlatform(platform: RegisterFcmTokenDto['platform']): FcmPlatform {
    switch (platform) {
      case 'android':
        return FcmPlatform.ANDROID;
      case 'ios':
        return FcmPlatform.IOS;
      case 'web':
        return FcmPlatform.WEB;
    }
  }

  private normalizeData(data?: PushPayload['data']) {
    if (!data) {
      return undefined;
    }

    return Object.fromEntries(
      Object.entries(data)
        .filter(([, value]) => value !== undefined && value !== null)
        .map(([key, value]) => [key, String(value)]),
    );
  }

  private async deactivateInvalidTokens(
    tokens: Array<{ id: string; token: string }>,
    responses: admin.messaging.BatchResponse['responses'],
  ) {
    const invalidTokens = responses
      .map((response, index) => ({ response, token: tokens[index]?.token }))
      .filter(({ response }) => !response.success)
      .filter(({ response }) => {
        const code = response.error?.code ?? '';
        return code.includes('registration-token-not-registered') || code.includes('invalid-registration-token');
      })
      .map(({ token }) => token)
      .filter((token): token is string => Boolean(token));

    if (!invalidTokens.length) {
      return;
    }

    await this.prisma.fcmDeviceToken.updateMany({
      where: { token: { in: invalidTokens } },
      data: { isActive: false },
    });

    this.logger.warn(`Deactivated ${invalidTokens.length} invalid FCM token(s)`);
  }

  private chunk<T>(items: T[], size: number): T[][] {
    const chunks: T[][] = [];
    for (let index = 0; index < items.length; index += size) {
      chunks.push(items.slice(index, index + size));
    }
    return chunks;
  }
}
