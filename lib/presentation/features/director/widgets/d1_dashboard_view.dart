import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../config/theme/app_theme.dart';
import '../../../../core/services/system_notification_service.dart';
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
                'Synchronisation en temps réel active',
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
          Consumer<SystemNotificationService>(
            builder: (context, notifService, _) {
              final alerts = notifService.activeAlerts;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('ALERTES ACTIVES', style: AppTypography.labelSmall),
                      if (alerts.isNotEmpty)
                        Text(
                          '${alerts.length} alerte${alerts.length > 1 ? 's' : ''}',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: AppColors.danger,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 9),
                  if (alerts.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text(
                        'Aucune alerte critique pour le moment.',
                        style: TextStyle(fontSize: 12, color: AppColors.primaryDark),
                      ),
                    )
                  else
                    ...alerts.take(3).map((alert) {
                      AlertType type = AlertType.error;
                      if (alert.type == 'credit' || alert.type == 'late') {
                        type = AlertType.warning;
                      } else if (alert.type == 'task' || alert.type == 'reception') {
                        type = AlertType.info;
                      }
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: AlertRow(
                          title: alert.title,
                          subtitle: alert.message,
                          type: type,
                          onTap: () {
                            notifService.markAsRead(alert.id);
                            _showAlertDetail(context, alert.title, alert.message);
                          },
                        ),
                      );
                    }),
                ],
              );
            },
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
              Expanded(child: Text(title)),
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
