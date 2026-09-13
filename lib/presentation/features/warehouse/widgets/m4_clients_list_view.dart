import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../config/theme/app_theme.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/interfaces/network_checker.dart';
import '../../../../core/services/offline_sync_service.dart';
import '../../../../core/services/socket_client_service.dart';
import '../../../../data/datasources/remote/api_client.dart';
import '../../../shared/widgets/common_widgets.dart';

class M4ClientsListView extends StatefulWidget {
  const M4ClientsListView({super.key});

  @override
  State<M4ClientsListView> createState() => _M4ClientsListViewState();
}

class _M4ClientsListViewState extends State<M4ClientsListView> {
  final ApiClient _apiClient = getIt<ApiClient>();
  final SocketClientService _socketService = getIt<SocketClientService>();
  final OfflineSyncService _offlineSyncService = getIt<OfflineSyncService>();
  final NetworkChecker _networkChecker = getIt<NetworkChecker>();
  StreamSubscription? _socketSubscription;

  bool _isAddingClient = false;
  bool _isLoading = false;
  String _searchQuery = '';

  // New client form states
  final TextEditingController _clientNameController = TextEditingController();
  final TextEditingController _clientPhoneController = TextEditingController();
  final TextEditingController _clientAddressController = TextEditingController();
  String _clientTypeSelection = 'retailer'; // retailer, wholesaler, restaurant

