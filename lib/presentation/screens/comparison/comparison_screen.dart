import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/extensions.dart';
import '../../../data/models/product_model.dart';
import '../../providers/product_providers.dart';
import '../../widgets/common/app_error_widget.dart';

class ComparisonScreen extends ConsumerWidget {
  const ComparisonScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ids = ref.watch(comparisonIdsProvider);
    final async = ref.watch(comparisonProductsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Compare Products'),
        actions: [
          if (ids.isNotEmpty)
            TextButton.icon(
              onPressed: () => ref.read(comparisonIdsProvider.notifier).clear(),
              icon: const Icon(Icons.clear_all_rounded, size: 18),
              label: const Text('Clear'),
            ),
        ],
      ),
      body: ids.isEmpty
          ? AppEmptyWidget(
              title: 'No products selected',
              subtitle:
                  'Select up to ${AppConstants.maxComparisonProducts} products '
                  'from search or product detail pages',
              icon: Icons.compare_arrows_rounded,
              action: () => context.push('/search'),
              actionLabel: 'Browse products',
            )
          : async.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => AppErrorWidget(
                message: 'Failed to load products',
                onRetry: () => ref.invalidate(comparisonProductsProvider),
              ),
              data: (products) => products.isEmpty
                  ? const Center(child: Text('No products to compare'))
                  : _ComparisonTable(products: products),
            ),
    );
  }
}

class _ComparisonTable extends StatelessWidget {
  const _ComparisonTable({required this.products});
  final List<ProductModel> products;

  @override
  Widget build(BuildContext context) {
    // Collect all nutrient slugs that appear in at least one product
    final allSlugs = <String>{};
    final slugOrder = <String, int>{};
    for (final p in products) {
      for (final pn in p.nutrients) {
        allSlugs.add(pn.nutrient.slug);
        slugOrder[pn.nutrient.slug] = pn.nutrient.displayOrder;
      }
    }
    final sortedSlugs = allSlugs.toList()
      ..sort(
        (a, b) => (slugOrder[a] ?? 99).compareTo(slugOrder[b] ?? 99),
      );

    return SingleChildScrollView(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: IntrinsicWidth(
          child: Column(
            children: [
              // Header row — product images + names
              _HeaderRow(products: products),
              const Divider(height: 2, thickness: 2, color: AppColors.border),

              // Nutrient rows
              ...sortedSlugs.map(
                (slug) => _NutrientCompareRow(
                  slug: slug,
                  products: products,
                ),
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeaderRow extends ConsumerWidget {
  const _HeaderRow({required this.products});
  final List<ProductModel> products;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label column spacer
        const SizedBox(width: 130),
        ...products.map(
          (p) => SizedBox(
            width: 140,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  // Image
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: p.imageUrl != null
                        ? CachedNetworkImage(
                            imageUrl: p.imageUrl!,
                            width: 80,
                            height: 80,
                            fit: BoxFit.cover,
                          )
                        : Container(
                            width: 80,
                            height: 80,
                            color: AppColors.surfaceVariant,
                            child: const Icon(
                              Icons.inventory_2_outlined,
                              color: AppColors.textTertiary,
                            ),
                          ),
                  ),
                  const SizedBox(height: 8),
                  if (p.brand != null)
                    Text(
                      p.brand!.name,
                      style: AppTextStyles.labelSmall.copyWith(
                        color: AppColors.primary,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  Text(
                    p.name,
                    style: AppTextStyles.labelMedium,
                    textAlign: TextAlign.center,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  // Remove button
                  GestureDetector(
                    onTap: () => ref
                        .read(comparisonIdsProvider.notifier)
                        .toggle(p.id),
                    child: const Icon(
                      Icons.remove_circle_outline_rounded,
                      size: 16,
                      color: AppColors.error,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _NutrientCompareRow extends StatelessWidget {
  const _NutrientCompareRow({
    required this.slug,
    required this.products,
  });
  final String slug;
  final List<ProductModel> products;

  @override
  Widget build(BuildContext context) {
    // Get values for each product
    final values = products
        .map((p) => p.getNutrientPer100g(slug))
        .toList();

    // Find nutrient name/unit from the first product that has it
    String nutrientName = slug;
    String unit = '';
    for (final p in products) {
      try {
        final pn = p.nutrients.firstWhere((n) => n.nutrient.slug == slug);
        nutrientName = pn.nutrient.name;
        unit = pn.nutrient.unit;
        break;
      } catch (_) {}
    }

    // Determine best/worst (numeric comparison, lower isn't always better)
    // We highlight the differences without a "healthier" verdict
    final numericValues =
        values.whereType<double>().toList();
    final maxVal = numericValues.isEmpty
        ? null
        : numericValues.reduce((a, b) => a > b ? a : b);
    final minVal = numericValues.isEmpty
        ? null
        : numericValues.reduce((a, b) => a < b ? a : b);
    final hasDiff = maxVal != null && minVal != null && maxVal != minVal;

    return Column(
      children: [
        const Divider(height: 1, color: AppColors.border),
        Row(
          children: [
            // Nutrient name
            SizedBox(
              width: 130,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                child: Text(
                  '$nutrientName\n($unit/100g)',
                  style: AppTextStyles.bodySmall,
                ),
              ),
            ),
            // Values per product
            ...values.asMap().entries.map((entry) {
              final v = entry.value;
              final isMax = hasDiff && v == maxVal;
              final isMin = hasDiff && v == minVal;

              return SizedBox(
                width: 140,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  color: isMax
                      ? AppColors.error.withValues(alpha: 0.05)
                      : isMin
                          ? AppColors.success.withValues(alpha: 0.05)
                          : null,
                  child: v == null
                      ? Text(
                          '—',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textTertiary,
                          ),
                          textAlign: TextAlign.center,
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              v.toNutrientString(),
                              style: AppTextStyles.bodyMedium.copyWith(
                                fontWeight: FontWeight.w600,
                                color: isMax
                                    ? AppColors.error
                                    : isMin
                                        ? AppColors.success
                                        : AppColors.textPrimary,
                              ),
                            ),
                            if (hasDiff)
                              Icon(
                                isMax
                                    ? Icons.arrow_upward_rounded
                                    : isMin
                                        ? Icons.arrow_downward_rounded
                                        : Icons.remove_rounded,
                                size: 12,
                                color: isMax
                                    ? AppColors.error
                                    : isMin
                                        ? AppColors.success
                                        : AppColors.textTertiary,
                              ),
                          ],
                        ),
                ),
              );
            }),
          ],
        ),
      ],
    );
  }
}
