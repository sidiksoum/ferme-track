import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../config/theme/app_theme.dart';
import '../../../shared/widgets/common_widgets.dart';
import '../../../providers/auth_provider.dart';

/// Warehouse Manager main screen combining sales, stock, and clients (M1 - M7)
class SalesScreen extends StatefulWidget {
  const SalesScreen({super.key});

  @override
  State<SalesScreen> createState() => _SalesScreenState();
}

class _SalesScreenState extends State<SalesScreen> {
  int _selectedNavIndex = 0;

  // M1 / M6 / M7 Sales states
  String _salesPage = 'cash'; // cash, credit, refund
  int _cartQuantity1 = 1;
  int _cartQuantity2 = 2;
  
  // M3 Egg reception states
  int _announcedEggs = 1664;
  int _verifiedEggs = 1660;
  final TextEditingController _eggCommentController = TextEditingController(text: 'Casse durant le transport…');

  // M4 Stock movements states
  String _stockMovementType = 'in'; // in, out
  String _stockArticle = 'Alvéole d\'œufs (30)';
  int _stockQty = 50;
  String _stockProvenance = 'A'; // A, B

  // M2 / M5 Client states
  bool _isAddingClient = false;
  String _clientType = 'retailer'; // retailer, wholesaler, restaurant

  // Mock repayment state
  int _repaymentAmount = 25000;
  String _repaymentMethod = 'cash'; // cash, mobile_money

