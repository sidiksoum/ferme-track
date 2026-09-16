import 'package:flutter/material.dart';
import '../../../../config/theme/app_theme.dart';
import '../../../shared/widgets/common_widgets.dart';

class V2CloseTaskView extends StatefulWidget {
  final Map<String, dynamic>? selectedTask;
  final VoidCallback onCancel;
  final Future<void> Function(Map<String, dynamic> payload) onDone;

  const V2CloseTaskView({
    super.key,
    required this.selectedTask,
    required this.onCancel,
    required this.onDone,
  });

  @override
  State<V2CloseTaskView> createState() => _V2CloseTaskViewState();
}

class _V2CloseTaskViewState extends State<V2CloseTaskView> {
  // Feed distribution states
  int _feedQty = 75;
  final TextEditingController _feedCommentController = TextEditingController();

  // Sanitary treatments (Vitamine, Déparasitant, Vaccination, Injection)
  int _doseQty = 1;
  final TextEditingController _sanitaryCommentController = TextEditingController();

  // Weighing (Pesée)
  double _weightVal = 1.85; // kg
  final TextEditingController _weightController = TextEditingController(text: '1.85');
  final TextEditingController _weighingCommentController = TextEditingController();

  // Egg collection states
  int _eggsPlusGros = 120;
  int _eggsGros = 420;
  int _eggsMoyen = 760;
  int _eggsPetit = 340;
  final TextEditingController _eggObservationController =
      TextEditingController();
  final TextEditingController _generalObservationController =
      TextEditingController();
  final Map<String, TextEditingController> _eggFormatControllers = {};

  // Cleaning states
  bool _cleaningConfirmed = false;
  final TextEditingController _cleaningCommentController = TextEditingController();

  // Temperature states
  int _temperatureVal = 24;

  @override
  void dispose() {
    _feedCommentController.dispose();
    _sanitaryCommentController.dispose();
    _weightController.dispose();
    _weighingCommentController.dispose();
    _eggObservationController.dispose();
    _generalObservationController.dispose();
    _cleaningCommentController.dispose();
    for (final controller in _eggFormatControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  int get _totalCollectedEggs {
    return _eggsPlusGros + _eggsGros + _eggsMoyen + _eggsPetit;
  }

  @override
  Widget build(BuildContext context) {
    final task =
        widget.selectedTask ??
        {
          'title': 'Distribuer l\'aliment',
          'meta': 'Bâtiment A · Lot L-2026-011',
        };

    final title = (task['title'] as String? ?? '').toLowerCase();
    final desc = (task['description'] as String? ?? '').toLowerCase();
    final taskType = (task['taskType'] as String? ?? '').toLowerCase();
    final combined = '$title $desc $taskType';

    final bool isFeeding = taskType == 'feeding' ||
        combined.contains('aliment') ||
        combined.contains('abrev') ||
        combined.contains('nourr');

    final bool isSanitary = taskType == 'treatment' ||
        taskType == 'vaccination' ||
        combined.contains('vitamine') ||
        combined.contains('vitamin') ||
        combined.contains('injection') ||
        combined.contains('inject') ||
        combined.contains('deparasitant') ||
        combined.contains('déparasitant') ||
        combined.contains('parasit') ||
        combined.contains('vaccin') ||
        combined.contains('traitement') ||
        combined.contains('soin') ||
        combined.contains('veto') ||
        combined.contains('médicament') ||
        combined.contains('medicament');

    final bool isWeighing = taskType == 'inspection' ||
        combined.contains('pes') ||
        combined.contains('poids');

    final bool isEggCollection = taskType == 'egg_collection' ||
        combined.contains('oeuf') ||
        combined.contains('œuf') ||
        combined.contains('ramassage') ||
        combined.contains('ponte') ||
        combined.contains('collecte');

    final bool isCleaning = taskType == 'cleaning' ||
        combined.contains('nettoy') ||
        combined.contains('desinfect') ||
        combined.contains('désinfect') ||
        combined.contains('lavage');

    final bool isTemperature = combined.contains('température') ||
        combined.contains('temperature');

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header info box
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Icon(Icons.assignment, color: AppColors.primaryDark),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task['title'] as String? ?? 'Tâche',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      Text(
                        task['meta'] as String? ?? '',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.inkSoft,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Render specific form based on task type
          if (isFeeding)
            _buildFeedDistributionForm()
          else if (isSanitary)
            _buildSanitaryTreatmentForm()
          else if (isWeighing)
            _buildWeighingForm()
          else if (isEggCollection)
            _buildEggCollectionForm()
          else if (isCleaning)
            _buildCleaningForm()
          else if (isTemperature)
            _buildTemperatureForm()
          else
            _buildDefaultCloseForm(),
        ],
      ),
    );
  }

