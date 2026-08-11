import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/category_repository.dart';
import '../../data/repositories/food_repository.dart';
import '../../data/repositories/search_repository.dart';
import '../../services/local_storage_service.dart';
import '../../services/open_food_facts_service.dart';

// ── Services ──────────────────────────────────────────────────────────────

final localStorageServiceProvider = Provider<LocalStorageService>(
  (ref) => const LocalStorageService(),
);

final openFoodFactsServiceProvider = Provider<OpenFoodFactsService>(
  (ref) => OpenFoodFactsService(),
);

// ── Repositories ──────────────────────────────────────────────────────────

final categoryRepositoryProvider = Provider<CategoryRepository>(
  (ref) => const CategoryRepository(),
);

final foodRepositoryProvider = Provider<FoodRepository>(
  (ref) => const FoodRepository(),
);

final searchRepositoryProvider = Provider<SearchRepository>(
  (ref) => const SearchRepository(),
);
