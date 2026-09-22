import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../../config/theme/app_theme.dart';
import '../../../../../core/di/service_locator.dart';
import '../../../../../data/datasources/remote/api_client.dart';
import '../../../../providers/auth_provider.dart';
import '../../../../shared/widgets/common_widgets.dart';

class T2AddActivityForm extends StatefulWidget {
  final List<Map<String, String>> buildingOptions;
  final List<Map<String, String>> responsibleOptions;
  final Map<String, String> responsibleIdsByLabel;
  final bool isLoadingOptions;
  final VoidCallback onSuccess;
  final VoidCallback onCancel;

  const T2AddActivityForm({
    super.key,
    required this.buildingOptions,
    required this.responsibleOptions,
    required this.responsibleIdsByLabel,
    required this.isLoadingOptions,
    required this.onSuccess,
    required this.onCancel,
  });

  @override
  State<T2AddActivityForm> createState() => _T2AddActivityFormState();
}

class _T2AddActivityFormState extends State<T2AddActivityForm> {
  final ApiClient _apiClient = getIt<ApiClient>();

  final List<String> _allActivityOptions = [
    'Vitamine',
    'Deparasitant',
    'Vaccination',
    'Injection',
    'Alimentation et abrevage',
    'Nettoyage',
    'Pesée',
    'Collecte des œufs',
  ];

  final Set<String> _selectedActivities = {};
  final Set<String> _selectedResponsibles = {};
  String _selectedBuildingForActivity = '';
  final TextEditingController _activityNotesController = TextEditingController();
  DateTime _startDate = DateTime.now();
  TimeOfDay _startTime = const TimeOfDay(hour: 8, minute: 0);
  DateTime _endDate = DateTime.now();
  TimeOfDay _endTime = const TimeOfDay(hour: 9, minute: 0);
  int _activityPriority = 2; // 1, 2, 3

  @override
  void initState() {
    super.initState();
    if (widget.buildingOptions.isNotEmpty) {
      _selectedBuildingForActivity = widget.buildingOptions.first['id']!;
    }
  }

