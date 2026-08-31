import 'package:flutter/material.dart';
import '../../../../config/theme/app_theme.dart';
import '../../../shared/widgets/common_widgets.dart';

class M3EggReceptionView extends StatefulWidget {
  const M3EggReceptionView({super.key});

  @override
  State<M3EggReceptionView> createState() => _M3EggReceptionViewState();
}

class _M3EggReceptionViewState extends State<M3EggReceptionView> {
  String _activeTab = 'pending'; // pending, validated
  Map<String, dynamic>? _selectedReceptionToValidate;

  // Active validation states & controllers
  int _verifiedCount = 0;
  int _formatPetit = 0;
  int _formatMoyen = 0;
  int _formatGrand = 0;

  final TextEditingController _verifiedCountController = TextEditingController();
  final TextEditingController _commentController = TextEditingController();
  final TextEditingController _petitController = TextEditingController();
  final TextEditingController _moyenController = TextEditingController();
  final TextEditingController _grandController = TextEditingController();

  // Lists
  final List<Map<String, dynamic>> _pendingReceptions = [
    {
      'id': '1',
      'building': 'A',
      'volailler': 'Ama Koffi',
      'announcedCount': 1664,
      'time': '07:05',
      'verifiedCount': 1660,
    }
  ];

  final List<Map<String, dynamic>> _validatedReceptions = [
    {
      'id': '2',
      'building': 'B',
      'volailler': 'Yao B.',
      'announcedCount': 980,
      'time': '07:20',
      'verifiedCount': 980,
      'comment': '',
      'formatPetit': 200,
      'formatMoyen': 500,
      'formatGrand': 280,
    }
  ];

  int get _totalRepartition {
    return _formatPetit + _formatMoyen + _formatGrand;
  }

  int get _deviation {
    if (_selectedReceptionToValidate == null) return 0;
    return (_selectedReceptionToValidate!['announcedCount'] as int) - _verifiedCount;
  }

  @override
  void dispose() {
    _verifiedCountController.dispose();
    _commentController.dispose();
    _petitController.dispose();
    _moyenController.dispose();
    _grandController.dispose();
    super.dispose();
  }

