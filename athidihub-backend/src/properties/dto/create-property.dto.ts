import { IsString, IsNotEmpty, IsInt, IsArray, IsOptional } from 'class-validator';

export class CreatePropertyDto {
  @IsString()
  @IsNotEmpty()
  organizationId: string;

  @IsString()
  @IsNotEmpty()
  name: string;

  @IsString()
  @IsNotEmpty()
  address: string;

  @IsString()
  @IsNotEmpty()
  city: string;

  @IsString()
  @IsNotEmpty()
  state: string;

  @IsInt()
  totalFloors: number;

  @IsArray()
  @IsString({ each: true })
  @IsOptional()
  amenities?: string[];
}
