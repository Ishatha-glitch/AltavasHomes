import 'package:supabase_flutter/supabase_flutter.dart';

/// Thin convenience accessor. Screens can also just call
/// Supabase.instance.client directly — this exists so query code
/// reads a bit shorter across the app.
class Db {
  static SupabaseClient get client => Supabase.instance.client;
}
