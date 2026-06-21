import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/constants/app_constants.dart';
import 'models/service_model.dart';

class ServiceRepository {
  const ServiceRepository(this._client);

  final SupabaseClient _client;

  Future<List<ServiceModel>> getServices() async {
    final rows = await _client
        .from(AppConstants.servicesTable)
        .select()
        .eq('is_active', true)
        .order('sort_order');

    return rows.map((row) => ServiceModel.fromJson(row)).toList();
  }

  Future<ServiceModel?> getServiceBySlug(String slug) async {
    final row = await _client
        .from(AppConstants.servicesTable)
        .select()
        .eq('slug', slug)
        .maybeSingle();

    return row == null ? null : ServiceModel.fromJson(row);
  }
}
