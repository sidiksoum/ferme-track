import 'package:flutter/material.dart';
import '../../../../../config/theme/app_theme.dart';
import '../../../../../core/di/service_locator.dart';
import '../../../../../data/datasources/remote/api_client.dart';
import '../../../../shared/widgets/common_widgets.dart';

class T2AddOrderForm extends StatefulWidget {
  final List<Map<String, dynamic>> existingSuppliers;
  final VoidCallback onOrderAdded;
  final VoidCallback onCancel;

  const T2AddOrderForm({
    super.key,
    required this.existingSuppliers,
    required this.onOrderAdded,
    required this.onCancel,
  });

  @override
  State<T2AddOrderForm> createState() => _T2AddOrderFormState();
}

class _T2AddOrderFormState extends State<T2AddOrderForm> {
  final ApiClient _apiClient = getIt<ApiClient>();

  final TextEditingController _supplierSearchController = TextEditingController();
  final TextEditingController _orderContactController = TextEditingController();
  final TextEditingController _orderAddressController = TextEditingController();
  final TextEditingController _orderCostController = TextEditingController();
  final TextEditingController _orderQuantityController = TextEditingController();
  final TextEditingController _orderNoteController = TextEditingController();

  String _selectedSupplierName = '';
  String _orderType = 'aliment'; // aliment, sanitaire, volaille
  String _orderArticle = 'Aliments';
  DateTime? _expectedDeliveryDate;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    if (widget.existingSuppliers.isNotEmpty) {
      final first = widget.existingSuppliers.first;
      _selectedSupplierName = first['name']?.toString() ?? '';
      _supplierSearchController.text = _selectedSupplierName;
      _orderContactController.text = first['phone']?.toString() ?? '';
      _orderAddressController.text = first['address']?.toString() ?? '';
    }
  }

  @override
  void dispose() {
    _supplierSearchController.dispose();
    _orderContactController.dispose();
    _orderAddressController.dispose();
    _orderCostController.dispose();
    _orderQuantityController.dispose();
    _orderNoteController.dispose();
    super.dispose();
  }

  void _onSupplierSelected(String name, String phone, String address) {
    setState(() {
      _selectedSupplierName = name;
      _supplierSearchController.text = name;
      if (phone.isNotEmpty) _orderContactController.text = phone;
      if (address.isNotEmpty) _orderAddressController.text = address;
    });
  }

  void _showSupplierSelectionModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        String filter = '';
        return StatefulBuilder(
          builder: (context, setModalState) {
            final filtered = widget.existingSuppliers.where((s) {
              final name = s['name']?.toString().toLowerCase() ?? '';
              return name.contains(filter.toLowerCase());
            }).toList();

            return Container(
              height: MediaQuery.of(context).size.height * 0.7,
              decoration: const BoxDecoration(
                color: AppColors.paper,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Choisir ou saisir un fournisseur',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    autofocus: true,
                    decoration: InputDecoration(
                      hintText: 'Rechercher ou saisir un nouveau nom...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: filter.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.add_circle, color: AppColors.primaryDark),
                              tooltip: 'Utiliser ce nouveau nom',
                              onPressed: () {
                                _onSupplierSelected(filter.trim(), '', '');
                                Navigator.pop(context);
                              },
                            )
                          : null,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onChanged: (val) {
                      setModalState(() => filter = val);
                    },
                    onSubmitted: (val) {
                      if (val.trim().isNotEmpty) {
                        _onSupplierSelected(val.trim(), '', '');
                        Navigator.pop(context);
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  if (filter.trim().isNotEmpty &&
                      !widget.existingSuppliers.any((s) => s['name']?.toString().toLowerCase() == filter.trim().toLowerCase()))
                    ListTile(
                      leading: const Icon(Icons.add_business, color: AppColors.primaryDark),
                      title: Text(
                        'Créer : "${filter.trim()}"',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryDark),
                      ),
                      subtitle: const Text('Enregistrer comme nouveau fournisseur'),
                      onTap: () {
                        _onSupplierSelected(filter.trim(), '', '');
                        Navigator.pop(context);
                      },
                    ),
                  const Divider(),
                  Expanded(
                    child: filtered.isEmpty
                        ? const Center(
                            child: Text(
                              'Aucun fournisseur trouvé.\nAppuyez sur Entrée ou sur le bouton "+" pour ajouter ce nom.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: AppColors.inkSoft),
                            ),
                          )
                        : ListView.builder(
                            itemCount: filtered.length,
                            itemBuilder: (context, index) {
                              final supplier = filtered[index];
                              final name = supplier['name']?.toString() ?? 'Fournisseur';
                              final phone = supplier['phone']?.toString() ?? '';
                              final address = supplier['address']?.toString() ?? '';

                              return ListTile(
                                leading: const CircleAvatar(
                                  backgroundColor: AppColors.primaryLight,
                                  child: Icon(Icons.store, color: AppColors.primaryDark, size: 20),
                                ),
                                title: Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
                                subtitle: Text([phone, address].where((s) => s.isNotEmpty).join(' · ')),
                                onTap: () {
                                  _onSupplierSelected(name, phone, address);
                                  Navigator.pop(context);
                                },
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'NOUVELLE COMMANDE FOURNISSEUR',
            style: AppTypography.label,
          ),
          const SizedBox(height: 16),

          // FOURNISSEUR FIELD (Searchable & Dynamic)
          const Text('FOURNISSEUR', style: AppTypography.label),
          const SizedBox(height: 6),
          GestureDetector(
            onTap: _showSupplierSelectionModal,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.paper,
                border: Border.all(color: AppColors.line, width: 1.6),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  const Icon(Icons.store, color: AppColors.inkSoft, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _selectedSupplierName.isEmpty
                          ? 'Sélectionner ou saisir un fournisseur'
                          : _selectedSupplierName,
                      style: TextStyle(
                        color: _selectedSupplierName.isEmpty
                            ? AppColors.inkSoft
                            : AppColors.primaryDark,
                        fontWeight: _selectedSupplierName.isEmpty
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

          AppInputBox(
            label: 'Contact',
            placeholder: 'Ex: +225 07 00 00 00',
            controller: _orderContactController,
          ),
          const SizedBox(height: 14),

          AppInputBox(
            label: 'Adresse fournisseur',
            placeholder: 'Ex: Zone 4 Abidjan',
            controller: _orderAddressController,
          ),
          const SizedBox(height: 14),

          const Text('TYPE DE PRODUIT', style: AppTypography.label),
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
                value: _orderType,
                isExpanded: true,
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      _orderType = val;
                      _syncOrderArticleForType();
                    });
                  }
                },
                items: const [
                  DropdownMenuItem(
                    value: 'aliment',
                    child: Text('Alimentation'),
                  ),
                  DropdownMenuItem(
                    value: 'sanitaire',
                    child: Text('Vétérinaire / Sanitaire'),
                  ),
                  DropdownMenuItem(
                    value: 'volaille',
                    child: Text('Volaille'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),

          const Text('ARTICLE', style: AppTypography.label),
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
                value: _getArticlesForType().contains(_orderArticle)
                    ? _orderArticle
                    : _getArticlesForType().first,
                isExpanded: true,
                onChanged: (val) {
                  if (val != null) {
                    setState(() => _orderArticle = val);
                  }
                },
                items: _getArticlesForType().map((art) {
                  return DropdownMenuItem(value: art, child: Text(art));
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 14),

          const Text('DATE DE RÉCEPTION PRÉVUE', style: AppTypography.label),
          const SizedBox(height: 6),
          GestureDetector(
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _expectedDeliveryDate ?? DateTime.now().add(const Duration(days: 3)),
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 90)),
              );
              if (picked != null) {
                setState(() => _expectedDeliveryDate = picked);
              }
            },
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
                    Icons.calendar_today,
                    color: AppColors.inkSoft,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _expectedDeliveryDate == null
                        ? 'Sélectionner la date de livraison'
                        : _formatDate(_expectedDeliveryDate!),
                    style: TextStyle(
                      color: _expectedDeliveryDate == null
                          ? AppColors.inkSoft
                          : AppColors.primaryDark,
                      fontWeight: _expectedDeliveryDate == null
                          ? FontWeight.normal
                          : FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),

          AppInputBox(
            label: 'Quantité attendue',
            placeholder: _orderType == 'volaille'
                ? 'Ex: 2000 sujets'
                : (_orderType == 'aliment' ? 'Ex: 40 sacs' : 'Ex: 100 doses'),
            controller: _orderQuantityController,
            inputType: TextInputType.number,
          ),
          const SizedBox(height: 14),

          AppInputBox(
            label: 'Coût estimé (FCFA)',
            placeholder: 'Ex: 250000',
            controller: _orderCostController,
            inputType: TextInputType.number,
          ),
          const SizedBox(height: 14),

          AppInputBox(
            label: 'Note / Instructions de commande',
            placeholder: 'Ex: Livraison urgente pour le Bâtiment A...',
            controller: _orderNoteController,
          ),
          const SizedBox(height: 24),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _submitOrder,
              child: _isSubmitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Enregistrer la Commande'),
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

  Future<void> _submitOrder() async {
    final supplierName = _selectedSupplierName.trim();
    if (supplierName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez renseigner le nom du fournisseur')),
      );
      return;
    }

    if (_expectedDeliveryDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez renseigner la date de réception prévue')),
      );
      return;
    }

    final qtyVal = double.tryParse(_orderQuantityController.text.trim()) ?? 1.0;
    final costVal = double.tryParse(_orderCostController.text.trim()) ?? 0.0;

    setState(() => _isSubmitting = true);
    showActionLoadingDialog(context, message: 'Enregistrement de la commande...');

    try {
      await _apiClient.post(
        '/orders',
        data: {
          'supplierName': supplierName,
          'contact': _orderContactController.text.trim(),
          'address': _orderAddressController.text.trim(),
          'type': _orderType,
          'article': _orderArticle,
          'expectedDate': _expectedDeliveryDate!.toIso8601String(),
          'quantity': qtyVal,
          'cost': costVal,
          'note': _orderNoteController.text.trim().isNotEmpty
              ? _orderNoteController.text.trim()
              : 'Commande $_orderType - $_orderArticle',
        },
      );

      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop(); // dismiss loading dialog
        widget.onOrderAdded();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Commande auprès de "$supplierName" planifiée avec succès !')),
        );
      }
    } catch (error) {
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop(); // dismiss loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Impossible d\'enregistrer la commande : $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _syncOrderArticleForType() {
    final articles = _getArticlesForType();
    if (!articles.contains(_orderArticle)) {
      _orderArticle = articles.first;
    }
  }

  List<String> _getArticlesForType() {
    final rawOptions = {
      'aliment': [
        'Aliments',
      ],
      'sanitaire': [
        'Produit veto',
      ],
      'volaille': [
        'Volailles',
      ],
    };

    final options = <String>[];
    for (final article in (rawOptions[_orderType] ?? rawOptions['aliment']!)) {
      if (!options.contains(article)) {
        options.add(article);
      }
    }

    if (!options.contains(_orderArticle) && options.isNotEmpty) {
      _orderArticle = options.first;
    }

    return options;
  }

  String _formatDate(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
  }
}
