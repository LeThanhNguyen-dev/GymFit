import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/supabase_providers.dart';
import '../../auth/providers/auth_providers.dart';
import '../data/models/shop_registration_model.dart';
import '../data/repositories/shop_registration_repository.dart';

final shopRegistrationRepositoryProvider = Provider<ShopRegistrationRepository>(
  (ref) => ShopRegistrationRepository(ref.watch(supabaseClientProvider)),
);

final myShopRegistrationProvider = FutureProvider.autoDispose<ShopRegistrationModel?>(
  (ref) async {
    final user = ref.watch(authProvider).user;
    if (user == null) return null;
    final repo = ref.read(shopRegistrationRepositoryProvider);
    return repo.getRegistrationStatus(user.id);
  },
);

final allShopRegistrationsProvider = FutureProvider.autoDispose<List<ShopRegistrationModel>>(
  (ref) {
    final repo = ref.read(shopRegistrationRepositoryProvider);
    return repo.getAllRegistrations();
  },
);

final shopRegistrationsByStatusProvider = FutureProvider.autoDispose.family<List<ShopRegistrationModel>, String>(
  (ref, status) {
    final repo = ref.read(shopRegistrationRepositoryProvider);
    return repo.getAllRegistrations(statusFilter: status);
  },
);
