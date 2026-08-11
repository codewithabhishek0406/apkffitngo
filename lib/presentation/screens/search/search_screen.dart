import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/models/product_model.dart';
import '../../../data/models/search_filter_model.dart';
import '../../providers/search_providers.dart';
import '../../widgets/common/app_error_widget.dart';
import '../../widgets/common/skeleton_loader.dart';
import '../../widgets/product/product_card.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key, this.initialQuery});
  final String? initialQuery;

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _searchCtrl = TextEditingController();
  final _focusNode = FocusNode();
  Timer? _debounce;
  bool _showFilters = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialQuery != null) {
      _searchCtrl.text = widget.initialQuery!;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(searchFilterProvider.notifier).setQuery(widget.initialQuery!);
      });
    }
    _focusNode.requestFocus();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _focusNode.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onQueryChanged(String q) {
    _debounce?.cancel();
    _debounce = Timer(
      const Duration(milliseconds: AppConstants.searchDebounceMs),
      () => ref.read(searchFilterProvider.notifier).setQuery(q),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filter = ref.watch(searchFilterProvider);

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: TextField(
          controller: _searchCtrl,
          focusNode: _focusNode,
          onChanged: _onQueryChanged,
          onSubmitted: (q) {
            ref.read(recentSearchesProvider.notifier).add(q);
          },
          decoration: InputDecoration(
            hintText: 'Search food, brand or category...',
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            filled: false,
            suffixIcon: _searchCtrl.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear_rounded, size: 18),
                    onPressed: () {
                      _searchCtrl.clear();
                      ref.read(searchFilterProvider.notifier).setQuery('');
                    },
                  )
                : null,
          ),
        ),
        actions: [
          Badge(
            isLabelVisible: filter.hasActiveFilters,
            label: const Text(''),
            child: IconButton(
              icon: const Icon(Icons.tune_rounded),
              onPressed: () => setState(() => _showFilters = !_showFilters),
            ),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Column(
        children: [
          // Filter panel
          AnimatedSize(
            duration: const Duration(milliseconds: 250),
            child: _showFilters
                ? _FilterPanel(
                    filter: filter,
                    onChanged: (newFilter) => ref
                        .read(searchFilterProvider.notifier)
                        .updateFilter(newFilter),
                  )
                : const SizedBox.shrink(),
          ),

          // Divider
          if (filter.hasActiveFilters)
            Container(
              color: AppColors.primaryLight,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Row(
                children: [
                  const Icon(Icons.filter_list_rounded,
                      size: 14, color: AppColors.primary),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Filters active',
                      style: AppTextStyles.labelSmall.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () =>
                        ref.read(searchFilterProvider.notifier).resetFilters(),
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(0, 24),
                    ),
                    child: const Text('Clear'),
                  ),
                ],
              ),
            ),

          Expanded(
            child: filter.query.isEmpty && !filter.hasActiveFilters
                ? _RecentSearchesPanel()
                : _SearchResults(filter: filter),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _SearchResults extends ConsumerWidget {
  const _SearchResults({required this.filter});
  final SearchFilterModel filter;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(searchResultsProvider(filter));

    return async.when(
      loading: () => const ProductGridSkeleton(),
      error: (e, _) => AppErrorWidget(
        message: 'Search failed. Check your connection.',
        onRetry: () => ref.invalidate(searchResultsProvider(filter)),
      ),
      data: (page) {
        if (page.products.isEmpty) {
          return AppEmptyWidget(
            title: 'No results',
            subtitle:
                'Try different keywords or remove some filters',
            icon: Icons.search_off_rounded,
          );
        }

        return Column(
          children: [
            // Count
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Row(
                children: [
                  Text(
                    '${page.totalCount} results',
                    style: AppTextStyles.bodySmall,
                  ),
                ],
              ),
            ),
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 0.72,
                ),
                itemCount: page.products.length,
                itemBuilder: (ctx, i) {
                  final p = page.products[i];
                  return ProductCard(
                    product: p,
                    onTap: () =>
                        ctx.push('/products/${p.slug}', extra: p),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

class _RecentSearchesPanel extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recents = ref.watch(recentSearchesProvider);

    if (recents.isEmpty) {
      return const AppEmptyWidget(
        title: 'Search anything',
        subtitle:
            'Find products by name, brand, barcode or ingredients',
        icon: Icons.search_rounded,
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Recent Searches', style: AppTextStyles.headlineSmall),
            TextButton(
              onPressed: () =>
                  ref.read(recentSearchesProvider.notifier).clear(),
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: const Size(0, 32),
              ),
              child: const Text('Clear all'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...recents.map(
          (q) => ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.history_rounded,
                color: AppColors.textTertiary, size: 18),
            title: Text(q, style: AppTextStyles.bodyMedium),
            trailing: IconButton(
              icon: const Icon(Icons.close_rounded,
                  size: 16, color: AppColors.textTertiary),
              onPressed: () =>
                  ref.read(recentSearchesProvider.notifier).remove(q),
            ),
            onTap: () {
              // Tap a recent search to re-run it
              final notifier =
                  ref.read(searchFilterProvider.notifier);
              notifier.setQuery(q);
            },
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _FilterPanel extends ConsumerWidget {
  const _FilterPanel({required this.filter, required this.onChanged});
  final SearchFilterModel filter;
  final ValueChanged<SearchFilterModel> onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // categoriesProvider available if needed for category filter chips
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Diet type
          Text('Diet', style: AppTextStyles.labelLarge),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            children: DietType.values
                .where((d) => d != DietType.unknown)
                .map((d) => FilterChip(
                      label: Text(d.label),
                      selected: filter.dietType == d,
                      onSelected: (v) => onChanged(
                        filter.copyWith(
                          dietType: v ? d : null,
                          clearDietType: !v,
                        ),
                      ),
                    ))
                .toList(),
          ),
          const SizedBox(height: 12),

          // Calorie range
          Text('Calories (per 100g)', style: AppTextStyles.labelLarge),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: _RangeInput(
                  hint: 'Min',
                  initialValue: filter.minCalories?.toString() ?? '',
                  onChanged: (v) => onChanged(
                    filter.copyWith(
                      minCalories: double.tryParse(v),
                    ),
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 10),
                child: Text('–'),
              ),
              Expanded(
                child: _RangeInput(
                  hint: 'Max',
                  initialValue: filter.maxCalories?.toString() ?? '',
                  onChanged: (v) => onChanged(
                    filter.copyWith(
                      maxCalories: double.tryParse(v),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Protein range
          Text('Protein (g per 100g)', style: AppTextStyles.labelLarge),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: _RangeInput(
                  hint: 'Min',
                  initialValue: filter.minProtein?.toString() ?? '',
                  onChanged: (v) => onChanged(
                    filter.copyWith(minProtein: double.tryParse(v)),
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 10),
                child: Text('–'),
              ),
              Expanded(
                child: _RangeInput(
                  hint: 'Max',
                  initialValue: filter.maxProtein?.toString() ?? '',
                  onChanged: (v) => onChanged(
                    filter.copyWith(maxProtein: double.tryParse(v)),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Sort
          Text('Sort', style: AppTextStyles.labelLarge),
          const SizedBox(height: 6),
          DropdownButtonFormField<SortOption>(
            initialValue: filter.sortBy,
            isDense: true,
            decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
            items: SortOption.values
                .map((s) => DropdownMenuItem(
                      value: s,
                      child: Text(s.label, style: AppTextStyles.bodyMedium),
                    ))
                .toList(),
            onChanged: (s) {
              if (s != null) {
                onChanged(filter.copyWith(sortBy: s));
              }
            },
          ),
        ],
      ),
    );
  }
}

class _RangeInput extends StatelessWidget {
  const _RangeInput({
    required this.hint,
    required this.onChanged,
    this.initialValue = '',
  });
  final String hint;
  final ValueChanged<String> onChanged;
  final String initialValue;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      initialValue: initialValue,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        hintText: hint,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      onChanged: onChanged,
    );
  }
}
