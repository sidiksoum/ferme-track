import 'package:flutter/material.dart';
import '../../../../config/theme/app_theme.dart';
import '../../../shared/widgets/common_widgets.dart';

class V2CloseTaskView extends StatefulWidget {
  final Map<String, dynamic>? selectedTask;
  final VoidCallback onCancel;
  final VoidCallback onDone;

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

  // Egg collection states
  int _eggsProduced = 1640;
  int _eggsBroken = 18;
  int _eggsUnsellable = 6;
  final TextEditingController _eggObservationController =
      TextEditingController();

  // Cleaning states
  bool _cleaningConfirmed = false;

  // Temperature states
  int _temperatureVal = 24;

  @override
  void dispose() {
    _eggObservationController.dispose();
    super.dispose();
  }

  int get _totalCollectedEggs {
    return _eggsProduced + _eggsBroken + _eggsUnsellable;
  }

  @override
  Widget build(BuildContext context) {
    final task =
        widget.selectedTask ??
        {
          'title': 'Distribuer l\'aliment',
          'meta': 'Bâtiment A · Lot L-2026-011',
        };

    final title = task['title'] as String;

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
                        title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      Text(
                        task['meta'] as String,
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
          if (title.toLowerCase().contains('aliment'))
            _buildFeedDistributionForm()
          else if (title.toLowerCase().contains('œufs') ||
              title.toLowerCase().contains('oeufs'))
            _buildEggCollectionForm()
          else if (title.toLowerCase().contains('nettoyage') ||
              title.toLowerCase().contains('abreuvoir'))
            _buildCleaningForm()
          else if (title.toLowerCase().contains('température') ||
              title.toLowerCase().contains('temperature'))
            _buildTemperatureForm()
          else
            _buildDefaultCloseForm(),
        ],
      ),
    );
  }

  // --- FORM A: FEED DISTRIBUTION ---
  Widget _buildFeedDistributionForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('QUANTITÉ DISTRIBUÉE', style: AppTypography.label),
        const SizedBox(height: 6),
        CounterBox(
          initialValue: _feedQty,
          unit: 'kilogrammes',
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
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Tâche clôturée : $_feedQty kg distribués'),
                    ),
                  );
                  widget.onDone();
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

  // --- FORM B: EGG COLLECTION ---
  Widget _buildEggCollectionForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('COLLECTE D\'ŒUFS', style: AppTypography.label),
        const SizedBox(height: 8),
        _buildFormatCounter(
          'Produits',
          _eggsProduced,
          (val) => setState(() => _eggsProduced = val),
        ),
        _buildFormatCounter(
          'Cassés',
          _eggsBroken,
          (val) => setState(() => _eggsBroken = val),
        ),
        const SizedBox(height: 12),

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
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Collecte enregistrée : $_totalCollectedEggs œufs',
                      ),
                    ),
                  );
                  widget.onDone();
                },
                child: const Text('Enregistrer'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // --- FORM C: CLEANING ---
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
                    : () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Tâche de nettoyage enregistrée et fermée',
                            ),
                          ),
                        );
                        widget.onDone();
                      },
                child: const Text('Confirmer'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // --- FORM D: TEMPERATURE ---
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
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Température enregistrée : $_temperatureVal °C',
                      ),
                    ),
                  );
                  widget.onDone();
                },
                child: const Text('Confirmer'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // --- FORM E: DEFAULT GENERAL CLOSE ---
  Widget _buildDefaultCloseForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Confirmer la réalisation de cette tâche ?',
          style: AppTypography.label,
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
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Tâche clôturée')),
                  );
                  widget.onDone();
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
                onTap: () => onChanged((value - 1).clamp(0, 5000)),
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
              Text(
                '$value',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: () => onChanged((value + 1).clamp(0, 5000)),
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
