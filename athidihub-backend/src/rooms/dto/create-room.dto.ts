import { IsString, IsNotEmpty, IsInt, IsBoolean, IsNumber, IsEnum } from 'class-validator';
import { RoomType } from '@prisma/client';

export class CreateRoomDto {
  @IsString()
  @IsNotEmpty()
  propertyId: string;

  @IsInt()
  floorNumber: number;

  @IsString()
  @IsNotEmpty()
  roomNumber: string;

  @IsEnum(RoomType)
  roomType: RoomType;

  @IsBoolean()
  isAC: boolean;

  @IsNumber()
  monthlyRent: number;

  @IsNumber()
  securityDeposit: number;

  @IsInt()
  capacity: number;
}
