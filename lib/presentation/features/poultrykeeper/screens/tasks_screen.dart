import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../config/theme/app_theme.dart';
import '../../../shared/widgets/common_widgets.dart';
import '../../../providers/auth_provider.dart';

/// Poultry Keeper main screen combining tasks and declarations (V1 - V6)
class PoltrykeeperTasksScreen extends StatefulWidget {
  const PoltrykeeperTasksScreen({super.key});

  @override
  State<PoltrykeeperTasksScreen> createState() =>
      _PoltrykeeperTasksScreenState();
}

class _PoltrykeeperTasksScreenState extends State<PoltrykeeperTasksScreen> {
  int _selectedNavIndex = 0;

  // V1 / V2 Task states
  Map<String, dynamic>? _selectedTaskToClose;
  String _closeStatus = 'done'; // done, partial, absent

  // V3/V4/V5 Declaration states
  String _declarationType = 'mortality'; // mortality, feed, eggs
  int _mortalityCount = 3;
  String _mortalityCause = 'heat'; // heat, disease, unknown

  // V4 Feed states
  int _feedQuantity = 75;

  // V5 Egg collection states
  int _eggsProduced = 1640;
  int _eggsBroken = 18;
  int _eggsUnsellable = 6;

  // V6 Anomaly states
  String _anomalyType = 'technical';
  String _anomalySeverity = 'high'; // low, high

