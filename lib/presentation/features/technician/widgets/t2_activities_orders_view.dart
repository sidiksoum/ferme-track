import 'package:flutter/material.dart';
import '../../../../config/theme/app_theme.dart';
import '../../../shared/widgets/common_widgets.dart';

class T2ActivitiesOrdersView extends StatefulWidget {
  const T2ActivitiesOrdersView({super.key});

  @override
  State<T2ActivitiesOrdersView> createState() => _T2ActivitiesOrdersViewState();
}

class _T2ActivitiesOrdersViewState extends State<T2ActivitiesOrdersView> {
  // Navigation tabs inside activities
  String _activitiesTab = 'planned'; // planned, done
  String _selectedBuildingFilter = 'all'; // all, A, B, C

  // Toggles for forms
  bool _isAddingActivity = false;
  bool _isAddingOrder = false;

  // Multi-selection options for new activity
  final List<String> _allActivityOptions = [
    'vitamine',
    'deparasitant',
    'vaccination',
    'anneau de boison',
    'injection',
    'allimentation et abrevage',
    'netoyage',
    'pese',
    'collecte des œufs',
  ];

  final List<String> _allResponsibleOptions = [
    'Ama Koffi — Volailler',
    'Yao B. — Magasinier',
    'Dr. Koffi — Technicien',
    'Seydou Yao — Grossiste',
  ];

  // Selected values for activity multiselects
  final Set<String> _selectedActivities = {};
  final Set<String> _selectedResponsibles = {};

  String _selectedBuildingForActivity = 'A';
  final TextEditingController _activityNotesController = TextEditingController();
  DateTime _startDate = DateTime.now();
  TimeOfDay _startTime = const TimeOfDay(hour: 8, minute: 0);
  DateTime _endDate = DateTime.now();
  TimeOfDay _endTime = const TimeOfDay(hour: 9, minute: 0);
  int _activityPriority = 2; // 1, 2, 3

  // Commande/Sortie form states
  final List<String> _enteredSuppliers = [
    'Avicola SARL',
    'VetPlus Côte d\'Ivoire',
    'Couvoir Béré',
  ];
  String _selectedSupplier = 'Avicola SARL';
  final TextEditingController _orderContactController = TextEditingController(text: '+225 07 45 89 21');
  final TextEditingController _orderAddressController = TextEditingController(text: 'Zone Industrielle Yopougon');
  String _orderType = 'aliment'; // aliment, sanitaire, volaille
  String _orderArticle = 'Aliment ponte 20 kg';
  DateTime? _expectedDeliveryDate;

  // Mock list of activities
  final List<Map<String, dynamic>> _activities = [
    {
      'title': 'Alimentation — Bât. A',
      'meta': '06:30 · Ama K.',
      'status': TaskStatus.done,
      'building': 'A',
      'notes': 'Distribuer l\'aliment ponte standard.',
    },
    {
      'title': 'Ramassage œufs — Bât. B',
      'meta': '07:15 · Yao B.',
      'status': TaskStatus.done,
      'building': 'B',
      'notes': 'Collecte matinale de la production d\'œufs.',
    },
    {
      'title': 'Vaccination Newcastle',
      'meta': '08:00 · Yao B.',
      'status': TaskStatus.late,
      'building': 'C',
      'notes': 'Rappel annuel indispensable.',
    },
    {
      'title': 'Pesée hebdomadaire',
      'meta': '16:00 · Yao B.',
      'status': TaskStatus.todo,
      'building': 'B',
      'notes': 'Peser un échantillon de 50 sujets.',
    },
  ];

