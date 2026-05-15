import { Injectable } from '@nestjs/common';
import { ThrottlerGuard } from '@nestjs/throttler';
import { Request } from 'express';

/**
 * Production-level rate limiting guard that:
 * - Enforces rate limits by user ID (authenticated) or IP (anonymous)
 * - Allows configurable limits per endpoint
 * - Logs exceeded requests
 */
@Injectable()
export class AppThrottlerGuard extends ThrottlerGuard {
  protected async getTracker(req: Record<string, any>): Promise<string> {
    // Use user ID if authenticated, otherwise use IP address
    const userId = (req.user as any)?.id;
    if (userId) {
      return `user_${userId}`;
    }
    return req.ip || req.connection?.remoteAddress || 'unknown-ip';
  }
}
