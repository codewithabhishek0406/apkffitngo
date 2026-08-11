import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/nutrient_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/extensions.dart';
import '../../../data/models/nutrient_model.dart';
import '../../../data/models/product_model.dart';
import '../../providers/product_providers.dart';
import '../../providers/providers.dart';
import '../../providers/search_providers.dart';
import '../../widgets/common/app_error_widget.dart';
import '../../widgets/nutrition/macro_strip.dart';
import '../../widgets/nutrition/nutrient_row.dart';

class ProductDetailScreen extends ConsumerWidget {
  const ProductDetailScreen({
    super.key,
    required this.slug,
    this.productPreview,
  });

  final String slug;
  final ProductModel? productPreview;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(productBySlugProvider(slug));

    return async.when(
      loading: () => Scaffold(
        appBar: AppBar(),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(),
        body: AppErrorWidget(
          message: 'Product not found',
          icon: Icons.inventory_2_outlined,
          onRetry: () => ref.invalidate(productBySlugProvider(slug)),
        ),
      ),
      data: (product) {
        // Record as recently viewed
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ref.read(localStorageServiceProvider).addRecentProduct(product);
        });
        return _ProductDetailView(product: product);
      },
    );
  }
}

class _ProductDetailView extends ConsumerStatefulWidget {
  const _ProductDetailView({required this.product});
  final ProductModel product;

  @override
  ConsumerState<_ProductDetailView> createState() => _ProductDetailViewState();
}

