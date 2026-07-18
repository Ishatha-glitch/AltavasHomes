import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthProvider extends ChangeNotifier {
  final SupabaseClient _client = Supabase.instance.client;

  Session? session;
  Map<String, dynamic>? profile;
  bool loading = true;

  AuthProvider() {
    _init();
  }

  Future<void> _init() async {
    session = _client.auth.currentSession;
    if (session != null) await _loadProfile();
    loading = false;
    notifyListeners();

    _client.auth.onAuthStateChange.listen((data) async {
      session = data.session;
      if (session != null) {
        await _loadProfile();
      } else {
        profile = null;
      }
      notifyListeners();
    });
  }

  Future<void> _loadProfile() async {
    if (session == null) return;
    final data = await _client
        .from('profiles')
        .select()
        .eq('id', session!.user.id)
        .maybeSingle();
    profile = data;
  }

  Future<void> reloadProfile() async {
    await _loadProfile();
    notifyListeners();
  }

  String? get role => profile?['role'] as String?;

  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String fullName,
    required String phone,
    required String role,
    String? serviceCategory,
  }) {
    return _client.auth.signUp(
      email: email,
      password: password,
      data: {
        'full_name': fullName,
        'phone': phone,
        'role': role,
        'service_category': serviceCategory,
      },
    );
  }

  Future<AuthResponse> signIn({required String email, required String password}) {
    return _client.auth.signInWithPassword(email: email, password: password);
  }

  Future<void> signOut() => _client.auth.signOut();
}
