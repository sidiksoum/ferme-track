import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../config/theme/app_theme.dart';
import '../../../shared/widgets/common_widgets.dart';
import '../../../providers/auth_provider.dart';
import '../widgets/m1_accueil_sales_view.dart';
import '../widgets/m2_sale_caisse_view.dart';
import '../widgets/m3_egg_reception_view.dart';
import '../widgets/m4_clients_list_view.dart';
import '../widgets/m5_caisse_view.dart';
import '../widgets/m6_notifications_view.dart';

/// Warehouse Manager main screen combining sales, stock, and clients (M1 - M7)
class SalesScreen extends StatefulWidget {
  const SalesScreen({super.key});

  @override
  State<SalesScreen> createState() => _SalesScreenState();
}

class _SalesScreenState extends State<SalesScreen> {
  int _selectedNavIndex = 0;
  bool _isShowingNotifications = false;

  @override
  Widget build(BuildContext context) {
    final authNotifier = context.watch<AuthNotifier>();
    final userName = authNotifier.currentUser?.fullName ?? 'Yao';

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAF7),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_getAppBarTitle()),
            Text(
              _getAppBarSubtitle(),
              style: AppTypography.appbarSubtitle,
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications, color: Colors.white),
            tooltip: 'Notifications',
            onPressed: () {
              setState(() {
                _isShowingNotifications = !_isShowingNotifications;
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            tooltip: 'Se déconnecter',
            onPressed: () {
              showLogoutConfirmationDialog(context, () async {
                if (!mounted) return;
                showActionLoadingDialog(context, message: 'Déconnexion en cours...');
                final success = await authNotifier.logout();
                if (!mounted) return;
                Navigator.of(context, rootNavigator: true).pop();
                if (!success && authNotifier.error != null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(authNotifier.error ?? 'Déconnexion impossible.')),
                  );
                }
              });
            },
          ),
        ],
      ),
      body: _buildBody(userName),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedNavIndex,
        onTap: (index) {
          setState(() {
            _selectedNavIndex = index;
            _isShowingNotifications = false;
          });
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.primaryDark,
        unselectedItemColor: const Color(0xFF9AA79C),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Accueil',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_cart),
            label: 'Ventes',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_balance_wallet),
            label: 'Caisse',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.inbox),
            label: 'Réceptions',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Clients',
          ),
        ],
      ),
    );
  }

  String _getAppBarTitle() {
    if (_isShowingNotifications) {
      return 'Mes Notifications';
    }
    switch (_selectedNavIndex) {
      case 0:
        return 'Espace Ventes & Stocks';
      case 1:
        return 'Historique & Facturation';
      case 2:
        return 'Journal de Caisse';
      case 3:
        return 'Réception des œufs';
      case 4:
        return 'Fiches Clients';
      default:
        return 'Gestion Magasin';
    }
  }

  String _getAppBarSubtitle() {
    if (_isShowingNotifications) {
      return 'Alertes de réception & validation';
    }
    switch (_selectedNavIndex) {
      case 0:
        return 'Ferme Akoupé · Tableau de bord';
      case 1:
        return 'Journal des factures clients';
      case 2:
        return 'Encaissements, décaissements & solde';
      case 3:
        return 'Validation des collectes du Volailler';
      case 4:
        return 'Créances & informations de contact';
      default:
        return 'Ferme Akoupé';
    }
  }

  Widget _buildBody(String userName) {
    if (_isShowingNotifications) {
      return const M6NotificationsView();
    }
    switch (_selectedNavIndex) {
      case 0:
        return M1AccueilSalesView(userName: userName);
      case 1:
        return const M2SaleCaisseView();
      case 2:
        return const M5CaisseView();
      case 3:
        return const M3EggReceptionView();
      case 4:
        return const M4ClientsListView();
      default:
        return M1AccueilSalesView(userName: userName);
    }
  }
}
