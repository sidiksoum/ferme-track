import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:provider/provider.dart';

import '../../../../config/theme/app_theme.dart';
import '../../../../data/datasources/remote/api_client.dart';
import '../../../providers/auth_provider.dart';
import '../../../shared/widgets/common_widgets.dart';

class BuildingLotItem {
  final String buildingId;
  final String buildingName;
  final int? capacity;
  final String? description;
  final List<BatchLineItem> lots;

  const BuildingLotItem({
    required this.buildingId,
    required this.buildingName,
    this.capacity,
    this.description,
    this.lots = const [],
  });
}

class BatchLineItem {
  final String id;
  final String name;
  final String species;
  final int currentCount;
  final String status;

  const BatchLineItem({
    required this.id,
    required this.name,
    required this.species,
    required this.currentCount,
    required this.status,
  });
}

class T5GestionView extends StatefulWidget {
  const T5GestionView({super.key});

  @override
  State<T5GestionView> createState() => _T5GestionViewState();
}

class _T5GestionViewState extends State<T5GestionView> {
  final ApiClient _apiClient = GetIt.instance<ApiClient>();

  bool _isLoading = true;
  String? _error;
  List<Map<String, dynamic>> _farms = [];
  List<BuildingLotItem> _buildings = [];
  String? _selectedFarmId;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final currentUser = context.read<AuthNotifier>().currentUser;

      final farmsResponse = await _apiClient.get('/farms');
      final allFarms = (farmsResponse is List ? farmsResponse : []).whereType<Map>().map(
        (f) => Map<String, dynamic>.from(f),
      ).toList();

      final availableFarms = currentUser?.farmId != null
          ? allFarms.where((farm) => farm['id'] == currentUser!.farmId).toList()
          : allFarms;

      if (availableFarms.isEmpty) {
        setState(() {
          _farms = allFarms;
          _selectedFarmId = null;
          _buildings = const [];
          _isLoading = false;
        });
        return;
      }

      final nextFarmId =
          _selectedFarmId ?? availableFarms.first['id'] as String?;
      final fallbackFarmId = nextFarmId ?? availableFarms.first['id'] as String;

      setState(() {
        _farms = availableFarms;
        _selectedFarmId = fallbackFarmId;
      });

