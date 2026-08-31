import 'package:flutter/material.dart';
import '../../../../config/theme/app_theme.dart';
import '../../../shared/widgets/common_widgets.dart';

class D3ActivitiesView extends StatefulWidget {
  const D3ActivitiesView({super.key});

  @override
  State<D3ActivitiesView> createState() => _D3ActivitiesViewState();
}

class _D3ActivitiesViewState extends State<D3ActivitiesView> {
  String _activitiesBuildingFilter = 'all'; // all, A, B, C
  String _activitiesTab = 'done'; // planned, done

  @override
  Widget build(BuildContext context) {
    final activities = [
      {
        'title': 'Alimentation — Bât. A',
        'meta': '06:30 · Ama K.',
        'status': TaskStatus.done,
        'building': 'A',
      },
      {
        'title': 'Ramassage œufs — Bât. B',
        'meta': '07:15 · Yao B.',
        'status': TaskStatus.done,
        'building': 'B',
      },
      {
        'title': 'Nettoyage — Bât. C',
        'meta': '08:00 · Ama K.',
        'status': TaskStatus.partial,
        'building': 'C',
      },
      {
        'title': 'Vaccination — Bât. C',
        'meta': '08:00 · Yao B.',
        'status': TaskStatus.late,
        'building': 'C',
      },
    ];

    // Filter list
    final filtered = activities.where((act) {
      if (_activitiesBuildingFilter != 'all' &&
          act['building'] != _activitiesBuildingFilter) {
        return false;
      }
      if (_activitiesTab == 'planned') {
        return act['status'] == TaskStatus.todo ||
            act['status'] == TaskStatus.late ||
            act['status'] == TaskStatus.partial;
      } else {
        return act['status'] == TaskStatus.done;
      }
    }).toList();

    return Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Sub tabs
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFEFEFE7),
              borderRadius: BorderRadius.circular(11),
            ),
            padding: const EdgeInsets.all(3),
            child: Row(
              children: [
                Expanded(
                  child: _buildSubTabButton(
                    'À faire / En cours',
                    _activitiesTab == 'planned',
                    () => setState(() => _activitiesTab = 'planned'),
                  ),
                ),
                Expanded(
                  child: _buildSubTabButton(
                    'Réalisées',
                    _activitiesTab == 'done',
                    () => setState(() => _activitiesTab = 'done'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Filters row
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip(
                  'Tous',
                  _activitiesBuildingFilter == 'all',
                  () => setState(() => _activitiesBuildingFilter = 'all'),
                ),
                _buildFilterChip(
                  'Bât. A',
                  _activitiesBuildingFilter == 'A',
                  () => setState(() => _activitiesBuildingFilter = 'A'),
                ),
                _buildFilterChip(
                  'Bât. B',
                  _activitiesBuildingFilter == 'B',
                  () => setState(() => _activitiesBuildingFilter = 'B'),
                ),
                _buildFilterChip(
                  'Bât. C',
                  _activitiesBuildingFilter == 'C',
                  () => setState(() => _activitiesBuildingFilter = 'C'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // List
          Expanded(
            child: filtered.isEmpty
                ? const Center(
                    child: Text(
                      'Aucune activité pour ces filtres.',
                      style: TextStyle(color: AppColors.inkSoft),
                    ),
                  )
                : ListView.builder(
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final act = filtered[index];
                      IconData icon = Icons.task_alt;
                      if (act['title'].toString().contains('Alimentation')) {
                        icon = Icons.restaurant;
                      } else if (act['title'].toString().contains('Ramassage')) {
                        icon = Icons.egg;
                      } else if (act['title'].toString().contains('Vaccination')) {
                        icon = Icons.healing;
                      }

                      return TaskCard(
                        icon: icon,
                        title: act['title'] as String,
                        meta: act['meta'] as String,
                        status: act['status'] as TaskStatus,
                        onTap: () => _showActivityDetail(context, act),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubTabButton(String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.paper : Colors.transparent,
          borderRadius: BorderRadius.circular(9),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: isSelected ? AppColors.primaryDark : AppColors.inkSoft,
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 7),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryDark : AppColors.paper,
          border: Border.all(color: isSelected ? AppColors.primaryDark : AppColors.line),
          borderRadius: BorderRadius.circular(100),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 10.5,
            fontWeight: FontWeight.w500,
            color: isSelected ? Colors.white : AppColors.inkSoft,
          ),
        ),
      ),
    );
  }

  void _showActivityDetail(BuildContext context, Map<String, dynamic> act) {
    String statusLabel = 'À faire';
    if (act['status'] == TaskStatus.done) statusLabel = 'Fait';
    if (act['status'] == TaskStatus.partial) statusLabel = 'Partiel';
    if (act['status'] == TaskStatus.late) statusLabel = 'En retard';

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(act['title']),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Détails : ${act['notes'] ?? 'Aucun détail disponible.'}'),
              const SizedBox(height: 10),
              Text('Responsable : ${act['meta'].toString().split(' · ').last}'),
              const SizedBox(height: 4),
              Text('Planification : ${act['meta'].toString().split(' · ').first}'),
              const SizedBox(height: 4),
              Text('Bâtiment concerné : Bâtiment ${act['building']}'),
              const SizedBox(height: 4),
              Text('Statut : $statusLabel'),
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
