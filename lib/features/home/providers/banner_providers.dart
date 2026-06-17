import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/models/banner_model.dart';
import '../data/repositories/banner_repository.dart';

final bannerRepositoryProvider = Provider<BannerRepository>((ref) {
  return BannerRepository(Supabase.instance.client);
});

final bannerListProvider = FutureProvider.autoDispose<List<BannerModel>>((ref) {
  final repository = ref.watch(bannerRepositoryProvider);
  return repository.getBanners();
});
