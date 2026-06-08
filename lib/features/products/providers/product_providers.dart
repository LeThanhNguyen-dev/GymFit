import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/supabase_providers.dart';
import '../data/repositories/product_repository.dart';

final productRepositoryProvider = Provider<ProductRepository>((ref) {
  return ProductRepository(ref.watch(supabaseClientProvider));
});
