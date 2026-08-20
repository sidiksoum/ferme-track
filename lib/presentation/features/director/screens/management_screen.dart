import 'package:flutter/material.dart';

import '../../../../config/theme/app_theme.dart';
import '../../../shared/widgets/common_widgets.dart';

class DirectorBuildingSummaryScreen extends StatefulWidget {
  const DirectorBuildingSummaryScreen({super.key});

  @override
  State<DirectorBuildingSummaryScreen> createState() => _DirectorBuildingSummaryScreenState();
}

class _DirectorBuildingSummaryScreenState extends State<DirectorBuildingSummaryScreen> {
  final List<Map<String, dynamic>> buildings = [
    {'name': 'Bâtiment A', 'birds': 3400, 'eggs': 2850, 'mortality': '0.3%', 'status': 'Stable'},
    {'name': 'Bâtiment B', 'birds': 2650, 'eggs': 2100, 'mortality': '0.5%', 'status': 'À surveiller'},
    {'name': 'Bâtiment C', 'birds': 2280, 'eggs': 1700, 'mortality': '0.7%', 'status': 'Alert'},
    {'name': 'Bâtiment D', 'birds': 4100, 'eggs': 3220, 'mortality': '0.4%', 'status': 'Stable'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAF7),
      appBar: AppBar(
        title: const Text('Bâtiments'),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(14),
        itemCount: buildings.length,
        itemBuilder: (context, index) {
          final building = buildings[index];
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.paper,
              border: Border.all(color: AppColors.line),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      building['name'],
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        color: AppColors.ink,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: building['status'] == 'Alert' ? AppColors.errorLight : AppColors.successLight,
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: Text(
                        building['status'],
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: building['status'] == 'Alert' ? AppColors.danger : AppColors.primaryDark,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(child: KpiCard(icon: Icons.pets, value: '${building['birds']}', label: 'Oiseaux')),
                    const SizedBox(width: 8),
                    Expanded(child: KpiCard(icon: Icons.egg, value: '${building['eggs']}', label: 'Œufs / jour')),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Mortalité : ${building['mortality']}',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.inkSoft,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class DirectorActivityTrackingScreen extends StatelessWidget {
  const DirectorActivityTrackingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final activities = [
      {'title': 'Distribution aliment', 'time': '06:30', 'status': TaskStatus.todo},
      {'title': 'Vaccination Lot L-2026-011', 'time': '09:00', 'status': TaskStatus.partial},
      {'title': 'Contrôle hygiène', 'time': '12:15', 'status': TaskStatus.done},
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAF7),
      appBar: AppBar(title: const Text('Suivi des activités')),
      body: Padding(
        padding: const EdgeInsets.all(14),
        child: ListView(
          children: activities.map((activity) {
            final status = activity['status'] as TaskStatus;
            return TaskCard(
              icon: status == TaskStatus.done ? Icons.check_circle : Icons.calendar_today,
              title: activity['title'] as String,
              meta: '${activity['time']} · Bâtiment A',
              status: status,
            );
          }).toList(),
        ),
      ),
    );
  }
}
