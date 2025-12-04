import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileProvider with ChangeNotifier {
  final SupabaseClient _supabase;
  Map<String, dynamic>? profile;
  bool isLoading = false;
  StreamSubscription<AuthState>? _authSub;
  User? currentUser;

  ProfileProvider(this._supabase) {
    _init();
  }

  Future<void> _init() async {
    // Initialize with current session
    currentUser = _supabase.auth.currentUser;
    if (currentUser != null) {
      await loadProfile();
    }

    // Set up auth state listener
    _authSub = _supabase.auth.onAuthStateChange.listen((event) async {
      final session = event.session;
      final newUser = session?.user;

      if (newUser?.id != currentUser?.id) {
        currentUser = newUser;
        if (newUser != null) {
          await loadProfile();
        } else {
          profile = null;
          notifyListeners();
        }
      }
    });
  }

  Future<void> loadProfile() async {
    if (currentUser == null) {
      profile = null;
      notifyListeners();
      return;
    }

    isLoading = true;
    notifyListeners();

    try {
      final response =
          await _supabase
              .from('profiles')
              .select()
              .eq('user_id', currentUser!.id)
              .maybeSingle();

      profile = response != null ? Map<String, dynamic>.from(response) : null;
    } catch (error, stackTrace) {
      debugPrint('Error loading profile: $error');
      debugPrint('Stack trace: $stackTrace');
      profile = null;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // bool get isAdmin {
  //   final role = profile?['role']?.toString().toLowerCase();
  //   return role == 'admin';
  // }

  Future<bool> verifyAdminPassword(String password) async {
    try {
      // Store original session tokens
      final originalSession = _supabase.auth.currentSession;
      if (originalSession == null) return false;

      // Attempt admin login
      const adminEmail = 'software.rmn@gmail.com';
      final adminResponse = await _supabase.auth.signInWithPassword(
        email: adminEmail,
        password: password,
      );

      // Immediately restore original session
      await _supabase.auth.setSession(
        originalSession.accessToken,
        // refreshToken: originalSession.refreshToken,
      );

      return adminResponse.user != null;
    } catch (e) {
      debugPrint('Admin verification error: $e');
      return false;
    }
  }

  bool get isAdmin => profile?['role']?.toString().toLowerCase() == 'admin';
  bool get isLoggedIn => currentUser != null;

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }
}
