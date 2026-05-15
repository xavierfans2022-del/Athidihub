import { IsString, IsNotEmpty, IsInt, IsOptional, IsNumber, IsDateString } from 'class-validator';

export class GenerateInvoiceDto {
  @IsString()
  @IsNotEmpty()
  tenantId: string;

  @IsInt()
  month: number;

  @IsInt()
  year: number;

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

  @IsDateString()
  @IsOptional()
  dueDate?: string;
}
