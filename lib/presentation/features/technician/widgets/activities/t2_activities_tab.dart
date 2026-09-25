import 'dart:convert';
import 'package:flutter/material.dart';
import '../../../../../config/theme/app_theme.dart';
import '../../../../../core/di/service_locator.dart';
import '../../../../../data/datasources/remote/api_client.dart';
import '../../../../shared/widgets/common_widgets.dart';

class T2ActivitiesTab extends StatefulWidget {
  final List<Map<String, dynamic>> activities;
  final List<Map<String, String>> buildingOptions;
  final bool isLoading;
  final Future<void> Function() onRefresh;

  const T2ActivitiesTab({
    super.key,
    required this.activities,
    required this.buildingOptions,
    required this.isLoading,
    required this.onRefresh,
  });

  @override
  State<T2ActivitiesTab> createState() => _T2ActivitiesTabState();
}

class _T2ActivitiesTabState extends State<T2ActivitiesTab> {
  final ApiClient _apiClient = getIt<ApiClient>();
  String _activitiesTab =
      'in_progress'; // in_progress, pending_validation, done
  String _selectedBuildingFilter = 'all'; // all, A, A1, B, B1, C, D, E, F

  String _normalizeBuildingValue(String? value) {
    if (value == null) return '';
    return value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
  }

  bool _matchesBuildingFilter(Map<String, dynamic> act) {
    if (_selectedBuildingFilter == 'all' ||
        _selectedBuildingFilter == 'Tous' ||
        _selectedBuildingFilter == 'Tous Bât.')
      return true;

    final filter = _selectedBuildingFilter.trim();
    final filterKey = _normalizeBuildingValue(filter);
    if (filterKey.isEmpty) return true;

    final buildingId =
        act['buildingId']?.toString() ??
        act['building_id']?.toString() ??
        act['idBuilding']?.toString() ??
        '';
    final buildingName =
        act['buildingName']?.toString() ?? act['building']?.toString() ?? '';

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
    final filteredActivities =
        widget.activities.where((act) {
          if (!_matchesBuildingFilter(act)) {
            return false;
          }
          if (_activitiesTab == 'pending_validation') {
            return act['status'] == TaskStatus.pendingValidation;
          }
          if (_activitiesTab == 'done') {
            return act['status'] == TaskStatus.done;
          }
          return act['status'] == TaskStatus.inProgress ||
              act['status'] == TaskStatus.partial ||
              act['status'] == TaskStatus.late ||
              act['status'] == TaskStatus.todo;
        }).toList()..sort(
          (a, b) => (b['scheduledDate']?.toString() ?? '').compareTo(
            a['scheduledDate']?.toString() ?? '',
          ),
        );

    return Column(
      children: [
        // Sub tabs (En cours / A valider / Faite)
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
                    'En cours',
                    _activitiesTab == 'in_progress',
                    () => setState(() => _activitiesTab = 'in_progress'),
                  ),
                ),
                Expanded(
                  child: _buildSubTabButton(
                    'A valider',
                    _activitiesTab == 'pending_validation',
                    () => setState(() => _activitiesTab = 'pending_validation'),
                  ),
                ),
                Expanded(
                  child: _buildSubTabButton(
                    'Faite',
                    _activitiesTab == 'done',
                    () => setState(() => _activitiesTab = 'done'),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Building filter row
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip(
                  'Tous Bât.',
                  _selectedBuildingFilter == 'all',
                  () => setState(() => _selectedBuildingFilter = 'all'),
                ),
                if (widget.buildingOptions.isNotEmpty)
                  ...widget.buildingOptions.map((option) {
                    final label = option['name']?.trim().isNotEmpty == true
                        ? option['name']!
                        : 'Bâtiment';
                    final value = option['id'] ?? option['name'] ?? 'all';
                    final isSelected =
                        _selectedBuildingFilter == value ||
                        _selectedBuildingFilter == option['name'] ||
                        _selectedBuildingFilter == option['id'];
                    return _buildFilterChip(
                      label,
                      isSelected,
                      () => setState(() => _selectedBuildingFilter = value),
                    );
                  }),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),

        // Main listings
        Expanded(
          child: RefreshIndicator(
            onRefresh: widget.onRefresh,
            color: AppColors.primaryDark,
            backgroundColor: AppColors.paper,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              children: [
                const Text(
                  'ACTIVITÉS DE LA SEMAINE',
                  style: AppTypography.labelSmall,
                ),
                const SizedBox(height: 8),
                if (widget.isLoading)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (filteredActivities.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: Center(
                      child: Text(
                        'Aucune activité enregistrée.',
                        style: TextStyle(color: AppColors.inkSoft),
                      ),
                    ),
                  ),
                ...filteredActivities.map((act) {
                  IconData icon = Icons.task_alt;
                  final title = act['title'].toString().toLowerCase();
                  if (title.contains('aliment')) {
                    icon = Icons.restaurant;
                  } else if (title.contains('ramassage') ||
                      title.contains('oeuf') ||
                      title.contains('œuf')) {
                    icon = Icons.egg;
                  } else if (title.contains('vaccin') ||
                      title.contains('vitamine') ||
                      title.contains('deparasitant')) {
                    icon = Icons.healing;
                  }

                  return TaskCard(
                    icon: icon,
                    title: act['title'] ?? 'Activité',
                    meta:
                        '${act['buildingName']} · ${act['responsibleName']} · ${act['scheduledDate']?.toString().split('T').first ?? ''} · ${act['meta']} - ${act['endTime'] ?? ''}',
                    status: act['status'] ?? TaskStatus.todo,
                    onTap: () {
                      if (act['status'] == TaskStatus.pendingValidation) {
                        _showValidationDialog(act);
                      } else {
                        _showActivityDetails(act);
                      }
                    },
                  );
                }),
                const SizedBox(height: 80),
              ],
            ),
          ),
        ),
      ],
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

