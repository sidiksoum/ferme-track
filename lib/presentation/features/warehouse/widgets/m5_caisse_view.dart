import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../config/theme/app_theme.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/services/socket_client_service.dart';
import '../../../../data/datasources/remote/api_client.dart';

class M5CaisseView extends StatefulWidget {
  const M5CaisseView({super.key});

  @override
  State<M5CaisseView> createState() => _M5CaisseViewState();
}

class _M5CaisseViewState extends State<M5CaisseView> {
  final ApiClient _apiClient = getIt<ApiClient>();
  final SocketClientService _socketService = getIt<SocketClientService>();
  StreamSubscription? _socketSubscription;

  Map<String, dynamic> _caisseStats = {
    'today_sales': 45000,
    'total_sales': 245000,
    'cash_sales': 178000,
    'credit_sales': 67000,
    'total_receivables': 126500,
  };

  @override
  void initState() {
    super.initState();
    _loadCaisseData();

    _socketSubscription = _socketService.allEvents.listen((event) {
      final evt = event['event']?.toString() ?? '';
      if (evt == 'sale:created' || evt == 'stock:updated' || evt.contains('refund')) {
        if (mounted) {
          _loadCaisseData(forceRefresh: true);
        }
      }
    });
  }

  @override
  void dispose() {
    _socketSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadCaisseData({bool forceRefresh = false}) async {
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

  @override
  Widget build(BuildContext context) {
    final int todaySales = (_caisseStats['today_sales'] as num?)?.toInt() ?? 0;
    final int cashSales = (_caisseStats['cash_sales'] as num?)?.toInt() ?? (_caisseStats['total_sales'] as num?)?.toInt() ?? 0;
    final int creditSales = (_caisseStats['credit_sales'] as num?)?.toInt() ?? 0;
    final int totalReceivables = (_caisseStats['total_receivables'] as num?)?.toInt() ?? 0;

    final movements = [
      {
        'label': 'Ventes du jour (Espèces/MOMo)',
        'type': 'in',
        'amount': todaySales,
        'time': 'Aujourd\'hui · En direct',
      },
      {
        'label': 'Total créances clients en cours',
        'type': 'credit',
        'amount': totalReceivables,
        'time': 'À recouvrer',
      },
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('SOLDE DE CAISSE GLOBAL', style: AppTypography.labelSmall),
          const SizedBox(height: 10),

          // Cash box header card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primaryDark,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Solde cumulé en caisse',
                  style: TextStyle(color: Colors.white70, fontSize: 11.5),
                ),
                const SizedBox(height: 2),
                Text(
                  '$cashSales FCFA',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 14),
                Container(height: 1, color: Colors.white24),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildCashSummaryItem('Ventes du jour', '+$todaySales FCFA'),
                    _buildCashSummaryItem('À crédit', '$creditSales FCFA'),
                    _buildCashSummaryItem('Créances totales', '$totalReceivables FCFA'),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Movements header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text('JOURNAL DE CAISSE DU JOUR', style: AppTypography.labelSmall),
              Text(
                'En direct',
                style: TextStyle(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Movements list
          ...movements.map((mov) {
            final bool isIn = mov['type'] == 'in';
            return Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: AppColors.line)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: isIn ? AppColors.successLight : AppColors.warningLight,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isIn ? Icons.arrow_downward : Icons.account_balance_wallet,
                      size: 14,
                      color: isIn ? AppColors.primaryDark : AppColors.warning,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          mov['label'] as String,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                        ),
                        Text(
                          mov['time'] as String,
                          style: const TextStyle(color: AppColors.inkSoft, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${isIn ? "+" : ""} ${mov['amount']} FCFA',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: isIn ? AppColors.primaryDark : AppColors.warning,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildCashSummaryItem(String title, String val) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(color: Colors.white70, fontSize: 10)),
        const SizedBox(height: 2),
        Text(
          val,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12.5,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
