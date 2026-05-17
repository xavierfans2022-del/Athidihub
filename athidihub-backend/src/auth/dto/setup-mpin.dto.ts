import { IsIn, IsOptional, IsString, MaxLength, Matches } from 'class-validator';

export class SetupMpinDto {
  @IsString()
  @Matches(/^\d{4,6}$/)
  pin: string;

  @IsOptional()
  @IsString()
  @MaxLength(120)
  fullName?: string;

  @IsOptional()
  @IsIn(['OWNER', 'TENANT'])
  role?: 'OWNER' | 'TENANT';
}