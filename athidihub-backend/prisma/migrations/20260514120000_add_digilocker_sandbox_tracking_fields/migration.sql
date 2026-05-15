-- AlterTable
ALTER TABLE "KYCVerification"
ADD COLUMN     "verificationUrl" TEXT,
ADD COLUMN     "digilockerSessionId" TEXT,
ADD COLUMN     "digilockerReferenceId" TEXT;

-- CreateIndex
CREATE INDEX "KYCVerification_digilockerSessionId_idx" ON "KYCVerification"("digilockerSessionId");

-- CreateIndex
CREATE INDEX "KYCVerification_digilockerReferenceId_idx" ON "KYCVerification"("digilockerReferenceId");
