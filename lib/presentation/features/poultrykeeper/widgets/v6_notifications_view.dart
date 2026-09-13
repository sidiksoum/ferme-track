import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../config/theme/app_theme.dart';
import '../../../../core/services/system_notification_service.dart';
import '../../../shared/widgets/common_widgets.dart';

class V6NotificationsView extends StatelessWidget {
  const V6NotificationsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<SystemNotificationService>(
      builder: (context, notifService, _) {
        final notifications = notifService.notifications;
        final unreadCount = notifService.unreadCount;

        return ListView(
          padding: const EdgeInsets.all(14),
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'NOTIFICATIONS VOLAILLER ($unreadCount NON LUE${unreadCount > 1 ? 'S' : ''})',
                  style: AppTypography.labelSmall,
                ),
                if (unreadCount > 0)
                  GestureDetector(
                    onTap: () => notifService.markAllAsRead(),
                    child: const Text(
                      'Tout marquer comme lu',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            if (notifications.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Center(
                  child: Text(
                    'Aucune notification volailler pour le moment.',
                    style: TextStyle(color: AppColors.inkSoft),
                  ),
                ),
              )
            else
              ...notifications.map((notif) {
                AlertType alertType = AlertType.info;
                if (notif.type.contains('alert') || notif.type == 'anomaly') {
                  alertType = AlertType.error;
                } else if (notif.type == 'credit' || notif.type == 'late') {
                  alertType = AlertType.warning;
                }

                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: AlertRow(
                          title: notif.title,
                          subtitle: notif.message,
                          type: alertType,
                          onTap: () {
                            notifService.markAsRead(notif.id);
                            _showNotificationDetail(
                              context,
                              notif.title,
                              notif.message,
                              _formatTime(notif.timestamp),
                            );
                          },
                        ),
                      ),
                      if (!notif.isRead) ...[
                        const SizedBox(width: 8),
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppColors.accent,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 4),
                      ],
                    ],
                  ),
                );
              }),
          ],
        );
      },
    );
  }

  void _showNotificationDetail(
    BuildContext context,
    String title,
    String details,
    String time,
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
              const SizedBox(height: 4),
              Text(
                'Reçu à $time',
                style: const TextStyle(fontSize: 11, color: AppColors.inkSoft),
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

  String _formatTime(DateTime dt) {
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}
