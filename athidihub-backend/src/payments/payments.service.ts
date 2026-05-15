import { Injectable } from '@nestjs/common';
import { CreatePaymentDto } from './dto/create-payment.dto';
import { UpdatePaymentDto } from './dto/update-payment.dto';
import { PrismaService } from '../prisma/prisma.service';
import { BadRequestException } from '@nestjs/common';

@Injectable()
export class PaymentsService {
  constructor(private readonly prisma: PrismaService) {}

  async create(createPaymentDto: CreatePaymentDto) {
    // If a payment already exists for this invoice, update it instead of creating duplicate
    const existing = await this.prisma.payment.findUnique({ where: { invoiceId: createPaymentDto.invoiceId } });
    const data: any = { ...createPaymentDto };
    if (createPaymentDto.status === 'SUCCESS') {
      data.paidAt = new Date();
    }

    if (existing) {
      const updated = await this.prisma.payment.update({ where: { id: existing.id }, data });
      if (createPaymentDto.status === 'SUCCESS') {
        await this.prisma.invoice.update({ where: { id: createPaymentDto.invoiceId }, data: { status: 'PAID' } });
      }
      return updated;
    }

    try {
      const payment = await this.prisma.payment.create({ data });

      if (createPaymentDto.status === 'SUCCESS') {
        await this.prisma.invoice.update({ where: { id: createPaymentDto.invoiceId }, data: { status: 'PAID' } });
      }

      return payment;
    } catch (err) {
      throw new BadRequestException(err);
    }
  }

  async findAll() {
    return this.prisma.payment.findMany();
  }

  async findOne(id: string) {
    return this.prisma.payment.findUnique({
      where: { id },
    });
  }

  async update(id: string, updatePaymentDto: UpdatePaymentDto) {
    const payment = await this.prisma.payment.update({
      where: { id },
      data: updatePaymentDto,
    });
    
    if (updatePaymentDto.status === 'SUCCESS') {
      await this.prisma.invoice.update({
        where: { id: payment.invoiceId },
        data: { status: 'PAID' },
      });
      await this.prisma.payment.update({
        where: { id: payment.id },
        data: { paidAt: new Date() },
      });
    }

    return payment;
  }

  async remove(id: string) {
    return this.prisma.payment.delete({
      where: { id },
    });
  }
}
