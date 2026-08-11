import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/utils/result.dart';
import '../../data/models/product_model.dart';
import 'providers.dart';

// ── Product detail ─────────────────────────────────────────────────────────

final productByIdProvider =
    FutureProvider.autoDispose.family<ProductModel, String>((ref, id) async {
  final repo = ref.watch(foodRepositoryProvider);
  final result = await repo.getProductById(id);
  return result.when(
    success: (data) => data,
    failure: (msg, _) => throw Exception(msg),
  );
});

final productBySlugProvider =
    FutureProvider.autoDispose.family<ProductModel, String>((ref, slug) async {
  final repo = ref.watch(foodRepositoryProvider);
  final result = await repo.getProductBySlug(slug);
  return result.when(
    success: (data) => data,
    failure: (msg, _) => throw Exception(msg),
  );
});

// ── Products by category ───────────────────────────────────────────────────

class CategoryProductsParams {
  const CategoryProductsParams({
    required this.categoryId,
    this.sortColumn,
    this.ascending = true,
    this.page = 0,
  });
  final String categoryId;
  final String? sortColumn;
  final bool ascending;
  final int page;

  @override
  bool operator ==(Object other) =>
      other is CategoryProductsParams &&
      other.categoryId == categoryId &&
      other.sortColumn == sortColumn &&
      other.ascending == ascending &&
      other.page == page;

  @override
  int get hashCode => Object.hash(categoryId, sortColumn, ascending, page);
}

final categoryProductsProvider = FutureProvider.autoDispose
    .family<List<ProductModel>, CategoryProductsParams>((ref, params) async {
  final repo = ref.watch(foodRepositoryProvider);
  final result = await repo.getProductsByCategory(
    categoryId: params.categoryId,
    page: params.page,
    sortColumn: params.sortColumn,
    ascending: params.ascending,
  );
  return result.when(
    success: (data) => data,
    failure: (msg, _) => throw Exception(msg),
  );
});

// ── Barcode lookup ─────────────────────────────────────────────────────────

final productByBarcodeProvider =
    FutureProvider.autoDispose.family<ProductModel?, String>(
        (ref, barcode) async {
  final repo = ref.watch(foodRepositoryProvider);
  final result = await repo.getProductByBarcode(barcode);
  return result.when(
    success: (data) => data,
    failure: (_, __) => null,
  );
});

// ── Comparison ─────────────────────────────────────────────────────────────

final comparisonIdsProvider =
    StateNotifierProvider<ComparisonNotifier, List<String>>(
  (ref) => ComparisonNotifier(ref),
);

class ComparisonNotifier extends StateNotifier<List<String>> {
  ComparisonNotifier(this._ref) : super([]) {
    _load();
  }

  final Ref _ref;

  void _load() {
    state = _ref.read(localStorageServiceProvider).getComparisonIds();
  }

  Future<void> toggle(String productId) async {
    if (state.contains(productId)) {
      state = state.where((id) => id != productId).toList();
    } else if (state.length < 3) {
      state = [...state, productId];
    }
    await _ref.read(localStorageServiceProvider).saveComparisonIds(state);
  }

  Future<void> clear() async {
    state = [];
    await _ref.read(localStorageServiceProvider).saveComparisonIds([]);
  }

  bool isInComparison(String productId) => state.contains(productId);
}

final comparisonProductsProvider =
    FutureProvider.autoDispose<List<ProductModel>>((ref) async {
  final ids = ref.watch(comparisonIdsProvider);
  if (ids.isEmpty) return [];
  final repo = ref.watch(foodRepositoryProvider);
  final result = await repo.getProductsByIds(ids);
  return result.when(
    success: (data) => data,
    failure: (msg, _) => throw Exception(msg),
  );
});

// ── Quantity calculator ────────────────────────────────────────────────────

final quantityGramsProvider =
    StateProvider.autoDispose<double>((ref) => 100.0);

// ── Serving toggle ─────────────────────────────────────────────────────────

final showPerServingProvider =
    StateProvider.autoDispose<bool>((ref) => false);
