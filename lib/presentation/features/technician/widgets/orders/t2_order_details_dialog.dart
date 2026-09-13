import 'package:flutter/material.dart';
import '../../../../../config/theme/app_theme.dart';

class T2OrderDetailsDialog extends StatelessWidget {
  final Map<String, dynamic> order;

  const T2OrderDetailsDialog({
    super.key,
    required this.order,
  });

  static Future<void> show(
    BuildContext context, {
    required Map<String, dynamic> order,
  }) {
    return showDialog<void>(
      context: context,
      builder: (dialogContext) => T2OrderDetailsDialog(order: order),
    );
  }

  @override
  Widget build(BuildContext context) {
    final supplier = order['supplier']?.toString() ?? 'Fournisseur inconnu';
    final ref = order['ref']?.toString() ?? 'N/A';
    final type = order['type']?.toString() ?? 'aliment';
    final details = order['details']?.toString() ?? 'Article';
    final cost = order['cost']?.toString() ?? 'Non renseigné';
    final quantity = order['quantity']?.toString() ?? '1';
    final expectedDate = order['expectedDate']?.toString().split('T').first ?? 'Non renseignée';
    final receivedDate = order['receivedDate']?.toString().split('T').first ?? expectedDate;
    final note = order['note']?.toString() ?? '';
    final receivedNote = order['receivedNote']?.toString() ?? '';
    final buildingName = order['buildingName']?.toString();
    final lotName = order['lotName']?.toString();
    final lotCount = order['lotCount']?.toString();

    final isPoultry = type.toLowerCase().contains('volaille') ||
        details.toLowerCase().contains('poussin') ||
        details.toLowerCase().contains('poulet');

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      contentPadding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Détails de la Commande',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Réf : #$ref',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.inkSoft,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.successLight,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check_circle, size: 14, color: AppColors.primaryDark),
                SizedBox(width: 4),
                Text(
                  'Livrée',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryDark,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Divider(height: 1),
            const SizedBox(height: 14),

            // Fournisseur Card
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.line),
              ),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.storefront,
                      size: 20,
                      color: AppColors.primaryDark,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'FOURNISSEUR',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: AppColors.inkSoft,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          supplier,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: AppColors.ink,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Key details grid
            _buildDetailRow(
              icon: Icons.inventory_2_outlined,
              label: 'Article / Détails',
              value: details,
            ),
            const SizedBox(height: 10),

            _buildDetailRow(
              icon: Icons.numbers,
              label: 'Quantité commandée',
              value: quantity,
            ),
            const SizedBox(height: 10),

            _buildDetailRow(
              icon: Icons.payments_outlined,
              label: 'Montant total',
              value: cost,
            ),
            const SizedBox(height: 10),

            _buildDetailRow(
              icon: Icons.event_available,
              label: 'Date de réception',
              value: receivedDate,
            ),

            // Section Volaille (Bâtiment & Lot) si applicable
            if (isPoultry || lotName != null || buildingName != null) ...[
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.primaryLight),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.pets, size: 16, color: AppColors.primaryDark),
                        SizedBox(width: 6),
                        Text(
                          'Intégration Cheptel & Lot',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryDark,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (buildingName != null)
                      Text(
                        '• Bâtiment : $buildingName',
                        style: const TextStyle(fontSize: 12, color: AppColors.ink),
                      ),
                    if (lotName != null)
                      Text(
                        '• Lot créé : $lotName',
                        style: const TextStyle(fontSize: 12, color: AppColors.ink),
                      ),
                    if (lotCount != null)
                      Text(
                        '• Effectif intégré : $lotCount volailles',
                        style: const TextStyle(fontSize: 12, color: AppColors.ink),
                      ),
                  ],
                ),
              ),
            ],

            // Section Observations / Notes
            if (receivedNote.isNotEmpty || note.isNotEmpty) ...[
              const SizedBox(height: 14),
              const Text(
                'OBSERVATIONS & RAPPORT DE RÉCEPTION',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: AppColors.inkSoft,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.line),
                ),
                child: Text(
                  receivedNote.isNotEmpty ? receivedNote : note,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.ink,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.inkSoft),
        const SizedBox(width: 8),
        Text(
          '$label : ',
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.inkSoft,
            fontWeight: FontWeight.w500,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.bold,
              color: AppColors.ink,
            ),
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }
}
