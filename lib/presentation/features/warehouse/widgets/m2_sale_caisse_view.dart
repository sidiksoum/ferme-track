import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../config/theme/app_theme.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/interfaces/network_checker.dart';
import '../../../../core/services/offline_sync_service.dart';
import '../../../../core/services/socket_client_service.dart';
import '../../../../data/datasources/remote/api_client.dart';
import '../../../shared/widgets/common_widgets.dart';

class M2SaleCaisseView extends StatefulWidget {
  const M2SaleCaisseView({super.key});

  @override
  State<M2SaleCaisseView> createState() => _M2SaleCaisseViewState();
}

class _M2SaleCaisseViewState extends State<M2SaleCaisseView> {
  final ApiClient _apiClient = getIt<ApiClient>();
  final SocketClientService _socketService = getIt<SocketClientService>();
  final OfflineSyncService _offlineSyncService = getIt<OfflineSyncService>();
  final NetworkChecker _networkChecker = getIt<NetworkChecker>();
  StreamSubscription? _socketSubscription;

  String _activeSubTab = 'history'; // history, refund
  bool _isAddingVente = false;

  // Search/Filter states
  String _clientSearchQuery = '';
  DateTime? _selectedFilterDate;
  String _salesPeriodFilter = 'all'; // all, today, 7j, 30j, custom
  DateTimeRange? _selectedDateRange;
  bool _showGraphBreakdown = true;

  // New Sale Form Controllers
  final TextEditingController _clientNameController = TextEditingController();
  final TextEditingController _clientContactController =
      TextEditingController();
  final TextEditingController _clientAddressController =
      TextEditingController();
  final TextEditingController _totalSaleAmountController =
      TextEditingController();
  final TextEditingController _paidAmountController = TextEditingController();
  final Map<String, TextEditingController> _quantityControllers = {};

  // Selected existing client ID if chosen from list
  String? _selectedClientId;

  // Egg formats quantities for sale
  int _qtyPetit = 0;
  int _qtyMoyen = 0;
  int _qtyGros = 0;
  int _qtyPlusGros = 0;

  DateTime? _dueDate;

  // Sales History List
  List<Map<String, dynamic>> _salesHistory = [
    {
      'id': 'V-001',
      'date': DateTime.now().subtract(const Duration(hours: 2)),
      'client': 'Client de passage',
      'contact': '—',
      'address': '—',
      'details': '10 plateaux Moyen format',
      'amount': 20000,
      'paid': 20000,
      'due': 0,
      'status': 'Payé',
      'items': [
        {'name': 'Moyen format', 'quantity': 10, 'total': 20000},
      ],
    },
    {
      'id': 'V-002',
      'date': DateTime.now().subtract(const Duration(days: 1)),
      'client': 'Adjoua Tanoh',
      'contact': '07 08 09 10 11',
      'address': 'Korhogo Marché',
      'details': '20 plateaux Gros format',
      'amount': 44000,
      'paid': 25500,
      'due': 18500,
      'status': 'Partiel',
      'items': [
        {'name': 'Gros format', 'quantity': 20, 'total': 44000},
      ],
    },
    {
      'id': 'V-003',
      'date': DateTime.now().subtract(const Duration(days: 3)),
      'client': 'Seydou Yao',
      'contact': '07 47 48 49 50',
      'address': 'Gare routière',
      'details': '40 plateaux Plus Gros format',
      'amount': 100000,
      'paid': 35000,
      'due': 65000,
      'status': 'Crédit',
      'items': [
        {'name': 'Plus Gros format', 'quantity': 40, 'total': 100000},
      ],
    },
  ];

  // Debtors/Créanciers List
  List<Map<String, dynamic>> _debtors = [
    {
      'client_id': 'c-1',
      'name': 'Seydou Yao',
      'due': 65000,
      'status': 'Échéance dépassée (12/08)',
      'isOverdue': true,
      'phone': '07 47 48 49 50',
      'address': 'Gare routière',
    },
    {
      'client_id': 'c-2',
      'name': 'Koffi Mensah',
      'due': 42000,
      'status': 'Échéance 25/08',
      'isOverdue': false,
      'phone': '05 06 07 08 09',
      'address': 'Marché central',
    },
    {
      'client_id': 'c-3',
      'name': 'Adjoua Tanoh',
      'due': 18500,
      'status': 'Échéance 28/08',
      'isOverdue': false,
      'phone': '07 08 09 10 11',
      'address': 'Korhogo Marché',
    },
  ];

  // Clients directory
  List<Map<String, dynamic>> _clientsList = [];

  int get _totalSaleAmount =>
      int.tryParse(_totalSaleAmountController.text.trim()) ?? 0;

  int get _remainingToPay {
    final paid = int.tryParse(_paidAmountController.text.trim()) ?? 0;
    return (_totalSaleAmount - paid).clamp(0, 100000000);
  }

  @override
  void initState() {
    super.initState();
    _loadAllData();

    // Écoute temps réel Socket.IO pour rafraîchissement instantané
    _socketSubscription = _socketService.allEvents.listen((event) {
      final evt = event['event']?.toString() ?? '';
      if (evt == 'sale:created' ||
          evt == 'stock:updated' ||
          evt.contains('reception')) {
        if (mounted) {
          _loadAllData(forceRefresh: true);
        }
      }
    });
  }

