import 'package:flutter/material.dart';
import '../../../../config/theme/app_theme.dart';

class M1AccueilSalesView extends StatefulWidget {
  final String userName;

  const M1AccueilSalesView({super.key, required this.userName});

  @override
  State<M1AccueilSalesView> createState() => _M1AccueilSalesViewState();
}

class _M1AccueilSalesViewState extends State<M1AccueilSalesView> {
  String _toggleMode = 'sales'; // sales, stock
  String _periodFilter = '7j'; // today, 7j, 30j, custom
  DateTimeRange? _selectedDateRange;

  final List<Map<String, dynamic>> _receivables = [
    {
      'client': 'Seydou Yao',
      'contact': '07 47 48 49 50',
      'address': 'Gare routière',
      'saleDetails': '40 plateaux Plus Gros format',
      'total': 100000,
      'paid': 35000,
      'due': 65000,
      'dueDate': '12/08/2026',
      'status': 'Échéance dépassée',
    },
    {
      'client': 'Adjoua Tanoh',
      'contact': '07 08 09 10 11',
      'address': 'Akoupé Marché',
      'saleDetails': '20 plateaux Gros format',
      'total': 44000,
      'paid': 25500,
      'due': 18500,
      'dueDate': '28/08/2026',
      'status': 'Échéance à venir',
    },
    {
      'client': 'Koffi Mensah',
      'contact': '05 06 07 08 09',
      'address': 'Marché central',
      'saleDetails': '12 plateaux Moyen format',
      'total': 21600,
      'paid': 9600,
      'due': 12000,
      'dueDate': '15/09/2026',
      'status': 'Échéance à venir',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Actor Welcome Sub-header
        Container(
          width: double.infinity,
          color: AppColors.primaryLight.withOpacity(0.3),
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 14),
          child: Text(
            'Bonjour, ${widget.userName}  ·  Ferme Akoupé  ·  3 bâtiments actifs',
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryDark,
            ),
          ),
        ),

        // Sub tabs
        Padding(
          padding: const EdgeInsets.all(14),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFFEFEFE7),
              borderRadius: BorderRadius.circular(11),
            ),
            padding: const EdgeInsets.all(3),
            child: Row(
              children: [
                Expanded(
                  child: _buildSubTabButton(
                    'Ventes & Créances',
                    _toggleMode == 'sales',
                    () => setState(() => _toggleMode = 'sales'),
                  ),
                ),
                Expanded(
                  child: _buildSubTabButton(
                    'Suivi des Stocks',
                    _toggleMode == 'stock',
                    () => setState(() => _toggleMode = 'stock'),
                  ),
                ),
              ],
            ),
          ),
        ),

        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: _toggleMode == 'sales'
                ? _buildSalesSummary()
                : _buildStockSummary(),
          ),
        ),
      ],
    );
  }

  Widget _buildSalesSummary() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'VENTES — PÉRIODE SÉLECTIONNÉE',
          style: AppTypography.labelSmall,
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppColors.primaryDark,
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _periodFilter == 'today'
                    ? 'Ventes d’aujourd’hui'
                    : 'Ventes cumulées',
                style: const TextStyle(color: Colors.white70, fontSize: 11),
              ),
              const SizedBox(height: 2),
              Text(
                _periodFilter == 'today' ? '45 000 FCFA' : '245 000 FCFA',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Container(height: 1, color: Colors.white24),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildSummaryItem('Comptant', '178 000'),
                  _buildSummaryItem('Crédit', '67 000'),
                  _buildSummaryItem('Créances tot.', '126 500'),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        const Text('PLUS GROSSES CRÉANCES', style: AppTypography.labelSmall),
        const SizedBox(height: 9),
        ..._receivables.map(_buildReceivableCard),
      ],
    );
  }

  Widget _buildReceivableCard(Map<String, dynamic> receivable) {
    final isOverdue = receivable['status'] == 'Échéance dépassée';
    final statusColor = isOverdue ? AppColors.danger : AppColors.accent;
    return GestureDetector(
      onTap: () => _showReceivableDetails(receivable),
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.paper,
          border: Border.all(color: AppColors.line),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: isOverdue
                    ? AppColors.errorLight
                    : AppColors.warningLight,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.account_balance_wallet_outlined,
                color: statusColor,
                size: 19,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    receivable['client'],
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13.5,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    receivable['saleDetails'],
                    style: const TextStyle(
                      color: AppColors.inkSoft,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Échéance : ${receivable['dueDate']}',
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 10.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              '${receivable['due']} FCFA',
              style: TextStyle(
                color: statusColor,
                fontWeight: FontWeight.bold,
                fontSize: 12.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showReceivableDetails(Map<String, dynamic> receivable) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(receivable['client']),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Contact : ${receivable['contact']}'),
              Text('Adresse : ${receivable['address']}'),
              const SizedBox(height: 10),
              Text('Vente : ${receivable['saleDetails']}'),
              Text('Montant total : ${receivable['total']} FCFA'),
              Text('Montant payé : ${receivable['paid']} FCFA'),
              Text('Reste à payer : ${receivable['due']} FCFA'),
              Text('Date d’échéance : ${receivable['dueDate']}'),
              Text('Statut : ${receivable['status']}'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  Widget _buildStockSummary() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'STOCK MAGASIN — ŒUFS PAR FORMAT',
          style: AppTypography.labelSmall,
        ),
        const SizedBox(height: 12),
        _buildEggStockItem(
          'Nombre de gros œufs',
          '1 240',
          '41 plaquettes',
          AppColors.primary,
        ),
        _buildEggStockItem(
          'Nombre de petits œufs',
          '980',
          '32 plaquettes',
          AppColors.primary,
        ),
        _buildEggStockItem(
          'Nombre d’œufs moyens',
          '4 320',
          '144 plaquettes',
          AppColors.primaryDark,
        ),
        _buildEggStockItem(
          'Nombre de plus gros œufs',
          '620',
          '21 plaquettes',
          AppColors.danger,
        ),
      ],
    );
  }

  Widget _buildEggStockItem(
    String label,
    String quantity,
    String trays,
    Color color,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.paper,
        border: Border.all(color: AppColors.line),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.egg, color: color, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '$quantity œufs',
                  style: const TextStyle(
                    color: AppColors.inkSoft,
                    fontSize: 11.5,
                  ),
                ),
              ],
            ),
          ),
          Text(
            trays,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStockItem(
    String name,
    int quantity,
    String unit,
    String status,
    double percent,
    Color progressColor,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
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
                  name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13.5,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: progressColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(
                      color: progressColor == AppColors.primary
                          ? AppColors.primaryDark
                          : progressColor,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              '$quantity $unit disponibles',
              style: const TextStyle(color: AppColors.inkSoft, fontSize: 11.5),
            ),
            const SizedBox(height: 8),
            Container(
              height: 6,
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFFEAEAE3),
                borderRadius: BorderRadius.circular(5),
              ),
              alignment: Alignment.centerLeft,
              child: FractionallySizedBox(
                widthFactor: percent,
                child: Container(
                  decoration: BoxDecoration(
                    color: progressColor,
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
              ),
            ),
          ],
        ),
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

  Widget _buildPeriodChip(String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryDark : AppColors.paper,
          border: Border.all(
            color: isSelected ? AppColors.primaryDark : AppColors.line,
          ),
          borderRadius: BorderRadius.circular(100),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : AppColors.inkSoft,
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryItem(String title, String val) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(color: Colors.white70, fontSize: 10),
        ),
        const SizedBox(height: 2),
        Text(
          val,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
  }
}
