import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/config/env.dart';

/// Thin wrapper around the Supabase client.
/// All repositories receive this via Riverpod injection — never
/// create SupabaseClient directly in UI code.
class SupabaseService {
  SupabaseService._();

  static SupabaseClient get client => Supabase.instance.client;

  static Future<void> initialize() async {
    await Supabase.initialize(
      url: Env.supabaseUrl,
      // ignore: deprecated_member_use
      anonKey: Env.supabaseAnonKey,
    );
  }

  // Convenience getters
  static SupabaseQueryBuilder table(String name) => client.from(name);
  static GoTrueClient get auth => client.auth;
  static SupabaseStorageClient get storage => client.storage;
}
