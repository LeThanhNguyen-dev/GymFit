import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/models/product_model.dart';

class ProductCacheService {
  ProductCacheService(this._prefs, this._connectivity);

  final SharedPreferences _prefs;
  final Connectivity _connectivity;

  static const String _featuredKey = 'cache_featured_products';
  static const String _newArrivalsKey = 'cache_new_arrivals';
  static const String _recommendedKey = 'cache_recommended_products';

  Future<bool> isOffline() async {
    final result = await _connectivity.checkConnectivity();
    return result.contains(ConnectivityResult.none);
  }

  Future<void> saveFeatured(List<ProductModel> products) async {
    final jsonList = products.map((p) => p.toJson()).toList();
    await _prefs.setString(_featuredKey, jsonEncode(jsonList));
  }

  List<ProductModel>? getFeatured() {
    final data = _prefs.getString(_featuredKey);
    if (data == null) return null;
    try {
      final List<dynamic> decoded = jsonDecode(data);
      return decoded.map((json) => ProductModel.fromJson(json)).toList();
    } catch (_) {
      return null;
    }
  }

  Future<void> saveNewArrivals(List<ProductModel> products) async {
    final jsonList = products.map((p) => p.toJson()).toList();
    await _prefs.setString(_newArrivalsKey, jsonEncode(jsonList));
  }

  List<ProductModel>? getNewArrivals() {
    final data = _prefs.getString(_newArrivalsKey);
    if (data == null) return null;
    try {
      final List<dynamic> decoded = jsonDecode(data);
      return decoded.map((json) => ProductModel.fromJson(json)).toList();
    } catch (_) {
      return null;
    }
  }

  Future<void> saveRecommended(List<ProductModel> products) async {
    final jsonList = products.map((p) => p.toJson()).toList();
    await _prefs.setString(_recommendedKey, jsonEncode(jsonList));
  }

  List<ProductModel>? getRecommended() {
    final data = _prefs.getString(_recommendedKey);
    if (data == null) return null;
    try {
      final List<dynamic> decoded = jsonDecode(data);
      return decoded.map((json) => ProductModel.fromJson(json)).toList();
    } catch (_) {
      return null;
    }
  }
}
