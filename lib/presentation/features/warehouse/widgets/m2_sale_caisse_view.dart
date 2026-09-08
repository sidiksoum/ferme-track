import 'package:flutter/material.dart';
import '../../../../config/theme/app_theme.dart';
import '../../../shared/widgets/common_widgets.dart';

class M2SaleCaisseView extends StatefulWidget {
  const M2SaleCaisseView({super.key});

  @override
  State<M2SaleCaisseView> createState() => _M2SaleCaisseViewState();
}

class _M2SaleCaisseViewState extends State<M2SaleCaisseView> {
  String _activeSubTab = 'history'; // history, refund
  bool _isAddingVente = false;

  // Search/Filter states
  String _clientSearchQuery = '';
  DateTime? _selectedFilterDate;

  // New Sale Form Controllers
  final TextEditingController _clientNameController = TextEditingController();
  final TextEditingController _clientContactController =
      TextEditingController();
  final TextEditingController _clientAddressController =
      TextEditingController();
  final TextEditingController _totalSaleAmountController =
      TextEditingController();
  final TextEditingController _paidAmountController = TextEditingController();
  final Map<String, TextEditingController> _quantityControllers = {};

  // Egg formats quantities for sale
  int _qtyPetit = 0;
  int _qtyMoyen = 0;
  int _qtyGros = 0;
  int _qtyPlusGros = 0;

  DateTime? _dueDate;

  // Mock Sales History
  final List<Map<String, dynamic>> _salesHistory = [
    {
      'date': DateTime.now().subtract(const Duration(hours: 2)),
      'client': 'Client de passage',
      'contact': '—',
      'address': '—',
      'details': '10 plateaux Moyen format',
      'amount': 18000,
      'paid': 18000,
      'due': 0,
      'status': 'Payé',
    },
    {
      'date': DateTime.now().subtract(const Duration(days: 1)),
      'client': 'Adjoua Tanoh',
      'contact': '07 08 09 10 11',
      'address': 'Akoupé Marché',
      'details': '20 plateaux Gros format',
      'amount': 44000,
      'paid': 25500,
      'due': 18500,
      'status': 'Partiel',
    },
    {
      'date': DateTime.now().subtract(const Duration(days: 3)),
      'client': 'Seydou Yao',
      'contact': '07 47 48 49 50',
      'address': 'Gare routière',
      'details': '40 plateaux Plus Gros format',
      'amount': 100000,
      'paid': 35000,
      'due': 65000,
      'status': 'Crédit',
    },
  ];

  // Mock Debtors/Créanciers
  final List<Map<String, dynamic>> _debtors = [
    {
      'name': 'Seydou Yao',
      'due': 65000,
      'status': 'Échéance dépassée (12/08)',
      'isOverdue': true,
    },
    {
      'name': 'Koffi Mensah',
      'due': 42000,
      'status': 'Échéance 25/08',
      'isOverdue': false,
    },
    {
      'name': 'Adjoua Tanoh',
      'due': 18500,
      'status': 'Échéance 28/08',
      'isOverdue': false,
    },
  ];

  int get _totalSaleAmount =>
      int.tryParse(_totalSaleAmountController.text) ?? 0;

  int get _remainingToPay {
    final paid = int.tryParse(_paidAmountController.text) ?? 0;
    return (_totalSaleAmount - paid).clamp(0, 10000000);
  }

