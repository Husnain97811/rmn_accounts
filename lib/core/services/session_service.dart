// session_service.dart
import 'dart:async';

import 'package:hive/hive.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../main.dart';
import '../../utils/views.dart';

class SessionService {
  static final Box _sessionBox = Hive.box('sessionBox');
  static Timer? _logoutTimer;
  static final _supabase = Supabase.instance.client;

  // Save login time and start timer
  static Future<void> startSession() async {
    final loginTime = DateTime.now();
    await _sessionBox.put('loginTime', loginTime);
    _startTimer(loginTime);
  }

  static void _startTimer(DateTime loginTime) {
    _logoutTimer?.cancel();

    final logoutTime = loginTime.add(const Duration(hours: 8));
    final remainingTime = logoutTime.difference(DateTime.now());

    if (remainingTime.isNegative) {
      _logout();
    } else {
      _logoutTimer = Timer(remainingTime, _logout);
    }
  }

  static Future<void> checkExistingSession() async {
    try {
      final session = Supabase.instance.client.auth.currentSession;
      if (session != null) {
        final loginTime = _sessionBox.get('loginTime');
        if (loginTime == null) {
          await startSession();
          return;
        }

        final sessionValidUntil = session.expiresAt;
        final currentTime = DateTime.now().millisecondsSinceEpoch ~/ 1000;

        if (sessionValidUntil! > currentTime) {
          _startTimer(loginTime);
        } else {
          await _logout();
        }
      }
    } catch (e) {
      await _logout();
    }
  }

  static Future<void> _logout() async {
    await _supabase.auth.signOut();
    await _sessionBox.delete('loginTime');
    _logoutTimer?.cancel();
    navigatorKey.currentState?.pushNamedAndRemoveUntil(
      RouteNames.signin,
      (route) => false,
    );
  }

  static Future<void> manualLogout() async {
    await _logout();
  }
}
