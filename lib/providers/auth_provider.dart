import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthProvider extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;

  Session? _session;
  Map<String, dynamic>? _profile;

  bool _loading = true;
  bool _busy = false;
  String? _error;

  Session? get session => _session;
  Map<String, dynamic>? get profile => _profile;

  bool get loading => _loading;
  bool get busy => _busy;

  String? get error => _error;
  String? get role => _profile?['role'];

  AuthProvider() {
    _initialize();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  Future<void> _initialize() async {
    _session = _supabase.auth.currentSession;

    if (_session != null) {
      await _loadProfile();
    } else {
      _loading = false;
      notifyListeners();
    }

    _supabase.auth.onAuthStateChange.listen((data) async {
      _session = data.session;

      if (_session != null) {
        await _loadProfile();
      } else {
        _profile = null;
        _loading = false;
        notifyListeners();
      }
    });
  }

  Future<void> _loadProfile() async {
    try {
      final user = _supabase.auth.currentUser;

      if (user == null) {
        _profile = null;
        _loading = false;
        notifyListeners();
        return;
      }

      final response = await _supabase
          .from('profiles')
          .select()
          .eq('id', user.id)
          .single();

      _profile = Map<String, dynamic>.from(response);
    } catch (e) {
      debugPrint('Profile loading error: $e');
      _error = 'Could not load your profile: $e';
      _profile = null;
    }

    _loading = false;
    notifyListeners();
  }

  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    try {
      _busy = true;
      _error = null;
      notifyListeners();

      await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      // Don't rely on the onAuthStateChange listener having already
      // fired by this point — read the session directly so
      // refreshProfile() doesn't see a stale null and bail out.
      _session = _supabase.auth.currentSession;

      await refreshProfile();

      return true;
    } on AuthException catch (e) {
      _error = e.message;
      return false;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  Future<bool> signUp({
    required String email,
    required String password,
    required String fullName,
    required String phone,
    required String role,
    String? serviceCategory,
  }) async {
    try {
      _busy = true;
      _error = null;
      notifyListeners();

      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {
          'full_name': fullName,
          'phone': phone,
          'role': role,
          'service_category': serviceCategory,
        },
      );

      if (response.user != null) {
        _session = _supabase.auth.currentSession;
        await refreshProfile();
      }

      return true;
    } on AuthException catch (e) {
      _error = e.message;
      return false;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    await _supabase.auth.signOut();

    _session = null;
    _profile = null;

    notifyListeners();
  }

  Future<void> refreshProfile() async {
    if (_session == null) return;

    _loading = true;
    notifyListeners();

    await _loadProfile();
  }
}
