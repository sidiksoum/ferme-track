import 'package:flutter/material.dart';
import '../../../../../core/di/service_locator.dart';
import '../../../../../data/datasources/remote/api_client.dart';

class T2CloseOrderDialog extends StatefulWidget {
  final Map<String, dynamic> order;
  final List<Map<String, String>> buildingOptions;
  final VoidCallback onOrderClosed;

  const T2CloseOrderDialog({
    super.key,
    required this.order,
    required this.buildingOptions,
    required this.onOrderClosed,
  });

  static Future<void> show(
    BuildContext context, {
    required Map<String, dynamic> order,
    required List<Map<String, String>> buildingOptions,
    required VoidCallback onOrderClosed,
  }) {
    return showDialog(
      context: context,
      builder: (context) => T2CloseOrderDialog(
        order: order,
        buildingOptions: buildingOptions,
        onOrderClosed: onOrderClosed,
      ),
    );
  }

  @override
  State<T2CloseOrderDialog> createState() => _T2CloseOrderDialogState();
}

class _T2CloseOrderDialogState extends State<T2CloseOrderDialog> {
  final ApiClient _apiClient = getIt<ApiClient>();

  final TextEditingController _qtyController = TextEditingController();
  final TextEditingController _commentController = TextEditingController();
  final TextEditingController _lotNameController = TextEditingController();
  final TextEditingController _lotCountController = TextEditingController();
  String? _selectedBuildingId;
  bool _isSubmitting = false;

  bool get _isPoultryOrder {
    final type = widget.order['type']?.toString().toLowerCase() ?? '';
    final details = widget.order['details']?.toString().toLowerCase() ?? '';
    return type == 'volaille' ||
        details.contains('poussin') ||
        details.contains('volaille') ||
        details.contains('poulet');
  }

  @override
  void initState() {
    super.initState();
    if (widget.buildingOptions.isNotEmpty) {
      _selectedBuildingId = widget.buildingOptions.first['id'];
    }
    final defaultLotName = 'Lot ${widget.order['ref'] ?? DateTime.now().millisecondsSinceEpoch}';
    _lotNameController.text = defaultLotName;
  }

  @override
  void dispose() {
    _qtyController.dispose();
    _commentController.dispose();
    _lotNameController.dispose();
    _lotCountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final supplierName = widget.order['supplier'] ?? 'Fournisseur';
    final details = widget.order['details'] ?? 'Articles';

    return AlertDialog(
      title: Text('Clôturer la commande : $supplierName'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Articles attendus : $details'),
            if (_isPoultryOrder) ...[
              const SizedBox(height: 14),
              const Text(
                'BÂTIMENT DE DESTINATION',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              ),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                value: widget.buildingOptions.any((b) => b['id'] == _selectedBuildingId)
                    ? _selectedBuildingId
                    : (widget.buildingOptions.isNotEmpty ? widget.buildingOptions.first['id'] : null),
                items: widget.buildingOptions
                    .map(
                      (building) => DropdownMenuItem(
                        value: building['id'],
                        child: Text(building['name']!),
                      ),
                    )
                    .toList(),
                onChanged: (value) => setState(() => _selectedBuildingId = value),
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _lotNameController,
                decoration: const InputDecoration(
                  labelText: 'Nom du lot (ex: Lot Pondeuses 2026)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _lotCountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Effectif du lot (Nombre de volailles reçues)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Commentaire sur la réception :',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _commentController,
                decoration: const InputDecoration(
                  hintText: 'Détails sur l\'état des volailles reçues...',
                  border: OutlineInputBorder(),
                ),
              ),
            ] else ...[
              const SizedBox(height: 14),
              const Text(
                'Quantité reçue :',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _qtyController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  hintText: 'Ex : 40 (sacs, flacons, etc.)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Commentaire de réception :',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _commentController,
                decoration: const InputDecoration(
                  hintText: 'Ex : Marchandise conforme reçue en bon état.',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: _isSubmitting ? null : _submitCloseOrder,
          child: _isSubmitting
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Clôturer la commande'),
        ),
      ],
    );
  }

  Future<void> _submitCloseOrder() async {
    final orderId = widget.order['id']?.toString();
    final comment = _commentController.text.trim();

    if (_isPoultryOrder) {
      final lotCountStr = _lotCountController.text.trim();
      final lotName = _lotNameController.text.trim();

      if (_selectedBuildingId == null || lotName.isEmpty || lotCountStr.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Veuillez renseigner le bâtiment, le nom du lot et l\'effectif reçu',
            ),
          ),
        );
        return;
      }

      final lotCount = int.tryParse(lotCountStr);
      if (lotCount == null || lotCount <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('L\'effectif doit être un nombre positif supérieur à 0'),
          ),
        );
        return;
      }

      setState(() => _isSubmitting = true);
      try {
        if (orderId != null && orderId.isNotEmpty) {
          await _apiClient.patch(
            '/orders/$orderId/receive',
            data: {
              'qtyReceived': lotCount.toDouble(),
              'comment': comment.isNotEmpty ? comment : 'Réception volaille conforme',
              'buildingId': _selectedBuildingId,
              'lotName': lotName,
              'lotCount': lotCount,
              'type': 'volaille',
            },
          );
        }

        if (mounted) {
          Navigator.pop(context);
          widget.onOrderClosed();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Commande de volailles clôturée et lot "$lotName" enregistré dans la table des lots !',
              ),
            ),
          );
        }
      } catch (error) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Impossible de clôturer la commande : $error')),
          );
        }
      } finally {
        if (mounted) setState(() => _isSubmitting = false);
      }
    } else {
      final qtyStr = _qtyController.text.trim();
      if (qtyStr.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Veuillez renseigner la quantité reçue'),
          ),
        );
        return;
      }

      final qty = double.tryParse(qtyStr);
      if (qty == null || qty <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('La quantité reçue doit être un nombre positif'),
          ),
        );
        return;
      }

      setState(() => _isSubmitting = true);
      try {
        if (orderId != null && orderId.isNotEmpty) {
          await _apiClient.patch(
            '/orders/$orderId/receive',
            data: {
              'qtyReceived': qty,
              'comment': comment.isNotEmpty ? comment : 'Marchandise conforme reçue en bon état.',
              'type': widget.order['type'] ?? 'aliment',
            },
          );
        }

        if (mounted) {
          Navigator.pop(context);
          widget.onOrderClosed();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Commande auprès de ${widget.order['supplier']} clôturée et stock ferme mis à jour !',
              ),
            ),
          );
        }
      } catch (error) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Impossible de clôturer la commande : $error')),
          );
        }
      } finally {
        if (mounted) setState(() => _isSubmitting = false);
      }
    }
  }
}
