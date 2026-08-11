import 'package:hive_flutter/hive_flutter.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/result.dart';
import '../../services/supabase_service.dart';
import '../models/category_model.dart';

class CategoryRepository {
  const CategoryRepository();

  /// Fetch all active categories. Returns from Hive cache if fresh.
  Future<Result<List<CategoryModel>>> getCategories({
    bool forceRefresh = false,
  }) async {
    try {
      final box = Hive.box(AppConstants.categoryCacheBox);
      final cachedAt = box.get('categories_cached_at') as DateTime?;
      final cachedData = box.get('categories') as List?;

      if (!forceRefresh &&
          cachedAt != null &&
          cachedData != null &&
          DateTime.now().difference(cachedAt) < AppConstants.categoryCacheDuration) {
        final models = cachedData
            .cast<Map<dynamic, dynamic>>()
            .map((e) => CategoryModel.fromJson(Map<String, dynamic>.from(e)))
            .toList();
        return Success(models);
      }

      final response = await SupabaseService.table('categories')
          .select('*')
          .eq('is_active', true)
          .order('name');

      final categories = (response as List)
          .map((e) => CategoryModel.fromJson(e as Map<String, dynamic>))
          .toList();

      // Cache locally
      await box.put('categories', response);
      await box.put('categories_cached_at', DateTime.now());

      return Success(categories);
    } catch (e) {
      return Failure('Failed to load categories: $e', error: e);
    }
  }

  Future<Result<CategoryModel>> getCategoryBySlug(String slug) async {
    try {
      final response = await SupabaseService.table('categories')
          .select('*')
          .eq('slug', slug)
          .eq('is_active', true)
          .single();

      return Success(CategoryModel.fromJson(response));
    } catch (e) {
      return Failure('Category not found', error: e);
    }
  }
}
