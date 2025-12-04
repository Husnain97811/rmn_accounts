// import 'dart:io';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:provider/provider.dart';
import 'package:rmn_accounts/core/config/supabase_config.dart';
import 'package:rmn_accounts/core/services/activity_service.dart';
import 'utils/views.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  GestureBinding.instance.resamplingEnabled = true;

  // Initialize Hive with Windows-compatible path
  await Hive.initFlutter();

  // Register DateTime adapter
  Hive.registerAdapter(DateTimeAdapter());

  final encryptionKey = Hive.generateSecureKey();

  // Initialize encrypted box
  await Hive.openBox(
    'sessionBox',
    encryptionCipher: HiveAesCipher(encryptionKey),
  );

  // initialize supabase
  await SupabaseConfig.initialize();

  // Supabase.instance.client.auth.onAuthStateChange.listen((event) {
  //   final session = event.session;

  // });

  runApp(
    MultiProvider(
      providers: [
        Provider(create: (_) => AuthService()),
        ChangeNotifierProvider(
          create: (context) => AuthProvider(context.read<AuthService>()),
        ),
        ChangeNotifierProvider(create: (_) => PermissionsProvider()),
        Provider(create: (_) => ActivityService()), // Add ActivityService
        ChangeNotifierProvider(create: (_) => MainLayoutProvider()),
        ChangeNotifierProvider(create: (_) => LoadingProvider()),
        ChangeNotifierProvider(create: (_) => SidebarProvider()),
        ChangeNotifierProvider(create: (_) => CashFlowProvider()),
        ChangeNotifierProvider(create: (_) => ChartVisibilityProvider()),
        ChangeNotifierProvider(
          create: (_) => ProfileProvider(Supabase.instance.client),
        ),

        ChangeNotifierProvider(
          create: (_) => InvestorProvider(Supabase.instance.client),
        ),
      ],
      child: MyApp(),
    ),
  );
}

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Sizer(
      builder: (p0, p1, p2) {
        return MaterialApp(
          // showPerformanceOverlay: true, // Helps identify rendering issues
          // checkerboardRasterCacheImages: true, // Highlights cached images
          navigatorKey: navigatorKey,
          builder: (context, child) {
            ErrorWidget.builder = (errorDetails) {
              return Column(
                children: [
                  Center(
                    child: Text(
                      'Something went wrong.\n Please contact developer\n main.',
                    ),
                  ),
                  Text(errorDetails.exceptionAsString()),
                ],
              );
            };
            return child!;
          },
          debugShowCheckedModeBanner: false,
          title: 'RMN Accounting',
          initialRoute: RouteNames.splashscreen,
          onGenerateRoute: Routes.generateRoute,
          // home: const AuthWrapper(),
        );
      },
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  late ActivityService _activityService;

  @override
  void initState() {
    super.initState();
    _activityService = ActivityService();
  }

  @override
  void dispose() {
    _activityService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final permissionsProvider = Provider.of<PermissionsProvider>(context);
    final mainLayoutProvider = Provider.of<MainLayoutProvider>(context);
    return StreamBuilder<AuthState>(
      stream: authProvider.supabase.auth.onAuthStateChange,
      builder: (context, snapshot) {
        final user = authProvider.currentUser;
        if (user != null) {
          return FutureBuilder(
            future:
                authProvider.supabase
                    .from('profiles')
                    .select()
                    .eq('user_id', user.id)
                    .single(),
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                final role = UserRole.values.firstWhere(
                  (e) => e.name == snapshot.data!['role'],
                );
                permissionsProvider.setUserRole(role);
                mainLayoutProvider.setMenuItems(role);

                // Start activity tracking
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _activityService.startTracking();
                });

                return ActivityTrackerWrapper(
                  activityService: _activityService,
                  child: const MainLayout(child: DashboardScreen()),
                );
              }
              return const Center(child: CircularProgressIndicator());
            },
          );
        }
        return const SplashScreen();
      },
    );
  }
}
