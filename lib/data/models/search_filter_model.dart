import 'product_model.dart';

enum SortOption {
  relevance,
  nameAsc,
  nameDesc,
  caloriesAsc,
  caloriesDesc,
  proteinDesc,
  sugarAsc,
  fatAsc,
  recentlyAdded,
}

extension SortOptionLabel on SortOption {
  String get label => switch (this) {
        SortOption.relevance => 'Relevance',
        SortOption.nameAsc => 'Name A–Z',
        SortOption.nameDesc => 'Name Z–A',
        SortOption.caloriesAsc => 'Calories: Low to High',
        SortOption.caloriesDesc => 'Calories: High to Low',
        SortOption.proteinDesc => 'Protein: High to Low',
        SortOption.sugarAsc => 'Sugar: Low to High',
        SortOption.fatAsc => 'Fat: Low to High',
        SortOption.recentlyAdded => 'Recently Added',
      };
}

class SearchFilterModel {
  const SearchFilterModel({
    this.query = '',
    this.categoryId,
    this.brandId,
    this.dietType,
    this.containsGluten,
    this.containsDairy,
    this.containsNuts,
    this.minCalories,
    this.maxCalories,
    this.minProtein,
    this.maxProtein,
    this.minSugar,
    this.maxSugar,
    this.sortBy = SortOption.relevance,
    this.page = 0,
  });

  final String query;
  final String? categoryId;
  final String? brandId;
  final DietType? dietType;
  final bool? containsGluten;
  final bool? containsDairy;
  final bool? containsNuts;
  final double? minCalories;
  final double? maxCalories;
  final double? minProtein;
  final double? maxProtein;
  final double? minSugar;
  final double? maxSugar;
  final SortOption sortBy;
  final int page;

  bool get hasActiveFilters =>
      categoryId != null ||
      brandId != null ||
      dietType != null ||
      containsGluten != null ||
      containsDairy != null ||
      containsNuts != null ||
      minCalories != null ||
      maxCalories != null ||
      minProtein != null ||
      maxProtein != null ||
      minSugar != null ||
      maxSugar != null;

  SearchFilterModel copyWith({
    String? query,
    String? categoryId,
    String? brandId,
    DietType? dietType,
    bool? containsGluten,
    bool? containsDairy,
    bool? containsNuts,
    double? minCalories,
    double? maxCalories,
    double? minProtein,
    double? maxProtein,
    double? minSugar,
    double? maxSugar,
    SortOption? sortBy,
    int? page,
    bool clearCategoryId = false,
    bool clearBrandId = false,
    bool clearDietType = false,
  }) {
    return SearchFilterModel(
      query: query ?? this.query,
      categoryId: clearCategoryId ? null : (categoryId ?? this.categoryId),
      brandId: clearBrandId ? null : (brandId ?? this.brandId),
      dietType: clearDietType ? null : (dietType ?? this.dietType),
      containsGluten: containsGluten ?? this.containsGluten,
      containsDairy: containsDairy ?? this.containsDairy,
      containsNuts: containsNuts ?? this.containsNuts,
      minCalories: minCalories ?? this.minCalories,
      maxCalories: maxCalories ?? this.maxCalories,
      minProtein: minProtein ?? this.minProtein,
      maxProtein: maxProtein ?? this.maxProtein,
      minSugar: minSugar ?? this.minSugar,
      maxSugar: maxSugar ?? this.maxSugar,
      sortBy: sortBy ?? this.sortBy,
      page: page ?? this.page,
    );
  }

  SearchFilterModel resetFilters() => SearchFilterModel(
        query: query,
        sortBy: sortBy,
      );
}
