import '../../core/constants/app_constants.dart';
import '../../core/utils/result.dart';
import '../../services/supabase_service.dart';
import '../models/product_model.dart';
import '../models/product_request_model.dart';

class FoodRepository {
  const FoodRepository();

  // ── Product detail ───────────────────────────────────────────────────────

  Future<Result<ProductModel>> getProductById(String id) async {
    try {
      final response = await SupabaseService.table('products')
          .select('''
            *,
            brand:brands(*),
            category:categories!products_category_id_fkey(*),
            product_nutrients(
              *,
              nutrient:nutrients(*)
            )
          ''')
          .eq('id', id)
          .eq('is_published', true)
          .single();

      return Success(ProductModel.fromJson(response));
    } catch (e) {
      return Failure('Product not found', error: e);
    }
  }

  Future<Result<ProductModel>> getProductBySlug(String slug) async {
    try {
      final response = await SupabaseService.table('products')
          .select('''
            *,
            brand:brands(*),
            category:categories!products_category_id_fkey(*),
            product_nutrients(
              *,
              nutrient:nutrients(*)
            )
          ''')
          .eq('slug', slug)
          .eq('is_published', true)
          .single();

      return Success(ProductModel.fromJson(response));
    } catch (e) {
      return Failure('Product not found', error: e);
    }
  }

  Future<Result<ProductModel>> getProductByBarcode(String barcode) async {
    try {
      final response = await SupabaseService.table('products')
          .select('''
            *,
            brand:brands(*),
            category:categories!products_category_id_fkey(*),
            product_nutrients(
              *,
              nutrient:nutrients(*)
            )
          ''')
          .eq('barcode', barcode)
          .eq('is_published', true)
          .maybeSingle();

      if (response == null) {
        return Failure('Product not found for barcode $barcode');
      }

      return Success(ProductModel.fromJson(response));
    } catch (e) {
      return Failure('Lookup failed: $e', error: e);
    }
  }

  // ── Product list by category ─────────────────────────────────────────────

  Future<Result<List<ProductModel>>> getProductsByCategory({
    required String categoryId,
    int page = 0,
    int pageSize = AppConstants.pageSize,
    String? sortColumn,
    bool ascending = true,
  }) async {
    try {
      var query = SupabaseService.table('products')
          .select('''
            *,
            brand:brands(id, name, logo_url),
            category:categories!products_category_id_fkey(id, name, slug),
            product_nutrients(
              *,
              nutrient:nutrients(*)
            )
          ''')
          .eq('category_id', categoryId)
          .eq('is_published', true);

      final response = await query
          .order(sortColumn ?? 'name', ascending: ascending)
          .range(page * pageSize, (page + 1) * pageSize - 1);

      final products = (response as List)
          .map((e) => ProductModel.fromJson(e as Map<String, dynamic>))
          .toList();

      return Success(products);
    } catch (e) {
      return Failure('Failed to load products: $e', error: e);
    }
  }

  // ── Multiple products by IDs (for comparison) ────────────────────────────

  Future<Result<List<ProductModel>>> getProductsByIds(
    List<String> ids,
  ) async {
    try {
      final response = await SupabaseService.table('products')
          .select('''
            *,
            brand:brands(*),
            category:categories!products_category_id_fkey(*),
            product_nutrients(
              *,
              nutrient:nutrients(*)
            )
          ''')
          .inFilter('id', ids)
          .eq('is_published', true);

      final products = (response as List)
          .map((e) => ProductModel.fromJson(e as Map<String, dynamic>))
          .toList();

      return Success(products);
    } catch (e) {
      return Failure('Failed to load products for comparison: $e', error: e);
    }
  }

  // ── Submit product request ────────────────────────────────────────────────

  Future<Result<void>> submitProductRequest(
    ProductRequestModel request,
  ) async {
    try {
      await SupabaseService.table('product_requests')
          .insert(request.toInsertJson());
      return const Success(null);
    } catch (e) {
      return Failure('Failed to submit request: $e', error: e);
    }
  }
}
