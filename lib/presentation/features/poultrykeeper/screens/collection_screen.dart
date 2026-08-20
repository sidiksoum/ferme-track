import 'package:flutter/material.dart';

import '../../../../config/theme/app_theme.dart';
import '../../../shared/widgets/common_widgets.dart';

class EggCollectionScreen extends StatefulWidget {
  const EggCollectionScreen({super.key});

  @override
  State<EggCollectionScreen> createState() => _EggCollectionScreenState();
}

class _EggCollectionScreenState extends State<EggCollectionScreen> {
  int _collectedEggs = 132;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAF7),
      appBar: AppBar(title: const Text('Collecte des œufs')),
      body: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('QUANTITÉ COLLECTÉE', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: AppColors.inkSoft, letterSpacing: 0.03)),
            const SizedBox(height: 8),
            CounterBox(
              initialValue: _collectedEggs,
              onChanged: (value) => setState(() => _collectedEggs = value),
              unit: 'œufs collectés',
            ),
            const SizedBox(height: 18),
            AppInputBox(
              label: 'Observation',
              placeholder: 'Mentionner un problème de collecte…',
              maxLines: 3,
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {},
                child: const Text('Valider la collecte'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AnomalyReportScreen extends StatefulWidget {
  const AnomalyReportScreen({super.key});

  @override
  State<AnomalyReportScreen> createState() => _AnomalyReportScreenState();
}

class _AnomalyReportScreenState extends State<AnomalyReportScreen> {
  String _selectedType = 'sanitary';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAF7),
      appBar: AppBar(title: const Text('Déclarer une anomalie')),
      body: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('TYPE', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: AppColors.inkSoft, letterSpacing: 0.03)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                _buildChip('sanitary', 'Sanitaire'),
                _buildChip('technical', 'Technique'),
                _buildChip('security', 'Sécurité'),
              ],
            ),
            const SizedBox(height: 18),
            AppInputBox(
              label: 'Description',
              placeholder: 'Décrire l’anomalie observée…',
              maxLines: 4,
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
                child: const Text('Envoyer l’anomalie'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChip(String value, String label) {
    final selected = _selectedType == value;
    return GestureDetector(
      onTap: () => setState(() => _selectedType = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.primaryLight : AppColors.paper,
          border: Border.all(color: selected ? AppColors.primary : AppColors.line),
          borderRadius: BorderRadius.circular(100),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: selected ? AppColors.primaryDark : AppColors.inkSoft,
          ),
        ),
      ),
    );
  }
}
