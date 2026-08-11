/// Well-known nutrient slugs — used for ordering & display, not for schema.
/// All actual nutrients live in the `nutrients` table.
class NutrientSlugs {
  NutrientSlugs._();

  static const String energy = 'energy_kcal';
  static const String protein = 'protein';
  static const String carbohydrates = 'carbohydrates';
  static const String fat = 'fat_total';
  static const String fiber = 'fiber';
  static const String sugar = 'sugar';
  static const String sodium = 'sodium';
  static const String saturatedFat = 'saturated_fat';
  static const String transFat = 'trans_fat';
  static const String cholesterol = 'cholesterol';

  /// Nutrients shown in the macro summary strip (order matters).
  static const List<String> macroOrder = [
    energy,
    protein,
    carbohydrates,
    fat,
    fiber,
    sugar,
    sodium,
  ];
}

/// OpenFoodFacts `nutriments` key → our nutrient slug mapping.
const Map<String, String> offNutrimentKeyMap = {
  'energy-kcal': NutrientSlugs.energy,
  'energy-kcal_100g': NutrientSlugs.energy,
  'proteins': NutrientSlugs.protein,
  'proteins_100g': NutrientSlugs.protein,
  'carbohydrates': NutrientSlugs.carbohydrates,
  'carbohydrates_100g': NutrientSlugs.carbohydrates,
  'fat': NutrientSlugs.fat,
  'fat_100g': NutrientSlugs.fat,
  'fiber': NutrientSlugs.fiber,
  'fiber_100g': NutrientSlugs.fiber,
  'sugars': NutrientSlugs.sugar,
  'sugars_100g': NutrientSlugs.sugar,
  'sodium': NutrientSlugs.sodium,
  'sodium_100g': NutrientSlugs.sodium,
  'saturated-fat': NutrientSlugs.saturatedFat,
  'saturated-fat_100g': NutrientSlugs.saturatedFat,
  'trans-fat': NutrientSlugs.transFat,
  'trans-fat_100g': NutrientSlugs.transFat,
  'cholesterol': NutrientSlugs.cholesterol,
  'cholesterol_100g': NutrientSlugs.cholesterol,
};
