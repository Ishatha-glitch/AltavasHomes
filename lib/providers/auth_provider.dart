import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthProvider extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;

  Session? _session;
  Map<String, dynamic>? _profile;
  bool _loading = true;

  Session? get session => _session;
  Map<String, dynamic>? get profile => _profile;
  bool get loading => _loading;

  String? get role => _profile?['role'];

  AuthProvider() {
    _initialize();
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
      debugPrint("Profile loading error: $e");
      _profile = null;
    }

    _loading = false;
    notifyListeners();
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