  Future<void> _loadAllData({bool forceRefresh = false}) async {
    if (!mounted) return;

    try {
      // 1. Load Sales
      final salesRes = await _apiClient.get(
        '/magasinier/sales',
        forceRefresh: forceRefresh,
        useCache: true,
      );
      if (mounted && salesRes is List) {
        _salesHistory = salesRes.map<Map<String, dynamic>>((s) {
          DateTime date;
          try {
            date = DateTime.parse(s['date']?.toString() ?? '');
          } catch (_) {
            date = DateTime.now();
          }
          return {
            'id':
                s['id']?.toString() ??
                'V-${DateTime.now().millisecondsSinceEpoch}',
            'date': date,
            'client':
                s['client']?.toString() ??
                s['customer_name']?.toString() ??
                'Client',
            'contact':
                s['contact']?.toString() ??
                s['customer_phone']?.toString() ??
                '—',
            'address':
                s['address']?.toString() ??
                s['customer_address']?.toString() ??
                '—',
            'details': s['details']?.toString() ?? 'Vente d\'œufs',
            'amount':
                (s['amount'] as num?)?.toInt() ??
                (s['total_amount'] as num?)?.toInt() ??
                0,
            'paid':
                (s['paid'] as num?)?.toInt() ??
                (s['amount_paid'] as num?)?.toInt() ??
                0,
            'due':
                (s['due'] as num?)?.toInt() ??
                (s['remaining_balance'] as num?)?.toInt() ??
                0,
            'status': s['status']?.toString() ?? 'Payé',
            'format_petit':
                (s['format_petit'] as num?)?.toInt() ??
                (s['qtyPetit'] as num?)?.toInt() ??
                0,
            'format_moyen':
                (s['format_moyen'] as num?)?.toInt() ??
                (s['qtyMoyen'] as num?)?.toInt() ??
                0,
            'format_gros':
                (s['format_gros'] as num?)?.toInt() ??
                (s['qtyGros'] as num?)?.toInt() ??
                0,
            'format_plus_gros':
                (s['format_plus_gros'] as num?)?.toInt() ??
                (s['qtyPlusGros'] as num?)?.toInt() ??
                0,
            'quantity_plates':
                (s['quantity_plates'] as num?)?.toInt() ??
                (s['quantity'] as num?)?.toInt() ??
                0,
            'items': s['items'] is List ? s['items'] : [],
          };
        }).toList();
      }

      // 2. Load Debtors
      final debtorsRes = await _apiClient.get(
        '/magasinier/clients/debtors',
        forceRefresh: forceRefresh,
        useCache: true,
      );
      if (mounted && debtorsRes is List) {
        _debtors = debtorsRes.map<Map<String, dynamic>>((d) {
          return {
            'client_id':
                d['client_id']?.toString() ?? d['id']?.toString() ?? '',
            'name': d['name']?.toString() ?? 'Client',
            'due':
                (d['due'] as num?)?.toInt() ??
                (d['balance'] as num?)?.toInt() ??
                0,
            'status': d['status']?.toString() ?? 'Échéance en cours',
            'isOverdue': d['isOverdue'] == true,
            'phone': d['phone']?.toString() ?? '—',
            'address': d['address']?.toString() ?? '—',
          };
        }).toList();
      }

      // 3. Load Clients
      final clientsRes = await _apiClient.get(
        '/magasinier/clients',
        forceRefresh: forceRefresh,
        useCache: true,
      );
      if (mounted && clientsRes is List) {
        _clientsList = clientsRes.map<Map<String, dynamic>>((c) {
          return {
            'id': c['id']?.toString() ?? '',
            'name': c['name']?.toString() ?? '',
            'phone': c['phone']?.toString() ?? '',
            'address': c['address']?.toString() ?? '',
            'type': c['type']?.toString() ?? 'Détaillante',
          };
        }).toList();
      }
    } catch (_) {
      // Keep local defaults on network error
    } finally {
      if (mounted) setState(() {});
    }
  }

