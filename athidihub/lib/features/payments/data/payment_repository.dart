import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:athidihub/core/network/dio_provider.dart';

final paymentRepositoryProvider = Provider<PaymentRepository>((ref) {
  return PaymentRepository(ref.read(dioProvider));
});

class PaymentModel {
  final String id;
  final String invoiceId;
  final String tenantId;
  final double amount;
  final String method;
  final String status;
  final String? paidAt;

  PaymentModel({
    required this.id,
    required this.invoiceId,
    required this.tenantId,
    required this.amount,
    required this.method,
    required this.status,
    this.paidAt,
  });

  factory PaymentModel.fromJson(Map<String, dynamic> json) {
    return PaymentModel(
      id: json['id'] ?? '',
      invoiceId: json['invoiceId'] ?? '',
      tenantId: json['tenantId'] ?? '',
      amount: double.parse((json['amount'] ?? 0).toString()),
      method: json['method'] ?? 'CASH',
      status: json['status'] ?? 'PENDING',
      paidAt: json['paidAt'],
    );
  }
}

class PaymentRepository {
  final Dio _dio;
  PaymentRepository(this._dio);

  Future<PaymentModel> createPayment({
    required String invoiceId,
    required String tenantId,
    required double amount,
    required String method,
  }) async {
    final response = await _dio.post('/payments', data: {
      'invoiceId': invoiceId,
      'tenantId': tenantId,
      'amount': amount,
      'method': method,
      'status': 'SUCCESS',
    });
    return PaymentModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<List<PaymentModel>> getPayments() async {
    final response = await _dio.get('/payments');
    final List data = response.data as List;
    return data.map((j) => PaymentModel.fromJson(j as Map<String, dynamic>)).toList();
  }
}