  @override
  void dispose() {
    _eggCommentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authNotifier = context.watch<AuthNotifier>();
    final userName = authNotifier.currentUser?.fullName ?? 'Magasinier';

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAF7),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_getAppBarTitle()),
            Text(
              _getAppBarSubtitle(),
              style: AppTypography.appbarSubtitle,
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            tooltip: 'Se déconnecter',
            onPressed: () async {
              await authNotifier.logout();
            },
          ),
        ],
      ),
      body: _buildBody(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedNavIndex,
        onTap: (index) {
          setState(() {
            _selectedNavIndex = index;
            _isAddingClient = false;
            _salesPage = 'cash';
          });
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.primaryDark,
        unselectedItemColor: const Color(0xFF9AA79C),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_cart),
            label: 'Ventes',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.inbox),
            label: 'Réceptions',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.storage),
            label: 'Stock',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Clients',
          ),
        ],
      ),
    );
  }

  String _getAppBarTitle() {
    switch (_selectedNavIndex) {
      case 0:
        if (_salesPage == 'credit') return 'Vente à crédit';
        if (_salesPage == 'refund') return 'Remboursement';
        return 'Nouvelle vente';
      case 1:
        return 'Réception des œufs';
      case 2:
        return 'Mouvement de stock';
      case 3:
        return _isAddingClient ? 'Nouveau client' : 'Clients';
      default:
        return 'Magasinier';
    }
  }

  String _getAppBarSubtitle() {
    switch (_selectedNavIndex) {
      case 0:
        if (_salesPage == 'credit') return 'Client : Koffi Mensah';
        if (_salesPage == 'refund') return 'Seydou Yao';
        return 'Client : Mme Adjoua T.';
      case 1:
        return 'En provenance de Bâtiment A';
      case 2:
        return 'Magasin principal';
      case 3:
        return _isAddingClient ? 'Fiche d\'identité' : '24 comptes actifs';
      default:
        return 'Ferme Akoupé';
    }
  }

  Widget _buildBody() {
    switch (_selectedNavIndex) {
      case 0:
        if (_salesPage == 'credit') return _buildM6CreditSale();
        if (_salesPage == 'refund') return _buildM7Refund();
        return _buildM1CashSale();
      case 1:
        return _buildM3EggReception();
      case 2:
        return _buildM4StockMovements();
      case 3:
        return _isAddingClient ? _buildM5NewClient() : _buildM2ClientsList();
      default:
        return _buildM1CashSale();
    }
  }

  // --- M1: VENTE AU COMPTANT ---
  Widget _buildM1CashSale() {
    return Column(
      children: [
        // Comptant/Crédit top toggle
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
                  child: _buildSubTabButton('Comptant', _salesPage == 'cash', () {
                    setState(() => _salesPage = 'cash');
                  }),
                ),
                Expanded(
                  child: _buildSubTabButton('Crédit', _salesPage == 'credit', () {
                    setState(() => _salesPage = 'credit');
                  }),
                ),
              ],
            ),
          ),
        ),

        Expanded(
          child: GridView.count(
            crossAxisCount: 2,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            mainAxisSpacing: 9,
            crossAxisSpacing: 9,
            childAspectRatio: 0.82,
            children: [
              _buildProductCard('Plateau d\'œufs', '1 800 FCFA', Icons.egg, false),
              _buildProductCard('Alvéole (30)', '2 500 FCFA', Icons.egg, true),
              _buildProductCard('Poulet vif', '4 500 FCFA', Icons.pets, false),
              _buildProductCard('Sac aliment', '9 000 FCFA', Icons.shopping_bag, false),
            ],
          ),
        ),

        // Cart bar
        Container(
          color: AppColors.primaryDark,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text('2 articles', style: TextStyle(color: Colors.white70, fontSize: 10)),
                  Text(
                    '7 000 FCFA',
                    style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              GestureDetector(
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Vente enregistrée et encaissée')),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.accent,
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: const Text(
                    'Encaisser →',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primaryDark),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProductCard(String name, String price, IconData icon, bool selected) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.paper,
        border: Border.all(color: selected ? AppColors.primary : AppColors.line, width: 1.4),
        borderRadius: BorderRadius.circular(13),
      ),
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, size: 20, color: AppColors.primaryDark),
          ),
          const SizedBox(height: 7),
          Text(name, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
          const SizedBox(height: 2),
          Text(price, style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: AppColors.primaryDark)),
        ],
      ),
    );
  }

  // --- M6: VENTE À CRÉDIT ---
  Widget _buildM6CreditSale() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Comptant/Crédit top toggle
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFEFEFE7),
              borderRadius: BorderRadius.circular(11),
            ),
            padding: const EdgeInsets.all(3),
            child: Row(
              children: [
                Expanded(
                  child: _buildSubTabButton('Comptant', _salesPage == 'cash', () {
                    setState(() => _salesPage = 'cash');
                  }),
                ),
                Expanded(
                  child: _buildSubTabButton('Crédit', _salesPage == 'credit', () {
                    setState(() => _salesPage = 'credit');
                  }),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          const AppInputBox(
            label: 'Plafond de crédit',
            placeholder: '80 000 FCFA',
            readOnly: true,
          ),
          const SizedBox(height: 12),
          const AppInputBox(
            label: 'Solde actuel dû',
            placeholder: '42 000 FCFA',
            readOnly: true,
          ),
          const SizedBox(height: 12),
          const AppInputBox(
            label: 'Montant de la vente',
            placeholder: '15 000 FCFA',
          ),
          const SizedBox(height: 12),
          const AppInputBox(
            label: 'Échéance de remboursement',
            placeholder: '20 août 2026',
            suffix: Icon(Icons.calendar_today, size: 14, color: AppColors.inkSoft),
          ),
          const SizedBox(height: 16),

          const AlertRow(
            title: 'Nouveau solde : 57 000 FCFA',
            subtitle: 'Sous le plafond autorisé de 80 000 FCFA',
            type: AlertType.info,
          ),
          const SizedBox(height: 20),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                setState(() => _salesPage = 'cash');
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Vente à crédit accordée')),
                );
              },
              child: const Text('Valider la vente à crédit'),
            ),
          ),
        ],
      ),
    );
  }

  // --- M7: ENREGISTRER UN REMBOURSEMENT ---
  Widget _buildM7Refund() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.primaryDark,
              borderRadius: BorderRadius.circular(16),
            ),
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text('Solde restant dû', style: TextStyle(color: Colors.white70, fontSize: 10.5)),
                SizedBox(height: 2),
                Text(
                  '65 000 FCFA',
                  style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          const Text('MONTANT REMBOURSÉ', style: AppTypography.label),
          const SizedBox(height: 6),
          CounterBox(
            initialValue: _repaymentAmount,
            unit: 'FCFA',
            onChanged: (val) => setState(() => _repaymentAmount = val),
          ),
          const SizedBox(height: 14),

          const Text('MODE DE PAIEMENT', style: AppTypography.label),
          const SizedBox(height: 6),
          Row(
            children: [
              _buildFilterChip('Espèces', _repaymentMethod == 'cash', () {
                setState(() => _repaymentMethod = 'cash');
              }),
              _buildFilterChip('Mobile Money', _repaymentMethod == 'mobile_money', () {
                setState(() => _repaymentMethod = 'mobile_money');
              }),
            ],
          ),
          const SizedBox(height: 20),

          const Text('HISTORIQUE RÉCENT', style: AppTypography.labelSmall),
          const SizedBox(height: 9),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColors.line)),
            ),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: const BoxDecoration(
                    color: AppColors.successLight,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check, color: AppColors.primaryDark),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text('Remboursement', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5)),
                    Text('15 juillet · Espèces', style: TextStyle(color: AppColors.inkSoft, fontSize: 9)),
                  ],
                ),
                const Spacer(),
                const Text(
                  '+20 000 FCFA',
                  style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 12.5),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                setState(() => _salesPage = 'cash');
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Remboursement enregistré')),
                );
              },
              child: const Text('Enregistrer le remboursement'),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => setState(() => _salesPage = 'cash'),
              child: const Text('Retour'),
            ),
          ),
        ],
      ),
    );
  }

  // --- M3: RÉCEPTION DES ŒUFS ---
  Widget _buildM3EggReception() {
    final difference = _announcedEggs - _verifiedEggs;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('QUANTITÉ ANNONCÉE PAR LE VOLAILLER', style: AppTypography.labelSmall),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.paper,
              border: Border.all(color: AppColors.line, width: 1.4),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Ama Koffi — 07:05', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold)),
                Text('$_announcedEggs œufs', style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          const SizedBox(height: 14),

          const Text('QUANTITÉ VÉRIFIÉE EN MAGASIN', style: AppTypography.labelSmall),
          const SizedBox(height: 6),
          CounterBox(
            initialValue: _verifiedEggs,
            unit: 'œufs reçus',
            onChanged: (val) => setState(() => _verifiedEggs = val),
          ),
          const SizedBox(height: 14),

          if (difference != 0) ...[
            AlertRow(
              title: 'Écart de $difference œufs',
              subtitle: 'Un commentaire justificatif est requis',
              type: AlertType.warning,
            ),
            const SizedBox(height: 12),
          ],

          AppInputBox(
            label: 'Commentaire',
            controller: _eggCommentController,
          ),
          const SizedBox(height: 24),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Réception d\'œufs enregistrée avec succès')),
                );
              },
              child: const Text('Valider la réception'),
            ),
          ),
        ],
      ),
    );
  }

  // --- M4: MOUVEMENTS DE STOCK ---
  Widget _buildM4StockMovements() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFEFEFE7),
              borderRadius: BorderRadius.circular(11),
            ),
            padding: const EdgeInsets.all(3),
            child: Row(
              children: [
                Expanded(
                  child: _buildSubTabButton('Entrée', _stockMovementType == 'in', () {
                    setState(() => _stockMovementType = 'in');
                  }),
                ),
                Expanded(
                  child: _buildSubTabButton('Sortie', _stockMovementType == 'out', () {
                    setState(() => _stockMovementType = 'out');
                  }),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          const Text('ARTICLE', style: AppTypography.label),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.paper,
              borderRadius: BorderRadius.circular(11),
              border: Border.all(color: AppColors.line, width: 1.4),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _stockArticle,
                isExpanded: true,
                onChanged: (val) {
                  if (val != null) setState(() => _stockArticle = val);
                },
                items: const [
                  DropdownMenuItem(value: 'Alvéole d\'œufs (30)', child: Text('Alvéole d\'œufs (30)')),
                  DropdownMenuItem(value: 'Aliment ponte 20 kg', child: Text('Aliment ponte 20 kg')),
                  DropdownMenuItem(value: 'Poulet vif', child: Text('Poulet vif')),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),

          const Text('QUANTITÉ', style: AppTypography.label),
          const SizedBox(height: 6),
          CounterBox(
            initialValue: _stockQty,
            unit: 'unités',
            onChanged: (val) => setState(() => _stockQty = val),
          ),
          const SizedBox(height: 14),

          const Text('PROVENANCE / DESTINATION', style: AppTypography.label),
          const SizedBox(height: 6),
          Row(
            children: [
              _buildFilterChip('Bâtiment A', _stockProvenance == 'A', () {
                setState(() => _stockProvenance = 'A');
              }),
              _buildFilterChip('Bâtiment B', _stockProvenance == 'B', () {
                setState(() => _stockProvenance = 'B');
              }),
            ],
          ),
          const SizedBox(height: 24),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Mouvement de stock enregistré')),
                );
              },
              child: const Text('Enregistrer le mouvement'),
            ),
          ),
        ],
      ),
    );
  }

  // --- M2: CLIENTS & CRÉANCES ---
  Widget _buildM2ClientsList() {
    final clients = [
      {'name': 'Adjoua Tanoh', 'type': 'Détaillante · échéance 12/08', 'balance': 18500, 'overdue': false},
      {'name': 'Koffi Mensah', 'type': 'Restaurateur · échéance 15/08', 'balance': 42000, 'overdue': false},
      {'name': 'Rokia Bamba', 'type': 'Détaillante · à jour', 'balance': 0, 'overdue': false},
      {'name': 'Seydou Yao', 'type': 'Grossiste · échéance dépassée', 'balance': 65000, 'overdue': true},
    ];

    return Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search box
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            decoration: BoxDecoration(
              color: AppColors.paper,
              border: Border.all(color: AppColors.line, width: 1.4),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Row(
              children: const [
                Icon(Icons.search, size: 14, color: AppColors.inkSoft),
                SizedBox(width: 8),
                Text('Rechercher un client…', style: TextStyle(color: AppColors.inkSoft, fontSize: 11.5)),
              ],
            ),
          ),
          const SizedBox(height: 14),

          Expanded(
            child: ListView.builder(
              itemCount: clients.length,
              itemBuilder: (context, index) {
                final c = clients[index];
                final isRed = c['overdue'] == true;
                final isZero = c['balance'] == 0;

                return GestureDetector(
                  onTap: () {
                    if (c['name'] == 'Seydou Yao') {
                      setState(() {
                        _salesPage = 'refund';
                        _selectedNavIndex = 0; // Redirect to repayment form
                      });
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: const BoxDecoration(
                      border: Border(bottom: BorderSide(color: AppColors.line)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 34,
                          height: 34,
                          decoration: const BoxDecoration(
                            color: AppColors.primaryLight,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            (c['name'] as String).split(' ').map((e) => e[0]).join(),
                            style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryDark),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(c['name'] as String, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5)),
                            Text(c['type'] as String, style: TextStyle(color: isRed ? AppColors.danger : AppColors.inkSoft, fontSize: 10)),
                          ],
                        ),
                        const Spacer(),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '${c['balance']} FCFA',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                                color: isZero ? AppColors.primary : (isRed ? AppColors.danger : AppColors.ink),
                              ),
                            ),
                            const Text('dus', style: TextStyle(color: AppColors.inkSoft, fontSize: 9)),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => setState(() => _isAddingClient = true),
              child: const Text('+ Nouveau client'),
            ),
          ),
        ],
      ),
    );
  }

  // --- M5: NOUVELLE FICHE CLIENT ---
  Widget _buildM5NewClient() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppInputBox(
            label: 'Identité',
            placeholder: 'Nom et prénoms',
          ),
          const SizedBox(height: 12),
          const AppInputBox(
            label: 'Téléphone',
            placeholder: '+225 …',
          ),
          const SizedBox(height: 12),
          const AppInputBox(
            label: 'Adresse',
            placeholder: 'Quartier, commune',
          ),
          const SizedBox(height: 12),

          const Text('TYPE DE CLIENT', style: AppTypography.label),
          const SizedBox(height: 6),
          Row(
            children: [
              _buildFilterChip('Détaillant', _clientType == 'retailer', () {
                setState(() => _clientType = 'retailer');
              }),
              _buildFilterChip('Grossiste', _clientType == 'wholesaler', () {
                setState(() => _clientType = 'wholesaler');
              }),
              _buildFilterChip('Restaurateur', _clientType == 'restaurant', () {
                setState(() => _clientType = 'restaurant');
              }),
            ],
          ),
          const SizedBox(height: 24),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                setState(() => _isAddingClient = false);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Nouveau client ajouté')),
                );
              },
              child: const Text('Créer la fiche client'),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => setState(() => _isAddingClient = false),
              child: const Text('Annuler'),
            ),
          ),
        ],
      ),
    );
  }

  // --- HELPER COMPONENT BUILDERS ---
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
            fontSize: 10,
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
