import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../config/theme/app_theme.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/interfaces/network_checker.dart';
import '../../../../core/services/offline_sync_service.dart';
import '../../../../core/services/socket_client_service.dart';
import '../../../../data/datasources/remote/api_client.dart';
import '../../../../core/services/system_notification_service.dart';
import '../../../shared/widgets/common_widgets.dart';
import '../../../providers/auth_provider.dart';
import '../widgets/v1_tasks_view.dart';
import '../widgets/v2_close_task_view.dart';
import '../widgets/v3_v6_anomaly_view.dart';
import '../widgets/v6_notifications_view.dart';

/// Poultry Keeper main screen combining tasks and declarations (V1 - V6)
class PoltrykeeperTasksScreen extends StatefulWidget {
  const PoltrykeeperTasksScreen({super.key});

  @override
  State<PoltrykeeperTasksScreen> createState() =>
      _PoltrykeeperTasksScreenState();
}

class _PoltrykeeperTasksScreenState extends State<PoltrykeeperTasksScreen> {
  final ApiClient _apiClient = getIt<ApiClient>();
  final SocketClientService _socketService = getIt<SocketClientService>();
  StreamSubscription? _socketSubscription;

  int _selectedNavIndex = 0;
  bool _isShowingNotifications = false;
  bool _isLoadingAnomalies = false;

  // Real list of reported anomalies from backend
  List<Map<String, dynamic>> _reportedAnomalies = [];

  @override
  void initState() {
    super.initState();
    _loadAnomaliesHistory();

    _socketSubscription = _socketService.allEvents.listen((event) {
      final evt = event['event']?.toString() ?? '';
      if (evt.contains('anomal') || evt.contains('mortality') || evt.contains('task')) {
        if (mounted) {
          _loadAnomaliesHistory(forceRefresh: true);
        }
      }
    });
  }

