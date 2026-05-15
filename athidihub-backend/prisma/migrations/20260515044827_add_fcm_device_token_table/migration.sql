-- CreateEnum
CREATE TYPE "FcmPlatform" AS ENUM ('ANDROID', 'IOS', 'WEB');

-- DropIndex
DROP INDEX "KYCVerification_digilockerReferenceId_idx";

-- DropIndex
DROP INDEX "KYCVerification_digilockerSessionId_idx";

-- CreateTable
CREATE TABLE "FcmDeviceToken" (
    "id" TEXT NOT NULL,
    "profileId" TEXT NOT NULL,
    "token" TEXT NOT NULL,
    "platform" "FcmPlatform" NOT NULL,
    "deviceId" TEXT,
    "deviceName" TEXT,
    "appVersion" TEXT,
    "locale" TEXT,
    "timezone" TEXT,
    "isActive" BOOLEAN NOT NULL DEFAULT true,
    "lastSeenAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "FcmDeviceToken_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "FcmDeviceToken_token_key" ON "FcmDeviceToken"("token");

-- CreateIndex
CREATE INDEX "FcmDeviceToken_profileId_isActive_idx" ON "FcmDeviceToken"("profileId", "isActive");

-- AddForeignKey
ALTER TABLE "FcmDeviceToken" ADD CONSTRAINT "FcmDeviceToken_profileId_fkey" FOREIGN KEY ("profileId") REFERENCES "Profile"("id") ON DELETE CASCADE ON UPDATE CASCADE;
