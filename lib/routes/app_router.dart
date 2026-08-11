import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../data/models/category_model.dart';
import '../data/models/product_model.dart';
import '../presentation/screens/category/category_detail_screen.dart';
import '../presentation/screens/category/category_list_screen.dart';
import '../presentation/screens/comparison/comparison_screen.dart';
import '../presentation/screens/favorites/favorites_screen.dart';
import '../presentation/screens/home/home_screen.dart';
import '../presentation/screens/product/product_detail_screen.dart';
import '../presentation/screens/scanner/scanner_screen.dart';
import '../presentation/screens/search/search_screen.dart';
import '../presentation/screens/shell_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  debugLogDiagnostics: false,
  routes: [
    // ── Main shell with bottom nav ──────────────────────────────────────────
    StatefulShellRoute.indexedStack(
      builder: (_, __, shell) => ShellScreen(navigationShell: shell),
      branches: [
        // Tab 0 — Home
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/',
              builder: (_, __) => const HomeScreen(),
              routes: [
                GoRoute(
                  path: 'categories',
                  builder: (_, __) => const CategoryListScreen(),
                  routes: [
                    GoRoute(
                      path: ':slug',
                      builder: (_, state) {
                        final category = state.extra as CategoryModel?;
                        return CategoryDetailScreen(
                          category: category ??
                              CategoryModel(
                                id: '',
                                name: state.pathParameters['slug']!,
                                slug: state.pathParameters['slug']!,
                              ),
                        );
                      },
                    ),
                  ],
                ),
                GoRoute(
                  path: 'products/:slug',
                  builder: (_, state) => ProductDetailScreen(
                    slug: state.pathParameters['slug']!,
                    productPreview: state.extra as ProductModel?,
                  ),
                ),
              ],
            ),
          ],
        ),

        // Tab 1 — Search
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/search',
              builder: (_, state) => SearchScreen(
                initialQuery: state.uri.queryParameters['q'],
              ),
            ),
          ],
        ),

        // Tab 2 — Scanner
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/scanner',
              builder: (_, __) => const ScannerScreen(),
            ),
          ],
        ),

        // Tab 3 — Comparison
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/comparison',
              builder: (_, __) => const ComparisonScreen(),
            ),
          ],
        ),

        // Tab 4 — Favorites
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/favorites',
              builder: (_, __) => const FavoritesScreen(),
            ),
          ],
        ),
      ],
    ),
  ],

  errorBuilder: (context, state) => Scaffold(
    appBar: AppBar(title: const Text('Page Not Found')),
    body: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline_rounded, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          const Text('Page not found',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () => context.go('/'),
            child: const Text('Go home'),
          ),
        ],
      ),
    ),
  ),
);