  // --- Verification Dialog for activities (Requires comment) ---
  void _showValidationDialog(Map<String, dynamic> act) {
    final commentController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(act['title'] ?? 'Validation de la tâche'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Assigné à : ${act['meta']}'),
                const SizedBox(height: 8),
                Text(
                  'Date programmée : ${_formatActivityDate(act['scheduledDate'])}',
                ),
                Text(
                  'Responsable : ${act['responsibleName'] ?? 'Non renseigné'}',
                ),
                Text('Bâtiment : ${act['buildingName'] ?? 'Non renseigné'}'),
                Text('Début : ${act['startTime'] ?? 'Non renseigné'}'),
                Text('Fin prévue : ${act['endTime'] ?? 'Non renseignée'}'),
                const SizedBox(height: 8),
                Text(
                  'Instructions : "${act['notes'] ?? 'Aucun détail disponible.'}"',
                ),
                if (act['submittedNotes'] != null)
                  Text(
                    'Compte rendu du volailler :\n${_formatActivityNotes(act['submittedNotes'])}',
                  ),
                const SizedBox(height: 14),
                const Text(
                  'Commentaire de réalisation (optionnel) :',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: commentController,
                  decoration: const InputDecoration(
                    hintText: 'Ex : Réalisé conformément au protocole.',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                await _confirmActivity(act, commentController.text.trim());
              },
              child: const Text('Confirmer la réalisation'),
            ),
          ],
        );
      },
    );
  }

  void _showActivityDetails(Map<String, dynamic> activity) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(activity['title'] as String? ?? 'Détails activité'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Date programmée : ${_formatActivityDate(activity['scheduledDate'])}',
              ),
              Text(
                'Responsable : ${activity['responsibleName'] ?? 'Non renseigné'}',
              ),
              Text('Bâtiment : ${activity['buildingName'] ?? 'Non renseigné'}'),
              Text(
                'Heure de programmation : ${activity['startTime'] ?? 'Non renseignée'}',
              ),
              Text(
                'Heure de fin prévue : ${activity['endTime'] ?? 'Non renseignée'}',
              ),
              Text(
                'Soumise par le volailler : ${_formatActivityTimestamp(activity['submittedAt'])}',
              ),
              Text(
                'Validée le : ${_formatActivityTimestamp(activity['completedAt'])}',
              ),
              const SizedBox(height: 12),
              Text('Instructions : ${activity['notes'] ?? 'Aucun détail'}'),
              if (activity['submittedNotes'] != null)
                Text(
                  'Compte rendu du volailler :\n${_formatActivityNotes(activity['submittedNotes'])}',
                ),
              if (activity['validationNotes'] != null)
                Text(
                  'Validation technicien :\n${_formatActivityNotes(activity['validationNotes'])}',
                ),
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

  Future<void> _confirmActivity(
    Map<String, dynamic> activity,
    String comment,
  ) async {
    final id = activity['id']?.toString();
    if (id == null || id.isEmpty) return;
    showActionLoadingDialog(context, message: 'Validation en cours...');
    try {
      await _apiClient.post(
        '/activities/$id/confirm',
        queryParameters: {'comment': comment},
        data: {'comment': comment},
      );
      widget.onRefresh();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Activité "${activity['title']}" validée et confirmée !',
            ),
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Validation impossible : $error')),
        );
      }
    } finally {
      if (mounted) Navigator.of(context, rootNavigator: true).pop();
    }
  }

  String _formatActivityTimestamp(dynamic value) {
    final parsed = DateTime.tryParse(value?.toString() ?? '');
    if (parsed == null) return 'Non renseignée';
    return '${parsed.day.toString().padLeft(2, '0')}/${parsed.month.toString().padLeft(2, '0')}/${parsed.year} ${parsed.hour.toString().padLeft(2, '0')}:${parsed.minute.toString().padLeft(2, '0')}';
  }

  String _formatActivityDate(dynamic value) {
    final parsed = DateTime.tryParse(value?.toString() ?? '');
    if (parsed == null) return 'Non renseignée';
    return '${parsed.day.toString().padLeft(2, '0')}/${parsed.month.toString().padLeft(2, '0')}/${parsed.year}';
  }

  String _formatActivityNotes(dynamic value) {
    if (value == null || value.toString().trim().isEmpty) {
      return 'Aucune information';
    }
    try {
      final decoded = jsonDecode(value.toString());
      if (decoded is Map) {
        final lines = <String>[];
        if (decoded['feedQtyKg'] != null) {
          lines.add(
            'Quantité d\'aliment distribué : ${decoded['feedQtyKg']} kg',
          );
        }
        if (decoded['dose'] != null) {
          lines.add('Quantité dose utilisée : ${decoded['dose']}');
        }
        if (decoded['weight'] != null) {
          lines.add('Poids moyen constaté : ${decoded['weight']} kg');
        }
        if (decoded['eggsProduced'] != null) {
          lines.add('Œufs produits : ${decoded['eggsProduced']}');
        }
        if (decoded['eggsBroken'] != null) {
          lines.add('Œufs cassés : ${decoded['eggsBroken']}');
        }
        if (decoded['eggsUnsellable'] != null) {
          lines.add('Œufs non vendables : ${decoded['eggsUnsellable']}');
        }
        if (decoded['eggsPlusGros'] != null) {
          lines.add('Œufs plus gros : ${decoded['eggsPlusGros']}');
        }
        if (decoded['eggsGros'] != null) {
          lines.add('Œufs gros : ${decoded['eggsGros']}');
        }
        if (decoded['eggsMoyen'] != null) {
          lines.add('Œufs moyens : ${decoded['eggsMoyen']}');
        }
        if (decoded['eggsPetit'] != null) {
          lines.add('Œufs petits : ${decoded['eggsPetit']}');
        }
        if (decoded['temperatureCelsius'] != null) {
          lines.add(
            'Température constatée : ${decoded['temperatureCelsius']} °C',
          );
        }
        if (decoded['notes'] != null &&
            decoded['notes'].toString().trim().isNotEmpty) {
          lines.add('Observation : ${decoded['notes']}');
        }
        if (decoded['confirmed'] == true) {
          lines.add('Confirmation : tâche réalisée');
        }
        return lines.join('\n');
      }
    } catch (_) {}
    return value.toString();
  }
}