class _ProductDetailViewState extends ConsumerState<_ProductDetailView>
    with SingleTickerProviderStateMixin {
  late final TabController _tabCtrl;
  bool _showPerServing = false;
  double _customGrams = 100;
  final _gramsCtrl = TextEditingController(text: '100');
  bool _showAllNutrients = false;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _gramsCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final isFav =
        ref.watch(favoritesProvider.notifier).isFavorite(product.id);
    final isInComp =
        ref.watch(comparisonIdsProvider.notifier).isInComparison(product.id);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // ── Hero image + actions ──────────────────────────────────────
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            backgroundColor: AppColors.surface,
            actions: [
              IconButton(
                icon: Icon(
                  isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                  color: isFav ? AppColors.error : null,
                ),
                onPressed: () =>
                    ref.read(favoritesProvider.notifier).toggle(product),
              ),
              IconButton(
                icon: Icon(
                  Icons.compare_arrows_rounded,
                  color: isInComp ? AppColors.primary : null,
                ),
                onPressed: () {
                  ref
                      .read(comparisonIdsProvider.notifier)
                      .toggle(product.id);
                  final ids = ref.read(comparisonIdsProvider);
                  if (ids.length >= 2) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('${ids.length} products selected'),
                        action: SnackBarAction(
                          label: 'Compare',
                          onPressed: () => context.push('/comparison'),
                        ),
                      ),
                    );
                  }
                },
              ),
              const SizedBox(width: 4),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: product.imageUrl != null
                  ? CachedNetworkImage(
                      imageUrl: product.imageUrl!,
                      fit: BoxFit.contain,
                      placeholder: (_, __) => Container(
                        color: AppColors.surfaceVariant,
                        child: const Center(
                          child: CircularProgressIndicator(),
                        ),
                      ),
                      errorWidget: (_, __, ___) => Container(
                        color: AppColors.surfaceVariant,
                        child: const Icon(
                          Icons.image_not_supported_outlined,
                          size: 64,
                          color: AppColors.textTertiary,
                        ),
                      ),
                    )
                  : Container(
                      color: AppColors.surfaceVariant,
                      child: const Icon(
                        Icons.inventory_2_outlined,
                        size: 80,
                        color: AppColors.textTertiary,
                      ),
                    ),
            ),
          ),

          // ── Product header ────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Brand + verified
                  Row(
                    children: [
                      if (product.brand != null)
                        Expanded(
                          child: Text(
                            product.brand!.name.toUpperCase(),
                            style: AppTextStyles.labelSmall.copyWith(
                              color: AppColors.primary,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                      if (product.isVerified) ...[
                        const Icon(
                          Icons.verified_rounded,
                          size: 14,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Verified',
                          style: AppTextStyles.labelSmall.copyWith(
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),

                  // Product name
                  Text(product.name, style: AppTextStyles.headlineLarge),
                  const SizedBox(height: 8),

                  // Category + diet type
                  Row(
                    children: [
                      if (product.category != null)
                        _Chip(
                          label: product.category!.name,
                          color: AppColors.surfaceVariant,
                          textColor: AppColors.textSecondary,
                          icon: Icons.category_outlined,
                        ),
                      const SizedBox(width: 6),
                      _DietChip(dietType: product.dietType),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),

          // ── Per 100g / Per Serving toggle ─────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: _ToggleBtn(
                            label: 'Per 100g',
                            active: !_showPerServing,
                            onTap: () => setState(() => _showPerServing = false),
                          ),
                        ),
                        if (product.servingSize != null)
                          Expanded(
                            child: _ToggleBtn(
                              label: 'Per Serving'
                                  '${product.servingSize != null ? ' (${product.servingSize!.toNutrientString()}${product.servingUnit ?? 'g'})' : ''}',
                              active: _showPerServing,
                              onTap: () =>
                                  setState(() => _showPerServing = true),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),

          // ── Macro strip ───────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: MacroStrip(
                product: product,
                showPerServing: _showPerServing,
                customGrams:
                    _customGrams == 100 ? null : _customGrams,
              ),
            ),
          ),

          // ── Quantity calculator ───────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: _QuantityCalculator(
                grams: _customGrams,
                onChanged: (g) => setState(() => _customGrams = g),
                controller: _gramsCtrl,
              ),
            ),
          ),

          // ── Full nutrient table ───────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Nutrition Facts', style: AppTextStyles.headlineSmall),
                  const SizedBox(height: 10),
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.border),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        // Header
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: const BoxDecoration(
                            color: AppColors.surfaceVariant,
                            borderRadius: BorderRadius.vertical(
                              top: Radius.circular(11),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Nutrient',
                                style: AppTextStyles.labelMedium,
                              ),
                              Text(
                                _showPerServing ? 'Per Serving' : 'Per 100g',
                                style: AppTextStyles.labelMedium,
                              ),
                            ],
                          ),
                        ),
                        // Macro nutrients first (ordered by display_order)
                        ..._buildNutrientRows(product, macroOnly: true),
                        // Expandable — other nutrients
                        if (!_showAllNutrients && _hasOtherNutrients(product))
                          _ExpandButton(
                            onTap: () =>
                                setState(() => _showAllNutrients = true),
                          )
                        else if (_showAllNutrients) ...[
                          ..._buildNutrientRows(product, macroOnly: false),
                          _CollapseButton(
                            onTap: () =>
                                setState(() => _showAllNutrients = false),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Ingredients ───────────────────────────────────────────────
          if (product.ingredients != null)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Ingredients', style: AppTextStyles.headlineSmall),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        product.ingredients!,
                        style: AppTextStyles.bodySmall,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // ── Allergens ─────────────────────────────────────────────────
          if ((product.allergens?.isNotEmpty ?? false) ||
              (product.mayContainAllergens?.isNotEmpty ?? false))
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Allergens', style: AppTextStyles.headlineSmall),
                    const SizedBox(height: 8),
                    if (product.allergens?.isNotEmpty ?? false) ...[
                      _AllergenRow(
                        prefix: 'Contains',
                        items: product.allergens!,
                        color: AppColors.error,
                      ),
                      const SizedBox(height: 6),
                    ],
                    if (product.mayContainAllergens?.isNotEmpty ?? false)
                      _AllergenRow(
                        prefix: 'May contain',
                        items: product.mayContainAllergens!,
                        color: AppColors.warning,
                      ),
                  ],
                ),
              ),
            ),

          // ── Product info ──────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
              child: _ProductInfoTable(product: product),
            ),
          ),

          // ── Disclaimer ────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.warning.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: AppColors.warning.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.info_outline_rounded,
                      size: 16,
                      color: AppColors.warning,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Nutritional information is for reference only and may '
                        'not reflect current product packaging. Not a medical tool. '
                        'Always check the label for the most accurate information.',
                        style: AppTextStyles.caption,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
    );
  }

  bool _hasOtherNutrients(ProductModel p) {
    return p.nutrients.any(
      (n) => !NutrientSlugs.macroOrder.contains(n.nutrient.slug),
    );
  }

  List<Widget> _buildNutrientRows(
    ProductModel p, {
    required bool macroOnly,
  }) {
    final sorted = List<ProductNutrientModel>.from(p.nutrients)
      ..sort((a, b) =>
          a.nutrient.displayOrder.compareTo(b.nutrient.displayOrder));

    final filtered = macroOnly
        ? sorted
            .where((n) => NutrientSlugs.macroOrder.contains(n.nutrient.slug))
            .toList()
        : sorted
            .where(
              (n) => !NutrientSlugs.macroOrder.contains(n.nutrient.slug),
            )
            .toList();

    final rows = <Widget>[];
    for (int i = 0; i < filtered.length; i++) {
      rows.add(NutrientRow(
        productNutrient: filtered[i],
        showPerServing: _showPerServing,
        customGrams: _customGrams == 100 ? null : _customGrams,
        isBold: filtered[i].nutrient.slug == NutrientSlugs.energy,
      ));
      if (i < filtered.length - 1) rows.add(const NutrientDivider());
    }
    return rows;
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _QuantityCalculator extends StatelessWidget {
  const _QuantityCalculator({
    required this.grams,
    required this.onChanged,
    required this.controller,
  });

  final double grams;
  final ValueChanged<double> onChanged;
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          const Icon(Icons.scale_outlined, size: 20, color: AppColors.textSecondary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Calculate for custom amount',
              style: AppTextStyles.labelLarge,
            ),
          ),
          SizedBox(
            width: 80,
            child: TextField(
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              textAlign: TextAlign.center,
              style: AppTextStyles.headlineSmall,
              decoration: const InputDecoration(
                suffix: Text('g'),
                contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              ),
              onChanged: (v) {
                final parsed = double.tryParse(v);
                if (parsed != null &&
                    parsed >= AppConstants.minServingGrams &&
                    parsed <= AppConstants.maxServingGrams) {
                  onChanged(parsed);
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ToggleBtn extends StatelessWidget {
  const _ToggleBtn({
    required this.label,
    required this.active,
    required this.onTap,
  });
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.all(4),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: active ? AppColors.surface : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          boxShadow: active
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: AppTextStyles.labelMedium.copyWith(
            color: active ? AppColors.primary : AppColors.textSecondary,
            fontWeight: active ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.color,
    required this.textColor,
    this.icon,
  });
  final String label;
  final Color color;
  final Color textColor;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: textColor),
            const SizedBox(width: 4),
          ],
          Text(label, style: TextStyle(fontSize: 11, color: textColor, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

class _DietChip extends StatelessWidget {
  const _DietChip({required this.dietType});
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
    return _Chip(
      label: dietType.label,
      color: color.withOpacity(0.1),
      textColor: color,
    );
  }
}

class _AllergenRow extends StatelessWidget {
  const _AllergenRow({
    required this.prefix,
    required this.items,
    required this.color,
  });
  final String prefix;
  final List<String> items;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 6,
      runSpacing: 6,
      children: [
        Text('$prefix:', style: AppTextStyles.labelLarge),
        ...items.map(
          (a) => Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: color.withOpacity(0.3)),
            ),
            child: Text(
              a.titleCase,
              style: TextStyle(
                fontSize: 12,
                color: color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ProductInfoTable extends StatelessWidget {
  const _ProductInfoTable({required this.product});
  final ProductModel product;

  @override
  Widget build(BuildContext context) {
    final rows = <(String, String?)>[
      ('Manufacturer', product.manufacturer),
      ('Country', product.country),
      ('Barcode', product.barcode),
      ('Serving Size',
          product.servingSize != null
              ? '${product.servingSize!.toNutrientString()} ${product.servingUnit ?? 'g'}'
              : null),
      ('Data Source', product.source),
      ('Status', product.verificationStatus.label),
      ('Last Updated', product.updatedAt?.toDisplayDate()),
    ].where((r) => r.$2 != null).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Product Information', style: AppTextStyles.headlineSmall),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: rows.indexed.map((entry) {
              final (i, row) = entry;
              return Column(
                children: [
                  if (i > 0) const Divider(height: 1, color: AppColors.border),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: Text(row.$1, style: AppTextStyles.bodySmall),
                        ),
                        Expanded(
                          flex: 3,
                          child: Text(
                            row.$2!,
                            style: AppTextStyles.bodyMedium,
                            textAlign: TextAlign.right,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class _ExpandButton extends StatelessWidget {
  const _ExpandButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Show more nutrients', style: AppTextStyles.labelMedium),
            const SizedBox(width: 4),
            const Icon(Icons.expand_more_rounded,
                size: 16, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}

class _CollapseButton extends StatelessWidget {
  const _CollapseButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Show less', style: AppTextStyles.labelMedium),
            const SizedBox(width: 4),
            const Icon(Icons.expand_less_rounded,
                size: 16, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}

// toDisplayDate() is provided by DateTimeExtensions in core/utils/extensions.dart
