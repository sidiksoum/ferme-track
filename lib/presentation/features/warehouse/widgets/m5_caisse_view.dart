import 'package:flutter/material.dart';
import '../../../../config/theme/app_theme.dart';
import '../../../shared/widgets/common_widgets.dart';

class M5CaisseView extends StatelessWidget {
  const M5CaisseView({super.key});

  @override
  Widget build(BuildContext context) {
    // Mock cash movements
    final movements = [
      {
        'label': 'Vente alvéoles Moyen',
        'type': 'in', // income
        'amount': 18000,
        'time': 'Aujourd\'hui · 14:20',
      },
      {
        'label': 'Remboursement Seydou Yao',
        'type': 'in',
        'amount': 20000,
        'time': 'Aujourd\'hui · 11:15',
      },
      {
        'label': 'Achat désinfectant Bâtiment C',
        'type': 'out', // expense
        'amount': 15000,
        'time': 'Aujourd\'hui · 09:30',
      },
      {
        'label': 'Vente Poulets vifs',
        'type': 'in',
        'amount': 82000,
        'time': 'Hier · 16:45',
      },
      {
        'label': 'Paiement transport d\'aliments',
        'type': 'out',
        'amount': 20000,
        'time': 'Hier · 10:00',
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
                  'Solde en caisse actuel',
                  style: TextStyle(color: Colors.white70, fontSize: 11.5),
                ),
                const SizedBox(height: 2),
                const Text(
                  '485 000 FCFA',
                  style: TextStyle(
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
                    _buildCashSummaryItem('Encaissements (MM/Esp)', '+120 000'),
                    _buildCashSummaryItem('Décaissements', '-35 000'),
                    _buildCashSummaryItem('Solde net jour', '+85 000'),
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
                'Voir tout',
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
                      color: isIn ? AppColors.successLight : AppColors.errorLight,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isIn ? Icons.arrow_downward : Icons.arrow_upward,
                      size: 14,
                      color: isIn ? AppColors.primaryDark : AppColors.danger,
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
                    '${isIn ? "+" : "–"} ${mov['amount']} FCFA',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: isIn ? AppColors.primaryDark : AppColors.danger,
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
            fontSize: 13.5,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
