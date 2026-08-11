import 'package:dio/dio.dart';
import '../core/config/env.dart';
import '../core/constants/nutrient_constants.dart';
import '../core/utils/result.dart';

/// Data returned from OpenFoodFacts after a barcode lookup.
/// This is used to pre-fill the admin product form — NOT stored directly.
class OFFProductData {
  const OFFProductData({
    required this.barcode,
    this.name,
    this.brandName,
    this.categories,
    this.ingredients,
    this.allergens,
    this.imageUrl,
    this.servingSize,
    this.nutrients = const {},
  });

  final String barcode;
  final String? name;
  final String? brandName;
  final String? categories;
  final String? ingredients;
  final List<String>? allergens;
  final String? imageUrl;
  final String? servingSize;

  /// Map of our nutrient slug → per-100g value.
  final Map<String, double> nutrients;
}

class OpenFoodFactsService {
  OpenFoodFactsService() {
    _dio = Dio(
      BaseOptions(
        baseUrl: Env.offBaseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 15),
        headers: {
          'User-Agent': Env.offUserAgent,
        },
      ),
    );
  }

  late final Dio _dio;

  /// Fetch product data by barcode from OpenFoodFacts.
  Future<Result<OFFProductData>> fetchByBarcode(String barcode) async {
    try {
      final response = await _dio.get(
        '/product/$barcode.json',
        queryParameters: {
          'fields':
              'product_name,brands,categories,ingredients_text,'
              'allergens_tags,image_front_url,serving_size,nutriments',
        },
      );

      final body = response.data as Map<String, dynamic>;
      final status = body['status'];

      if (status == 0 || body['product'] == null) {
        return Failure('Product not found in OpenFoodFacts');
      }

      final product = body['product'] as Map<String, dynamic>;
      final nutriments = product['nutriments'] as Map<String, dynamic>? ?? {};

      // Map nutriments to our nutrient slugs
      final nutrients = <String, double>{};
      offNutrimentKeyMap.forEach((offKey, ourSlug) {
        // Prefer _100g suffix keys; fall back to plain key
        final key100 = offKey.endsWith('_100g') ? offKey : '${offKey}_100g';
        final value = nutriments[key100] ?? nutriments[offKey];
        if (value != null) {
          final d = (value as num).toDouble();
          // Only set if we haven't already stored a value for this slug
          if (!nutrients.containsKey(ourSlug)) {
            nutrients[ourSlug] = d;
          }
        }
      });

      // Allergens come as tags like 'en:gluten', 'en:milk'
      final allergenTags =
          (product['allergens_tags'] as List?)?.cast<String>() ?? [];
      final allergens = allergenTags
          .map((t) => t.contains(':') ? t.split(':').last : t)
          .map((t) => t.replaceAll('-', ' ').trim())
          .where((t) => t.isNotEmpty)
          .toList();

      return Success(OFFProductData(
        barcode: barcode,
        name: product['product_name'] as String?,
        brandName: product['brands'] as String?,
        categories: product['categories'] as String?,
        ingredients: product['ingredients_text'] as String?,
        allergens: allergens.isEmpty ? null : allergens,
        imageUrl: product['image_front_url'] as String?,
        servingSize: product['serving_size'] as String?,
        nutrients: nutrients,
      ));
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        return Failure('OpenFoodFacts request timed out');
      }
      return Failure('OpenFoodFacts error: ${e.message}', error: e);
    } catch (e) {
      return Failure('Unexpected error: $e', error: e);
    }
  }
}
