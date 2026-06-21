import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/banner_model.dart';

class BannerRepository {
  const BannerRepository(this._client);
  final SupabaseClient _client;

  Future<List<BannerModel>> getBanners({String position = 'home'}) async {
    final now = DateTime.now().toUtc().toIso8601String();

    final rows = await _client
        .from('banners')
        .select()
        .eq('is_active', true)
        .eq('position', position)
        .or('start_date.is.null,start_date.lte.$now')
        .or('end_date.is.null,end_date.gte.$now')
        .order('sort_order');

    return rows.map((row) => BannerModel.fromJson(row)).toList();
  }

  Future<BannerModel?> getBannerById(String id) async {
    try {
      final row = await _client
          .from('banners')
          .select()
          .eq('id', id)
          .single();
      return BannerModel.fromJson(row);
    } catch (_) {
      return null;
    }
  }
}
