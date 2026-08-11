import 'package:flutter/material.dart';
import '../../../core/constants/nutrient_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/extensions.dart';
import '../../../data/models/product_model.dart';

class MacroStrip extends StatelessWidget {
  const MacroStrip({
    super.key,
    required this.product,
    required this.showPerServing,
    this.customGrams,
  });

  final ProductModel product;
  final bool showPerServing;
  final double? customGrams;

  double? _getValue(String slug) {
    if (customGrams != null) {
      return product.getNutrientPer100g(slug)?.scaleToGrams(customGrams!);
    }
    return showPerServing
        ? product.getNutrientPerServing(slug)
        : product.getNutrientPer100g(slug);
  }

  @override
  Widget build(BuildContext context) {
    final calories = _getValue(NutrientSlugs.energy);
    final protein = _getValue(NutrientSlugs.protein);
    final carbs = _getValue(NutrientSlugs.carbohydrates);
    final fat = _getValue(NutrientSlugs.fat);
    final fiber = _getValue(NutrientSlugs.fiber);
    final sugar = _getValue(NutrientSlugs.sugar);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          // Calories headline
          if (calories != null) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  calories.toNutrientString(),
                  style: AppTextStyles.calorieBig,
                ),
                const SizedBox(width: 4),
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text(
                    'kcal',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.calorieColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              showPerServing
                  ? 'Per Serving'
                  : customGrams != null
                      ? 'Per ${customGrams!.toNutrientString()}g'
                      : 'Per 100g',
              style: AppTextStyles.bodySmall,
            ),
            const SizedBox(height: 16),
            const Divider(color: AppColors.border, height: 1),
            const SizedBox(height: 16),
          ],

          // Macro row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _MacroTile(label: 'Protein', value: protein, unit: 'g', color: AppColors.proteinColor),
              _MacroTile(label: 'Carbs', value: carbs, unit: 'g', color: AppColors.carbColor),
              _MacroTile(label: 'Fat', value: fat, unit: 'g', color: AppColors.fatColor),
              _MacroTile(label: 'Fiber', value: fiber, unit: 'g', color: AppColors.fiberColor),
              _MacroTile(label: 'Sugar', value: sugar, unit: 'g', color: AppColors.sugarColor),
            ],
          ),
        ],
      ),
    );
  }
}

class _MacroTile extends StatelessWidget {
  const _MacroTile({
    required this.label,
    required this.value,
    required this.unit,
    required this.color,
  });

  final String label;
  final double? value;
  final String unit;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: value == null
                ? Text('—',
                    style: TextStyle(
                        color: color, fontWeight: FontWeight.w700))
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        value!.toNutrientString(),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: color,
                        ),
                      ),
                      Text(
                        unit,
                        style: TextStyle(
                          fontSize: 9,
                          color: color.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ),
          ),
        ),
        const SizedBox(height: 6),
        Text(label, style: AppTextStyles.labelSmall),
      ],
    );
  }
}
