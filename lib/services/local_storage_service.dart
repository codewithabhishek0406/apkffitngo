import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import '../core/constants/app_constants.dart';
import '../data/models/product_model.dart';

/// Handles all Hive-based local storage operations.
class LocalStorageService {
  const LocalStorageService();

  // ── Favorites ─────────────────────────────────────────────────────────────

  Box get _favBox => Hive.box(AppConstants.favoritesBox);

  bool isFavorite(String productId) => _favBox.containsKey(productId);

  Future<void> addFavorite(ProductModel product) async {
    await _favBox.put(product.id, jsonEncode(_productToMap(product)));
  }

  Future<void> removeFavorite(String productId) async {
    await _favBox.delete(productId);
  }

  List<ProductModel> getFavorites() {
    return _favBox.values
        .map((v) {
          try {
            final map = jsonDecode(v as String) as Map<String, dynamic>;
            return ProductModel.fromJson(map);
          } catch (_) {
            return null;
          }
        })
        .whereType<ProductModel>()
        .toList();
  }

  // ── Recent Products ────────────────────────────────────────────────────────

  Box get _recentBox => Hive.box(AppConstants.recentProductsBox);

  Future<void> addRecentProduct(ProductModel product) async {
    await _recentBox.delete(product.id); // remove old position
    await _recentBox.put(product.id, jsonEncode(_productToMap(product)));

    // Trim to max
    if (_recentBox.length > AppConstants.maxRecentProducts) {
      final firstKey = _recentBox.keys.first;
      await _recentBox.delete(firstKey);
    }
  }

  List<ProductModel> getRecentProducts() {
    return _recentBox.values.toList().reversed
        .map((v) {
          try {
            final map = jsonDecode(v as String) as Map<String, dynamic>;
            return ProductModel.fromJson(map);
          } catch (_) {
            return null;
          }
        })
        .whereType<ProductModel>()
        .take(AppConstants.maxRecentProducts)
        .toList();
  }

  // ── Recent Searches ────────────────────────────────────────────────────────

  Box get _searchBox => Hive.box(AppConstants.recentSearchesBox);

  Future<void> addRecentSearch(String query) async {
    if (query.trim().isEmpty) return;
    await _searchBox.delete(query); // avoid duplicates
    await _searchBox.put(query, DateTime.now().toIso8601String());

    if (_searchBox.length > AppConstants.maxRecentSearches) {
      await _searchBox.delete(_searchBox.keys.first);
    }
  }

  List<String> getRecentSearches() {
    return _searchBox.keys.cast<String>().toList().reversed.toList();
  }

  Future<void> clearRecentSearches() async {
    await _searchBox.clear();
  }

  Future<void> removeRecentSearch(String query) async {
    await _searchBox.delete(query);
  }

  // ── Comparison list ────────────────────────────────────────────────────────

  Box get _settingsBox => Hive.box(AppConstants.settingsBox);

  List<String> getComparisonIds() {
    final raw = _settingsBox.get('comparison_ids');
    if (raw == null) return [];
    return List<String>.from(jsonDecode(raw as String) as List);
  }

  Future<void> saveComparisonIds(List<String> ids) async {
    await _settingsBox.put('comparison_ids', jsonEncode(ids));
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  Map<String, dynamic> _productToMap(ProductModel p) => {
        'id': p.id,
        'name': p.name,
        'slug': p.slug,
        'image_url': p.imageUrl,
        'diet_type': p.dietType.name,
        'verification_status': p.verificationStatus.label.toLowerCase(),
        'is_published': p.isPublished,
        'brand': p.brand != null
            ? {'id': p.brand!.id, 'name': p.brand!.name, 'logo_url': p.brand!.logoUrl}
            : null,
        'category': p.category != null
            ? {'id': p.category!.id, 'name': p.category!.name, 'slug': p.category!.slug}
            : null,
        'serving_size': p.servingSize,
        'serving_unit': p.servingUnit,
        'product_nutrients': p.nutrients
            .map((n) => {
                  'id': n.id,
                  'product_id': n.productId,
                  'nutrient_id': n.nutrientId,
                  'value_per_100g': n.valuePer100g,
                  'value_per_serving': n.valuePerServing,
                  'nutrient': {
                    'id': n.nutrient.id,
                    'name': n.nutrient.name,
                    'slug': n.nutrient.slug,
                    'unit': n.nutrient.unit,
                    'display_order': n.nutrient.displayOrder,
                  },
                })
            .toList(),
      };

  static Future<void> initBoxes() async {
    await Hive.initFlutter();
    await Future.wait([
      Hive.openBox(AppConstants.favoritesBox),
      Hive.openBox(AppConstants.recentProductsBox),
      Hive.openBox(AppConstants.recentSearchesBox),
      Hive.openBox(AppConstants.settingsBox),
      Hive.openBox(AppConstants.categoryCacheBox),
    ]);
  }
}