  @override
  void didUpdateWidget(covariant T2AddActivityForm oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_selectedBuildingForActivity.isEmpty && widget.buildingOptions.isNotEmpty) {
      _selectedBuildingForActivity = widget.buildingOptions.first['id']!;
    }
  }

  @override
  void dispose() {
    _activityNotesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isLoadingOptions) {
      return const Center(child: CircularProgressIndicator());
    }

    final String chosenActivitiesStr = _selectedActivities.isEmpty
        ? 'Aucune activité choisie'
        : _selectedActivities.join(', ');

    final String chosenResponsiblesStr = _selectedResponsibles.isEmpty
        ? 'Aucun responsable choisi'
        : _selectedResponsibles.map((r) => r.split(' — ')[0]).join(', ');

    return SingleChildScrollView(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'PROGRAMMER UNE OU PLUSIEURS ACTIVITÉS',
            style: AppTypography.label,
          ),
          const SizedBox(height: 14),

          // Multi-activities selection box
          const Text(
            'ACTIVITÉ(S) (MULTI-SÉLECTION)',
            style: AppTypography.label,
          ),
          const SizedBox(height: 6),
          GestureDetector(
            onTap: _showMultiSelectActivitiesDialog,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.paper,
                border: Border.all(color: AppColors.line, width: 1.6),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.list_alt,
                    color: AppColors.inkSoft,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      chosenActivitiesStr,
                      style: TextStyle(
                        color: _selectedActivities.isEmpty
                            ? AppColors.inkSoft
                            : AppColors.primaryDark,
                        fontWeight: _selectedActivities.isEmpty
                            ? FontWeight.normal
                            : FontWeight.bold,
                      ),
                    ),
                  ),
                  const Icon(Icons.arrow_drop_down, color: AppColors.inkSoft),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),

          const Text('BÂTIMENT', style: AppTypography.label),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: AppColors.paper,
              border: Border.all(color: AppColors.line, width: 1.6),
              borderRadius: BorderRadius.circular(14),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: widget.buildingOptions.any(
                  (option) => option['id'] == _selectedBuildingForActivity,
                )
                    ? _selectedBuildingForActivity
                    : (widget.buildingOptions.isNotEmpty
                        ? widget.buildingOptions.first['id']
                        : null),
                isExpanded: true,
                onChanged: (val) {
                  if (val != null) {
                    setState(() => _selectedBuildingForActivity = val);
                  }
                },
                items: widget.buildingOptions
                    .map(
                      (building) => DropdownMenuItem(
                        value: building['id'],
                        child: Text(building['name']!),
                      ),
                    )
                    .toList(),
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Multi-responsibles selection box
          const Text(
            'RESPONSABLE(S) (MULTI-SÉLECTION)',
            style: AppTypography.label,
          ),
          const SizedBox(height: 6),
          GestureDetector(
            onTap: _showMultiSelectResponsiblesDialog,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.paper,
                border: Border.all(color: AppColors.line, width: 1.6),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.people_outline,
                    color: AppColors.inkSoft,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      chosenResponsiblesStr,
                      style: TextStyle(
                        color: _selectedResponsibles.isEmpty
                            ? AppColors.inkSoft
                            : AppColors.primaryDark,
                        fontWeight: _selectedResponsibles.isEmpty
                            ? FontWeight.normal
                            : FontWeight.bold,
                      ),
                    ),
                  ),
                  const Icon(Icons.arrow_drop_down, color: AppColors.inkSoft),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),

          const Text('DÉBUT DE L\'ACTIVITÉ', style: AppTypography.label),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: AppInputBox(
                  placeholder: _formatDate(_startDate),
                  readOnly: true,
                  onTap: _selectStartDate,
                  suffix: const Icon(
                    Icons.calendar_today,
                    size: 16,
                    color: AppColors.inkSoft,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AppInputBox(
                  placeholder: _formatTime(_startTime),
                  readOnly: true,
                  onTap: _selectStartTime,
                  suffix: const Icon(
                    Icons.access_time,
                    size: 16,
                    color: AppColors.inkSoft,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          const Text('FIN DE L\'ACTIVITÉ', style: AppTypography.label),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: AppInputBox(
                  placeholder: _formatDate(_endDate),
                  readOnly: true,
                  onTap: _selectEndDate,
                  suffix: const Icon(
                    Icons.calendar_today,
                    size: 16,
                    color: AppColors.inkSoft,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AppInputBox(
                  placeholder: _formatTime(_endTime),
                  readOnly: true,
                  onTap: _selectEndTime,
                  suffix: const Icon(
                    Icons.access_time,
                    size: 16,
                    color: AppColors.inkSoft,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          const Text('NOTES / INSTRUCTIONS', style: AppTypography.label),
          const SizedBox(height: 6),
          AppInputBox(
            placeholder: 'Saisissez les détails de la tâche…',
            maxLines: 3,
            controller: _activityNotesController,
          ),
          const SizedBox(height: 24),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _submitForm,
              child: const Text('Créer l\'activité'),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: widget.onCancel,
              child: const Text('Annuler'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _submitForm() async {
    if (_selectedActivities.isEmpty || _selectedResponsibles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Veuillez choisir au moins une activité et un responsable',
          ),
        ),
      );
      return;
    }
    final start = DateTime(
      _startDate.year,
      _startDate.month,
      _startDate.day,
      _startTime.hour,
      _startTime.minute,
    );
    final end = DateTime(
      _endDate.year,
      _endDate.month,
      _endDate.day,
      _endTime.hour,
      _endTime.minute,
    );
    showActionLoadingDialog(
      context,
      message: 'Programmation en cours...',
    );
    try {
      final farmId = context.read<AuthNotifier>().currentUser?.farmId;
      if (farmId == null || farmId.isEmpty || _selectedBuildingForActivity.isEmpty) {
        throw StateError('Ferme ou bâtiment indisponible');
      }
      final responsibleIds = _selectedResponsibles
          .map((label) => widget.responsibleIdsByLabel[label])
          .whereType<String>()
          .toList();

      await Future.wait([
        for (final activityName in _selectedActivities)
          for (final responsibleId in responsibleIds)
            _apiClient.post(
              '/tasks',
              data: {
                'farm_id': farmId,
                'building_id': _selectedBuildingForActivity,
                'title': activityName,
                'description': _activityNotesController.text.trim(),
                'task_type': _taskTypeFor(activityName),
                'priority': _priorityFor(_activityPriority),
                'scheduled_date': _formatApiDate(start),
                'start_time': _timeForApi(start),
                'end_time': _timeForApi(end),
                'assigned_to_id': responsibleId,
              },
            ),
      ]);

      if (!mounted) return;
      widget.onSuccess();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Activités programmées avec succès'),
        ),
      );
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Création impossible : $error')),
        );
      }
    } finally {
      if (mounted) Navigator.of(context, rootNavigator: true).pop();
    }
  }

  void _showMultiSelectActivitiesDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Choisir des activités'),
              content: SingleChildScrollView(
                child: Column(
                  children: _allActivityOptions.map((opt) {
                    final bool isChecked = _selectedActivities.contains(opt);
                    return CheckboxListTile(
                      title: Text(opt),
                      value: isChecked,
                      activeColor: AppColors.primaryDark,
                      onChanged: (val) {
                        setDialogState(() {
                          if (val == true) {
                            _selectedActivities.add(opt);
                          } else {
                            _selectedActivities.remove(opt);
                          }
                        });
                        setState(() {});
                      },
                    );
                  }).toList(),
                ),
              ),
              actions: [
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Terminer'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showMultiSelectResponsiblesDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Choisir des responsables'),
              content: SingleChildScrollView(
                child: Column(
                  children: widget.responsibleOptions.map((responsible) {
                    final opt = responsible['name']!;
                    final bool isChecked = _selectedResponsibles.contains(opt);
                    return CheckboxListTile(
                      title: Text(opt),
                      value: isChecked,
                      activeColor: AppColors.primaryDark,
                      onChanged: (val) {
                        setDialogState(() {
                          if (val == true) {
                            _selectedResponsibles.add(opt);
                          } else {
                            _selectedResponsibles.remove(opt);
                          }
                        });
                        setState(() {});
                      },
                    );
                  }).toList(),
                ),
              ),
              actions: [
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Terminer'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  String _taskTypeFor(String activity) {
    final value = activity.toLowerCase();
    if (value.contains('vaccin')) return 'VACCINATION';
    if (value.contains('aliment') || value.contains('abrevage') || value.contains('abreuv')) return 'FEEDING';
    if (value.contains('netoy') || value.contains('nettoy')) return 'CLEANING';
    if (value.contains('œuf') || value.contains('oeuf') || value.contains('ramassage') || value.contains('ponte')) return 'EGG_COLLECTION';
    if (value.contains('pese') || value.contains('pesée')) return 'INSPECTION';
    if (value.contains('mortalit')) return 'MORTALITY';
    if (value.contains('vitamine') ||
        value.contains('deparasitant') ||
        value.contains('déparasitant') ||
        value.contains('injection') ||
        value.contains('soin') ||
        value.contains('traitement')) {
      return 'TREATMENT';
    }
    return 'OTHER';
  }

  String _priorityFor(int priority) {
    if (priority >= 4) return 'URGENT';
    if (priority >= 3) return 'HIGH';
    if (priority <= 1) return 'LOW';
    return 'NORMAL';
  }

  String _timeForApi(DateTime value) =>
      '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}:00';

  String _formatDate(DateTime dt) =>
      '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';

  String _formatApiDate(DateTime dt) =>
      '${dt.year.toString().padLeft(4, '0')}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';

  String _formatTime(TimeOfDay tod) =>
      '${tod.hour.toString().padLeft(2, '0')}:${tod.minute.toString().padLeft(2, '0')}';

  Future<void> _selectStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2025),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() => _startDate = picked);
    }
  }

  Future<void> _selectStartTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _startTime,
    );
    if (picked != null) {
      setState(() => _startTime = picked);
    }
  }

  Future<void> _selectEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate,
      firstDate: DateTime(2025),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() => _endDate = picked);
    }
  }

  Future<void> _selectEndTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _endTime,
    );
    if (picked != null) {
      setState(() => _endTime = picked);
    }
  }
}
