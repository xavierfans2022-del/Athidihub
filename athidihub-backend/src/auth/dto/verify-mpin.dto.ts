import { IsString, Matches } from 'class-validator';

export class VerifyMpinDto {
  @IsString()
  @Matches(/^\d{4,6}$/)
  pin: string;
}