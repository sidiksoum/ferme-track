import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/services/socket_client_service.dart';
import '../../../../data/datasources/remote/api_client.dart';
import '../../../providers/auth_provider.dart';
import '../../../shared/widgets/common_widgets.dart';
import 'activities/t2_activities_tab.dart';
import 'activities/t2_add_activity_form.dart';
import 'orders/t2_add_order_form.dart';
import 'orders/t2_orders_tab.dart';
import 'egg_exits/t2_add_egg_exit_form.dart';

class T2ActivitiesOrdersView extends StatefulWidget {
  const T2ActivitiesOrdersView({super.key});

  @override
  State<T2ActivitiesOrdersView> createState() => _T2ActivitiesOrdersViewState();
}

class _T2ActivitiesOrdersViewState extends State<T2ActivitiesOrdersView> {
  final ApiClient _apiClient = getIt<ApiClient>();
  final SocketClientService _socketService = getIt<SocketClientService>();
  StreamSubscription? _socketSubscription;

  // Loading states
  bool _isLoadingActivities = false;
  bool _isLoadingOrders = false;
  bool _isLoadingEggExits = false;
  bool _isLoadingOptions = false;

  // View state machine
  bool _isAddingActivity = false;
  bool _isAddingOrder = false;
  bool _isAddingOrderForm = false;
  bool _isAddingEggExitForm = false;
  String _orderWorkspaceSubTab = 'orders'; // 'orders' or 'eggs'

  // Data lists
  final List<Map<String, String>> _buildingOptions = [];
  final List<Map<String, String>> _responsibleOptions = [];
  final Map<String, String> _responsibleIdsByLabel = {};
  final List<Map<String, String>> _staffOptions = [];
  final List<Map<String, dynamic>> _existingSuppliers = [];

  final List<Map<String, dynamic>> _activities = [];
  final List<Map<String, dynamic>> _orders = [];
  final List<Map<String, dynamic>> _eggExits = [];

  @override
  void initState() {
    super.initState();
    _loadAllInitialData();

    // Écoute temps réel Socket.IO pour rafraîchir les activités, commandes et stocks
    _socketSubscription = _socketService.allEvents.listen((event) {
      final evt = event['event']?.toString() ?? '';
      if (evt.contains('task') || evt.contains('activity') || evt.contains('order') || evt.contains('stock') || evt.contains('egg')) {
        if (mounted) {
          final farmId = context.read<AuthNotifier>().currentUser?.farmId;
          _loadActivities(farmId: farmId, forceRefresh: true);
          _loadOrders(farmId: farmId, forceRefresh: true);
          _loadEggExits(farmId: farmId, forceRefresh: true);
        }
      }
    });
  }

