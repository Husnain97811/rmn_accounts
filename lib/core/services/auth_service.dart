import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rmn_accounts/core/config/app_constants.dart';
import 'package:rmn_accounts/utils/views.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final SupabaseClient supabase;
  String? _currentUserEmail;
  String? _currentUserPassword;
  AuthService() : supabase = Supabase.instance.client;

  Future<void> storeCurrentUserCredentials() async {
    _currentUserEmail = supabase.auth.currentUser?.email;
    // Note: In production, you should use a secure storage solution
    // and only store this temporarily in memory
  }

  Future<bool> verifyAdminPassword(
    String password,
    BuildContext context,
  ) async {
    try {
      // Store current user email
      _currentUserEmail = Supabase.instance.client.auth.currentUser?.email;

      // Replace with your admin email
      const adminEmail = 'software.rmn@gmail.com';

      // Show loading indicator
      _showLoading(context, true);

      // Verify admin credentials
      final response = await Supabase.instance.client.auth.signInWithPassword(
        email: adminEmail,
        password: password,
      );

      if (response.user == null) return false;

      return true;
    } catch (e) {
      return false;
    } finally {
      // Re-authenticate original user
      await _reauthenticateOriginalUser(context);
      _showLoading(context, false);
    }
  }

  Future<void> _reauthenticateOriginalUser(BuildContext context) async {
    if (_currentUserEmail == null) return;

    try {
      final password = await _showPasswordDialog(context);
      if (password != null) {
        await Supabase.instance.client.auth.signInWithPassword(
          email: _currentUserEmail!,
          password: password,
        );
      }
    } catch (e) {
      await Supabase.instance.client.auth.signOut();
    }
  }

  Future<String?> signUpWithEmail({
    required String name,
    required String email,
    required String password,
    required String role,
    required String confirmPassword,
  }) async {
    try {
      LoadingProvider().startLoading();
      // Validate only allowed sign-up roles
      if (!UserRole.signUpRoles.any((e) => e.name == role)) {
        return 'Invalid role selected for sign-up';
      }

      final authResponse = await supabase.auth.signUp(
        email: email,
        password: password,
        //add metadata here
        data: {'name': name},
      );

      if (authResponse.user == null) return 'Sign-up failed. Please try again.';

      await supabase.from('profiles').upsert({
        'user_id': authResponse.user?.id,
        'name': name,
        'email': email,
        'role': role,
      });

      return null;
    } catch (e) {
      LoadingProvider().stopLoading();

      return e.toString();
    } finally {
      LoadingProvider().stopLoading();
    }
  }

  Future<String?> signInWithEmail(String email, String password) async {
    try {
      final response = await supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      if (response.session == null) {
        return 'Sign-in failed. Please check your credentials.';
      }
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> _showPasswordDialog(BuildContext context) async {
    final passwordController = TextEditingController();
    String? password;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => AlertDialog(
            title: const Text('Reauthentication Required'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Please enter your password to continue'),
                const SizedBox(height: 16),
                TextField(
                  controller: passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Your Password',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
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

  void _showLoading(BuildContext context, bool show) {
    final loadingProvider = Provider.of<LoadingProvider>(
      context,
      listen: false,
    );
    loadingProvider.startLoading();
  }
}
