import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/constants/app_constants.dart';
import '../models/shop_registration_model.dart';

class ShopRegistrationRepository {
  const ShopRegistrationRepository(this._client);

  final SupabaseClient _client;

  Future<ShopRegistrationModel> submitRegistration({
    required String userId,
    required String shopName,
    String? shopDescription,
    required String phoneNumber,
    required String address,
    Uint8List? cccdFrontImage,
    String? cccdFrontExt,
    Uint8List? cccdBackImage,
    String? cccdBackExt,
    required String fullName,
    required String cccdNumber,
    required DateTime dateOfBirth,
    required DateTime issuedDate,
    required String issuedPlace,
    Uint8List? businessLicenseImage,
    String? businessLicenseExt,
    String? taxCode,
    required String businessType,
  }) async {
    String? cccdFrontUrl;
    String? cccdBackUrl;
    String? businessLicenseUrl;

    if (cccdFrontImage != null) {
      cccdFrontUrl = await _uploadImage(cccdFrontImage, userId, 'cccd_front', cccdFrontExt ?? 'jpg');
    }
    if (cccdBackImage != null) {
      cccdBackUrl = await _uploadImage(cccdBackImage, userId, 'cccd_back', cccdBackExt ?? 'jpg');
    }
    if (businessLicenseImage != null) {
      businessLicenseUrl = await _uploadImage(
        businessLicenseImage,
        userId,
        'business_license',
        businessLicenseExt ?? 'jpg',
      );
    }

    final now = DateTime.now().toUtc().toIso8601String();
    final payload = {
      'user_id': userId,
      'shop_name': shopName,
      'shop_description': shopDescription,
      'phone_number': phoneNumber,
      'address': address,
      'cccd_front_url': cccdFrontUrl,
      'cccd_back_url': cccdBackUrl,
      'full_name': fullName,
      'cccd_number': cccdNumber,
      'date_of_birth': dateOfBirth.toUtc().toIso8601String(),
      'issued_date': issuedDate.toUtc().toIso8601String(),
      'issued_place': issuedPlace,
      'business_license_url': businessLicenseUrl,
      'tax_code': taxCode,
      'business_type': businessType,
      'status': 'pending',
      'submitted_at': now,
      'created_at': now,
      'updated_at': now,
    };

    final row = await _client
        .from(AppConstants.shopRegistrationsTable)
        .insert(payload)
        .select()
        .single();

    return ShopRegistrationModel.fromJson(row);
  }

  Future<ShopRegistrationModel> updateRegistration({
    required String id,
    required String userId,
    required String shopName,
    String? shopDescription,
    required String phoneNumber,
    required String address,
    Uint8List? cccdFrontImage,
    String? cccdFrontExt,
    Uint8List? cccdBackImage,
    String? cccdBackExt,
    required String fullName,
    required String cccdNumber,
    required DateTime dateOfBirth,
    required DateTime issuedDate,
    required String issuedPlace,
    Uint8List? businessLicenseImage,
    String? businessLicenseExt,
    String? taxCode,
    required String businessType,
    String? existingCccdFrontUrl,
    String? existingCccdBackUrl,
    String? existingBusinessLicenseUrl,
  }) async {
    String? cccdFrontUrl = existingCccdFrontUrl;
    String? cccdBackUrl = existingCccdBackUrl;
    String? businessLicenseUrl = existingBusinessLicenseUrl;

    if (cccdFrontImage != null) {
      cccdFrontUrl = await _uploadImage(cccdFrontImage, userId, 'cccd_front', cccdFrontExt ?? 'jpg');
    }
    if (cccdBackImage != null) {
      cccdBackUrl = await _uploadImage(cccdBackImage, userId, 'cccd_back', cccdBackExt ?? 'jpg');
    }
    if (businessLicenseImage != null) {
      businessLicenseUrl = await _uploadImage(
        businessLicenseImage,
        userId,
        'business_license',
        businessLicenseExt ?? 'jpg',
      );
    }

    final now = DateTime.now().toUtc().toIso8601String();
    final payload = {
      'shop_name': shopName,
      'shop_description': shopDescription,
      'phone_number': phoneNumber,
      'address': address,
      'cccd_front_url': cccdFrontUrl,
      'cccd_back_url': cccdBackUrl,
      'full_name': fullName,
      'cccd_number': cccdNumber,
      'date_of_birth': dateOfBirth.toUtc().toIso8601String(),
      'issued_date': issuedDate.toUtc().toIso8601String(),
      'issued_place': issuedPlace,
      'business_license_url': businessLicenseUrl,
      'tax_code': taxCode,
      'business_type': businessType,
      'status': 'pending',
      'rejection_reason': null,
      'submitted_at': now,
      'updated_at': now,
    };

    final row = await _client
        .from(AppConstants.shopRegistrationsTable)
        .update(payload)
        .eq('id', id)
        .eq('user_id', userId)
        .select()
        .single();

    return ShopRegistrationModel.fromJson(row);
  }

