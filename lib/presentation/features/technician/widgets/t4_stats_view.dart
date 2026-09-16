import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../config/theme/app_theme.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/services/socket_client_service.dart';
import '../../../../data/datasources/remote/api_client.dart';

class T4StatsView extends StatefulWidget {
  const T4StatsView({super.key});

  @override
  State<T4StatsView> createState() => _T4StatsViewState();
}

class _T4StatsViewState extends State<T4StatsView> {
  final ApiClient _apiClient = getIt<ApiClient>();
  final SocketClientService _socketService = getIt<SocketClientService>();
  StreamSubscription? _socketSubscription;

  String _periodFilter = '7j'; // today, 7j, 30j, custom
  String _buildingFilter = 'Tous'; // Tous, or building id/name
  DateTimeRange? _selectedDateRange;

  // Real data for buildings stats
  List<Map<String, dynamic>> _allBuildingsData = [];
  List<Map<String, dynamic>> _layingChartData = [];
  Map<String, dynamic> _statsSummary = {
    'totalEggs': 0,
    'totalDeaths': 0,
    'totalBirds': 0,
    'overallLayingRate': '0%',
  };

  @override
  void initState() {
    super.initState();
    _loadStatsData();

    _socketSubscription = _socketService.allEvents.listen((event) {
      final evt = event['event']?.toString() ?? '';
      if (evt.contains('egg') ||
          evt.contains('mortality') ||
          evt.contains('task') ||
          evt.contains('activity') ||
          evt.contains('reception')) {
        if (mounted) {
          _loadStatsData(forceRefresh: true);
        }
      }
    });
  }

