import 'package:flutter/material.dart';
import '../../../../../config/theme/app_theme.dart';
import '../../../../shared/widgets/common_widgets.dart';
import '../egg_exits/t2_egg_exits_tab.dart';
import 't2_close_order_dialog.dart';
import 't2_order_details_dialog.dart';

class T2OrdersTab extends StatefulWidget {
  final List<Map<String, dynamic>> orders;
  final List<Map<String, dynamic>> eggExits;
  final List<Map<String, String>> buildingOptions;
  final bool isLoadingOrders;
  final bool isLoadingEggExits;
  final String activeSubTab; // 'orders' or 'eggs'
  final ValueChanged<String> onSubTabChanged;
  final VoidCallback onAddOrder;
  final VoidCallback onAddEggExit;
  final VoidCallback onBack;
  final VoidCallback onRefreshOrders;

  const T2OrdersTab({
    super.key,
    required this.orders,
    required this.eggExits,
    required this.buildingOptions,
    required this.isLoadingOrders,
    required this.isLoadingEggExits,
    required this.activeSubTab,
    required this.onSubTabChanged,
    required this.onAddOrder,
    required this.onAddEggExit,
    required this.onBack,
    required this.onRefreshOrders,
  });

  @override
  State<T2OrdersTab> createState() => _T2OrdersTabState();
}

class _T2OrdersTabState extends State<T2OrdersTab> {
  @override
  Widget build(BuildContext context) {
    final isOrdersTab = widget.activeSubTab == 'orders';

    return Column(
      children: [
        // Sub-tabs toggle (Commande / Sortie œufs)
        Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Expanded(
                child: _buildSubTabButton(
                  'Commande',
                  isOrdersTab,
                  () => widget.onSubTabChanged('orders'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildSubTabButton(
                  'Sortie œufs',
                  !isOrdersTab,
                  () => widget.onSubTabChanged('eggs'),
                ),
              ),
            ],
          ),
        ),

        // Content
        Expanded(
          child: isOrdersTab
              ? _buildOrdersList()
              : T2EggExitsTab(
                  eggExits: widget.eggExits,
                  isLoading: widget.isLoadingEggExits,
                ),
        ),

        // Sticky Bottom actions row
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 8, 14, 14),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: widget.onBack,
                  child: const Text('Retour'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: isOrdersTab ? widget.onAddOrder : widget.onAddEggExit,
                  icon: const Icon(Icons.add, size: 16),
                  label: Text(
                    isOrdersTab ? 'Ajouter une commande' : 'Effectuer une sortie',
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOrdersList() {
    if (widget.isLoadingOrders) {
      return const Center(child: CircularProgressIndicator());
    }

    if (widget.orders.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 40),
          child: Text(
            'Aucune commande enregistrée.',
            style: TextStyle(color: AppColors.inkSoft),
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      children: [
        const Text('COMMANDES FOURNISSEURS', style: AppTypography.labelSmall),
        const SizedBox(height: 10),
        ...widget.orders.map((ord) {
          final statusStr = (ord['status']?.toString() ?? '').toLowerCase();
          final isDelivered = statusStr.contains('livr') ||
              statusStr.contains('fait') ||
              statusStr.contains('received') ||
              statusStr.contains('clotur');
          final isLate = ord['isLate'] == true;
          final status = isDelivered
              ? TaskStatus.done
              : (isLate ? TaskStatus.late : TaskStatus.todo);

          final costStr = ord['cost'] != null ? ' · ${ord['cost']}' : '';
          final qtyStr = ord['quantity'] != null ? ' (${ord['quantity']})' : '';

          return TaskCard(
            icon: Icons.shopping_bag,
            title: ord['supplier'] ?? 'Fournisseur inconnu',
            meta:
                '${ord['details']}$qtyStr · Réf: #${ord['ref']} · ${isDelivered ? 'Livrée' : ord['status']}$costStr',
            status: status,
            onTap: () {
              if (isDelivered) {
                T2OrderDetailsDialog.show(
                  context,
                  order: ord,
                );
              } else {
                T2CloseOrderDialog.show(
                  context,
                  order: ord,
                  buildingOptions: widget.buildingOptions,
                  onOrderClosed: () {
                    ord['status'] = 'Livrée';
                    widget.onRefreshOrders();
                  },
                );
              }
            },
          );
        }),
      ],
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
}
