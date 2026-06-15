import '../../../../core/errors/error_handler.dart';
import '../../../../core/services/supabase_auth_service.dart';
import '../../../../core/services/supabase_database_service.dart';
import '../models/address_model.dart';

const _addressTable = 'addresses';

class AddressRepository {
  AddressRepository(this._authService, this._databaseService);

  final SupabaseAuthService _authService;
  final SupabaseDatabaseService _databaseService;

  Future<List<AddressModel>> getAddresses() async {
    final authUser = _authService.currentUser;
    if (authUser == null) throw Exception('Bạn cần đăng nhập trước');

    final rows = await _databaseService
        .table(_addressTable)
        .select()
        .eq('user_id', authUser.id)
        .order('is_default', ascending: false)
        .order('created_at', ascending: false);

    return rows
        .map((r) => AddressModel.fromJson(Map<String, dynamic>.from(r)))
        .toList();
  }

  Future<AddressModel?> getDefaultAddress() async {
    final authUser = _authService.currentUser;
    if (authUser == null) return null;

    final rows = await _databaseService
        .table(_addressTable)
        .select()
        .eq('user_id', authUser.id)
        .eq('is_default', true)
        .limit(1);

    if (rows.isEmpty) return null;
    return AddressModel.fromJson(Map<String, dynamic>.from(rows.first));
  }

  Future<AddressModel> createAddress(AddressModel address) async {
    if (_authService.currentUser == null) {
      throw Exception('Bạn cần đăng nhập trước');
    }

    final userId = _authService.currentUser!.id;
    final inserted = await guardSupabase(() async {
      if (address.isDefault) {
        await _databaseService
            .table(_addressTable)
            .update({'is_default': false})
            .eq('user_id', userId);
      }
      return await _databaseService.insert(_addressTable, address.toInsertJson());
    });
    return AddressModel.fromJson(inserted);
  }

  Future<AddressModel> updateAddress(AddressModel address) async {
    if (_authService.currentUser == null) {
      throw Exception('Bạn cần đăng nhập trước');
    }

    final updated = await guardSupabase(() async {
      if (address.isDefault) {
        await _databaseService
            .table(_addressTable)
            .update({'is_default': false})
            .eq('user_id', _authService.currentUser!.id)
            .neq('id', address.id);
      }
      return await _databaseService.updateById(
        _addressTable,
        address.id,
        address.toUpdateJson(),
      );
    });
    return AddressModel.fromJson(updated);
  }

  Future<void> deleteAddress(String addressId) async {
    if (_authService.currentUser == null) {
      throw Exception('Bạn cần đăng nhập trước');
    }

    await guardSupabase(
      () => _databaseService.deleteById(_addressTable, addressId),
    );
  }

  Future<void> setDefaultAddress(String addressId) async {
    final authUser = _authService.currentUser;
    if (authUser == null) throw Exception('Bạn cần đăng nhập trước');

    await guardSupabase(() async {
      await _databaseService
          .table(_addressTable)
          .update({'is_default': false})
          .eq('user_id', authUser.id);
      await _databaseService
          .table(_addressTable)
          .update({'is_default': true, 'updated_at': DateTime.now().toUtc().toIso8601String()})
          .eq('id', addressId);
    });
  }
}
