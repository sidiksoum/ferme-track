import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../config/constants/app_constants.dart';
import '../../core/interfaces/network_checker.dart';
import '../../core/utils/app_logger.dart';
import '../../data/datasources/local/cache_manager.dart';
import '../../data/datasources/remote/api_client.dart';
import '../../data/models/sync_operation.dart';

enum SyncEngineState {
  idle,
  syncing,
  success,
  error,
}

/// Service de gestion de la file d'attente hors-ligne et synchronisation d'arrière-plan
class OfflineSyncService extends ChangeNotifier {
  final ApiClient _apiClient;
  final NetworkChecker _networkChecker;
  final CacheManager _cacheManager;

  static const String queueBoxName = AppConstants.boxSync;
  Box? _queueBox;

  bool _isSyncing = false;
  DateTime? _lastSyncTime;
  String? _lastError;
  StreamSubscription<bool>? _networkSubscription;
  Timer? _periodicSyncTimer;

  final StreamController<SyncEngineState> _stateController =
      StreamController<SyncEngineState>.broadcast();

  OfflineSyncService({
    required ApiClient apiClient,
    required NetworkChecker networkChecker,
    required CacheManager cacheManager,
  })  : _apiClient = apiClient,
        _networkChecker = networkChecker,
        _cacheManager = cacheManager;

  bool get isSyncing => _isSyncing;
  DateTime? get lastSyncTime => _lastSyncTime;
  String? get lastError => _lastError;
  Stream<SyncEngineState> get syncStateStream => _stateController.stream;

  Box get queueBox {
    if (_queueBox == null || !_queueBox!.isOpen) {
      _queueBox = Hive.box(queueBoxName);
    }
    return _queueBox!;
  }

  int get pendingOperationsCount {
    try {
      final keys = queueBox.keys;
      int count = 0;
      for (final key in keys) {
        final raw = queueBox.get(key);
        if (raw != null) {
          final op = SyncOperation.fromMap(Map<String, dynamic>.from(raw as Map));
          if (op.status == SyncStatus.pending || op.status == SyncStatus.failed) {
            count++;
          }
        }
      }
      return count;
    } catch (_) {
      return 0;
    }
  }

  List<SyncOperation> get pendingOperations {
    try {
      final list = <SyncOperation>[];
      for (final key in queueBox.keys) {
        final raw = queueBox.get(key);
        if (raw != null) {
          list.add(SyncOperation.fromMap(Map<String, dynamic>.from(raw as Map)));
        }
      }
      list.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      return list;
    } catch (e) {
      AppLogger.error('Erreur lecture pendingOperations: $e');
      return [];
    }
  }

  Future<void> init() async {
    try {
      if (!Hive.isBoxOpen(queueBoxName)) {
        _queueBox = await Hive.openBox(queueBoxName);
      } else {
        _queueBox = Hive.box(queueBoxName);
      }

      // Écouter les changements de connexion réseau
      _networkSubscription = _networkChecker.connectivityStream.listen((hasInternet) {
        if (hasInternet) {
          AppLogger.info('Connexion Internet rétablie. Démarrage synchronisation de la file...');
          syncPendingOperations();
        }
      });

      // Synchronisation périodique de sécurité (toutes les 3 minutes si des éléments sont en attente)
      _periodicSyncTimer = Timer.periodic(const Duration(minutes: 3), (_) async {
        if (pendingOperationsCount > 0 && await _networkChecker.hasConnection) {
          syncPendingOperations();
        }
      });

      AppLogger.info('OfflineSyncService initialisé (opérations en attente: $pendingOperationsCount)');
    } catch (e, stackTrace) {
      AppLogger.error('Erreur init OfflineSyncService: $e', e, stackTrace);
    }
  }

