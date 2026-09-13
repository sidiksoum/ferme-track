import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../config/theme/app_theme.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/interfaces/network_checker.dart';
import '../../../../core/services/offline_sync_service.dart';
import '../../../../core/services/socket_client_service.dart';
import '../../../../data/datasources/remote/api_client.dart';
import '../../../shared/widgets/common_widgets.dart';

class M3EggReceptionView extends StatefulWidget {
  const M3EggReceptionView({super.key});

  @override
  State<M3EggReceptionView> createState() => _M3EggReceptionViewState();
}

class _M3EggReceptionViewState extends State<M3EggReceptionView> {
  final ApiClient _apiClient = getIt<ApiClient>();
  final SocketClientService _socketService = getIt<SocketClientService>();
  final OfflineSyncService _offlineSyncService = getIt<OfflineSyncService>();
  final NetworkChecker _networkChecker = getIt<NetworkChecker>();
  StreamSubscription? _socketSubscription;

  String _activeTab = 'pending'; // pending, validated
  Map<String, dynamic>? _selectedReceptionToValidate;
  bool _isLoading = false;
  bool _isValidating = false;

  // Active validation states & controllers
  int _verifiedCount = 0;
  int _formatPetit = 0;
  int _formatMoyen = 0;
  int _formatGros = 0;
  int _formatPlusGros = 0;

  final TextEditingController _verifiedCountController =
      TextEditingController();
  final TextEditingController _commentController = TextEditingController();
  final TextEditingController _petitController = TextEditingController();
  final TextEditingController _moyenController = TextEditingController();
  final TextEditingController _grosController = TextEditingController();
  final TextEditingController _plusGrosController = TextEditingController();

  final List<Map<String, dynamic>> _pendingReceptions = [];
  final List<Map<String, dynamic>> _validatedReceptions = [];

  int get _totalRepartition {
    return _formatPetit + _formatMoyen + _formatGros + _formatPlusGros;
  }

  @override
  void initState() {
    super.initState();
    _loadReceptions();

    // Écoute temps réel Socket.IO pour rafraîchissement instantané
    _socketSubscription = _socketService.allEvents.listen((event) {
      final evt = event['event']?.toString() ?? '';
      if (evt == 'stock:updated' || evt.contains('reception') || evt.contains('egg')) {
        if (mounted) {
          _loadReceptions(forceRefresh: true);
        }
      }
    });
  }

