import 'dart:async';

class Debouncer {
  Debouncer({this.delay = const Duration(milliseconds: 300)});

  final Duration delay;
  Timer? _timer;

  void call(VoidCallback action) {
    _timer?.cancel();
    _timer = Timer(delay, action);
  }

  void dispose() {
    _timer?.cancel();
  }
}

typedef VoidCallback = void Function();

String formatPhoneNumber(String phone) {
  if (phone.length == 10) {
    return '${phone.substring(0, 3)} ${phone.substring(3, 6)} ${phone.substring(6)}';
  }
  if (phone.length == 11) {
    return '${phone.substring(0, 4)} ${phone.substring(4, 7)} ${phone.substring(7)}';
  }
  return phone;
}
