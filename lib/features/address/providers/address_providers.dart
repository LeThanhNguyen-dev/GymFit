import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/supabase_providers.dart';
import '../data/models/address_model.dart';
import '../data/repositories/address_repository.dart';

final addressRepositoryProvider = Provider<AddressRepository>((ref) {
  return AddressRepository(ref.watch(supabaseClientProvider));
});

final userAddressesProvider = FutureProvider<List<AddressModel>>((ref) {
  final user = ref.watch(supabaseClientProvider).auth.currentUser;
  if (user == null) return const <AddressModel>[];
  return ref.watch(addressRepositoryProvider).getAddresses(user.id);
});

final defaultAddressProvider = FutureProvider<AddressModel?>((ref) {
  final user = ref.watch(supabaseClientProvider).auth.currentUser;
  if (user == null) return null;
  return ref.watch(addressRepositoryProvider).getDefaultAddress(user.id);
});
