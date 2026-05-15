/*
  Warnings:

  - You are about to drop the column `address` on the `Organization` table. All the data in the column will be lost.
  - You are about to drop the column `city` on the `Organization` table. All the data in the column will be lost.
  - You are about to drop the column `state` on the `Organization` table. All the data in the column will be lost.
  - You are about to drop the column `depositPaid` on the `Tenant` table. All the data in the column will be lost.

*/
-- AlterTable
ALTER TABLE "Organization" DROP COLUMN "address",
DROP COLUMN "city",
DROP COLUMN "state";

-- AlterTable
ALTER TABLE "Tenant" DROP COLUMN "depositPaid";