  @override
  void dispose() {
    _socketSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadAllInitialData() async {
    if (!mounted) return;
    final farmId = context.read<AuthNotifier>().currentUser?.farmId;
    if (farmId == null || farmId.isEmpty) return;

    await Future.wait([
      _loadFormOptions(farmId),
      _loadActivities(farmId: farmId),
      _loadOrders(farmId: farmId),
      _loadEggExits(farmId: farmId),
    ]);
  }

  Future<void> _loadFormOptions(String farmId, {bool forceRefresh = false}) async {
    if (!mounted) return;
    if (_buildingOptions.isNotEmpty && !forceRefresh) {
      return;
    }
    setState(() => _isLoadingOptions = true);
    try {
      final responses = await Future.wait([
        _apiClient.get(
          '/buildings',
          queryParameters: {'farm_id': farmId},
          forceRefresh: forceRefresh,
          useCache: true,
        ),
        _apiClient.get('/technician/volaillers'),
        _apiClient.get('/technician/staff'),
        _apiClient.get('/suppliers'),
      ]);

      // 1. Buildings
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

      // 2. Volaillers for activity assignments
      _responsibleOptions.clear();
      _responsibleIdsByLabel.clear();
      for (final item in (responses[1] as List? ?? []).whereType<Map>()) {
        final label = '${item['full_name'] ?? item['username'] ?? 'Volailler'} — Volailler';
        final id = item['id'].toString();
        _responsibleIdsByLabel[label] = id;
        _responsibleOptions.add({'id': id, 'name': label});
      }

      // 3. Staff (Technicians + Volaillers) for Egg Exits
      _staffOptions
        ..clear()
        ..addAll(
          (responses[2] as List? ?? []).whereType<Map>().map((item) {
            final role = item['role']?.toString().toUpperCase() == 'POULTRYKEEPER' ? 'Volailler' : 'Technicien';
            final name = item['full_name'] ?? item['username'] ?? 'Personnel';
            return {
              'id': item['id'].toString(),
              'name': '$name ($role)',
            };
          }),
        );
      if (_staffOptions.isEmpty && _responsibleOptions.isNotEmpty) {
        _staffOptions.addAll(_responsibleOptions);
      }

      // 4. Suppliers
      _existingSuppliers
        ..clear()
        ..addAll(
          (responses[3] as List? ?? []).whereType<Map>().map((item) => {
                'id': item['id']?.toString() ?? '',
                'name': item['name']?.toString() ?? '',
                'phone': item['phone']?.toString() ?? '',
                'address': item['address']?.toString() ?? '',
              }),
        );
    } catch (_) {
      // Fallback silently if offline (ApiClient cache will provide previous data)
    } finally {
      if (mounted) setState(() => _isLoadingOptions = false);
    }
  }

  Future<void> _loadActivities({String? farmId, bool forceRefresh = false}) async {
    if (!mounted) return;
    if (_activities.isEmpty) setState(() => _isLoadingActivities = true);
    try {
      final response = await _apiClient.get(
        '/activities',
        forceRefresh: forceRefresh,
        useCache: true,
      );
      if (!mounted || response is! List) return;
      setState(() {
        _activities
          ..clear()
          ..addAll(
            response.whereType<Map>().map((item) {
              final status = item['status']?.toString().toLowerCase();
              final building = item['building']?.toString();
              final startTime = item['startTime']?.toString() ?? '';
              final responsibleLabel = item['responsibleName']?.toString();
              return {
                'id': item['id']?.toString(),
                'title': item['title']?.toString() ?? 'Activité',
                'meta': [startTime, responsibleLabel]
                    .where((value) => value != null && value.isNotEmpty)
                    .join(' · '),
                'status': (status == 'done' || status == 'completed')
                    ? TaskStatus.done
                    : (status == 'pending_validation' || status == 'submitted')
                        ? TaskStatus.pendingValidation
                        : status == 'in_progress'
                            ? TaskStatus.inProgress
                            : status == 'late'
                                ? TaskStatus.late
                                : TaskStatus.todo,
                'building': building?.replaceFirst('Bâtiment ', '') ?? '',
                'notes': item['notes']?.toString() ?? item['description']?.toString(),
                'buildingName':
                    item['buildingName']?.toString() ?? 'Bâtiment non renseigné',
                'responsibleName':
                    item['responsibleName']?.toString() ?? 'Responsable non renseigné',
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
    } catch (_) {
    } finally {
      if (mounted) setState(() => _isLoadingActivities = false);
    }
  }

  Future<void> _loadOrders({String? farmId, bool forceRefresh = false}) async {
    if (!mounted) return;
    if (_orders.isEmpty) setState(() => _isLoadingOrders = true);
    try {
      final response = await _apiClient.get(
        '/orders',
        forceRefresh: forceRefresh,
        useCache: true,
      );
      if (!mounted || response is! List) return;
      setState(() {
        _orders
          ..clear()
          ..addAll(
            response.whereType<Map>().map((item) => {
                  'id': item['id']?.toString(),
                  'supplier': item['supplier']?.toString() ?? 'Fournisseur inconnu',
                  'details': item['details']?.toString() ?? 'Articles',
                  'type': item['type']?.toString() ?? 'aliment',
                  'ref': item['ref']?.toString() ?? '',
                  'status': item['status']?.toString() ?? 'En attente',
                  'isLate': item['isLate'] == true,
                  'cost': item['cost']?.toString(),
                  'quantity': item['quantity']?.toString(),
                  'expectedDate': item['expectedDate']?.toString(),
                  'note': item['note']?.toString(),
                  'receivedDate': item['receivedDate']?.toString(),
                  'receivedNote': item['receivedNote']?.toString(),
                  'qtyReceived': item['qtyReceived']?.toString(),
                  'buildingName': item['buildingName']?.toString(),
                  'lotName': item['lotName']?.toString(),
                  'lotCount': item['lotCount']?.toString(),
                  'receivedBy': item['receivedBy']?.toString(),
                }),
          );
      });
    } catch (_) {
    } finally {
      if (mounted) setState(() => _isLoadingOrders = false);
    }
  }

  Future<void> _loadEggExits({String? farmId, bool forceRefresh = false}) async {
    if (!mounted) return;
    if (_eggExits.isEmpty) setState(() => _isLoadingEggExits = true);
    try {
      final response = await _apiClient.get(
        '/magasinier/egg-exits',
        forceRefresh: forceRefresh,
        useCache: true,
      );
      if (!mounted || response is! List) return;
      setState(() {
        _eggExits
          ..clear()
          ..addAll(
            response.whereType<Map>().map((item) => {
                  'id': item['id']?.toString(),
                  'date': item['date']?.toString(),
                  'quantity': item['quantity'] ?? 0,
                  'responsible': item['responsible']?.toString() ?? 'Responsable inconnu',
                  'plusGros': item['plusGros'] ?? 0,
                  'gros': item['gros'] ?? 0,
                  'moyen': item['moyen'] ?? 0,
                  'petit': item['petit'] ?? 0,
                  'comment': item['comment']?.toString(),
                  'status': item['status']?.toString() ?? 'pending',
                }),
          );
      });
    } catch (_) {
    } finally {
      if (mounted) setState(() => _isLoadingEggExits = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // 1. Add activity form view
    if (_isAddingActivity) {
      return T2AddActivityForm(
        buildingOptions: _buildingOptions,
        responsibleOptions: _responsibleOptions,
        responsibleIdsByLabel: _responsibleIdsByLabel,
        isLoadingOptions: _isLoadingOptions,
        onSuccess: () {
          setState(() => _isAddingActivity = false);
          _loadActivities(forceRefresh: true);
        },
        onCancel: () => setState(() => _isAddingActivity = false),
      );
    }

    // 2. Add order form view
    if (_isAddingOrderForm) {
      return T2AddOrderForm(
        existingSuppliers: _existingSuppliers,
        onOrderAdded: () {
          setState(() => _isAddingOrderForm = false);
          _loadOrders(forceRefresh: true);
          final farmId = context.read<AuthNotifier>().currentUser?.farmId;
          if (farmId != null) _loadFormOptions(farmId);
        },
        onCancel: () => setState(() => _isAddingOrderForm = false),
      );
    }

    // 3. Add egg exit form view
    if (_isAddingEggExitForm) {
      return T2AddEggExitForm(
        staffOptions: _staffOptions,
        onExitSaved: () {
          setState(() => _isAddingEggExitForm = false);
          _loadEggExits(forceRefresh: true);
        },
        onCancel: () => setState(() => _isAddingEggExitForm = false),
      );
    }

    // 4. Orders and Egg Exits workspace view
    if (_isAddingOrder) {
      return T2OrdersTab(
        orders: _orders,
        eggExits: _eggExits,
        buildingOptions: _buildingOptions,
        isLoadingOrders: _isLoadingOrders,
        isLoadingEggExits: _isLoadingEggExits,
        activeSubTab: _orderWorkspaceSubTab,
        onSubTabChanged: (tab) => setState(() => _orderWorkspaceSubTab = tab),
        onAddOrder: () => setState(() => _isAddingOrderForm = true),
        onAddEggExit: () => setState(() => _isAddingEggExitForm = true),
        onBack: () => setState(() => _isAddingOrder = false),
        onRefreshOrders: () => _loadOrders(forceRefresh: true),
      );
    }

    // 5. Default Activities list view
    return Stack(
      children: [
        T2ActivitiesTab(
          activities: _activities,
          buildingOptions: _buildingOptions,
          isLoading: _isLoadingActivities,
          onRefresh: () {
            final farmId = context.read<AuthNotifier>().currentUser?.farmId;
            if (farmId != null && farmId.isNotEmpty) {
              _loadFormOptions(farmId);
            }
            _loadActivities(forceRefresh: true);
          },
        ),

        // Sticky Bottom action buttons
        Positioned(
          left: 12,
          right: 12,
          bottom: 12,
          child: Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => setState(() => _isAddingActivity = true),
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
                      _orderWorkspaceSubTab = 'orders';
                    });
                    _loadOrders();
                    _loadEggExits();
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
}