  // Clients directory
  List<Map<String, dynamic>> _clientsList = [
    {
      'id': 'c-1',
      'name': 'Adjoua Tanoh',
      'type': 'Détaillante',
      'tag': 'retailer',
      'phone': '07 08 09 10 11',
      'address': 'Akoupé Marché',
      'due': 18500,
      'status': 'échéance 12/08',
    },
    {
      'id': 'c-2',
      'name': 'Koffi Mensah',
      'type': 'Restaurateur',
      'tag': 'restaurant',
      'phone': '05 06 07 08 09',
      'address': 'Gendarmerie route',
      'due': 42000,
      'status': 'échéance 15/08',
    },
    {
      'id': 'c-3',
      'name': 'Rokia Bamba',
      'type': 'Détaillante',
      'tag': 'wholesaler',
      'phone': '01 02 03 04 05',
      'address': 'Akoupé Nord',
      'due': 0,
      'status': 'à jour',
    },
    {
      'id': 'c-4',
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
  void initState() {
    super.initState();
    _loadClients();

    // Écoute temps réel Socket.IO pour rafraîchissement instantané
    _socketSubscription = _socketService.allEvents.listen((event) {
      final evt = event['event']?.toString() ?? '';
      if (evt == 'sale:created' || evt.contains('client')) {
        if (mounted) {
          _loadClients(forceRefresh: true);
        }
      }
    });
  }

  @override
  void dispose() {
    _socketSubscription?.cancel();
    _clientNameController.dispose();
    _clientPhoneController.dispose();
    _clientAddressController.dispose();
    super.dispose();
  }

  Future<void> _loadClients({bool forceRefresh = false}) async {
    if (!mounted) return;
    if (_clientsList.isEmpty) {
      setState(() => _isLoading = true);
    }

    try {
      final response = await _apiClient.get(
        '/magasinier/clients',
        forceRefresh: forceRefresh,
        useCache: true,
      );
      if (mounted && response is List && response.isNotEmpty) {
        setState(() {
          _clientsList = response.map<Map<String, dynamic>>((c) {
            return {
              'id': c['id']?.toString() ?? '',
              'name': c['name']?.toString() ?? '',
              'type': c['type']?.toString() ?? 'Détaillante',
              'tag': c['tag']?.toString() ?? 'retailer',
              'phone': c['phone']?.toString() ?? '—',
              'address': c['address']?.toString() ?? '—',
              'due': (c['due'] as num?)?.toInt() ?? (c['balance'] as num?)?.toInt() ?? 0,
              'status': c['status']?.toString() ?? 'à jour',
            };
          }).toList();
        });
      }
    } catch (_) {
      // Keep offline list on error
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
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
          c['type'].toString().toLowerCase().contains(_searchQuery.toLowerCase()) ||
          c['phone'].toString().toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    return Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search Field
          AppInputBox(
            placeholder: 'Rechercher un client ou contact…',
            suffix: const Icon(Icons.search, color: AppColors.inkSoft),
            onChanged: (val) {
              setState(() {
                _searchQuery = val;
              });
            },
          ),
          const SizedBox(height: 16),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('COMPTES CLIENTS ACTIFS (${filtered.length})', style: AppTypography.labelSmall),
              if (_isLoading)
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
            ],
          ),
          const SizedBox(height: 9),

          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadClients,
              child: filtered.isEmpty
                  ? const Center(
                      child: Text(
                        'Aucun client trouvé',
                        style: TextStyle(color: AppColors.inkSoft),
                      ),
                    )
                  : ListView.builder(
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final c = filtered[index];
                        final dueAmt = (c['due'] as num?)?.toInt() ?? 0;
                        final bool hasDue = dueAmt > 0;
                        final bool isLate = c['status'].toString().contains('dépassée');

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
                                  c['name'].toString().isNotEmpty
                                      ? c['name'].toString().substring(0, 2).toUpperCase()
                                      : 'CL',
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
                                      c['name'] as String,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${c['type']}  ·  ${c['phone']}  ·  ${c['status']}',
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
                                    '$dueAmt FCFA',
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
          const Text('AJOUTER UN NOUVEAU CLIENT', style: AppTypography.label),
          const SizedBox(height: 16),
          AppInputBox(
            label: 'Nom complet du client',
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
            label: 'Numéro de Téléphone',
            placeholder: 'Ex : 07 00 00 00 00',
            controller: _clientPhoneController,
          ),
          const SizedBox(height: 14),

          AppInputBox(
            label: 'Adresse / Zone de distribution',
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
                  onPressed: () async {
                    if (_clientNameController.text.trim().isEmpty || _clientPhoneController.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Veuillez remplir le nom et le téléphone')),
                      );
                      return;
                    }

                    String clientTypeLabel = 'Détaillante';
                    if (_clientTypeSelection == 'wholesaler') clientTypeLabel = 'Grossiste';
                    if (_clientTypeSelection == 'restaurant') clientTypeLabel = 'Restaurateur';

                    final clientData = {
                      'name': _clientNameController.text.trim(),
                      'phone': _clientPhoneController.text.trim(),
                      'contact': _clientPhoneController.text.trim(),
                      'address': _clientAddressController.text.trim(),
                      'client_type': _clientTypeSelection,
                    };

                    showActionLoadingDialog(context, message: 'Enregistrement du client...');
                    bool isOfflineQueued = false;
                    try {
                      final isOnline = await _networkChecker.hasConnection;
                      if (!isOnline) {
                        await _offlineSyncService.enqueueOperation(
                          endpoint: '/magasinier/clients',
                          method: 'POST',
                          payload: clientData,
                          description: 'Nouveau client: ${_clientNameController.text.trim()}',
                        );
                        isOfflineQueued = true;
                      } else {
                        await _apiClient.post(
                          '/magasinier/clients',
                          data: clientData,
                        );
                      }
                    } catch (_) {
                      await _offlineSyncService.enqueueOperation(
                        endpoint: '/magasinier/clients',
                        method: 'POST',
                        payload: clientData,
                        description: 'Nouveau client: ${_clientNameController.text.trim()}',
                      );
                      isOfflineQueued = true;
                    } finally {
                      if (mounted) {
                        Navigator.of(context, rootNavigator: true).pop(); // dismiss loading dialog
                      }
                    }

                    setState(() {
                      _clientsList.insert(0, {
                        'id': 'c-${DateTime.now().millisecondsSinceEpoch}',
                        'name': _clientNameController.text.trim(),
                        'type': clientTypeLabel,
                        'tag': _clientTypeSelection,
                        'phone': _clientPhoneController.text.trim(),
                        'address': _clientAddressController.text.trim(),
                        'due': 0,
                        'status': 'à jour',
                      });
                      _isAddingClient = false;
                    });

                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          backgroundColor: isOfflineQueued ? Colors.orange : AppColors.syncGreen,
                          content: Text(
                            isOfflineQueued
                                ? 'Client enregistré hors-ligne (en attente de synchro) !'
                                : 'Client enregistré avec succès !',
                          ),
                        ),
                      );
                      _loadClients();
                    }
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
