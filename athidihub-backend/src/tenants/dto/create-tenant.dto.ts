import { IsString, IsNotEmpty, IsOptional, IsBoolean, IsDateString, IsNumber } from 'class-validator';

export class CreateTenantDto {
  @IsString()
  @IsNotEmpty()
  organizationId: string;

  @IsString()
  @IsNotEmpty()
  name: string;

  @IsString()
  @IsNotEmpty()
  phone: string;

  @IsString()
  @IsNotEmpty()
  email: string;

  @IsString()
  @IsOptional()
  aadhaarUrl?: string;

  @IsString()
  @IsNotEmpty()
  emergencyContact: string;

  @IsDateString()
  joiningDate: string;


  @IsString()
  @IsOptional()
  agreementUrl?: string;
}
