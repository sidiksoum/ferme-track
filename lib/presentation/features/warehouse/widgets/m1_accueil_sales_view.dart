import 'package:flutter/material.dart';
import '../../../../config/theme/app_theme.dart';
import '../../../shared/widgets/common_widgets.dart';

class M1AccueilSalesView extends StatefulWidget {
  final String userName;

  const M1AccueilSalesView({
    super.key,
    required this.userName,
  });

  @override
  State<M1AccueilSalesView> createState() => _M1AccueilSalesViewState();
}

class _M1AccueilSalesViewState extends State<M1AccueilSalesView> {
  String _toggleMode = 'sales'; // sales, stock
  String _periodFilter = '7j'; // today, 7j, 30j, custom
  DateTimeRange? _selectedDateRange;

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
        // Period Filter
        const Text('FILTRER PAR PÉRIODE', style: AppTypography.labelSmall),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildPeriodChip('Aujourd\'hui', _periodFilter == 'today', () => setState(() => _periodFilter = 'today')),
            _buildPeriodChip('7 jours', _periodFilter == '7j', () => setState(() => _periodFilter = '7j')),
            _buildPeriodChip('Mois en cours', _periodFilter == '30j', () => setState(() => _periodFilter = '30j')),
            _buildPeriodChip('Personnalisé', _periodFilter == 'custom', () async {
              setState(() => _periodFilter = 'custom');
              final picked = await showDateRangePicker(
                context: context,
                firstDate: DateTime(2025),
                lastDate: DateTime(2027),
              );
              if (picked != null) {
                setState(() => _selectedDateRange = picked);
              }
            }),
          ],
        ),
        if (_periodFilter == 'custom' && _selectedDateRange != null) ...[
          const SizedBox(height: 6),
          Text(
            'Du ${_formatDate(_selectedDateRange!.start)} au ${_formatDate(_selectedDateRange!.end)}',
            style: const TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.bold),
          ),
        ],
        const SizedBox(height: 14),

        // Summary values
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
              const Text(
                'Ventes — période sélectionnée',
                style: TextStyle(color: Colors.white70, fontSize: 11),
              ),
              const SizedBox(height: 2),
              Text(
                _periodFilter == 'today'
                    ? '45 000 FCFA'
                    : (_periodFilter == '30j' ? '820 000 FCFA' : '245 000 FCFA'),
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
                    _periodFilter == 'today' ? '30 000' : '178 000',
                  ),
                  _buildSummaryItem(
                    'Crédit',
                    _periodFilter == 'today' ? '15 000' : '67 000',
                  ),
                  _buildSummaryItem('Créances tot.', '126 500'),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        const Text('PLUS GROSSES CRÉANCES', style: AppTypography.labelSmall),
        const SizedBox(height: 9),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.paper,
            border: Border.all(color: AppColors.line),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(
                  color: AppColors.errorLight,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: const Text(
                  'SY',
                  style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.danger),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Seydou Yao',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Échéance dépassée',
                    style: TextStyle(color: AppColors.danger, fontSize: 9.5, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const Spacer(),
              const Text(
                '65 000 FCFA',
                style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.danger, fontSize: 14),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStockSummary() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('SUIVI DES STOCKS — VUE DIRECTEUR', style: AppTypography.labelSmall),
        const SizedBox(height: 12),
        _buildStockItem('Aliment ponte', 12, 'sacs', 'Bas', 0.35, AppColors.accent),
        _buildStockItem('Aliment démarrage', 3, 'sacs', 'Critique', 0.08, AppColors.danger),
        _buildStockItem('Vaccin Newcastle', 85, 'doses', 'OK', 0.85, AppColors.primary),
        _buildStockItem('Vitamines complexes', 40, 'flacons', 'OK', 0.65, AppColors.primary),
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
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: progressColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(
                      color: progressColor == AppColors.primary ? AppColors.primaryDark : progressColor,
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
          border: Border.all(color: isSelected ? AppColors.primaryDark : AppColors.line),
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
        Text(title, style: const TextStyle(color: Colors.white70, fontSize: 10)),
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
