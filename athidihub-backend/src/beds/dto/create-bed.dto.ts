import { IsString, IsNotEmpty, IsEnum, IsOptional } from 'class-validator';
import { BedType, BedStatus } from '@prisma/client';

export class CreateBedDto {
  @IsString()
  @IsNotEmpty()
  roomId: string;

  @IsString()
  @IsNotEmpty()
  bedNumber: string;

  @IsEnum(BedType)
  @IsOptional()
  bedType?: BedType;

  @IsEnum(BedStatus)
  @IsOptional()
  status?: BedStatus;
}
