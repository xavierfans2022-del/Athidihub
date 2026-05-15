import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:athidihub/features/payments/data/payment_repository.dart';

class PaymentState {
  final bool isLoading;
  final String? error;
  final PaymentModel? result;

  PaymentState({this.isLoading = false, this.error, this.result});

  PaymentState copyWith({bool? isLoading, String? error, PaymentModel? result}) {
    return PaymentState(
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      result: result ?? this.result,
    );
  }
}

class PaymentNotifier extends StateNotifier<PaymentState> {
  final PaymentRepository _repo;

  PaymentNotifier(this._repo) : super(PaymentState());

  Future<bool> recordPayment({
    required String invoiceId,
    required String tenantId,
    required double amount,
    required String method,
  }) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final payment = await _repo.createPayment(
        invoiceId: invoiceId,
        tenantId: tenantId,
        amount: amount,
        method: method,
      );
      state = state.copyWith(isLoading: false, result: payment);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }
}

final paymentNotifierProvider =
    StateNotifierProvider<PaymentNotifier, PaymentState>((ref) {
  return PaymentNotifier(ref.read(paymentRepositoryProvider));
});

final paymentsByInvoiceProvider = FutureProvider.family<List<PaymentModel>, String>((ref, invoiceId) async {
  final repo = ref.watch(paymentRepositoryProvider);
  final all = await repo.getPayments();
  return all.where((p) => p.invoiceId == invoiceId).toList();
});
