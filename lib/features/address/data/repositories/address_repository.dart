import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/constants/app_constants.dart';
import '../models/address_model.dart';

class AddressRepository {
  const AddressRepository(this._client);

  final SupabaseClient _client;

  Future<List<AddressModel>> getAddresses(String userId) async {
    final rows = await _client
        .from(AppConstants.addressesTable)
        .select()
        .eq('user_id', userId)
        .order('is_default', ascending: false)
        .order('created_at', ascending: false);
    return rows.map((row) => AddressModel.fromJson(row)).toList();
  }

  Future<AddressModel?> getDefaultAddress(String userId) async {
    final row = await _client
        .from(AppConstants.addressesTable)
        .select()
        .eq('user_id', userId)
        .eq('is_default', true)
        .maybeSingle();
    return row == null ? null : AddressModel.fromJson(row);
  }

  Future<AddressModel?> getAddressById(String id) async {
    final row = await _client
        .from(AppConstants.addressesTable)
        .select()
        .eq('id', id)
        .maybeSingle();
    return row == null ? null : AddressModel.fromJson(row);
  }
}
