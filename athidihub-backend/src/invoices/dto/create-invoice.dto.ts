import { IsString, IsNotEmpty, IsNumber, IsInt, IsOptional, IsEnum, IsDateString } from 'class-validator';
import { InvoiceStatus } from '@prisma/client';

export class CreateInvoiceDto {
  @IsString()
  @IsNotEmpty()
  tenantId: string;

  @IsString()
  @IsNotEmpty()
  organizationId: string;

  @IsInt()
  month: number;

  @IsInt()
  year: number;

  @IsNumber()
  baseRent: number;

  @IsNumber()
  @IsOptional()
  utilityCharges?: number;

  @IsNumber()
  @IsOptional()
  foodCharges?: number;

  @IsNumber()
  @IsOptional()
  lateFee?: number;

  @IsNumber()
  @IsOptional()
  discount?: number;

  @IsNumber()
  totalAmount: number;

  @IsDateString()
  dueDate: string;

  @IsEnum(InvoiceStatus)
  @IsOptional()
  status?: InvoiceStatus;
}