  /// Enregistre une mutation locale en file d'attente
  Future<SyncOperation> enqueueOperation({
    required String endpoint,
    required String method,
    Map<String, dynamic>? payload,
    Map<String, String>? headers,
    String? description,
  }) async {
    final operation = SyncOperation.create(
      endpoint: endpoint,
      method: method,
      payload: payload,
      headers: headers,
      description: description,
    );

    try {
      await queueBox.put(operation.id, operation.toMap());
      AppLogger.info('Opération hors-ligne mise en file: ${operation.method} ${operation.endpoint} (ID: ${operation.id})');
      notifyListeners();

      // Si le réseau est disponible, tenter la synchro immédiatement
      final isOnline = await _networkChecker.hasConnection;
      if (isOnline) {
        // Exécuter en arrière-plan sans bloquer
        unawaited(syncPendingOperations());
      }
    } catch (e, stackTrace) {
      AppLogger.error('Erreur enqueueOperation: $e', e, stackTrace);
    }

    return operation;
  }

  /// Traite et rejoue séquentiellement toutes les opérations en attente
  Future<bool> syncPendingOperations() async {
    if (_isSyncing) return false;

    final isOnline = await _networkChecker.hasConnection;
    if (!isOnline) {
      AppLogger.debug('Synchronisation ignorée : appareil hors-ligne.');
      return false;
    }

    final operations = pendingOperations.where((op) => op.status != SyncStatus.completed).toList();
    if (operations.isEmpty) {
      return true;
    }

    _isSyncing = true;
    _stateController.add(SyncEngineState.syncing);
    notifyListeners();

    AppLogger.info('Début synchronisation de ${operations.length} opérations...');
    bool allSucceeded = true;

    for (final op in operations) {
      try {
        // Marquer en cours de synchronisation
        final updatingOp = op.copyWith(status: SyncStatus.syncing);
        await queueBox.put(updatingOp.id, updatingOp.toMap());

        // Exécuter l'appel HTTP correspondant
        switch (op.method.toUpperCase()) {
          case 'POST':
            await _apiClient.post(op.endpoint, data: op.payload);
            break;
          case 'PATCH':
            await _apiClient.patch(op.endpoint, data: op.payload);
            break;
          case 'PUT':
            await _apiClient.put(op.endpoint, data: op.payload);
            break;
          case 'DELETE':
            await _apiClient.delete(op.endpoint, data: op.payload);
            break;
          default:
            await _apiClient.post(op.endpoint, data: op.payload);
        }

        // Succès : supprimer de la file d'attente
        await queueBox.delete(op.id);
        AppLogger.info('Synchronisé avec succès: ${op.method} ${op.endpoint}');

        // Invalider le cache pour que les écrans rechargent les données fraîches
        _invalidateCacheForEndpoint(op.endpoint);
      } catch (e) {
        allSucceeded = false;
        _lastError = e.toString();
        AppLogger.error('Échec synchronisation opération (${op.id}): $e');

        final failedOp = op.copyWith(
          status: SyncStatus.failed,
          retryCount: op.retryCount + 1,
          error: e.toString(),
        );
        await queueBox.put(failedOp.id, failedOp.toMap());
      }
    }

    _isSyncing = false;
    _lastSyncTime = DateTime.now();
    _stateController.add(allSucceeded ? SyncEngineState.success : SyncEngineState.error);
    notifyListeners();

    return allSucceeded;
  }

  void _invalidateCacheForEndpoint(String endpoint) {
    if (endpoint.contains('/volailler/tasks')) {
      _cacheManager.invalidatePrefix('/volailler/tasks');
      _cacheManager.invalidatePrefix('/activities');
    } else if (endpoint.contains('/activities')) {
      _cacheManager.invalidatePrefix('/activities');
      _cacheManager.invalidatePrefix('/volailler/tasks');
    } else if (endpoint.contains('/buildings') || endpoint.contains('/batches')) {
      _cacheManager.invalidatePrefix('/buildings');
      _cacheManager.invalidatePrefix('/batches');
      _cacheManager.invalidatePrefix('/farms');
    } else if (endpoint.contains('/magasinier')) {
      _cacheManager.invalidatePrefix('/magasinier');
    }
  }

  /// Supprime manuellement une opération de la file
  Future<void> removeOperation(String id) async {
    await queueBox.delete(id);
    notifyListeners();
  }

  /// Vide toutes les opérations en attente
  Future<void> clearQueue() async {
    await queueBox.clear();
    notifyListeners();
  }

  @override
  void dispose() {
    _networkSubscription?.cancel();
    _periodicSyncTimer?.cancel();
    _stateController.close();
    super.dispose();
  }
}
