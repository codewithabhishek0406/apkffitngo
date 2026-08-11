import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/extensions.dart';
import '../../../data/models/nutrient_model.dart';

class NutrientRow extends StatelessWidget {
  const NutrientRow({
    super.key,
    required this.productNutrient,
    required this.showPerServing,
    this.customGrams,
    this.isHighlighted = false,
    this.isBold = false,
    this.indent = false,
  });

  final ProductNutrientModel productNutrient;
  final bool showPerServing;
  final double? customGrams; // if set, override with scaled value
  final bool isHighlighted;
  final bool isBold;
  final bool indent;

  double? get _value {
    if (customGrams != null) {
      return productNutrient.scaledValue(customGrams!);
    }
    return showPerServing
        ? productNutrient.valuePerServing
        : productNutrient.valuePer100g;
  }

  @override
  Widget build(BuildContext context) {
    final value = _value;
    final nutrient = productNutrient.nutrient;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: indent ? 24 : 16,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color: isHighlighted ? AppColors.primaryLight : null,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              nutrient.name,
              style: isBold
                  ? AppTextStyles.labelLarge
                  : AppTextStyles.bodyMedium,
            ),
          ),
          if (value == null)
            Text(
              '—',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textTertiary,
              ),
            )
          else
            RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: value.toNutrientString(),
                    style: isBold
                        ? AppTextStyles.labelLarge
                        : AppTextStyles.bodyMedium,
                  ),
                  TextSpan(
                    text: ' ${nutrient.unit}',
                    style: AppTextStyles.bodySmall,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class NutrientDivider extends StatelessWidget {
  const NutrientDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return const Divider(height: 1, thickness: 1, color: AppColors.border);
  }
}
