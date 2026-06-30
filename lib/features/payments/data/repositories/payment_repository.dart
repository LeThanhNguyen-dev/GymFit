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

  Stream<PaymentModel?> watchPaymentByOrderId(String orderId) {
    return _client
        .from(AppConstants.paymentsTable)
        .stream(primaryKey: ['id'])
        .eq('order_id', orderId)
        .map((rows) => rows.isEmpty ? null : PaymentModel.fromJson(rows.first));
  }

  Future<List<PaymentModel>> getPaymentHistory(String userId) async {
    final rows = await _client
        .from(AppConstants.paymentsTable)
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);
    return rows.map((row) => PaymentModel.fromJson(row)).toList();
  }

  Future<PayOsPaymentSession> createPayOsPayment(PaymentModel payment) async {
    final response = await _client.functions.invoke(
      'create-payos-payment',
      body: {'payment_id': payment.id, 'order_id': payment.orderId},
    );
    return PayOsPaymentSession.fromJson(_functionData(response.data));
  }

  Future<PaymentModel> syncPayOsPayment(PaymentModel payment) async {
    final response = await _client.functions.invoke(
      'sync-payos-payment',
      body: {'payment_id': payment.id, 'order_id': payment.orderId},
    );
    return PaymentModel.fromJson(_functionData(response.data));
  }

  Map<String, dynamic> _functionData(Object? body) {
    final root = Map<String, dynamic>.from(body as Map);
    if (root['error'] != null) {
      throw StateError(root['error'].toString());
    }
    return Map<String, dynamic>.from(root['data'] as Map);
  }
}

class PayOsPaymentSession {
  const PayOsPaymentSession({
    required this.orderCode,
    required this.amount,
    required this.description,
    required this.qrCode,
    required this.paymentLinkId,
    this.checkoutUrl,
    this.accountNumber,
    this.accountName,
    this.bin,
    this.status = 'PENDING',
  });

  final int orderCode;
  final int amount;
  final String description;
  final String qrCode;
  final String paymentLinkId;
  final String? checkoutUrl;
  final String? accountNumber;
  final String? accountName;
  final String? bin;
  final String status;

  factory PayOsPaymentSession.fromJson(Map<String, dynamic> json) {
    return PayOsPaymentSession(
      orderCode: (json['orderCode'] as num?)?.toInt() ?? 0,
      amount: (json['amount'] as num?)?.toInt() ?? 0,
      description: json['description']?.toString() ?? '',
      qrCode: json['qrCode']?.toString() ?? '',
      paymentLinkId: json['paymentLinkId']?.toString() ?? '',
      checkoutUrl: json['checkoutUrl'] as String?,
      accountNumber: json['accountNumber']?.toString(),
      accountName: json['accountName']?.toString(),
      bin: json['bin']?.toString(),
      status: json['status']?.toString() ?? 'PENDING',
    );
  }
}
