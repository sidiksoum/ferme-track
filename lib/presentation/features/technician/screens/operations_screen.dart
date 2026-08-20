import 'package:flutter/material.dart';

import '../../../../config/theme/app_theme.dart';
import '../../../shared/widgets/common_widgets.dart';

class TechnicianOrdersScreen extends StatelessWidget {
  const TechnicianOrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final orders = [
      {'title': 'Commande aliment 40 sacs', 'meta': 'Réf: AL-302 · En cours', 'status': TaskStatus.todo},
      {'title': 'Achat vaccin', 'meta': 'Réf: VAC-18 · À valider', 'status': TaskStatus.partial},
      {'title': 'Commande désinfectant', 'meta': 'Réf: DIS-09 · Livrée', 'status': TaskStatus.done},
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAF7),
      appBar: AppBar(title: const Text('Commandes')),
      body: Padding(
        padding: const EdgeInsets.all(14),
        child: ListView(
          children: orders.map((item) {
            return TaskCard(
              icon: Icons.inventory_2,
              title: item['title'] as String,
              meta: item['meta'] as String,
              status: item['status'] as TaskStatus,
            );
          }).toList(),
        ),
      ),
    );
  }
}

class TechnicianDeliveryScreen extends StatelessWidget {
  const TechnicianDeliveryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final deliveries = [
      {'title': 'Livraison Bâtiment A', 'meta': '12 sacs · 07:40', 'status': TaskStatus.todo},
      {'title': 'Réception vaccin', 'meta': '06 flacons · 08:15', 'status': TaskStatus.done},
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAF7),
      appBar: AppBar(title: const Text('Réceptions')),
      body: Padding(
        padding: const EdgeInsets.all(14),
        child: ListView(
          children: deliveries.map((delivery) {
            return TaskCard(
              icon: Icons.local_shipping,
              title: delivery['title'] as String,
              meta: delivery['meta'] as String,
              status: delivery['status'] as TaskStatus,
            );
          }).toList(),
        ),
      ),
    );
  }
}