  @override
  void dispose() {
    _clientNameController.dispose();
    _clientContactController.dispose();
    _clientAddressController.dispose();
    _totalSaleAmountController.dispose();
    _paidAmountController.dispose();
    for (final controller in _quantityControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isAddingVente) {
      return _buildNewSaleForm();
    }

    return Column(
      children: [
        // Tabs (Historique / Remboursement)
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
                    'Historique',
                    _activeSubTab == 'history',
                    () => setState(() => _activeSubTab = 'history'),
                  ),
                ),
                Expanded(
                  child: _buildSubTabButton(
                    'Remboursement',
                    _activeSubTab == 'refund',
                    () => setState(() => _activeSubTab = 'refund'),
                  ),
                ),
              ],
            ),
          ),
        ),

        Expanded(
          child: _activeSubTab == 'history'
              ? _buildHistoryTab()
              : _buildReimbursementTab(),
        ),
      ],
    );
  }

  // --- TAB 1: SALES HISTORY ---
  Widget _buildHistoryTab() {
    final filteredSales = _salesHistory.where((sale) {
      final nameMatches = sale['client'].toString().toLowerCase().contains(
        _clientSearchQuery.toLowerCase(),
      );
      if (_selectedFilterDate == null) return nameMatches;
      final saleDate = sale['date'] as DateTime;
      return nameMatches &&
          saleDate.year == _selectedFilterDate!.year &&
          saleDate.month == _selectedFilterDate!.month &&
          saleDate.day == _selectedFilterDate!.day;
    }).toList();

    return Column(
      children: [
        // Filters Box
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Column(
            children: [
              AppInputBox(
                placeholder: 'Filtrer par nom de client…',
                suffix: const Icon(
                  Icons.search,
                  size: 18,
                  color: AppColors.inkSoft,
                ),
                onChanged: (val) => setState(() => _clientSearchQuery = val),
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(2025),
                    lastDate: DateTime(2027),
                  );
                  if (picked != null) {
                    setState(() => _selectedFilterDate = picked);
                  }
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.paper,
                    border: Border.all(color: AppColors.line),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.calendar_today,
                        size: 16,
                        color: AppColors.inkSoft,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _selectedFilterDate == null
                              ? 'Filtrer par date (Toutes dates)'
                              : 'Date : ${_formatDate(_selectedFilterDate!)}',
                          style: TextStyle(
                            fontSize: 12.5,
                            color: _selectedFilterDate == null
                                ? AppColors.inkSoft
                                : AppColors.primaryDark,
                            fontWeight: _selectedFilterDate == null
                                ? FontWeight.normal
                                : FontWeight.bold,
                          ),
                        ),
                      ),
                      if (_selectedFilterDate != null)
                        GestureDetector(
                          onTap: () =>
                              setState(() => _selectedFilterDate = null),
                          child: const Icon(
                            Icons.clear,
                            size: 16,
                            color: AppColors.inkSoft,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // List
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            itemCount: filteredSales.length,
            itemBuilder: (context, index) {
              final sale = filteredSales[index];
              Color statusColor = AppColors.primary;
              if (sale['status'] == 'Crédit') statusColor = AppColors.danger;
              if (sale['status'] == 'Partiel') statusColor = AppColors.accent;

              return Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: AppColors.line)),
                ),
                child: Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          sale['client'] as String,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13.5,
                          ),
                        ),
                        Text(
                          '${sale['details']} · ${_formatDate(sale['date'] as DateTime)}',
                          style: const TextStyle(
                            color: AppColors.inkSoft,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${sale['amount']} FCFA',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            sale['status'] as String,
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: statusColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ),

        // Effectuer une vente Sticky Bar
        Container(
          padding: const EdgeInsets.all(12),
          decoration: const BoxDecoration(
            color: AppColors.paper,
            border: Border(top: BorderSide(color: AppColors.line)),
          ),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                setState(() {
                  _isAddingVente = true;
                  _clientNameController.clear();
                  _clientContactController.clear();
                  _clientAddressController.clear();
                  _paidAmountController.clear();
                  _totalSaleAmountController.clear();
                  _qtyPetit = 0;
                  _qtyMoyen = 0;
                  _qtyGros = 0;
                  _qtyPlusGros = 0;
                  _dueDate = null;
                });
              },
              child: const Text('Effectuer une vente'),
            ),
          ),
        ),
      ],
    );
  }

  // --- TAB 2: REIMBURSEMENT (CREDITORS LIST) ---
  Widget _buildReimbursementTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(14),
      itemCount: _debtors.length,
      itemBuilder: (context, index) {
        final debtor = _debtors[index];
        return Container(
          padding: const EdgeInsets.all(12),
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: AppColors.paper,
            border: Border.all(color: AppColors.line),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: debtor['isOverdue']
                      ? AppColors.errorLight
                      : AppColors.warningLight,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  debtor['name'].toString().substring(0, 2).toUpperCase(),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: debtor['isOverdue']
                        ? AppColors.danger
                        : AppColors.warning,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      debtor['name'] as String,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13.5,
                      ),
                    ),
                    Text(
                      debtor['status'] as String,
                      style: TextStyle(
                        color: debtor['isOverdue']
                            ? AppColors.danger
                            : AppColors.inkSoft,
                        fontSize: 11,
                        fontWeight: debtor['isOverdue']
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () => _showRepaymentDialog(debtor),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  minimumSize: Size.zero,
                ),
                child: const Text(
                  'Rembourser',
                  style: TextStyle(fontSize: 11.5),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // --- REPAYMENT/REMBOURSEMENT DIALOG ---
  void _showRepaymentDialog(Map<String, dynamic> debtor) {
    final refundController = TextEditingController();
    String method = 'espèces';
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text('Remboursement : ${debtor['name']}'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Créance restante due : ${debtor['due']} FCFA'),
                  const SizedBox(height: 12),
                  const Text(
                    'Montant remboursé (FCFA) :',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: refundController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      hintText: 'Ex: 20000',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Mode de paiement :',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Radio<String>(
                        value: 'espèces',
                        groupValue: method,
                        activeColor: AppColors.primaryDark,
                        onChanged: (val) => setDialogState(() => method = val!),
                      ),
                      const Text('Espèces'),
                      const SizedBox(width: 14),
                      Radio<String>(
                        value: 'mobile_money',
                        groupValue: method,
                        activeColor: AppColors.primaryDark,
                        onChanged: (val) => setDialogState(() => method = val!),
                      ),
                      const Text('MOMo'),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Annuler'),
                ),
                ElevatedButton(
                  onPressed: () {
                    final int amt = int.tryParse(refundController.text) ?? 0;
                    if (amt <= 0 || amt > debtor['due']) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Veuillez entrer un montant valide'),
                        ),
                      );
                      return;
                    }
                    setState(() {
                      debtor['due'] = debtor['due'] - amt;
                      if (debtor['due'] == 0) {
                        debtor['status'] = 'Réglé';
                      } else {
                        debtor['status'] =
                            'Créance mise à jour (${debtor['due']} FCFA restant)';
                      }
                    });
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Remboursement de $amt FCFA enregistré avec succès !',
                        ),
                      ),
                    );
                  },
                  child: const Text('Enregistrer'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // --- FORM 3: EFFECTUER UNE VENTE FORM ---
  Widget _buildNewSaleForm() {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.primaryDark),
          onPressed: () => setState(() => _isAddingVente = false),
        ),
        title: const Text(
          'Effectuer une vente',
          style: TextStyle(
            color: AppColors.primaryDark,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Client details
            const Text('CLIENT & CONTACTS', style: AppTypography.label),
            const SizedBox(height: 8),
            AppInputBox(
              label: 'Nom complet du client',
              placeholder: 'Ex : Adjoua Tanoh',
              controller: _clientNameController,
            ),
            const SizedBox(height: 10),
            AppInputBox(
              label: 'Numéro de contact',
              placeholder: 'Ex : 07 08 09 10 11',
              controller: _clientContactController,
            ),
            const SizedBox(height: 10),
            AppInputBox(
              label: 'Adresse',
              placeholder: 'Ex : Marché d\'Akoupé',
              controller: _clientAddressController,
            ),
            const SizedBox(height: 16),

            // Formats counts
            const Text(
              'SÉLECTIONNER LES FORMATS & QUANTITÉS (ALVÉOLES)',
              style: AppTypography.label,
            ),
            const SizedBox(height: 8),
            _buildFormatInputRow(
              'Petit format',
              _qtyPetit,
              (val) => setState(() => _qtyPetit = val),
            ),
            _buildFormatInputRow(
              'Moyen format',
              _qtyMoyen,
              (val) => setState(() => _qtyMoyen = val),
            ),
            _buildFormatInputRow(
              'Gros format',
              _qtyGros,
              (val) => setState(() => _qtyGros = val),
            ),
            _buildFormatInputRow(
              'Plus gros format',
              _qtyPlusGros,
              (val) => setState(() => _qtyPlusGros = val),
            ),
            const SizedBox(height: 16),

            // Payment tracking
            const Text('PAIEMENT & CALCULS', style: AppTypography.label),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.paper,
                border: Border.all(color: AppColors.line),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  AppInputBox(
                    label: 'Montant total (FCFA)',
                    placeholder: 'Saisissez le montant total',
                    controller: _totalSaleAmountController,
                    inputType: TextInputType.number,
                    onChanged: (_) => setState(() {}),
                  ),
                  const Divider(height: 16, color: AppColors.line),
                  AppInputBox(
                    label: 'Montant payé (FCFA)',
                    placeholder: 'Ex : 10000',
                    controller: _paidAmountController,
                    onChanged: (val) => setState(() {}),
                  ),
                  const SizedBox(height: 10),
                  _buildCalculationRow(
                    'Reste à payer',
                    '$_remainingToPay FCFA',
                    valueColor: _remainingToPay > 0
                        ? AppColors.danger
                        : AppColors.primaryDark,
                    isBold: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Due date if credit
            if (_remainingToPay > 0) ...[
              const Text(
                'ÉCHÉANCE DU CRÉDIT (REQUIS)',
                style: AppTypography.label,
              ),
              const SizedBox(height: 6),
              GestureDetector(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now().add(const Duration(days: 7)),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 90)),
                  );
                  if (picked != null) {
                    setState(() => _dueDate = picked);
                  }
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.paper,
                    border: Border.all(color: AppColors.line, width: 1.6),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.calendar_today,
                        size: 16,
                        color: AppColors.inkSoft,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _dueDate == null
                            ? 'Choisir la date d\'échéance'
                            : _formatDate(_dueDate!),
                        style: TextStyle(
                          color: _dueDate == null
                              ? AppColors.inkSoft
                              : AppColors.primaryDark,
                          fontWeight: _dueDate == null
                              ? FontWeight.normal
                              : FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Submit Vente
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed:
                    (_totalSaleAmount == 0 ||
                        (_remainingToPay > 0 && _dueDate == null) ||
                        _clientNameController.text.isEmpty)
                    ? null
                    : () {
                        setState(() {
                          _salesHistory.insert(0, {
                            'date': DateTime.now(),
                            'client': _clientNameController.text,
                            'contact': _clientContactController.text,
                            'address': _clientAddressController.text,
                            'details': 'Achat formats variés',
                            'amount': _totalSaleAmount,
                            'paid':
                                int.tryParse(_paidAmountController.text) ?? 0,
                            'due': _remainingToPay,
                            'status': _remainingToPay == 0
                                ? 'Payé'
                                : (_remainingToPay == _totalSaleAmount
                                      ? 'Crédit'
                                      : 'Partiel'),
                          });

                          if (_remainingToPay > 0) {
                            _debtors.add({
                              'name': _clientNameController.text,
                              'due': _remainingToPay,
                              'status': 'Échéance ${_formatDate(_dueDate!)}',
                              'isOverdue': false,
                            });
                          }
                          _isAddingVente = false;
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Vente enregistrée avec succès !'),
                          ),
                        );
                      },
                child: const Text('Valider la vente'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormatInputRow(
    String label,
    int value,
    Function(int) onChanged,
  ) {
    final controller = _quantityControllers.putIfAbsent(
      label,
      () => TextEditingController(text: value.toString()),
    );
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
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5),
          ),
          Row(
            children: [
              GestureDetector(
                onTap: () {
                  final next = (value - 1).clamp(0, 10000);
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
                  final next = (value + 1).clamp(0, 10000);
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

  Widget _buildCalculationRow(
    String label,
    String val, {
    bool isBold = false,
    Color? valueColor,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(color: AppColors.inkSoft, fontSize: 12.5),
        ),
        Text(
          val,
          style: TextStyle(
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            color: valueColor ?? AppColors.primaryDark,
            fontSize: 13,
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

  String _formatDate(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
  }
}
