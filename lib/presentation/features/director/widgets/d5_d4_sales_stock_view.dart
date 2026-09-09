import 'package:flutter/material.dart';
import '../../../../config/theme/app_theme.dart';
import '../../../shared/widgets/common_widgets.dart';

class D5D4SalesStockView extends StatefulWidget {
  const D5D4SalesStockView({super.key});

  @override
  State<D5D4SalesStockView> createState() => _D5D4SalesStockViewState();
}

class _D5D4SalesStockViewState extends State<D5D4SalesStockView> {
  String _salesOrStockToggle = 'sales'; // sales, stock
  String _salesPeriodFilter = '7j'; // today, 7j, 30j, custom
  DateTimeRange? _selectedDateRange;
  String _stockSubTab = 'magasin'; // magasin, ferme

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
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
                    'Ventes & Créances (D5)',
                    _salesOrStockToggle == 'sales',
                    () => setState(() => _salesOrStockToggle = 'sales'),
                  ),
                ),
                Expanded(
                  child: _buildSubTabButton(
                    'Suivi des Stocks (D4)',
                    _salesOrStockToggle == 'stock',
                    () => setState(() => _salesOrStockToggle = 'stock'),
                  ),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: _salesOrStockToggle == 'sales'
                ? _buildD5Sales()
                : _buildD4Stock(),
          ),
        ),
      ],
    );
  }

  Widget _buildD5Sales() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Filter by Date
        const Text('FILTRER PAR PÉRIODE', style: AppTypography.labelSmall),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: AppColors.paper,
                  border: Border.all(color: AppColors.line, width: 1.5),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _salesPeriodFilter,
                    isExpanded: true,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.primaryDark,
                    ),
                    onChanged: (val) async {
                      if (val != null) {
                        setState(() => _salesPeriodFilter = val);
                        if (val == 'custom') {
                          final picked = await showDateRangePicker(
                            context: context,
                            firstDate: DateTime(2025),
                            lastDate: DateTime(2027),
                          );
                          if (picked != null) {
                            setState(() => _selectedDateRange = picked);
                          }
                        }
                      }
                    },
                    items: const [
                      DropdownMenuItem(
                        value: 'today',
                        child: Text('Aujourd\'hui'),
                      ),
                      DropdownMenuItem(value: '7j', child: Text('7 jours')),
                      DropdownMenuItem(
                        value: '30j',
                        child: Text('Mois en cours'),
                      ),
                      DropdownMenuItem(
                        value: 'custom',
                        child: Text('Personnalisé'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        if (_salesPeriodFilter == 'custom' && _selectedDateRange != null) ...[
          const SizedBox(height: 6),
          Text(
            'Période : ${_formatDate(_selectedDateRange!.start)} au ${_formatDate(_selectedDateRange!.end)}',
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
        const SizedBox(height: 14),

        // Summary card
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
                _salesPeriodFilter == 'today'
                    ? 'Ventes d\'aujourd\'hui'
                    : (_salesPeriodFilter == '7j'
                          ? 'Ventes (7 derniers jours)'
                          : 'Ventes cumulées'),
                style: const TextStyle(color: Colors.white70, fontSize: 10.5),
              ),
              const SizedBox(height: 2),
              Text(
                _salesPeriodFilter == 'today'
                    ? '45 000 FCFA'
                    : (_salesPeriodFilter == '30j'
                          ? '820 000 FCFA'
                          : '245 000 FCFA'),
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
                  _buildSummaryItem(
                    'Comptant',
                    _salesPeriodFilter == 'today' ? '30 000' : '178 000',
                  ),
                  _buildSummaryItem(
                    'Crédit',
                    _salesPeriodFilter == 'today' ? '15 000' : '67 000',
                  ),
                  _buildSummaryItem('Créances tot.', '126 500'),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        const Text('RÉPARTITION GRAPHIQUE', style: AppTypography.labelSmall),
        const SizedBox(height: 4),
        const Text(
          'Nombre d\'œufs (Plateaux de 30)',
          style: TextStyle(
            fontSize: 11,
            color: AppColors.inkSoft,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 14),
        // Bar Chart for Sales
        SizedBox(
          height: 180,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _buildBar(0.40, 'L', false),
              _buildBar(0.58, 'M', false),
              _buildBar(0.35, 'M', false, isLight: true),
              _buildBar(0.64, 'J', false),
              _buildBar(0.70, 'V', false),
              _buildBar(0.85, 'S', true),
              _buildBar(0.60, 'D', false),
            ],
          ),
        ),
        const SizedBox(height: 20),

        const Text('PLUS GROSSES CRÉANCES', style: AppTypography.labelSmall),
        const SizedBox(height: 9),
        ..._getReceivables().map(_buildReceivableCard),
      ],
    );
  }

  List<Map<String, dynamic>> _getReceivables() {
    return [
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

  Widget _buildD4Stock() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'SUIVI DES STOCKS — VUE DIRECTEUR',
          style: AppTypography.labelSmall,
        ),
        const SizedBox(height: 12),
        // Sub-tabs for Magasin and Ferme
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFEFEFE7),
            borderRadius: BorderRadius.circular(9),
          ),
          padding: const EdgeInsets.all(2),
          child: Row(
            children: [
              Expanded(
                child: _buildSubTabButton(
                  'Stocks Magasin',
                  _stockSubTab == 'magasin',
                  () => setState(() => _stockSubTab = 'magasin'),
                ),
              ),
              Expanded(
                child: _buildSubTabButton(
                  'Stocks Ferme',
                  _stockSubTab == 'ferme',
                  () => setState(() => _stockSubTab = 'ferme'),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        if (_stockSubTab == 'magasin') ...[
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
            'Nombre d œufs moyens',
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
        ] else ...[
          _buildStockItem(
            'Aliment ponte (Mangeoire)',
            4,
            'sacs',
            'OK',
            0.80,
            AppColors.primary,
          ),
          _buildStockItem(
            'Aliment croissance (Mangeoire)',
            2,
            'sacs',
            'Bas',
            0.40,
            AppColors.accent,
          ),
          _buildStockItem(
            'Désinfectant',
            15,
            'litres',
            'OK',
            0.75,
            AppColors.primary,
          ),
          _buildStockItem(
            'Eau de boisson',
            500,
            'litres',
            'OK',
            0.90,
            AppColors.primary,
          ),
        ],
      ],
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
            fontSize: 13.5,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildBar(
    double heightFactor,
    String label,
    bool highlight, {
    bool isLight = false,
  }) {
    Color barColor = AppColors.primary;
    if (highlight) barColor = AppColors.accent;
    if (isLight) barColor = AppColors.primaryLight;

    final int eggCount = (heightFactor * 3000).toInt();
    final int plateCount = (eggCount / 30).round();

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(
          '$eggCount\n($plateCount pl.)',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 8.5,
            fontWeight: FontWeight.bold,
            color: highlight ? AppColors.accent : AppColors.primaryDark,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          height: 120 * heightFactor,
          width: 18,
          decoration: BoxDecoration(
            color: barColor,
            border: isLight ? Border.all(color: const Color(0xFFCFE3CF)) : null,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(3)),
          ),
        ),
        const SizedBox(height: 5),
        Text(
          label,
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.bold,
            color: highlight ? AppColors.accent : AppColors.inkSoft,
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
  }
}
