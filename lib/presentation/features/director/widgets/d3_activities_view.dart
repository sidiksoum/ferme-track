import 'dart:convert';

import 'package:flutter/material.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../data/datasources/remote/api_client.dart';
import '../../../../config/theme/app_theme.dart';
import '../../../shared/widgets/common_widgets.dart';

class D3ActivitiesView extends StatefulWidget {
  const D3ActivitiesView({super.key});

  @override
  State<D3ActivitiesView> createState() => _D3ActivitiesViewState();
}

class _D3ActivitiesViewState extends State<D3ActivitiesView> {
  final ApiClient _apiClient = getIt<ApiClient>();
  List<Map<String, dynamic>> _activities = [];
  bool _isLoading = true;
  String _activitiesBuildingFilter = 'all'; // all, A, B, C
  String _activitiesTab = 'planned'; // planned, done

  @override
  void initState() {
    super.initState();
    _loadActivities();
  }

  Future<void> _loadActivities() async {
    try {
      final response = await _apiClient.get('/activities');
      if (!mounted || response is! List) return;
      setState(() {
        _activities =
            response.whereType<Map>().map((raw) {
              final item = Map<String, dynamic>.from(raw);
              final status = item['status']?.toString();
              return {
                ...item,
                'status': status == 'done'
                    ? TaskStatus.done
                    : status == 'pending_validation'
                    ? TaskStatus.pendingValidation
                    : status == 'partial'
                    ? TaskStatus.partial
                    : status == 'late'
                    ? TaskStatus.late
                    : TaskStatus.todo,
                'building': item['building']?.toString() ?? '',
                'buildingName':
                    item['buildingName']?.toString() ??
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
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Filter list
    final filtered = _activities.where((act) {
      if (_activitiesBuildingFilter != 'all' &&
          act['building'] != _activitiesBuildingFilter) {
        return false;
      }
      if (_activitiesTab == 'planned') {
        return act['status'] == TaskStatus.todo ||
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
                _buildFilterChip(
                  'Bât. A',
                  _activitiesBuildingFilter == 'A',
                  () => setState(() => _activitiesBuildingFilter = 'A'),
                ),
                _buildFilterChip(
                  'Bât. B',
                  _activitiesBuildingFilter == 'B',
                  () => setState(() => _activitiesBuildingFilter = 'B'),
                ),
                _buildFilterChip(
                  'Bât. C',
                  _activitiesBuildingFilter == 'C',
                  () => setState(() => _activitiesBuildingFilter = 'C'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          if (_isLoading)
            const Expanded(child: Center(child: CircularProgressIndicator()))
          else
            // List
            Expanded(
              child: filtered.isEmpty
                  ? const Center(
                      child: Text(
                        'Aucune activité pour ces filtres.',
                        style: TextStyle(color: AppColors.inkSoft),
                      ),
                    )
                  : ListView.builder(
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final act = filtered[index];
                        IconData icon = Icons.task_alt;
                        if (act['title'].toString().contains('Alimentation')) {
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
            lines.add('Quantité distribuée : ${decoded['feedQtyKg']} kg');
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
