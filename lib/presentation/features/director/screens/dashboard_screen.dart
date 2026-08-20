import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../config/theme/app_theme.dart';
import '../../../shared/widgets/common_widgets.dart';
import '../../../providers/auth_provider.dart';

/// Director Home Screen - Dashboard & Tabs
/// Combines mockups: D1, D2, D3, D4, D5, D6
class DirectorDashboardScreen extends StatefulWidget {
  const DirectorDashboardScreen({super.key});

  @override
  State<DirectorDashboardScreen> createState() =>
      _DirectorDashboardScreenState();
}

class _DirectorDashboardScreenState extends State<DirectorDashboardScreen> {
  int _selectedNavIndex = 0;

  // Active sub-page toggles
  String _activitiesBuildingFilter = 'all'; // all, A, B, C
  String _activitiesTab = 'done'; // planned, done
  String _buildingTab = 'prod'; // prod, sanitary, activities, history
  String _selectedBuildingName = 'Bâtiment C';
  String _salesOrStockToggle = 'sales'; // sales, stock

  bool _isShowingNotifications = false;

  // User management states
  bool _isAddingUser = false;
  bool _isEditingUser = false;
  int? _editingUserIndex;
  final TextEditingController _userNameController = TextEditingController();
  final TextEditingController _userUsernameController = TextEditingController();
  final TextEditingController _userPasswordController = TextEditingController();
  String _userRoleSelection = 'volailler';

  final List<Map<String, String>> _usersList = [
    {
      'name': 'Directeur Général',
      'username': 'directeur',
      'role': 'directeur',
      'password': 'password123',
    },
    {
      'name': 'Dr. Koffi (Technicien)',
      'username': 'technicien',
      'role': 'technicien',
      'password': 'techpassword',
    },
    {
      'name': 'Ama Koffi (Volailler)',
      'username': 'volailler',
      'role': 'volailler',
      'password': 'volaillerpass',
    },
    {
      'name': 'Yao (Magasinier)',
      'username': 'magasinier',
      'role': 'magasinier',
      'password': 'magasinierpass',
    },
  ];

