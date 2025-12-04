// services/admin_auth_service.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AdminAuthService {
  static final _instance = AdminAuthService._internal();
  factory AdminAuthService() => _instance;
  AdminAuthService._internal();

  final SupabaseClient _supabase = Supabase.instance.client;
  bool _isVerified = false;

  Future<bool> verifyAdminPassword(
    String password,
    BuildContext context,
  ) async {
    try {
      // Store current user email (not password - we'll ask for it when needed)
      final currentUserEmail = _supabase.auth.currentUser?.email;
      if (currentUserEmail == null) return false;

      // 1. Verify admin credentials
      const adminEmail = 'software.rmn@gmail.com';
      final adminResponse = await _supabase.auth.signInWithPassword(
        email: adminEmail,
        password: password,
      );
      if (adminResponse.user == null) return false;

      // 2. Immediately show dialog to re-authenticate original user
      final originalPassword = await _showReauthDialog(context);
      if (originalPassword == null) return false;

      // 3. Restore original session
      final userResponse = await _supabase.auth.signInWithPassword(
        email: currentUserEmail,
        password: originalPassword,
      );

      _isVerified = userResponse.user != null;
      return _isVerified;
    } catch (e) {
      debugPrint('Admin verification error: $e');
      _isVerified = false;
      return false;
    }
  }

  Future<String?> _showReauthDialog(BuildContext context) async {
    final passwordController = TextEditingController();
    String? password;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => AlertDialog(
            title: const Text('Re-enter Your Password'),
            content: TextField(
              controller: passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Your Password',
                border: OutlineInputBorder(),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  password = passwordController.text;
                  Navigator.pop(context);
                },
                child: const Text('Continue'),
              ),
            ],
          ),
    );

    return password;
  }

  bool get isVerified => _isVerified;
  void resetVerification() => _isVerified = false;
}
