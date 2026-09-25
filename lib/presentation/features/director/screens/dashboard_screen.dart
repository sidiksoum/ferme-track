import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../config/theme/app_theme.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/services/system_notification_service.dart';
import '../../../../data/datasources/remote/api_client.dart';
import '../../../shared/widgets/common_widgets.dart';
import '../../../providers/auth_provider.dart';
import '../widgets/d1_dashboard_view.dart';
import '../widgets/d3_activities_view.dart';
import '../widgets/d5_d4_sales_stock_view.dart';
import '../widgets/user_management_view.dart';
import '../widgets/d6_notifications_view.dart';
import '../widgets/d7_stats_table_view.dart';

/// Director Home Screen - Dashboard & Tabs
class DirectorDashboardScreen extends StatefulWidget {
  const DirectorDashboardScreen({super.key});

  @override
  State<DirectorDashboardScreen> createState() =>
      _DirectorDashboardScreenState();
}

class _DirectorDashboardScreenState extends State<DirectorDashboardScreen> {
  final ApiClient _apiClient = getIt<ApiClient>();
  int _selectedNavIndex = 0;
  bool _isShowingNotifications = false;
  int _buildingsCount = 0;

  @override
  void initState() {
    super.initState();
    _loadBuildingsCount();
  }

  Future<void> _loadBuildingsCount({bool forceRefresh = false}) async {
    try {
      final response = await _apiClient.get(
        '/buildings',
        forceRefresh: forceRefresh,
        useCache: true,
      );
      if (mounted && response is List) {
        setState(() {
          _buildingsCount = response.length;
        });
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final authNotifier = context.watch<AuthNotifier>();
    final userName = authNotifier.currentUser?.fullName ?? 'Koffi';
    final farmName = authNotifier.currentUser?.farmName ?? 'Ferme';
    final buildingText = _buildingsCount > 0
        ? ' · $_buildingsCount bâtiment${_buildingsCount > 1 ? 's' : ''} actif${_buildingsCount > 1 ? 's' : ''}'
        : '';

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAF7),
      appBar: AppBar(
        leading: _isShowingNotifications
            ? IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () =>
                    setState(() => _isShowingNotifications = false),
              )
            : null,
        title: _isShowingNotifications
            ? Consumer<SystemNotificationService>(
                builder: (context, notifService, _) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Notifications'),
                    Text(
                      'Alertes (${notifService.unreadCount} non lue${notifService.unreadCount > 1 ? 's' : ''})',
                      style: AppTypography.appbarSubtitle,
                    ),
                  ],
                ),
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Bonjour, $userName'),
                  Text(
                    '$farmName$buildingText',
                    style: AppTypography.appbarSubtitle,
                  ),
                ],
              ),
        actions: [
          Consumer<SystemNotificationService>(
            builder: (context, notifService, _) {
              final unread = notifService.unreadCount;
              return GestureDetector(
                onTap: () => setState(() {
                  _isShowingNotifications = !_isShowingNotifications;
                }),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      const Icon(
                        Icons.notifications_none,
                        size: 22,
                        color: Colors.white,
                      ),
                      if (!_isShowingNotifications && unread > 0)
                        Positioned(
                          top: 10,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: const BoxDecoration(
                              color: AppColors.accent,
                              shape: BoxShape.circle,
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 12,
                              minHeight: 12,
                            ),
                            child: Text(
                              unread > 99 ? '99+' : '$unread',
                              style: const TextStyle(
                                color: AppColors.primaryDark,
                                fontSize: 8,
                                fontWeight: FontWeight.w900,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            tooltip: 'Se déconnecter',
            onPressed: () {
              showLogoutConfirmationDialog(context, () async {
                if (!mounted) return;
                showActionLoadingDialog(
                  context,
                  message: 'Déconnexion en cours...',
                );
                final success = await authNotifier.logout();
                if (!mounted) return;
                Navigator.of(context, rootNavigator: true).pop();
                if (success) {
                  Navigator.of(
                    context,
                  ).pushNamedAndRemoveUntil('/login', (route) => false);
                } else if (authNotifier.error != null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        authNotifier.error ?? 'Déconnexion impossible.',
                      ),
                    ),
                  );
                }
              });
            },
          ),
        ],
      ),
      body: _buildBody(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedNavIndex,
        onTap: (index) => setState(() {
          _selectedNavIndex = index;
          _isShowingNotifications = false;
        }),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.primaryDark,
        unselectedItemColor: const Color(0xFF9AA79C),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Accueil'),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: 'Activités',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart),
            label: 'Statistiques',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.trending_up),
            label: 'Ventes/Stock',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people),
            label: 'Utilisateurs',
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isShowingNotifications) {
      return const D6NotificationsView();
    }
    return IndexedStack(
      index: _selectedNavIndex,
      children: [
        D1DashboardView(
          onViewNotifications: () {
            setState(() {
              _isShowingNotifications = true;
            });
          },
        ),
        const D3ActivitiesView(),
        const D7StatsTableView(),
        const D5D4SalesStockView(),
        const UserManagementView(),
      ],
    );
  }
}
