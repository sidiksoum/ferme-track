import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../config/theme/app_theme.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../data/datasources/remote/api_client.dart';
import '../../../providers/auth_provider.dart';
import '../../../shared/widgets/common_widgets.dart';

class T2ActivitiesOrdersView extends StatefulWidget {
  const T2ActivitiesOrdersView({super.key});

  @override
  State<T2ActivitiesOrdersView> createState() => _T2ActivitiesOrdersViewState();
}

class _T2ActivitiesOrdersViewState extends State<T2ActivitiesOrdersView> {
  final ApiClient _apiClient = getIt<ApiClient>();
  bool _isLoadingActivities = false;
  bool _isLoadingFormOptions = false;
  final List<Map<String, String>> _buildingOptions = [];
  final List<Map<String, String>> _responsibleOptions = [];
  final Map<String, String> _responsibleIdsByLabel = {};

  // Navigation tabs inside activities
  String _activitiesTab =
      'in_progress'; // in_progress, pending_validation, done
  String _selectedBuildingFilter = 'all'; // all, A, B, C

  // Toggles for forms
  bool _isAddingActivity = false;
  bool _isAddingOrder = false;
  bool _isAddingOrderForm = false;
  bool _isAddingEggExitForm = false;
  String _orderWorkspaceTab = 'orders';

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

  // Selected values for activity multiselects
  final Set<String> _selectedActivities = {};
  final Set<String> _selectedResponsibles = {};

