import { Module } from '@nestjs/common';
import { TenantPortalController } from './tenant-portal.controller';
import { TenantPortalService } from './tenant-portal.service';
import { PrismaModule } from '../prisma/prisma.module';
import { AuthModule } from '../auth/auth.module';

@Module({
  imports: [PrismaModule, AuthModule],
  controllers: [TenantPortalController],
  providers: [TenantPortalService],
  exports: [TenantPortalService],
})
export class TenantPortalModule {}
