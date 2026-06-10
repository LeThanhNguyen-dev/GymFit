import 'dart:math';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../shared/enums/database_enums.dart';
import '../../../orders/data/models/order_model.dart';

class PaymentRepository {
  const PaymentRepository(this._client);

  final SupabaseClient _client;

  Future<PaymentModel> createPayment(
    String orderId,
    String userId,
    PaymentMethod method,
    double amount,
  ) async {
    final row = await _client
        .from(AppConstants.paymentsTable)
        .insert({
          'order_id': orderId,
          'user_id': userId,
          'method': method.name,
          'status': 'pending',
          'amount': amount,
          'currency': 'VND',
          'gateway': method == PaymentMethod.cod ? null : method.name,
        })
        .select()
        .single();
    return PaymentModel.fromJson(row);
  }

  Future<PaymentModel> updatePaymentStatus(
    String paymentId,
    PaymentStatus status, {
    String? transactionId,
  }) async {
    final now = DateTime.now().toIso8601String();
    final row = await _client
        .from(AppConstants.paymentsTable)
        .update({
          'status': status.name,
          'gateway_transaction_id': transactionId,
          if (status == PaymentStatus.paid) 'paid_at': now,
          if (status == PaymentStatus.failed) 'failed_at': now,
          'updated_at': now,
        })
        .eq('id', paymentId)
        .select()
        .single();
    return PaymentModel.fromJson(row);
  }

  Future<PaymentModel?> getPaymentByOrderId(String orderId) async {
    final row = await _client
        .from(AppConstants.paymentsTable)
        .select()
        .eq('order_id', orderId)
        .maybeSingle();
    return row == null ? null : PaymentModel.fromJson(row);
  }

  Future<List<PaymentModel>> getPaymentHistory(String userId) async {
    final rows = await _client
        .from(AppConstants.paymentsTable)
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);
    return rows.map((row) => PaymentModel.fromJson(row)).toList();
  }

  Future<PaymentModel> mockMomoPayment(String paymentId, double amount) {
    return _mockGatewayPayment(paymentId, 'MOMO');
  }

  Future<PaymentModel> mockVnPayPayment(String paymentId, double amount) {
    return _mockGatewayPayment(paymentId, 'VNPAY');
  }

  Future<PaymentModel> _mockGatewayPayment(
    String paymentId,
    String prefix,
  ) async {
    await updatePaymentStatus(paymentId, PaymentStatus.pending);
    await Future<void>.delayed(const Duration(seconds: 2));
    final success = Random().nextDouble() < 0.9;
    return updatePaymentStatus(
      paymentId,
      success ? PaymentStatus.paid : PaymentStatus.failed,
      transactionId: success
          ? '$prefix-${DateTime.now().millisecondsSinceEpoch}'
          : null,
    );
  }
}
