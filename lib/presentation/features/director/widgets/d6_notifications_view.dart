import 'package:flutter/material.dart';
import '../../../../config/theme/app_theme.dart';
import '../../../shared/widgets/common_widgets.dart';

class D6NotificationsView extends StatelessWidget {
  const D6NotificationsView({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        const Text(
          'ALERTES EN ATTENTE (3 NON LUES)',
          style: AppTypography.labelSmall,
        ),
        const SizedBox(height: 9),
        _buildNotificationRow(
          context,
          title: 'Mortalité anormale — Bât. C',
          desc: 'Taux 1,8 % sur 24h, seuil dépassé',
          type: AlertType.error,
          unread: true,
          details:
              'Le taux de mortalité sur les dernières 24h est de 1.8%, ce qui dépasse le seuil critique pour le Bâtiment C.\n\nRecommandation : inspecter le lot L-2026-013, isoler les sujets fébriles et désinfecter les abreuvoirs.',
        ),
        _buildNotificationRow(
          context,
          title: 'Rupture de stock',
          desc: 'Aliment démarrage sous le seuil',
          type: AlertType.error,
          unread: true,
          details:
              'Le stock d\'aliment démarrage est descendu sous le seuil critique de 5 sacs.\nQuantité actuelle : 3 sacs.\n\nAction : Une commande d\'approvisionnement urgente doit être planifiée.',
        ),
        _buildNotificationRow(
          context,
          title: 'Échéance de paiement',
          desc: 'Seydou Yao — 65 000 FCFA, en retard',
          type: AlertType.warning,
          unread: true,
          details:
              'Le client Seydou Yao (Grossiste) présente un retard de paiement de 65 000 FCFA pour sa commande du 12/08.\n\nAction : Relancer le client par téléphone ou suspendre les ventes à crédit.',
        ),
        _buildNotificationRow(
          context,
          title: 'Retard de livraison',
          desc: 'Commande AB-118 — fournisseur Avicola',
          type: AlertType.info,
          unread: false,
          details:
              'La livraison de la commande AB-118 (aliment ponte) par Avicola SARL prévue hier n\'a pas encore été validée en magasin.\n\nAction : Contacter le transporteur d\'Avicola.',
        ),
        _buildNotificationRow(
          context,
          title: 'Anomalie signalée — Yao B.',
          desc: 'Fuite d\'abreuvoir, Bâtiment B',
          type: AlertType.error,
          unread: false,
          details:
              'Le volailler Yao B. a rapporté une fuite d\'eau continue au niveau de l\'abreuvoir n°3 dans le Bâtiment B.\n\nAction : Dépêcher le technicien de maintenance.',
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

  void _showNotificationDetail(
    BuildContext context,
    String title,
    String details,
  ) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Row(
            children: [
              const Icon(
                Icons.notifications_active_outlined,
                color: AppColors.primaryDark,
              ),
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
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 12),
              Text(details, style: const TextStyle(fontSize: 13, height: 1.4)),
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