  Future<ShopRegistrationModel?> getRegistrationStatus(String userId) async {
    try {
      final rows = await _client
          .from(AppConstants.shopRegistrationsTable)
          .select()
          .eq('user_id', userId)
          .order('submitted_at', ascending: false)
          .limit(1);

      if (rows.isEmpty) return null;
      return ShopRegistrationModel.fromJson(rows.first);
    } catch (_) {
      return null;
    }
  }

  Future<List<ShopRegistrationModel>> getAllRegistrations({
    String? statusFilter,
  }) async {
    var query = _client
        .from(AppConstants.shopRegistrationsTable)
        .select();

    if (statusFilter != null && statusFilter != 'all') {
      query = query.eq('status', statusFilter);
    }

    final rows = await query.order('submitted_at', ascending: false);
    return rows.map((row) => ShopRegistrationModel.fromJson(row)).toList();
  }

  Future<void> approveRegistration(String id) async {
    final now = DateTime.now().toUtc().toIso8601String();
    // Lấy user_id từ registration
    final reg = await _client
        .from(AppConstants.shopRegistrationsTable)
        .select('user_id')
        .eq('id', id)
        .single();
    final userId = reg['user_id'] as String;
    // Update trạng thái registration
    await _client
        .from(AppConstants.shopRegistrationsTable)
        .update({
          'status': 'approved',
          'reviewed_at': now,
          'updated_at': now,
        })
        .eq('id', id);
    // Update role + sellerStatus trong profiles table bằng RPC để tránh lỗi RLS recursion
    await _client.rpc('admin_update_seller_status', params: {
      'target_id': userId,
      'new_status': 'approved',
    });
  }

  Future<void> rejectRegistration(String id, String reason) async {
    final now = DateTime.now().toUtc().toIso8601String();
    await _client
        .from(AppConstants.shopRegistrationsTable)
        .update({
          'status': 'rejected',
          'rejection_reason': reason,
          'reviewed_at': now,
          'updated_at': now,
        })
        .eq('id', id);

    // Lấy user_id để update profile
    final reg = await _client
        .from(AppConstants.shopRegistrationsTable)
        .select('user_id')
        .eq('id', id)
        .single();
    final userId = reg['user_id'] as String;

    await _client.rpc('admin_update_seller_status', params: {
      'target_id': userId,
      'new_status': 'rejected',
    });
  }

  Future<String> _uploadImage(
    Uint8List bytes,
    String userId,
    String prefix,
    String ext,
  ) async {
    final path = 'shop_registrations/$userId/${prefix}_${DateTime.now().millisecondsSinceEpoch}.$ext';
    await _client.storage.from('shop-documents').uploadBinary(path, bytes);
    final url = _client.storage.from('shop-documents').getPublicUrl(path);
    return url;
  }
}