  // Mock list of orders
  final List<Map<String, dynamic>> _orders = [
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

  @override
  void dispose() {
    _activityNotesController.dispose();
    _orderContactController.dispose();
    _orderAddressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isAddingActivity) {
      return _buildAddActivityForm();
    }
    if (_isAddingOrder) {
      return _buildAddOrderForm();
    }

    final filteredActivities = _activities.where((act) {
      if (_selectedBuildingFilter != 'all' && act['building'] != _selectedBuildingFilter) {
        return false;
      }
      if (_activitiesTab == 'planned') {
        return act['status'] != TaskStatus.done;
      } else {
        return act['status'] == TaskStatus.done;
      }
    }).toList();

    return Column(
      children: [
        // Sub tabs (À faire / Réalisées)
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
                    'Programmées',
                    _activitiesTab == 'planned',
                    () => setState(() => _activitiesTab = 'planned'),
                  ),
                ),
                Expanded(
                  child: _buildSubTabButton(
                    'Réalisées',
                    _activitiesTab == 'done',
                    () => setState(() => _activitiesTab = 'done'),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Building filter row
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip('Tous Bât.', _selectedBuildingFilter == 'all', () => setState(() => _selectedBuildingFilter = 'all')),
                _buildFilterChip('Bât. A', _selectedBuildingFilter == 'A', () => setState(() => _selectedBuildingFilter = 'A')),
                _buildFilterChip('Bât. B', _selectedBuildingFilter == 'B', () => setState(() => _selectedBuildingFilter = 'B')),
                _buildFilterChip('Bât. C', _selectedBuildingFilter == 'C', () => setState(() => _selectedBuildingFilter = 'C')),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),

        // Main listings
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            children: [
              const Text('ACTIVITÉS DE LA SEMAINE', style: AppTypography.labelSmall),
              const SizedBox(height: 8),
              if (filteredActivities.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Center(
                    child: Text('Aucune activité enregistrée.', style: TextStyle(color: AppColors.inkSoft)),
                  ),
                ),
              ...filteredActivities.map((act) {
                IconData icon = Icons.task_alt;
                if (act['title'].toString().contains('Alimentation')) {
                  icon = Icons.restaurant;
                } else if (act['title'].toString().contains('Ramassage')) {
                  icon = Icons.egg;
                } else if (act['title'].toString().contains('Vaccination')) {
                  icon = Icons.healing;
                }

                return TaskCard(
                  icon: icon,
                  title: act['title'],
                  meta: act['meta'],
                  status: act['status'],
                  onTap: () {
                    _showValidationDialog(act);
                  },
                );
              }),
              const SizedBox(height: 16),

              const Text('COMMANDES EN COURS', style: AppTypography.labelSmall),
              const SizedBox(height: 8),
              ..._orders.map((ord) {
                final bool isDelivered = ord['status'] == 'Livrée';
                return TaskCard(
                  icon: Icons.shopping_bag,
                  title: ord['supplier'],
                  meta: '${ord['details']} · Réf: #${ord['ref']} · ${ord['status']}',
                  status: isDelivered ? TaskStatus.done : (ord['isLate'] ? TaskStatus.late : TaskStatus.todo),
                  onTap: isDelivered ? null : () => _showCloseOrderDialog(ord),
                );
              }),
              const SizedBox(height: 80),
            ],
          ),
        ),

