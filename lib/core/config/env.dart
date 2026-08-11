// ignore_for_file: do_not_use_environment

/// Environment configuration loaded from dart-define at build time.
/// Usage:
///   flutter run --dart-define=SUPABASE_URL=https://xxx.supabase.co
///               --dart-define=SUPABASE_ANON_KEY=eyJ...
class Env {
  Env._();

  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://your-project-ref.supabase.co',
  );

  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'your-anon-key',
  );

  static const String appName = 'FitNGo';
  static const String appVersion = '1.0.0';

  /// OpenFoodFacts — no key required
  static const String offBaseUrl = 'https://world.openfoodfacts.org/api/v2';
  static const String offUserAgent =
      'FitNGo/1.0 (github.com/fitngo; contact@fitngo.app)';
}
