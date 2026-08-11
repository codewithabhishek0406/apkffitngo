import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../providers/search_providers.dart';
import '../../widgets/common/app_error_widget.dart';
import '../../widgets/product/product_card.dart';

class FavoritesScreen extends ConsumerWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favorites = ref.watch(favoritesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Favorites'),
        actions: [
          if (favorites.isNotEmpty)
            TextButton.icon(
              onPressed: () => _confirmClearAll(context, ref),
              icon: const Icon(Icons.delete_outline_rounded, size: 18),
              label: const Text('Clear all'),
              style: TextButton.styleFrom(
                  foregroundColor: AppColors.error),
            ),
        ],
      ),
      body: favorites.isEmpty
          ? AppEmptyWidget(
              title: 'No favorites yet',
              subtitle: 'Tap the heart icon on any product to save it here',
              icon: Icons.favorite_border_rounded,
              action: () => context.push('/search'),
              actionLabel: 'Browse products',
            )
          : GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.72,
              ),
              itemCount: favorites.length,
              itemBuilder: (ctx, i) {
                final p = favorites[i];
                return ProductCard(
                  product: p,
                  onTap: () => ctx.push('/products/${p.slug}', extra: p),
                );
              },
            ),
    );
  }

  Future<void> _confirmClearAll(
      BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Clear favorites?'),
        content: const Text(
            'All saved favorites will be removed from this device.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style:
                ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Clear all'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final items = ref.read(favoritesProvider);
      for (final p in items) {
        await ref.read(favoritesProvider.notifier).toggle(p);
      }
    }
  }
}
