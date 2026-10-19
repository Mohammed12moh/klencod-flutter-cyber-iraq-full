/// Non-secret client config. The anon key is PUBLIC by design (protected by
/// RLS on the server) — never put the service_role key or any AI provider
/// key in this app.
class SupabaseConfig {
  static const String url = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://YOUR_PROJECT.supabase.co',
  );
  static const String anonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'YOUR_ANON_KEY',
  );
}