  @override
  void dispose() {
    _userNameController.dispose();
    _userUsernameController.dispose();
    _userPasswordController.dispose();
    super.dispose();
  }

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
          // Notification indicator pointing to D6 page
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
            icon: Icon(Icons.home_work),
            label: 'Bâtiments',
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
      return _buildD6Notifications();
    }
    switch (_selectedNavIndex) {
      case 0:
        return _buildD1Dashboard();
      case 1:
        return _buildD3Activities();
      case 2:
        return _buildD2BuildingDetails();
      case 3:
        return _buildD5D4SalesStock();
      case 4:
        return _buildUserManagement();
      default:
        return _buildD1Dashboard();
    }
  }

  // --- D1: TABLEAU DE BORD ---
  Widget _buildD1Dashboard() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Sync status
          Row(
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: AppColors.syncGreen,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              const Text(
                'Synchronisé à 9:38',
                style: TextStyle(fontSize: 10.5, color: AppColors.inkSoft),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // KPI Grid
          const Text('INDICATEURS DU JOUR', style: AppTypography.labelSmall),
          const SizedBox(height: 9),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 9,
            crossAxisSpacing: 9,
            childAspectRatio: 1.05,
            children: const [
              KpiCard(icon: Icons.home, value: '6', label: 'Bâtiments actifs'),
              KpiCard(
                icon: Icons.pets,
                value: '12 400',
                label: 'Effectif total',
              ),
              KpiCard(
                icon: Icons.egg,
                value: '9 850',
                label: 'Œufs produits / jour',
              ),
              KpiCard(
                icon: Icons.warning_outlined,
                value: '20',
                label: 'Nombre de mortalité',
                iconBackgroundColor: AppColors.errorLight,
                iconColor: AppColors.danger,
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Active Alerts
          const Text('ALERTES ACTIVES', style: AppTypography.labelSmall),
          const SizedBox(height: 9),
          AlertRow(
            title: 'Rupture d\'aliments — Bât. C',
            subtitle: 'Stock à 4 %, réappro. requis',
            type: AlertType.error,
            onTap: () => setState(() => _selectedNavIndex = 4),
          ),
          AlertRow(
            title: 'Échéance client — 2 comptes',
            subtitle: 'Paiement attendu sous 3 jours',
            type: AlertType.warning,
            onTap: () => setState(() => _selectedNavIndex = 4),
          ),
        ],
      ),
    );
  }

  // --- D3: SUIVI DES ACTIVITÉS ---
  Widget _buildD3Activities() {
    final activities = [
      {
        'title': 'Alimentation — Bât. A',
        'meta': '06:30 · Ama K.',
        'status': TaskStatus.done,
        'building': 'A',
      },
      {
        'title': 'Ramassage œufs — Bât. B',
        'meta': '07:15 · Yao B.',
        'status': TaskStatus.done,
        'building': 'B',
      },
      {
        'title': 'Nettoyage — Bât. C',
        'meta': '08:00 · Ama K.',
        'status': TaskStatus.partial,
        'building': 'C',
      },
      {
        'title': 'Vaccination — Bât. C',
        'meta': '08:00 · Yao B.',
        'status': TaskStatus.late,
        'building': 'C',
      },
    ];

    // Filter list
    final filtered = activities.where((act) {
      if (_activitiesBuildingFilter != 'all' &&
          act['building'] != _activitiesBuildingFilter) {
        return false;
      }
      if (_activitiesTab == 'planned') {
        return act['status'] == TaskStatus.todo ||
            act['status'] == TaskStatus.late ||
            act['status'] == TaskStatus.partial;
      } else {
        return act['status'] == TaskStatus.done;
      }
    }).toList();

    return Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Sub tabs
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFEFEFE7),
              borderRadius: BorderRadius.circular(11),
            ),
            padding: const EdgeInsets.all(3),
            child: Row(
              children: [
                Expanded(
                  child: _buildSubTabButton(
                    'Programmées',
                    _activitiesTab == 'planned',
                    () {
                      setState(() => _activitiesTab = 'planned');
                    },
                  ),
                ),
                Expanded(
                  child: _buildSubTabButton(
                    'Réalisées',
                    _activitiesTab == 'done',
                    () {
                      setState(() => _activitiesTab = 'done');
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip(
                  'Tous',
                  _activitiesBuildingFilter == 'all',
                  () {
                    setState(() => _activitiesBuildingFilter = 'all');
                  },
                ),
                _buildFilterChip(
                  'Bât. A',
                  _activitiesBuildingFilter == 'A',
                  () {
                    setState(() => _activitiesBuildingFilter = 'A');
                  },
                ),
                _buildFilterChip(
                  'Bât. B',
                  _activitiesBuildingFilter == 'B',
                  () {
                    setState(() => _activitiesBuildingFilter = 'B');
                  },
                ),
                _buildFilterChip(
                  'Bât. C',
                  _activitiesBuildingFilter == 'C',
                  () {
                    setState(() => _activitiesBuildingFilter = 'C');
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          Expanded(
            child: filtered.isEmpty
                ? const Center(
                    child: Text(
                      'Aucune activité trouvée',
                      style: TextStyle(color: AppColors.inkSoft),
                    ),
                  )
                : ListView.builder(
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final item = filtered[index];
                      final status = item['status'] as TaskStatus;
                      return TaskCard(
                        icon: status == TaskStatus.done
                            ? Icons.check_circle
                            : Icons.calendar_today,
                        title: item['title'] as String,
                        meta: item['meta'] as String,
                        status: status,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  // --- D2: FICHE BÂTIMENT ---
  Widget _buildD2BuildingDetails() {
    final buildings = [
      {
        'name': 'Bâtiment A',
        'birds': '3 400 sujets',
        'mortality': 'Mortalité 0,2 %',
        'yield': '98%',
      },
      {
        'name': 'Bâtiment B',
        'birds': '2 950 sujets',
        'mortality': 'Mortalité 0,3 %',
        'yield': '95%',
      },
      {
        'name': 'Bâtiment C',
        'birds': '2 100 sujets',
        'mortality': 'Mortalité 0,4 %',
        'yield': '87%',
        'alert': true,
      },
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Selector for selected building details
          Container(
            decoration: BoxDecoration(
              color: AppColors.paper,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.line),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedBuildingName,
                isExpanded: true,
                onChanged: (val) {
                  if (val != null) setState(() => _selectedBuildingName = val);
                },
                items: const [
                  DropdownMenuItem(
                    value: 'Bâtiment A',
                    child: Text('Bâtiment A (Lot L-2026-011)'),
                  ),
                  DropdownMenuItem(
                    value: 'Bâtiment B',
                    child: Text('Bâtiment B (Lot L-2026-012)'),
                  ),
                  DropdownMenuItem(
                    value: 'Bâtiment C',
                    child: Text('Bâtiment C (Lot L-2026-014 · 2 100 sujets)'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Tabs
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFEFEFE7),
              borderRadius: BorderRadius.circular(11),
            ),
            padding: const EdgeInsets.all(3),
            child: Row(
              children: [
                Expanded(
                  child: _buildSubTabButton(
                    'Production',
                    _buildingTab == 'prod',
                    () {
                      setState(() => _buildingTab = 'prod');
                    },
                  ),
                ),
                Expanded(
                  child: _buildSubTabButton(
                    'Sanitaire',
                    _buildingTab == 'sanitary',
                    () {
                      setState(() => _buildingTab = 'sanitary');
                    },
                  ),
                ),
                Expanded(
                  child: _buildSubTabButton(
                    'Activités',
                    _buildingTab == 'activities',
                    () {
                      setState(() => _buildingTab = 'activities');
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          if (_buildingTab == 'prod') ...[
            const Text(
              'PRODUCTION D\'ŒUFS — 7 DERNIERS JOURS',
              style: AppTypography.labelSmall,
            ),
            const SizedBox(height: 14),
            // Custom Bar Chart
            Container(
              height: 120,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _buildBar(0.55, 'L', false),
                  _buildBar(0.62, 'M', false),
                  _buildBar(0.48, 'M', false),
                  _buildBar(0.70, 'J', false),
                  _buildBar(0.66, 'V', false),
                  _buildBar(0.74, 'S', false),
                  _buildBar(0.80, 'D', true), // Highlight Sunday
                ],
              ),
            ),
          ] else if (_buildingTab == 'sanitary') ...[
            const Text(
              'VACCINATIONS & TRAITEMENTS',
              style: AppTypography.labelSmall,
            ),
            const SizedBox(height: 9),
            const TaskCard(
              icon: Icons.healing,
              title: 'Newcastle',
              meta: 'Réalisée le 14/08/2026',
              status: TaskStatus.done,
            ),
            const TaskCard(
              icon: Icons.shield,
              title: 'Gumboro Booster',
              meta: 'Planifiée pour le 21/08/2026',
              status: TaskStatus.todo,
            ),
          ] else ...[
            const Text(
              'ACTIVITÉS DU BÂTIMENT',
              style: AppTypography.labelSmall,
            ),
            const SizedBox(height: 9),
            const TaskCard(
              icon: Icons.restaurant,
              title: 'Alimentation du matin',
              meta: 'Confirmée à 06:45',
              status: TaskStatus.done,
            ),
          ],
          const SizedBox(height: 20),

          // Comparative List
          const Text('COMPARATIF BÂTIMENTS', style: AppTypography.labelSmall),
          const SizedBox(height: 9),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: buildings.length,
            itemBuilder: (context, index) {
              final b = buildings[index];
              final isRed = b['alert'] == true;
              return Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: AppColors.line)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: isRed
                            ? AppColors.errorLight
                            : AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        (b['name'] as String).split(' ').last,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isRed
                              ? AppColors.danger
                              : AppColors.primaryDark,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          b['name'] as String,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12.5,
                          ),
                        ),
                        Text(
                          b['mortality'] as String,
                          style: const TextStyle(
                            color: AppColors.inkSoft,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          b['yield'] as String,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12.5,
                            color: isRed ? AppColors.danger : AppColors.primary,
                          ),
                        ),
                        const Text(
                          'rendement',
                          style: TextStyle(
                            color: AppColors.inkSoft,
                            fontSize: 9,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // --- D5 & D4: VENTES / STOCKS ---
  Widget _buildD5D4SalesStock() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(14),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFFEFEFE7),
              borderRadius: BorderRadius.circular(11),
            ),
            padding: const EdgeInsets.all(3),
            child: Row(
              children: [
                Expanded(
                  child: _buildSubTabButton(
                    'Ventes & Créances (D5)',
                    _salesOrStockToggle == 'sales',
                    () {
                      setState(() => _salesOrStockToggle = 'sales');
                    },
                  ),
                ),
                Expanded(
                  child: _buildSubTabButton(
                    'Suivi des Stocks (D4)',
                    _salesOrStockToggle == 'stock',
                    () {
                      setState(() => _salesOrStockToggle = 'stock');
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: _salesOrStockToggle == 'sales'
                ? _buildD5Sales()
                : _buildD4Stock(),
          ),
        ),
      ],
    );
  }

  Widget _buildD5Sales() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Summary card
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppColors.primaryDark,
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Ventes du jour',
                style: TextStyle(color: Colors.white70, fontSize: 10.5),
              ),
              const SizedBox(height: 2),
              const Text(
                '245 000 FCFA',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Container(height: 1, color: Colors.white24),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildSummaryItem('Comptant', '178 000'),
                  _buildSummaryItem('Crédit', '67 000'),
                  _buildSummaryItem('Créances tot.', '126 500'),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        const Text(
          'RÉPARTITION — 7 DERNIERS JOURS',
          style: AppTypography.labelSmall,
        ),
        const SizedBox(height: 14),
        // Bar Chart for Sales
        SizedBox(
          height: 100,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _buildBar(
                0.40,
                'L',
                false,
                color: AppColors.primaryLight,
                border: Border.all(color: const Color(0xFFCFE3CF)),
              ),
              _buildBar(0.58, 'M', false),
              _buildBar(
                0.35,
                'M',
                false,
                color: AppColors.primaryLight,
                border: Border.all(color: const Color(0xFFCFE3CF)),
              ),
              _buildBar(0.64, 'J', false),
              _buildBar(0.70, 'V', false),
              _buildBar(0.85, 'S', true), // Weekend high
              _buildBar(0.60, 'D', false),
            ],
          ),
        ),
        const SizedBox(height: 20),

        const Text('PLUS GROSSES CRÉANCES', style: AppTypography.labelSmall),
        const SizedBox(height: 9),
        Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: const BoxDecoration(
                  color: AppColors.errorLight,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: const Text(
                  'SY',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.danger,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Seydou Yao',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12.5,
                    ),
                  ),
                  Text(
                    'Échéance dépassée',
                    style: TextStyle(color: AppColors.danger, fontSize: 9),
                  ),
                ],
              ),
              const Spacer(),
              const Text(
                '65 000 FCFA',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.danger,
                  fontSize: 12.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildD4Stock() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('NIVEAUX PAR ARTICLE', style: AppTypography.labelSmall),
        const SizedBox(height: 12),
        _buildStockProgress('Aliment ponte 20 kg', 0.68, AppColors.primary),
        _buildStockProgress('Aliment démarrage', 0.22, AppColors.accent),
        _buildStockProgress('Vaccin Newcastle', 0.04, AppColors.danger),
        _buildStockProgress('Œufs commercialisables', 0.81, AppColors.primary),
        const SizedBox(height: 20),

        const Text('DERNIERS MOUVEMENTS', style: AppTypography.labelSmall),
        const SizedBox(height: 9),
        Container(
          padding: const EdgeInsets.all(10),
          margin: const EdgeInsets.only(bottom: 7),
          decoration: BoxDecoration(
            color: AppColors.paper,
            border: Border.all(color: AppColors.line),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Container(
                width: 22,
                height: 22,
                decoration: const BoxDecoration(
                  color: AppColors.successLight,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.arrow_upward,
                  size: 12,
                  color: AppColors.primaryDark,
                ),
              ),
              const SizedBox(width: 9),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Entrée — Aliment ponte',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '+40 sacs · aujourd\'hui',
                    style: TextStyle(fontSize: 10, color: AppColors.inkSoft),
                  ),
                ],
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.all(10),
          margin: const EdgeInsets.only(bottom: 7),
          decoration: BoxDecoration(
            color: AppColors.paper,
            border: Border.all(color: AppColors.line),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Container(
                width: 22,
                height: 22,
                decoration: const BoxDecoration(
                  color: AppColors.errorLight,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.arrow_downward,
                  size: 12,
                  color: AppColors.danger,
                ),
              ),
              const SizedBox(width: 9),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Sortie — Vaccin Newcastle',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '-12 doses · aujourd\'hui',
                    style: TextStyle(fontSize: 10, color: AppColors.inkSoft),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  // --- D6: NOTIFICATIONS ---
  Widget _buildD6Notifications() {
    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        const Text(
          'ALERTES EN ATTENTE (3 NON LUES)',
          style: AppTypography.labelSmall,
        ),
        const SizedBox(height: 9),
        _buildNotificationRow(
          title: 'Mortalité anormale — Bât. C',
          desc: 'Taux 1,8 % sur 24h, seuil dépassé',
          type: AlertType.error,
          unread: true,
        ),
        _buildNotificationRow(
          title: 'Rupture de stock',
          desc: 'Aliment démarrage sous le seuil',
          type: AlertType.error,
          unread: true,
        ),
        _buildNotificationRow(
          title: 'Échéance de paiement',
          desc: 'Seydou Yao — 65 000 FCFA, en retard',
          type: AlertType.warning,
          unread: true,
        ),
        _buildNotificationRow(
          title: 'Retard de livraison',
          desc: 'Commande AB-118 — fournisseur Avicola',
          type: AlertType.info,
          unread: false,
        ),
        _buildNotificationRow(
          title: 'Anomalie signalée — Yao B.',
          desc: 'Fuite d\'abreuvoir, Bâtiment B',
          type: AlertType.error,
          unread: false,
        ),
      ],
    );
  }

  // --- HELPER COMPONENT BUILDERS ---
  Widget _buildSubTabButton(String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.paper : Colors.transparent,
          borderRadius: BorderRadius.circular(9),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: isSelected ? AppColors.primaryDark : AppColors.inkSoft,
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 7),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryDark : AppColors.paper,
          border: Border.all(
            color: isSelected ? AppColors.primaryDark : AppColors.line,
          ),
          borderRadius: BorderRadius.circular(100),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 10.5,
            fontWeight: FontWeight.w500,
            color: isSelected ? Colors.white : AppColors.inkSoft,
          ),
        ),
      ),
    );
  }

  Widget _buildBar(
    double pct,
    String label,
    bool isAccent, {
    Color? color,
    BoxBorder? border,
  }) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Container(
          width: 14,
          height: pct * 75,
          decoration: BoxDecoration(
            color: color ?? (isAccent ? AppColors.accent : AppColors.primary),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(5)),
            border: border,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          label,
          style: const TextStyle(fontSize: 8, color: AppColors.inkSoft),
        ),
      ],
    );
  }

  Widget _buildSummaryItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 10),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildStockProgress(String name, double percent, Color fillColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                name,
                style: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '${(percent * 100).toInt()}%',
                style: const TextStyle(
                  fontSize: 10.5,
                  color: AppColors.inkSoft,
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Container(
            height: 8,
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFFEAEAE3),
              borderRadius: BorderRadius.circular(5),
            ),
            alignment: Alignment.centerLeft,
            child: FractionallySizedBox(
              widthFactor: percent,
              child: Container(
                decoration: BoxDecoration(
                  color: fillColor,
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationRow({
    required String title,
    required String desc,
    required AlertType type,
    required bool unread,
  }) {
    return Row(
      children: [
        Expanded(
          child: AlertRow(title: title, subtitle: desc, type: type),
        ),
        if (unread) ...[
          const SizedBox(width: 8),
          Container(
            width: 7,
            height: 7,
            decoration: const BoxDecoration(
              color: AppColors.accent,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 4),
        ],
      ],
    );
  }

  Widget _buildUserManagement() {
    if (_isAddingUser || _isEditingUser) {
      return _buildUserForm();
    }
    return _buildUserList();
  }

  Widget _buildUserList() {
    return Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _isAddingUser = true;
                  _userNameController.clear();
                  _userUsernameController.clear();
                  _userPasswordController.clear();
                  _userRoleSelection = 'volailler';
                });
              },
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Ajouter un utilisateur'),
            ),
          ),
          const SizedBox(height: 16),
          const Text('UTILISATEURS ENREGISTRÉS', style: AppTypography.labelSmall),
          const SizedBox(height: 9),
          Expanded(
            child: ListView.builder(
              itemCount: _usersList.length,
              itemBuilder: (context, index) {
                final user = _usersList[index];
                IconData roleIcon = Icons.person;
                if (user['role'] == 'directeur') roleIcon = Icons.admin_panel_settings;
                if (user['role'] == 'technicien') roleIcon = Icons.engineering;
                if (user['role'] == 'volailler') roleIcon = Icons.agriculture;
                if (user['role'] == 'magasinier') roleIcon = Icons.store;

                return Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: const BoxDecoration(
                    border: Border(bottom: BorderSide(color: AppColors.line)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: const BoxDecoration(
                          color: AppColors.primaryLight,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(roleIcon, color: AppColors.primaryDark, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user['name']!,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Identifiant: ${user['username']}  ·  Rôle: ${user['role']}',
                              style: const TextStyle(color: AppColors.inkSoft, fontSize: 13),
                            ),
                            Text(
                              'Mot de passe: ${user['password']}',
                              style: const TextStyle(color: AppColors.inkSoft, fontSize: 12, fontStyle: FontStyle.italic),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit, color: AppColors.primaryDark),
                        onPressed: () {
                          setState(() {
                            _isEditingUser = true;
                            _editingUserIndex = index;
                            _userNameController.text = user['name']!;
                            _userUsernameController.text = user['username']!;
                            _userPasswordController.text = user['password']!;
                            _userRoleSelection = user['role']!;
                          });
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: AppColors.danger),
                        onPressed: () {
                          setState(() {
                            final deleted = _usersList.removeAt(index);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Utilisateur ${deleted['name']} supprimé')),
                            );
                          });
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _isEditingUser ? 'MODIFIER L\'UTILISATEUR' : 'AJOUTER UN NOUVEL UTILISATEUR',
            style: AppTypography.label,
          ),
          const SizedBox(height: 16),
          AppInputBox(
            label: 'Nom complet',
            placeholder: 'Ex: Yao Koffi',
            controller: _userNameController,
          ),
          const SizedBox(height: 14),
          AppInputBox(
            label: 'Identifiant (Login)',
            placeholder: 'Ex: yaokoffi',
            controller: _userUsernameController,
          ),
          const SizedBox(height: 14),
          const Text('Rôle de l\'utilisateur', style: AppTypography.label),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: AppColors.paper,
              border: Border.all(color: AppColors.line, width: 1.6),
              borderRadius: BorderRadius.circular(14),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _userRoleSelection,
                isExpanded: true,
                onChanged: (val) {
                  if (val != null) {
                    setState(() => _userRoleSelection = val);
                  }
                },
                items: const [
                  DropdownMenuItem(value: 'directeur', child: Text('Directeur')),
                  DropdownMenuItem(value: 'technicien', child: Text('Technicien')),
                  DropdownMenuItem(value: 'volailler', child: Text('Volailler')),
                  DropdownMenuItem(value: 'magasinier', child: Text('Magasinier')),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          AppInputBox(
            label: 'Mot de passe',
            placeholder: 'Ex: yaopassword',
            controller: _userPasswordController,
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    setState(() {
                      _isAddingUser = false;
                      _isEditingUser = false;
                      _editingUserIndex = null;
                    });
                  },
                  child: const Text('Annuler'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    if (_userNameController.text.isEmpty ||
                        _userUsernameController.text.isEmpty ||
                        _userPasswordController.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Veuillez remplir tous les champs')),
                      );
                      return;
                    }

                    setState(() {
                      if (_isEditingUser && _editingUserIndex != null) {
                        _usersList[_editingUserIndex!] = {
                          'name': _userNameController.text,
                          'username': _userUsernameController.text,
                          'role': _userRoleSelection,
                          'password': _userPasswordController.text,
                        };
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Utilisateur mis à jour')),
                        );
                      } else {
                        _usersList.add({
                          'name': _userNameController.text,
                          'username': _userUsernameController.text,
                          'role': _userRoleSelection,
                          'password': _userPasswordController.text,
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Utilisateur ajouté')),
                        );
                      }
                      _isAddingUser = false;
                      _isEditingUser = false;
                      _editingUserIndex = null;
                    });
                  },
                  child: const Text('Enregistrer'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

