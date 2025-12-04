import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:rmn_accounts/core/services/session_service.dart';
import 'package:rmn_accounts/main.dart';
import 'package:rmn_accounts/shared/widgets/exception_handler.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../utils/views.dart';
import '../services/auth_service.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService;
  final SupabaseClient supabase;
  User? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;
  bool _isAuthenticated = false;

  bool get isAuthenticated => _isAuthenticated;

  AuthProvider(this._authService) : supabase = _authService.supabase;

  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> signUp(
    String name,
    String email,
    String password,
    String confirmpassword,
    String role,
  ) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final error = await _authService.signUpWithEmail(
        name: name,
        email: email,
        password: password,
        confirmPassword: confirmpassword,
        role: role,
      );

      if (error != null) {
        _errorMessage = error;
      }
    } catch (e) {
      _errorMessage = e.toString();
      print('error');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signIn(
    BuildContext context,
    String email,
    String password,
  ) async {
    try {
      final response = await supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.session != null) {
        _currentUser = response.session!.user;
        _isAuthenticated = true;
        notifyListeners();
      } else {
        // Handle case where login succeeded but session is somehow null (unlikely but possible)
        _isAuthenticated = false;
        notifyListeners();
      }
    } catch (e) {
      // Handle error
      _isAuthenticated = false;
      notifyListeners(); // Ensure state reflects failed login
      print("Sign in error: $e"); // Log the error
      rethrow;
    } finally {
      notifyListeners();
    }
  }

  Future<void> initialize() async {
    try {
      // Wait for potential session recovery
      await Future.delayed(const Duration(milliseconds: 300));

      final session = supabase.auth.currentSession;
      _isAuthenticated = session != null;
      _currentUser = supabase.auth.currentUser;

      notifyListeners();
    } catch (e) {
      _errorMessage = 'Session initialization failed';
      notifyListeners();
    }
  }

  void checkAuthentication(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_isAuthenticated) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          RouteNames.sidebar,
          (route) => false,
        );
      } else {
        Navigator.pushNamedAndRemoveUntil(
          context,
          RouteNames.signin,
          (route) => false,
        );
      }
    });
  }

  Future<void> signOut() async {
    await supabase.auth
        .signOut()
        .then((_) {
          _currentUser = null;
          _isAuthenticated = false;
          SessionService.manualLogout();
          notifyListeners();
        })
        .catchError((error) {
          SupabaseExceptionHandler.showErrorSnackbar(
            navigatorKey.currentContext!,
            SupabaseExceptionHandler.handleSupabaseError(error),
          );
        });
    _isAuthenticated = false;
    notifyListeners();
  }
}
