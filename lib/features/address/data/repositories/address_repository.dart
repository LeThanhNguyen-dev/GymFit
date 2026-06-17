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

  Future<AddressModel> createAddress(AddressModel address) async {
    final data = address.toJson();
    data.remove('id');
    data.remove('created_at');
    data.remove('updated_at');
    final row = await _client
        .from(AppConstants.addressesTable)
        .insert(data)
        .select()
        .single();
    return AddressModel.fromJson(row);
  }

  Future<AddressModel> updateAddress(AddressModel address) async {
    final data = address.toJson();
    data.remove('id');
    data.remove('user_id');
    data.remove('created_at');
    final row = await _client
        .from(AppConstants.addressesTable)
        .update(data)
        .eq('id', address.id)
        .select()
        .single();
    return AddressModel.fromJson(row);
  }

  Future<void> deleteAddress(String id) async {
    await _client.from(AppConstants.addressesTable).delete().eq('id', id);
  }

  Future<void> setDefaultAddress(String id, String userId) async {
    await _client.from(AppConstants.addressesTable).update({
      'is_default': false,
    }).eq('user_id', userId).neq('id', id);
    await _client.from(AppConstants.addressesTable).update({
      'is_default': true,
    }).eq('id', id);
  }
}