  @override
  void dispose() {
    _socketSubscription?.cancel();
    _clientNameController.dispose();
    _clientContactController.dispose();
    _clientAddressController.dispose();
    _totalSaleAmountController.dispose();
    _paidAmountController.dispose();
    for (final controller in _quantityControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isAddingVente) {
      return _buildNewSaleForm();
    }

    return Column(
      children: [
        // Tabs (Historique / Remboursement)
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
                    'Historique des Ventes',
                    _activeSubTab == 'history',
                    () => setState(() => _activeSubTab = 'history'),
                  ),
                ),
                Expanded(
                  child: _buildSubTabButton(
                    'Remboursement Crédits (${_debtors.length})',
                    _activeSubTab == 'refund',
                    () => setState(() => _activeSubTab = 'refund'),
                  ),
                ),
              ],
            ),
          ),
        ),

        Expanded(
          child: _activeSubTab == 'history'
              ? _buildHistoryTab()
              : _buildReimbursementTab(),
        ),
      ],
    );
  }

  // --- TAB 1: SALES HISTORY ---
  Widget _buildHistoryTab() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final filteredSales = _salesHistory.where((sale) {
      final clientText = (sale['client'] ?? '').toString().toLowerCase();
      final idText = (sale['id'] ?? '').toString().toLowerCase();
      final detailsText = (sale['details'] ?? '').toString().toLowerCase();
      final q = _clientSearchQuery.trim().toLowerCase();
      final matchesSearch =
          q.isEmpty ||
          clientText.contains(q) ||
          idText.contains(q) ||
          detailsText.contains(q);

      if (!matchesSearch) return false;

      final saleDate = sale['date'] is DateTime
          ? (sale['date'] as DateTime)
          : DateTime.now();

      if (_selectedFilterDate != null) {
        if (saleDate.year != _selectedFilterDate!.year ||
            saleDate.month != _selectedFilterDate!.month ||
            saleDate.day != _selectedFilterDate!.day) {
          return false;
        }
      }

      switch (_salesPeriodFilter) {
        case 'today':
          final sDay = DateTime(saleDate.year, saleDate.month, saleDate.day);
          return sDay.isAtSameMomentAs(today);
        case '7j':
          final sevenDaysAgo = today.subtract(const Duration(days: 7));
          return saleDate.isAfter(sevenDaysAgo) ||
              saleDate.isAtSameMomentAs(sevenDaysAgo);
        case '30j':
          final thirtyDaysAgo = today.subtract(const Duration(days: 30));
          return saleDate.isAfter(thirtyDaysAgo) ||
              saleDate.isAtSameMomentAs(thirtyDaysAgo);
        case 'custom':
          if (_selectedDateRange != null) {
            final start = DateTime(
              _selectedDateRange!.start.year,
              _selectedDateRange!.start.month,
              _selectedDateRange!.start.day,
            );
            final end = DateTime(
              _selectedDateRange!.end.year,
              _selectedDateRange!.end.month,
              _selectedDateRange!.end.day,
              23,
              59,
              59,
            );
            return (saleDate.isAfter(start) ||
                    saleDate.isAtSameMomentAs(start)) &&
                (saleDate.isBefore(end) || saleDate.isAtSameMomentAs(end));
          }
          return true;
        case 'all':
        default:
          return true;
      }
    }).toList();

    final int totalPeriodSales = filteredSales.fold<int>(
      0,
      (sum, s) => sum + ((s['amount'] as num?)?.toInt() ?? 0),
    );
    final int totalPeriodCash = filteredSales.fold<int>(
      0,
      (sum, s) => sum + ((s['paid'] as num?)?.toInt() ?? 0),
    );
    final int totalPeriodCredit = filteredSales.fold<int>(
      0,
      (sum, s) => sum + ((s['due'] as num?)?.toInt() ?? 0),
    );
    final int totalReceivables = _debtors.fold<int>(
      0,
      (sum, d) => sum + ((d['due'] as num?)?.toInt() ?? 0),
    );

    return Column(
      children: [
        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadAllData,
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              children: [
                // Filter by Period Selector
                const Text(
                  'FILTRER PAR PÉRIODE',
                  style: AppTypography.labelSmall,
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: AppColors.paper,
                          border: Border.all(color: AppColors.line, width: 1.5),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _salesPeriodFilter,
                            isExpanded: true,
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.primaryDark,
                            ),
                            onChanged: (val) async {
                              if (val != null) {
                                setState(() => _salesPeriodFilter = val);
                                if (val == 'custom') {
                                  final picked = await showDateRangePicker(
                                    context: context,
                                    firstDate: DateTime(2025),
                                    lastDate: DateTime(2027),
                                  );
                                  if (picked != null) {
                                    setState(() => _selectedDateRange = picked);
                                  }
                                }
                              }
                            },
                            items: const [
                              DropdownMenuItem(
                                value: 'all',
                                child: Text('Toutes les ventes (Global)'),
                              ),
                              DropdownMenuItem(
                                value: 'today',
                                child: Text('Aujourd\'hui'),
                              ),
                              DropdownMenuItem(
                                value: '7j',
                                child: Text('7 derniers jours'),
                              ),
                              DropdownMenuItem(
                                value: '30j',
                                child: Text('Mois en cours (30 jours)'),
                              ),
                              DropdownMenuItem(
                                value: 'custom',
                                child: Text('Période personnalisée'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                if (_salesPeriodFilter == 'custom' &&
                    _selectedDateRange != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    'Période : ${_formatDate(_selectedDateRange!.start)} au ${_formatDate(_selectedDateRange!.end)}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
                const SizedBox(height: 12),

                // Summary KPI Card
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
                      Text(
                        _getPeriodLabel(),
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 10.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${_formatCurrency(totalPeriodSales)} FCFA',
                        style: const TextStyle(
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
                          _buildSummaryItem(
                            'Comptant',
                            '${_formatCurrency(totalPeriodCash)} FCFA',
                          ),
                          _buildSummaryItem(
                            'Crédit',
                            '${_formatCurrency(totalPeriodCredit)} FCFA',
                          ),
                          _buildSummaryItem(
                            'Créances tot.',
                            '${_formatCurrency(totalReceivables)} FCFA',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Real Dynamic Graphical Distribution Chart
                _buildDynamicSalesChart(filteredSales),
                const SizedBox(height: 14),

                // Search and Specific Date Filter
                AppInputBox(
                  placeholder: 'Rechercher par client ou facture…',
                  suffix: const Icon(
                    Icons.search,
                    size: 18,
                    color: AppColors.inkSoft,
                  ),
                  onChanged: (val) => setState(() => _clientSearchQuery = val),
                ),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime(2025),
                      lastDate: DateTime(2027),
                    );
                    if (picked != null) {
                      setState(() => _selectedFilterDate = picked);
                    }
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.paper,
                      border: Border.all(color: AppColors.line),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.calendar_today,
                          size: 16,
                          color: AppColors.inkSoft,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _selectedFilterDate == null
                                ? 'Filtrer par date exacte (Toutes)'
                                : 'Date : ${_formatDate(_selectedFilterDate!)}',
                            style: TextStyle(
                              fontSize: 12.5,
                              color: _selectedFilterDate == null
                                  ? AppColors.inkSoft
                                  : AppColors.primaryDark,
                              fontWeight: _selectedFilterDate == null
                                  ? FontWeight.normal
                                  : FontWeight.bold,
                            ),
                          ),
                        ),
                        if (_selectedFilterDate != null)
                          GestureDetector(
                            onTap: () =>
                                setState(() => _selectedFilterDate = null),
                            child: const Icon(
                              Icons.clear,
                              size: 16,
                              color: AppColors.inkSoft,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // Section Title
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'HISTORIQUE DES FACTURES (${filteredSales.length})',
                      style: AppTypography.labelSmall,
                    ),
                    if (filteredSales.isNotEmpty)
                      Text(
                        'Total : ${_formatCurrency(totalPeriodSales)} FCFA',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryDark,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),

                // Sales list items
                if (filteredSales.isEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 36),
                    alignment: Alignment.center,
                    child: const Text(
                      'Aucune vente enregistrée pour cette sélection',
                      style: TextStyle(color: AppColors.inkSoft),
                    ),
                  )
                else
                  ...filteredSales.map((sale) {
                    Color statusColor = AppColors.primaryDark;
                    if (sale['status'] == 'Crédit')
                      statusColor = AppColors.danger;
                    if (sale['status'] == 'Partiel')
                      statusColor = AppColors.accent;

                    return GestureDetector(
                      onTap: () => _showSaleDetails(sale),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: const BoxDecoration(
                          border: Border(
                            bottom: BorderSide(color: AppColors.line),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: statusColor.withOpacity(0.12),
                                shape: BoxShape.circle,
                              ),
                              alignment: Alignment.center,
                              child: Icon(
                                Icons.receipt_long,
                                color: statusColor,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    sale['client'] as String,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13.5,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${sale['details']} · ${_formatDate(sale['date'] as DateTime)}',
                                    style: const TextStyle(
                                      color: AppColors.inkSoft,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '${_formatCurrency((sale['amount'] as num?)?.toInt() ?? 0)} FCFA',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: statusColor.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    sale['status'] as String,
                                    style: TextStyle(
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.bold,
                                      color: statusColor,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),

        // Effectuer une vente Sticky Bar
        Container(
          padding: const EdgeInsets.all(12),
          decoration: const BoxDecoration(
            color: AppColors.paper,
            border: Border(top: BorderSide(color: AppColors.line)),
          ),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.add_shopping_cart, size: 18),
              onPressed: () {
                setState(() {
                  _isAddingVente = true;
                  _selectedClientId = null;
                  _clientNameController.clear();
                  _clientContactController.clear();
                  _clientAddressController.clear();
                  _paidAmountController.clear();
                  _totalSaleAmountController.clear();
                  _qtyPetit = 0;
                  _qtyMoyen = 0;
                  _qtyGros = 0;
                  _qtyPlusGros = 0;
                  _dueDate = null;
                });
              },
              label: const Text('Effectuer une vente'),
            ),
          ),
        ),
      ],
    );
  }

  // --- TAB 2: REIMBURSEMENT (CREDITORS LIST) ---
  Widget _buildReimbursementTab() {
    return RefreshIndicator(
      onRefresh: _loadAllData,
      child: _debtors.isEmpty
          ? const Center(
              child: Text(
                'Aucun client avec un crédit en cours.',
                style: TextStyle(color: AppColors.inkSoft),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(14),
              itemCount: _debtors.length,
              itemBuilder: (context, index) {
                final debtor = _debtors[index];
                final isOverdue = debtor['isOverdue'] == true;
                return Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    color: AppColors.paper,
                    border: Border.all(color: AppColors.line),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: isOverdue
                              ? AppColors.errorLight
                              : AppColors.warningLight,
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          debtor['name'].toString().isNotEmpty
                              ? debtor['name']
                                    .toString()
                                    .substring(0, 2)
                                    .toUpperCase()
                              : 'CL',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isOverdue
                                ? AppColors.danger
                                : AppColors.warning,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              debtor['name'] as String,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13.5,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${debtor['due']} FCFA dus · ${debtor['status']}',
                              style: TextStyle(
                                color: isOverdue
                                    ? AppColors.danger
                                    : AppColors.inkSoft,
                                fontSize: 11,
                                fontWeight: isOverdue
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () => _showRepaymentDialog(debtor),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          minimumSize: Size.zero,
                        ),
                        child: const Text(
                          'Rembourser',
                          style: TextStyle(fontSize: 11.5),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }

  // --- SALE DETAILS MODAL ---
  void _showSaleDetails(Map<String, dynamic> sale) {
    showDialog(
      context: context,
      builder: (context) {
        Color statusColor = AppColors.primaryDark;
        if (sale['status'] == 'Crédit') statusColor = AppColors.danger;
        if (sale['status'] == 'Partiel') statusColor = AppColors.accent;

        final items = (sale['items'] is List) ? (sale['items'] as List) : [];
        final statusText = sale['status']?.toString() ?? 'Payé';
        final clientName =
            sale['client']?.toString() ??
            sale['customer_name']?.toString() ??
            'Client';
        final contactStr =
            sale['contact']?.toString() ??
            sale['customer_phone']?.toString() ??
            '—';
        final addressStr =
            sale['address']?.toString() ??
            sale['customer_address']?.toString() ??
            '—';
        final dateStr = sale['date'] is DateTime
            ? _formatDate(sale['date'] as DateTime)
            : (sale['date']?.toString().split('T')[0] ?? '—');
        final amountVal =
            (sale['amount'] as num?)?.toDouble() ??
            (sale['total_amount'] as num?)?.toDouble() ??
            0.0;
        final paidVal =
            (sale['paid'] as num?)?.toDouble() ??
            (sale['amount_paid'] as num?)?.toDouble() ??
            0.0;
        final dueVal =
            (sale['due'] as num?)?.toDouble() ??
            (sale['remaining_balance'] as num?)?.toDouble() ??
            0.0;

        return AlertDialog(
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Détails de la Facture',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  statusText,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildModalRow('Client :', clientName, isBold: true),
                _buildModalRow('Contact :', contactStr),
                _buildModalRow('Adresse :', addressStr),
                _buildModalRow('Date :', dateStr),
                const Divider(height: 20, color: AppColors.line),
                const Text(
                  'ARTICLES VENDUS',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppColors.inkSoft,
                  ),
                ),
                const SizedBox(height: 6),
                if (items.isEmpty)
                  Text(
                    sale['details']?.toString() ?? 'Articles d\'œufs',
                    style: const TextStyle(fontSize: 13),
                  )
                else
                  ...items.map((item) {
                    final qty = (item['quantity'] as num?)?.toDouble() ?? 0.0;
                    final unitPrice =
                        (item['unit_price'] as num?)?.toDouble() ??
                        (item['unitPrice'] as num?)?.toDouble() ??
                        0.0;
                    final total =
                        (item['total'] as num?)?.toDouble() ??
                        (qty * unitPrice);
                    final name =
                        item['name']?.toString() ??
                        item['calibre']?.toString() ??
                        'Article';
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 3),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '$name (${qty.toInt()} plq. / ${qty.toInt() * 30} œufs)',
                            style: const TextStyle(fontSize: 12.5),
                          ),
                          Text(
                            '${total.toInt()} FCFA',
                            style: const TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                const Divider(height: 20, color: AppColors.line),
                _buildModalRow(
                  'Montant Total :',
                  '${amountVal.toInt()} FCFA',
                  isBold: true,
                ),
                _buildModalRow(
                  'Montant Réglé :',
                  '${paidVal.toInt()} FCFA',
                  color: AppColors.primaryDark,
                ),
                _buildModalRow(
                  'Solde Restant Dû :',
                  '${dueVal.toInt()} FCFA',
                  isBold: true,
                  color: dueVal > 0 ? AppColors.danger : AppColors.primaryDark,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Fermer'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildModalRow(
    String label,
    String value, {
    bool isBold = false,
    Color? color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: AppColors.inkSoft, fontSize: 12.5),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: color ?? AppColors.ink,
            ),
          ),
        ],
      ),
    );
  }

  // --- REPAYMENT/REMBOURSEMENT DIALOG ---
  void _showRepaymentDialog(Map<String, dynamic> debtor) {
    final refundController = TextEditingController();
    String method = 'espèces';
    showDialog(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (stateCtx, setDialogState) {
            return AlertDialog(
              title: Text('Remboursement : ${debtor['name']}'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Créance restante due : ${debtor['due']} FCFA',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.danger,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Montant remboursé (FCFA) :',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: refundController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      hintText: 'Ex: 20000',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Mode de paiement :',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Radio<String>(
                        value: 'espèces',
                        groupValue: method,
                        activeColor: AppColors.primaryDark,
                        onChanged: (val) => setDialogState(() => method = val!),
                      ),
                      const Text('Espèces'),
                      const SizedBox(width: 14),
                      Radio<String>(
                        value: 'mobile_money',
                        groupValue: method,
                        activeColor: AppColors.primaryDark,
                        onChanged: (val) => setDialogState(() => method = val!),
                      ),
                      const Text('MOMo'),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogCtx).pop(),
                  child: const Text('Annuler'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final int amt = int.tryParse(refundController.text) ?? 0;
                    if (amt <= 0 || amt > (debtor['due'] as int)) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Veuillez entrer un montant valide inférieur ou égal à la dette.',
                          ),
                        ),
                      );
                      return;
                    }

                    showActionLoadingDialog(
                      context,
                      message: 'Enregistrement du remboursement...',
                    );
                    bool isOfflineQueued = false;
                    try {
                      final clientId = debtor['client_id'] ?? debtor['id'];
                      final isOnline = await _networkChecker.hasConnection;
                      if (!isOnline) {
                        await _offlineSyncService.enqueueOperation(
                          endpoint: '/magasinier/clients/$clientId/refund',
                          method: 'POST',
                          payload: {'amount': amt, 'payment_method': method},
                          description:
                              'Remboursement: ${debtor['name']} ($amt FCFA)',
                        );
                        isOfflineQueued = true;
                      } else {
                        await _apiClient.post(
                          '/magasinier/clients/$clientId/refund',
                          data: {'amount': amt, 'payment_method': method},
                        );
                      }
                    } catch (_) {
                      final clientId = debtor['client_id'] ?? debtor['id'];
                      await _offlineSyncService.enqueueOperation(
                        endpoint: '/magasinier/clients/$clientId/refund',
                        method: 'POST',
                        payload: {'amount': amt, 'payment_method': method},
                        description:
                            'Remboursement: ${debtor['name']} ($amt FCFA)',
                      );
                      isOfflineQueued = true;
                    } finally {
                      if (mounted) {
                        Navigator.of(
                          context,
                          rootNavigator: true,
                        ).pop(); // dismiss loading dialog
                      }
                    }

                    setState(() {
                      debtor['due'] = (debtor['due'] as int) - amt;
                      if ((debtor['due'] as int) <= 0) {
                        debtor['status'] = 'Réglé';
                        _debtors.removeWhere(
                          (d) => d['name'] == debtor['name'],
                        );
                      } else {
                        debtor['status'] =
                            'Créance mise à jour (${debtor['due']} FCFA restant)';
                      }
                    });

                    if (mounted) {
                      Navigator.of(dialogCtx).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          backgroundColor: isOfflineQueued
                              ? Colors.orange
                              : AppColors.syncGreen,
                          content: Text(
                            isOfflineQueued
                                ? 'Remboursement enregistré hors-ligne (en attente de synchro) !'
                                : 'Remboursement de $amt FCFA enregistré avec succès !',
                          ),
                        ),
                      );
                      _loadAllData(forceRefresh: true);
                    }
                  },
                  child: const Text('Enregistrer'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // --- FORM 3: EFFECTUER UNE VENTE FORM ---
  Widget _buildNewSaleForm() {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.primaryDark),
          onPressed: () => setState(() => _isAddingVente = false),
        ),
        title: const Text(
          'Effectuer une vente',
          style: TextStyle(
            color: AppColors.primaryDark,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Client selector / autocomplete
            const Text('CLIENT & CONTACTS', style: AppTypography.label),
            const SizedBox(height: 8),

            if (_clientsList.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: AppColors.paper,
                  border: Border.all(color: AppColors.line),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    value: _selectedClientId,
                    hint: const Text(
                      'Choisir un client enregistré…',
                      style: TextStyle(fontSize: 13),
                    ),
                    items: [
                      const DropdownMenuItem<String>(
                        value: null,
                        child: Text(
                          '+ Nouveau client / Passage',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryDark,
                          ),
                        ),
                      ),
                      ..._clientsList.map((c) {
                        return DropdownMenuItem<String>(
                          value: c['id']?.toString(),
                          child: Text(
                            '${c['name']} (${c['phone'] ?? c['type']})',
                            style: const TextStyle(fontSize: 13),
                          ),
                        );
                      }),
                    ],
                    onChanged: (val) {
                      setState(() {
                        _selectedClientId = val;
                        if (val != null) {
                          final selected = _clientsList.firstWhere(
                            (c) => c['id'] == val,
                            orElse: () => {},
                          );
                          _clientNameController.text = selected['name'] ?? '';
                          _clientContactController.text =
                              selected['phone'] ?? '';
                          _clientAddressController.text =
                              selected['address'] ?? '';
                        }
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(height: 10),
            ],

            AppInputBox(
              label: 'Nom complet du client',
              placeholder: 'Ex : Adjoua Tanoh',
              controller: _clientNameController,
            ),
            const SizedBox(height: 10),
            AppInputBox(
              label: 'Numéro de contact',
              placeholder: 'Ex : 07 08 09 10 11',
              controller: _clientContactController,
            ),
            const SizedBox(height: 10),
            AppInputBox(
              label: 'Adresse / Point de livraison',
              placeholder: 'Ex : Marché d\'Korhogo',
              controller: _clientAddressController,
            ),
            const SizedBox(height: 16),

            // Formats counts
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'SÉLECTIONNER LES FORMATS (EN ŒUFS)',
                  style: AppTypography.label,
                ),
                Text(
                  'Total : ${_qtyPetit + _qtyMoyen + _qtyGros + _qtyPlusGros} œufs (~${(_qtyPetit + _qtyMoyen + _qtyGros + _qtyPlusGros) ~/ 30} plq${(_qtyPetit + _qtyMoyen + _qtyGros + _qtyPlusGros) % 30 > 0 ? " + ${(_qtyPetit + _qtyMoyen + _qtyGros + _qtyPlusGros) % 30}" : ""})',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryDark,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _buildFormatInputRow(
              'Petit format',
              _qtyPetit,
              (val) => setState(() => _qtyPetit = val),
            ),
            _buildFormatInputRow(
              'Moyen format',
              _qtyMoyen,
              (val) => setState(() => _qtyMoyen = val),
            ),
            _buildFormatInputRow(
              'Gros format',
              _qtyGros,
              (val) => setState(() => _qtyGros = val),
            ),
            _buildFormatInputRow(
              'Plus gros format',
              _qtyPlusGros,
              (val) => setState(() => _qtyPlusGros = val),
            ),
            const SizedBox(height: 16),

            // Payment tracking
            const Text('PAIEMENT & CALCULS', style: AppTypography.label),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.paper,
                border: Border.all(color: AppColors.line),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  AppInputBox(
                    label: 'Montant total de la vente (FCFA)',
                    placeholder: 'Saisir le montant total (ex : 25 000)',
                    controller: _totalSaleAmountController,
                    inputType: TextInputType.number,
                    onChanged: (_) => setState(() {}),
                  ),
                  const Divider(height: 16, color: AppColors.line),
                  AppInputBox(
                    label: 'Montant réglé / payé (FCFA)',
                    placeholder: 'Saisir le montant payé (ex : 25 000)',
                    controller: _paidAmountController,
                    inputType: TextInputType.number,
                    onChanged: (val) => setState(() {}),
                  ),
                  const SizedBox(height: 10),
                  _buildCalculationRow(
                    'Reste à payer',
                    '$_remainingToPay FCFA',
                    valueColor: _remainingToPay > 0
                        ? AppColors.danger
                        : AppColors.primaryDark,
                    isBold: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Due date if credit
            if (_remainingToPay > 0) ...[
              const Text(
                'ÉCHÉANCE DU CRÉDIT (REQUIS)',
                style: AppTypography.label,
              ),
              const SizedBox(height: 6),
              GestureDetector(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now().add(const Duration(days: 7)),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 90)),
                  );
                  if (picked != null) {
                    setState(() => _dueDate = picked);
                  }
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.paper,
                    border: Border.all(color: AppColors.line, width: 1.6),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.calendar_today,
                        size: 16,
                        color: AppColors.inkSoft,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _dueDate == null
                            ? 'Choisir la date d\'échéance'
                            : _formatDate(_dueDate!),
                        style: TextStyle(
                          color: _dueDate == null
                              ? AppColors.inkSoft
                              : AppColors.primaryDark,
                          fontWeight: _dueDate == null
                              ? FontWeight.normal
                              : FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Submit Vente
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed:
                    (_totalSaleAmount == 0 ||
                        (_remainingToPay > 0 && _dueDate == null) ||
                        _clientNameController.text.trim().isEmpty)
                    ? null
                    : () async {
                        final int totalEggs =
                            _qtyPetit + _qtyMoyen + _qtyGros + _qtyPlusGros;
                        final double totalPlates = totalEggs / 30.0;
                        final itemsList = [
                          if (_qtyPetit > 0)
                            {
                              'calibre': 'petit',
                              'name': 'Petit format',
                              'quantity': _qtyPetit,
                              'eggs': _qtyPetit,
                              'plates': _qtyPetit / 30.0,
                            },
                          if (_qtyMoyen > 0)
                            {
                              'calibre': 'moyen',
                              'name': 'Moyen format',
                              'quantity': _qtyMoyen,
                              'eggs': _qtyMoyen,
                              'plates': _qtyMoyen / 30.0,
                            },
                          if (_qtyGros > 0)
                            {
                              'calibre': 'gros',
                              'name': 'Gros format',
                              'quantity': _qtyGros,
                              'eggs': _qtyGros,
                              'plates': _qtyGros / 30.0,
                            },
                          if (_qtyPlusGros > 0)
                            {
                              'calibre': 'plusGros',
                              'name': 'Plus Gros format',
                              'quantity': _qtyPlusGros,
                              'eggs': _qtyPlusGros,
                              'plates': _qtyPlusGros / 30.0,
                            },
                        ];

                        final int paidAmt =
                            int.tryParse(_paidAmountController.text.trim()) ??
                            0;
                        final String clientName = _clientNameController.text
                            .trim();
                        final String clientPhone = _clientContactController.text
                            .trim();
                        final String clientAddress = _clientAddressController
                            .text
                            .trim();

                        final saleData = {
                          'customer_id': _selectedClientId,
                          'client_id': _selectedClientId,
                          'customer_name': clientName,
                          'buyer_name': clientName,
                          'clientName': clientName,
                          'customer_phone': clientPhone,
                          'contact': clientPhone,
                          'customer_address': clientAddress,
                          'address': clientAddress,
                          'total_amount': _totalSaleAmount,
                          'amount_paid': paidAmt,
                          'paidAmount': paidAmt,
                          'due_date': _dueDate?.toIso8601String().split('T')[0],
                          'dueDate': _dueDate?.toIso8601String(),
                          'format_petit': _qtyPetit,
                          'qtyPetit': _qtyPetit,
                          'eggsPetit': _qtyPetit,
                          'format_moyen': _qtyMoyen,
                          'qtyMoyen': _qtyMoyen,
                          'eggsMoyen': _qtyMoyen,
                          'format_gros': _qtyGros,
                          'qtyGros': _qtyGros,
                          'eggsGros': _qtyGros,
                          'format_plus_gros': _qtyPlusGros,
                          'qtyPlusGros': _qtyPlusGros,
                          'eggsPlusGros': _qtyPlusGros,
                          'quantity_plates': totalPlates > 0 ? totalPlates : 1.0,
                          'quantity_eggs': totalEggs > 0 ? totalEggs : 30,
                          'quantity': totalEggs > 0 ? totalEggs : 30,
                          'items': itemsList,
                        };

                        showActionLoadingDialog(
                          context,
                          message: 'Enregistrement de la vente...',
                        );
                        bool isOfflineQueued = false;
                        try {
                          final isOnline = await _networkChecker.hasConnection;
                          if (!isOnline) {
                            await _offlineSyncService.enqueueOperation(
                              endpoint: '/magasinier/sales',
                              method: 'POST',
                              payload: saleData,
                              description:
                                  'Vente: $clientName ($totalEggs œufs / $_totalSaleAmount FCFA)',
                            );
                            isOfflineQueued = true;
                          } else {
                            await _apiClient.post(
                              '/magasinier/sales',
                              data: saleData,
                            );
                          }
                        } catch (_) {
                          await _offlineSyncService.enqueueOperation(
                            endpoint: '/magasinier/sales',
                            method: 'POST',
                            payload: saleData,
                            description:
                                'Vente: $clientName ($totalEggs œufs / $_totalSaleAmount FCFA)',
                          );
                          isOfflineQueued = true;
                        } finally {
                          if (mounted) {
                            Navigator.of(
                              context,
                              rootNavigator: true,
                            ).pop(); // dismiss loading dialog
                          }
                        }

                        final displayEggs = totalEggs > 0 ? totalEggs : 30;
                        final displayPlates = totalPlates > 0 ? totalPlates : 1.0;

                        setState(() {
                          _salesHistory.insert(0, {
                            'id': 'V-${DateTime.now().millisecondsSinceEpoch}',
                            'date': DateTime.now(),
                            'client': clientName,
                            'contact': clientPhone,
                            'address': clientAddress,
                            'details':
                                '$displayEggs œufs (~${displayPlates.toStringAsFixed(1)} plateaux)',
                            'amount': _totalSaleAmount,
                            'paid': paidAmt,
                            'due': _remainingToPay,
                            'status': _remainingToPay == 0
                                ? 'Payé'
                                : (_remainingToPay == _totalSaleAmount
                                      ? 'Crédit'
                                      : 'Partiel'),
                            'items': itemsList,
                          });

                          if (_remainingToPay > 0) {
                            _debtors.insert(0, {
                              'client_id': _selectedClientId ?? '',
                              'name': clientName,
                              'due': _remainingToPay,
                              'status': _dueDate != null
                                  ? 'Échéance ${_formatDate(_dueDate!)}'
                                  : 'À crédit',
                              'isOverdue': false,
                              'phone': clientPhone,
                              'address': clientAddress,
                            });
                          }
                          _isAddingVente = false;
                        });

                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              backgroundColor: isOfflineQueued
                                  ? Colors.orange
                                  : AppColors.syncGreen,
                              content: Text(
                                isOfflineQueued
                                    ? 'Vente enregistrée hors-ligne ($displayEggs œufs déstockés localement) !'
                                    : 'Vente enregistrée avec succès ! ($displayEggs œufs / ~${displayPlates.toStringAsFixed(1)} plq déstockés)',
                              ),
                            ),
                          );
                        }
                        _loadAllData(forceRefresh: true);
                      },
                child: const Text('Valider la vente'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormatInputRow(
    String label,
    int value,
    Function(int) onChanged,
  ) {
    final controller = _quantityControllers.putIfAbsent(
      label,
      () => TextEditingController(text: value.toString()),
    );
    if (controller.text != value.toString() &&
        int.tryParse(controller.text) != value) {
      controller.text = value.toString();
    }
    final int platesCount = value ~/ 30;
    final int remainingEggs = value % 30;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.paper,
        border: Border.all(color: AppColors.line),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$value œufs (~$platesCount plq${remainingEggs > 0 ? " + $remainingEggs œufs" : ""})',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.inkSoft,
                  ),
                ),
              ],
            ),
          ),
          Row(
            children: [
              GestureDetector(
                onTap: () {
                  final next = (value >= 30) ? value - 30 : 0;
                  controller.text = next.toString();
                  controller.selection = TextSelection.collapsed(
                    offset: controller.text.length,
                  );
                  onChanged(next);
                },
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  alignment: Alignment.center,
                  child: const Text(
                    '–',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: AppColors.primaryDark,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 82,
                height: 38,
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: AppColors.line, width: 1.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: TextField(
                  controller: controller,
                  textAlign: TextAlign.center,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryDark,
                  ),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(
                      vertical: 8,
                      horizontal: 4,
                    ),
                  ),
                  onChanged: (input) {
                    final parsed = int.tryParse(input);
                    if (parsed != null && parsed >= 0) {
                      onChanged(parsed);
                    } else if (input.isEmpty) {
                      onChanged(0);
                    }
                  },
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () {
                  final next = (value + 30).clamp(0, 100000);
                  controller.text = next.toString();
                  controller.selection = TextSelection.collapsed(
                    offset: controller.text.length,
                  );
                  onChanged(next);
                },
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  alignment: Alignment.center,
                  child: const Text(
                    '+',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
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

  Widget _buildDynamicSalesChart(List<Map<String, dynamic>> sales) {
    final now = DateTime.now();
    final List<DateTime> last7Days = List.generate(7, (i) {
      final d = now.subtract(Duration(days: 6 - i));
      return DateTime(d.year, d.month, d.day);
    });

    final List<String> dayLabels = ['L', 'M', 'M', 'J', 'V', 'S', 'D'];
    final Map<int, int> dayPlates = {};
    for (int i = 0; i < 7; i++) {
      dayPlates[i] = 0;
    }

    int totalPetit = 0;
    int totalMoyen = 0;
    int totalGros = 0;
    int totalPlusGros = 0;

    for (final sale in sales) {
      final saleDate = sale['date'] is DateTime
          ? (sale['date'] as DateTime)
          : DateTime.now();
      final sDate = DateTime(saleDate.year, saleDate.month, saleDate.day);

      int sPetit =
          (sale['format_petit'] as num?)?.toInt() ??
          (sale['qtyPetit'] as num?)?.toInt() ??
          0;
      int sMoyen =
          (sale['format_moyen'] as num?)?.toInt() ??
          (sale['qtyMoyen'] as num?)?.toInt() ??
          0;
      int sGros =
          (sale['format_gros'] as num?)?.toInt() ??
          (sale['qtyGros'] as num?)?.toInt() ??
          0;
      int sPlus =
          (sale['format_plus_gros'] as num?)?.toInt() ??
          (sale['qtyPlusGros'] as num?)?.toInt() ??
          0;

      final items = sale['items'] is List ? (sale['items'] as List) : [];
      if (items.isNotEmpty) {
        sPetit = 0;
        sMoyen = 0;
        sGros = 0;
        sPlus = 0;
        for (final it in items) {
          final calibre = (it['calibre'] ?? it['name'] ?? '')
              .toString()
              .toLowerCase();
          final q = (it['quantity'] as num?)?.toInt() ?? 0;
          if (calibre.contains('plus')) {
            sPlus += q;
          } else if (calibre.contains('gros')) {
            sGros += q;
          } else if (calibre.contains('petit')) {
            sPetit += q;
          } else {
            sMoyen += q;
          }
        }
      }

      if (sPetit == 0 && sMoyen == 0 && sGros == 0 && sPlus == 0) {
        final details = (sale['details'] ?? '').toString().toLowerCase();
        final amt = (sale['amount'] as num?)?.toInt() ?? 0;
        final qTotal =
            (sale['quantity_plates'] as num?)?.toInt() ??
            (sale['quantity'] as num?)?.toInt() ??
            (amt > 0 ? (amt / 2200).round() : 10);
        final displayQ = qTotal > 0 ? qTotal : 10;

        if (details.contains('plus')) {
          sPlus += displayQ;
        } else if (details.contains('gros')) {
          sGros += displayQ;
        } else if (details.contains('petit')) {
          sPetit += displayQ;
        } else if (details.contains('moyen')) {
          sMoyen += displayQ;
        } else {
          final int pM = (displayQ * 0.40).round();
          final int pG = (displayQ * 0.30).round();
          final int pP = (displayQ * 0.15).round();
          final int pSmall = (displayQ - (pM + pG + pP)).clamp(0, 10000);
          sMoyen += pM > 0 ? pM : 1;
          sGros += pG;
          sPlus += pP;
          sPetit += pSmall;
        }
      }

      final int saleTotalPlates = sPetit + sMoyen + sGros + sPlus;

      for (int i = 0; i < 7; i++) {
        if (sDate.isAtSameMomentAs(last7Days[i])) {
          dayPlates[i] = (dayPlates[i] ?? 0) + saleTotalPlates;
        }
      }

      totalPetit += sPetit;
      totalMoyen += sMoyen;
      totalGros += sGros;
      totalPlusGros += sPlus;
    }

    int maxPlates = 1;
    for (final p in dayPlates.values) {
      if (p > maxPlates) maxPlates = p;
    }

    final int totalPlatesAll =
        totalPetit + totalMoyen + totalGros + totalPlusGros;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.paper,
        border: Border.all(color: AppColors.line),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'RÉPARTITION GRAPHIQUE',
                    style: AppTypography.labelSmall,
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Volume des 7 derniers jours (Plateaux de 30)',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.inkSoft,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: Icon(
                  _showGraphBreakdown
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
                  size: 20,
                  color: AppColors.inkSoft,
                ),
                onPressed: () =>
                    setState(() => _showGraphBreakdown = !_showGraphBreakdown),
              ),
            ],
          ),
          if (_showGraphBreakdown) ...[
            const SizedBox(height: 14),
            SizedBox(
              height: 140,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: List.generate(7, (i) {
                  final dayDate = last7Days[i];
                  final weekdayIndex = (dayDate.weekday - 1) % 7;
                  final label = dayLabels[weekdayIndex];
                  final count = dayPlates[i] ?? 0;
                  final heightFactor = (count / maxPlates).clamp(0.08, 1.0);
                  final isToday = i == 6;

                  return _buildDailyBar(heightFactor, label, isToday, count);
                }),
              ),
            ),
            const SizedBox(height: 16),
            const Divider(height: 1, color: AppColors.line),
            const SizedBox(height: 12),
            const Text(
              'RÉPARTITION PAR CALIBRE (PÉRIODE)',
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.bold,
                color: AppColors.inkSoft,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildFormatChip(
                    'Plus Gros',
                    totalPlusGros,
                    totalPlatesAll,
                    AppColors.danger,
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: _buildFormatChip(
                    'Gros',
                    totalGros,
                    totalPlatesAll,
                    AppColors.primary,
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: _buildFormatChip(
                    'Moyen',
                    totalMoyen,
                    totalPlatesAll,
                    AppColors.primaryDark,
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: _buildFormatChip(
                    'Petit',
                    totalPetit,
                    totalPlatesAll,
                    AppColors.accent,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDailyBar(
    double heightFactor,
    String label,
    bool isToday,
    int plateCount,
  ) {
    Color barColor = isToday ? AppColors.accent : AppColors.primary;
    if (plateCount == 0) barColor = AppColors.line;

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(
          '$plateCount pl.',
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.bold,
            color: isToday
                ? AppColors.accent
                : (plateCount > 0 ? AppColors.primaryDark : AppColors.inkSoft),
          ),
        ),
        const SizedBox(height: 4),
        Container(
          height: 80 * heightFactor,
          width: 18,
          decoration: BoxDecoration(
            color: barColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
          ),
        ),
        const SizedBox(height: 5),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: isToday ? AppColors.accent : AppColors.inkSoft,
          ),
        ),
      ],
    );
  }

  Widget _buildFormatChip(String label, int plates, int totalAll, Color color) {
    final double pct = totalAll > 0 ? (plates / totalAll * 100) : 0;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 9.5,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '$plates pl.',
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: AppColors.ink,
            ),
          ),
          Text(
            '${pct.toStringAsFixed(0)}%',
            style: const TextStyle(fontSize: 9, color: AppColors.inkSoft),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String title, String val) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(color: Colors.white70, fontSize: 10),
        ),
        const SizedBox(height: 2),
        Text(
          val,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  String _formatCurrency(num value) {
    final str = value.toInt().toString();
    final buffer = StringBuffer();
    int count = 0;
    for (int i = str.length - 1; i >= 0; i--) {
      buffer.write(str[i]);
      count++;
      if (count % 3 == 0 && i > 0) {
        buffer.write(' ');
      }
    }
    return buffer.toString().split('').reversed.join('');
  }

  String _getPeriodLabel() {
    switch (_salesPeriodFilter) {
      case 'today':
        return "Ventes d'aujourd'hui";
      case '7j':
        return 'Ventes (7 derniers jours)';
      case '30j':
        return 'Ventes du mois en cours';
      case 'custom':
        if (_selectedDateRange != null) {
          return 'Ventes du ${_formatDate(_selectedDateRange!.start)} au ${_formatDate(_selectedDateRange!.end)}';
        }
        return 'Ventes (Période personnalisée)';
      default:
        return 'Ventes cumulées (Global)';
    }
  }

  Widget _buildCalculationRow(
    String label,
    String val, {
    bool isBold = false,
    Color? valueColor,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(color: AppColors.inkSoft, fontSize: 12.5),
        ),
        Text(
          val,
          style: TextStyle(
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            color: valueColor ?? AppColors.primaryDark,
            fontSize: 13,
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
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: isSelected ? AppColors.primaryDark : AppColors.inkSoft,
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
  }
}
