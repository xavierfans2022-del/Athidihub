-- AlterTable
ALTER TABLE "Assignment" ADD COLUMN     "monthlyRent" DECIMAL(65,30) NOT NULL DEFAULT 0,
ADD COLUMN     "securityDeposit" DECIMAL(65,30) NOT NULL DEFAULT 0;
