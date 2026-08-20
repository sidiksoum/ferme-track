import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'config/constants/app_constants.dart';
import 'config/theme/app_theme.dart';
import 'core/di/service_locator.dart';
import 'core/utils/app_logger.dart';
import 'data/datasources/local/local_storage.dart';
import 'domain/repositories/authentication_repository.dart';
import 'presentation/features/authentication/screens/login_screen.dart';
import 'presentation/features/director/screens/dashboard_screen.dart';
import 'presentation/features/poultrykeeper/screens/tasks_screen.dart';
import 'presentation/features/warehouse/screens/warehouse_screens.dart';
import 'presentation/features/technician/screens/planning_screen.dart';
import 'presentation/providers/activities_provider.dart';
import 'presentation/providers/auth_provider.dart';
import 'presentation/providers/buildings_provider.dart';
import 'presentation/providers/clients_provider.dart';
import 'presentation/providers/notifications_provider.dart';
import 'presentation/providers/sales_provider.dart';
import 'presentation/providers/stocks_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Initialize local cache
    await HiveCache.init();

    // Setup service locator
    await ServiceLocator.init();

    AppLogger.info('App initialization successful');
  } catch (e, stackTrace) {
    AppLogger.error('App initialization error', e, stackTrace);
  }

  runApp(const FermeTrackApp());
}

/// Main App Widget
class FermeTrackApp extends StatelessWidget {
  const FermeTrackApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Authentication Provider
        ChangeNotifierProvider(
          create: (_) => AuthNotifier(
            getIt<AuthenticationRepository>(),
          ),
        ),
        ChangeNotifierProvider(create: (_) => ActivitiesProvider()),
        ChangeNotifierProvider(create: (_) => BuildingsProvider()),
        ChangeNotifierProvider(create: (_) => StocksProvider()),
        ChangeNotifierProvider(create: (_) => SalesProvider()),
        ChangeNotifierProvider(create: (_) => ClientsProvider()),
        ChangeNotifierProvider(create: (_) => NotificationsProvider()),
      ],
      child: MaterialApp(
        title: AppConstants.appName,
        theme: AppTheme.lightTheme,
        debugShowCheckedModeBanner: false,

        // Localization
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('fr', 'CI'),
          Locale('fr', 'FR'),
          Locale('en', 'US'),
        ],
        locale: const Locale('fr', 'CI'),

        // Routes
        home: const _AppHomeRouter(),
        routes: {
          '/login': (context) => const LoginScreen(),
          '/director': (context) => const DirectorDashboardScreen(),
          '/poultrykeeper': (context) => const PoltrykeeperTasksScreen(),
          '/warehouse': (context) => const SalesScreen(),
          '/technician': (context) => const PlanningScreen(),
        },

        // Navigation
        onGenerateRoute: _generateRoute,

        // Error handling
        builder: (context, child) {
          return Scaffold(
            body: child,
          );
        },
      ),
    );
  }

  /// Generate routes dynamically
  static Route<dynamic>? _generateRoute(RouteSettings settings) {
    AppLogger.debug('Route: ${settings.name}');

    switch (settings.name) {
      case '/login':
        return MaterialPageRoute(builder: (_) => const LoginScreen());
      case '/director':
        return MaterialPageRoute(builder: (_) => const DirectorDashboardScreen());
      case '/poultrykeeper':
        return MaterialPageRoute(builder: (_) => const PoltrykeeperTasksScreen());
      case '/warehouse':
        return MaterialPageRoute(builder: (_) => const SalesScreen());
      case '/technician':
        return MaterialPageRoute(builder: (_) => const PlanningScreen());
      default:
        return MaterialPageRoute(builder: (_) => const SplashScreen());
    }
  }
}

/// App Home Router - Handles navigation based on auth state
class _AppHomeRouter extends StatefulWidget {
  const _AppHomeRouter({super.key});

  @override
  State<_AppHomeRouter> createState() => __AppHomeRouterState();
}

class __AppHomeRouterState extends State<_AppHomeRouter> {
  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    final authNotifier = context.read<AuthNotifier>();
    await authNotifier.init();
  }

  void _navigateToHome(String? role) {
    String route;
    switch (role) {
      case AppConstants.roleDirector:
        route = '/director';
        break;
      case AppConstants.rolePoultryKeeper:
        route = '/poultrykeeper';
        break;
      case AppConstants.roleWarehouseManager:
        route = '/warehouse';
        break;
      case AppConstants.roleTechnician:
      default:
        route = '/login';
    }

    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        Navigator.of(context).pushReplacementNamed(route);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthNotifier>(
      builder: (context, authNotifier, _) {
        if (authNotifier.isLoading) {
          return const SplashScreen();
        }

        if (authNotifier.isLoggedIn && authNotifier.currentUser != null) {
          // Navigate based on role
          return _buildHomeScreen(authNotifier.currentUser!.role);
        }

        return const LoginScreen();
      },
    );
  }

  Widget _buildHomeScreen(String role) {
    switch (role) {
      case AppConstants.roleDirector:
        return const DirectorDashboardScreen();
      case AppConstants.rolePoultryKeeper:
        return const PoltrykeeperTasksScreen();
      case AppConstants.roleWarehouseManager:
        return const SalesScreen();
      case AppConstants.roleTechnician:
        return const PlanningScreen();
      default:
        return const LoginScreen();
    }
  }
}
