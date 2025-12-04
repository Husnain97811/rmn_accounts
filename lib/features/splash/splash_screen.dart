import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rmn_accounts/core/services/activity_service.dart';
import 'package:rmn_accounts/utils/views.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.initialize();

    if (mounted) {
      if (authProvider.isAuthenticated) {
        // Get activity service and start tracking
        final activityService = Provider.of<ActivityService>(
          context,
          listen: false,
        );
        activityService.startTracking();

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
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
