import 'package:flutter/material.dart';
import '../../../../config/theme/app_theme.dart';
import '../../../shared/widgets/common_widgets.dart';

class M4ClientsListView extends StatefulWidget {
  const M4ClientsListView({super.key});

  @override
  State<M4ClientsListView> createState() => _M4ClientsListViewState();
}

class _M4ClientsListViewState extends State<M4ClientsListView> {
  bool _isAddingClient = false;
  String _searchQuery = '';

  // New client form states
  final TextEditingController _clientNameController = TextEditingController();
  final TextEditingController _clientPhoneController = TextEditingController();
  final TextEditingController _clientAddressController = TextEditingController();
  String _clientTypeSelection = 'retailer'; // retailer, wholesaler, restaurant

  // Mock clients directory
  final List<Map<String, dynamic>> _clientsList = [
    {
      'name': 'Adjoua Tanoh',
      'type': 'Détaillante',
      'tag': 'retailer',
      'phone': '07 08 09 10 11',
      'address': 'Akoupé Marché',
      'due': 18500,
      'status': 'échéance 12/08',
    },
    {
      'name': 'Koffi Mensah',
      'type': 'Restaurateur',
      'tag': 'restaurant',
      'phone': '05 06 07 08 09',
      'address': 'Gendarmerie route',
      'due': 42000,
      'status': 'échéance 15/08',
    },
    {
      'name': 'Rokia Bamba',
      'type': 'Détaillante',
      'tag': 'wholesaler',
      'phone': '01 02 03 04 05',
      'address': 'Akoupé Nord',
      'due': 0,
      'status': 'à jour',
    },
    {
      'name': 'Seydou Yao',
      'type': 'Grossiste',
      'tag': 'wholesaler',
      'phone': '07 47 48 49 50',
      'address': 'Gare routière',
      'due': 65000,
      'status': 'échéance dépassée',
    },
  ];

  @override
  void dispose() {
    _clientNameController.dispose();
    _clientPhoneController.dispose();
    _clientAddressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isAddingClient) {
      return _buildNewClientForm();
    }
    return _buildClientsList();
  }

  Widget _buildClientsList() {
    final filtered = _clientsList.where((c) {
      return c['name'].toString().toLowerCase().contains(_searchQuery.toLowerCase()) ||
          c['type'].toString().toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    return Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search Field
          AppInputBox(
            placeholder: 'Rechercher un client…',
            suffix: const Icon(Icons.search, color: AppColors.inkSoft),
            onChanged: (val) {
              setState(() {
                _searchQuery = val;
              });
            },
          ),
          const SizedBox(height: 16),

          const Text('COMPTES CLIENTS ACTIFS', style: AppTypography.labelSmall),
          const SizedBox(height: 9),

          Expanded(
            child: ListView.builder(
              itemCount: filtered.length,
              itemBuilder: (context, index) {
                final c = filtered[index];
                final bool hasDue = c['due'] > 0;
                final bool isLate = c['status'] == 'échéance dépassée';

                return Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: const BoxDecoration(
                    border: Border(bottom: BorderSide(color: AppColors.line)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: isLate
                              ? AppColors.errorLight
                              : (hasDue ? AppColors.warningLight : AppColors.primaryLight),
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          c['name'].toString().substring(0, 2).toUpperCase(),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isLate
                                ? AppColors.danger
                                : (hasDue ? AppColors.warning : AppColors.primaryDark),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              c['name'],
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5),
                            ),
                            Text(
                              '${c['type']}  ·  ${c['status']}',
                              style: TextStyle(
                                fontSize: 11.5,
                                color: isLate ? AppColors.danger : AppColors.inkSoft,
                                fontWeight: isLate ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${c['due']} FCFA',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13.5,
                              color: isLate ? AppColors.danger : AppColors.primaryDark,
                            ),
                          ),
                          const Text(
                            'dus',
                            style: TextStyle(color: AppColors.inkSoft, fontSize: 10),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          // Add client button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _isAddingClient = true;
                  _clientNameController.clear();
                  _clientPhoneController.clear();
                  _clientAddressController.clear();
                  _clientTypeSelection = 'retailer';
                });
              },
              icon: const Icon(Icons.person_add, size: 16),
              label: const Text('Nouveau client'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNewClientForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('AJOUTER UN CLIENT', style: AppTypography.label),
          const SizedBox(height: 16),
          AppInputBox(
            label: 'Nom complet',
            placeholder: 'Ex : Akissi Delphine',
            controller: _clientNameController,
          ),
          const SizedBox(height: 14),

          const Text('Type de client', style: AppTypography.label),
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
                value: _clientTypeSelection,
                isExpanded: true,
                onChanged: (val) {
                  if (val != null) {
                    setState(() => _clientTypeSelection = val);
                  }
                },
                items: const [
                  DropdownMenuItem(value: 'retailer', child: Text('Détaillant(e)')),
                  DropdownMenuItem(value: 'wholesaler', child: Text('Grossiste')),
                  DropdownMenuItem(value: 'restaurant', child: Text('Restaurateur')),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),

          AppInputBox(
            label: 'Téléphone',
            placeholder: 'Ex : 07 00 00 00 00',
            controller: _clientPhoneController,
          ),
          const SizedBox(height: 14),

          AppInputBox(
            label: 'Adresse / zone',
            placeholder: 'Ex : Akoupé centre',
            controller: _clientAddressController,
          ),
          const SizedBox(height: 24),

          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    setState(() {
                      _isAddingClient = false;
                    });
                  },
                  child: const Text('Annuler'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    if (_clientNameController.text.isEmpty || _clientPhoneController.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Veuillez remplir le nom et le téléphone')),
                      );
                      return;
                    }

                    String clientTypeLabel = 'Détaillante';
                    if (_clientTypeSelection == 'wholesaler') clientTypeLabel = 'Grossiste';
                    if (_clientTypeSelection == 'restaurant') clientTypeLabel = 'Restaurateur';

                    setState(() {
                      _clientsList.add({
                        'name': _clientNameController.text,
                        'type': clientTypeLabel,
                        'tag': _clientTypeSelection,
                        'phone': _clientPhoneController.text,
                        'address': _clientAddressController.text,
                        'due': 0,
                        'status': 'à jour',
                      });
                      _isAddingClient = false;
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Client enregistré avec succès')),
                    );
                  },
                  child: const Text('Enregistrer'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
