import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/supabase_providers.dart';
import '../data/models/profile_model.dart';
import '../data/repositories/profile_repository.dart';

// ── Repository Providers ──

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepository(
    ref.watch(supabaseAuthServiceProvider),
    ref.watch(supabaseDatabaseServiceProvider),
    ref.watch(supabaseStorageServiceProvider),
  );
});

// ── Profile Providers ──

final profileProvider = FutureProvider<ProfileModel>((ref) async {
  final repo = ref.watch(profileRepositoryProvider);
  return repo.getProfile();
});

