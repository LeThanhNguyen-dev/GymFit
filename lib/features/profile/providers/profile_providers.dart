import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/supabase_providers.dart';
import '../data/models/address_model.dart';
import '../data/models/profile_model.dart';
import '../data/repositories/address_repository.dart';
import '../data/repositories/profile_repository.dart';

// ── Repository Providers ──

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepository(
    ref.watch(supabaseAuthServiceProvider),
    ref.watch(supabaseDatabaseServiceProvider),
    ref.watch(supabaseStorageServiceProvider),
  );
});

final addressRepositoryProvider = Provider<AddressRepository>((ref) {
  return AddressRepository(
    ref.watch(supabaseAuthServiceProvider),
    ref.watch(supabaseDatabaseServiceProvider),
  );
});

// ── Profile Providers ──

final profileProvider = FutureProvider<ProfileModel>((ref) async {
  final repo = ref.watch(profileRepositoryProvider);
  return repo.getProfile();
});

// ── Address Providers ──

final addressListProvider =
    FutureProvider.autoDispose<List<AddressModel>>((ref) async {
  final repo = ref.watch(addressRepositoryProvider);
  return repo.getAddresses();
});

final defaultAddressProvider =
    FutureProvider.autoDispose<AddressModel?>((ref) async {
  final repo = ref.watch(addressRepositoryProvider);
  return repo.getDefaultAddress();
});
