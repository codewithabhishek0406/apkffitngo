import '../../core/constants/app_constants.dart';
import '../../core/utils/result.dart';
import '../../services/supabase_service.dart';
import '../models/product_model.dart';
import '../models/search_filter_model.dart';

class SearchResult {
  const SearchResult({
    required this.products,
    required this.totalCount,
    required this.hasMore,
  });

  final List<ProductModel> products;
  final int totalCount;
  final bool hasMore;
}

class SearchRepository {
  const SearchRepository();

  Future<Result<SearchResult>> search(SearchFilterModel filter) async {
    try {
      final offset = filter.page * AppConstants.pageSize;

      final response = await SupabaseService.client.rpc(
        'search_products',
        params: {
          'p_query': filter.query,
          'p_category_id': filter.categoryId,
          'p_brand_id': filter.brandId,
          'p_diet_type': filter.dietType?.name,
          'p_min_calories': filter.minCalories,
          'p_max_calories': filter.maxCalories,
          'p_min_protein': filter.minProtein,
          'p_max_protein': filter.maxProtein,
          'p_min_sugar': filter.minSugar,
          'p_max_sugar': filter.maxSugar,
          'p_limit': AppConstants.pageSize,
          'p_offset': offset,
        },
      );

      final rows = response as List;
      if (rows.isEmpty) {
        return const Success(
          SearchResult(products: [], totalCount: 0, hasMore: false),
        );
      }

      final totalCount = (rows.first['total_count'] as int?) ?? rows.length;

      final products = rows.map((row) {
        // The RPC returns flat columns; map to ProductModel shape
        final map = row as Map<String, dynamic>;
        return ProductModel.fromJson({
          'id': map['id'],
          'name': map['name'],
          'slug': map['slug'],
          'barcode': map['barcode'],
          'image_url': map['image_url'],
          'diet_type': map['diet_type'],
          'verification_status': map['verification_status'],
          'serving_size': map['serving_size'],
          'serving_unit': map['serving_unit'],
          'is_published': true,
          'brand': map['brand_id'] != null
              ? {
                  'id': map['brand_id'],
                  'name': map['brand_name'],
                  'logo_url': map['brand_logo'],
                }
              : null,
          'category': map['category_id'] != null
              ? {
                  'id': map['category_id'],
                  'name': map['category_name'],
                  'slug': map['category_slug'],
                }
              : null,
          // Nutrient summary for card display
          'product_nutrients': _buildNutrientList(map),
        });
      }).toList();

      return Success(SearchResult(
        products: products,
        totalCount: totalCount,
        hasMore: offset + products.length < totalCount,
      ));
    } catch (e) {
      return Failure('Search failed: $e', error: e);
    }
  }

  List<Map<String, dynamic>> _buildNutrientList(
    Map<String, dynamic> row,
  ) {
    final result = <Map<String, dynamic>>[];
    final nutrientMap = {
      'energy_kcal': row['calories_per_100g'],
      'protein': row['protein_per_100g'],
      'sugar': row['sugar_per_100g'],
    };

    nutrientMap.forEach((slug, value) {
      if (value != null) {
        result.add({
          'id': slug,
          'product_id': row['id'],
          'nutrient_id': slug,
          'value_per_100g': value,
          'nutrient': {'id': slug, 'name': slug, 'slug': slug, 'unit': ''},
        });
      }
    });
    return result;
  }
}
