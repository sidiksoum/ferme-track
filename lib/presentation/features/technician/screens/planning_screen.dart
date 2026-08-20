import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../config/theme/app_theme.dart';
import '../../../shared/widgets/common_widgets.dart';
import '../../../providers/auth_provider.dart';

/// Technician main screen combining planning and sub-screens (T1 - T8)
class PlanningScreen extends StatefulWidget {
  const PlanningScreen({super.key});

  @override
  State<PlanningScreen> createState() => _PlanningScreenState();
}

class _PlanningScreenState extends State<PlanningScreen> {
  int _selectedNavIndex = 0;

  // Toggles and page selectors
  String _selectedBuildingFilter = 'all'; // all, A, B, C, D
  bool _isAddingActivity = false; // T2 toggle
  String _activityType = 'feeding'; // feeding, water, eggs, vaccine
  int _activityPriority = 2; // 1, 2, 3

  // T2 Activity states
  String _selectedBuildingForActivity = 'A';
  String _selectedResponsibleForActivity = 'Ama Koffi — Volailler';
  final TextEditingController _activityNotesController =
      TextEditingController();
  DateTime _startDate = DateTime.now();
  TimeOfDay _startTime = const TimeOfDay(hour: 8, minute: 0);
  DateTime _endDate = DateTime.now();
  TimeOfDay _endTime = const TimeOfDay(hour: 9, minute: 0);

  @override
  void dispose() {
    _activityNotesController.dispose();
    super.dispose();
  }

  // T3 / T4 order states
  String _orderTab = 'pending'; // pending, delivered, draft
  Map<String, dynamic>? _selectedOrderToReceive; // T4 details
  String _discrepancyReason = 'casse'; // casse, missing

  // T5 batch allocation
  String _selectedBuildingForBatch = 'D'; // A, D, E

  // T7 consumption details
  String _consoBuilding = 'C';

  // T8 validation states
  List<Map<String, dynamic>> _retours = [
    {
      'id': '1',
      'title': 'Nettoyage — Bât. C',
      'desc': 'Ama K. · « Zone 2 non terminée »',
      'status': 'revoir',
    },
    {
      'id': '2',
      'title': 'Anomalie signalée — Bât. B',
      'desc': 'Yao B. · Fuite d\'abreuvoir, photo jointe',
      'status': 'urgent',
    },
    {
      'id': '3',
      'title': 'Alimentation — Bât. A',
      'desc': 'Ama K. · Réalisée à 06:34',
      'status': 'validee',
    },
    {
      'id': '4',
      'title': 'Ramassage œufs — Bât. B',
      'desc': 'Yao B. · Réalisée à 07:18',
      'status': 'validee',
    },
  ];

  // Selected sub-operation under Tab 3 (Opérations)
  String _selectedOperation =
      'menu'; // menu, allocation, consumption, validation