  void _startValidation(Map<String, dynamic> reception) {
    setState(() {
      _selectedReceptionToValidate = reception;
      _verifiedCount = reception['verifiedCount'];
      _formatPetit = 0;
      _formatMoyen = 0;
      _formatGrand = 0;
      _commentController.clear();

      // Initialize text fields
      _verifiedCountController.text = _verifiedCount.toString();
      _petitController.text = '0';
      _moyenController.text = '0';
      _grandController.text = '0';
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
                    'En attente',
                    _activeTab == 'pending',
                    () => setState(() => _activeTab = 'pending'),
                  ),
                ),
                Expanded(
                  child: _buildSubTabButton(
                    'Validées',
                    _activeTab == 'validated',
                    () => setState(() => _activeTab = 'validated'),
                  ),
                ),
              ],
            ),
          ),
        ),

        Expanded(
          child: ListView(
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
                ..._validatedReceptions.map((item) => _buildValidatedCard(item)),
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
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                ),
                const SizedBox(height: 4),
                Text(
                  '${item['volailler']} — Bât. ${item['building']} · annoncé ${item['announcedCount']} œufs',
                  style: const TextStyle(color: AppColors.inkSoft, fontSize: 11.5),
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
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                ),
                const SizedBox(height: 4),
                Text(
                  '${item['volailler']} — Bât. ${item['building']} · annoncé ${item['announcedCount']} œufs',
                  style: const TextStyle(color: AppColors.inkSoft, fontSize: 11.5),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
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
        ],
      ),
    );
  }

  Widget _buildValidationForm() {
    final item = _selectedReceptionToValidate!;
    final bool hasDeviation = _deviation != 0;
    final bool commentRequired = hasDeviation && _commentController.text.isEmpty;
    final bool repartitionMatch = _totalRepartition == _verifiedCount;
    final bool canValidate = !commentRequired && repartitionMatch;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.primaryDark),
          onPressed: () => setState(() => _selectedReceptionToValidate = null),
        ),
        title: Text(
          'En provenance de Bâtiment ${item['building']}',
          style: const TextStyle(color: AppColors.primaryDark, fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Announcement card
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Quantité annoncée par le volailler',
                    style: TextStyle(fontSize: 11, color: AppColors.primaryDark),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${item['volailler']} — ${item['time']}',
                        style: const TextStyle(fontSize: 12.5, color: AppColors.inkSoft, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '${item['announcedCount']} œufs',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primaryDark),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Verified count - Direct Numeric text input
            const Text('QUANTITÉ VÉRIFIÉE EN MAGASIN', style: AppTypography.label),
            const SizedBox(height: 6),
            AppInputBox(
              placeholder: 'Saisissez la quantité vérifiée…',
              inputType: TextInputType.number,
              controller: _verifiedCountController,
              onChanged: (val) {
                setState(() {
                  _verifiedCount = int.tryParse(val) ?? 0;
                });
              },
            ),
            const SizedBox(height: 12),

            // Discrepancy details
            if (hasDeviation) ...[
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.errorLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning, color: AppColors.danger, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      'Écart de $_deviation œuf(s)  ·  Commentaire requis',
                      style: const TextStyle(color: AppColors.danger, fontSize: 11.5, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              const Text('COMMENTAIRE JUSTIFICATIF', style: AppTypography.label),
              const SizedBox(height: 6),
              AppInputBox(
                placeholder: 'Ex : Casse durant le transport…',
                controller: _commentController,
                onChanged: (val) => setState(() {}),
              ),
              const SizedBox(height: 16),
            ],

            // egg formatting repartition - Direct Numeric text inputs
            const Text('RÉPARTITION PAR FORMAT (SAISIE DIRECTE)', style: AppTypography.label),
            const SizedBox(height: 8),
            
            AppInputBox(
              label: 'Petit format',
              placeholder: 'Ex: 200',
              inputType: TextInputType.number,
              controller: _petitController,
              onChanged: (val) {
                setState(() {
                  _formatPetit = int.tryParse(val) ?? 0;
                });
              },
            ),
            const SizedBox(height: 8),
            
            AppInputBox(
              label: 'Moyen format',
              placeholder: 'Ex: 500',
              inputType: TextInputType.number,
              controller: _moyenController,
              onChanged: (val) {
                setState(() {
                  _formatMoyen = int.tryParse(val) ?? 0;
                });
              },
            ),
            const SizedBox(height: 8),
            
            AppInputBox(
              label: 'Grand format',
              placeholder: 'Ex: 280',
              inputType: TextInputType.number,
              controller: _grandController,
              onChanged: (val) {
                setState(() {
                  _formatGrand = int.tryParse(val) ?? 0;
                });
              },
            ),
            const SizedBox(height: 16),

            // Total check
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: repartitionMatch ? AppColors.successLight : AppColors.errorLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total réparti',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: repartitionMatch ? AppColors.primaryDark : AppColors.danger,
                    ),
                  ),
                  Text(
                    '$_totalRepartition / $_verifiedCount œufs',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: repartitionMatch ? AppColors.primaryDark : AppColors.danger,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: !canValidate
                    ? null
                    : () {
                        setState(() {
                          // Move this item to validated list
                          _pendingReceptions.remove(item);
                          _validatedReceptions.add({
                            'id': item['id'],
                            'building': item['building'],
                            'volailler': item['volailler'],
                            'announcedCount': item['announcedCount'],
                            'time': item['time'],
                            'verifiedCount': _verifiedCount,
                            'comment': _commentController.text,
                            'formatPetit': _formatPetit,
                            'formatMoyen': _formatMoyen,
                            'formatGrand': _formatGrand,
                          });
                          _selectedReceptionToValidate = null;
                          _activeTab = 'validated';
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Réception validée avec succès !')),
                        );
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