        // Sticky Bottom buttons row
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      _isAddingActivity = true;
                      _selectedActivities.clear();
                      _selectedResponsibles.clear();
                    });
                  },
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Activité', style: TextStyle(fontSize: 12)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    setState(() {
                      _isAddingOrder = true;
                      _expectedDeliveryDate = null;
                    });
                  },
                  icon: const Icon(Icons.shopping_cart, size: 16),
                  label: const Text('Commande/Sortie', style: TextStyle(fontSize: 12)),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // --- Verification Dialog for activities (Requires comment) ---
  void _showValidationDialog(Map<String, dynamic> act) {
    final commentController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(act['title']),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Assigné à : ${act['meta']}'),
              const SizedBox(height: 8),
              Text('Notes de tâche : "${act['notes'] ?? 'Aucun détail disponible.'}"'),
              const SizedBox(height: 14),
              const Text(
                'Commentaire de réalisation (Requis) :',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: commentController,
                decoration: const InputDecoration(
                  hintText: 'Ex : Réalisé conformément au protocole.',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () {
                if (commentController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Un commentaire de réalisation est requis pour confirmer la tâche')),
                  );
                  return;
                }
                setState(() {
                  act['status'] = TaskStatus.done;
                  act['notes'] = '${act['notes'] ?? ''} (Commentaire de confirmation : ${commentController.text})';
                });
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Activité "${act['title']}" validée et confirmée !')),
                );
              },
              child: const Text('Confirmer la réalisation'),
            ),
          ],
        );
      },
    );
  }

  // --- Order receipt close dialog (Quantity received + comment) ---
  void _showCloseOrderDialog(Map<String, dynamic> ord) {
    final qtyController = TextEditingController();
    final commentController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Clôturer la commande : ${ord['supplier']}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Articles attendus : ${ord['details']}'),
              const SizedBox(height: 14),
              const Text(
                'Quantité reçue :',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: qtyController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  hintText: 'Ex : 40',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Commentaire de réception :',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: commentController,
                decoration: const InputDecoration(
                  hintText: 'Ex : Marchandise conforme reçue en bon état.',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () {
                if (qtyController.text.trim().isEmpty || commentController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Veuillez renseigner la quantité et un commentaire')),
                  );
                  return;
                }
                setState(() {
                  ord['status'] = 'Livrée';
                  ord['details'] = '${ord['details']} (Reçu : ${qtyController.text})';
                  ord['comment'] = commentController.text;
                });
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Commande auprès de ${ord['supplier']} clôturée !')),
                );
              },
              child: const Text('Clôturer la commande'),
            ),
          ],
        );
      },
    );
  }

  // --- FORM A: NEW ACTIVITY WITH MULTI-SELECTION ---
  Widget _buildAddActivityForm() {
    final String chosenActivitiesStr = _selectedActivities.isEmpty
        ? 'Aucune activité choisie'
        : _selectedActivities.join(', ');

    final String chosenResponsiblesStr = _selectedResponsibles.isEmpty
        ? 'Aucun responsable choisi'
        : _selectedResponsibles.map((r) => r.split(' — ')[0]).join(', ');

    return SingleChildScrollView(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('PROGRAMMER UNE OU PLUSIEURS ACTIVITÉS', style: AppTypography.label),
          const SizedBox(height: 14),

          // Multi-activities selection box
          const Text('ACTIVITÉ(S) (MULTI-SÉLECTION)', style: AppTypography.label),
          const SizedBox(height: 6),
          GestureDetector(
            onTap: _showMultiSelectActivitiesDialog,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.paper,
                border: Border.all(color: AppColors.line, width: 1.6),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  const Icon(Icons.list_alt, color: AppColors.inkSoft, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      chosenActivitiesStr,
                      style: TextStyle(
                        color: _selectedActivities.isEmpty ? AppColors.inkSoft : AppColors.primaryDark,
                        fontWeight: _selectedActivities.isEmpty ? FontWeight.normal : FontWeight.bold,
                      ),
                    ),
                  ),
                  const Icon(Icons.arrow_drop_down, color: AppColors.inkSoft),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),

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

          // Multi-responsibles selection box
          const Text('RESPONSABLE(S) (MULTI-SÉLECTION)', style: AppTypography.label),
          const SizedBox(height: 6),
          GestureDetector(
            onTap: _showMultiSelectResponsiblesDialog,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.paper,
                border: Border.all(color: AppColors.line, width: 1.6),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  const Icon(Icons.people_outline, color: AppColors.inkSoft, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      chosenResponsiblesStr,
                      style: TextStyle(
                        color: _selectedResponsibles.isEmpty ? AppColors.inkSoft : AppColors.primaryDark,
                        fontWeight: _selectedResponsibles.isEmpty ? FontWeight.normal : FontWeight.bold,
                      ),
                    ),
                  ),
                  const Icon(Icons.arrow_drop_down, color: AppColors.inkSoft),
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
                  suffix: const Icon(Icons.calendar_today, size: 16, color: AppColors.inkSoft),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AppInputBox(
                  placeholder: _formatTime(_startTime),
                  readOnly: true,
                  onTap: _selectStartTime,
                  suffix: const Icon(Icons.access_time, size: 16, color: AppColors.inkSoft),
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
                  suffix: const Icon(Icons.calendar_today, size: 16, color: AppColors.inkSoft),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AppInputBox(
                  placeholder: _formatTime(_endTime),
                  readOnly: true,
                  onTap: _selectEndTime,
                  suffix: const Icon(Icons.access_time, size: 16, color: AppColors.inkSoft),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          const Text('NOTES / INSTRUCTIONS', style: AppTypography.label),
          const SizedBox(height: 6),
          AppInputBox(
            placeholder: 'Saisissez les détails de la tâche…',
            maxLines: 3,
            controller: _activityNotesController,
          ),
          const SizedBox(height: 24),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                if (_selectedActivities.isEmpty || _selectedResponsibles.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Veuillez choisir au moins une activité et un responsable')),
                  );
                  return;
                }
                setState(() {
                  for (var activityName in _selectedActivities) {
                    _activities.add({
                      'title': '$activityName — Bât. $_selectedBuildingForActivity',
                      'meta': '${_formatTime(_startTime)} · ${_selectedResponsibles.map((r) => r.split(' — ')[0]).join(', ')}',
                      'status': TaskStatus.todo,
                      'building': _selectedBuildingForActivity,
                      'notes': _activityNotesController.text,
                    });
                  }
                  _isAddingActivity = false;
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Activités programmées avec succès')),
                );
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

  void _showMultiSelectActivitiesDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Choisir des activités'),
              content: SingleChildScrollView(
                child: Column(
                  children: _allActivityOptions.map((opt) {
                    final bool isChecked = _selectedActivities.contains(opt);
                    return CheckboxListTile(
                      title: Text(opt),
                      value: isChecked,
                      activeColor: AppColors.primaryDark,
                      onChanged: (val) {
                        setDialogState(() {
                          if (val == true) {
                            _selectedActivities.add(opt);
                          } else {
                            _selectedActivities.remove(opt);
                          }
                        });
                        setState(() {}); // outer
                      },
                    );
                  }).toList(),
                ),
              ),
              actions: [
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Terminer'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showMultiSelectResponsiblesDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Choisir des responsables'),
              content: SingleChildScrollView(
                child: Column(
                  children: _allResponsibleOptions.map((opt) {
                    final bool isChecked = _selectedResponsibles.contains(opt);
                    return CheckboxListTile(
                      title: Text(opt),
                      value: isChecked,
                      activeColor: AppColors.primaryDark,
                      onChanged: (val) {
                        setDialogState(() {
                          if (val == true) {
                            _selectedResponsibles.add(opt);
                          } else {
                            _selectedResponsibles.remove(opt);
                          }
                        });
                        setState(() {}); // outer
                      },
                    );
                  }).toList(),
                ),
              ),
              actions: [
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Terminer'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // --- FORM B: COMMANDE / SORTIE DE STOCK ---
  Widget _buildAddOrderForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('NOUVELLE COMMANDE / SORTIE DE STOCK', style: AppTypography.label),
          const SizedBox(height: 16),

          const Text('FOURNISSEUR', style: AppTypography.label),
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
                value: _selectedSupplier,
                isExpanded: true,
                onChanged: (val) {
                  if (val != null) {
                    setState(() => _selectedSupplier = val);
                  }
                },
                items: _enteredSuppliers.map((s) {
                  return DropdownMenuItem(value: s, child: Text(s));
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 14),

          AppInputBox(
            label: 'Contact',
            placeholder: 'Ex: +225 07 00 00 00',
            controller: _orderContactController,
          ),
          const SizedBox(height: 14),

          AppInputBox(
            label: 'Adresse de livraison',
            placeholder: 'Ex: Zone 4 Abidjan',
            controller: _orderAddressController,
          ),
          const SizedBox(height: 14),

          const Text('TYPE DE PRODUIT', style: AppTypography.label),
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
                value: _orderType,
                isExpanded: true,
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      _orderType = val;
                      if (val == 'aliment') _orderArticle = 'Aliment ponte 20 kg';
                      if (val == 'sanitaire') _orderArticle = 'Vaccin Newcastle';
                      if (val == 'volaille') _orderArticle = 'Poussins d\'un jour';
                    });
                  }
                },
                items: const [
                  DropdownMenuItem(value: 'aliment', child: Text('Alimentation')),
                  DropdownMenuItem(value: 'sanitaire', child: Text('Sanitaire / Vétérinaire')),
                  DropdownMenuItem(value: 'volaille', child: Text('Volaille / Sujets')),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),

          const Text('ARTICLE', style: AppTypography.label),
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
                value: _orderArticle,
                isExpanded: true,
                onChanged: (val) {
                  if (val != null) {
                    setState(() => _orderArticle = val);
                  }
                },
                items: _getArticlesForType().map((art) {
                  return DropdownMenuItem(value: art, child: Text(art));
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 14),

          const Text('DATE DE RÉCEPTION PRÉVUE', style: AppTypography.label),
          const SizedBox(height: 6),
          GestureDetector(
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: DateTime.now().add(const Duration(days: 3)),
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 90)),
              );
              if (picked != null) {
                setState(() => _expectedDeliveryDate = picked);
              }
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.paper,
                border: Border.all(color: AppColors.line, width: 1.6),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today, color: AppColors.inkSoft, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    _expectedDeliveryDate == null
                        ? 'Sélectionner la date de livraison prévue'
                        : _formatDate(_expectedDeliveryDate!),
                    style: TextStyle(
                      color: _expectedDeliveryDate == null ? AppColors.inkSoft : AppColors.primaryDark,
                      fontWeight: _expectedDeliveryDate == null ? FontWeight.normal : FontWeight.bold,
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
                if (_expectedDeliveryDate == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Veuillez renseigner la date de réception prévue')),
                  );
                  return;
                }
                setState(() {
                  _orders.add({
                    'supplier': _selectedSupplier,
                    'details': '$_orderArticle (Type: ${_orderType.toUpperCase()})',
                    'ref': 'CMD-${121 + _orders.length}',
                    'status': 'En attente',
                    'isLate': false,
                  });
                  _isAddingOrder = false;
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Commande / Sortie de stock planifiée !')),
                );
              },
              child: const Text('Enregistrer la Commande / Sortie'),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => setState(() => _isAddingOrder = false),
              child: const Text('Annuler'),
            ),
          ),
        ],
      ),
    );
  }

  List<String> _getArticlesForType() {
    if (_orderType == 'aliment') {
      return ['Aliment ponte 20 kg', 'Aliment démarrage', 'Aliment croissance'];
    } else if (_orderType == 'sanitaire') {
      return ['Vaccin Newcastle', 'Vitamines complexes', 'Vermifuge liquide'];
    } else {
      return ['Poussins d\'un jour', 'Poulettes démarrées', 'Coquelets vifs'];
    }
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
            fontSize: 11,
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
          border: Border.all(color: isSelected ? AppColors.primaryDark : AppColors.line),
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
