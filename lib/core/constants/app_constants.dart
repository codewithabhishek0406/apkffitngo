class AppConstants {
  AppConstants._();

  // Pagination
  static const int pageSize = 20;
  static const int searchDebounceMs = 400;

  // Local storage box names (Hive)
  static const String favoritesBox = 'favorites_box';
  static const String recentSearchesBox = 'recent_searches_box';
  static const String recentProductsBox = 'recent_products_box';
  static const String settingsBox = 'settings_box';
  static const String categoryCacheBox = 'category_cache_box';

  // Max items kept locally
  static const int maxRecentSearches = 20;
  static const int maxRecentProducts = 30;

  // Comparison
  static const int maxComparisonProducts = 3;

  // Image quality (WebP)
  static const int imageThumbnailSize = 200;
  static const int imageFullSize = 800;

  // Cache duration
  static const Duration categoryCacheDuration = Duration(hours: 24);
  static const Duration productCacheDuration = Duration(hours: 6);

  // Quantity calculator bounds
  static const double minServingGrams = 1;
  static const double maxServingGrams = 2000;
}