  @override
  void dispose() {
    _socketSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadStatsData({bool forceRefresh = false}) async {
    if (!mounted) return;
    try {
      final queryParams = <String, dynamic>{
        'period': _periodFilter,
        'buildingId': _buildingFilter,
      };
      if (_periodFilter == 'custom' && _selectedDateRange != null) {
        queryParams['start_date'] = _selectedDateRange!.start.toIso8601String();
        queryParams['end_date'] = _selectedDateRange!.end.toIso8601String();
      }

      final response = await _apiClient.get(
        '/technician/stats/production',
        queryParameters: queryParams,
        forceRefresh: forceRefresh,
        useCache: true,
      );

      if (!mounted || response is! Map) return;

      final buildings = response['buildings'] as List? ?? [];
      final chart = response['layingChart'] as List? ?? [];
      final summary = response['summary'] as Map? ?? {};

      setState(() {
        _allBuildingsData = buildings
            .whereType<Map>()
            .map((b) => Map<String, dynamic>.from(b))
            .toList();
        _layingChartData = chart
            .whereType<Map>()
            .map((c) => Map<String, dynamic>.from(c))
            .toList();
        if (summary.isNotEmpty) {
          _statsSummary = Map<String, dynamic>.from(summary);
        }
      });
    } catch (_) {}
  }

  int _getMortalityForPeriod(Map<String, dynamic> item) {
    return (item['mortalityCount'] as num?)?.toInt() ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    final filteredBuildings = _allBuildingsData.where((b) {
      if (_buildingFilter == 'Tous') return true;
      final id = b['id']?.toString() ?? '';
      final name = b['name']?.toString() ?? '';
      return id == _buildingFilter || name.contains(_buildingFilter);
    }).toList();

    return RefreshIndicator(
      onRefresh: () => _loadStatsData(forceRefresh: true),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
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
                _buildPeriodChip(
                  'Aujourd\'hui',
                  _periodFilter == 'today',
                  () {
                    setState(() => _periodFilter = 'today');
                    _loadStatsData();
                  },
                ),
                _buildPeriodChip(
                  '7 jours',
                  _periodFilter == '7j',
                  () {
                    setState(() => _periodFilter = '7j');
                    _loadStatsData();
                  },
                ),
                _buildPeriodChip(
                  'Mois en cours',
                  _periodFilter == '30j',
                  () {
                    setState(() => _periodFilter = '30j');
                    _loadStatsData();
                  },
                ),
                _buildPeriodChip(
                  'Personnalisé',
                  _periodFilter == 'custom',
                  () async {
                    final picked = await showDateRangePicker(
                      context: context,
                      firstDate: DateTime(2025),
                      lastDate: DateTime(2027),
                    );
                    if (picked != null) {
                      setState(() {
                        _periodFilter = 'custom';
                        _selectedDateRange = picked;
                      });
                      _loadStatsData();
                    }
                  },
                ),
              ],
            ),
            if (_periodFilter == 'custom' && _selectedDateRange != null) ...[
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
            const SizedBox(height: 16),

            // 2. Building Filter
            const Text('FILTRER PAR BÂTIMENT', style: AppTypography.labelSmall),
            const SizedBox(height: 6),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildBuildingChip('Tous', _buildingFilter == 'Tous'),
                  ..._allBuildingsData.map((b) {
                    final name = b['name']?.toString() ?? 'Bâtiment';
                    final id = b['id']?.toString() ?? name;
                    return _buildBuildingChip(
                      name,
                      _buildingFilter == id || _buildingFilter == name,
                    );
                  }),
                ],
              ),
            ),
            const SizedBox(height: 20),

            _buildComparativeTable(filteredBuildings),
            const SizedBox(height: 24),

            // 3. Comparative Building list
            const Text('RAPPORTS COMPARATIFS', style: AppTypography.labelSmall),
            const SizedBox(height: 10),

            if (filteredBuildings.isEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.paper,
                  border: Border.all(color: AppColors.line),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: Text(
                    'Aucun bâtiment enregistré pour cette période',
                    style: TextStyle(
                      color: AppColors.inkSoft,
                      fontSize: 12,
                    ),
                  ),
                ),
              )
            else
              ...filteredBuildings.map((b) {
                final int mortality = _getMortalityForPeriod(b);
                return _buildBuildingStat(
                  letter: b['id'] as String? ?? 'A',
                  name: b['name'] as String? ?? 'Bâtiment',
                  volailler: b['volailler'] as String? ?? 'Volailler',
                  activitiesPercent: b['activitiesPercent'] as String? ?? '90%',
                  mortalityCount: mortality,
                  yieldVal: b['yield'] as String? ?? '95%',
                  isRed: b['isRed'] == true,
                );
              }),
            const SizedBox(height: 20),

            // 4. Bar chart
            const Text(
              'PRODUCTION D\'ŒUFS — HISTORIQUE',
              style: AppTypography.labelSmall,
            ),
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
            SizedBox(
              height: 180,
              child: _buildDynamicBarChart(),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildDynamicBarChart() {
    if (_layingChartData.isEmpty) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          _buildBar(0.15, 'L', false, 0, 0),
          _buildBar(0.15, 'M', false, 0, 0),
          _buildBar(0.15, 'M', false, 0, 0, isLight: true),
          _buildBar(0.15, 'J', false, 0, 0),
          _buildBar(0.15, 'V', false, 0, 0),
          _buildBar(0.15, 'S', false, 0, 0),
          _buildBar(0.15, 'D', false, 0, 0),
        ],
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: _layingChartData.map((item) {
        final double height = (item['relativeHeight'] as num?)?.toDouble() ?? 0.15;
        final String day = item['day']?.toString() ?? 'J';
        final bool isToday = item['isToday'] == true;
        final int eggs = (item['eggsCount'] as num?)?.toInt() ?? 0;
        final int plates = (item['platesCount'] as num?)?.toInt() ?? (eggs / 30).round();

        return _buildBar(height, day, isToday, eggs, plates);
      }).toList(),
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
                Text(
                  name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Volailler : $volailler  ·  $activitiesPercent d\'act. faites',
                  style: const TextStyle(
                    color: AppColors.inkSoft,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      size: 12,
                      color: mortalityCount > 10
                          ? AppColors.danger
                          : AppColors.inkSoft,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '$mortalityCount mort(s) sur la période',
                      style: TextStyle(
                        color: mortalityCount > 10
                            ? AppColors.danger
                            : AppColors.inkSoft,
                        fontSize: 10.5,
                        fontWeight: mortalityCount > 10
                            ? FontWeight.bold
                            : FontWeight.normal,
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

  Widget _buildComparativeTable(List<Map<String, dynamic>> buildings) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'TABLEAU COMPARATIF DES BÂTIMENTS',
          style: AppTypography.labelSmall,
        ),
        const SizedBox(height: 10),
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
                _buildTableHeaderRow(),
                ...buildings.map((b) {
                  final state = b['status'] as String? ?? 'Stable';
                  Color stateColor = AppColors.primary;
                  if (state == 'Excellent') stateColor = AppColors.primaryDark;
                  if (state == 'Vigilance') stateColor = AppColors.accent;
                  if (state == 'Critique') stateColor = AppColors.danger;

                  return _buildTableDataRow(
                    b['name'] as String? ?? 'Bâtiment',
                    b['birdsCount'] as String? ?? '3 000',
                    b['yield'] as String? ?? '90%',
                    b['mortality'] as String? ?? '0 mort',
                    state,
                    stateColor,
                  );
                }),
              ],
            ),
          ),
        ),
        const SizedBox(height: 18),
        const Text('RÉSUMÉ ANALYTIQUE', style: AppTypography.labelSmall),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _buildSummaryCard(
                'Œufs récoltés',
                _eggsForPeriod(),
                _periodLabel(),
                Icons.egg,
                AppColors.primary,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildSummaryCard(
                'Mortalité totale',
                _mortalityForPeriod(),
                _periodLabel(),
                Icons.warning,
                AppColors.danger,
              ),
            ),
          ],
        ),
      ],
    );
  }

  TableRow _buildTableHeaderRow() {
    return TableRow(
      decoration: const BoxDecoration(color: Color(0xFFF1F1EB)),
      children: ['Bâtiment', 'Volailles', 'Taux ponte', 'Mortalité', 'Statut']
          .map(
            (label) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
              child: Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 10,
                  color: AppColors.primaryDark,
                ),
              ),
            ),
          )
          .toList(),
    );
  }

  TableRow _buildTableDataRow(
    String building,
    String birds,
    String rate,
    String mortality,
    String state,
    Color color,
  ) {
    return TableRow(
      children: [
        _buildTableCell(building, bold: true),
        _buildTableCell(birds),
        _buildTableCell(rate),
        _buildTableCell(
          mortality,
          color: color == AppColors.danger
              ? AppColors.danger
              : AppColors.inkSoft,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              state,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 9,
                color: color,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTableCell(String value, {bool bold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      child: Text(
        value,
        style: TextStyle(
          fontSize: 10,
          fontWeight: bold ? FontWeight.bold : FontWeight.normal,
          color: color ?? AppColors.ink,
        ),
      ),
    );
  }

  String _periodLabel() => _periodFilter == 'today'
      ? 'Aujourd’hui'
      : _periodFilter == '30j'
      ? 'Mois en cours'
      : '7 derniers jours';

  String _eggsForPeriod() {
    final eggs = (_statsSummary['totalEggs'] as num?)?.toInt() ?? 0;
    return _formatNumber(eggs);
  }

  String _mortalityForPeriod() {
    final deaths = (_statsSummary['totalDeaths'] as num?)?.toInt() ?? 0;
    return '$deaths ${deaths > 1 ? "sujets" : "sujet"}';
  }

  String _formatNumber(int val) {
    final str = val.toString();
    if (str.length <= 3) return str;
    final buffer = StringBuffer();
    int count = 0;
    for (int i = str.length - 1; i >= 0; i--) {
      buffer.write(str[i]);
      count++;
      if (count % 3 == 0 && i != 0) {
        buffer.write(' ');
      }
    }
    return buffer.toString().split('').reversed.join('');
  }

  Widget _buildSummaryCard(
    String title,
    String value,
    String period,
    IconData icon,
    Color color,
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
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.inkSoft,
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                Text(
                  period,
                  style: const TextStyle(fontSize: 9, color: AppColors.inkSoft),
                ),
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

  Widget _buildBuildingChip(String label, bool isSelected) {
    final String targetFilter = label == 'Tous'
        ? 'Tous'
        : label.replaceAll('Bât. ', '');
    return GestureDetector(
      onTap: () {
        setState(() => _buildingFilter = targetFilter);
        _loadStatsData();
      },
      child: Container(
        margin: const EdgeInsets.only(right: 6),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
            fontSize: 10.5,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : AppColors.inkSoft,
          ),
        ),
      ),
    );
  }

  Widget _buildBar(
    double heightFactor,
    String label,
    bool highlight,
    int eggCount,
    int plateCount, {
    bool isLight = false,
  }) {
    Color barColor = AppColors.primary;
    if (highlight) barColor = AppColors.accent;
    if (isLight) barColor = AppColors.primaryLight;

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
          height: 120 * heightFactor.clamp(0.2, 1.0),
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

