String formatCurrency(num value) {
  final amount = value.round().toString();
  final buffer = StringBuffer();

  for (var i = 0; i < amount.length; i++) {
    final remaining = amount.length - i;
    buffer.write(amount[i]);
    if (remaining > 1 && remaining % 3 == 1) {
      buffer.write('.');
    }
  }

  return '$bufferđ';
}
