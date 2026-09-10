import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../config/theme/app_theme.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/interfaces/network_checker.dart';
import '../../../../core/services/offline_sync_service.dart';
import '../../../../core/services/socket_client_service.dart';
import '../../../../data/datasources/remote/api_client.dart';
import '../../../shared/widgets/common_widgets.dart';

class V1TasksView extends StatefulWidget {
  final Future<bool> Function(Map<String, dynamic>) onSelectTask;

  const V1TasksView({super.key, required this.onSelectTask});

  @override
  State<V1TasksView> createState() => _V1TasksViewState();
}

class _V1TasksViewState extends State<V1TasksView> {
  final ApiClient _apiClient = getIt<ApiClient>();
  final NetworkChecker _networkChecker = getIt<NetworkChecker>();
  final SocketClientService _socketService = getIt<SocketClientService>();

  List<Map<String, dynamic>> _tasks = [];
  bool _isLoading = true;
  String? _error;
  String _activeTab = 'todo';
  bool _isOnline = true;
  StreamSubscription? _socketSubscription;
  StreamSubscription? _networkSubscription;

  @override
  void initState() {
    super.initState();
    _checkInitialNetwork();
    _loadTasks();

    // Écouter les événements temps réel Socket.IO
    _socketSubscription = _socketService.taskEvents.listen((event) {
      if (mounted) {
        _loadTasks(forceRefresh: true);
      }
    });

    // Écouter l'état du réseau
    _networkSubscription = _networkChecker.connectivityStream.listen((hasNet) {
      if (mounted) {
        setState(() => _isOnline = hasNet);
      }
    });
  }

  Future<void> _checkInitialNetwork() async {
    final net = await _networkChecker.hasConnection;
    if (mounted) {
      setState(() => _isOnline = net);
    }
  }

  @override
  void dispose() {
    _socketSubscription?.cancel();
    _networkSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadTasks({bool forceRefresh = false}) async {
    try {
      final response = await _apiClient.get(
        '/volailler/tasks',
        forceRefresh: forceRefresh,
        useCache: true,
      );
      if (!mounted || response is! List) return;
      setState(() {
        _tasks = response.whereType<Map>().map((rawItem) {
          final item = Map<String, dynamic>.from(rawItem);
          final status = item['status']?.toString();
          return {
            ...item,
            'title': item['title']?.toString() ?? 'Tâche',
            'meta': item['meta']?.toString() ?? '',
            'buildingName':
                item['buildingName']?.toString() ?? 'Bâtiment non renseigné',
            'responsibleName':
                item['responsibleName']?.toString() ??
                'Responsable non renseigné',
            'taskType': item['taskType']?.toString() ?? 'other',
            'description': item['description']?.toString(),
            'scheduledDate': item['scheduledDate']?.toString(),
            'startTime': item['startTime']?.toString(),
            'endTime': item['endTime']?.toString(),
            'submittedAt': item['submittedAt']?.toString(),
            'completedAt': item['completedAt']?.toString(),
            'submittedNotes': item['submittedNotes']?.toString(),
            'validationNotes': item['validationNotes']?.toString(),
            'status': status == 'done'
                ? TaskStatus.done
                : status == 'pending_validation'
                ? TaskStatus.pendingValidation
                : TaskStatus.inProgress,
            'icon': _iconFor(item['taskType']?.toString()),
          };
        }).toList();
        _error = null;
      });
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  IconData _iconFor(String? type) {
    switch (type) {
      case 'feeding':
        return Icons.restaurant;
      case 'egg_collection':
        return Icons.egg;
      case 'cleaning':
        return Icons.cleaning_services;
      case 'vaccination':
        return Icons.vaccines;
      case 'inspection':
        return Icons.thermostat;
      default:
        return Icons.assignment;
    }
  }

  @override
  Widget build(BuildContext context) {
    final syncService = context.watch<OfflineSyncService>();

    final visibleTasks = _tasks.where((task) {
      if (_activeTab == 'pending_validation') {
        return task['status'] == TaskStatus.pendingValidation;
      }
      if (_activeTab == 'done') return task['status'] == TaskStatus.done;
      return task['status'] == TaskStatus.todo ||
          task['status'] == TaskStatus.inProgress ||
          task['status'] == TaskStatus.partial ||
          task['status'] == TaskStatus.late;
    }).toList()
      ..sort(
        (a, b) => (b['scheduledDate']?.toString() ?? '').compareTo(
          a['scheduledDate']?.toString() ?? '',
        ),
      );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Offline Sync Status Banner & Badge
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 14),
          color: AppColors.primaryLight.withOpacity(0.3),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _isOnline ? 'Connecté · En direct' : 'Mode Hors-Ligne actif',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryDark,
                ),
              ),
              SyncStatusBadge(
                isOnline: _isOnline,
                isSyncing: syncService.isSyncing,
                pendingCount: syncService.pendingOperationsCount,
                onSyncTap: () {
                  syncService.syncPendingOperations();
                },
              ),
            ],
          ),
        ),

        // Sub Tabs
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
          child: Row(
            children: [
              _buildTab('À faire', 'todo'),
              _buildTab('À valider', 'pending_validation'),
              _buildTab('Faite', 'done'),
            ],
          ),
        ),

        // Tasks List with Pull-To-Refresh
        Expanded(
          child: RefreshIndicator(
            onRefresh: () => _loadTasks(forceRefresh: true),
            child: ListView.builder(
              padding: const EdgeInsets.all(14),
              itemCount: _isLoading || _error != null ? 1 : visibleTasks.length,
              itemBuilder: (context, index) {
                if (_isLoading) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }
                if (_error != null && _tasks.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.cloud_off, size: 44, color: AppColors.inkSoft),
                          const SizedBox(height: 12),
                          Text(
                            'Impossible de charger les tâches.\n$_error',
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: AppColors.inkSoft),
                          ),
                          const SizedBox(height: 12),
                          FilledButton.icon(
                            onPressed: () => _loadTasks(forceRefresh: true),
                            icon: const Icon(Icons.refresh),
                            label: const Text('Réessayer'),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                if (visibleTasks.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Text(
                        _activeTab == 'todo'
                            ? 'Aucune tâche à faire pour le moment.'
                            : _activeTab == 'pending_validation'
                                ? 'Aucune tâche en attente de validation.'
                                : 'Aucune tâche terminée.',
                        style: const TextStyle(color: AppColors.inkSoft),
                      ),
                    ),
                  );
                }

                final task = visibleTasks[index];
                return TaskCard(
                  icon: task['icon'] as IconData,
                  title: task['title'] as String,
                  meta:
                      '${task['buildingName']} · ${task['responsibleName']} · ${task['scheduledDate']?.toString().split('T').first ?? ''} · ${task['meta']} - ${task['endTime'] ?? ''}',
                  status: task['status'] as TaskStatus,
                  onTap: task['status'] != TaskStatus.done
                      ? () async {
                          final closed = await widget.onSelectTask(task);
                          if (closed && mounted) {
                            setState(
                              () => task['status'] = TaskStatus.pendingValidation,
                            );
                          }
                        }
                      : null,
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTab(String label, String value) {
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _activeTab = value),
        child: Container(
          margin: const EdgeInsets.only(right: 6),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: _activeTab == value
                ? AppColors.primaryDark
                : AppColors.paper,
            border: Border.all(color: AppColors.line),
            borderRadius: BorderRadius.circular(9),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _activeTab == value ? Colors.white : AppColors.inkSoft,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
