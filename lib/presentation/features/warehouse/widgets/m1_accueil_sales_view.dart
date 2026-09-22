import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../config/theme/app_theme.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/services/socket_client_service.dart';
import '../../../../data/datasources/remote/api_client.dart';

class M1AccueilSalesView extends StatefulWidget {
  final String userName;

  const M1AccueilSalesView({super.key, required this.userName});

  @override
  State<M1AccueilSalesView> createState() => _M1AccueilSalesViewState();
}

class _M1AccueilSalesViewState extends State<M1AccueilSalesView> {
  final ApiClient _apiClient = getIt<ApiClient>();
  final SocketClientService _socketService = getIt<SocketClientService>();
  StreamSubscription? _socketSubscription;

  String _toggleMode = 'sales'; // sales, stock
  final String _periodFilter = 'today'; // today, 7j, 30j, custom

  Map<String, int> _eggFormats = {
    'plusGros': 0,
    'gros': 0,
    'moyen': 0,
    'petit': 0,
  };

  Map<String, dynamic> _caisseStats = {
    'today_sales': 45000,
    'total_sales': 245000,
    'cash_sales': 178000,
    'credit_sales': 67000,
    'total_receivables': 126500,
  };

  List<Map<String, dynamic>> _receivables = [
    {
      'client': 'Seydou Yao',
      'contact': '07 47 48 49 50',
      'address': 'Gare routière',
      'saleDetails': '40 plateaux Plus Gros format',
      'total': 100000,
      'paid': 35000,
      'due': 65000,
      'dueDate': '12/08/2026',
      'status': 'Échéance dépassée',
    },
    {
      'client': 'Adjoua Tanoh',
      'contact': '07 08 09 10 11',
      'address': 'Ferme Soro',
      'saleDetails': '20 plateaux Gros format',
      'total': 44000,
      'paid': 25500,
      'due': 18500,
      'dueDate': '28/08/2026',
      'status': 'Échéance à venir',
    },
    {
      'client': 'Koffi Mensah',
      'contact': '05 06 07 08 09',
      'address': 'Marché central',
      'saleDetails': '12 plateaux Moyen format',
      'total': 21600,
      'paid': 9600,
      'due': 12000,
      'dueDate': '15/09/2026',
      'status': 'Échéance à venir',
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadDashboardData();

    // Écoute temps réel Socket.IO pour rafraîchissement instantané
    _socketSubscription = _socketService.allEvents.listen((event) {
      final eventName = event['event']?.toString() ?? '';
      if (eventName.contains('sale') ||
          eventName.contains('stock') ||
          eventName.contains('reception') ||
          eventName.contains('egg') ||
          eventName.contains('order')) {
        if (mounted) {
          _loadDashboardData(forceRefresh: true);
        }
      }
    });
  }

  @override
  void dispose() {
    _socketSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadDashboardData({bool forceRefresh = false}) async {
    await Future.wait([
      _loadEggStocks(forceRefresh: forceRefresh),
      _loadCaisseStats(forceRefresh: forceRefresh),
      _loadReceivables(forceRefresh: forceRefresh),
    ]);
  }

  Future<void> _loadEggStocks({bool forceRefresh = false}) async {
    if (!mounted) return;
    try {
      final response = await _apiClient.get(
        '/magasinier/egg-stocks',
        forceRefresh: forceRefresh,
        useCache: true,
      );
      if (mounted && response is Map<String, dynamic>) {
        setState(() {
          _eggFormats = {
            'plusGros': (response['plusGros'] as num?)?.toInt() ?? 0,
            'gros': (response['gros'] as num?)?.toInt() ?? 0,
            'moyen': (response['moyen'] as num?)?.toInt() ?? 0,
            'petit': (response['petit'] as num?)?.toInt() ?? 0,
          };
        });
        return;
      }
    } catch (_) {}

    try {
      final response = await _apiClient.get(
        '/magasinier/egg-exits',
        forceRefresh: forceRefresh,
        useCache: true,
      );
      if (!mounted || response is! List) return;

      int plusGros = 0, gros = 0, moyen = 0, petit = 0;
      for (final item in response.whereType<Map>()) {
        if (item['status'] == 'validated') {
          plusGros += (item['plusGros'] as num?)?.toInt() ?? 0;
          gros += (item['gros'] as num?)?.toInt() ?? 0;
          moyen += (item['moyen'] as num?)?.toInt() ?? 0;
          petit += (item['petit'] as num?)?.toInt() ?? 0;
        }
      }

      setState(() {
        _eggFormats = {
          'plusGros': plusGros,
          'gros': gros,
          'moyen': moyen,
          'petit': petit,
        };
      });
    } catch (_) {}
  }

  Future<void> _loadCaisseStats({bool forceRefresh = false}) async {
    if (!mounted) return;
    try {
      final response = await _apiClient.get(
        '/magasinier/caisse',
        forceRefresh: forceRefresh,
        useCache: true,
      );
      if (mounted && response is Map<String, dynamic>) {
        setState(() {
          _caisseStats = response;
        });
      }
    } catch (_) {}
  }

  Future<void> _loadReceivables({bool forceRefresh = false}) async {
    if (!mounted) return;
    try {
      final response = await _apiClient.get(
        '/magasinier/clients/debtors',
        forceRefresh: forceRefresh,
        useCache: true,
      );
      if (mounted && response is List && response.isNotEmpty) {
        setState(() {
          _receivables = response.map<Map<String, dynamic>>((r) {
            final due =
                (r['due'] as num?)?.toInt() ??
                (r['balance'] as num?)?.toInt() ??
                0;
            final isOverdue =
                r['isOverdue'] == true ||
                (r['status']?.toString().contains('dépassée') ?? false);
            return {
              'client': r['name']?.toString() ?? 'Client',
              'contact': r['phone']?.toString() ?? '—',
              'address': r['address']?.toString() ?? '—',
              'saleDetails': 'Solde débiteur restant',
              'total': due,
              'paid': 0,
              'due': due,
              'dueDate': r['dueDate']?.toString() ?? '15/09/2026',
              'status': isOverdue ? 'Échéance dépassée' : 'Échéance à venir',
            };
          }).toList();
        });
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Actor Welcome Sub-header
        Container(
          width: double.infinity,
          color: AppColors.primaryLight.withOpacity(0.3),
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 14),
          child: Text(
            'Bonjour, ${widget.userName}  ·  Ferme Soro  ·  8 bâtiments actifs',
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryDark,
            ),
          ),
        ),

        // Sub tabs
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
                    'Ventes & Créances',
                    _toggleMode == 'sales',
                    () {
                      setState(() => _toggleMode = 'sales');
                      _loadDashboardData(forceRefresh: true);
                    },
                  ),
                ),
                Expanded(
                  child: _buildSubTabButton(
                    'Suivi des Stocks',
                    _toggleMode == 'stock',
                    () {
                      setState(() => _toggleMode = 'stock');
                      _loadEggStocks(forceRefresh: true);
                    },
                  ),
                ),
              ],
            ),
          ),
        ),

        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadDashboardData,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: _toggleMode == 'sales'
                  ? _buildSalesSummary()
                  : _buildStockSummary(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSalesSummary() {
    final todaySales = _caisseStats['today_sales'] ?? 45000;
    final totalSales = _caisseStats['total_sales'] ?? 245000;
    final cashSales = _caisseStats['cash_sales'] ?? 178000;
    final creditSales = _caisseStats['credit_sales'] ?? 67000;
    final totalReceivables = _caisseStats['total_receivables'] ?? 126500;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'VENTES — PÉRIODE SÉLECTIONNÉE',
          style: AppTypography.labelSmall,
        ),
        const SizedBox(height: 12),
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
                _periodFilter == 'today'
                    ? 'Ventes d’aujourd’hui'
                    : 'Ventes cumulées',
                style: const TextStyle(color: Colors.white70, fontSize: 11),
              ),
              const SizedBox(height: 2),
              Text(
                _periodFilter == 'today'
                    ? '$todaySales FCFA'
                    : '$totalSales FCFA',
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
                  _buildSummaryItem('Comptant', '$cashSales FCFA'),
                  _buildSummaryItem('Crédit', '$creditSales FCFA'),
                  _buildSummaryItem('Créances tot.', '$totalReceivables FCFA'),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'PLUS GROSSES CRÉANCES',
              style: AppTypography.labelSmall,
            ),
            Text(
              '${_receivables.length} clients',
              style: const TextStyle(fontSize: 11, color: AppColors.inkSoft),
            ),
          ],
        ),
        const SizedBox(height: 9),
        ..._receivables.map(_buildReceivableCard),
      ],
    );
  }

  Widget _buildReceivableCard(Map<String, dynamic> receivable) {
    final isOverdue = receivable['status'] == 'Échéance dépassée';
    final statusColor = isOverdue ? AppColors.danger : AppColors.accent;
    return GestureDetector(
      onTap: () => _showReceivableDetails(receivable),
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 10),
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
                color: isOverdue
                    ? AppColors.errorLight
                    : AppColors.warningLight,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.account_balance_wallet_outlined,
                color: statusColor,
                size: 19,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    receivable['client'],
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13.5,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    receivable['saleDetails'],
                    style: const TextStyle(
                      color: AppColors.inkSoft,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Échéance : ${receivable['dueDate']}',
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 10.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              '${receivable['due']} FCFA',
              style: TextStyle(
                color: statusColor,
                fontWeight: FontWeight.bold,
                fontSize: 12.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showReceivableDetails(Map<String, dynamic> receivable) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(receivable['client']),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Contact : ${receivable['contact']}'),
              Text('Adresse : ${receivable['address']}'),
              const SizedBox(height: 10),
              Text('Vente : ${receivable['saleDetails']}'),
              Text('Montant total : ${receivable['total']} FCFA'),
              Text('Montant payé : ${receivable['paid']} FCFA'),
              Text('Reste à payer : ${receivable['due']} FCFA'),
              Text('Date d’échéance : ${receivable['dueDate']}'),
              Text('Statut : ${receivable['status']}'),
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

  Widget _buildStockSummary() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'STOCK MAGASIN — ŒUFS PAR FORMAT',
          style: AppTypography.labelSmall,
        ),
        const SizedBox(height: 12),
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
      ],
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
}
