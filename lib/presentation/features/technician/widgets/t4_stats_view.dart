import 'package:flutter/material.dart';
import '../../../../config/theme/app_theme.dart';
import '../../../shared/widgets/common_widgets.dart';

class T4StatsView extends StatefulWidget {
  const T4StatsView({super.key});

  @override
  State<T4StatsView> createState() => _T4StatsViewState();
}

class _T4StatsViewState extends State<T4StatsView> {
  String _periodFilter = '7j'; // today, 7j, 30j, custom
  String _buildingFilter = 'Tous'; // Tous, A, B, C, D
  DateTimeRange? _selectedDateRange;

  // Mock data for buildings stats
  final List<Map<String, dynamic>> _allBuildingsData = [
    {
      'id': 'A',
      'name': 'Bâtiment A',
      'volailler': 'Ama Koffi',
      'activitiesPercent': '92%',
      'yield': '98%',
      'mortalityToday': 0,
      'mortality7j': 3,
      'mortality30j': 12,
    },
    {
      'id': 'B',
      'name': 'Bâtiment B',
      'volailler': 'Yao B.',
      'activitiesPercent': '85%',
      'yield': '95%',
      'mortalityToday': 1,
      'mortality7j': 14,
      'mortality30j': 42,
    },
    {
      'id': 'C',
      'name': 'Bâtiment C',
      'volailler': 'Dr. Koffi',
      'activitiesPercent': '78%',
      'yield': '87%',
      'mortalityToday': 4,
      'mortality7j': 20,
      'mortality30j': 68,
      'isRed': true,
    },
    {
      'id': 'D',
      'name': 'Bâtiment D',
      'volailler': 'Seydou Yao',
      'activitiesPercent': '64%',
      'yield': '76%',
      'mortalityToday': 8,
      'mortality7j': 35,
      'mortality30j': 110,
      'isRed': true,
    },
  ];

  int _getMortalityForPeriod(Map<String, dynamic> item) {
    if (_periodFilter == 'today') {
      return item['mortalityToday'] as int;
    } else if (_periodFilter == '30j') {
      return item['mortality30j'] as int;
    } else {
      // 7j or custom
      return item['mortality7j'] as int;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Filter by building
    final filteredBuildings = _allBuildingsData.where((b) {
      if (_buildingFilter == 'Tous') return true;
      return b['id'] == _buildingFilter;
    }).toList();

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

          // 2. Building Filter
          const Text('FILTRER PAR BÂTIMENT', style: AppTypography.labelSmall),
          const SizedBox(height: 6),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildBuildingChip('Tous', _buildingFilter == 'Tous'),
                _buildBuildingChip('Bât. A', _buildingFilter == 'A'),
                _buildBuildingChip('Bât. B', _buildingFilter == 'B'),
                _buildBuildingChip('Bât. C', _buildingFilter == 'C'),
                _buildBuildingChip('Bât. D', _buildingFilter == 'D'),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // 3. Comparative Building list
          const Text('RAPPORTS COMPARATIFS', style: AppTypography.labelSmall),
          const SizedBox(height: 10),

          ...filteredBuildings.map((b) {
            final int mortality = _getMortalityForPeriod(b);
            return _buildBuildingStat(
              letter: b['id'] as String,
              name: b['name'] as String,
              volailler: b['volailler'] as String,
              activitiesPercent: b['activitiesPercent'] as String,
              mortalityCount: mortality,
              yieldVal: b['yield'] as String,
              isRed: b['isRed'] == true,
            );
          }),
          const SizedBox(height: 20),

          // 4. Bar chart
          const Text('PRODUCTION D\'ŒUFS — HISTORIQUE', style: AppTypography.labelSmall),
          const SizedBox(height: 4),
          const Text('Nombre d\'œufs (Plateaux de 30)', style: TextStyle(fontSize: 11, color: AppColors.inkSoft, fontWeight: FontWeight.w500)),
          const SizedBox(height: 14),
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
        ],
      ),
    );
  }

  Widget _buildBuildingStat({
    required String letter,
    required String name,
    required String volailler,
    required String activitiesPercent,
    required int mortalityCount,
    required String yieldVal,
    required bool isRed,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 10),
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
            decoration: BoxDecoration(
              color: isRed ? AppColors.errorLight : AppColors.primaryLight,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              letter,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isRed ? AppColors.danger : AppColors.primaryDark,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                const SizedBox(height: 2),
                Text(
                  'Volailler : $volailler  ·  $activitiesPercent d\'act. faites',
                  style: const TextStyle(color: AppColors.inkSoft, fontSize: 11),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, size: 12, color: mortalityCount > 10 ? AppColors.danger : AppColors.inkSoft),
                    const SizedBox(width: 4),
                    Text(
                      '$mortalityCount mort(s) sur la période',
                      style: TextStyle(
                        color: mortalityCount > 10 ? AppColors.danger : AppColors.inkSoft,
                        fontSize: 10.5,
                        fontWeight: mortalityCount > 10 ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                yieldVal,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14.5,
                  color: isRed ? AppColors.danger : AppColors.primaryDark,
                ),
              ),
              const Text(
                'rendement',
                style: TextStyle(color: AppColors.inkSoft, fontSize: 9.5),
              ),
            ],
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

  Widget _buildBuildingChip(String label, bool isSelected) {
    final String targetFilter = label == 'Tous' ? 'Tous' : label.replaceAll('Bât. ', '');
    return GestureDetector(
      onTap: () => setState(() => _buildingFilter = targetFilter),
      child: Container(
        margin: const EdgeInsets.only(right: 6),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryDark : AppColors.paper,
          border: Border.all(color: isSelected ? AppColors.primaryDark : AppColors.line),
          borderRadius: BorderRadius.circular(100),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 10.5,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : AppColors.inkSoft,
          ),
        ),
      ),
    );
  }

  Widget _buildBar(double heightFactor, String label, bool highlight, {bool isLight = false}) {
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
