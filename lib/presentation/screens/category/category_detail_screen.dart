import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/models/category_model.dart';
import '../../../data/models/product_model.dart';
import '../../../data/models/search_filter_model.dart';
import '../../providers/product_providers.dart';
import '../../widgets/common/app_error_widget.dart';
import '../../widgets/common/skeleton_loader.dart';
import '../../widgets/product/product_card.dart';

class CategoryDetailScreen extends ConsumerStatefulWidget {
  const CategoryDetailScreen({
    super.key,
    required this.category,
  });

  final CategoryModel category;

  @override
  ConsumerState<CategoryDetailScreen> createState() =>
      _CategoryDetailScreenState();
}

class _CategoryDetailScreenState
    extends ConsumerState<CategoryDetailScreen> {
  SortOption _sort = SortOption.nameAsc;
  DietType? _dietFilter;
  int _page = 0;
  bool _hasMore = true;
  bool _loadingMore = false;
  final _scrollCtrl = ScrollController();
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollCtrl.position.pixels >=
            _scrollCtrl.position.maxScrollExtent - 200 &&
        _hasMore &&
        !_loadingMore) {
      _loadMore();
    }
  }

  Future<void> _loadMore() async {
    if (_loadingMore) return;
    setState(() => _loadingMore = true);
    setState(() {
      _page++;
      _loadingMore = false;
    });
  }

  String? get _sortColumn => switch (_sort) {
        SortOption.nameAsc || SortOption.nameDesc => 'name',
        _ => null,
      };

  bool get _ascending => _sort == SortOption.nameAsc;

  @override
  Widget build(BuildContext context) {
    final params = CategoryProductsParams(
      categoryId: widget.category.id,
      sortColumn: _sortColumn,
      ascending: _ascending,
      page: _page,
    );

    final async = ref.watch(categoryProductsProvider(params));

    return Scaffold(
      body: CustomScrollView(
        controller: _scrollCtrl,
        slivers: [
          // App bar
          SliverAppBar(
            pinned: true,
            backgroundColor: AppColors.surface,
            title: Text(widget.category.name),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(56),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                child: TextField(
                  controller: _searchCtrl,
                  decoration: const InputDecoration(
                    hintText: 'Search in this category...',
                    prefixIcon: Icon(Icons.search_rounded, size: 20),
                    contentPadding: EdgeInsets.symmetric(vertical: 10),
                  ),
                  onChanged: (v) => setState(() {
                    _query = v;
                    _page = 0;
                  }),
                ),
              ),
            ),
          ),

          // Sort & filter bar
          SliverToBoxAdapter(
            child: _FilterBar(
              currentSort: _sort,
              currentDiet: _dietFilter,
              onSortChanged: (s) => setState(() {
                _sort = s;
                _page = 0;
              }),
              onDietChanged: (d) => setState(() {
                _dietFilter = d;
                _page = 0;
              }),
            ),
          ),

          // Products grid
          async.when(
            loading: () => const SliverToBoxAdapter(
              child: ProductGridSkeleton(),
            ),
            error: (e, _) => SliverFillRemaining(
              child: AppErrorWidget(
                message: e.toString(),
                onRetry: () => ref.invalidate(categoryProductsProvider(params)),
              ),
            ),
            data: (products) {
              final filtered = _query.isEmpty
                  ? products
                  : products
                      .where((p) =>
                          p.name
                              .toLowerCase()
                              .contains(_query.toLowerCase()) ||
                          (p.brand?.name
                                  .toLowerCase()
                                  .contains(_query.toLowerCase()) ??
                              false))
                      .toList();

              final dietFiltered = _dietFilter == null
                  ? filtered
                  : filtered
                      .where((p) => p.dietType == _dietFilter)
                      .toList();

              if (dietFiltered.isEmpty) {
                return SliverFillRemaining(
                  child: AppEmptyWidget(
                    title: 'No products found',
                    subtitle: 'Try adjusting your filters',
                    icon: Icons.inventory_2_outlined,
                  ),
                );
              }

              return SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverGrid(
                  delegate: SliverChildBuilderDelegate(
                    (ctx, i) {
                      final p = dietFiltered[i];
                      return ProductCard(
                        product: p,
                        onTap: () =>
                            ctx.push('/products/${p.slug}', extra: p),
                      );
                    },
                    childCount: dietFiltered.length,
                  ),
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 0.72,
                  ),
                ),
              );
            },
          ),

          if (_loadingMore)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator()),
              ),
            ),

          const SliverToBoxAdapter(child: SizedBox(height: 20)),
        ],
      ),
    );
  }
}

class _FilterBar extends StatelessWidget {
  const _FilterBar({
    required this.currentSort,
    required this.currentDiet,
    required this.onSortChanged,
    required this.onDietChanged,
  });

  final SortOption currentSort;
  final DietType? currentDiet;
  final ValueChanged<SortOption> onSortChanged;
  final ValueChanged<DietType?> onDietChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          // Sort picker
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ActionChip(
              avatar: const Icon(Icons.sort_rounded, size: 14),
              label: Text(currentSort.label, style: AppTextStyles.labelMedium),
              onPressed: () async {
                final selected = await showModalBottomSheet<SortOption>(
                  context: context,
                  builder: (_) => _SortSheet(current: currentSort),
                );
                if (selected != null) onSortChanged(selected);
              },
            ),
          ),

          // Diet filter
          for (final dt in [DietType.veg, DietType.vegan, DietType.nonVeg])
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text(
                  dt == DietType.veg
                      ? 'Veg'
                      : dt == DietType.vegan
                          ? 'Vegan'
                          : 'Non-Veg',
                  style: AppTextStyles.labelMedium,
                ),
                selected: currentDiet == dt,
                onSelected: (v) => onDietChanged(v ? dt : null),
                selectedColor: AppColors.primaryLight,
                checkmarkColor: AppColors.primary,
              ),
            ),
        ],
      ),
    );
  }
}

class _SortSheet extends StatelessWidget {
  const _SortSheet({required this.current});
  final SortOption current;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          Text('Sort by', style: AppTextStyles.headlineSmall),
          const SizedBox(height: 8),
          for (final opt in [
            SortOption.nameAsc,
            SortOption.nameDesc,
            SortOption.caloriesAsc,
            SortOption.caloriesDesc,
            SortOption.proteinDesc,
            SortOption.sugarAsc,
            SortOption.recentlyAdded,
          ])
            ListTile(
              title: Text(opt.label),
              trailing:
                  current == opt ? const Icon(Icons.check, color: AppColors.primary) : null,
              onTap: () => Navigator.pop(context, opt),
            ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
