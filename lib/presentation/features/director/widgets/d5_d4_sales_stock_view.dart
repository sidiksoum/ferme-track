import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../config/theme/app_theme.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/services/socket_client_service.dart';
import '../../../../data/datasources/remote/api_client.dart';
import '../../../shared/widgets/common_widgets.dart';

class D5D4SalesStockView extends StatefulWidget {
  const D5D4SalesStockView({super.key});

  @override
  State<D5D4SalesStockView> createState() => _D5D4SalesStockViewState();
}

class _D5D4SalesStockViewState extends State<D5D4SalesStockView> {
  final ApiClient _apiClient = getIt<ApiClient>();
  final SocketClientService _socketService = getIt<SocketClientService>();
  StreamSubscription? _socketSubscription;

  String _salesOrStockToggle = 'sales'; // sales, stock
  String _salesSubTab = 'history'; // history, debtors
  String _salesPeriodFilter = 'all'; // all, today, 7j, 30j, custom
  DateTimeRange? _selectedDateRange;
  String _clientSearchQuery = '';
  DateTime? _selectedFilterDate;
  bool _showGraphBreakdown = true;

  // Real Sales & Debtors lists
  List<Map<String, dynamic>> _salesHistory = [];
  List<Map<String, dynamic>> _debtors = [];
  bool _isLoadingSales = false;

  // Stock data
  String _stockSubTab = 'magasin'; // magasin, ferme
  List<Map<String, dynamic>> _farmStockItems = [];
  Map<String, int> _eggFormats = {
    'plusGros': 0,
    'gros': 0,
    'moyen': 0,
    'petit': 0,
  };
  bool _isLoadingStocks = false;

  @override
  void initState() {
    super.initState();
    _loadAllData();

    // Realtime Socket.IO synchronization
    _socketSubscription = _socketService.allEvents.listen((event) {
      final evt = event['event']?.toString() ?? '';
      if (evt.contains('sale') ||
          evt.contains('stock') ||
          evt.contains('refund') ||
          evt.contains('reception') ||
          evt.contains('egg') ||
          evt.contains('order')) {
        if (mounted) {
          _loadAllData(forceRefresh: true);
        }
      }
    });
  }