  @override
  Widget build(BuildContext context) {
    final authNotifier = context.watch<AuthNotifier>();
    final userName = authNotifier.currentUser?.fullName ?? 'Ama Koffi';

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAF7),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_getAppBarTitle()),
            Text(
              _getAppBarSubtitle(userName),
              style: AppTypography.appbarSubtitle,
            ),
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
            _selectedTaskToClose = null;
          });
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.primaryDark,
        unselectedItemColor: const Color(0xFF9AA79C),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.assignment),
            label: 'Tâches',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.add_box), label: 'Déclarer'),
          BottomNavigationBarItem(icon: Icon(Icons.warning), label: 'Anomalie'),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications),
            label: 'Alertes',
          ),
        ],
      ),
    );
  }

  String _getAppBarTitle() {
    switch (_selectedNavIndex) {
      case 0:
        return _selectedTaskToClose != null ? 'Fermer la tâche' : 'Mes tâches';
      case 1:
        if (_declarationType == 'mortality') return 'Déclarer une mortalité';
        if (_declarationType == 'feed') return 'Aliments distribués';
        return 'Collecte des œufs';
      case 2:
        return 'Signaler une anomalie';
      case 3:
        return 'Alertes & Notifications';
      default:
        return 'Volailler';
    }
  }

  String _getAppBarSubtitle(String userName) {
    switch (_selectedNavIndex) {
      case 0:
        return _selectedTaskToClose != null
            ? '${_selectedTaskToClose!['title']} · Bâtiment A'
            : '$userName · Bâtiment A';
      case 1:
        return 'Bâtiment A · Lot L-2026-011';
      case 2:
        return 'Bâtiment B';
      case 3:
        return 'Statut de connexion';
      default:
        return 'Ferme Akoupé';
    }
  }

  Widget _buildBody() {
    switch (_selectedNavIndex) {
      case 0:
        return _selectedTaskToClose != null
            ? _buildV2CloseTask()
            : _buildV1Tasks();
      case 1:
        return _buildDeclarationsTab();
      case 2:
        return _buildV6AnomalyReport();
      case 3:
        return _buildVolaillerAlerts();
      default:
        return _buildV1Tasks();
    }
  }

  // --- V1: MES TÂCHES ---
  Widget _buildV1Tasks() {
    final tasks = [
      {
        'title': 'Distribuer l\'aliment',
        'meta': '06:30 · Priorité haute',
        'status': TaskStatus.todo,
        'icon': Icons.restaurant,
      },
      {
        'title': 'Ramasser les œufs',
        'meta': '07:00 · Matin',
        'status': TaskStatus.todo,
        'icon': Icons.egg,
      },
      {
        'title': 'Nettoyage abreuvoirs',
        'meta': '08:30 · Quotidien',
        'status': TaskStatus.todo,
        'icon': Icons.cleaning_services,
      },
      {
        'title': 'Contrôle température',
        'meta': '05:45 · Étable',
        'status': TaskStatus.done,
        'icon': Icons.check_circle,
      },
    ];

    return Column(
      children: [
        // Offline status pill
        Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
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
                'Hors ligne · 1 tâche en attente',
                style: TextStyle(fontSize: 10.5, color: AppColors.inkSoft),
              ),
            ],
          ),
        ),

        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            itemCount: tasks.length,
            itemBuilder: (context, index) {
              final t = tasks[index];
              return TaskCard(
                icon: t['icon'] as IconData,
                title: t['title'] as String,
                meta: t['meta'] as String,
                status: t['status'] as TaskStatus,
                onTap: () {
                  setState(() => _selectedTaskToClose = t);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  // --- V2: CLÔTURER UNE TÂCHE ---
  Widget _buildV2CloseTask() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('STATUT DE LA TÂCHE', style: AppTypography.label),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildFilterChip('Réalisée', _closeStatus == 'done', () {
                setState(() => _closeStatus = 'done');
              }),
              _buildFilterChip('Partielle', _closeStatus == 'partial', () {
                setState(() => _closeStatus = 'partial');
              }),
              _buildFilterChip('Non réalisée', _closeStatus == 'absent', () {
                setState(() => _closeStatus = 'absent');
              }),
            ],
          ),
          const SizedBox(height: 14),

          const Text('HEURE DE RÉALISATION', style: AppTypography.label),
          const SizedBox(height: 6),
          const AppInputBox(
            placeholder: '06:41',
            readOnly: true,
            suffix: Icon(Icons.access_time, size: 14, color: AppColors.inkSoft),
          ),
          const SizedBox(height: 14),

          const Text('OBSERVATION (OPTIONNEL)', style: AppTypography.label),
          const SizedBox(height: 6),
          const AppInputBox(
            placeholder: 'Ajouter un commentaire…',
            maxLines: 2,
          ),
          const SizedBox(height: 14),

          // Photo attachment
          GestureDetector(
            onTap: () {},
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 20),
              decoration: BoxDecoration(
                border: Border.all(
                  color: const Color(0xFFC9D6C6),
                  width: 1.6,
                  style: BorderStyle.solid,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: const [
                  Icon(Icons.camera_alt, size: 20, color: AppColors.inkSoft),
                  SizedBox(height: 6),
                  Text(
                    'Ajouter une photo',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AppColors.inkSoft,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                setState(() => _selectedTaskToClose = null);
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('Tâche validée')));
              },
              child: const Text('Valider la tâche'),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => setState(() => _selectedTaskToClose = null),
              child: const Text('Retour'),
            ),
          ),
        ],
      ),
    );
  }

  // --- DECLARATIONS TAB ---
  Widget _buildDeclarationsTab() {
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
                    'Mortalité (V3)',
                    _declarationType == 'mortality',
                    () {
                      setState(() => _declarationType = 'mortality');
                    },
                  ),
                ),
                Expanded(
                  child: _buildSubTabButton(
                    'Aliments (V4)',
                    _declarationType == 'feed',
                    () {
                      setState(() => _declarationType = 'feed');
                    },
                  ),
                ),
                Expanded(
                  child: _buildSubTabButton(
                    'Œufs (V5)',
                    _declarationType == 'eggs',
                    () {
                      setState(() => _declarationType = 'eggs');
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
            child: _buildSelectedDeclarationForm(),
          ),
        ),
      ],
    );
  }

  Widget _buildSelectedDeclarationForm() {
    if (_declarationType == 'mortality') return _buildV3MortalityForm();
    if (_declarationType == 'feed') return _buildV4FeedForm();
    return _buildV5EggCollectionForm();
  }

  // --- V3: DÉCLARER MORTALITÉ ---
  Widget _buildV3MortalityForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('NOMBRE DE SUJETS', style: AppTypography.labelSmall),
        const SizedBox(height: 6),
        CounterBox(
          initialValue: _mortalityCount,
          onChanged: (val) => setState(() => _mortalityCount = val),
        ),
        const SizedBox(height: 14),

        const Text('CAUSE PRÉSUMÉE', style: AppTypography.label),
        const SizedBox(height: 6),
        Row(
          children: [
            _buildFilterChip('Chaleur', _mortalityCause == 'heat', () {
              setState(() => _mortalityCause = 'heat');
            }),
            _buildFilterChip('Maladie', _mortalityCause == 'disease', () {
              setState(() => _mortalityCause = 'disease');
            }),
            _buildFilterChip('Inconnue', _mortalityCause == 'unknown', () {
              setState(() => _mortalityCause = 'unknown');
            }),
          ],
        ),
        const SizedBox(height: 16),

        // Photo button
        GestureDetector(
          onTap: () {},
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 18),
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFFC9D6C6), width: 1.6),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: const [
                Icon(Icons.camera_alt, size: 20, color: AppColors.inkSoft),
                SizedBox(height: 6),
                Text(
                  'Ajouter une photo (optionnel)',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppColors.inkSoft,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),

        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Déclaration de mortalité enregistrée'),
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            child: const Text('Confirmer la déclaration'),
          ),
        ),
      ],
    );
  }

  // --- V4: ALIMENTS DISTRIBUÉS ---
  Widget _buildV4FeedForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('QUANTITÉ DISTRIBUÉE', style: AppTypography.labelSmall),
        const SizedBox(height: 6),
        CounterBox(
          initialValue: _feedQuantity,
          unit: 'kilogrammes',
          onChanged: (val) => setState(() => _feedQuantity = val),
        ),
        const SizedBox(height: 14),

        const Text('QUANTITÉS HABITUELLES', style: AppTypography.label),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildFilterChip(
              '25 kg',
              _feedQuantity == 25,
              () => setState(() => _feedQuantity = 25),
            ),
            _buildFilterChip(
              '50 kg',
              _feedQuantity == 50,
              () => setState(() => _feedQuantity = 50),
            ),
            _buildFilterChip(
              '75 kg',
              _feedQuantity == 75,
              () => setState(() => _feedQuantity = 75),
            ),
            _buildFilterChip(
              '100 kg',
              _feedQuantity == 100,
              () => setState(() => _feedQuantity = 100),
            ),
          ],
        ),
        const SizedBox(height: 16),

        const AppInputBox(
          label: 'Bâtiment / lot',
          placeholder: 'Bâtiment A — Lot L-2026-011',
          readOnly: true,
        ),
        const SizedBox(height: 24),

        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Quantité d\'aliments enregistrée'),
                ),
              );
            },
            child: const Text('Enregistrer'),
          ),
        ),
      ],
    );
  }

  // --- V5: COLLECTE DES ŒUFS ---
  Widget _buildV5EggCollectionForm() {
    final totalCollected = _eggsProduced + _eggsBroken + _eggsUnsellable;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: _buildMiniCounter(
                'Produits',
                _eggsProduced,
                (val) => setState(() => _eggsProduced = val),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildMiniCounter(
                'Cassés',
                _eggsBroken,
                (val) => setState(() => _eggsBroken = val),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildMiniCounter(
                'Non vend.',
                _eggsUnsellable,
                (val) => setState(() => _eggsUnsellable = val),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Total Summary Card
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppColors.primaryDark,
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Total collecté',
                style: TextStyle(color: Colors.white70, fontSize: 10.5),
              ),
              const SizedBox(height: 2),
              Text(
                '$totalCollected œufs',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        const Text('OBSERVATION (OPTIONNEL)', style: AppTypography.label),
        const SizedBox(height: 6),
        const AppInputBox(placeholder: 'Ajouter un commentaire…'),
        const SizedBox(height: 24),

        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Collecte d\'œufs enregistrée')),
              );
            },
            child: const Text('Enregistrer la collecte'),
          ),
        ),
      ],
    );
  }

  Widget _buildMiniCounter(
    String label,
    int value,
    void Function(int) onChanged,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.paper,
        border: Border.all(color: AppColors.line, width: 1.4),
        borderRadius: BorderRadius.circular(13),
      ),
      padding: const EdgeInsets.all(10),
      child: Column(
        children: [
          Text(
            value.toString(),
            style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
          ),
          Text(
            label,
            style: const TextStyle(fontSize: 9, color: AppColors.inkSoft),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: () =>
                    onChanged((value - 1).clamp(0, double.infinity).toInt()),
                child: Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(7),
                  ),
                  alignment: Alignment.center,
                  child: const Text(
                    '–',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryDark,
                    ),
                  ),
                ),
              ),
              GestureDetector(
                onTap: () => onChanged(value + 1),
                child: Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(7),
                  ),
                  alignment: Alignment.center,
                  child: const Text(
                    '+',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryDark,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- V6: ANOMALIE REPORT ---
  Widget _buildV6AnomalyReport() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('TYPE D\'ANOMALIE', style: AppTypography.label),
          const SizedBox(height: 6),
          Row(
            children: [
              _buildFilterChip(
                'Technique',
                _anomalyType == 'technical',
                () => setState(() => _anomalyType = 'technical'),
              ),
              _buildFilterChip(
                'Sanitaire',
                _anomalyType == 'sanitary',
                () => setState(() => _anomalyType = 'sanitary'),
              ),
              _buildFilterChip(
                'Sécurité',
                _anomalyType == 'security',
                () => setState(() => _anomalyType = 'security'),
              ),
            ],
          ),
          const SizedBox(height: 14),

          const Text('GRAVITÉ', style: AppTypography.label),
          const SizedBox(height: 6),
          Row(
            children: [
              _buildFilterChip(
                'Faible',
                _anomalySeverity == 'low',
                () => setState(() => _anomalySeverity = 'low'),
              ),
              _buildFilterChip(
                'Élevée',
                _anomalySeverity == 'high',
                () => setState(() => _anomalySeverity = 'high'),
              ),
            ],
          ),
          const SizedBox(height: 14),

          const Text('DESCRIPTION', style: AppTypography.label),
          const SizedBox(height: 6),
          const AppInputBox(
            placeholder: 'Fuite au niveau de l\'abreuvoir 3…',
            maxLines: 4,
          ),
          const SizedBox(height: 14),

          // Photo button
          GestureDetector(
            onTap: () {},
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 20),
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFFC9D6C6), width: 1.6),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: const [
                  Icon(Icons.camera_alt, size: 20, color: AppColors.inkSoft),
                  SizedBox(height: 6),
                  Text(
                    'Prendre une photo',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AppColors.inkSoft,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Signalement d\'anomalie envoyé'),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.danger,
              ),
              child: const Text('Envoyer le signalement'),
            ),
          ),
        ],
      ),
    );
  }

  // --- ALERTS LIST ---
  Widget _buildVolaillerAlerts() {
    return ListView(
      padding: const EdgeInsets.all(14),
      children: const [
        Text('NOTIFICATIONS LOCALES', style: AppTypography.labelSmall),
        SizedBox(height: 9),
        AlertRow(
          title: 'Mode hors ligne activé',
          subtitle: 'Les tâches et déclarations seront stockées localement.',
          type: AlertType.info,
        ),
        AlertRow(
          title: 'Newcastle Newcastle',
          subtitle:
              'Campagne de vaccination Newcastle en retard sur Bâtiment C.',
          type: AlertType.warning,
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
}
