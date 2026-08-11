import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/extensions.dart';
import '../../../data/models/product_model.dart';
import '../../providers/product_providers.dart';
import '../../providers/search_providers.dart';

class ProductCard extends ConsumerWidget {
  const ProductCard({
    super.key,
    required this.product,
    required this.onTap,
    this.onCompareToggle,
  });

  final ProductModel product;
  final VoidCallback onTap;
  final VoidCallback? onCompareToggle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isFav =
        ref.watch(favoritesProvider.notifier).isFavorite(product.id);
    final isInComparison =
        ref.watch(comparisonIdsProvider.notifier).isInComparison(product.id);

    final calories = product.getNutrientPer100g('energy_kcal');
    final protein = product.getNutrientPer100g('protein');
    final sugar = product.getNutrientPer100g('sugar');

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isInComparison ? AppColors.primary : AppColors.border,
            width: isInComparison ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(15)),
                  child: product.imageUrl != null
                      ? CachedNetworkImage(
                          imageUrl: product.imageUrl!,
                          height: 130,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => _imgPlaceholder(),
                          errorWidget: (_, __, ___) => _imgPlaceholder(),
                        )
                      : _imgPlaceholder(),
                ),
                Positioned(
                  top: 8, left: 8,
                  child: _DietBadge(dietType: product.dietType),
                ),
                if (product.isVerified)
                  const Positioned(
                      top: 8, right: 8, child: _VerifiedBadge()),
                Positioned(
                  bottom: 6,
                  right: 6,
                  child: GestureDetector(
                    onTap: () => ref
                        .read(favoritesProvider.notifier)
                        .toggle(product),
                    child: Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isFav
                            ? Icons.favorite_rounded
                            : Icons.favorite_border_rounded,
                        size: 16,
                        color: isFav
                            ? AppColors.error
                            : AppColors.textTertiary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (product.brand != null)
                      Text(
                        product.brand!.name,
                        style: AppTextStyles.labelSmall.copyWith(
                          color: AppColors.primary,
                          letterSpacing: 0.3,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    const SizedBox(height: 2),
                    Text(
                      product.name,
                      style:
                          AppTextStyles.labelLarge.copyWith(fontSize: 13),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        if (calories != null)
                          _NutrientPill(
                              value: calories.toNutrientString(),
                              unit: 'kcal',
                              color: AppColors.calorieColor),
                        const SizedBox(width: 4),
                        if (protein != null)
                          _NutrientPill(
                              value: protein.toNutrientString(),
                              unit: 'P',
                              color: AppColors.proteinColor),
                        const SizedBox(width: 4),
                        if (sugar != null)
                          _NutrientPill(
                              value: sugar.toNutrientString(),
                              unit: 'S',
                              color: AppColors.sugarColor),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _imgPlaceholder() => Container(
        height: 130,
        color: AppColors.surfaceVariant,
        child: const Center(
          child: Icon(Icons.image_outlined,
              color: AppColors.textTertiary, size: 32),
        ),
      );
}

class _DietBadge extends StatelessWidget {
  const _DietBadge({required this.dietType});
  final DietType dietType;

  @override
  Widget build(BuildContext context) {
    if (dietType == DietType.unknown) return const SizedBox.shrink();
    final color = switch (dietType) {
      DietType.veg => AppColors.vegColor,
      DietType.vegan => AppColors.veganColor,
      DietType.nonVeg => AppColors.nonVegColor,
      DietType.unknown => AppColors.textTertiary,
    };
    final icon = switch (dietType) {
      DietType.veg || DietType.vegan => Icons.circle,
      _ => Icons.change_history_rounded,
    };
    return Container(
      width: 18,
      height: 18,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color, width: 1.5),
      ),
      child: Icon(icon, size: 10, color: color),
    );
  }
}

class _VerifiedBadge extends StatelessWidget {
  const _VerifiedBadge();
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(6),
      ),
      child: const Icon(Icons.verified_rounded,
          size: 10, color: Colors.white),
    );
  }
}

class _NutrientPill extends StatelessWidget {
  const _NutrientPill(
      {required this.value, required this.unit, required this.color});
  final String value;
  final String unit;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        '$value$unit',
        style: TextStyle(
            fontSize: 9, fontWeight: FontWeight.w600, color: color),
      ),
    );
  }
}