  @override
  void dispose() {
    _socketSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadAllData({bool forceRefresh = false}) async {
    await Future.wait([
      _loadSalesAndDebtors(forceRefresh: forceRefresh),
      _loadStocks(forceRefresh: forceRefresh),
    ]);
  }

  Future<void> _loadSalesAndDebtors({bool forceRefresh = false}) async {
    if (!mounted) return;
    setState(() => _isLoadingSales = true);
    try {
      final responses = await Future.wait([
        _apiClient.get(
          '/magasinier/sales',
          forceRefresh: forceRefresh,
          useCache: true,
        ),
        _apiClient.get(
          '/magasinier/clients/debtors',
          forceRefresh: forceRefresh,
          useCache: true,
        ),
      ]);

      if (mounted && responses[0] is List) {
        _salesHistory = (responses[0] as List).map<Map<String, dynamic>>((s) {
          DateTime date;
          try {
            date = DateTime.parse(s['date']?.toString() ?? '');
          } catch (_) {
            date = DateTime.now();
          }
          return {
            'id': s['id']?.toString() ?? 'V-${DateTime.now().millisecondsSinceEpoch}',
            'date': date,
            'client': s['client']?.toString() ?? s['customer_name']?.toString() ?? 'Client',
            'contact': s['contact']?.toString() ?? s['customer_phone']?.toString() ?? '—',
            'address': s['address']?.toString() ?? s['customer_address']?.toString() ?? '—',
            'details': s['details']?.toString() ?? 'Vente d\'œufs',
            'amount': (s['amount'] as num?)?.toInt() ?? (s['total_amount'] as num?)?.toInt() ?? 0,
            'paid': (s['paid'] as num?)?.toInt() ?? (s['amount_paid'] as num?)?.toInt() ?? 0,
            'due': (s['due'] as num?)?.toInt() ?? (s['remaining_balance'] as num?)?.toInt() ?? 0,
            'status': s['status']?.toString() ?? 'Payé',
            'format_petit': (s['format_petit'] as num?)?.toInt() ?? (s['qtyPetit'] as num?)?.toInt() ?? 0,
            'format_moyen': (s['format_moyen'] as num?)?.toInt() ?? (s['qtyMoyen'] as num?)?.toInt() ?? 0,
            'format_gros': (s['format_gros'] as num?)?.toInt() ?? (s['qtyGros'] as num?)?.toInt() ?? 0,
            'format_plus_gros': (s['format_plus_gros'] as num?)?.toInt() ?? (s['qtyPlusGros'] as num?)?.toInt() ?? 0,
            'quantity_plates': (s['quantity_plates'] as num?)?.toInt() ?? (s['quantity'] as num?)?.toInt() ?? 0,
            'items': s['items'] is List ? s['items'] : [],
          };
        }).toList();
      }

      if (mounted && responses[1] is List) {
        _debtors = (responses[1] as List).map<Map<String, dynamic>>((d) {
          return {
            'client_id': d['client_id']?.toString() ?? d['id']?.toString() ?? '',
            'name': d['name']?.toString() ?? 'Client',
            'due': (d['due'] as num?)?.toInt() ?? (d['balance'] as num?)?.toInt() ?? 0,
            'status': d['status']?.toString() ?? 'Échéance en cours',
            'isOverdue': d['isOverdue'] == true,
            'phone': d['phone']?.toString() ?? '—',
            'address': d['address']?.toString() ?? '—',
          };
        }).toList();
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _isLoadingSales = false);
    }
  }

  Future<void> _loadStocks({bool forceRefresh = false}) async {
    if (!mounted) return;
    setState(() => _isLoadingStocks = true);
    try {
      final responses = await Future.wait([
        _apiClient.get(
          '/stocks',
          queryParameters: {'category': 'farm'},
          forceRefresh: forceRefresh,
          useCache: true,
        ),
        _apiClient.get(
          '/magasinier/egg-stocks',
          forceRefresh: forceRefresh,
          useCache: true,
        ),
      ]);

      if (responses[0] is List) {
        _farmStockItems = (responses[0] as List).whereType<Map>().map((item) {
          final qty = (item['quantity'] as num?)?.toDouble() ?? 0.0;
          final threshold = (item['alertThreshold'] as num?)?.toDouble() ?? 10.0;
          final status = item['status']?.toString() ?? (qty <= 10.0 ? 'Critique' : (qty <= 25.0 ? 'Bas' : 'OK'));
          final percent = (item['percent'] as num?)?.toDouble() ?? (qty / (threshold * 3)).clamp(0.05, 1.0);
          return {
            'name': item['name']?.toString() ?? 'Article',
            'quantity': qty.toInt(),
            'unit': item['unit']?.toString() ?? 'unités',
            'status': status,
            'percent': percent,
          };
        }).toList();
      }

      if (responses[1] is Map<String, dynamic>) {
        final res = responses[1] as Map<String, dynamic>;
        _eggFormats = {
          'plusGros': (res['plusGros'] as num?)?.toInt() ?? 0,
          'gros': (res['gros'] as num?)?.toInt() ?? 0,
          'moyen': (res['moyen'] as num?)?.toInt() ?? 0,
          'petit': (res['petit'] as num?)?.toInt() ?? 0,
        };
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _isLoadingStocks = false);
    }
  }

  @override
  Widget build(BuildContext context) {
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
                    () => setState(() => _salesOrStockToggle = 'sales'),
                  ),
                ),
                Expanded(
                  child: _buildSubTabButton(
                    'Suivi des Stocks (D4)',
                    _salesOrStockToggle == 'stock',
                    () => setState(() => _salesOrStockToggle = 'stock'),
                  ),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: _salesOrStockToggle == 'sales'
              ? _buildD5Sales()
              : _buildD4Stock(),
        ),
      ],
    );
  }

  Widget _buildD5Sales() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final filteredSales = _salesHistory.where((sale) {
      final clientText = (sale['client'] ?? '').toString().toLowerCase();
      final idText = (sale['id'] ?? '').toString().toLowerCase();
      final detailsText = (sale['details'] ?? '').toString().toLowerCase();
      final q = _clientSearchQuery.trim().toLowerCase();
      final matchesSearch = q.isEmpty ||
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
            return (saleDate.isAfter(start) || saleDate.isAtSameMomentAs(start)) &&
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
        // Sub-tabs: Historique des Ventes vs Créances & Débiteurs
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFFEFEFE7),
              borderRadius: BorderRadius.circular(10),
            ),
            padding: const EdgeInsets.all(2),
            child: Row(
              children: [
                Expanded(
                  child: _buildSubTabButton(
                    'Historique des Ventes',
                    _salesSubTab == 'history',
                    () => setState(() => _salesSubTab = 'history'),
                  ),
                ),
                Expanded(
                  child: _buildSubTabButton(
                    'Créances & Débiteurs (${_debtors.length})',
                    _salesSubTab == 'debtors',
                    () => setState(() => _salesSubTab = 'debtors'),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),

        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadAllData,
            child: _salesSubTab == 'history'
                ? _buildSalesHistorySection(
                    filteredSales: filteredSales,
                    totalPeriodSales: totalPeriodSales,
                    totalPeriodCash: totalPeriodCash,
                    totalPeriodCredit: totalPeriodCredit,
                    totalReceivables: totalReceivables,
                  )
                : _buildDebtorsSection(
                    totalReceivables: totalReceivables,
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildSalesHistorySection({
    required List<Map<String, dynamic>> filteredSales,
    required int totalPeriodSales,
    required int totalPeriodCash,
    required int totalPeriodCredit,
    required int totalReceivables,
  }) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      children: [
        // Filter by Period Selector
        const Text('FILTRER PAR PÉRIODE', style: AppTypography.labelSmall),
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
        if (_salesPeriodFilter == 'custom' && _selectedDateRange != null) ...[
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
                style: const TextStyle(color: Colors.white70, fontSize: 10.5),
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
                    onTap: () => setState(() => _selectedFilterDate = null),
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
            if (sale['status'] == 'Crédit') statusColor = AppColors.danger;
            if (sale['status'] == 'Partiel') statusColor = AppColors.accent;

            return GestureDetector(
              onTap: () => _showSaleDetails(sale),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: AppColors.line)),
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
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildDebtorsSection({required int totalReceivables}) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.paper,
            border: Border.all(color: AppColors.line),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('TOTAL CRÉANCES DUES', style: AppTypography.labelSmall),
                  const SizedBox(height: 4),
                  Text(
                    '${_formatCurrency(totalReceivables)} FCFA',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.danger,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.errorLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${_debtors.length} client${_debtors.length > 1 ? 's' : ''}',
                  style: const TextStyle(
                    color: AppColors.danger,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        const Text('DÉTAIL DES CRÉANCES CLIENTS', style: AppTypography.labelSmall),
        const SizedBox(height: 8),

        if (_debtors.isEmpty)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 40),
            alignment: Alignment.center,
            child: const Text(
              'Aucun client avec un crédit en cours.',
              style: TextStyle(color: AppColors.inkSoft),
            ),
          )
        else
          ..._debtors.map((debtor) {
            final isOverdue = debtor['isOverdue'] == true;
            return GestureDetector(
              onTap: () => _showReceivableDetails(debtor),
              child: Container(
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
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: isOverdue
                            ? AppColors.errorLight
                            : AppColors.warningLight,
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        debtor['name'].toString().isNotEmpty
                            ? debtor['name'].toString().substring(0, 2).toUpperCase()
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
                            '${debtor['status']} · Tel: ${debtor['phone']}',
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
                    Text(
                      '${_formatCurrency(debtor['due'] as num)} FCFA',
                      style: TextStyle(
                        color: isOverdue ? AppColors.danger : AppColors.primaryDark,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        const SizedBox(height: 20),
      ],
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

      int sPetit = (sale['format_petit'] as num?)?.toInt() ?? (sale['qtyPetit'] as num?)?.toInt() ?? 0;
      int sMoyen = (sale['format_moyen'] as num?)?.toInt() ?? (sale['qtyMoyen'] as num?)?.toInt() ?? 0;
      int sGros = (sale['format_gros'] as num?)?.toInt() ?? (sale['qtyGros'] as num?)?.toInt() ?? 0;
      int sPlus = (sale['format_plus_gros'] as num?)?.toInt() ?? (sale['qtyPlusGros'] as num?)?.toInt() ?? 0;

      final items = sale['items'] is List ? (sale['items'] as List) : [];
      if (items.isNotEmpty) {
        sPetit = 0;
        sMoyen = 0;
        sGros = 0;
        sPlus = 0;
        for (final it in items) {
          final calibre = (it['calibre'] ?? it['name'] ?? '').toString().toLowerCase();
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
        final qTotal = (sale['quantity_plates'] as num?)?.toInt() ??
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

    final int totalPlatesAll = totalPetit + totalMoyen + totalGros + totalPlusGros;

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
                  Text('RÉPARTITION GRAPHIQUE', style: AppTypography.labelSmall),
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
                  _showGraphBreakdown ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                  size: 20,
                  color: AppColors.inkSoft,
                ),
                onPressed: () => setState(() => _showGraphBreakdown = !_showGraphBreakdown),
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

  Widget _buildFormatChip(
    String label,
    int plates,
    int totalAll,
    Color color,
  ) {
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

  void _showSaleDetails(Map<String, dynamic> sale) {
    showDialog(
      context: context,
      builder: (context) {
        Color statusColor = AppColors.primaryDark;
        if (sale['status'] == 'Crédit') statusColor = AppColors.danger;
        if (sale['status'] == 'Partiel') statusColor = AppColors.accent;

        final items = (sale['items'] is List) ? (sale['items'] as List) : [];
        final statusText = sale['status']?.toString() ?? 'Payé';
        final clientName = sale['client']?.toString() ?? sale['customer_name']?.toString() ?? 'Client';
        final contactStr = sale['contact']?.toString() ?? sale['customer_phone']?.toString() ?? '—';
        final addressStr = sale['address']?.toString() ?? sale['customer_address']?.toString() ?? '—';
        final dateStr = sale['date'] is DateTime
            ? _formatDate(sale['date'] as DateTime)
            : (sale['date']?.toString().split('T')[0] ?? '—');
        final amountVal = (sale['amount'] as num?)?.toDouble() ?? (sale['total_amount'] as num?)?.toDouble() ?? 0.0;
        final paidVal = (sale['paid'] as num?)?.toDouble() ?? (sale['amount_paid'] as num?)?.toDouble() ?? 0.0;
        final dueVal = (sale['due'] as num?)?.toDouble() ?? (sale['remaining_balance'] as num?)?.toDouble() ?? 0.0;

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
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.inkSoft),
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
                    final unitPrice = (item['unit_price'] as num?)?.toDouble() ??
                        (item['unitPrice'] as num?)?.toDouble() ??
                        0.0;
                    final total = (item['total'] as num?)?.toDouble() ??
                        (qty * unitPrice);
                    final name = item['name']?.toString() ??
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
                            '${_formatCurrency(total)} FCFA',
                            style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    );
                  }),
                const Divider(height: 20, color: AppColors.line),
                _buildModalRow('Montant Total :', '${_formatCurrency(amountVal)} FCFA', isBold: true),
                _buildModalRow('Montant Réglé :', '${_formatCurrency(paidVal)} FCFA', color: AppColors.primaryDark),
                _buildModalRow(
                  'Solde Restant Dû :',
                  '${_formatCurrency(dueVal)} FCFA',
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

  void _showReceivableDetails(Map<String, dynamic> receivable) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(receivable['name']?.toString() ?? 'Détail Créance'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildModalRow('Contact :', receivable['phone']?.toString() ?? '—'),
              _buildModalRow('Adresse :', receivable['address']?.toString() ?? '—'),
              const SizedBox(height: 8),
              _buildModalRow('Statut :', receivable['status']?.toString() ?? '—'),
              _buildModalRow(
                'Montant Restant Dû :',
                '${_formatCurrency((receivable['due'] as num?) ?? 0)} FCFA',
                isBold: true,
                color: AppColors.danger,
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

  Widget _buildModalRow(String label, String value, {bool isBold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppColors.inkSoft, fontSize: 12.5)),
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

  Widget _buildD4Stock() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'SUIVI DES STOCKS — VUE DIRECTEUR',
                style: AppTypography.labelSmall,
              ),
              const SizedBox(height: 10),
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFEFEFE7),
                  borderRadius: BorderRadius.circular(9),
                ),
                padding: const EdgeInsets.all(2),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildSubTabButton(
                        'Stocks Magasin',
                        _stockSubTab == 'magasin',
                        () => setState(() => _stockSubTab = 'magasin'),
                      ),
                    ),
                    Expanded(
                      child: _buildSubTabButton(
                        'Stocks Ferme',
                        _stockSubTab == 'ferme',
                        () => setState(() => _stockSubTab = 'ferme'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadAllData,
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              children: [
                if (_stockSubTab == 'magasin') ...[
                  _buildEggStockItem(
                    'Nombre de plus gros œufs',
                    '${_eggFormats['plusGros'] ?? 0}',
                    '${((_eggFormats['plusGros'] ?? 0) / 30).floor()} plaquettes',
                    AppColors.danger,
                  ),
                  _buildEggStockItem(
                    'Nombre de gros œufs',
                    '${_eggFormats['gros'] ?? 0}',
                    '${((_eggFormats['gros'] ?? 0) / 30).floor()} plaquettes',
                    AppColors.primary,
                  ),
                  _buildEggStockItem(
                    'Nombre d’œufs moyens',
                    '${_eggFormats['moyen'] ?? 0}',
                    '${((_eggFormats['moyen'] ?? 0) / 30).floor()} plaquettes',
                    AppColors.primaryDark,
                  ),
                  _buildEggStockItem(
                    'Nombre de petits œufs',
                    '${_eggFormats['petit'] ?? 0}',
                    '${((_eggFormats['petit'] ?? 0) / 30).floor()} plaquettes',
                    AppColors.accent,
                  ),
                ] else ...[
                  if (_farmStockItems.isEmpty && !_isLoadingStocks)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 30),
                        child: Text(
                          'Aucun article de stock ferme enregistré.',
                          style: TextStyle(color: AppColors.inkSoft),
                        ),
                      ),
                    )
                  else
                    ..._farmStockItems.map((item) {
                      final status = item['status']?.toString() ?? 'OK';
                      Color color = AppColors.primary;
                      if (status == 'Critique') color = AppColors.danger;
                      if (status == 'Bas') color = AppColors.accent;

                      return _buildStockItem(
                        item['name'],
                        item['quantity'],
                        item['unit'],
                        status,
                        (item['percent'] as num?)?.toDouble() ?? 0.5,
                        color,
                      );
                    }),
                ],
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStockItem(
    String name,
    int quantity,
    String unit,
    String status,
    double percent,
    Color progressColor,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.paper,
          border: Border.all(color: AppColors.line),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13.5,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: progressColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(
                      color: progressColor == AppColors.primary
                          ? AppColors.primaryDark
                          : progressColor,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              '$quantity $unit disponibles',
              style: const TextStyle(color: AppColors.inkSoft, fontSize: 11.5),
            ),
            const SizedBox(height: 8),
            Container(
              height: 6,
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
                    color: progressColor,
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEggStockItem(
    String label,
    String quantity,
    String trays,
    Color color,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
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
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.egg, color: color, size: 20),
          ),
          const SizedBox(width: 10),
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
                const SizedBox(height: 3),
                Text(
                  '$quantity œufs',
                  style: const TextStyle(
                    color: AppColors.inkSoft,
                    fontSize: 11.5,
                  ),
                ),
              ],
            ),
          ),
          Text(
            trays,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
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

  String _formatDate(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
  }
}
