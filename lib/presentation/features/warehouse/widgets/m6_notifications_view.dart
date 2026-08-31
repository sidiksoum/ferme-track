import 'package:flutter/material.dart';
import '../../../../config/theme/app_theme.dart';
import '../../../shared/widgets/common_widgets.dart';

class M6NotificationsView extends StatelessWidget {
  const M6NotificationsView({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        const Text(
          'NOTIFICATIONS MAGASIN (2 ACTIVES)',
          style: AppTypography.labelSmall,
        ),
        const SizedBox(height: 9),
        _buildNotificationRow(
          context,
          title: 'Nouvelle réception en attente',
          desc: 'Bât. A · Ama Koffi',
          type: AlertType.info,
          unread: true,
          details: 'Le volailler Ama Koffi a soumis une collecte de 1 664 œufs en provenance du Bâtiment A. Veuillez vérifier et valider la quantité en magasin.',
        ),
        _buildNotificationRow(
          context,
          title: 'Réception validée',
          desc: 'Bât. B · Yao B.',
          type: AlertType.info,
          unread: false,
          details: 'La réception de 980 œufs en provenance du Bâtiment B a été validée par Yao B. et répartie par formats.',
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
