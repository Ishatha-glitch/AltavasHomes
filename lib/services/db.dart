import 'package:supabase_flutter/supabase_flutter.dart';

/// ===========================================================
/// AltavasHomes Database Service
/// -----------------------------------------------------------
/// Central access point for:
/// - Database
/// - Authentication
/// - Storage
/// - Realtime
/// ===========================================================
class Db {
  Db._();

  /// Supabase client
  static final SupabaseClient client = Supabase.instance.client;

  /// Authentication
  static GoTrueClient get auth => client.auth;

  /// Storage
  static SupabaseStorageClient get storage => client.storage;

  /// Current user
  static User? get currentUser => auth.currentUser;

  /// Current session
  static Session? get currentSession => auth.currentSession;

  /// Current user ID
  static String? get currentUserId => currentUser?.id;

  /// Check login state
  static bool get isLoggedIn => currentUser != null;

  // ===========================================================
  // PROFILE
  // ===========================================================

  static Future<Map<String, dynamic>?> getProfile() async {
    if (currentUser == null) return null;

    return await client
        .from('profiles')
        .select()
        .eq('id', currentUser!.id)
        .maybeSingle();
  }

  // ===========================================================
  // LEASES
  // ===========================================================

  static Future<Map<String, dynamic>?> getActiveLease() async {
    if (currentUser == null) return null;

    return await client
        .from('leases')
        .select('*, properties(*)')
        .eq('tenant_id', currentUser!.id)
        .eq('active', true)
        .order('created_at', ascending: false)
        .limit(1)
        .maybeSingle();
  }

  // ===========================================================
  // PAYMENTS
  // ===========================================================

  static Future<List<Map<String, dynamic>>> getPayments() async {
    if (currentUser == null) return [];

    final response = await client
        .from('payments')
        .select()
        .eq('tenant_id', currentUser!.id)
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }

  // ===========================================================
  // PROPERTIES
  // ===========================================================

  static Future<List<Map<String, dynamic>>> getProperties() async {
    final response = await client
        .from('properties')
        .select()
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }

  // ===========================================================
  // REALTIME
  // ===========================================================

  static RealtimeChannel realtime(String channel) {
    return client.channel(channel);
  }

  // ===========================================================
  // SIGN OUT
  // ===========================================================

  static Future<void> signOut() async {
    await auth.signOut();
  }
}
