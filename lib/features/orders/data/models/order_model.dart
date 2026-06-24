import 'package:flutter/material.dart';

import '../../../../core/models/model_converters.dart';
import '../../../../shared/enums/database_enums.dart';

class OrderModel {
  const OrderModel({
    required this.id,
    required this.orderNumber,
    required this.userId,
    required this.shippingFullName,
    required this.shippingPhone,
    required this.shippingAddress1,
    required this.shippingCity,
    required this.subtotal,
    required this.totalAmount,
    this.status = OrderStatus.pending,
    this.shippingAddress2,
    this.shippingWard,
    this.shippingDistrict,
    this.shippingProvince,
    this.shippingCountry = 'VN',
    this.shippingPostalCode,
    this.discountAmount = 0,
    this.shippingFee = 0,
    this.taxAmount = 0,
    this.voucherId,
    this.voucherCode,
    this.customerNote,
    this.adminNote,
    this.confirmedAt,
    this.shippedAt,
    this.deliveredAt,
    this.cancelledAt,
    this.cancelReason,
    this.items = const [],
    this.payment,
    this.shippingTracking = const [],
    this.statusHistory = const [],
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String orderNumber;
  final String userId;
  final OrderStatus status;
  final String shippingFullName;
  final String shippingPhone;
  final String shippingAddress1;
  final String? shippingAddress2;
  final String? shippingWard;
  final String? shippingDistrict;
  final String shippingCity;
  final String? shippingProvince;
  final String shippingCountry;
  final String? shippingPostalCode;
  final double subtotal;
  final double discountAmount;
  final double shippingFee;
  final double taxAmount;
  final double totalAmount;
  final String? voucherId;
  final String? voucherCode;
  final String? customerNote;
  final String? adminNote;
  final DateTime? confirmedAt;
  final DateTime? shippedAt;
  final DateTime? deliveredAt;
  final DateTime? cancelledAt;
  final String? cancelReason;
  final List<OrderItemModel> items;
  final PaymentModel? payment;
  final List<ShippingTrackingModel> shippingTracking;
  final List<OrderStatusHistoryModel> statusHistory;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory OrderModel.fromJson(Map<String, dynamic> json) => OrderModel(
    id: json['id'].toString(),
    orderNumber: json['order_number'].toString(),
    userId: json['user_id'].toString(),
    status: enumFromSnake(
      OrderStatus.values,
      json['status'],
      OrderStatus.pending,
    ),
    shippingFullName: json['shipping_full_name'].toString(),
    shippingPhone: json['shipping_phone'].toString(),
    shippingAddress1: json['shipping_address1'].toString(),
    shippingAddress2: json['shipping_address2'] as String?,
    shippingWard: json['shipping_ward'] as String?,
    shippingDistrict: json['shipping_district'] as String?,
    shippingCity: json['shipping_city'].toString(),
    shippingProvince: json['shipping_province'] as String?,
    shippingCountry: json['shipping_country'] as String? ?? 'VN',
    shippingPostalCode: json['shipping_postal_code'] as String?,
    subtotal: doubleFromJson(json['subtotal']) ?? 0,
    discountAmount: doubleFromJson(json['discount_amount']) ?? 0,
    shippingFee: doubleFromJson(json['shipping_fee']) ?? 0,
    taxAmount: doubleFromJson(json['tax_amount']) ?? 0,
    totalAmount: doubleFromJson(json['total_amount']) ?? 0,
    voucherId: json['voucher_id'] as String?,
    voucherCode: json['voucher_code'] as String?,
    customerNote: json['customer_note'] as String?,
    adminNote: json['admin_note'] as String?,
    confirmedAt: dateTimeFromJson(json['confirmed_at']),
    shippedAt: dateTimeFromJson(json['shipped_at']),
    deliveredAt: dateTimeFromJson(json['delivered_at']),
    cancelledAt: dateTimeFromJson(json['cancelled_at']),
    cancelReason: json['cancel_reason'] as String?,
    items: mapListFromJson(
      json['items'] ?? json['order_items'],
    ).map(OrderItemModel.fromJson).toList(),
    payment: (json['payment'] ?? _firstRelation(json['payments'])) is Map
        ? PaymentModel.fromJson(
            mapFromJson(json['payment'] ?? _firstRelation(json['payments'])),
          )
        : null,
    shippingTracking: mapListFromJson(
      json['shipping_tracking'],
    ).map(ShippingTrackingModel.fromJson).toList(),
    statusHistory: mapListFromJson(
      json['status_history'] ?? json['order_status_history'],
    ).map(OrderStatusHistoryModel.fromJson).toList(),
    createdAt: dateTimeFromJson(json['created_at']),
    updatedAt: dateTimeFromJson(json['updated_at']),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'order_number': orderNumber,
    'user_id': userId,
    'status': enumToSnake(status),
    'shipping_full_name': shippingFullName,
    'shipping_phone': shippingPhone,
    'shipping_address1': shippingAddress1,
    'shipping_address2': shippingAddress2,
    'shipping_ward': shippingWard,
    'shipping_district': shippingDistrict,
    'shipping_city': shippingCity,
    'shipping_province': shippingProvince,
    'shipping_country': shippingCountry,
    'shipping_postal_code': shippingPostalCode,
    'subtotal': subtotal,
    'discount_amount': discountAmount,
    'shipping_fee': shippingFee,
    'tax_amount': taxAmount,
    'total_amount': totalAmount,
    'voucher_id': voucherId,
    'voucher_code': voucherCode,
    'customer_note': customerNote,
    'admin_note': adminNote,
    'confirmed_at': dateTimeToJson(confirmedAt),
    'shipped_at': dateTimeToJson(shippedAt),
    'delivered_at': dateTimeToJson(deliveredAt),
    'cancelled_at': dateTimeToJson(cancelledAt),
    'cancel_reason': cancelReason,
    'items': items.map((item) => item.toJson()).toList(),
    'payment': payment?.toJson(),
    'shipping_tracking': shippingTracking
        .map((tracking) => tracking.toJson())
        .toList(),
    'status_history': statusHistory.map((item) => item.toJson()).toList(),
    'created_at': dateTimeToJson(createdAt),
    'updated_at': dateTimeToJson(updatedAt),
  };

  bool get canCancel =>
      status == OrderStatus.pending || status == OrderStatus.confirmed;

  bool get canConfirmDelivery => status == OrderStatus.shipped;

  String get statusText => switch (status) {
    OrderStatus.pending => 'Cho xac nhan',
    OrderStatus.confirmed => 'Da xac nhan',
    OrderStatus.processing => 'Dang xu ly',
    OrderStatus.shipped => 'Dang giao',
    OrderStatus.delivered => 'Da giao',
    OrderStatus.cancelled => 'Da huy',
    OrderStatus.refunded => 'Da hoan tien',
    OrderStatus.partiallyRefunded => 'Hoan tien mot phan',
  };

  Color get statusColor => switch (status) {
    OrderStatus.pending => Colors.orange,
    OrderStatus.confirmed => Colors.blue,
    OrderStatus.processing => Colors.indigo,
    OrderStatus.shipped => Colors.purple,
    OrderStatus.delivered => Colors.green,
    OrderStatus.cancelled => Colors.red,
    OrderStatus.refunded || OrderStatus.partiallyRefunded => Colors.teal,
  };

  OrderModel copyWith({
    String? id,
    String? orderNumber,
    String? userId,
    OrderStatus? status,
    String? shippingFullName,
    String? shippingPhone,
    String? shippingAddress1,
    String? shippingAddress2,
    String? shippingWard,
    String? shippingDistrict,
    String? shippingCity,
    String? shippingProvince,
    String? shippingCountry,
    String? shippingPostalCode,
    double? subtotal,
    double? discountAmount,
    double? shippingFee,
    double? taxAmount,
    double? totalAmount,
    String? voucherId,
    String? voucherCode,
    String? customerNote,
    String? adminNote,
    DateTime? confirmedAt,
    DateTime? shippedAt,
    DateTime? deliveredAt,
    DateTime? cancelledAt,
    String? cancelReason,
    List<OrderItemModel>? items,
    PaymentModel? payment,
    List<ShippingTrackingModel>? shippingTracking,
    List<OrderStatusHistoryModel>? statusHistory,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return OrderModel(
      id: id ?? this.id,
      orderNumber: orderNumber ?? this.orderNumber,
      userId: userId ?? this.userId,
      status: status ?? this.status,
      shippingFullName: shippingFullName ?? this.shippingFullName,
      shippingPhone: shippingPhone ?? this.shippingPhone,
      shippingAddress1: shippingAddress1 ?? this.shippingAddress1,
      shippingAddress2: shippingAddress2 ?? this.shippingAddress2,
      shippingWard: shippingWard ?? this.shippingWard,
      shippingDistrict: shippingDistrict ?? this.shippingDistrict,
      shippingCity: shippingCity ?? this.shippingCity,
      shippingProvince: shippingProvince ?? this.shippingProvince,
      shippingCountry: shippingCountry ?? this.shippingCountry,
      shippingPostalCode: shippingPostalCode ?? this.shippingPostalCode,
      subtotal: subtotal ?? this.subtotal,
      discountAmount: discountAmount ?? this.discountAmount,
      shippingFee: shippingFee ?? this.shippingFee,
      taxAmount: taxAmount ?? this.taxAmount,
      totalAmount: totalAmount ?? this.totalAmount,
      voucherId: voucherId ?? this.voucherId,
      voucherCode: voucherCode ?? this.voucherCode,
      customerNote: customerNote ?? this.customerNote,
      adminNote: adminNote ?? this.adminNote,
      confirmedAt: confirmedAt ?? this.confirmedAt,
      shippedAt: shippedAt ?? this.shippedAt,
      deliveredAt: deliveredAt ?? this.deliveredAt,
      cancelledAt: cancelledAt ?? this.cancelledAt,
      cancelReason: cancelReason ?? this.cancelReason,
      items: items ?? this.items,
      payment: payment ?? this.payment,
      shippingTracking: shippingTracking ?? this.shippingTracking,
      statusHistory: statusHistory ?? this.statusHistory,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class OrderItemModel {
  const OrderItemModel({
    required this.id,
    required this.orderId,
    required this.productName,
    required this.unitPrice,
    required this.quantity,
    required this.totalPrice,
    this.variantId,
    this.productId,
    this.variantName,
    this.sku,
    this.imageUrl,
    this.discountAmount = 0,
    this.isReviewed = false,
    this.createdAt,
  });

  final String id;
  final String orderId;
  final String? variantId;
  final String? productId;
  final String productName;
  final String? variantName;
  final String? sku;
  final String? imageUrl;
  final double unitPrice;
  final int quantity;
  final double discountAmount;
  final double totalPrice;
  final bool isReviewed;
  final DateTime? createdAt;

  factory OrderItemModel.fromJson(Map<String, dynamic> json) => OrderItemModel(
    id: json['id'].toString(),
    orderId: json['order_id'].toString(),
    variantId: json['variant_id'] as String?,
    productId: json['product_id'] as String?,
    productName: json['product_name'].toString(),
    variantName: json['variant_name'] as String?,
    sku: json['sku'] as String?,
    imageUrl: json['image_url'] as String?,
    unitPrice: doubleFromJson(json['unit_price']) ?? 0,
    quantity: intFromJson(json['quantity']) ?? 1,
    discountAmount: doubleFromJson(json['discount_amount']) ?? 0,
    totalPrice: doubleFromJson(json['total_price']) ?? 0,
    isReviewed: json['is_reviewed'] as bool? ?? false,
    createdAt: dateTimeFromJson(json['created_at']),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'order_id': orderId,
    'variant_id': variantId,
    'product_id': productId,
    'product_name': productName,
    'variant_name': variantName,
    'sku': sku,
    'image_url': imageUrl,
    'unit_price': unitPrice,
    'quantity': quantity,
    'discount_amount': discountAmount,
    'total_price': totalPrice,
    'is_reviewed': isReviewed,
    'created_at': dateTimeToJson(createdAt),
  };

  String get variantInfo => variantName ?? sku ?? '';
}

class OrderStatusHistoryModel {
  const OrderStatusHistoryModel({
    required this.id,
    required this.orderId,
    required this.toStatus,
    this.fromStatus,
    this.note,
    this.changedBy,
    this.createdAt,
  });

  final String id;
  final String orderId;
  final OrderStatus? fromStatus;
  final OrderStatus toStatus;
  final String? note;
  final String? changedBy;
  final DateTime? createdAt;

  factory OrderStatusHistoryModel.fromJson(Map<String, dynamic> json) {
    return OrderStatusHistoryModel(
      id: json['id'].toString(),
      orderId: json['order_id'].toString(),
      fromStatus: json['from_status'] == null
          ? null
          : enumFromSnake(
              OrderStatus.values,
              json['from_status'],
              OrderStatus.pending,
            ),
      toStatus: enumFromSnake(
        OrderStatus.values,
        json['to_status'],
        OrderStatus.pending,
      ),
      note: json['note'] as String?,
      changedBy: json['changed_by'] as String?,
      createdAt: dateTimeFromJson(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'order_id': orderId,
    'from_status': fromStatus == null ? null : enumToSnake(fromStatus!),
    'to_status': enumToSnake(toStatus),
    'note': note,
    'changed_by': changedBy,
    'created_at': dateTimeToJson(createdAt),
  };
}

class PaymentModel {
  const PaymentModel({
    required this.id,
    required this.orderId,
    required this.userId,
    required this.method,
    required this.amount,
    this.status = PaymentStatus.pending,
    this.currency = 'VND',
    this.gateway,
    this.gatewayTransactionId,
    this.gatewayResponse = const {},
    this.refundedAmount = 0,
    this.refundedAt,
    this.paidAt,
    this.failedAt,
    this.failureReason,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String orderId;
  final String userId;
  final PaymentMethod method;
  final PaymentStatus status;
  final double amount;
  final String currency;
  final String? gateway;
  final String? gatewayTransactionId;
  final Map<String, dynamic> gatewayResponse;
  final double refundedAmount;
  final DateTime? refundedAt;
  final DateTime? paidAt;
  final DateTime? failedAt;
  final String? failureReason;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory PaymentModel.fromJson(Map<String, dynamic> json) => PaymentModel(
    id: json['id'].toString(),
    orderId: json['order_id'].toString(),
    userId: json['user_id'].toString(),
    method: enumFromSnake(
      PaymentMethod.values,
      json['method'],
      PaymentMethod.cod,
    ),
    status: enumFromSnake(
      PaymentStatus.values,
      json['status'],
      PaymentStatus.pending,
    ),
    amount: doubleFromJson(json['amount']) ?? 0,
    currency: json['currency'] as String? ?? 'VND',
    gateway: json['gateway'] as String?,
    gatewayTransactionId: json['gateway_transaction_id'] as String?,
    gatewayResponse: mapFromJson(json['gateway_response']),
    refundedAmount: doubleFromJson(json['refunded_amount']) ?? 0,
    refundedAt: dateTimeFromJson(json['refunded_at']),
    paidAt: dateTimeFromJson(json['paid_at']),
    failedAt: dateTimeFromJson(json['failed_at']),
    failureReason: json['failure_reason'] as String?,
    createdAt: dateTimeFromJson(json['created_at']),
    updatedAt: dateTimeFromJson(json['updated_at']),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'order_id': orderId,
    'user_id': userId,
    'method': enumToSnake(method),
    'status': enumToSnake(status),
    'amount': amount,
    'currency': currency,
    'gateway': gateway,
    'gateway_transaction_id': gatewayTransactionId,
    'gateway_response': gatewayResponse,
    'refunded_amount': refundedAmount,
    'refunded_at': dateTimeToJson(refundedAt),
    'paid_at': dateTimeToJson(paidAt),
    'failed_at': dateTimeToJson(failedAt),
    'failure_reason': failureReason,
    'created_at': dateTimeToJson(createdAt),
    'updated_at': dateTimeToJson(updatedAt),
  };

  String get methodDisplay => switch (method) {
    PaymentMethod.cod => 'Thanh toan khi nhan hang',
    PaymentMethod.momo => 'Vi Momo',
    PaymentMethod.payos => 'payOS / VietQR',
    PaymentMethod.bankTransfer => 'Chuyen khoan',
    PaymentMethod.creditCard || PaymentMethod.debitCard => 'The ngan hang',
    _ => method.name,
  };

  String get statusDisplay => switch (status) {
    PaymentStatus.pending => 'Cho thanh toan',
    PaymentStatus.paid => 'Thanh cong',
    PaymentStatus.failed => 'That bai',
    PaymentStatus.refunded => 'Da hoan tien',
    PaymentStatus.partiallyRefunded => 'Hoan tien mot phan',
    PaymentStatus.chargeback => 'Khieu nai hoan tien',
  };
}

class ShippingTrackingModel {
  const ShippingTrackingModel({
    required this.id,
    required this.orderId,
    required this.carrier,
    required this.trackingNumber,
    this.status = ShippingStatus.pending,
    this.estimatedDelivery,
    this.actualDelivery,
    this.shippingFee,
    this.serviceType,
    this.trackingUrl,
    this.events = const [],
    this.lastEventAt,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String orderId;
  final String carrier;
  final String trackingNumber;
  final ShippingStatus status;
  final DateTime? estimatedDelivery;
  final DateTime? actualDelivery;
  final double? shippingFee;
  final String? serviceType;
  final String? trackingUrl;
  final List<Map<String, dynamic>> events;
  final DateTime? lastEventAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory ShippingTrackingModel.fromJson(Map<String, dynamic> json) {
    return ShippingTrackingModel(
      id: json['id'].toString(),
      orderId: json['order_id'].toString(),
      carrier: json['carrier'].toString(),
      trackingNumber: json['tracking_number'].toString(),
      status: enumFromSnake(
        ShippingStatus.values,
        json['status'],
        ShippingStatus.pending,
      ),
      estimatedDelivery: dateTimeFromJson(json['estimated_delivery']),
      actualDelivery: dateTimeFromJson(json['actual_delivery']),
      shippingFee: doubleFromJson(json['shipping_fee']),
      serviceType: json['service_type'] as String?,
      trackingUrl: json['tracking_url'] as String?,
      events: mapListFromJson(json['events']),
      lastEventAt: dateTimeFromJson(json['last_event_at']),
      createdAt: dateTimeFromJson(json['created_at']),
      updatedAt: dateTimeFromJson(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'order_id': orderId,
    'carrier': carrier,
    'tracking_number': trackingNumber,
    'status': enumToSnake(status),
    'estimated_delivery': dateToJson(estimatedDelivery),
    'actual_delivery': dateToJson(actualDelivery),
    'shipping_fee': shippingFee,
    'service_type': serviceType,
    'tracking_url': trackingUrl,
    'events': events,
    'last_event_at': dateTimeToJson(lastEventAt),
    'created_at': dateTimeToJson(createdAt),
    'updated_at': dateTimeToJson(updatedAt),
  };

  String get statusDisplay => switch (status) {
    ShippingStatus.pending => 'Dang chuan bi',
    ShippingStatus.pickedUp => 'Da lay hang',
    ShippingStatus.inTransit => 'Dang van chuyen',
    ShippingStatus.outForDelivery => 'Dang giao hang',
    ShippingStatus.delivered => 'Da giao',
    ShippingStatus.failedAttempt => 'Giao khong thanh cong',
    ShippingStatus.returned => 'Hoan hang',
    ShippingStatus.lost => 'That lac',
  };
}

Object? _firstRelation(Object? value) {
  if (value is List && value.isNotEmpty) return value.first;
  return value;
}
