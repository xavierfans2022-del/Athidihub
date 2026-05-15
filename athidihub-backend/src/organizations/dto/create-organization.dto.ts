import { IsString, IsOptional, IsNotEmpty } from 'class-validator';

export class CreateOrganizationDto {
  @IsString()
  @IsNotEmpty()
  name!: string;

  @IsString()
  @IsNotEmpty()
  businessType!: string;

  @IsString()
  @IsOptional()
  gstNumber?: string;
  // address/city/state removed — use logoUrl for branding
  @IsString()
  @IsOptional()
  logoUrl?: string;
}
