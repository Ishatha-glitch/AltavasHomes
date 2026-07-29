import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthProvider extends ChangeNotifier {
  final SupabaseClient _client = Supabase.instance.client;

  Session? _session;
  Map<String, dynamic>? _profile;

  bool _loading = true;
  bool _busy = false;

  String? _error;

  StreamSubscription<AuthState>? _authSubscription;

  AuthProvider() {
    _initialize();
  }

  //=============================
  // GETTERS
  //=============================

  Session? get session => _session;

  User? get user => _session?.user;

  Map<String, dynamic>? get profile => _profile;

  bool get loading => _loading;

  bool get busy => _busy;

  String? get error => _error;

  String? get role => _profile?['role'] as String?;

  bool get isLoggedIn => _session != null;

  //=============================
  // INITIALIZATION
  //=============================

  Future<void> _initialize() async {
    try {
      _session = _client.auth.currentSession;

      if (_session != null) {
        await _loadProfile();
      }

      _authSubscription =
          _client.auth.onAuthStateChange.listen((event) async {
        _session = event.session;

        if (_session != null) {
          await _loadProfile();
        } else {
          _profile = null;
        }

        notifyListeners();
      });
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  //=============================
  // PROFILE
  //=============================

  Future<void> _loadProfile() async {
    if (_session == null) return;

    try {
      final data = await _client
          .from('profiles')
          .select()
          .eq('id', _session!.user.id)
          .maybeSingle();

      _profile = data;
    } catch (e) {
      _error = e.toString();
    }
  }

  Future<void> reloadProfile() async {
    await _loadProfile();
    notifyListeners();
  }

  //=============================
  // AUTH
  //=============================

  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String fullName,
    required String phone,
    required String role,
    String? serviceCategory,
  }) async {
    _busy = true;
    _error = null;
    notifyListeners();

    try {
      return await _client.auth.signUp(
        email: email,
        password: password,
        data: {
          'full_name': fullName,
          'phone': phone,
          'role': role,
          'service_category': serviceCategory,
        },
      );
    } on AuthException catch (e) {
      _error = e.message;
      rethrow;
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    _busy = true;
    _error = null;
    notifyListeners();

    try {
      return await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );
    } on AuthException catch (e) {
      _error = e.message;
      rethrow;
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    _busy = true;
    _error = null;
    notifyListeners();

    try {
      await _client.auth.signOut();

      _session = null;
      _profile = null;
    } on AuthException catch (e) {
      _error = e.message;
      rethrow;
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  //=============================
  // UTILITIES
  //=============================

  void clearError() {
    _error = null;
    notifyListeners();
  }

  //=============================
  // DISPOSE
  //=============================

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}
