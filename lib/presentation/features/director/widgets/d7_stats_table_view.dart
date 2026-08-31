import 'package:flutter/material.dart';
import '../../../../config/theme/app_theme.dart';
import '../../../shared/widgets/common_widgets.dart';

class D7StatsTableView extends StatefulWidget {
  const D7StatsTableView({super.key});

  @override
  State<D7StatsTableView> createState() => _D7StatsTableViewState();
}

class _D7StatsTableViewState extends State<D7StatsTableView> {
  String _periodFilter = '7j'; // today, 7j, 30j, custom
  DateTimeRange? _selectedDateRange;

  // Mock stats changing based on period
  String _getLayingRate(String baseRate) {
    if (_periodFilter == 'today') {
      return baseRate;
    } else if (_periodFilter == '30j') {
      final val = int.tryParse(baseRate.replaceAll('%', ''));
      return val != null ? '${(val - 3).clamp(10, 100)}%' : baseRate;
    } else {
      final val = int.tryParse(baseRate.replaceAll('%', ''));
      return val != null ? '${(val - 1).clamp(10, 100)}%' : baseRate;
    }
  }

  String _getMortality(String baseMortality) {
    final count = int.tryParse(baseMortality.replaceAll(' morts', ''));
    if (count == null) return baseMortality;
    if (_periodFilter == 'today') {
      return '${(count / 10).round()} mort(s)';
    } else if (_periodFilter == '30j') {
      return '${(count * 3)} morts';
    } else {
      return '$count morts';
    }
  }

  String _getEggsCollected() {
    if (_periodFilter == 'today') {
      return '9 850';
    } else if (_periodFilter == '30j') {
      return '285 400';
    } else {
      return '68 950';
    }
  }

  String _getMortalityTotalText() {
    if (_periodFilter == 'today') {
      return '8 sujets';
    } else if (_periodFilter == '30j') {
      return '218 sujets';
    } else {
      return '72 sujets';
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Period Filter
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
              'Période : ${_formatDate(_selectedDateRange!.start)} au ${_formatDate(_selectedDateRange!.end)}',
              style: const TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.bold),
            ),
          ],
          const SizedBox(height: 16),

          const Text('TABLEAU COMPARATIF DES BÂTIMENTS', style: AppTypography.labelSmall),
          const SizedBox(height: 10),

          // Custom Data Table
          Container(
            decoration: BoxDecoration(
              color: AppColors.paper,
              border: Border.all(color: AppColors.line),
              borderRadius: BorderRadius.circular(12),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Table(
                columnWidths: const {
                  0: FlexColumnWidth(1.2),
                  1: FlexColumnWidth(1.2),
                  2: FlexColumnWidth(1.2),
                  3: FlexColumnWidth(1.2),
                  4: FlexColumnWidth(1.4),
                },
                border: const TableBorder(
                  horizontalInside: BorderSide(color: AppColors.line, width: 1),
                ),
                children: [
                  // Table Header
                  _buildHeaderRow(),
                  // Data Rows
                  _buildDataRow('Bât. A', '3 200', _getLayingRate('94%'), _getMortality('3 morts'), 'Excellent', AppColors.primaryDark),
                  _buildDataRow('Bât. B', '3 000', _getLayingRate('91%'), _getMortality('14 morts'), 'Stable', AppColors.primary),
                  _buildDataRow('Bât. C', '3 100', _getLayingRate('85%'), _getMortality('20 morts'), 'Vigilance', AppColors.accent),
                  _buildDataRow('Bât. D', '3 100', _getLayingRate('72%'), _getMortality('35 morts'), 'Critique', AppColors.danger),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Summary performance cards
          const Text('RÉSUMÉ ANALYTIQUE', style: AppTypography.labelSmall),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _buildSummaryCard(
                  'Œufs récoltés',
                  _getEggsCollected(),
                  _periodFilter == 'today'
                      ? 'Aujourd\'hui'
                      : (_periodFilter == '30j' ? 'Mois en cours' : '7 derniers jours'),
                  Icons.egg,
                  AppColors.primary,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildSummaryCard(
                  'Mortalité totale',
                  _getMortalityTotalText(),
                  _periodFilter == 'today'
                      ? 'Aujourd\'hui'
                      : (_periodFilter == '30j' ? 'Mois en cours' : '7 derniers jours'),
                  Icons.warning,
                  AppColors.danger,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Production chart
          const Text('PRODUCTION D\'ŒUFS — HISTORIQUE HEBDOMADAIRE', style: AppTypography.labelSmall),
          const SizedBox(height: 4),
          const Text('Nombre d\'œufs (Plateaux de 30)', style: TextStyle(fontSize: 11, color: AppColors.inkSoft, fontWeight: FontWeight.w500)),
          const SizedBox(height: 14),
          SizedBox(
            height: 180, // Increased height from 120 to 180 (Aussi augmente la taille des graphiques)
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _buildChartBar(0.40, 'L', false),
                _buildChartBar(0.58, 'M', false),
                _buildChartBar(0.35, 'M', false, isLight: true),
                _buildChartBar(0.64, 'J', false),
                _buildChartBar(0.70, 'V', false),
                _buildChartBar(0.85, 'S', true),
                _buildChartBar(0.60, 'D', false),
              ],
            ),
          ),
        ],
      ),
    );
  }

  TableRow _buildHeaderRow() {
    return TableRow(
      decoration: const BoxDecoration(
        color: Color(0xFFF1F1EB),
      ),
      children: [
        _buildHeaderCell('Bâtiment'),
        _buildHeaderCell('Volailles'),
        _buildHeaderCell('Taux Ponte'),
        _buildHeaderCell('Mortalité'),
        _buildHeaderCell('Statut'),
      ],
    );
  }

  Widget _buildHeaderCell(String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      child: Text(
        label,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 10,
          color: AppColors.primaryDark,
        ),
      ),
    );
  }

  TableRow _buildDataRow(
    String bat,
    String volailles,
    String ponte,
    String mortalite,
    String statut,
    Color statusColor,
  ) {
    return TableRow(
      children: [
        _buildCell(bat, isBold: true),
        _buildCell(volailles),
        _buildCell(ponte),
        _buildCell(mortalite, textColor: (mortalite.contains('0') || mortalite.contains('1 ') || mortalite.contains('2 morts') || mortalite.contains('3 morts')) ? AppColors.inkSoft : AppColors.danger),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              statut,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 9,
                color: statusColor,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCell(String text, {bool isBold = false, Color? textColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          color: textColor ?? AppColors.primaryDark,
        ),
      ),
    );
  }

  Widget _buildSummaryCard(
    String label,
    String val,
    String period,
    IconData icon,
    Color iconColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.paper,
        border: Border.all(color: AppColors.line),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 10, color: AppColors.inkSoft)),
                Text(val, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                Text(period, style: const TextStyle(fontSize: 9, color: AppColors.inkSoft)),
              ],
            ),
          ),
        ],
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

  Widget _buildChartBar(double heightFactor, String label, bool highlight, {bool isLight = false}) {
    Color barColor = AppColors.primary;
    if (highlight) barColor = AppColors.accent;
    if (isLight) barColor = AppColors.primaryLight;

    // Numerical calculation for eggs and plates labels above chart bars
    final int eggCount = (heightFactor * 3000).toInt();
    final int plateCount = (eggCount / 30).round();

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        // Display counts on top of bars (Nombre d'oeufs ou plateaux)
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
          height: 120 * heightFactor, // Increased visual height inside the 180px parent
          width: 18, // Slightly wider for visual premium feel
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