  @override
  Widget build(BuildContext context) {
    final authNotifier = context.watch<AuthNotifier>();

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAF7),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_getAppBarTitle()),
            Text(_getAppBarSubtitle(), style: AppTypography.appbarSubtitle),
          ],
        ),
        actions: [
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
        onTap: (index) {
          setState(() {
            _selectedNavIndex = index;
            _isAddingActivity = false;
            _selectedOrderToReceive = null;
            _selectedOperation = 'menu';
          });
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.primaryDark,
        unselectedItemColor: const Color(0xFF9AA79C),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: 'Planification',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.healing),
            label: 'Sanitaire',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_cart),
            label: 'Commandes',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.build), label: 'Opérations'),
        ],
      ),
    );
  }

  String _getAppBarTitle() {
    switch (_selectedNavIndex) {
      case 0:
        return _isAddingActivity ? 'Nouvelle activité' : 'Planification';
      case 1:
        return 'Programme sanitaire';
      case 2:
        return _selectedOrderToReceive != null
            ? 'Réceptionner'
            : 'Commandes fournisseurs';
      case 3:
        if (_selectedOperation == 'allocation') return 'Affecter un lot';
        if (_selectedOperation == 'consumption') return 'Consommation';
        if (_selectedOperation == 'validation') return 'Retours du jour';
        return 'Opérations techniques';
      default:
        return 'Technicien';
    }
  }

  String _getAppBarSubtitle() {
    switch (_selectedNavIndex) {
      case 0:
        return _isAddingActivity
            ? 'Bâtiment A · Lot L-2026-011'
            : 'Semaine du 3 au 9 août';
      case 1:
        return 'Vaccinations · Traitements';
      case 2:
        return _selectedOrderToReceive != null
            ? '${_selectedOrderToReceive!['supplier']} · #${_selectedOrderToReceive!['ref']}'
            : '8 commandes ce mois-ci';
      case 3:
        if (_selectedOperation == 'allocation')
          return 'Lot L-2026-019 · 2 000 poussins';
        if (_selectedOperation == 'consumption') return 'Bâtiment C · Aliments';
        if (_selectedOperation == 'validation') return '4 tâches à valider';
        return 'Gestion et suivis';
      default:
        return 'Ferme Akoupé';
    }
  }

  Widget _buildBody() {
    switch (_selectedNavIndex) {
      case 0:
        return _isAddingActivity ? _buildT2NewActivity() : _buildT1Planning();
      case 1:
        return _buildT6SanitaryProgram();
      case 2:
        return _selectedOrderToReceive != null
            ? _buildT4ReceiveDelivery()
            : _buildT3SupplierOrders();
      case 3:
        return _buildOperationsTab();
      default:
        return _buildT1Planning();
    }
  }

  // --- T1: PLANIFICATION ---
  Widget _buildT1Planning() {
    final activities = [
      {
        'title': 'Alimentation',
        'meta': '06:30 · Ama K.',
        'status': TaskStatus.done,
        'building': 'A',
      },
      {
        'title': 'Abreuvement',
        'meta': '10:00 · Ama K.',
        'status': TaskStatus.todo,
        'building': 'A',
      },
      {
        'title': 'Vaccination Newcastle',
        'meta': '08:00 · Yao B.',
        'status': TaskStatus.late,
        'building': 'C',
      },
      {
        'title': 'Pesée hebdomadaire',
        'meta': '16:00 · Yao B.',
        'status': TaskStatus.todo,
        'building': 'B',
      },
    ];

    final filtered = activities
        .where(
          (act) =>
              _selectedBuildingFilter == 'all' ||
              act['building'] == _selectedBuildingFilter,
        )
        .toList();

    return Column(
      children: [
        // Sync indicator
        Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          color: Colors.transparent,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: AppColors.accent,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              const Text(
                '2 en attente d\'envoi',
                style: TextStyle(fontSize: 10.5, color: AppColors.inkSoft),
              ),
            ],
          ),
        ),

        // Building Filter Scroll
        SizedBox(
          height: 36,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            children: [
              _buildFilterChip('Tous', _selectedBuildingFilter == 'all', () {
                setState(() => _selectedBuildingFilter = 'all');
              }),
              _buildFilterChip('Bât. A', _selectedBuildingFilter == 'A', () {
                setState(() => _selectedBuildingFilter = 'A');
              }),
              _buildFilterChip('Bât. B', _selectedBuildingFilter == 'B', () {
                setState(() => _selectedBuildingFilter = 'B');
              }),
              _buildFilterChip('Bât. C', _selectedBuildingFilter == 'C', () {
                setState(() => _selectedBuildingFilter = 'C');
              }),
            ],
          ),
        ),
        const SizedBox(height: 12),

        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            itemCount: filtered.length,
            itemBuilder: (context, index) {
              final act = filtered[index];
              IconData icon = Icons.calendar_today;
              if (act['title'] == 'Alimentation') icon = Icons.restaurant;
              if (act['title'] == 'Abreuvement') icon = Icons.water_drop;
              if (act['title'] == 'Vaccination Newcastle') icon = Icons.healing;
              if (act['title'] == 'Pesée hebdomadaire') icon = Icons.scale;

              return TaskCard(
                icon: icon,
                title: act['title'] as String,
                meta: act['meta'] as String,
                status: act['status'] as TaskStatus,
              );
            },
          ),
        ),

        // Add Activity Button
        Padding(
          padding: const EdgeInsets.all(14),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => setState(() => _isAddingActivity = true),
              icon: const Icon(Icons.add),
              label: const Text('Programmer une activité'),
            ),
          ),
        ),
      ],
    );
  }

  // --- T2: NOUVELLE ACTIVITÉ ---
  Widget _buildT2NewActivity() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('TYPE D\'ACTIVITÉ', style: AppTypography.label),
          const SizedBox(height: 8),
          GridView.count(
            crossAxisCount: 4,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 7,
            crossAxisSpacing: 7,
            childAspectRatio: 0.85,
            children: [
              _buildTypeCell('feeding', Icons.restaurant, 'Alim.'),
              _buildTypeCell('water', Icons.water_drop, 'Eau'),
              _buildTypeCell('eggs', Icons.egg, 'Œufs'),
              _buildTypeCell('vaccine', Icons.healing, 'Vaccin'),
            ],
          ),
          const SizedBox(height: 16),

          const Text('BÂTIMENT', style: AppTypography.label),
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
                value: _selectedBuildingForActivity,
                isExpanded: true,
                onChanged: (val) {
                  if (val != null) {
                    setState(() => _selectedBuildingForActivity = val);
                  }
                },
                items: const [
                  DropdownMenuItem(value: 'A', child: Text('Bâtiment A')),
                  DropdownMenuItem(value: 'B', child: Text('Bâtiment B')),
                  DropdownMenuItem(value: 'C', child: Text('Bâtiment C')),
                  DropdownMenuItem(value: 'D', child: Text('Bâtiment D')),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),

          const Text('RESPONSABLE', style: AppTypography.label),
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
                value: _selectedResponsibleForActivity,
                isExpanded: true,
                onChanged: (val) {
                  if (val != null) {
                    setState(() => _selectedResponsibleForActivity = val);
                  }
                },
                items: const [
                  DropdownMenuItem(
                    value: 'Ama Koffi — Volailler',
                    child: Text('Ama Koffi — Volailler'),
                  ),
                  DropdownMenuItem(
                    value: 'Yao B. — Volailler',
                    child: Text('Yao B. — Magasinier'),
                  ),
                  DropdownMenuItem(
                    value: 'Dr. Koffi — Volailler',
                    child: Text('Dr. Koffi — Technicien'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),

          const Text('DÉBUT DE L\'ACTIVITÉ', style: AppTypography.label),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: AppInputBox(
                  placeholder: _formatDate(_startDate),
                  readOnly: true,
                  onTap: _selectStartDate,
                  suffix: const Icon(
                    Icons.calendar_today,
                    size: 16,
                    color: AppColors.inkSoft,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AppInputBox(
                  placeholder: _formatTime(_startTime),
                  readOnly: true,
                  onTap: _selectStartTime,
                  suffix: const Icon(
                    Icons.access_time,
                    size: 16,
                    color: AppColors.inkSoft,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          const Text('FIN DE L\'ACTIVITÉ', style: AppTypography.label),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: AppInputBox(
                  placeholder: _formatDate(_endDate),
                  readOnly: true,
                  onTap: _selectEndDate,
                  suffix: const Icon(
                    Icons.calendar_today,
                    size: 16,
                    color: AppColors.inkSoft,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AppInputBox(
                  placeholder: _formatTime(_endTime),
                  readOnly: true,
                  onTap: _selectEndTime,
                  suffix: const Icon(
                    Icons.access_time,
                    size: 16,
                    color: AppColors.inkSoft,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          const Text('NOTES / CONSIGNES', style: AppTypography.label),
          const SizedBox(height: 6),
          AppInputBox(
            placeholder: 'Détails et instructions pour la tâche...',
            maxLines: 3,
            controller: _activityNotesController,
          ),
          const SizedBox(height: 14),

          const Text('NIVEAU DE PRIORITÉ', style: AppTypography.label),
          const SizedBox(height: 8),
          Row(
            children: List.generate(3, (index) {
              final active = index < _activityPriority;
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _activityPriority = index + 1),
                  child: Container(
                    height: 8,
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    decoration: BoxDecoration(
                      color: active
                          ? AppColors.accent
                          : const Color(0xFFEAEAE3),
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 24),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                setState(() => _isAddingActivity = false);
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('Activité créée')));
              },
              child: const Text('Créer l\'activité'),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => setState(() => _isAddingActivity = false),
              child: const Text('Annuler'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeCell(String id, IconData icon, String label) {
    final selected = _activityType == id;
    return GestureDetector(
      onTap: () => setState(() => _activityType = id),
      child: Container(
        decoration: BoxDecoration(
          color: selected ? AppColors.primaryLight : AppColors.paper,
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.line,
            width: 1.4,
          ),
          borderRadius: BorderRadius.circular(11),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: selected ? AppColors.primaryDark : AppColors.inkSoft,
            ),
            const SizedBox(height: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: selected ? AppColors.primaryDark : AppColors.inkSoft,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- T6: PROGRAMME SANITAIRE ---
  Widget _buildT6SanitaryProgram() {
    return ListView(
      padding: const EdgeInsets.all(14),
      children: const [
        Text('PROCHAINES ÉCHÉANCES', style: AppTypography.labelSmall),
        SizedBox(height: 9),
        TaskCard(
          icon: Icons.healing,
          title: 'Vaccination Newcastle',
          meta: 'Bât. C · Lot L-014 · aujourd\'hui',
          status: TaskStatus.late,
        ),
        TaskCard(
          icon: Icons.healing,
          title: 'Traitement anti-parasitaire',
          meta: 'Bât. A · Lot L-011 · 6 août',
          status: TaskStatus.todo,
        ),
        TaskCard(
          icon: Icons.cleaning_services,
          title: 'Désinfection complète',
          meta: 'Bât. E · avant nouveau lot · 9 août',
          status: TaskStatus.todo,
        ),
        TaskCard(
          icon: Icons.check_circle,
          title: 'Vaccination Gumboro',
          meta: 'Bât. B · Lot L-013 · confirmée',
          status: TaskStatus.done,
        ),
      ],
    );
  }

  // --- T3: COMMANDES FOURNISSEURS ---
  Widget _buildT3SupplierOrders() {
    final orders = [
      {
        'supplier': 'Avicola SARL',
        'details': '40 sacs aliment ponte',
        'ref': '118',
        'status': 'En attente',
        'isLate': false,
      },
      {
        'supplier': 'VetPlus Côte d\'Ivoire',
        'details': '200 doses vaccin',
        'ref': '119',
        'status': 'Retard',
        'isLate': true,
      },
      {
        'supplier': 'Couvoir Béré',
        'details': '2 000 poussins',
        'ref': '120',
        'status': 'Confirmée',
        'isLate': false,
      },
    ];

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
                    'En cours',
                    _orderTab == 'pending',
                    () {
                      setState(() => _orderTab = 'pending');
                    },
                  ),
                ),
                Expanded(
                  child: _buildSubTabButton(
                    'Livrées',
                    _orderTab == 'delivered',
                    () {
                      setState(() => _orderTab = 'delivered');
                    },
                  ),
                ),
                Expanded(
                  child: _buildSubTabButton(
                    'Brouillons',
                    _orderTab == 'draft',
                    () {
                      setState(() => _orderTab = 'draft');
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          Expanded(
            child: ListView.builder(
              itemCount: orders.length,
              itemBuilder: (context, index) {
                final ord = orders[index];
                return TaskCard(
                  icon: Icons.shopping_bag,
                  title: ord['supplier'] as String,
                  meta: ord['details'] as String,
                  status: ord['isLate'] == true
                      ? TaskStatus.late
                      : TaskStatus.todo,
                  onTap: () {
                    setState(() => _selectedOrderToReceive = ord);
                  },
                );
              },
            ),
          ),

          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () {},
              child: const Text('+ Nouvelle commande'),
            ),
          ),
        ],
      ),
    );
  }

  // --- T4: RÉCEPTION LIVRAISON ---
  Widget _buildT4ReceiveDelivery() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('QUANTITÉS REÇUES', style: AppTypography.labelSmall),
          const SizedBox(height: 9),
          // Discrepancy counter
          const AppInputBox(
            label: 'Aliment ponte 20kg',
            placeholder: '38 / 40 sacs',
          ),
          const SizedBox(height: 12),

          const Text('MOTIF DE L\'ÉCART', style: AppTypography.label),
          const SizedBox(height: 6),
          Row(
            children: [
              _buildFilterChip(
                'Casse transport',
                _discrepancyReason == 'casse',
                () {
                  setState(() => _discrepancyReason = 'casse');
                },
              ),
              _buildFilterChip('Manquant', _discrepancyReason == 'missing', () {
                setState(() => _discrepancyReason = 'missing');
              }),
            ],
          ),
          const SizedBox(height: 14),

          const AppInputBox(
            label: 'Aliment démarrage',
            placeholder: '20 / 20 sacs',
          ),
          const SizedBox(height: 16),

          const AlertRow(
            title: 'Livraison partielle',
            subtitle: '1 écart détecté sur 2 articles',
            type: AlertType.warning,
          ),
          const SizedBox(height: 20),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                setState(() => _selectedOrderToReceive = null);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Livraison réceptionnée avec succès'),
                  ),
                );
              },
              child: const Text('Confirmer la réception'),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => setState(() => _selectedOrderToReceive = null),
              child: const Text('Retour'),
            ),
          ),
        ],
      ),
    );
  }

  // --- OPERATIONS CONTROLLER ---
  Widget _buildOperationsTab() {
    if (_selectedOperation == 'allocation') return _buildT5BatchAllocation();
    if (_selectedOperation == 'consumption') return _buildT7Consumption();
    if (_selectedOperation == 'validation') return _buildT8Validation();

    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        _buildOperationMenuItem(
          icon: Icons.layers,
          title: 'Affecter un lot (T5)',
          desc: 'Distribuer poussins dans bâtiments libres',
          onTap: () => setState(() => _selectedOperation = 'allocation'),
        ),
        _buildOperationMenuItem(
          icon: Icons.trending_up,
          title: 'Consommation d\'aliments (T7)',
          desc: 'Suivi réel vs théorique des consommations',
          onTap: () => setState(() => _selectedOperation = 'consumption'),
        ),
        _buildOperationMenuItem(
          icon: Icons.assignment_turned_in,
          title: 'Validation des retours (T8)',
          desc: 'Valider rapports et déclarations terrain',
          onTap: () => setState(() => _selectedOperation = 'validation'),
        ),
      ],
    );
  }

  Widget _buildOperationMenuItem({
    required IconData icon,
    required String title,
    required String desc,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.paper,
        border: Border.all(color: AppColors.line),
        borderRadius: BorderRadius.circular(14),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primaryLight,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppColors.primaryDark),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
        ),
        subtitle: Text(
          desc,
          style: const TextStyle(color: AppColors.inkSoft, fontSize: 11.5),
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }

  // --- T5: AFFECTATION DE LOT ---
  Widget _buildT5BatchAllocation() {
    return Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'CHOISIR UN BÂTIMENT DISPONIBLE',
            style: AppTypography.labelSmall,
          ),
          const SizedBox(height: 9),
          _buildAllocationItem('A', 'Bâtiment A', 'Capacité restante : 400'),
          _buildAllocationItem('D', 'Bâtiment D', 'Capacité restante : 2 500'),
          _buildAllocationItem('E', 'Bâtiment E', 'Complet', isComplet: true),
          const SizedBox(height: 20),

          const Text('BÂTIMENT SÉLECTIONNÉ', style: AppTypography.label),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.paper,
              border: Border.all(color: AppColors.line),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Bâtiment $_selectedBuildingForBatch',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const Text(
                  '2 500 places libres',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                setState(() => _selectedOperation = 'menu');
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Lot affecté avec succès')),
                );
              },
              child: const Text('Confirmer l\'affectation'),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => setState(() => _selectedOperation = 'menu'),
              child: const Text('Retour'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAllocationItem(
    String letter,
    String name,
    String details, {
    bool isComplet = false,
  }) {
    final isSelected = _selectedBuildingForBatch == letter;
    return GestureDetector(
      onTap: isComplet
          ? null
          : () => setState(() => _selectedBuildingForBatch = letter),
      child: Container(
        padding: const EdgeInsets.all(12),
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: isComplet
              ? const Color(0xFFF6F6F1)
              : (isSelected ? AppColors.primaryLight : AppColors.paper),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.line,
            width: isSelected ? 1.6 : 1.0,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: isComplet
                    ? AppColors.errorLight
                    : (isSelected ? AppColors.primary : AppColors.primaryLight),
                borderRadius: BorderRadius.circular(10),
              ),
              alignment: Alignment.center,
              child: Text(
                letter,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isComplet
                      ? AppColors.danger
                      : (isSelected ? Colors.white : AppColors.primaryDark),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(
                  details,
                  style: TextStyle(
                    color: isComplet ? AppColors.danger : AppColors.inkSoft,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
            if (isSelected) ...[
              const Spacer(),
              const Icon(Icons.check_circle, color: AppColors.primaryDark),
            ],
          ],
        ),
      ),
    );
  }

  // --- T7: CONSOMMATION ALIMENTS ---
  Widget _buildT7Consumption() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AlertRow(
            title: 'Écart significatif détecté',
            subtitle: '+18 % vs consommation théorique',
            type: AlertType.error,
          ),
          const SizedBox(height: 12),

          const Text(
            'RÉEL VS THÉORIQUE — 7 JOURS (KG)',
            style: AppTypography.labelSmall,
          ),
          const SizedBox(height: 14),
          // Dual bar chart
          SizedBox(
            height: 100,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _buildDualBar(0.50, 0.40, 'L'),
                _buildDualBar(0.58, 0.50, 'M'),
                _buildDualBar(0.45, 0.42, 'M'),
                _buildDualBar(0.66, 0.60, 'J'),
                _buildDualBar(0.52, 0.50, 'V'),
                _buildDualBar(0.72, 0.64, 'S'),
                _buildDualBar(0.48, 0.46, 'D'),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Legend
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(width: 10, height: 10, color: AppColors.primary),
              const SizedBox(width: 4),
              const Text(
                'Réel',
                style: TextStyle(fontSize: 10, color: AppColors.inkSoft),
              ),
              const SizedBox(width: 14),
              Container(
                width: 10,
                height: 10,
                color: AppColors.primaryLight,
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.primary),
                ),
              ),
              const SizedBox(width: 4),
              const Text(
                'Théorique',
                style: TextStyle(fontSize: 10, color: AppColors.inkSoft),
              ),
            ],
          ),
          const SizedBox(height: 20),

          const Text('STOCK ALIMENT LIÉ', style: AppTypography.labelSmall),
          const SizedBox(height: 12),
          _buildStockProgress('Aliment ponte 20kg', 0.68, AppColors.primary),
          const SizedBox(height: 20),

          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => setState(() => _selectedOperation = 'menu'),
              child: const Text('Retour'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDualBar(double realPct, double theoPct, String label) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Container(
              width: 8,
              height: realPct * 65,
              decoration: const BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.vertical(top: Radius.circular(3)),
              ),
            ),
            const SizedBox(width: 2),
            Container(
              width: 8,
              height: theoPct * 65,
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                border: Border.all(color: AppColors.primary),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(3),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 5),
        Text(
          label,
          style: const TextStyle(fontSize: 8, color: AppColors.inkSoft),
        ),
      ],
    );
  }

  Widget _buildStockProgress(String name, double percent, Color fillColor) {
    return Column(
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
              style: const TextStyle(fontSize: 10.5, color: AppColors.inkSoft),
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
    );
  }

  // --- T8: VALIDATION DES RETOURS ---
  Widget _buildT8Validation() {
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(14),
            itemCount: _retours.length,
            itemBuilder: (context, index) {
              final r = _retours[index];
              final statusStr = r['status'] as String;

              IconData icon = Icons.assignment;
              TaskStatus status = TaskStatus.todo;
              Color bg = AppColors.warningLight;
              Color fg = AppColors.warning;

              if (statusStr == 'validee') {
                icon = Icons.check_circle;
                status = TaskStatus.done;
                bg = AppColors.successLight;
                fg = AppColors.primaryDark;
              } else if (statusStr == 'urgent') {
                icon = Icons.warning;
                status = TaskStatus.late;
                bg = AppColors.errorLight;
                fg = AppColors.danger;
              } else {
                icon = Icons.assignment_late;
                status = TaskStatus.partial;
              }

              return Dismissible(
                key: Key(r['id']!),
                background: Container(
                  color: AppColors.primary,
                  alignment: Alignment.centerLeft,
                  padding: const EdgeInsets.only(left: 20),
                  child: const Icon(Icons.check, color: Colors.white),
                ),
                secondaryBackground: Container(
                  color: AppColors.danger,
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  child: const Icon(Icons.close, color: Colors.white),
                ),
                onDismissed: (direction) {
                  setState(() {
                    _retours.removeAt(index);
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        direction == DismissDirection.startToEnd
                            ? 'Retour validé'
                            : 'Retour rejeté (renvoyé pour relecture)',
                      ),
                    ),
                  );
                },
                child: TaskCard(
                  icon: icon,
                  title: r['title']!,
                  meta: r['desc']!,
                  status: status,
                  customIconBackground: bg,
                  customIconColor: fg,
                ),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(14),
          child: SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => setState(() => _selectedOperation = 'menu'),
              child: const Text('Retour'),
            ),
          ),
        ),
      ],
    );
  }

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

  String _formatDate(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
  }

  String _formatTime(TimeOfDay tod) {
    return '${tod.hour.toString().padLeft(2, '0')}:${tod.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _selectStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2025),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() => _startDate = picked);
    }
  }

  Future<void> _selectStartTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _startTime,
    );
    if (picked != null) {
      setState(() => _startTime = picked);
    }
  }

  Future<void> _selectEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate,
      firstDate: DateTime(2025),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() => _endDate = picked);
    }
  }

  Future<void> _selectEndTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _endTime,
    );
    if (picked != null) {
      setState(() => _endTime = picked);
    }
  }
}
