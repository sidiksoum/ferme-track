import 'package:flutter/material.dart';
import '../../../../config/theme/app_theme.dart';
import '../../../shared/widgets/common_widgets.dart';

class D1DashboardView extends StatelessWidget {
  final VoidCallback onViewNotifications;

  const D1DashboardView({super.key, required this.onViewNotifications});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Sync status
          Row(
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: AppColors.syncGreen,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              const Text(
                'Synchronisé à 9:38',
                style: TextStyle(fontSize: 10.5, color: AppColors.inkSoft),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // KPI Grid
          const Text('INDICATEURS DU JOUR', style: AppTypography.labelSmall),
          const SizedBox(height: 9),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 9,
            crossAxisSpacing: 9,
            childAspectRatio: 1.05,
            children: const [
              KpiCard(
                icon: Icons.egg,
                value: '9 850',
                label: 'Œufs récoltés — jour',
              ),
              KpiCard(
                icon: Icons.warning_outlined,
                value: '20',
                label: 'Mortalité — jour',
                iconBackgroundColor: AppColors.errorLight,
                iconColor: AppColors.danger,
              ),
              KpiCard(
                icon: Icons.pets,
                value: '12 400',
                label: 'Volailles — toutes fermes',
              ),
              KpiCard(
                icon: Icons.done_all,
                value: '78%',
                label: 'Activités réalisées — jour',
                iconBackgroundColor: AppColors.primaryLight,
                iconColor: AppColors.primaryDark,
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Active Alerts
          const Text('ALERTES ACTIVES', style: AppTypography.labelSmall),
          const SizedBox(height: 9),
          AlertRow(
            title: 'Rupture de stock',
            subtitle: 'Aliment démarrage sous le seuil',
            type: AlertType.error,
            onTap: () => _showAlertDetail(
              context,
              'Rupture de stock',
              'L\'aliment démarrage a franchi son seuil critique.\nIl ne reste plus que 3 sacs disponibles en magasin.\n\nAction : Une commande urgente auprès d\'Avicola SARL doit être passée.',
            ),
          ),
          const SizedBox(height: 8),
          AlertRow(
            title: 'Échéance',
            subtitle: 'Seydou Yao — 65 000 FCFA, en retard',
            type: AlertType.warning,
            onTap: () => _showAlertDetail(
              context,
              'Échéance de paiement',
              'Le client Seydou Yao (Grossiste) a un solde débiteur de 65 000 FCFA.\nL\'échéance fixée était le 12/08/2026.\n\nStatut actuel : En retard de paiement.',
            ),
          ),
          const SizedBox(height: 14),

          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: onViewNotifications,
              icon: const Icon(
                Icons.arrow_forward,
                size: 14,
                color: AppColors.primary,
              ),
              label: const Text(
                'Voir toutes les notifications →',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAlertDetail(BuildContext context, String title, String details) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.info_outline, color: AppColors.primaryDark),
              const SizedBox(width: 8),
              Text(title),
            ],
          ),
          content: Text(
            details,
            style: const TextStyle(fontSize: 13, height: 1.4),
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
}
