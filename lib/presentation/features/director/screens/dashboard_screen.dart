import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../config/theme/app_theme.dart';
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
  int _selectedNavIndex = 0;
  bool _isShowingNotifications = false;

  @override
  Widget build(BuildContext context) {
    final authNotifier = context.watch<AuthNotifier>();
    final userName = authNotifier.currentUser?.fullName ?? 'Koffi';

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAF7),
      appBar: AppBar(
        leading: _isShowingNotifications
            ? IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => setState(() => _isShowingNotifications = false),
              )
            : null,
        title: _isShowingNotifications
            ? const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Notifications'),
                  Text(
                    'Alertes en attente (3 non lues)',
                    style: AppTypography.appbarSubtitle,
                  ),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Bonjour, $userName'),
                  const Text(
                    'Ferme Akoupé · 6 bâtiments actifs',
                    style: AppTypography.appbarSubtitle,
                  ),
                ],
              ),
        actions: [
          GestureDetector(
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
                  if (!_isShowingNotifications)
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
                        child: const Text(
                          '3',
                          style: TextStyle(
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
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            tooltip: 'Se déconnecter',
            onPressed: () async {
              await authNotifier.logout();
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
    switch (_selectedNavIndex) {
      case 0:
        return D1DashboardView(
          onViewNotifications: () {
            setState(() {
              _isShowingNotifications = true;
            });
          },
        );
      case 1:
        return const D3ActivitiesView();
      case 2:
        return const D7StatsTableView();
      case 3:
        return const D5D4SalesStockView();
      case 4:
        return const UserManagementView();
      default:
        return D1DashboardView(
          onViewNotifications: () {
            setState(() {
              _isShowingNotifications = true;
            });
          },
        );
    }
  }
}
