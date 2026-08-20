import 'package:flutter/material.dart';

import '../../../../config/theme/app_theme.dart';
import '../../../shared/widgets/common_widgets.dart';

class WarehouseClientScreen extends StatelessWidget {
  const WarehouseClientScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, String>> clients = [
      {'name': 'Mme Adjoua T.', 'balance': '125 000 FCFA', 'type': 'Détaillante'},
      {'name': 'Akon Market', 'balance': '50 000 FCFA', 'type': 'Grossiste'},
      {'name': 'Restaurant K', 'balance': '80 000 FCFA', 'type': 'Restaurant'},
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAF7),
      appBar: AppBar(title: const Text('Clients & créances')),
      body: ListView.builder(
        padding: const EdgeInsets.all(14),
        itemCount: clients.length,
        itemBuilder: (context, index) {
          final client = clients[index];
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.paper,
              border: Border.all(color: AppColors.line),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(client['name'] ?? '', style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: AppColors.ink)),
                    Text(client['type'] ?? '', style: const TextStyle(fontSize: 10, color: AppColors.inkSoft)),
                  ],
                ),
                Text(client['balance'] ?? '', style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: AppColors.primaryDark)),
              ],
            ),
          );
        },
      ),
    );
  }
}

class WarehouseStockMovementScreen extends StatelessWidget {
  const WarehouseStockMovementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> movements = [
      {'title': 'Entrée · 150 œufs', 'meta': 'Réception Bât. A · 07:35', 'status': TaskStatus.done},
      {'title': 'Sortie · 40 sacs', 'meta': 'Vente comptant · 09:10', 'status': TaskStatus.todo},
      {'title': 'Retrait · 8 kg aliment', 'meta': 'Usage atelier · 11:20', 'status': TaskStatus.partial},
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAF7),
      appBar: AppBar(title: const Text('Mouvements de stock')),
      body: Padding(
        padding: const EdgeInsets.all(14),
        child: ListView(
          children: movements.map((movement) {
            final status = movement['status'] as TaskStatus;
            return TaskCard(
              icon: status == TaskStatus.done ? Icons.arrow_downward : Icons.arrow_upward,
              title: movement['title'] as String,
              meta: movement['meta'] as String,
              status: status,
            );
          }).toList(),
        ),
      ),
    );
  }
}
