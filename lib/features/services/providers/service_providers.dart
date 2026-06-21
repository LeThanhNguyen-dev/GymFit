import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/supabase_providers.dart';
import '../data/models/service_model.dart';
import '../data/service_repository.dart';

final serviceRepositoryProvider = Provider<ServiceRepository>((ref) {
  return ServiceRepository(ref.watch(supabaseClientProvider));
});

final serviceListProvider = FutureProvider<List<ServiceModel>>((ref) {
  return ref.watch(serviceRepositoryProvider).getServices();
});

final serviceBySlugProvider =
    FutureProvider.family<ServiceModel?, String>((ref, slug) {
  return ref.watch(serviceRepositoryProvider).getServiceBySlug(slug);
});