  String _selectedBuildingForActivity = '';
  final TextEditingController _activityNotesController =
      TextEditingController();
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
  final TextEditingController _orderContactController = TextEditingController(
    text: '+225 07 45 89 21',
  );
  final TextEditingController _orderAddressController = TextEditingController(
    text: 'Zone Industrielle Yopougon',
  );
  final TextEditingController _orderCostController = TextEditingController();
  final TextEditingController _eggExitResponsibleController =
      TextEditingController();
  final TextEditingController _eggExitQuantityController =
      TextEditingController();
  final TextEditingController _poultryLotNameController =
      TextEditingController();
  final TextEditingController _poultryLotCountController =
      TextEditingController();
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
      'type': 'aliment',
      'ref': '118',
      'status': 'En attente',
      'isLate': false,
    },
    {
      'supplier': 'VetPlus Côte d\'Ivoire',
      'details': '200 doses vaccin',
      'type': 'sanitaire',
      'ref': '119',
      'status': 'Retard',
      'isLate': true,
    },
    {
      'supplier': 'Couvoir Béré',
      'details': '2 000 poussins',
      'type': 'volaille',
      'ref': '120',
      'status': 'Confirmée',
      'isLate': false,
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadFormData();
  }

  Future<void> _loadFormData() async {
    if (!mounted) return;
    setState(() {
      _isLoadingActivities = true;
      _isLoadingFormOptions = true;
    });
    try {
      final farmId = context.read<AuthNotifier>().currentUser?.farmId;
      if (farmId == null || farmId.isEmpty) {
        throw StateError('Aucune ferme associée à la session');
      }
      final responses = await Future.wait([
        _apiClient.get('/buildings', queryParameters: {'farm_id': farmId}),
        _apiClient.get('/technician/volaillers'),
      ]);
      _buildingOptions
        ..clear()
        ..addAll(
          (responses[0] as List? ?? []).whereType<Map>().map(
            (item) => {
              'id': item['id'].toString(),
              'name': item['name']?.toString() ?? 'Bâtiment',
            },
          ),
        );
      _responsibleOptions
        ..clear()
        ..addAll(
          (responses[1] as List? ?? []).whereType<Map>().map((item) {
            final label =
                '${item['full_name'] ?? item['username'] ?? 'Volailler'} — Volailler';
            final id = item['id'].toString();
            _responsibleIdsByLabel[label] = id;
            return {'id': id, 'name': label};
          }),
        );
      if (_buildingOptions.isNotEmpty) {
        _selectedBuildingForActivity = _buildingOptions.first['id']!;
      }
      await _loadActivities(farmId);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Impossible de charger les options : $error')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingActivities = false;
          _isLoadingFormOptions = false;
        });
      }
    }
  }

  Future<void> _loadActivities([String? farmId]) async {
    try {
      final response = await _apiClient.get('/activities');
      if (!mounted || response is! List) return;
      setState(() {
        _activities
          ..clear()
          ..addAll(
            response.whereType<Map>().map((item) {
              final status = item['status']?.toString();
              final building = item['building']?.toString();
              final startTime = item['startTime']?.toString() ?? '';
              final responsibleLabel = item['responsibleName']?.toString();
              return {
                'id': item['id']?.toString(),
                'title': item['title']?.toString() ?? 'Activité',
                'meta': [startTime, responsibleLabel]
                    .where((value) => value != null && value.isNotEmpty)
                    .join(' · '),
                'status': status == 'done'
                    ? TaskStatus.done
                    : status == 'pending_validation'
                    ? TaskStatus.pendingValidation
                    : status == 'in_progress'
                    ? TaskStatus.inProgress
                    : status == 'late'
                    ? TaskStatus.late
                    : TaskStatus.todo,
                'building': building?.replaceFirst('Bâtiment ', '') ?? '',
                'notes': item['description']?.toString(),
                'buildingName':
                    item['buildingName']?.toString() ??
                    'Bâtiment non renseigné',
                'responsibleName':
                    item['responsibleName']?.toString() ??
                    'Responsable non renseigné',
                'scheduledDate': item['scheduledDate']?.toString(),
                'startTime': item['startTime']?.toString() ?? startTime,
                'endTime': item['endTime']?.toString(),
                'submittedAt': item['submittedAt']?.toString(),
                'completedAt': item['completedAt']?.toString(),
                'submittedNotes': item['submittedNotes']?.toString(),
                'validationNotes': item['validationNotes']?.toString(),
              };
            }),
          );
      });
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Impossible de charger les activités : $error'),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _activityNotesController.dispose();
    _orderContactController.dispose();
    _orderAddressController.dispose();
    _orderCostController.dispose();
    _eggExitResponsibleController.dispose();
    _eggExitQuantityController.dispose();
    _poultryLotNameController.dispose();
    _poultryLotCountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isAddingActivity) {
      return _buildAddActivityForm();
    }
    if (_isAddingOrder) {
      return _buildOrderWorkspace();
    }

    final filteredActivities =
        _activities.where((act) {
          if (_selectedBuildingFilter != 'all' &&
              act['building'] != _selectedBuildingFilter) {
            return false;
          }
          if (_activitiesTab == 'pending_validation')
            return act['status'] == TaskStatus.pendingValidation;
          if (_activitiesTab == 'done') return act['status'] == TaskStatus.done;
          return act['status'] == TaskStatus.inProgress ||
              act['status'] == TaskStatus.partial ||
              act['status'] == TaskStatus.late ||
              act['status'] == TaskStatus.todo;
        }).toList()..sort(
          (a, b) => (b['scheduledDate']?.toString() ?? '').compareTo(
            a['scheduledDate']?.toString() ?? '',
          ),
        );

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
                    'En cours',
                    _activitiesTab == 'in_progress',
                    () => setState(() => _activitiesTab = 'in_progress'),
                  ),
                ),
                Expanded(
                  child: _buildSubTabButton(
                    'A valider',
                    _activitiesTab == 'pending_validation',
                    () => setState(() => _activitiesTab = 'pending_validation'),
                  ),
                ),
                Expanded(
                  child: _buildSubTabButton(
                    'Faite',
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
                _buildFilterChip(
                  'Tous Bât.',
                  _selectedBuildingFilter == 'all',
                  () => setState(() => _selectedBuildingFilter = 'all'),
                ),
                _buildFilterChip(
                  'Bât. A',
                  _selectedBuildingFilter == 'A',
                  () => setState(() => _selectedBuildingFilter = 'A'),
                ),
                _buildFilterChip(
                  'Bât. B',
                  _selectedBuildingFilter == 'B',
                  () => setState(() => _selectedBuildingFilter = 'B'),
                ),
                _buildFilterChip(
                  'Bât. C',
                  _selectedBuildingFilter == 'C',
                  () => setState(() => _selectedBuildingFilter = 'C'),
                ),
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
              const Text(
                'ACTIVITÉS DE LA SEMAINE',
                style: AppTypography.labelSmall,
              ),
              const SizedBox(height: 8),
              if (_isLoadingActivities)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (filteredActivities.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Center(
                    child: Text(
                      'Aucune activité enregistrée.',
                      style: TextStyle(color: AppColors.inkSoft),
                    ),
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
                  meta:
                      '${act['buildingName']} · ${act['responsibleName']} · ${act['scheduledDate']?.toString().split('T').first ?? ''} · ${act['meta']} - ${act['endTime'] ?? ''}',
                  status: act['status'],
                  onTap: () {
                    if (act['status'] == TaskStatus.pendingValidation) {
                      _showValidationDialog(act);
                    } else {
                      _showActivityDetails(act);
                    }
                  },
                );
              }),
              const SizedBox(height: 16),

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
                      _isAddingOrderForm = false;
                      _isAddingEggExitForm = false;
                      _orderWorkspaceTab = 'orders';
                      _expectedDeliveryDate = null;
                    });
                  },
                  icon: const Icon(Icons.shopping_cart, size: 16),
                  label: const Text(
                    'Commande/Sortie',
                    style: TextStyle(fontSize: 12),
                  ),
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
              Text(
                'Date programmée : ${_formatActivityDate(act['scheduledDate'])}',
              ),
              Text(
                'Responsable : ${act['responsibleName'] ?? 'Non renseigné'}',
              ),
              Text('Bâtiment : ${act['buildingName'] ?? 'Non renseigné'}'),
              Text('Début : ${act['startTime'] ?? 'Non renseigné'}'),
              Text('Fin prévue : ${act['endTime'] ?? 'Non renseignée'}'),
              const SizedBox(height: 8),
              Text(
                'Instructions : "${act['notes'] ?? 'Aucun détail disponible.'}"',
              ),
              if (act['submittedNotes'] != null)
                Text(
                  'Compte rendu du volailler :\n${_formatActivityNotes(act['submittedNotes'])}',
                ),
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
              onPressed: () async {
                if (commentController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Un commentaire de réalisation est requis pour confirmer la tâche',
                      ),
                    ),
                  );
                  return;
                }
                Navigator.pop(context);
                await _confirmActivity(act, commentController.text.trim());
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
    final lotNameController = TextEditingController();
    final lotCountController = TextEditingController();
    String? selectedBuildingId = _buildingOptions.isNotEmpty
        ? _buildingOptions.first['id']
        : null;
    final isPoultryOrder =
        ord['type'] == 'volaille' ||
        ord['details'].toString().toLowerCase().contains('poussin');
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            title: Text('Clôturer la commande : ${ord['supplier']}'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Articles attendus : ${ord['details']}'),
                if (isPoultryOrder) ...[
                  const SizedBox(height: 14),
                  const Text(
                    'BÂTIMENT DE DESTINATION',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    value: selectedBuildingId,
                    items: _buildingOptions
                        .map(
                          (building) => DropdownMenuItem(
                            value: building['id'],
                            child: Text(building['name']!),
                          ),
                        )
                        .toList(),
                    onChanged: (value) =>
                        setDialogState(() => selectedBuildingId = value),
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: lotNameController,
                    decoration: const InputDecoration(
                      labelText: 'Nom du lot',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: lotCountController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Effectif du lot',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
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
                onPressed: () async {
                  if (qtyController.text.trim().isEmpty ||
                      commentController.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Veuillez renseigner la quantité et un commentaire',
                        ),
                      ),
                    );
                    return;
                  }
                  if (isPoultryOrder &&
                      (selectedBuildingId == null ||
                          lotNameController.text.trim().isEmpty ||
                          lotCountController.text.trim().isEmpty)) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Veuillez renseigner le bâtiment et les informations du lot',
                        ),
                      ),
                    );
                    return;
                  }
                  setState(() {
                    ord['status'] = 'Livrée';
                    ord['details'] =
                        '${ord['details']} (Reçu : ${qtyController.text})';
                    ord['comment'] = commentController.text;
                    if (isPoultryOrder) {
                      ord['buildingId'] = selectedBuildingId;
                      ord['lotName'] = lotNameController.text.trim();
                      ord['lotCount'] =
                          int.tryParse(lotCountController.text.trim()) ?? 0;
                    }
                  });
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Commande auprès de ${ord['supplier']} clôturée !',
                      ),
                    ),
                  );
                },
                child: const Text('Clôturer la commande'),
              ),
            ],
          ),
        );
      },
    );
  }

  // --- FORM A: NEW ACTIVITY WITH MULTI-SELECTION ---
  Widget _buildAddActivityForm() {
    if (_isLoadingFormOptions) {
      return const Center(child: CircularProgressIndicator());
    }
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
          const Text(
            'PROGRAMMER UNE OU PLUSIEURS ACTIVITÉS',
            style: AppTypography.label,
          ),
          const SizedBox(height: 14),

          // Multi-activities selection box
          const Text(
            'ACTIVITÉ(S) (MULTI-SÉLECTION)',
            style: AppTypography.label,
          ),
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
                  const Icon(
                    Icons.list_alt,
                    color: AppColors.inkSoft,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      chosenActivitiesStr,
                      style: TextStyle(
                        color: _selectedActivities.isEmpty
                            ? AppColors.inkSoft
                            : AppColors.primaryDark,
                        fontWeight: _selectedActivities.isEmpty
                            ? FontWeight.normal
                            : FontWeight.bold,
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
                value:
                    _buildingOptions.any(
                      (option) => option['id'] == _selectedBuildingForActivity,
                    )
                    ? _selectedBuildingForActivity
                    : null,
                isExpanded: true,
                onChanged: (val) {
                  if (val != null) {
                    setState(() => _selectedBuildingForActivity = val);
                  }
                },
                items: _buildingOptions
                    .map(
                      (building) => DropdownMenuItem(
                        value: building['id'],
                        child: Text(building['name']!),
                      ),
                    )
                    .toList(),
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Multi-responsibles selection box
          const Text(
            'RESPONSABLE(S) (MULTI-SÉLECTION)',
            style: AppTypography.label,
          ),
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
                  const Icon(
                    Icons.people_outline,
                    color: AppColors.inkSoft,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      chosenResponsiblesStr,
                      style: TextStyle(
                        color: _selectedResponsibles.isEmpty
                            ? AppColors.inkSoft
                            : AppColors.primaryDark,
                        fontWeight: _selectedResponsibles.isEmpty
                            ? FontWeight.normal
                            : FontWeight.bold,
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
              onPressed: () async {
                if (_selectedActivities.isEmpty ||
                    _selectedResponsibles.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Veuillez choisir au moins une activité et un responsable',
                      ),
                    ),
                  );
                  return;
                }
                final start = DateTime(
                  _startDate.year,
                  _startDate.month,
                  _startDate.day,
                  _startTime.hour,
                  _startTime.minute,
                );
                final end = DateTime(
                  _endDate.year,
                  _endDate.month,
                  _endDate.day,
                  _endTime.hour,
                  _endTime.minute,
                );
                showActionLoadingDialog(
                  context,
                  message: 'Programmation en cours...',
                );
                try {
                  final farmId = context
                      .read<AuthNotifier>()
                      .currentUser
                      ?.farmId;
                  if (farmId == null ||
                      farmId.isEmpty ||
                      _selectedBuildingForActivity.isEmpty) {
                    throw StateError('Ferme ou bâtiment indisponible');
                  }
                  final responsibleIds = _selectedResponsibles
                      .map((label) => _responsibleIdsByLabel[label])
                      .whereType<String>()
                      .toList();
                  await Future.wait([
                    for (final activityName in _selectedActivities)
                      for (final responsibleId in responsibleIds)
                        _apiClient.post(
                          '/tasks',
                          data: {
                            'farm_id': farmId,
                            'building_id': _selectedBuildingForActivity,
                            'title': activityName,
                            'description': _activityNotesController.text.trim(),
                            'task_type': _taskTypeFor(activityName),
                            'priority': _priorityFor(_activityPriority),
                            'scheduled_date': _formatApiDate(start),
                            'start_time': _timeForApi(start),
                            'end_time': _timeForApi(end),
                            'assigned_to_id': responsibleId,
                          },
                        ),
                  ]);
                  if (!mounted) return;
                  setState(() => _isAddingActivity = false);
                  await _loadActivities();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Activités programmées avec succès'),
                      ),
                    );
                  }
                } catch (error) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Création impossible : $error')),
                    );
                  }
                } finally {
                  if (mounted) Navigator.of(context, rootNavigator: true).pop();
                }
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

  Future<void> _confirmActivity(
    Map<String, dynamic> activity,
    String comment,
  ) async {
    final id = activity['id']?.toString();
    if (id == null || id.isEmpty) return;
    showActionLoadingDialog(context, message: 'Validation en cours...');
    try {
      await _apiClient.post(
        '/activities/$id/confirm',
        queryParameters: {'comment': comment},
      );
      if (!mounted) return;
      await _loadActivities();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Activité "${activity['title']}" validée et confirmée !',
            ),
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Validation impossible : $error')),
        );
      }
    } finally {
      if (mounted) Navigator.of(context, rootNavigator: true).pop();
    }
  }

  void _showActivityDetails(Map<String, dynamic> activity) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(activity['title'] as String),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Date programmée : ${_formatActivityDate(activity['scheduledDate'])}',
              ),
              Text(
                'Responsable : ${activity['responsibleName'] ?? 'Non renseigné'}',
              ),
              Text('Bâtiment : ${activity['buildingName'] ?? 'Non renseigné'}'),
              Text(
                'Heure de programmation : ${activity['startTime'] ?? 'Non renseignée'}',
              ),
              Text(
                'Heure de fin prévue : ${activity['endTime'] ?? 'Non renseignée'}',
              ),
              Text(
                'Soumise par le volailler : ${_formatActivityTimestamp(activity['submittedAt'])}',
              ),
              Text(
                'Validée le : ${_formatActivityTimestamp(activity['completedAt'])}',
              ),
              const SizedBox(height: 12),
              Text('Instructions : ${activity['notes'] ?? 'Aucun détail'}'),
              if (activity['submittedNotes'] != null)
                Text(
                  'Compte rendu du volailler :\n${_formatActivityNotes(activity['submittedNotes'])}',
                ),
              if (activity['validationNotes'] != null)
                Text(
                  'Validation technicien :\n${_formatActivityNotes(activity['validationNotes'])}',
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  String _formatActivityTimestamp(dynamic value) {
    final parsed = DateTime.tryParse(value?.toString() ?? '');
    if (parsed == null) return 'Non renseignée';
    return '${parsed.day.toString().padLeft(2, '0')}/${parsed.month.toString().padLeft(2, '0')}/${parsed.year} ${parsed.hour.toString().padLeft(2, '0')}:${parsed.minute.toString().padLeft(2, '0')}';
  }

  String _formatActivityDate(dynamic value) {
    final parsed = DateTime.tryParse(value?.toString() ?? '');
    if (parsed == null) return 'Non renseignée';
    return '${parsed.day.toString().padLeft(2, '0')}/${parsed.month.toString().padLeft(2, '0')}/${parsed.year}';
  }

  String _formatActivityNotes(dynamic value) {
    if (value == null || value.toString().trim().isEmpty)
      return 'Aucune information';
    try {
      final decoded = jsonDecode(value.toString());
      if (decoded is Map) {
        final lines = <String>[];
        if (decoded['feedQtyKg'] != null)
          lines.add('Quantité distribuée : ${decoded['feedQtyKg']} kg');
        if (decoded['eggsProduced'] != null)
          lines.add('Œufs produits : ${decoded['eggsProduced']}');
        if (decoded['eggsBroken'] != null)
          lines.add('Œufs cassés : ${decoded['eggsBroken']}');
        if (decoded['eggsUnsellable'] != null)
          lines.add('Œufs non vendables : ${decoded['eggsUnsellable']}');
        if (decoded['eggsPlusGros'] != null)
          lines.add('Œufs plus gros : ${decoded['eggsPlusGros']}');
        if (decoded['eggsGros'] != null)
          lines.add('Œufs gros : ${decoded['eggsGros']}');
        if (decoded['eggsMoyen'] != null)
          lines.add('Œufs moyens : ${decoded['eggsMoyen']}');
        if (decoded['eggsPetit'] != null)
          lines.add('Œufs petits : ${decoded['eggsPetit']}');
        if (decoded['temperatureCelsius'] != null)
          lines.add(
            'Température constatée : ${decoded['temperatureCelsius']} °C',
          );
        if (decoded['notes'] != null &&
            decoded['notes'].toString().trim().isNotEmpty)
          lines.add('Observation : ${decoded['notes']}');
        if (decoded['confirmed'] == true)
          lines.add('Confirmation : tâche réalisée');
        return lines.join('\n');
      }
    } catch (_) {}
    return value.toString();
  }

  String _taskTypeFor(String activity) {
    final value = activity.toLowerCase();
    if (value.contains('vaccin')) return 'vaccination';
    if (value.contains('aliment') || value.contains('abrevage'))
      return 'feeding';
    if (value.contains('netoy') || value.contains('nettoy')) return 'cleaning';
    if (value.contains('œuf') || value.contains('oeuf'))
      return 'egg_collection';
    if (value.contains('pese')) return 'inspection';
    if (value.contains('vitamine') ||
        value.contains('deparasitant') ||
        value.contains('injection'))
      return 'treatment';
    return 'other';
  }

  String _priorityFor(int priority) {
    if (priority >= 3) return 'high';
    if (priority <= 1) return 'low';
    return 'normal';
  }

  String _timeForApi(DateTime value) =>
      '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}:00';

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
                  children: _responsibleOptions.map((responsible) {
                    final opt = responsible['name']!;
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
  Widget _buildOrderWorkspace() {
    if (_isAddingOrderForm) return _buildAddOrderForm();
    if (_isAddingEggExitForm) return _buildEggExitForm();

    final isOrdersTab = _orderWorkspaceTab == 'orders';
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Expanded(
                child: _buildSubTabButton(
                  'Commande',
                  isOrdersTab,
                  () => setState(() => _orderWorkspaceTab = 'orders'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildSubTabButton(
                  'Sortie œufs',
                  !isOrdersTab,
                  () => setState(() => _orderWorkspaceTab = 'eggs'),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: isOrdersTab ? _buildOrdersList() : _buildEggExitsList(),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 8, 14, 14),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => setState(() => _isAddingOrder = false),
                  child: const Text('Retour'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => setState(() {
                    if (isOrdersTab) {
                      _isAddingOrderForm = true;
                    } else {
                      _isAddingEggExitForm = true;
                    }
                  }),
                  icon: const Icon(Icons.add, size: 16),
                  label: Text(
                    isOrdersTab
                        ? 'Ajouter une commande'
                        : 'Effectuer une sortie',
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOrdersList() {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      children: [
        const Text('COMMANDES EN COURS', style: AppTypography.labelSmall),
        const SizedBox(height: 10),
        ..._orders.map((ord) {
          final isDelivered = ord['status'] == 'Livrée';
          return TaskCard(
            icon: Icons.shopping_bag,
            title: ord['supplier'],
            meta:
                '${ord['details']} · Réf: #${ord['ref']} · ${ord['status']} · ${ord['cost'] ?? 'Coût non renseigné'}',
            status: isDelivered
                ? TaskStatus.done
                : (ord['isLate'] ? TaskStatus.late : TaskStatus.todo),
            onTap: isDelivered ? null : () => _showCloseOrderDialog(ord),
          );
        }),
      ],
    );
  }

  Widget _buildEggExitsList() {
    final exits = [
      {
        'date': '03/09/2026 · 16:30',
        'responsible': 'Ama Koffi',
        'quantity': '1 240 œufs',
        'details': '30 plus gros · 90 gros · 460 moyens · 660 petits',
      },
      {
        'date': '02/09/2026 · 17:10',
        'responsible': 'Yao B.',
        'quantity': '980 œufs',
        'details': '20 plus gros · 80 gros · 380 moyens · 500 petits',
      },
    ];
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      children: [
        const Text('SORTIES D’ŒUFS', style: AppTypography.labelSmall),
        const SizedBox(height: 10),
        ...exits.map(
          (exit) => TaskCard(
            icon: Icons.egg,
            title: exit['quantity']!,
            meta:
                '${exit['date']} · ${exit['responsible']} · ${exit['details']}',
            status: TaskStatus.done,
            onTap: () {},
          ),
        ),
      ],
    );
  }

  Widget _buildEggExitForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('EFFECTUER UNE SORTIE D’ŒUFS', style: AppTypography.label),
          const SizedBox(height: 16),
          AppInputBox(
            label: 'Nombre d’œufs',
            placeholder: 'Total sorti',
            controller: _eggExitQuantityController,
            inputType: TextInputType.number,
          ),
          const SizedBox(height: 12),
          AppInputBox(
            label: 'Plus gros',
            placeholder: 'Nombre de plus gros',
            inputType: TextInputType.number,
          ),
          const SizedBox(height: 12),
          AppInputBox(
            label: 'Gros',
            placeholder: 'Nombre de gros',
            inputType: TextInputType.number,
          ),
          const SizedBox(height: 12),
          AppInputBox(
            label: 'Moyen',
            placeholder: 'Nombre de moyens',
            inputType: TextInputType.number,
          ),
          const SizedBox(height: 12),
          AppInputBox(
            label: 'Petit',
            placeholder: 'Nombre de petits',
            inputType: TextInputType.number,
          ),
          const SizedBox(height: 12),
          AppInputBox(
            label: 'Responsable sortie',
            placeholder: 'Nom du responsable',
            controller: _eggExitResponsibleController,
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => setState(() => _isAddingEggExitForm = false),
              child: const Text('Enregistrer la sortie'),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => setState(() => _isAddingEggExitForm = false),
              child: const Text('Annuler'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddOrderForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'NOUVELLE COMMANDE / SORTIE DE STOCK',
            style: AppTypography.label,
          ),
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

          AppInputBox(
            label: 'Coût',
            placeholder: 'Ex: 250 000 FCFA',
            controller: _orderCostController,
            inputType: TextInputType.number,
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
                      if (val == 'aliment')
                        _orderArticle = 'Aliment ponte 20 kg';
                      if (val == 'sanitaire')
                        _orderArticle = 'Vaccin Newcastle';
                      if (val == 'volaille')
                        _orderArticle = 'Poussins d\'un jour';
                    });
                  }
                },
                items: const [
                  DropdownMenuItem(
                    value: 'aliment',
                    child: Text('Alimentation'),
                  ),
                  DropdownMenuItem(
                    value: 'sanitaire',
                    child: Text('Sanitaire / Vétérinaire'),
                  ),
                  DropdownMenuItem(
                    value: 'volaille',
                    child: Text('Volaille / Sujets'),
                  ),
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
                  const Icon(
                    Icons.calendar_today,
                    color: AppColors.inkSoft,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _expectedDeliveryDate == null
                        ? 'Sélectionner la date de livraison'
                        : _formatDate(_expectedDeliveryDate!),
                    style: TextStyle(
                      color: _expectedDeliveryDate == null
                          ? AppColors.inkSoft
                          : AppColors.primaryDark,
                      fontWeight: _expectedDeliveryDate == null
                          ? FontWeight.normal
                          : FontWeight.bold,
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
                    const SnackBar(
                      content: Text(
                        'Veuillez renseigner la date de réception prévue',
                      ),
                    ),
                  );
                  return;
                }
                setState(() {
                  _orders.add({
                    'supplier': _selectedSupplier,
                    'details':
                        '$_orderArticle (Type: ${_orderType.toUpperCase()})',
                    'type': _orderType,
                    'ref': 'CMD-${121 + _orders.length}',
                    'status': 'En attente',
                    'isLate': false,
                    'cost': _orderCostController.text.trim().isEmpty
                        ? 'Coût non renseigné'
                        : '${_orderCostController.text.trim()} FCFA',
                  });
                  _isAddingOrderForm = false;
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Commande planifiée !')),
                );
              },
              child: const Text('Enregistrer la Commande'),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => setState(() => _isAddingOrderForm = false),
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

  String _formatApiDate(DateTime dt) {
    return '${dt.year.toString().padLeft(4, '0')}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
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
