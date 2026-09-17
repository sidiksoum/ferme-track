import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../config/theme/app_theme.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/services/socket_client_service.dart';
import '../../../../data/datasources/remote/api_client.dart';

class T3StockView extends StatefulWidget {
  const T3StockView({super.key});

  @override
  State<T3StockView> createState() => _T3StockViewState();
}

class _T3StockViewState extends State<T3StockView> {
  final ApiClient _apiClient = getIt<ApiClient>();
  final SocketClientService _socketService = getIt<SocketClientService>();
  StreamSubscription? _socketSubscription;

  bool _isLoading = false;
  final List<Map<String, dynamic>> _stockItems = [];

  @override
  void initState() {
    super.initState();
    _loadStocks();

    _socketSubscription = _socketService.allEvents.listen((event) {
      final evt = event['event']?.toString() ?? '';
      if (evt.contains('stock') ||
          evt.contains('order') ||
          evt.contains('task') ||
          evt.contains('sale') ||
          evt.contains('reception') ||
          evt.contains('activity')) {
        if (mounted) {
          _loadStocks(forceRefresh: true);
        }
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Silent background re-validation on view activation
    _loadStocks();
  }

  @override
  void dispose() {
    _socketSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadStocks({bool forceRefresh = false}) async {
    if (!mounted) return;
    if (_stockItems.isEmpty) {
      setState(() => _isLoading = true);
    }
    try {
      final response = await _apiClient.get(
        '/stocks',
        queryParameters: {'category': 'farm'},
        forceRefresh: forceRefresh,
        useCache: true,
      );
      if (!mounted || response is! List) return;

      setState(() {
        _stockItems
          ..clear()
          ..addAll(
            response
                .whereType<Map>()
                .where((item) {
                  final name = item['name']?.toString().toLowerCase() ?? '';
                  final cat = item['category']?.toString().toLowerCase() ?? '';
                  // Exclure les stocks d'œufs (gérés par le magasinier) du stock ferme technicien
                  if (name.contains('oeuf') ||
                      name.contains('œuf') ||
                      name.contains('alveole') ||
                      cat == 'egg' ||
                      cat == 'sales_product') {
                    return false;
                  }
                  return true;
                })
                .map((item) {
                  final qty = (item['quantity'] as num?)?.toDouble() ?? 0.0;
                  final threshold =
                      (item['alertThreshold'] as num?)?.toDouble() ?? 10.0;
                  final status =
                      item['status']?.toString() ??
                      (qty <= 10.0
                          ? 'Critique'
                          : (qty <= 25.0 ? 'Bas' : 'OK'));
                  final percent =
                      (item['percent'] as num?)?.toDouble() ??
                      (qty / (threshold * 3)).clamp(0.05, 1.0);

                  return {
                    'id': item['id']?.toString() ?? '',
                    'name': item['name']?.toString() ?? 'Article',
                    'quantity': qty.toInt(),
                    'unit': item['unit']?.toString() ?? 'unités',
                    'status': status,
                    'percent': percent,
                    'alertThreshold': threshold,
                  };
                }),
          );
      });
    } catch (_) {
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _loadStocks,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'MÉDICAMENTS & STOCKS FERME',
                  style: AppTypography.labelSmall,
                ),
                if (_isLoading)
                  const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            if (_stockItems.isEmpty && !_isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Text(
                    'Aucun article de stock enregistré.',
                    style: TextStyle(color: AppColors.inkSoft),
                  ),
                ),
              )
            else
              ..._stockItems.map((item) {
                final status = item['status']?.toString() ?? 'OK';
                Color progressColor = AppColors.primary;
                if (status == 'Critique') {
                  progressColor = AppColors.danger;
                } else if (status == 'Bas') {
                  progressColor = AppColors.accent;
                }

                return _buildStockItem(
                  item['name'],
                  item['quantity'],
                  item['unit'],
                  status,
                  item['percent'],
                  progressColor,
                );
              }),
          ],
        ),
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
      padding: const EdgeInsets.only(bottom: 16),
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
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: progressColor.withValues(alpha: 0.12),
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
              '$quantity $unit disponibles (Seuil critique : 10)',
              style: const TextStyle(color: AppColors.inkSoft, fontSize: 12),
            ),
            const SizedBox(height: 8),
            Container(
              height: 7,
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFFEAEAE3),
                borderRadius: BorderRadius.circular(5),
              ),
              alignment: Alignment.centerLeft,
              child: FractionallySizedBox(
                widthFactor: percent.clamp(0.0, 1.0),
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
}
