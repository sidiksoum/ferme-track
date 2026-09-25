import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../config/theme/app_theme.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/services/socket_client_service.dart';
import '../../../../data/datasources/remote/api_client.dart';

class D7StatsTableView extends StatefulWidget {
  const D7StatsTableView({super.key});

  @override
  State<D7StatsTableView> createState() => _D7StatsTableViewState();
}

class _D7StatsTableViewState extends State<D7StatsTableView> {
  final ApiClient _apiClient = getIt<ApiClient>();
  final SocketClientService _socketService = getIt<SocketClientService>();
  StreamSubscription? _socketSubscription;

  String _periodFilter = '7j'; // today, 7j, 30j, custom
  String _buildingFilter = 'Tous';
  DateTimeRange? _selectedDateRange;

  List<Map<String, dynamic>> _buildingOptions = [];
  List<Map<String, dynamic>> _buildingsData = [];
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
    _loadBuildingOptions();
    _loadStatsData();

    _socketSubscription = _socketService.allEvents.listen((event) {
      final evt = event['event']?.toString() ?? '';
      if (evt.contains('egg') ||
          evt.contains('mortality') ||
          evt.contains('task') ||
          evt.contains('activity') ||
          evt.contains('stock') ||
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

  Future<void> _loadBuildingOptions() async {
    if (!mounted) return;
    try {
      final response = await _apiClient.get('/buildings', useCache: true);
      if (!mounted || response is! List) return;
      setState(() {
        _buildingOptions = response.whereType<Map>().map((item) => {
          'id': item['id']?.toString() ?? '',
          'name': item['name']?.toString() ?? 'Bâtiment',
        }).toList();
      });
    } catch (_) {}
  }

  Future<void> _loadStatsData({bool forceRefresh = false}) async {
    if (!mounted) return;
    try {
      final queryParams = <String, dynamic>{
        'period': _periodFilter,
        if (_buildingFilter != 'Tous') 'buildingId': _buildingFilter,
      };
      if (_periodFilter == 'custom' && _selectedDateRange != null) {
        queryParams['start_date'] = _selectedDateRange!.start.toIso8601String();
        queryParams['end_date'] = _selectedDateRange!.end.toIso8601String();
      }

      final response = await _apiClient.get(
        '/director/stats/comparative',
        queryParameters: queryParams,
        forceRefresh: forceRefresh,
        useCache: true,
      );

      if (!mounted || response is! Map) return;

      final buildings = response['buildings'] as List? ?? [];
      final chart = response['layingChart'] as List? ?? [];
      final summary = response['summary'] as Map? ?? {};

      setState(() {
        _buildingsData = buildings
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

  Color _getStatusColor(String status, String? hexColor) {
    if (hexColor != null && hexColor.isNotEmpty) {
      if (hexColor.startsWith('#')) {
        final hex = hexColor.replaceAll('#', '');
        if (hex.length == 6) {
          return Color(int.parse('0xFF$hex'));
        }
      }
    }
    switch (status) {
      case 'Excellent':
        return AppColors.primaryDark;
      case 'Stable':
        return AppColors.primary;
      case 'Vigilance':
        return AppColors.accent;
      case 'Critique':
        return AppColors.danger;
      default:
        return AppColors.primary;
    }
  }

  String _normalizeBuildingValue(String? value) {
    if (value == null) return '';
    return value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
  }

  bool _matchesBuildingFilter(Map<String, dynamic> building) {
    if (_buildingFilter == 'Tous' || _buildingFilter == 'all') return true;

    final filterKey = _normalizeBuildingValue(_buildingFilter);
    if (filterKey.isEmpty) return true;

    final id = building['id']?.toString() ?? '';
    final name = building['name']?.toString() ?? '';
    final bName = building['buildingName']?.toString() ?? '';

    if (_buildingFilter == id || _buildingFilter == name || _buildingFilter == bName) {
      return true;
    }

    final normId = _normalizeBuildingValue(id);
    final normName = _normalizeBuildingValue(name);
    final normBName = _normalizeBuildingValue(bName);

    return normId == filterKey ||
        normName == filterKey ||
        normBName == filterKey ||
        normName.contains(filterKey) ||
        filterKey.contains(normName);
  }

  @override
  Widget build(BuildContext context) {
    final filteredBuildings = _buildingsData.where(_matchesBuildingFilter).toList();

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
            const Text('FILTRER PAR BÂTIMENT', style: AppTypography.labelSmall),
            const SizedBox(height: 6),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip(
                    'Tous',
                    _buildingFilter == 'Tous',
                    () {
                      setState(() => _buildingFilter = 'Tous');
                      _loadStatsData(forceRefresh: true);
                    },
                  ),
                  if (_buildingOptions.isNotEmpty)
                    ..._buildingOptions.map((option) {
                      final label = option['name']?.toString() ?? 'Bâtiment';
                      final value = option['id']?.toString() ?? label;
                      final isSelected = _buildingFilter == value ||
                          _buildingFilter == option['id'] ||
                          _buildingFilter == option['name'];
                      return _buildFilterChip(
                        label,
                        isSelected,
                        () {
                          setState(() => _buildingFilter = value);
                          _loadStatsData(forceRefresh: true);
                        },
                      );
                    }),
                ],
              ),
            ),
            const SizedBox(height: 16),

            const Text(
              'TABLEAU COMPARATIF DES BÂTIMENTS',
              style: AppTypography.labelSmall,
            ),
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
                    horizontalInside: BorderSide(
                      color: AppColors.line,
                      width: 1,
                    ),
                  ),
                  children: [
                    // Table Header
                    _buildHeaderRow(),
                    // Dynamic Data Rows
                    if (filteredBuildings.isEmpty)
                      const TableRow(
                        children: [
                          Padding(
                            padding: EdgeInsets.symmetric(
                              vertical: 20,
                              horizontal: 8,
                            ),
                            child: Text(
                              'Aucun bâtiment trouvé',
                              style: TextStyle(
                                color: AppColors.inkSoft,
                                fontSize: 11,
                              ),
                            ),
                          ),
                          SizedBox(),
                          SizedBox(),
                          SizedBox(),
                          SizedBox(),
                        ],
                      )
                    else
                      ...filteredBuildings.map((b) {
                        final status = b['status']?.toString() ?? 'Stable';
                        final hexColor = b['statusColorHex']?.toString();
                        final statusColor = _getStatusColor(status, hexColor);
                        final name =
                            b['buildingName']?.toString() ?? 'Bâtiment';
                        final birds = b['birdsCount']?.toString() ?? '0';
                        final rate = b['layingRate']?.toString() ?? '0%';
                        final mort = b['mortality']?.toString() ?? '0 mort';

                        return _buildDataRow(
                          name,
                          birds,
                          rate,
                          mort,
                          status,
                          statusColor,
                        );
                      }),
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
                        : (_periodFilter == '30j'
                              ? 'Mois en cours'
                              : '7 derniers jours'),
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
                        : (_periodFilter == '30j'
                              ? 'Mois en cours'
                              : '7 derniers jours'),
                    Icons.warning,
                    AppColors.danger,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Production chart
            const Text(
              'PRODUCTION D\'ŒUFS — HISTORIQUE HEBDOMADAIRE',
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
              child: _buildDynamicChart(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDynamicChart() {
    if (_layingChartData.isEmpty) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          _buildChartBar(0.15, 'L', false, 0, 0),
          _buildChartBar(0.15, 'M', false, 0, 0),
          _buildChartBar(0.15, 'M', false, 0, 0, isLight: true),
          _buildChartBar(0.15, 'J', false, 0, 0),
          _buildChartBar(0.15, 'V', false, 0, 0),
          _buildChartBar(0.15, 'S', false, 0, 0),
          _buildChartBar(0.15, 'D', false, 0, 0),
        ],
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: _layingChartData.map((item) {
        final double height =
            (item['relativeHeight'] as num?)?.toDouble() ?? 0.15;
        final String day = item['day']?.toString() ?? 'J';
        final bool isToday = item['isToday'] == true;
        final int eggs = (item['eggsCount'] as num?)?.toInt() ?? 0;
        final int plates =
            (item['platesCount'] as num?)?.toInt() ?? (eggs / 30).round();

        return _buildChartBar(height, day, isToday, eggs, plates);
      }).toList(),
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
    final isDanger = mortalite.contains('35') ||
        mortalite.contains('20') ||
        statusColor == AppColors.danger;

    return TableRow(
      children: [
        _buildCell(bat, isBold: true),
        _buildCell(volailles),
        _buildCell(ponte),
        _buildCell(
          mortalite,
          textColor: isDanger ? AppColors.danger : AppColors.inkSoft,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
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

  String _getEggsCollected() {
    final eggs = (_statsSummary['totalEggs'] as num?)?.toInt() ?? 0;
    return _formatNumber(eggs);
  }

  String _getMortalityTotalText() {
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
              color: iconColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppColors.inkSoft,
                  ),
                ),
                Text(
                  val,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  period,
                  style: const TextStyle(
                    fontSize: 9,
                    color: AppColors.inkSoft,
                  ),
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

  Widget _buildFilterChip(String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 7),
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
            fontWeight: FontWeight.w500,
            color: isSelected ? Colors.white : AppColors.inkSoft,
          ),
        ),
      ),
    );
  }

  Widget _buildChartBar(
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
          height: 120 * heightFactor.clamp(0.15, 1.0),
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

