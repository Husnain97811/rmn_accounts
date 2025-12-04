import 'package:flutter/material.dart';
import 'package:rmn_accounts/features/auth/presentation/views/forgot_pass.dart';
import 'package:rmn_accounts/features/auth/presentation/views/reset_pass_otp.dart';
import 'package:rmn_accounts/main.dart';
import 'package:rmn_accounts/shared/widgets/sidebar.dart';
import 'package:rmn_accounts/utils/views.dart';

class Routes {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case RouteNames.splashscreen:
        return MaterialPageRoute(builder: (context) => SplashScreen());
      case RouteNames.signin:
        return MaterialPageRoute(builder: (context) => SignInScreen());
      case RouteNames.forgotPass:
        return MaterialPageRoute(builder: (context) => ForgotPasswordScreen());
      // case RouteNames.resetPassOtp:
      //   return MaterialPageRoute(
      //     builder: (context) => ResetPasswordOtpScreen(),
      //   );
      case RouteNames.signup:
        return MaterialPageRoute(builder: (context) => SignUpScreen());
      case RouteNames.sidebar:
        return MaterialPageRoute(builder: (context) => Sidebar());
      case RouteNames.dashboard:
        return MaterialPageRoute(builder: (context) => DashboardScreen());
      case RouteNames.authWrapper:
        return MaterialPageRoute(builder: (context) => AuthWrapper());
      case RouteNames.cashflow_entries:
        return MaterialPageRoute(builder: (context) => CashFlowEntriesScreen());

      default:
        return MaterialPageRoute(
          builder: (context) {
            return Scaffold(body: Center(child: Text('No route generated ')));
          },
        );
    }
  }
}

// class SideBar {}

class RouteNames {
  static const String splashscreen = '/splash_screen';
  static const String signup = '/signup';
  static const String signin = '/signin';
  static const String forgotPass = '/forgot_password';
  static const String resetPassOtp = '/reset-password-otp';
  static const String dashboard = '/dashboard';
  static const String main = '/main';
  static const String sidebar = '/sidebar';
  static const String customers = '/customers';
  static const String properties = '/properties';
  static const String authWrapper = '/auth_wrapper';
  static const String cashflow_entries = '/cashflow_entries';
}
