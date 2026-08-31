import 'package:flutter/material.dart';
import '../../../../config/theme/app_theme.dart';
import '../../../shared/widgets/common_widgets.dart';

class V3V6AnomalyView extends StatefulWidget {
  const V3V6AnomalyView({super.key});

  @override
  State<V3V6AnomalyView> createState() => _V3V6AnomalyViewState();
}

class _V3V6AnomalyViewState extends State<V3V6AnomalyView> {
  String _activeTab = 'mortality'; // mortality, other

  // Mortality states
  int _mortalityCount = 3;
  String _mortalityCause = 'heat'; // heat, disease, unknown
  final TextEditingController _mortalityCommentController = TextEditingController();

  // Other anomaly states
  String _anomalyType = 'technical'; // technical, sanitary, security
  String _anomalySeverity = 'high'; // low, high
  final TextEditingController _anomalyNotesController = TextEditingController();

  @override
  void dispose() {
    _anomalyNotesController.dispose();
    _mortalityCommentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Tabs at the top
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
                    'Signaler une mortalité',
                    _activeTab == 'mortality',
                    () => setState(() => _activeTab = 'mortality'),
                  ),
                ),
                Expanded(
                  child: _buildSubTabButton(
                    'Autre anomalie',
                    _activeTab == 'other',
                    () => setState(() => _activeTab = 'other'),
                  ),
                ),
              ],
            ),
          ),
        ),

        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: _activeTab == 'mortality'
                ? _buildMortalityForm()
                : _buildOtherAnomalyForm(),
          ),
        ),
      ],
    );
  }

  Widget _buildMortalityForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('NOMBRE DE SUJETS', style: AppTypography.label),
        const SizedBox(height: 6),
        CounterBox(
          initialValue: _mortalityCount,
          onChanged: (val) {
            setState(() {
              _mortalityCount = val;
            });
          },
        ),
        const SizedBox(height: 14),

        const Text('CAUSE PROBABLE', style: AppTypography.label),
        const SizedBox(height: 6),
        Row(
          children: [
            _buildFilterChip('Maladie', _mortalityCause == 'disease', () {
              setState(() => _mortalityCause = 'disease');
            }),
            _buildFilterChip('Chaleur', _mortalityCause == 'heat', () {
              setState(() => _mortalityCause = 'heat');
            }),
            _buildFilterChip('Inconnue', _mortalityCause == 'unknown', () {
              setState(() => _mortalityCause = 'unknown');
            }),
          ],
        ),
        const SizedBox(height: 14),

        const Text('COMMENTAIRE / DÉTAILS (REQUIS)', style: AppTypography.label),
        const SizedBox(height: 6),
        AppInputBox(
          placeholder: 'Précisez les symptômes ou circonstances…',
          controller: _mortalityCommentController,
        ),
        const SizedBox(height: 14),

        const Text('PHOTO (OPTIONNEL)', style: AppTypography.label),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Appareil photo activé (simulation)')),
            );
          },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 20),
            decoration: BoxDecoration(
              border: Border.all(
                color: const Color(0xFFC9D6C6),
                width: 1.6,
                style: BorderStyle.solid,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: const [
                Icon(Icons.camera_alt, size: 20, color: AppColors.inkSoft),
                SizedBox(height: 6),
                Text(
                  'Ajouter une photo (optionnel)',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppColors.inkSoft,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),

        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              if (_mortalityCommentController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Veuillez ajouter un commentaire explicatif')),
                );
                return;
              }
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Déclaration de mortalité enregistrée')),
              );
              setState(() {
                _mortalityCount = 3;
                _mortalityCause = 'heat';
                _mortalityCommentController.clear();
              });
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            child: const Text('Envoyer la déclaration'),
          ),
        ),
      ],
    );
  }

  Widget _buildOtherAnomalyForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('TYPE D\'ANOMALIE', style: AppTypography.label),
        const SizedBox(height: 6),
        Row(
          children: [
            _buildFilterChip('Technique', _anomalyType == 'technical', () {
              setState(() => _anomalyType = 'technical');
            }),
            _buildFilterChip('Sanitaire', _anomalyType == 'sanitary', () {
              setState(() => _anomalyType = 'sanitary');
            }),
            _buildFilterChip('Sécurité', _anomalyType == 'security', () {
              setState(() => _anomalyType = 'security');
            }),
          ],
        ),
        const SizedBox(height: 14),

        const Text('NIVEAU DE GRAVITÉ', style: AppTypography.label),
        const SizedBox(height: 6),
        Row(
          children: [
            _buildFilterChip('Faible', _anomalySeverity == 'low', () {
              setState(() => _anomalySeverity = 'low');
            }),
            _buildFilterChip('Élevée', _anomalySeverity == 'high', () {
              setState(() => _anomalySeverity = 'high');
            }),
          ],
        ),
        const SizedBox(height: 14),

        const Text('DESCRIPTION / NOTES', style: AppTypography.label),
        const SizedBox(height: 6),
        AppInputBox(
          placeholder: 'Détaillez le problème rencontré...',
          maxLines: 3,
          controller: _anomalyNotesController,
        ),
        const SizedBox(height: 14),

        const Text('PREUVE PHOTO', style: AppTypography.label),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Appareil photo activé (simulation)')),
            );
          },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 20),
            decoration: BoxDecoration(
              border: Border.all(
                color: const Color(0xFFC9D6C6),
                width: 1.6,
                style: BorderStyle.solid,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: const [
                Icon(Icons.camera_alt, size: 20, color: AppColors.inkSoft),
                SizedBox(height: 6),
                Text(
                  'Prendre une photo',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppColors.inkSoft,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),

        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Signalement d\'anomalie envoyé')),
              );
              setState(() {
                _anomalyNotesController.clear();
                _anomalyType = 'technical';
                _anomalySeverity = 'high';
              });
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            child: const Text('Envoyer le signalement'),
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
          border: Border.all(color: isSelected ? AppColors.primaryDark : AppColors.line),
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
}
