import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../config/theme/app_theme.dart';
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
            onPressed: () async {
              await authNotifier.logout();
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
          BottomNavigationBarItem(
            icon: Icon(Icons.warning),
            label: 'Anomalie',
          ),
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
            _showCloseTaskDialog(context, task);
          },
        );
      case 1:
        return const V3V6AnomalyView();
      case 2:
        return _buildAnomaliesHistory();
      default:
        return V1TasksView(
          onSelectTask: (task) {
            _showCloseTaskDialog(context, task);
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
                        Text('Type : ${item['title']}', style: const TextStyle(fontWeight: FontWeight.bold)),
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
                    child: const Icon(Icons.warning, color: AppColors.danger, size: 16),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item['title'] as String,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                        ),
                        Text(
                          item['meta'] as String,
                          style: const TextStyle(color: AppColors.inkSoft, fontSize: 11.5),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    item['date'] as String,
                    style: const TextStyle(fontSize: 10, color: AppColors.inkSoft),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showCloseTaskDialog(BuildContext context, Map<String, dynamic> task) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        return AlertDialog(
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Clôturer la tâche', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
              onDone: () {
                Navigator.pop(dialogContext);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Tâche clôturée avec succès !')),
                );
              },
            ),
          ),
        );
      },
    );
  }
}
