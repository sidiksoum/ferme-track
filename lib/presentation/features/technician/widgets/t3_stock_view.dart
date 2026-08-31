import 'package:flutter/material.dart';
import '../../../../config/theme/app_theme.dart';
import '../../../shared/widgets/common_widgets.dart';

class T3StockView extends StatelessWidget {
  const T3StockView({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'MÉDICAMENTS & STOCKS — NIVEAU GESTIONNAIRE',
            style: AppTypography.labelSmall,
          ),
          const SizedBox(height: 16),
          _buildStockItem('Aliment ponte', 12, 'sacs', 'Bas', 0.35, AppColors.accent),
          _buildStockItem('Aliment démarrage', 3, 'sacs', 'Critique', 0.08, AppColors.danger),
          _buildStockItem('Vaccin Newcastle', 85, 'doses', 'OK', 0.85, AppColors.primary),
          _buildStockItem('Vitamines complexes', 40, 'flacons', 'OK', 0.65, AppColors.primary),
        ],
      ),
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
      padding: const EdgeInsets.only(bottom: 16),
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
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: progressColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(
                      color: progressColor == AppColors.primary ? AppColors.primaryDark : progressColor,
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
              style: const TextStyle(color: AppColors.inkSoft, fontSize: 12),
            ),
            const SizedBox(height: 8),
            Container(
              height: 7,
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
}