  @override
  void dispose() {
    _socketSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadAnomaliesHistory({bool forceRefresh = false}) async {
    if (!mounted) return;
    if (_reportedAnomalies.isEmpty) {
      setState(() => _isLoadingAnomalies = true);
    }
    try {
      final response = await _apiClient.get(
        '/volailler/anomalies/my-history',
        forceRefresh: forceRefresh,
        useCache: true,
      );
      if (!mounted || response is! List) return;
      setState(() {
        _reportedAnomalies = response
            .whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .toList();
      });
    } catch (_) {
    } finally {
      if (mounted) setState(() => _isLoadingAnomalies = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authNotifier = context.watch<AuthNotifier>();
    final userName = authNotifier.currentUser?.fullName ?? 'Ama Koffi';

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAF7),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_getAppBarTitle()),
            Text(
              _getAppBarSubtitle(userName),
              style: AppTypography.appbarSubtitle,
            ),
          ],
        ),
        actions: [
          Consumer<SystemNotificationService>(
            builder: (context, notifService, _) {
              final unread = notifService.unreadCount;
              return GestureDetector(
                onTap: () => setState(() {
                  _isShowingNotifications = !_isShowingNotifications;
                }),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      const Icon(
                        Icons.notifications_none,
                        size: 22,
                        color: Colors.white,
                      ),
                      if (!_isShowingNotifications && unread > 0)
                        Positioned(
                          top: 10,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: const BoxDecoration(
                              color: AppColors.accent,
                              shape: BoxShape.circle,
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 12,
                              minHeight: 12,
                            ),
                            child: Text(
                              unread > 99 ? '99+' : '$unread',
                              style: const TextStyle(
                                color: AppColors.primaryDark,
                                fontSize: 8,
                                fontWeight: FontWeight.w900,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            tooltip: 'Se déconnecter',
            onPressed: () {
              showLogoutConfirmationDialog(context, () async {
                if (!mounted) return;
                showActionLoadingDialog(
                  context,
                  message: 'Déconnexion en cours...',
                );
                final success = await authNotifier.logout();
                if (!mounted) return;
                Navigator.of(context, rootNavigator: true).pop();
                if (success) {
                  Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
                } else if (authNotifier.error != null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        authNotifier.error ?? 'Déconnexion impossible.',
                      ),
                    ),
                  );
                }
              });
            },
          ),
        ],
      ),
      body: _buildBody(userName),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedNavIndex,
        onTap: (index) {
          setState(() {
            _selectedNavIndex = index;
            _isShowingNotifications = false;
          });
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.primaryDark,
        unselectedItemColor: const Color(0xFF9AA79C),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.assignment),
            label: 'Tâches',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.warning), label: 'Anomalie'),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: 'Historique',
          ),
        ],
      ),
    );
  }

  String _getAppBarTitle() {
    if (_isShowingNotifications) {
      return 'Mes Notifications';
    }
    switch (_selectedNavIndex) {
      case 0:
        return 'Mes tâches';
      case 1:
        return 'Signaler une anomalie';
      case 2:
        return 'Historique des anomalies';
      default:
        return 'Espace Volailler';
    }
  }

  String _getAppBarSubtitle(String userName) {
    if (_isShowingNotifications) {
      return 'Alertes & Tâches en retard';
    }
    switch (_selectedNavIndex) {
      case 0:
        return '$userName · Aujourd\'hui';
      case 1:
        return 'Déclarations d\'urgence & Santé';
      case 2:
        return 'Déclarations enregistrées';
      default:
        return userName;
    }
  }

  Widget _buildBody(String userName) {
    if (_isShowingNotifications) {
      return const V6NotificationsView();
    }
    return IndexedStack(
      index: _selectedNavIndex,
      children: [
        V1TasksView(
          onSelectTask: (task) async {
            if (task['status'] == TaskStatus.done ||
                task['status'] == TaskStatus.pendingValidation) {
              _showTaskDetails(context, task);
              return false;
            }
            return await _showCloseTaskDialog(context, task);
          },
        ),
        const V3V6AnomalyView(),
        _buildAnomaliesHistory(),
      ],
    );
  }

  String _formatAnomalyDate(dynamic value) {
    if (value == null) return '';
    DateTime? dt;
    if (value is DateTime) {
      dt = value;
    } else if (value is String) {
      dt = DateTime.tryParse(value);
    }
    if (dt == null) return value.toString();
    final localDt = dt.toLocal();
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final targetStart = DateTime(localDt.year, localDt.month, localDt.day);
    final diffDays = todayStart.difference(targetStart).inDays;

    final timeStr = '${localDt.hour.toString().padLeft(2, '0')}:${localDt.minute.toString().padLeft(2, '0')}';
    if (diffDays == 0) {
      return 'Aujourd\'hui à $timeStr';
    } else if (diffDays == 1) {
      return 'Hier à $timeStr';
    }
    final months = [
      'janv.', 'févr.', 'mars', 'avr.', 'mai', 'juin',
      'juil.', 'août', 'sept.', 'oct.', 'nov.', 'déc.'
    ];
    final monthStr = months[localDt.month - 1];
    return '${localDt.day} $monthStr ${localDt.year} à $timeStr';
  }

  Widget _buildAnomaliesHistory() {
    return RefreshIndicator(
      onRefresh: () => _loadAnomaliesHistory(forceRefresh: true),
      child: _isLoadingAnomalies && _reportedAnomalies.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : _reportedAnomalies.isEmpty
              ? ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(32),
                  children: const [
                    Center(
                      child: Text(
                        'Aucune anomalie déclarée pour le moment.',
                        style: TextStyle(color: AppColors.inkSoft),
                      ),
                    ),
                  ],
                )
              : ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(14),
                  itemCount: _reportedAnomalies.length,
                  itemBuilder: (context, index) {
                    final item = _reportedAnomalies[index];
                    final dateFormatted = _formatAnomalyDate(item['date'] ?? item['created_at']);
                    final building = item['buildingName'] ?? item['building'] ?? 'Bâtiment';
                    final cause = item['cause'] != null && item['cause'].toString().isNotEmpty
                        ? ' · ${item['cause']}'
                        : '';
                    final details = item['meta']?.toString() ?? '$building$cause';

                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(
                        color: AppColors.paper,
                        border: Border.all(color: AppColors.line),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: InkWell(
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (dialogContext) {
                              return AlertDialog(
                                title: Text(item['title'] as String? ?? 'Anomalie'),
                                content: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Type : ${item['title']}',
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(height: 8),
                                    Text('Date : $dateFormatted'),
                                    const SizedBox(height: 8),
                                    Text('Détails : $details'),
                                    if (item['description'] != null &&
                                        item['description'].toString().trim().isNotEmpty) ...[
                                      const SizedBox(height: 8),
                                      Text('Notes : ${item['description']}'),
                                    ] else if (item['comment'] != null &&
                                        item['comment'].toString().trim().isNotEmpty) ...[
                                      const SizedBox(height: 8),
                                      Text('Notes : ${item['comment']}'),
                                    ],
                                  ],
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(dialogContext),
                                    child: const Text('Fermer'),
                                  ),
                                ],
                              );
                            },
                          );
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              Container(
                                width: 34,
                                height: 34,
                                decoration: const BoxDecoration(
                                  color: AppColors.errorLight,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.warning,
                                  color: AppColors.danger,
                                  size: 16,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item['title'] as String? ?? 'Anomalie',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13.5,
                                      ),
                                    ),
                                    Text(
                                      details,
                                      style: const TextStyle(
                                        color: AppColors.inkSoft,
                                        fontSize: 11.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                dateFormatted,
                                style: const TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.inkSoft,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
    );
  }

  Future<bool> _showCloseTaskDialog(
    BuildContext context,
    Map<String, dynamic> task,
  ) async {
    final result = await showDialog<bool>(
          context: context,
          barrierDismissible: true,
          builder: (dialogContext) {
            return AlertDialog(
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Clôturer la tâche',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(dialogContext, false),
                  ),
                ],
              ),
              content: SizedBox(
                width: double.maxFinite,
                child: V2CloseTaskView(
                  selectedTask: task,
                  onCancel: () => Navigator.pop(dialogContext, false),
                  onDone: (payload) async {
                    final success = await _closeTask(task, payload);
                    if (dialogContext.mounted) {
                      Navigator.pop(dialogContext, success);
                    }
                  },
                ),
              ),
            );
          },
        );
    return result ?? false;
  }

  void _showTaskDetails(BuildContext context, Map<String, dynamic> task) {
    String formatDateTime(dynamic value) {
      final parsed = DateTime.tryParse(value?.toString() ?? '');
      if (parsed == null) return 'Non renseignée';
      return '${parsed.day.toString().padLeft(2, '0')}/${parsed.month.toString().padLeft(2, '0')}/${parsed.year} à ${parsed.hour.toString().padLeft(2, '0')}:${parsed.minute.toString().padLeft(2, '0')}';
    }

    String formatNotes(dynamic value) {
      if (value == null || value.toString().trim().isEmpty)
        return 'Aucune information';
      try {
        final decoded = jsonDecode(value.toString());
        if (decoded is Map) {
          final lines = <String>[];
          if (decoded['feedQtyKg'] != null)
            lines.add('Quantité d\'aliment distribué : ${decoded['feedQtyKg']} kg');
          if (decoded['dose'] != null)
            lines.add('Quantité dose utilisée : ${decoded['dose']}');
          if (decoded['weight'] != null)
            lines.add('Poids moyen constaté : ${decoded['weight']} kg');
          if (decoded['eggsProduced'] != null)
            lines.add('Œufs produits : ${decoded['eggsProduced']}');
          if (decoded['eggsBroken'] != null)
            lines.add('Œufs cassés : ${decoded['eggsBroken']}');
          if (decoded['eggsUnsellable'] != null)
            lines.add('Œufs non vendables : ${decoded['eggsUnsellable']}');
          if (decoded['eggsPlusGros'] != null)
            lines.add('Œufs plus gros : ${decoded['eggsPlusGros']}');
          if (decoded['eggsGros'] != null)
            lines.add('Œufs gros : ${decoded['eggsGros']}');
          if (decoded['eggsMoyen'] != null)
            lines.add('Œufs moyens : ${decoded['eggsMoyen']}');
          if (decoded['eggsPetit'] != null)
            lines.add('Œufs petits : ${decoded['eggsPetit']}');
          if (decoded['temperatureCelsius'] != null)
            lines.add(
              'Température constatée : ${decoded['temperatureCelsius']} °C',
            );
          if (decoded['notes'] != null &&
              decoded['notes'].toString().trim().isNotEmpty)
            lines.add('Observation : ${decoded['notes']}');
          if (decoded['confirmed'] == true)
            lines.add('Confirmation : tâche réalisée');
          return lines.join('\n');
        }
      } catch (_) {}
      return value.toString();
    }

    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(task['title'] as String),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Programmée le : ${formatDateTime(task['scheduledDate'])}'),
              Text(
                'Responsable : ${task['responsibleName'] ?? 'Non renseigné'}',
              ),
              Text('Bâtiment : ${task['buildingName'] ?? 'Non renseigné'}'),
              Text(
                'Heure de programmation : ${task['startTime'] ?? 'Non renseignée'}',
              ),
              Text(
                'Heure de fin prévue : ${task['endTime'] ?? 'Non renseignée'}',
              ),
              Text('Soumise le : ${formatDateTime(task['submittedAt'])}'),
              Text('Validée le : ${formatDateTime(task['completedAt'])}'),
              const SizedBox(height: 12),
              Text('Instructions : ${task['description'] ?? 'Aucun détail'}'),
              if (task['submittedNotes'] != null)
                Text('Compte rendu :\n${formatNotes(task['submittedNotes'])}'),
              if (task['validationNotes'] != null)
                Text(
                  'Validation technicien :\n${formatNotes(task['validationNotes'])}',
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  Future<bool> _closeTask(
    Map<String, dynamic> task,
    Map<String, dynamic> payload,
  ) async {
    final taskId = task['id']?.toString();
    if (taskId == null || taskId.isEmpty) return false;
    showActionLoadingDialog(
      context,
      message: 'Enregistrement de la clôture...',
    );
    try {
      final networkChecker = getIt<NetworkChecker>();
      final isOnline = await networkChecker.hasConnection;

      if (!isOnline) {
        // Enregistrer directement dans la file d'attente hors-ligne
        await getIt<OfflineSyncService>().enqueueOperation(
          endpoint: '/volailler/tasks/$taskId/close',
          method: 'PATCH',
          payload: payload,
          description: 'Clôture: ${task['title'] ?? 'Tâche'}',
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              backgroundColor: Colors.orange,
              content: Text(
                'Tâche enregistrée hors-ligne ! Elle sera synchronisée automatiquement.',
              ),
            ),
          );
        }
        return true;
      }

      // En ligne : appel API direct
      await getIt<ApiClient>().patch(
        '/volailler/tasks/$taskId/close',
        data: payload,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: AppColors.syncGreen,
            content: Text('Tâche clôturée avec succès !'),
          ),
        );
      }
      return true;
    } catch (error) {
      // Fallback si la requête échoue en cours de route
      try {
        await getIt<OfflineSyncService>().enqueueOperation(
          endpoint: '/volailler/tasks/$taskId/close',
          method: 'PATCH',
          payload: payload,
          description: 'Clôture: ${task['title'] ?? 'Tâche'}',
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              backgroundColor: Colors.orange,
              content: Text(
                'Connexion instable : tâche enregistrée localement pour synchronisation.',
              ),
            ),
          );
        }
        return true;
      } catch (_) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Clôture impossible : $error')));
        }
        return false;
      }
    } finally {
      if (mounted) Navigator.of(context, rootNavigator: true).pop();
    }
  }
}
