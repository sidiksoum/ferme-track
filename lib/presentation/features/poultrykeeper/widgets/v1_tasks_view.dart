import 'package:flutter/material.dart';
import '../../../../config/theme/app_theme.dart';
import '../../../shared/widgets/common_widgets.dart';

class V1TasksView extends StatelessWidget {
  final Function(Map<String, dynamic>) onSelectTask;

  const V1TasksView({
    super.key,
    required this.onSelectTask,
  });

  @override
  Widget build(BuildContext context) {
    final tasks = [
      {
        'title': 'Distribuer l\'aliment',
        'meta': '06:30 · Priorité haute',
        'status': TaskStatus.todo,
        'icon': Icons.restaurant,
      },
      {
        'title': 'Ramasser les œufs',
        'meta': '07:00 · Matin',
        'status': TaskStatus.todo,
        'icon': Icons.egg,
      },
      {
        'title': 'Nettoyage abreuvoirs',
        'meta': '08:30 · Quotidien',
        'status': TaskStatus.todo,
        'icon': Icons.cleaning_services,
      },
      {
        'title': 'Contrôle température',
        'meta': '05:45 · Étable',
        'status': TaskStatus.done,
        'icon': Icons.check_circle,
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Offline Sync Status indicator
        Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 14),
          color: AppColors.primaryLight.withOpacity(0.4),
          child: Row(
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: AppColors.accent,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              const Text(
                'Hors ligne · 1 tâche en attente',
                style: TextStyle(fontSize: 10.5, color: AppColors.primaryDark, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),

        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(14),
            itemCount: tasks.length,
            itemBuilder: (context, index) {
              final task = tasks[index];
              return TaskCard(
                icon: task['icon'] as IconData,
                title: task['title'] as String,
                meta: task['meta'] as String,
                status: task['status'] as TaskStatus,
                onTap: task['status'] == TaskStatus.todo
                    ? () => onSelectTask(task)
                    : null,
              );
            },
          ),
        ),
      ],
    );
  }
}
