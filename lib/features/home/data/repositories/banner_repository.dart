import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/banner_model.dart';

class BannerRepository {
  const BannerRepository(this._client);
  final SupabaseClient _client;

  Future<List<BannerModel>> getBanners() async {
    try {
      final rows = await _client
          .from('banners')
          .select()
          .eq('is_active', true)
          .order('sort_order');
      
      return rows.map((row) => BannerModel.fromJson(row)).toList();
    } catch (e) {
      // Fallback in case table doesn't exist yet in user's DB
      return _getMockBanners();
    }
  }

  List<BannerModel> _getMockBanners() {
    return const [
      BannerModel(
        id: '1',
        title: 'Bộ sưu tập Hè 2026',
        subtitle: 'Giảm đến 40%',
        gradientStart: '#667EEA',
        gradientEnd: '#764BA2',
        iconName: 'fitness_center',
        targetRoute: '/products',
      ),
      BannerModel(
        id: '2',
        title: 'Nike & Adidas',
        subtitle: 'Thương hiệu hàng đầu',
        gradientStart: '#FF6B6B',
        gradientEnd: '#EE5A24',
        iconName: 'sports_gymnastics',
        targetRoute: '/products',
      ),
      BannerModel(
        id: '3',
        title: 'Thực phẩm bổ sung',
        subtitle: 'Tăng cơ, giảm mỡ',
        gradientStart: '#11998E',
        gradientEnd: '#38EF7D',
        iconName: 'local_pharmacy_outlined',
        targetRoute: '/products',
      ),
    ];
  }
}
