import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../config/theme/app_theme.dart';
import '../../../shared/widgets/common_widgets.dart';
import '../../../providers/auth_provider.dart';
import '../../director/widgets/d6_notifications_view.dart';
import '../widgets/t1_accueil_view.dart';
import '../widgets/t2_activities_orders_view.dart';
import '../widgets/t3_stock_view.dart';
import '../widgets/t4_stats_view.dart';
import '../widgets/t5_gestion_view.dart';

/// Technician main screen combining planning, operations and stocks
class PlanningScreen extends StatefulWidget {
  const PlanningScreen({super.key});

  @override
  State<PlanningScreen> createState() => _PlanningScreenState();
}

class _PlanningScreenState extends State<PlanningScreen> {
  int _selectedNavIndex = 0;
  bool _isShowingNotifications = false;

  @override
  Widget build(BuildContext context) {
    final authNotifier = context.watch<AuthNotifier>();
    final userName = authNotifier.currentUser?.fullName ?? 'Dr. Koffi';

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
                  Text(_getAppBarTitle(userName)),
                  Text(
                    _getAppBarSubtitle(),
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
              final shouldLogout = await showLogoutConfirmationDialog(context);
              if (!shouldLogout || !mounted) return;

              showActionLoadingDialog(context, message: 'Déconnexion en cours...');
              final success = await authNotifier.logout();
              if (!mounted) return;
              Navigator.of(context, rootNavigator: true).pop();

              if (!success && authNotifier.error != null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(authNotifier.error ?? 'Déconnexion impossible.')),
                );
              }
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
            icon: Icon(Icons.assignment),
            label: 'Activités',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.inventory_2),
            label: 'Stocks',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'Stats'),
          BottomNavigationBarItem(icon: Icon(Icons.business), label: 'Gestion'),
        ],
      ),
    );
  }

  String _getAppBarTitle(String userName) {
    switch (_selectedNavIndex) {
      case 0:
        return 'Bonjour, $userName';
      case 1:
        return 'Activités & Commandes';
      case 2:
        return 'Stock Aliments & Médicaments';
      case 3:
        return 'Statistiques de Production';
      case 4:
        return 'Gestion des Bâtiments';
      default:
        return 'Tableau de bord';
    }
  }

  String _getAppBarSubtitle() {
    switch (_selectedNavIndex) {
      case 0:
        return 'Ferme Akoupé · Suivi technique';
      case 1:
        return 'Gestion des tâches quotidiennes';
      case 2:
        return 'Suivi des approvisionnements';
      case 3:
        return 'Rendements & ponte hebdomadaire';
      case 4:
        return 'Bâtiments, lots et affectation';
      default:
        return 'Ferme Akoupé';
    }
  }

  Widget _buildBody() {
    if (_isShowingNotifications) {
      return const D6NotificationsView();
    }
    switch (_selectedNavIndex) {
      case 0:
        return T1AccueilView(
          onViewNotifications: () {
            setState(() {
              _isShowingNotifications = true;
            });
          },
        );
      case 1:
        return const T2ActivitiesOrdersView();
      case 2:
        return const T3StockView();
      case 3:
        return const T4StatsView();
      case 4:
        return const T5GestionView();
      default:
        return T1AccueilView(
          onViewNotifications: () {
            setState(() {
              _isShowingNotifications = true;
            });
          },
        );
    }
  }
}
