// utils/verification_service.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class VerificationService {
  static final _instance = VerificationService._internal();
  final _supabase = Supabase.instance.client;

  factory VerificationService() => _instance;

  VerificationService._internal();

  Future<bool> verifyPassword(String password) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user?.email == null) return false;

      // Reauthenticate to verify password
      final response = await _supabase.auth.signInWithPassword(
        email: user!.email!,
        password: password,
      );
      return response.user != null;
    } catch (e) {
      return false;
    }
  }

  // Future<bool> showPasswordDialog(BuildContext context) async {
  //   final passwordController = TextEditingController();
  //   bool isVerified = false;

  //   await showDialog(
  //     context: context,
  //     barrierDismissible: false,
  //     builder:
  //         (context) => AlertDialog(
  //           title: const Text('Security Verification'),
  //           content: Column(
  //             mainAxisSize: MainAxisSize.min,
  //             children: [
  //               TextField(
  //                 controller: passwordController,
  //                 obscureText: true,
  //                 decoration: const InputDecoration(
  //                   labelText: 'Enter your password',
  //                   border: OutlineInputBorder(),
  //                 ),
  //               ),
  //               const SizedBox(height: 16),
  //               Text(
  //                 'Please verify your identity to continue',
  //                 style: Theme.of(context).textTheme.bodySmall,
  //               ),
  //             ],
  //           ),
  //           actions: [
  //             TextButton(
  //               onPressed: () => Navigator.pop(context),
  //               child: const Text('Cancel'),
  //             ),
  //             ElevatedButton(
  //               onPressed: () async {
  //                 if (passwordController.text.isEmpty) {
  //                   ScaffoldMessenger.of(context).showSnackBar(
  //                     const SnackBar(
  //                       content: Text('Please enter your password'),
  //                     ),
  //                   );
  //                   return;
  //                 }

  //                 final isValid = await verifyPassword(passwordController.text);
  //                 if (isValid) {
  //                   isVerified = true;
  //                   Navigator.pop(context);
  //                 } else {
  //                   ScaffoldMessenger.of(context).showSnackBar(
  //                     const SnackBar(content: Text('Incorrect password')),
  //                   );
  //                 }
  //               },
  //               child: const Text('Verify'),
  //             ),
  //           ],
  //         ),
  //   );

  //   return isVerified;
  // }
}
