import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/supabase_providers.dart';

final isAdminProvider = Provider<bool>((ref) {
  final user = ref.watch(supabaseClientProvider).auth.currentUser;
  final metadata = {...?user?.appMetadata, ...?user?.userMetadata};
  return metadata['role'] == 'admin' || metadata['is_admin'] == true;
});

final adminGuardProvider = Provider<bool>((ref) {
  return ref.watch(isAdminProvider);
});
