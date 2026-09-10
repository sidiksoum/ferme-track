import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../config/theme/app_theme.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/interfaces/network_checker.dart';
import '../../../../core/services/offline_sync_service.dart';
import '../../../../data/datasources/remote/api_client.dart';
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
  int _selectedNavIndex = 0;
  bool _isShowingNotifications = false;

  // Mock list of reported anomalies for the 3rd tab
  final List<Map<String, dynamic>> _reportedAnomalies = [
    {
      'title': 'Mortalité signalée',
      'meta': 'Bâtiment C · 3 sujets · Cause: Chaleur',
      'date': 'Aujourd\'hui · 14:15',
    },
    {
      'title': 'Fuite d\'eau',
      'meta': 'Bâtiment B · Abreuvoir n°3',
      'date': 'Hier · 09:30',
    },
  ];

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
          IconButton(
            icon: const Icon(Icons.notifications, color: Colors.white),
            tooltip: 'Notifications',
            onPressed: () {
              setState(() {
                _isShowingNotifications = !_isShowingNotifications;
              });
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
                if (!success && authNotifier.error != null) {
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
    switch (_selectedNavIndex) {
      case 0:
        return V1TasksView(
          onSelectTask: (task) {
            if (task['status'] == TaskStatus.done ||
                task['status'] == TaskStatus.pendingValidation) {
              _showTaskDetails(context, task);
              return Future.value(false);
            }
            return _showCloseTaskDialog(context, task);
          },
        );
      case 1:
        return const V3V6AnomalyView();
      case 2:
        return _buildAnomaliesHistory();
      default:
        return V1TasksView(
          onSelectTask: (task) {
            if (task['status'] == TaskStatus.done ||
                task['status'] == TaskStatus.pendingValidation) {
              _showTaskDetails(context, task);
              return Future.value(false);
            }
            return _showCloseTaskDialog(context, task);
          },
        );
    }
  }

  Widget _buildAnomaliesHistory() {
    return ListView.builder(
      padding: const EdgeInsets.all(14),
      itemCount: _reportedAnomalies.length,
      itemBuilder: (context, index) {
        final item = _reportedAnomalies[index];
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
                    title: Text(item['title'] as String),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Type : ${item['title']}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text('Date : ${item['date']}'),
                        const SizedBox(height: 8),
                        Text('Détails : ${item['meta']}'),
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
                          item['title'] as String,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13.5,
                          ),
                        ),
                        Text(
                          item['meta'] as String,
                          style: const TextStyle(
                            color: AppColors.inkSoft,
                            fontSize: 11.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    item['date'] as String,
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppColors.inkSoft,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<bool> _showCloseTaskDialog(
    BuildContext context,
    Map<String, dynamic> task,
  ) async {
    return await showDialog<bool>(
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
                    onPressed: () => Navigator.pop(dialogContext),
                  ),
                ],
              ),
              content: Container(
                width: double.maxFinite,
                child: V2CloseTaskView(
                  selectedTask: task,
                  onCancel: () => Navigator.pop(dialogContext),
                  onDone: (payload) async {
                    final success = await _closeTask(task, payload);
                    if (success && dialogContext.mounted) {
                      Navigator.pop(dialogContext, true);
                    }
                  },
                ),
              ),
            );
          },
        ) ??
        false;
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
            lines.add('Quantité distribuée : ${decoded['feedQtyKg']} kg');
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
