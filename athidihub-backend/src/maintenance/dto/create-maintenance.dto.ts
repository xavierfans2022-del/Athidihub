import { IsString, IsNotEmpty, IsArray, IsOptional, IsEnum } from 'class-validator';
import { MaintenanceType } from '@prisma/client';

export class CreateMaintenanceDto {
  @IsString()
  @IsNotEmpty()
  tenantId: string;

  @IsString()
  @IsNotEmpty()
  propertyId: string;

  @IsEnum(MaintenanceType)
  category: MaintenanceType;

  @IsString()
  @IsNotEmpty()
  description: string;

  @IsArray()
  @IsString({ each: true })
  @IsOptional()
  imageUrls?: string[];
}