  // --- FORM A: FEED DISTRIBUTION (Alimentation et abreuvage) ---
  Widget _buildFeedDistributionForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('QUANTITÉ D\'ALIMENT DISTRIBUÉ', style: AppTypography.label),
        const SizedBox(height: 6),
        CounterBox(
          initialValue: _feedQty,
          unit: 'kilogrammes (kg)',
          onChanged: (val) => setState(() => _feedQty = val),
        ),
        const SizedBox(height: 12),
        const Text('Quantités habituelles', style: AppTypography.labelSmall),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildPresetButton(25),
            _buildPresetButton(50),
            _buildPresetButton(75),
            _buildPresetButton(100),
          ],
        ),
        const SizedBox(height: 14),
        const Text('COMMENTAIRE / OBSERVATION', style: AppTypography.label),
        const SizedBox(height: 6),
        AppInputBox(
          placeholder: 'Précisez l\'état des mangeoires, abreuvoirs…',
          controller: _feedCommentController,
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: widget.onCancel,
                child: const Text('Annuler'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton(
                onPressed: () async {
                  await widget.onDone({
                    'feedQtyKg': _feedQty.toDouble(),
                    'notes': _feedCommentController.text.trim(),
                    'confirmed': true,
                  });
                },
                child: const Text('Confirmer'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPresetButton(int value) {
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _feedQty = value),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: _feedQty == value ? AppColors.primaryDark : AppColors.paper,
            border: Border.all(
              color: _feedQty == value ? AppColors.primaryDark : AppColors.line,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          alignment: Alignment.center,
          child: Text(
            '$value kg',
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.bold,
              color: _feedQty == value ? Colors.white : AppColors.inkSoft,
            ),
          ),
        ),
      ),
    );
  }

  // --- FORM B: SANITARY TREATMENTS (Vitamine, Déparasitant, Vaccination, Injection) ---
  Widget _buildSanitaryTreatmentForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('QUANTITÉ DOSE UTILISÉE', style: AppTypography.label),
        const SizedBox(height: 6),
        CounterBox(
          initialValue: _doseQty,
          unit: 'dose(s) / flacon(s)',
          onChanged: (val) => setState(() => _doseQty = val),
        ),
        const SizedBox(height: 14),
        const Text('COMMENTAIRE / OBSERVATION', style: AppTypography.label),
        const SizedBox(height: 6),
        AppInputBox(
          placeholder: 'Nom du produit, mode d\'administration ou réaction…',
          controller: _sanitaryCommentController,
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: widget.onCancel,
                child: const Text('Annuler'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton(
                onPressed: () async {
                  await widget.onDone({
                    'dose': _doseQty.toDouble(),
                    'notes': _sanitaryCommentController.text.trim(),
                    'confirmed': true,
                  });
                },
                child: const Text('Confirmer'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // --- FORM C: WEIGHING (Pesée) ---
  Widget _buildWeighingForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('POIDS MOYEN CONSTATÉ (KG)', style: AppTypography.label),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.paper,
            border: Border.all(color: AppColors.line),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              const Icon(Icons.scale, color: AppColors.primaryDark, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: _weightController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    hintText: 'Ex : 1.85',
                    border: InputBorder.none,
                    isDense: true,
                  ),
                  onChanged: (val) {
                    final p = double.tryParse(val.replaceAll(',', '.'));
                    if (p != null) _weightVal = p;
                  },
                ),
              ),
              const Text(
                'kg / sujet',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.inkSoft,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        const Text('COMMENTAIRE / OBSERVATION', style: AppTypography.label),
        const SizedBox(height: 6),
        AppInputBox(
          placeholder: 'Échantillon pesé, uniformité du lot…',
          controller: _weighingCommentController,
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: widget.onCancel,
                child: const Text('Annuler'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton(
                onPressed: () async {
                  final parsedWeight = double.tryParse(
                    _weightController.text.replaceAll(',', '.').trim(),
                  ) ?? _weightVal;
                  await widget.onDone({
                    'weight': parsedWeight,
                    'notes': _weighingCommentController.text.trim(),
                    'confirmed': true,
                  });
                },
                child: const Text('Confirmer'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // --- FORM D: EGG COLLECTION ---
  Widget _buildEggCollectionForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('COLLECTE D\'ŒUFS', style: AppTypography.label),
        const SizedBox(height: 8),
        _buildFormatCounter(
          'Plus gros',
          _eggsPlusGros,
          (val) => setState(() => _eggsPlusGros = val),
        ),
        _buildFormatCounter(
          'Gros',
          _eggsGros,
          (val) => setState(() => _eggsGros = val),
        ),
        _buildFormatCounter(
          'Moyen',
          _eggsMoyen,
          (val) => setState(() => _eggsMoyen = val),
        ),
        _buildFormatCounter(
          'Petit',
          _eggsPetit,
          (val) => setState(() => _eggsPetit = val),
        ),
        const SizedBox(height: 10),

        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.primaryLight,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total collecté',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryDark,
                ),
              ),
              Text(
                '$_totalCollectedEggs œufs',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryDark,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        const Text('Observation (optionnel)', style: AppTypography.label),
        const SizedBox(height: 6),
        AppInputBox(
          placeholder: 'Ajouter un commentaire…',
          controller: _eggObservationController,
        ),
        const SizedBox(height: 24),

        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: widget.onCancel,
                child: const Text('Annuler'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton(
                onPressed: () async {
                  await widget.onDone({
                    'eggsPlusGros': _eggsPlusGros,
                    'eggsGros': _eggsGros,
                    'eggsMoyen': _eggsMoyen,
                    'eggsPetit': _eggsPetit,
                    'notes': _eggObservationController.text.trim(),
                    'confirmed': true,
                  });
                },
                child: const Text('Enregistrer'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // --- FORM E: CLEANING ---
  Widget _buildCleaningForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.paper,
            border: Border.all(color: AppColors.line),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Checkbox(
                value: _cleaningConfirmed,
                activeColor: AppColors.primaryDark,
                onChanged: (val) {
                  if (val != null) {
                    setState(() => _cleaningConfirmed = val);
                  }
                },
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Confirmer la clôture de la tâche de nettoyage',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        const Text('COMMENTAIRE / OBSERVATION', style: AppTypography.label),
        const SizedBox(height: 6),
        AppInputBox(
          placeholder: 'Produits utilisés, litière changée…',
          controller: _cleaningCommentController,
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: widget.onCancel,
                child: const Text('Annuler'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton(
                onPressed: !_cleaningConfirmed
                    ? null
                    : () async {
                        await widget.onDone({
                          'confirmed': true,
                          'notes': _cleaningCommentController.text.trim(),
                        });
                      },
                child: const Text('Confirmer'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // --- FORM F: TEMPERATURE ---
  Widget _buildTemperatureForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('TEMPÉRATURE CONSTATÉE', style: AppTypography.label),
        const SizedBox(height: 6),
        CounterBox(
          initialValue: _temperatureVal,
          unit: 'degrés Celsius (°C)',
          onChanged: (val) => setState(() => _temperatureVal = val),
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: widget.onCancel,
                child: const Text('Annuler'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton(
                onPressed: () async {
                  await widget.onDone({
                    'temperatureCelsius': _temperatureVal.toDouble(),
                    'confirmed': true,
                  });
                },
                child: const Text('Confirmer'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // --- FORM G: DEFAULT GENERAL CLOSE ---
  Widget _buildDefaultCloseForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('DÉTAILS DE RÉALISATION', style: AppTypography.label),
        const SizedBox(height: 6),
        AppInputBox(
          placeholder: 'Produit, dose, observation ou résultat…',
          controller: _generalObservationController,
          maxLines: 3,
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: widget.onCancel,
                child: const Text('Annuler'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton(
                onPressed: () async {
                  await widget.onDone({
                    'confirmed': true,
                    'notes': _generalObservationController.text.trim(),
                  });
                },
                child: const Text('Confirmer'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFormatCounter(String label, int value, Function(int) onChanged) {
    final controller = _eggFormatControllers.putIfAbsent(
      label,
      () => TextEditingController(text: value.toString()),
    );
    if (controller.text != value.toString() && !controller.selection.isValid) {
      controller.text = value.toString();
    }
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.paper,
        border: Border.all(color: AppColors.line),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          Row(
            children: [
              GestureDetector(
                onTap: () {
                  final next = (value - 1).clamp(0, 5000);
                  controller.text = next.toString();
                  controller.selection = TextSelection.collapsed(
                    offset: controller.text.length,
                  );
                  onChanged(next);
                },
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  alignment: Alignment.center,
                  child: const Text(
                    '–',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryDark,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 80,
                child: TextField(
                  controller: controller,
                  textAlign: TextAlign.center,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    isDense: true,
                  ),
                  onChanged: (input) {
                    final parsed = int.tryParse(input);
                    if (parsed != null && parsed >= 0) onChanged(parsed);
                  },
                ),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: () {
                  final next = (value + 1).clamp(0, 5000);
                  controller.text = next.toString();
                  controller.selection = TextSelection.collapsed(
                    offset: controller.text.length,
                  );
                  onChanged(next);
                },
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  alignment: Alignment.center,
                  child: const Text(
                    '+',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryDark,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
