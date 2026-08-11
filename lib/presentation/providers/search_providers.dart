import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/utils/result.dart';
import '../../data/models/product_model.dart';
import '../../data/models/search_filter_model.dart';
import 'providers.dart';

// ── Filter state ───────────────────────────────────────────────────────────

final searchFilterProvider =
    StateNotifierProvider.autoDispose<SearchFilterNotifier, SearchFilterModel>(
  (ref) => SearchFilterNotifier(),
);

class SearchFilterNotifier extends StateNotifier<SearchFilterModel> {
  SearchFilterNotifier() : super(const SearchFilterModel());

  void setQuery(String q) => state = state.copyWith(query: q, page: 0);

  void setCategory(String? id) =>
      state = state.copyWith(categoryId: id, page: 0, clearCategoryId: id == null);

  void setSort(SortOption sort) => state = state.copyWith(sortBy: sort, page: 0);

  void setDietType(DietType? type) =>
      state = state.copyWith(dietType: type, page: 0, clearDietType: type == null);

  void setCalorieRange(double? min, double? max) =>
      state = state.copyWith(minCalories: min, maxCalories: max, page: 0);

  void setProteinRange(double? min, double? max) =>
      state = state.copyWith(minProtein: min, maxProtein: max, page: 0);

  void setSugarRange(double? min, double? max) =>
      state = state.copyWith(minSugar: min, maxSugar: max, page: 0);

  void nextPage() => state = state.copyWith(page: state.page + 1);

  void resetFilters() => state = state.resetFilters();

  void reset() => state = const SearchFilterModel();

  void updateFilter(SearchFilterModel newFilter) => state = newFilter;
}

// ── Search results ─────────────────────────────────────────────────────────

final searchResultsProvider =
    FutureProvider.autoDispose.family<SearchResultPage, SearchFilterModel>(
  (ref, filter) async {
    final repo = ref.watch(searchRepositoryProvider);
    final result = await repo.search(filter);
    return result.when(
      success: (data) => SearchResultPage(
        products: data.products,
        totalCount: data.totalCount,
        hasMore: data.hasMore,
      ),
      failure: (msg, _) => throw Exception(msg),
    );
  },
);

class SearchResultPage {
  const SearchResultPage({
    required this.products,
    required this.totalCount,
    required this.hasMore,
  });

  final List<ProductModel> products;
  final int totalCount;
  final bool hasMore;
}

// ── Favorites ──────────────────────────────────────────────────────────────

final favoritesProvider =
    StateNotifierProvider<FavoritesNotifier, List<ProductModel>>(
  (ref) => FavoritesNotifier(ref),
);

class FavoritesNotifier extends StateNotifier<List<ProductModel>> {
  FavoritesNotifier(this._ref) : super([]) {
    state = _ref.read(localStorageServiceProvider).getFavorites();
  }

  final Ref _ref;

  bool isFavorite(String id) =>
      _ref.read(localStorageServiceProvider).isFavorite(id);

  Future<void> toggle(ProductModel product) async {
    final storage = _ref.read(localStorageServiceProvider);
    if (storage.isFavorite(product.id)) {
      await storage.removeFavorite(product.id);
    } else {
      await storage.addFavorite(product);
    }
    state = storage.getFavorites();
  }
}

// ── Recent searches ────────────────────────────────────────────────────────

final recentSearchesProvider =
    StateNotifierProvider<RecentSearchesNotifier, List<String>>(
  (ref) => RecentSearchesNotifier(ref),
);

class RecentSearchesNotifier extends StateNotifier<List<String>> {
  RecentSearchesNotifier(this._ref) : super([]) {
    state = _ref.read(localStorageServiceProvider).getRecentSearches();
  }

  final Ref _ref;

  Future<void> add(String query) async {
    await _ref.read(localStorageServiceProvider).addRecentSearch(query);
    state = _ref.read(localStorageServiceProvider).getRecentSearches();
  }

  Future<void> remove(String query) async {
    await _ref.read(localStorageServiceProvider).removeRecentSearch(query);
    state = List.from(state)..remove(query);
  }

  Future<void> clear() async {
    await _ref.read(localStorageServiceProvider).clearRecentSearches();
    state = [];
  }
}
