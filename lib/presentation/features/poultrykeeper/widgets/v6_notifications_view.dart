import 'package:flutter/material.dart';
import '../../../../config/theme/app_theme.dart';
import '../../../shared/widgets/common_widgets.dart';

class V6NotificationsView extends StatelessWidget {
  const V6NotificationsView({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        const Text(
          'NOTIFICATIONS VOLAILLER (2 ACTIVES)',
          style: AppTypography.labelSmall,
        ),
        const SizedBox(height: 9),
        _buildNotificationRow(
          context,
          title: 'Tâche en retard',
          desc: 'Vaccination Newcastle - Bât. C',
          type: AlertType.error,
          unread: true,
          details: 'La tâche "Vaccination Newcastle" planifiée à 08:00 pour le Bâtiment C est en retard de plus de 2 heures.',
        ),
        _buildNotificationRow(
          context,
          title: 'Nouvelle tâche',
          desc: 'Pesée hebdomadaire - Bât. B',
          type: AlertType.info,
          unread: true,
          details: 'Une nouvelle tâche "Pesée hebdomadaire" a été programmée par le Technicien pour aujourd\'hui à 16:00.',
        ),
      ],
    );
  }

  Widget _buildNotificationRow(
    BuildContext context, {
    required String title,
    required String desc,
    required AlertType type,
    required bool unread,
    required String details,
  }) {
    return Row(
      children: [
        Expanded(
          child: AlertRow(
            title: title,
            subtitle: desc,
            type: type,
            onTap: () => _showNotificationDetail(context, title, details),
          ),
        ),
        if (unread) ...[
          const SizedBox(width: 8),
          Container(
            width: 7,
            height: 7,
            decoration: const BoxDecoration(
              color: AppColors.accent,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 4),
        ],
      ],
    );
  }

  void _showNotificationDetail(BuildContext context, String title, String details) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.notifications_active_outlined, color: AppColors.primaryDark),
              const SizedBox(width: 8),
              const Text('Détails'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 12),
              Text(
                details,
                style: const TextStyle(fontSize: 13, height: 1.4),
              ),
            ],
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