      await _loadFarmBuildings(fallbackFarmId);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Impossible de charger les bâtiments et lots.';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadFarmBuildings(String farmId) async {
    try {
      final buildingsResponse = await _apiClient.get(
        '/buildings',
        queryParameters: {'farm_id': farmId},
      );

      final batchesResponse = await _apiClient.get(
        '/batches',
        queryParameters: {'farm_id': farmId},
      );

      final buildingList = (buildingsResponse is List ? buildingsResponse : []).whereType<Map>().map((item) {
        final map = Map<String, dynamic>.from(item);
        return BuildingLotItem(
          buildingId: map['id'].toString(),
          buildingName: map['name']?.toString() ?? 'Bâtiment',
          capacity: map['capacity'] is int ? map['capacity'] as int : null,
          description: map['description']?.toString(),
        );
      }).toList();

      final batchesByBuilding = <String, List<BatchLineItem>>{};
      final batchList = (batchesResponse is List ? batchesResponse : []).whereType<Map>().map((item) {
        final map = Map<String, dynamic>.from(item);
        return BatchLineItem(
          id: map['id'].toString(),
          name: map['name']?.toString() ?? 'Lot',
          species: map['species']?.toString() ?? 'poussins',
          currentCount: map['current_count'] is int
              ? map['current_count'] as int
              : 0,
          status: map['status']?.toString() ?? 'ACTIVE',
        );
      }).toList();

      for (final batch in batchList) {
        final buildingId = _findBuildingIdForBatch(
          batch.id,
          batchesResponse is List ? batchesResponse as List<dynamic> : const [],
        );
        if (buildingId != null) {
          batchesByBuilding
              .putIfAbsent(buildingId, () => <BatchLineItem>[])
              .add(batch);
        }
      }

      final enriched = <BuildingLotItem>[];
      for (final building in buildingList) {
        final lots =
            batchesByBuilding[building.buildingId] ?? const <BatchLineItem>[];
        enriched.add(
          BuildingLotItem(
            buildingId: building.buildingId,
            buildingName: building.buildingName,
            capacity: building.capacity,
            description: building.description,
            lots: lots,
          ),
        );
      }

      if (!mounted) return;
      setState(() {
        _buildings = enriched;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Impossible de charger les bâtiments pour cette ferme.';
        _isLoading = false;
      });
    }
  }

  String? _findBuildingIdForBatch(String batchId, List<dynamic> batches) {
    for (final item in batches) {
      if (item is Map) {
        final map = Map<String, dynamic>.from(item);
        if (map['id']?.toString() == batchId && map['building_id'] != null) {
          return map['building_id'].toString();
        }
      }
    }
    return null;
  }

  Future<void> _handleFarmChanged(String? farmId) async {
    if (farmId == null) {
      setState(() {
        _selectedFarmId = null;
        _buildings = const [];
      });
      return;
    }

    setState(() => _selectedFarmId = farmId);
    await _loadFarmBuildings(farmId);
  }

  Future<void> _showBuildingDialog({BuildingLotItem? building}) async {
    final nameController = TextEditingController(text: building?.buildingName);
    final capacityController = TextEditingController(
      text: building?.capacity?.toString() ?? '',
    );
    final descriptionController = TextEditingController(
      text: building?.description ?? '',
    );

    final currentFarmId =
        _selectedFarmId ?? context.read<AuthNotifier>().currentUser?.farmId;
    if (currentFarmId == null) {
      _showMessage('Aucune ferme disponible pour ce technicien.');
      return;
    }

    final pageContext = context;
    final didSave = await showDialog<bool>(
      context: pageContext,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(
                building == null
                    ? 'Ajouter un bâtiment'
                    : 'Modifier le bâtiment',
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Ferme',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: currentFarmId,
                      items: _farms.map((farm) {
                        final id = farm['id'].toString();
                        return DropdownMenuItem<String>(
                          value: id,
                          child: Text(farm['name']?.toString() ?? 'Ferme'),
                        );
                      }).toList(),
                      onChanged: null,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Nom du bâtiment',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: capacityController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Capacité (optionnel)',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: descriptionController,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, false),
                  child: const Text('Annuler'),
                ),
                FilledButton(
                  onPressed: () async {
                    final name = nameController.text.trim();
                    if (name.isEmpty) {
                      _showMessage('Le nom du bâtiment est obligatoire.');
                      return;
                    }

                    final capacityText = capacityController.text.trim();
                    int? capacity;
                    if (capacityText.isNotEmpty) {
                      capacity = int.tryParse(capacityText);
                    }

                    try {
                      if (building == null) {
                        showActionLoadingDialog(
                          context,
                          message: 'Ajout du bâtiment en cours...',
                        );
                        final createdBuilding = await _apiClient.post(
                          '/buildings',
                          data: {
                            'farm_id': currentFarmId,
                            'name': name,
                            'capacity': capacity,
                            'description':
                                descriptionController.text.trim().isEmpty
                                ? null
                                : descriptionController.text.trim(),
                          },
                        );
                      } else {
                        showActionLoadingDialog(
                          context,
                          message: 'Mise à jour du bâtiment...',
                        );
                        await _apiClient.put(
                          '/buildings/${building.buildingId}',
                          data: {
                            'name': name,
                            'capacity': capacity,
                            'description':
                                descriptionController.text.trim().isEmpty
                                ? null
                                : descriptionController.text.trim(),
                          },
                        );
                      }

                      if (mounted) {
                        Navigator.of(context, rootNavigator: true).pop();
                        Navigator.pop(dialogContext, true);
                      }
                    } catch (e) {
                      if (mounted) {
                        Navigator.of(context, rootNavigator: true).pop();
                        _showMessage('Échec de l\'enregistrement du bâtiment.');
                      }
                    }
                  },
                  child: const Text('Enregistrer'),
                ),
              ],
            );
          },
        );
      },
    );

    if (didSave == true && mounted) {
      await _loadFarmBuildings(currentFarmId);
    }
  }

  Future<void> _deleteBuilding(BuildingLotItem building) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Supprimer le bâtiment ?'),
          content: Text(
            'Voulez-vous vraiment supprimer ${building.buildingName} ?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Annuler'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text(
                'Supprimer',
                style: TextStyle(color: AppColors.danger),
              ),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    try {
      showActionLoadingDialog(context, message: 'Suppression du bâtiment...');
      await _apiClient.delete('/buildings/${building.buildingId}');
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
        _showMessage('Bâtiment supprimé.');
        if (_selectedFarmId != null) {
          await _loadFarmBuildings(_selectedFarmId!);
        }
      }
    } catch (_) {
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
        _showMessage('Impossible de supprimer ce bâtiment.');
      }
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 48,
                color: AppColors.danger,
              ),
              const SizedBox(height: 12),
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadData,
                child: const Text('Réessayer'),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedFarmId,
                    decoration: const InputDecoration(
                      labelText: 'Ferme',
                      border: OutlineInputBorder(),
                    ),
                    items: _farms.map((farm) {
                      final id = farm['id'].toString();
                      return DropdownMenuItem<String>(
                        value: id,
                        child: Text(farm['name']?.toString() ?? 'Ferme'),
                      );
                    }).toList(),
                    onChanged: _handleFarmChanged,
                  ),
                ),
                const SizedBox(width: 12),
                FilledButton.icon(
                  onPressed: () => _showBuildingDialog(),
                  icon: const Icon(Icons.add_business_rounded),
                  label: const Text('Ajouter'),
                ),
              ],
            ),
            const SizedBox(height: 18),
            const Text('BÂTIMENTS ET LOTS', style: AppTypography.labelSmall),
            const SizedBox(height: 10),
            if (_buildings.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppColors.paper,
                  border: Border.all(color: AppColors.line),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Text(
                  'Aucun bâtiment pour cette ferme.',
                  style: TextStyle(color: AppColors.inkSoft),
                ),
              )
            else
              ..._buildings.map((building) => _buildBuildingCard(building)),
          ],
        ),
      ),
    );
  }

  Widget _buildBuildingCard(BuildingLotItem building) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.paper,
        border: Border.all(color: AppColors.line),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      building.buildingName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (building.description != null &&
                        building.description!.isNotEmpty)
                      Text(
                        building.description!,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.inkSoft,
                        ),
                      ),
                  ],
                ),
              ),
              Row(
                children: [
                  IconButton(
                    onPressed: () => _showBuildingDialog(building: building),
                    icon: const Icon(
                      Icons.edit_outlined,
                      color: AppColors.primaryDark,
                    ),
                    tooltip: 'Modifier',
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (building.capacity != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(100),
              ),
              child: Text(
                'Capacité: ${building.capacity} poussins',
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.primaryDark,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          const SizedBox(height: 12),
          const Text(
            'Lots associés',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
          ),
          const SizedBox(height: 6),
          if (building.lots.isEmpty)
            const Text(
              'Aucun lot associé à ce bâtiment.',
              style: TextStyle(color: AppColors.inkSoft, fontSize: 12),
            )
          else
            ...building.lots.map(
              (lot) => Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.line),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            lot.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '${lot.currentCount} volailles · ${lot.status}',
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.inkSoft,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.pets, size: 18, color: AppColors.primary),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
