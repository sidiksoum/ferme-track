import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../config/theme/app_theme.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/services/socket_client_service.dart';
import '../../../../data/datasources/remote/api_client.dart';
import '../../../providers/auth_provider.dart';
import '../../../shared/widgets/common_widgets.dart';

class D3ActivitiesView extends StatefulWidget {
  const D3ActivitiesView({super.key});

  @override
  State<D3ActivitiesView> createState() => _D3ActivitiesViewState();
}

class _D3ActivitiesViewState extends State<D3ActivitiesView> {
  final ApiClient _apiClient = getIt<ApiClient>();
  final SocketClientService _socketService = getIt<SocketClientService>();
  StreamSubscription? _socketSubscription;

  List<Map<String, dynamic>> _activities = [];
  List<Map<String, String>> _buildingOptions = [];
  bool _isLoading = false;
  String _activitiesBuildingFilter = 'all'; // all, A, B, C
  String _activitiesTab = 'planned'; // planned, done

  @override
  void initState() {
    super.initState();
    _loadBuildings();
    _loadActivities();

    // Écoute temps réel Socket.IO pour actualisation en arrière-plan
    _socketSubscription = _socketService.allEvents.listen((event) {
      final evt = event['event']?.toString() ?? '';
      if (evt.contains('task') ||
          evt.contains('activit') ||
          evt.contains('order') ||
          evt.contains('anomal')) {
        if (mounted) {
          _loadActivities(forceRefresh: true);
        }
      }
    });
  }

