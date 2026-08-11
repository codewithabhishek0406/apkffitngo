/// Validation helpers used in both Flutter and admin data entry.
class NutrientValidator {
  NutrientValidator._();

  static const double _maxPer100g = 100.0;
  static const double _maxEnergyPer100g = 900.0; // kcal (pure fat ≈ 884)
  static const double _maxSodiumPer100g = 40000.0; // mg (very salty product)

  /// Returns null if valid, or an error string if not.
  static String? validateNutrientValue({
    required String slug,
    required double value,
  }) {
    if (value < 0) return 'Nutrient value cannot be negative';

    if (slug == 'energy_kcal') {
      if (value > _maxEnergyPer100g) {
        return 'Energy $value kcal/100g seems too high (max ~$_maxEnergyPer100g)';
      }
    } else if (slug == 'sodium') {
      if (value > _maxSodiumPer100g) {
        return 'Sodium $value mg/100g seems too high';
      }
    } else {
      if (value > _maxPer100g) {
        return 'Value $value g/100g exceeds 100g — please check';
      }
    }
    return null;
  }

  /// Validates that the sum of protein + carbs + fat ≤ 100g (rough check).
  static String? validateMacroSum({
    double? protein,
    double? carbs,
    double? fat,
  }) {
    final total = (protein ?? 0) + (carbs ?? 0) + (fat ?? 0);
    if (total > 105) {
      // Allow a small margin for rounding
      return 'Protein + Carbs + Fat = ${total.toStringAsFixed(1)}g exceeds 100g';
    }
    return null;
  }
}
