-- CreateEnum
CREATE TYPE "UserRole" AS ENUM ('OWNER', 'TENANT');

-- CreateEnum
CREATE TYPE "OnboardingStatus" AS ENUM ('NOT_STARTED', 'IN_PROGRESS', 'COMPLETED');

-- AlterTable
ALTER TABLE "Profile" ADD COLUMN     "role" "UserRole" NOT NULL DEFAULT 'OWNER';

-- AlterTable
ALTER TABLE "Tenant" ADD COLUMN     "hasAssignment" BOOLEAN NOT NULL DEFAULT false;

-- CreateTable
CREATE TABLE "OnboardingProgress" (
    "id" TEXT NOT NULL,
    "profileId" TEXT NOT NULL,
    "currentStep" INTEGER NOT NULL DEFAULT 0,
    "onboardingStatus" "OnboardingStatus" NOT NULL DEFAULT 'NOT_STARTED',
    "organizationCreated" BOOLEAN NOT NULL DEFAULT false,
    "propertyCreated" BOOLEAN NOT NULL DEFAULT false,
    "roomCreated" BOOLEAN NOT NULL DEFAULT false,
    "bedCreated" BOOLEAN NOT NULL DEFAULT false,
    "organizationId" TEXT,
    "propertyId" TEXT,
    "roomId" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,
    "completedAt" TIMESTAMP(3),

    CONSTRAINT "OnboardingProgress_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "OnboardingProgress_profileId_key" ON "OnboardingProgress"("profileId");

-- CreateIndex
CREATE INDEX "OnboardingProgress_profileId_onboardingStatus_idx" ON "OnboardingProgress"("profileId", "onboardingStatus");

-- AddForeignKey
ALTER TABLE "OnboardingProgress" ADD CONSTRAINT "OnboardingProgress_profileId_fkey" FOREIGN KEY ("profileId") REFERENCES "Profile"("id") ON DELETE CASCADE ON UPDATE CASCADE;