  @override
  void dispose() {
    _socketSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadBuildings({bool forceRefresh = false}) async {
    if (!mounted) return;
    if (_buildingOptions.isNotEmpty && !forceRefresh) {
      return;
    }
    try {
      final farmId = context.read<AuthNotifier>().currentUser?.farmId;
      final response = await _apiClient.get(
        '/buildings',
        queryParameters: (farmId != null && farmId.isNotEmpty) ? {'farm_id': farmId} : null,
        forceRefresh: forceRefresh,
        useCache: true,
      );

      if (!mounted || response is! List) return;

      setState(() {
        _buildingOptions = response.whereType<Map>().map((item) => {
          'id': item['id']?.toString() ?? '',
          'name': item['name']?.toString() ?? 'Bâtiment',
        }).toList();
      });
    } catch (_) {}
  }

  Future<void> _loadActivities({bool forceRefresh = false}) async {
    if (!mounted) return;
    if (_activities.isEmpty) {
      setState(() => _isLoading = true);
    }
    try {
      final response = await _apiClient.get(
        '/activities',
        forceRefresh: forceRefresh,
        useCache: true,
      );
      if (!mounted || response is! List) return;
      setState(() {
        _activities =
            response.whereType<Map>().map((raw) {
              final item = Map<String, dynamic>.from(raw);
              final status = item['status']?.toString().toLowerCase();
              return {
                ...item,
                'status': (status == 'done' || status == 'completed')
                    ? TaskStatus.done
                    : (status == 'pending_validation' || status == 'submitted')
                    ? TaskStatus.pendingValidation
                    : status == 'partial'
                    ? TaskStatus.partial
                    : status == 'in_progress'
                    ? TaskStatus.inProgress
                    : status == 'late'
                    ? TaskStatus.late
                    : TaskStatus.todo,
                'buildingId': item['buildingId']?.toString() ?? item['building_id']?.toString() ?? '',
                'building': item['building']?.toString() ?? '',
                'buildingName':
                    item['buildingName']?.toString() ??
                    item['building']?.toString() ??
                    'Bâtiment non renseigné',
                'responsibleName':
                    item['responsibleName']?.toString() ??
                    'Responsable non renseigné',
              };
            }).toList()..sort(
              (a, b) => (b['scheduledDate']?.toString() ?? '').compareTo(
                a['scheduledDate']?.toString() ?? '',
              ),
            );
      });
    } catch (_) {
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _normalizeBuildingValue(String? value) {
    if (value == null) return '';
    return value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
  }

  bool _matchesBuildingFilter(Map<String, dynamic> act) {
    if (_activitiesBuildingFilter == 'all' || _activitiesBuildingFilter == 'Tous') return true;

    final filter = _activitiesBuildingFilter.trim();
    final filterKey = _normalizeBuildingValue(filter);
    if (filterKey.isEmpty) return true;

    final buildingId = act['buildingId']?.toString() ?? act['building_id']?.toString() ?? act['idBuilding']?.toString() ?? '';
    final buildingName = act['buildingName']?.toString() ?? act['building']?.toString() ?? '';

    if (buildingId == filter || buildingName == filter) return true;

    final normId = _normalizeBuildingValue(buildingId);
    final normName = _normalizeBuildingValue(buildingName);

    return normId == filterKey ||
        normName == filterKey ||
        normName.contains(filterKey) ||
        filterKey.contains(normName);
  }

  @override
  Widget build(BuildContext context) {
    // Filter list
    final filtered = _activities.where((act) {
      if (!_matchesBuildingFilter(act)) {
        return false;
      }
      if (_activitiesTab == 'planned') {
        return act['status'] == TaskStatus.todo ||
            act['status'] == TaskStatus.inProgress ||
            act['status'] == TaskStatus.late ||
            act['status'] == TaskStatus.partial ||
            act['status'] == TaskStatus.pendingValidation;
      } else {
        return act['status'] == TaskStatus.done;
      }
    }).toList();

    return Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Sub tabs
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFEFEFE7),
              borderRadius: BorderRadius.circular(11),
            ),
            padding: const EdgeInsets.all(3),
            child: Row(
              children: [
                Expanded(
                  child: _buildSubTabButton(
                    'À faire / En cours',
                    _activitiesTab == 'planned',
                    () => setState(() => _activitiesTab = 'planned'),
                  ),
                ),
                Expanded(
                  child: _buildSubTabButton(
                    'Réalisées',
                    _activitiesTab == 'done',
                    () => setState(() => _activitiesTab = 'done'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Filters row
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip(
                  'Tous',
                  _activitiesBuildingFilter == 'all',
                  () => setState(() => _activitiesBuildingFilter = 'all'),
                ),
                if (_buildingOptions.isNotEmpty)
                  ..._buildingOptions.map((option) {
                    final label = option['name']?.trim().isNotEmpty == true
                        ? option['name']!
                        : 'Bâtiment';
                    final value = option['id'] ?? option['name'] ?? 'all';
                    final isSelected = _activitiesBuildingFilter == value ||
                        _activitiesBuildingFilter == option['name'] ||
                        _activitiesBuildingFilter == option['id'];
                    return _buildFilterChip(
                      label,
                      isSelected,
                      () => setState(() => _activitiesBuildingFilter = value),
                    );
                  }),
              ],
            ),
          ),
          const SizedBox(height: 16),

          if (_isLoading)
            const Expanded(child: Center(child: CircularProgressIndicator()))
          else
            // List
            Expanded(
              child: RefreshIndicator(
                onRefresh: () => _loadActivities(forceRefresh: true),
                child: filtered.isEmpty
                    ? ListView(
                        children: const [
                          Padding(
                            padding: EdgeInsets.symmetric(vertical: 40),
                            child: Center(
                              child: Text(
                                'Aucune activité pour ces filtres.',
                                style: TextStyle(color: AppColors.inkSoft),
                              ),
                            ),
                          ),
                        ],
                      )
                    : ListView.builder(
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final act = filtered[index];
                          IconData icon = Icons.task_alt;
                          if (act['title'].toString().contains(
                            'Alimentation',
                          )) {
                            icon = Icons.restaurant;
                          } else if (act['title'].toString().contains(
                            'Ramassage',
                          )) {
                            icon = Icons.egg;
                          } else if (act['title'].toString().contains(
                            'Vaccination',
                          )) {
                            icon = Icons.healing;
                          }

                          return TaskCard(
                            icon: icon,
                            title: act['title'] as String,
                            meta:
                                '${act['buildingName']} · ${act['responsibleName']} · ${act['scheduledDate']?.toString().split('T').first ?? ''} · ${act['startTime'] ?? act['meta']} - ${act['endTime'] ?? ''}',
                            status: act['status'] as TaskStatus,
                            onTap: () => _showActivityDetail(context, act),
                          );
                        },
                      ),
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

  void _showActivityDetail(BuildContext context, Map<String, dynamic> act) {
    String formatDate(dynamic value) {
      final parsed = DateTime.tryParse(value?.toString() ?? '');
      if (parsed == null) return 'Non renseignée';
      return '${parsed.day.toString().padLeft(2, '0')}/${parsed.month.toString().padLeft(2, '0')}/${parsed.year}';
    }

    String formatDateTime(dynamic value) {
      final parsed = DateTime.tryParse(value?.toString() ?? '');
      if (parsed == null) return 'Non renseignée';
      return '${formatDate(parsed)} à ${parsed.hour.toString().padLeft(2, '0')}:${parsed.minute.toString().padLeft(2, '0')}';
    }

    String formatNotes(dynamic value) {
      if (value == null || value.toString().trim().isEmpty)
        return 'Aucune information';
      try {
        final decoded = jsonDecode(value.toString());
        if (decoded is Map) {
          final lines = <String>[];
          if (decoded['feedQtyKg'] != null)
            lines.add(
              'Quantité d\'aliment distribué : ${decoded['feedQtyKg']} kg',
            );
          if (decoded['dose'] != null)
            lines.add('Quantité dose utilisée : ${decoded['dose']}');
          if (decoded['weight'] != null)
            lines.add('Poids moyen constaté : ${decoded['weight']} kg');
          if (decoded['eggsProduced'] != null)
            lines.add('Œufs produits : ${decoded['eggsProduced']}');
          if (decoded['eggsBroken'] != null)
            lines.add('Œufs cassés : ${decoded['eggsBroken']}');
          if (decoded['eggsUnsellable'] != null)
            lines.add('Œufs non vendables : ${decoded['eggsUnsellable']}');
          if (decoded['eggsPlusGros'] != null)
            lines.add('Œufs plus gros : ${decoded['eggsPlusGros']}');
          if (decoded['eggsGros'] != null)
            lines.add('Œufs gros : ${decoded['eggsGros']}');
          if (decoded['eggsMoyen'] != null)
            lines.add('Œufs moyens : ${decoded['eggsMoyen']}');
          if (decoded['eggsPetit'] != null)
            lines.add('Œufs petits : ${decoded['eggsPetit']}');
          if (decoded['temperatureCelsius'] != null)
            lines.add(
              'Température constatée : ${decoded['temperatureCelsius']} °C',
            );
          if (decoded['notes'] != null &&
              decoded['notes'].toString().trim().isNotEmpty)
            lines.add('Observation : ${decoded['notes']}');
          if (decoded['confirmed'] == true)
            lines.add('Confirmation : tâche réalisée');
          return lines.join('\n');
        }
      } catch (_) {}
      return value.toString();
    }

    String statusLabel = 'À faire';
    if (act['status'] == TaskStatus.done) statusLabel = 'Fait';
    if (act['status'] == TaskStatus.pendingValidation)
      statusLabel = 'A valider';
    if (act['status'] == TaskStatus.partial) statusLabel = 'Partiel';
    if (act['status'] == TaskStatus.late) statusLabel = 'En retard';

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(act['title']),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Détails : ${act['notes'] ?? 'Aucun détail disponible.'}'),
              const SizedBox(height: 10),
              Text(
                'Responsable : ${act['responsibleName'] ?? 'Non renseigné'}',
              ),
              const SizedBox(height: 4),
              Text(
                'Bâtiment concerné : ${act['buildingName'] ?? 'Non renseigné'}',
              ),
              const SizedBox(height: 4),
              Text('Date programmée : ${formatDate(act['scheduledDate'])}'),
              Text('Début : ${act['startTime'] ?? 'Non renseigné'}'),
              Text('Fin prévue : ${act['endTime'] ?? 'Non renseignée'}'),
              Text('Soumise le : ${formatDateTime(act['submittedAt'])}'),
              Text('Validée le : ${formatDateTime(act['completedAt'])}'),
              if (act['submittedNotes'] != null)
                Text(
                  'Compte rendu volailler :\n${formatNotes(act['submittedNotes'])}',
                ),
              if (act['validationNotes'] != null)
                Text(
                  'Validation technicien :\n${formatNotes(act['validationNotes'])}',
                ),
              const SizedBox(height: 4),
              Text('Statut : $statusLabel'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Fermer'),
            ),
          ],
        );
      },
    );
  }
}
