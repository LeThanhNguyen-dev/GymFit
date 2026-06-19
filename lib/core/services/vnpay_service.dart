import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:intl/intl.dart';

import '../constants/app_constants.dart';

class VnPayService {
  /// Sinh mã checksum HMAC SHA512 cho VNPay
  String _generateHash(String data) {
    final bytes = utf8.encode(data);
    final key = utf8.encode(AppConstants.vnpayHashSecret);
    final hmac = Hmac(sha512, key);
    final digest = hmac.convert(bytes);
    return digest.toString();
  }

  /// Tạo link thanh toán VNPay
  String createPaymentUrl({
    required int amount,
    required String orderInfo,
    required String returnUrl,
    String? ipAddress,
  }) {
    final now = DateTime.now();
    final expire = now.add(const Duration(minutes: 15));
    
    final dateFormat = DateFormat('yyyyMMddHHmmss');
    final createDate = dateFormat.format(now);
    final expireDate = dateFormat.format(expire);
    
    // Tạo mã đơn hàng duy nhất
    final txnRef = now.millisecondsSinceEpoch.toString();

    final params = <String, String>{
      'vnp_Version': '2.1.0',
      'vnp_Command': 'pay',
      'vnp_TmnCode': AppConstants.vnpayTmnCode,
      'vnp_Locale': 'vn',
      'vnp_CurrCode': 'VND',
      'vnp_TxnRef': txnRef,
      'vnp_OrderInfo': orderInfo,
      'vnp_OrderType': 'other',
      'vnp_Amount': (amount * 100).toString(), // VNPay yêu cầu nhân 100
      'vnp_ReturnUrl': returnUrl,
      'vnp_IpAddr': ipAddress ?? '127.0.0.1', // Bắt buộc phải có IP, mock tạm nếu null
      'vnp_CreateDate': createDate,
      'vnp_ExpireDate': expireDate,
    };

    // Sắp xếp các key theo thứ tự alphabet (RẤT QUAN TRỌNG ĐỂ KÝ ĐÚNG)
    final sortedKeys = params.keys.toList()..sort();
    final List<String> queryData = [];
    final List<String> hashData = [];
    
    for (final key in sortedKeys) {
      final value = params[key];
      if (value != null && value.isNotEmpty) {
        queryData.add('${Uri.encodeComponent(key)}=${Uri.encodeComponent(value)}');
        hashData.add('$key=$value');
      }
    }
    
    final queryString = queryData.join('&');
    final signData = hashData.join('&');
    
    final secureHash = _generateHash(signData);
    
    return '${AppConstants.vnpayUrl}?$queryString&vnp_SecureHash=$secureHash';
  }
}
