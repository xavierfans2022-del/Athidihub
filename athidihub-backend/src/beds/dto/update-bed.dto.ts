import { IsString, IsOptional, IsEnum } from 'class-validator';
import { BedType, BedStatus } from '@prisma/client';

export class UpdateBedDto {
  @IsString()
  @IsOptional()
  bedNumber?: string;

  @IsEnum(BedType)
  @IsOptional()
  bedType?: BedType;

  @IsEnum(BedStatus)
  @IsOptional()
  status?: BedStatus;
}
