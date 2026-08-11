import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/utils/result.dart';
import '../../data/models/category_model.dart';
import 'providers.dart';

/// All active categories (cached in Hive for 24h).
final categoriesProvider =
    FutureProvider.autoDispose<List<CategoryModel>>((ref) async {
  final repo = ref.watch(categoryRepositoryProvider);
  final result = await repo.getCategories();
  return result.when(
    success: (data) => data,
    failure: (msg, _) => throw Exception(msg),
  );
});

/// Category by slug — for category detail page.
final categoryBySlugProvider = FutureProvider.autoDispose
    .family<CategoryModel, String>((ref, slug) async {
  final repo = ref.watch(categoryRepositoryProvider);
  final result = await repo.getCategoryBySlug(slug);
  return result.when(
    success: (data) => data,
    failure: (msg, _) => throw Exception(msg),
  );
});
