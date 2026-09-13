import 'package:flutter/material.dart';
import '../../../../../config/theme/app_theme.dart';
import '../../../../../core/di/service_locator.dart';
import '../../../../../data/datasources/remote/api_client.dart';
import '../../../../shared/widgets/common_widgets.dart';

class T2AddEggExitForm extends StatefulWidget {
  final List<Map<String, String>> staffOptions;
  final VoidCallback onExitSaved;
  final VoidCallback onCancel;

  const T2AddEggExitForm({
    super.key,
    required this.staffOptions,
    required this.onExitSaved,
    required this.onCancel,
  });

  @override
  State<T2AddEggExitForm> createState() => _T2AddEggExitFormState();
}

class _T2AddEggExitFormState extends State<T2AddEggExitForm> {
  final ApiClient _apiClient = getIt<ApiClient>();

  final TextEditingController _totalQuantityController = TextEditingController();
  final TextEditingController _plusGrosController = TextEditingController();
  final TextEditingController _grosController = TextEditingController();
  final TextEditingController _moyenController = TextEditingController();
  final TextEditingController _petitController = TextEditingController();
  final TextEditingController _commentController = TextEditingController();

  String? _selectedResponsibleId;
  String? _selectedResponsibleName;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    if (widget.staffOptions.isNotEmpty) {
      _selectedResponsibleId = widget.staffOptions.first['id'];
      _selectedResponsibleName = widget.staffOptions.first['name'];
    }
  }

  @override
  void dispose() {
    _totalQuantityController.dispose();
    _plusGrosController.dispose();
    _grosController.dispose();
    _moyenController.dispose();
    _petitController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  void _calculateTotalFromFormats() {
    final plusGros = int.tryParse(_plusGrosController.text.trim()) ?? 0;
    final gros = int.tryParse(_grosController.text.trim()) ?? 0;
    final moyen = int.tryParse(_moyenController.text.trim()) ?? 0;
    final petit = int.tryParse(_petitController.text.trim()) ?? 0;

    final sum = plusGros + gros + moyen + petit;
    if (sum > 0 && _totalQuantityController.text.trim().isEmpty) {
      _totalQuantityController.text = sum.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('EFFECTUER UNE SORTIE D’ŒUFS', style: AppTypography.label),
          const SizedBox(height: 16),

          // Total quantity
          AppInputBox(
            label: 'Nombre d’œufs total',
            placeholder: 'Ex: 1240',
            controller: _totalQuantityController,
            inputType: TextInputType.number,
          ),
          const SizedBox(height: 14),

          const Text('RÉPARTITION PAR CALIBRE', style: AppTypography.label),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: AppInputBox(
                  label: 'Plus gros',
                  placeholder: 'Ex: 30',
                  controller: _plusGrosController,
                  inputType: TextInputType.number,
                  onChanged: (_) => _calculateTotalFromFormats(),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: AppInputBox(
                  label: 'Gros',
                  placeholder: 'Ex: 90',
                  controller: _grosController,
                  inputType: TextInputType.number,
                  onChanged: (_) => _calculateTotalFromFormats(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: AppInputBox(
                  label: 'Moyen',
                  placeholder: 'Ex: 460',
                  controller: _moyenController,
                  inputType: TextInputType.number,
                  onChanged: (_) => _calculateTotalFromFormats(),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: AppInputBox(
                  label: 'Petit',
                  placeholder: 'Ex: 660',
                  controller: _petitController,
                  inputType: TextInputType.number,
                  onChanged: (_) => _calculateTotalFromFormats(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Dynamic staff dropdown (Technicians + Volaillers)
          const Text('RESPONSABLE SORTIE (TECHNICIEN / VOLAILLER)', style: AppTypography.label),
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
                value: widget.staffOptions.any((s) => s['id'] == _selectedResponsibleId)
                    ? _selectedResponsibleId
                    : (widget.staffOptions.isNotEmpty ? widget.staffOptions.first['id'] : null),
                isExpanded: true,
                onChanged: (val) {
                  if (val != null) {
                    final staff = widget.staffOptions.firstWhere((s) => s['id'] == val, orElse: () => {'name': ''});
                    setState(() {
                      _selectedResponsibleId = val;
                      _selectedResponsibleName = staff['name'];
                    });
                  }
                },
                items: widget.staffOptions
                    .map(
                      (staff) => DropdownMenuItem(
                        value: staff['id'],
                        child: Text(
                          staff['name'] ?? 'Personnel',
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
          ),
          const SizedBox(height: 14),

          AppInputBox(
            label: 'Commentaire / Observations',
            placeholder: 'Ex: Ramassage du matin bâtiment A...',
            controller: _commentController,
          ),
          const SizedBox(height: 24),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _submitEggExit,
              child: _isSubmitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Enregistrer la sortie'),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: _isSubmitting ? null : widget.onCancel,
              child: const Text('Annuler'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _submitEggExit() async {
    final qtyStr = _totalQuantityController.text.trim();
    if (qtyStr.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez renseigner le nombre d’œufs')),
      );
      return;
    }

    final qty = double.tryParse(qtyStr);
    if (qty == null || qty <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('La quantité d’œufs doit être un nombre positif')),
      );
      return;
    }

    final plusGros = int.tryParse(_plusGrosController.text.trim()) ?? 0;
    final gros = int.tryParse(_grosController.text.trim()) ?? 0;
    final moyen = int.tryParse(_moyenController.text.trim()) ?? 0;
    final petit = int.tryParse(_petitController.text.trim()) ?? 0;

    final responsibleName = _selectedResponsibleName ?? 'Personnel';

    setState(() => _isSubmitting = true);
    showActionLoadingDialog(context, message: 'Enregistrement de la sortie d\'œufs...');

    try {
      await _apiClient.post(
        '/magasinier/egg-exits',
        data: {
          'quantity': qty,
          'responsibleName': responsibleName,
          'responsibleUserId': _selectedResponsibleId,
          'plusGros': plusGros,
          'gros': gros,
          'moyen': moyen,
          'petit': petit,
          'comment': _commentController.text.trim().isNotEmpty
              ? _commentController.text.trim()
              : 'Sortie d\'œufs vers magasin',
        },
      );

      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop(); // dismiss loader
        widget.onExitSaved();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sortie d\'œufs enregistrée et transmise à la réception du magasinier !'),
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop(); // dismiss loader
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Impossible d\'enregistrer la sortie : $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }
}
