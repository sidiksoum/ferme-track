import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../config/theme/app_theme.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/services/socket_client_service.dart';
import '../../../../core/services/system_notification_service.dart';
import '../../../../data/datasources/remote/api_client.dart';
import '../../../shared/widgets/common_widgets.dart';

class T1AccueilView extends StatefulWidget {
  final VoidCallback onViewNotifications;

  const T1AccueilView({super.key, required this.onViewNotifications});

  @override
  State<T1AccueilView> createState() => _T1AccueilViewState();
}

class _T1AccueilViewState extends State<T1AccueilView> {
  final ApiClient _apiClient = getIt<ApiClient>();
  final SocketClientService _socketService = getIt<SocketClientService>();
  StreamSubscription? _socketSubscription;

  int _eggsToday = 0;
  int _deathsToday = 0;
  int _totalBirds = 0;
  int _activitiesRate = 0;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();

    _socketSubscription = _socketService.allEvents.listen((event) {
      final evt = event['event']?.toString() ?? '';
      if (evt.contains('task') ||
          evt.contains('activity') ||
          evt.contains('stock') ||
          evt.contains('anomaly') ||
          evt.contains('mortality') ||
          evt.contains('reception') ||
          evt.contains('egg')) {
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
    try {
      final response = await _apiClient.get(
        '/dashboard/technician',
        forceRefresh: forceRefresh,
        useCache: true,
      );
      if (!mounted || response is! Map) return;

      final summary = response['summary'] as Map? ?? {};
      final activities = response['activities'] as Map? ?? {};

      setState(() {
        if (summary['eggs_today'] != null) {
          _eggsToday = (summary['eggs_today'] as num).toInt();
        }
        if (summary['deaths_today'] != null) {
          _deathsToday = (summary['deaths_today'] as num).toInt();
        }
        if (summary['total_birds'] != null) {
          _totalBirds = (summary['total_birds'] as num).toInt();
        }
        if (summary['activities_rate'] != null) {
          _activitiesRate = (summary['activities_rate'] as num).toInt();
        } else if (activities['rate_percent'] != null) {
          _activitiesRate = (activities['rate_percent'] as num).toInt();
        }
      });
    } catch (_) {}
  }

  String _formatNumber(int val) {
    final str = val.toString();
    if (str.length <= 3) return str;
    final buffer = StringBuffer();
    int count = 0;
    for (int i = str.length - 1; i >= 0; i--) {
      buffer.write(str[i]);
      count++;
      if (count % 3 == 0 && i != 0) {
        buffer.write(' ');
      }
    }
    return buffer.toString().split('').reversed.join('');
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () => _loadDashboardData(forceRefresh: true),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
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
              children: [
                KpiCard(
                  icon: Icons.egg,
                  value: _formatNumber(_eggsToday),
                  label: 'Œufs récoltés — jour',
                ),
                KpiCard(
                  icon: Icons.warning_outlined,
                  value: _deathsToday.toString(),
                  label: 'Mortalité — jour',
                  iconBackgroundColor: AppColors.errorLight,
                  iconColor: AppColors.danger,
                ),
                KpiCard(
                  icon: Icons.pets,
                  value: _formatNumber(_totalBirds),
                  label: 'Volailles — toutes fermes',
                ),
                KpiCard(
                  icon: Icons.done_all,
                  value: '$_activitiesRate%',
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
                          color: AppColors.primaryLight.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text(
                          'Aucune alerte technique active.',
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
                              _showAlertDetails(context, alert.title, alert.message);
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
                onPressed: widget.onViewNotifications,
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
      ),
    );
  }

  void _showAlertDetails(BuildContext context, String title, String details) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.info_outline, color: AppColors.primaryDark),
            const SizedBox(width: 8),
            Expanded(child: Text(title)),
          ],
        ),
        content: Text(details, style: const TextStyle(fontSize: 13, height: 1.4)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }
}
