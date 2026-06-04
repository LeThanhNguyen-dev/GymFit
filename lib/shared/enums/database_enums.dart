enum GenderType { male, female, other, preferNotToSay }

enum ProductStatus { draft, active, inactive, outOfStock, discontinued }

enum VariantStatus { active, inactive, discontinued }

enum InventoryAction { restock, sale, returnItem, adjustment, damage, transfer }

enum AddressType { home, work, other }

enum VoucherType { percentage, fixedAmount, freeShipping, buyXGetY }

enum VoucherScope { global, category, brand, product, userSpecific }

enum OrderStatus {
  pending,
  confirmed,
  processing,
  shipped,
  delivered,
  cancelled,
  refunded,
  partiallyRefunded,
}

enum PaymentStatus {
  pending,
  paid,
  failed,
  refunded,
  partiallyRefunded,
  chargeback,
}

enum PaymentMethod {
  creditCard,
  debitCard,
  paypal,
  stripe,
  bankTransfer,
  cod,
  momo,
  zalopay,
  vnpay,
  applePay,
  googlePay,
}

enum ShippingStatus {
  pending,
  pickedUp,
  inTransit,
  outForDelivery,
  delivered,
  failedAttempt,
  returned,
  lost,
}

enum ReviewStatus { pending, approved, rejected, flagged }

enum TicketStatus { open, inProgress, waitingCustomer, resolved, closed }

enum TicketPriority { low, medium, high, urgent }

enum TicketCategory {
  orderIssue,
  paymentIssue,
  shippingIssue,
  productIssue,
  returnRefund,
  accountIssue,
  other,
}

String enumToSnake(Enum value) {
  return value.name.replaceAllMapped(
    RegExp('[A-Z]'),
    (match) => '_${match.group(0)!.toLowerCase()}',
  );
}

T enumFromSnake<T extends Enum>(List<T> values, Object? value, T fallback) {
  if (value == null) return fallback;
  final normalized = value.toString();

  return values.firstWhere(
    (item) => enumToSnake(item) == normalized,
    orElse: () => fallback,
  );
}