  Future<void> _loadReceptions({bool forceRefresh = false}) async {
    if (!mounted) return;
    if (_pendingReceptions.isEmpty && _validatedReceptions.isEmpty) {
      setState(() => _isLoading = true);
    }
    try {
      final response = await _apiClient.get(
        '/magasinier/egg-exits',
        forceRefresh: forceRefresh,
        useCache: true,
      );
      if (!mounted || response is! List) return;

      _pendingReceptions.clear();
      _validatedReceptions.clear();

      for (final item in response.whereType<Map>()) {
        final status = item['status']?.toString() ?? 'pending';
        final qty = (item['quantity'] as num?)?.toInt() ?? 0;
        final timeStr = item['date']?.toString().split('T').last.substring(0, 5) ?? '08:00';

        final mapItem = {
          'id': item['id']?.toString() ?? '',
          'building': item['building']?.toString() ?? 'A',
          'volailler': item['responsible']?.toString() ?? 'Personnel',
          'announcedCount': qty,
          'time': timeStr,
          'verifiedCount': qty,
          'plusGros': (item['plusGros'] as num?)?.toInt() ?? 0,
          'gros': (item['gros'] as num?)?.toInt() ?? 0,
          'moyen': (item['moyen'] as num?)?.toInt() ?? 0,
          'petit': (item['petit'] as num?)?.toInt() ?? 0,
          'comment': item['comment']?.toString() ?? '',
          'status': status,
        };

        if (status == 'validated') {
          _validatedReceptions.add(mapItem);
        } else {
          _pendingReceptions.add(mapItem);
        }
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _socketSubscription?.cancel();
    _verifiedCountController.dispose();
    _commentController.dispose();
    _petitController.dispose();
    _moyenController.dispose();
    _grosController.dispose();
    _plusGrosController.dispose();
    super.dispose();
  }

  void _startValidation(Map<String, dynamic> reception) {
    setState(() {
      _selectedReceptionToValidate = reception;
      _verifiedCount = (reception['verifiedCount'] as num?)?.toInt() ?? (reception['announcedCount'] as num?)?.toInt() ?? 0;
      _formatPetit = (reception['petit'] ?? reception['formatPetit'] ?? 0) as int;
      _formatMoyen = (reception['moyen'] ?? reception['formatMoyen'] ?? 0) as int;
      _formatGros = (reception['gros'] ?? reception['formatGros'] ?? 0) as int;
      _formatPlusGros = (reception['plusGros'] ?? reception['formatPlusGros'] ?? 0) as int;
      _commentController.clear();

      _verifiedCountController.text = _verifiedCount.toString();
      _petitController.text = _formatPetit.toString();
      _moyenController.text = _formatMoyen.toString();
      _grosController.text = _formatGros.toString();
      _plusGrosController.text = _formatPlusGros.toString();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_selectedReceptionToValidate != null) {
      return _buildValidationForm();
    }
    return _buildTabsAndLists();
  }

  Widget _buildTabsAndLists() {
    return Column(
      children: [
        // Tabs
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
                    'En attente (${_pendingReceptions.length})',
                    _activeTab == 'pending',
                    () => setState(() => _activeTab = 'pending'),
                  ),
                ),
                Expanded(
                  child: _buildSubTabButton(
                    'Validées (${_validatedReceptions.length})',
                    _activeTab == 'validated',
                    () => setState(() => _activeTab = 'validated'),
                  ),
                ),
              ],
            ),
          ),
        ),

        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  children: [
                    if (_activeTab == 'pending') ...[
                      if (_pendingReceptions.isEmpty)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 40),
                            child: Text(
                              'Aucune réception en attente.',
                              style: TextStyle(color: AppColors.inkSoft),
                            ),
                          ),
                        ),
                      ..._pendingReceptions.map((item) => _buildPendingCard(item)),
                    ] else ...[
                      if (_validatedReceptions.isEmpty)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 40),
                            child: Text(
                              'Aucune réception validée.',
                              style: TextStyle(color: AppColors.inkSoft),
                            ),
                          ),
                        ),
                      ..._validatedReceptions.map(
                        (item) => _buildValidatedCard(item),
                      ),
                    ],
                  ],
                ),
        ),
      ],
    );
  }

  Widget _buildPendingCard(Map<String, dynamic> item) {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.paper,
        border: Border.all(color: AppColors.line),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Réception des œufs — Bâtiment ${item['building']}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${item['volailler']} — Bât. ${item['building']} · annoncé ${item['announcedCount']} œufs',
                  style: const TextStyle(
                    color: AppColors.inkSoft,
                    fontSize: 11.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Plus gros ${item['plusGros']} · Gros ${item['gros']} · Moyen ${item['moyen']} · Petit ${item['petit']}',
                  style: const TextStyle(
                    color: AppColors.primaryDark,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: () => _startValidation(item),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              minimumSize: Size.zero,
            ),
            child: const Text('À valider', style: TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Widget _buildValidatedCard(Map<String, dynamic> item) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _showValidatedDetailsDialog(item),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: AppColors.paper,
            border: Border.all(color: AppColors.line),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Réception des œufs — Bâtiment ${item['building']}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${item['volailler']} — Bât. ${item['building']} · annoncé ${item['announcedCount']} œufs',
                      style: const TextStyle(
                        color: AppColors.inkSoft,
                        fontSize: 11.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Plus gros ${item['plusGros'] ?? item['formatPlusGros'] ?? 0} · Gros ${item['gros'] ?? item['formatGros'] ?? 0} · Moyen ${item['moyen'] ?? item['formatMoyen'] ?? 0} · Petit ${item['petit'] ?? item['formatPetit'] ?? 0}',
                      style: const TextStyle(
                        color: AppColors.primaryDark,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.successLight,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'Validée',
                      style: TextStyle(
                        color: AppColors.primaryDark,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.chevron_right, size: 18, color: AppColors.inkSoft),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showValidatedDetailsDialog(Map<String, dynamic> item) {
    final building = item['building']?.toString() ?? 'A';
    final volailler = item['volailler']?.toString() ?? 'Personnel';
    final announced = (item['announcedCount'] as num?)?.toInt() ?? 0;
    final verified = (item['verifiedCount'] as num?)?.toInt() ?? announced;
    final petit = (item['petit'] as num?)?.toInt() ?? 0;
    final moyen = (item['moyen'] as num?)?.toInt() ?? 0;
    final gros = (item['gros'] as num?)?.toInt() ?? 0;
    final plusGros = (item['plusGros'] as num?)?.toInt() ?? 0;
    final comment = item['comment']?.toString() ?? '';
    final timeStr = item['time']?.toString() ?? '';

    final totalCalibres = petit + moyen + gros + plusGros;
    final effectiveTotal = totalCalibres > 0 ? totalCalibres : verified;
    final deviation = announced - effectiveTotal;

    final platesCount = effectiveTotal ~/ 30;
    final remainingEggs = effectiveTotal % 30;

    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          contentPadding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Réception Validée',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.ink,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Détails du contrôle magasin',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: AppColors.inkSoft,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.successLight,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle, size: 13, color: AppColors.primaryDark),
                    SizedBox(width: 4),
                    Text(
                      'Validée',
                      style: TextStyle(
                        color: AppColors.primaryDark,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Divider(height: 1),
                const SizedBox(height: 12),

                // Card info bâtiment & volailler
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.line),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.egg_outlined, color: AppColors.primaryDark, size: 18),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Bâtiment $building — $volailler',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12.5,
                                color: AppColors.ink,
                              ),
                            ),
                            if (timeStr.isNotEmpty)
                              Text(
                                'Heure de réception : $timeStr',
                                style: const TextStyle(fontSize: 11, color: AppColors.inkSoft),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Section Quantités vérifiées
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.paper,
                          border: Border.all(color: AppColors.line),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Annoncé volailler', style: TextStyle(fontSize: 10, color: AppColors.inkSoft)),
                            const SizedBox(height: 2),
                            Text(
                              '$announced œufs',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.ink),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight.withValues(alpha: 0.3),
                          border: Border.all(color: AppColors.primaryLight),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Vérifié magasin', style: TextStyle(fontSize: 10, color: AppColors.primaryDark, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 2),
                            Text(
                              '$effectiveTotal œufs',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.primaryDark),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Équivalence plateaux
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF4F6F0),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.grid_view, size: 15, color: AppColors.primaryDark),
                      const SizedBox(width: 6),
                      Text(
                        'Équivalent : $platesCount plateaux de 30${remainingEggs > 0 ? " + $remainingEggs œufs" : ""}',
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryDark,
                        ),
                      ),
                    ],
                  ),
                ),

                if (deviation != 0) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.errorLight,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.warning_amber_rounded, size: 14, color: AppColors.danger),
                        const SizedBox(width: 6),
                        Text(
                          'Écart : ${deviation > 0 ? "-$deviation œufs manquants" : "+${-deviation} œufs excédent"}',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: AppColors.danger,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 14),

                // Grille des calibres
                const Text(
                  'RÉPARTITION PAR CALIBRE',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: AppColors.inkSoft,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(child: _buildCalibreCard('Petit (S)', petit)),
                    const SizedBox(width: 6),
                    Expanded(child: _buildCalibreCard('Moyen (M)', moyen)),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(child: _buildCalibreCard('Gros (L)', gros)),
                    const SizedBox(width: 6),
                    Expanded(child: _buildCalibreCard('Plus Gros (XL)', plusGros)),
                  ],
                ),

                // Observations si présentes
                if (comment.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  const Text(
                    'OBSERVATIONS',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: AppColors.inkSoft,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.line),
                    ),
                    child: Text(
                      comment,
                      style: const TextStyle(fontSize: 11.5, color: AppColors.ink, fontStyle: FontStyle.italic),
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Fermer'),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCalibreCard(String label, int count) {
    final plates = count ~/ 30;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              color: AppColors.inkSoft,
            ),
          ),
          const SizedBox(height: 2),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$count',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: AppColors.ink,
                ),
              ),
              Text(
                '$plates plat.',
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryDark,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildValidationForm() {
    final item = _selectedReceptionToValidate!;
    final int effectiveTotal = _totalRepartition > 0 ? _totalRepartition : _verifiedCount;
    final int announced = (item['announcedCount'] as num?)?.toInt() ?? 0;
    final int deviation = announced - effectiveTotal;
    final bool canValidate = effectiveTotal > 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(14),
      child: Container(
        padding: const EdgeInsets.all(14),
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
                  'Bâtiment ${item['building']} — ${item['volailler']}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () {
                    setState(() => _selectedReceptionToValidate = null);
                  },
                ),
              ],
            ),
            Text(
              'Arrivée ${item['time']} · Annoncé : ${item['announcedCount']} œufs',
              style: const TextStyle(color: AppColors.inkSoft, fontSize: 12),
            ),
            const SizedBox(height: 16),

            // Number of verified eggs
            AppInputBox(
              label: 'Nombre vérifié (Total reçu)',
              placeholder: 'Ex: $announced',
              inputType: TextInputType.number,
              controller: _verifiedCountController,
              onChanged: (val) {
                setState(() => _verifiedCount = int.tryParse(val) ?? 0);
              },
            ),
            const SizedBox(height: 10),

            // Deviation tag
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: deviation == 0
                        ? AppColors.successLight
                        : (deviation > 0
                            ? AppColors.warningLight
                            : AppColors.errorLight),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Text(
                    deviation == 0
                        ? 'Conforme : aucun écart (0 œuf)'
                        : (deviation > 0
                            ? 'Écart : -$deviation œufs (manquant/cassé)'
                            : 'Écart : +${-deviation} œufs (surplus)'),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: deviation == 0
                          ? AppColors.primaryDark
                          : (deviation > 0
                              ? AppColors.accent
                              : AppColors.danger),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Comment
            AppInputBox(
              label: 'Commentaire / Motif de l\'écart',
              placeholder: deviation != 0
                  ? 'Ex: ${deviation.abs()} œufs cassés pendant le transport...'
                  : 'Ex: Réception conforme sans anomalie...',
              controller: _commentController,
            ),
            const SizedBox(height: 16),

            const Text(
              'RÉPARTITION PAR CALIBRE (OBLIGATOIRE)',
              style: AppTypography.labelSmall,
            ),
            const SizedBox(height: 10),

            AppInputBox(
              label: 'Petit',
              placeholder: 'Ex: 50',
              inputType: TextInputType.number,
              controller: _petitController,
              onChanged: (val) {
                setState(() {
                  _formatPetit = int.tryParse(val) ?? 0;
                  if (_totalRepartition > 0 && (_verifiedCount == 0 || _verifiedCount == announced)) {
                    _verifiedCount = _totalRepartition;
                    _verifiedCountController.text = '$_totalRepartition';
                  }
                });
              },
            ),
            const SizedBox(height: 16),

            AppInputBox(
              label: 'Moyen',
              placeholder: 'Ex: 50',
              inputType: TextInputType.number,
              controller: _moyenController,
              onChanged: (val) {
                setState(() {
                  _formatMoyen = int.tryParse(val) ?? 0;
                  if (_totalRepartition > 0 && (_verifiedCount == 0 || _verifiedCount == announced)) {
                    _verifiedCount = _totalRepartition;
                    _verifiedCountController.text = '$_totalRepartition';
                  }
                });
              },
            ),
            const SizedBox(height: 16),

            AppInputBox(
              label: 'Gros',
              placeholder: 'Ex: 50',
              inputType: TextInputType.number,
              controller: _grosController,
              onChanged: (val) {
                setState(() {
                  _formatGros = int.tryParse(val) ?? 0;
                  if (_totalRepartition > 0 && (_verifiedCount == 0 || _verifiedCount == announced)) {
                    _verifiedCount = _totalRepartition;
                    _verifiedCountController.text = '$_totalRepartition';
                  }
                });
              },
            ),
            const SizedBox(height: 16),

            AppInputBox(
              label: 'Plus gros',
              placeholder: 'Ex: 50',
              inputType: TextInputType.number,
              controller: _plusGrosController,
              onChanged: (val) {
                setState(() {
                  _formatPlusGros = int.tryParse(val) ?? 0;
                  if (_totalRepartition > 0 && (_verifiedCount == 0 || _verifiedCount == announced)) {
                    _verifiedCount = _totalRepartition;
                    _verifiedCountController.text = '$_totalRepartition';
                  }
                });
              },
            ),
            const SizedBox(height: 16),

            // Total check
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: effectiveTotal > 0
                    ? AppColors.successLight
                    : AppColors.errorLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Total vérifié à intégrer au stock :',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryDark,
                    ),
                  ),
                  Text(
                    '$effectiveTotal œufs (${(effectiveTotal / 30).toStringAsFixed(1)} pl.)',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryDark,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: (!canValidate || _isValidating)
                    ? null
                    : () async {
                        setState(() => _isValidating = true);
                        showActionLoadingDialog(context, message: 'Validation de la réception...');
                        bool isOfflineQueued = false;
                        try {
                          final recId = item['id']?.toString() ?? '';
                          final int countToSave = effectiveTotal;
                          final commentText = _commentController.text.trim();
                          final finalComment = commentText.isNotEmpty
                              ? commentText
                              : (deviation != 0
                                  ? 'Réception validée avec écart de $deviation œufs'
                                  : 'Réception d\'œufs conforme');

                          final payload = {
                            'verifiedCount': countToSave,
                            'formatPetit': _formatPetit,
                            'formatMoyen': _formatMoyen,
                            'formatGrand': _formatGros + _formatPlusGros,
                            'comment': finalComment,
                          };

                          if (recId.isNotEmpty) {
                            final isOnline = await _networkChecker.hasConnection;
                            if (!isOnline) {
                              await _offlineSyncService.enqueueOperation(
                                endpoint: '/magasinier/receptions/$recId/validate',
                                method: 'PATCH',
                                payload: payload,
                                description: 'Validation réception œufs: $countToSave œufs (Bât. ${item['building']})',
                              );
                              isOfflineQueued = true;
                            } else {
                              await _apiClient.patch(
                                '/magasinier/receptions/$recId/validate',
                                data: payload,
                              );
                            }
                          }

                          if (mounted) {
                            Navigator.of(context, rootNavigator: true).pop(); // dismiss loading dialog
                            setState(() {
                              _pendingReceptions.remove(item);
                              _validatedReceptions.insert(0, {
                                'id': item['id'],
                                'building': item['building'],
                                'volailler': item['volailler'],
                                'announcedCount': item['announcedCount'],
                                'time': item['time'],
                                'verifiedCount': countToSave,
                                'comment': finalComment,
                                'formatPetit': _formatPetit,
                                'formatMoyen': _formatMoyen,
                                'formatGrand': _formatGros + _formatPlusGros,
                              });
                              _selectedReceptionToValidate = null;
                            });

                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                backgroundColor: isOfflineQueued ? Colors.orange : AppColors.syncGreen,
                                content: Text(
                                  isOfflineQueued
                                      ? 'Validation enregistrée hors-ligne (en attente de synchro) !'
                                      : 'Réception de $countToSave œufs validée et stock magasin mis à jour !',
                                ),
                              ),
                            );
                            _loadReceptions();
                          }
                        } catch (e) {
                          try {
                            final recId = item['id']?.toString() ?? '';
                            final int countToSave = effectiveTotal;
                            final commentText = _commentController.text.trim();
                            final finalComment = commentText.isNotEmpty
                                ? commentText
                                : (deviation != 0
                                    ? 'Réception validée avec écart de $deviation œufs'
                                    : 'Réception d\'œufs conforme');

                            final payload = {
                              'verifiedCount': countToSave,
                              'formatPetit': _formatPetit,
                              'formatMoyen': _formatMoyen,
                              'formatGrand': _formatGros + _formatPlusGros,
                              'comment': finalComment,
                            };
                            await _offlineSyncService.enqueueOperation(
                              endpoint: '/magasinier/receptions/$recId/validate',
                              method: 'PATCH',
                              payload: payload,
                              description: 'Validation réception œufs: $countToSave œufs (Bât. ${item['building']})',
                            );
                            if (mounted) {
                              Navigator.of(context, rootNavigator: true).pop();
                              setState(() {
                                _pendingReceptions.remove(item);
                                _validatedReceptions.insert(0, {
                                  'id': item['id'],
                                  'building': item['building'],
                                  'volailler': item['volailler'],
                                  'announcedCount': item['announcedCount'],
                                  'time': item['time'],
                                  'verifiedCount': countToSave,
                                  'comment': finalComment,
                                  'formatPetit': _formatPetit,
                                  'formatMoyen': _formatMoyen,
                                  'formatGrand': _formatGros + _formatPlusGros,
                                });
                                _selectedReceptionToValidate = null;
                              });
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  backgroundColor: Colors.orange,
                                  content: Text('Connexion instable : validation enregistrée localement pour synchronisation.'),
                                ),
                              );
                              _loadReceptions();
                            }
                          } catch (_) {
                            if (mounted) {
                              Navigator.of(context, rootNavigator: true).pop();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  backgroundColor: AppColors.danger,
                                  content: Text('Erreur de validation : $e'),
                                ),
                              );
                            }
                          }
                        } finally {
                          if (mounted) setState(() => _isValidating = false);
                        }
                      },
                child: const Text('Valider la réception'),
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
}
