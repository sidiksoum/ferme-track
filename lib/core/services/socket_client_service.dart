import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

import '../../config/constants/app_constants.dart';
import '../../core/interfaces/network_checker.dart';
import '../../core/utils/app_logger.dart';
import '../../data/datasources/local/cache_manager.dart';

/// Service client Socket.IO pour la communication et les notifications en temps réel
class SocketClientService extends ChangeNotifier {
  final CacheManager _cacheManager;
  final NetworkChecker? _networkChecker;
  io.Socket? _socket;

  bool _isConnected = false;
  String? _currentToken;
  String? _currentFarmId;
  StreamSubscription<bool>? _networkSubscription;

  final StreamController<Map<String, dynamic>> _taskEventController =
      StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<Map<String, dynamic>> _activityEventController =
      StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<Map<String, dynamic>> _stockEventController =
      StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<Map<String, dynamic>> _alertEventController =
      StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<Map<String, dynamic>> _saleEventController =
      StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<Map<String, dynamic>> _orderEventController =
      StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<Map<String, dynamic>> _anomalyEventController =
      StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<Map<String, dynamic>> _allEventsController =
      StreamController<Map<String, dynamic>>.broadcast();

  SocketClientService({
    required CacheManager cacheManager,
    NetworkChecker? networkChecker,
  })  : _cacheManager = cacheManager,
        _networkChecker = networkChecker {
    // Écoute de la connectivité réseau pour auto-reconnecter sans spammer quand hors-ligne
    _networkSubscription = _networkChecker?.connectivityStream.listen((isOnline) {
      if (isOnline && !_isConnected && _currentToken != null) {
        AppLogger.info('🌐 Réseau rétabli. Reconnexion Socket.IO...');
        _connectInternal();
      } else if (!isOnline && _socket != null) {
        _isConnected = false;
        notifyListeners();
      }
    });
  }

  bool get isConnected => _isConnected;
  Stream<Map<String, dynamic>> get taskEvents => _taskEventController.stream;
  Stream<Map<String, dynamic>> get activityEvents => _activityEventController.stream;
  Stream<Map<String, dynamic>> get stockEvents => _stockEventController.stream;
  Stream<Map<String, dynamic>> get alertEvents => _alertEventController.stream;
  Stream<Map<String, dynamic>> get saleEvents => _saleEventController.stream;
  Stream<Map<String, dynamic>> get orderEvents => _orderEventController.stream;
  Stream<Map<String, dynamic>> get anomalyEvents => _anomalyEventController.stream;
  Stream<Map<String, dynamic>> get allEvents => _allEventsController.stream;

  /// Établit la connexion Socket.IO avec le serveur
  void connect({required String token, String? farmId}) {
    _currentToken = token;
    _currentFarmId = farmId;

    if (_socket != null && _socket!.connected) {
      if (farmId != null && farmId != _currentFarmId) {
        _socket!.emit('join_farm', {'farmId': farmId});
      }
      return;
    }

    _connectInternal();
  }

  void _connectInternal() {
    if (_currentToken == null) return;

    final rootUrl = AppConstants.baseUrl.replaceAll('/api/v1', '');

    try {
      if (_socket != null) {
        _socket!.dispose();
      }

      _socket = io.io(
        rootUrl,
        io.OptionBuilder()
            .setTransports(['websocket', 'polling'])
            .setPath('/socket.io')
            .enableAutoConnect()
            .enableReconnection()
            .setReconnectionDelay(3000)
            .setReconnectionAttempts(5)
            .setAuth({
              'token': _currentToken,
              'farmId': _currentFarmId,
            })
            .build(),
      );

      _setupListeners();
      _socket!.connect();
    } catch (e, stackTrace) {
      AppLogger.error('Erreur initialisation Socket.IO: $e', e, stackTrace);
    }
  }

  void _setupListeners() {
    if (_socket == null) return;

    _socket!.onConnect((_) {
      _isConnected = true;
      AppLogger.info('🟢 Socket.IO connecté avec succès !');
      if (_currentFarmId != null) {
        _socket!.emit('join_farm', {'farmId': _currentFarmId});
      }
      notifyListeners();
    });

    _socket!.onDisconnect((_) {
      _isConnected = false;
      AppLogger.debug('Socket.IO déconnecté.');
      notifyListeners();
    });

    _socket!.onConnectError((err) {
      _isConnected = false;
      final msg = err.toString().toLowerCase();
      if (msg.contains('socketexception') || msg.contains('failed host lookup') || msg.contains('errno = 7')) {
        // En mode hors-ligne, journalisation discrète
        AppLogger.debug('Socket.IO en attente de connexion réseau.');
      } else {
        AppLogger.warning('⚠️ Statut Socket.IO: $err');
      }
      notifyListeners();
    });

    _socket!.onError((err) {
      _isConnected = false;
      final msg = err.toString().toLowerCase();
      if (!msg.contains('socketexception') && !msg.contains('failed host lookup')) {
        AppLogger.warning('⚠️ Erreur Socket.IO: $err');
      }
    });

    // Événement : Nouvelle tâche créée par le technicien
    _socket!.on('notification:new', (data) {
      AppLogger.info('⚡ Événement reçu [notification:new]: $data');
      if (data is Map) {
        final map = Map<String, dynamic>.from(data);
        _allEventsController.add({'event': 'notification:new', 'data': map});
        notifyListeners();
      }
    });

    _socket!.on('task:created', (data) {
      AppLogger.info('⚡ Événement reçu [task:created]: $data');
      _cacheManager.invalidatePrefix('/volailler/tasks');
      _cacheManager.invalidatePrefix('/activities');
      _cacheManager.invalidatePrefix('/buildings');
      _cacheManager.invalidatePrefix('/batches');
      if (data is Map) {
        final map = Map<String, dynamic>.from(data);
        _taskEventController.add(map);
        _allEventsController.add({'event': 'task:created', 'data': map});
        notifyListeners();
      }
    });

    // Événement : Tâche clôturée par un volailler
    _socket!.on('task:closed', (data) {
      AppLogger.info('⚡ Événement reçu [task:closed]: $data');
      _cacheManager.invalidatePrefix('/volailler/tasks');
      _cacheManager.invalidatePrefix('/activities');
      _cacheManager.invalidatePrefix('/stocks');
      if (data is Map) {
        final map = Map<String, dynamic>.from(data);
        _taskEventController.add(map);
        _allEventsController.add({'event': 'task:closed', 'data': map});
        notifyListeners();
      }
    });

    // Événement : Activité mise à jour ou confirmée
    _socket!.on('activity:updated', (data) {
      AppLogger.info('⚡ Événement reçu [activity:updated]: $data');
      _cacheManager.invalidatePrefix('/activities');
      _cacheManager.invalidatePrefix('/volailler/tasks');
      _cacheManager.invalidatePrefix('/stocks');
      if (data is Map) {
        final map = Map<String, dynamic>.from(data);
        _activityEventController.add(map);
        _allEventsController.add({'event': 'activity:updated', 'data': map});
        notifyListeners();
      }
    });

    // Événement : Mise à jour de stock
    _socket!.on('stock:updated', (data) {
      AppLogger.info('⚡ Événement reçu [stock:updated]: $data');
      _cacheManager.invalidatePrefix('/stocks');
      _cacheManager.invalidatePrefix('/magasinier/egg-stocks');
      _cacheManager.invalidatePrefix('/magasinier/caisse');
      _cacheManager.invalidatePrefix('/magasinier/egg-exits');
      if (data is Map) {
        final map = Map<String, dynamic>.from(data);
        _stockEventController.add(map);
        _allEventsController.add({'event': 'stock:updated', 'data': map});
        notifyListeners();
      }
    });

    // Événement : Nouvelle vente enregistrée
    _socket!.on('sale:created', (data) {
      AppLogger.info('⚡ Événement reçu [sale:created]: $data');
      _cacheManager.invalidatePrefix('/magasinier/sales');
      _cacheManager.invalidatePrefix('/magasinier/caisse');
      _cacheManager.invalidatePrefix('/magasinier/egg-stocks');
      _cacheManager.invalidatePrefix('/magasinier/clients');
      _cacheManager.invalidatePrefix('/stocks');
      if (data is Map) {
        final map = Map<String, dynamic>.from(data);
        _saleEventController.add(map);
        _allEventsController.add({'event': 'sale:created', 'data': map});
        notifyListeners();
      }
    });

    // Événement : Nouvelle commande fournisseur
    _socket!.on('order:created', (data) {
      AppLogger.info('⚡ Événement reçu [order:created]: $data');
      _cacheManager.invalidatePrefix('/orders');
      _cacheManager.invalidatePrefix('/activities');
      _cacheManager.invalidatePrefix('/stocks');
      if (data is Map) {
        final map = Map<String, dynamic>.from(data);
        _orderEventController.add(map);
        _allEventsController.add({'event': 'order:created', 'data': map});
        notifyListeners();
      }
    });

    // Événement : Anomalie signalée
    _socket!.on('anomaly:reported', (data) {
      AppLogger.info('⚡ Événement reçu [anomaly:reported]: $data');
      _cacheManager.invalidatePrefix('/anomalies');
      _cacheManager.invalidatePrefix('/activities');
      if (data is Map) {
        final map = Map<String, dynamic>.from(data);
        _anomalyEventController.add(map);
        _alertEventController.add(map);
        _allEventsController.add({'event': 'anomaly:reported', 'data': map});
        notifyListeners();
      }
    });

    // Événement : Nouvelle alerte critique
    _socket!.on('alert:new', (data) {
      AppLogger.info('⚡ Événement reçu [alert:new]: $data');
      if (data is Map) {
        final map = Map<String, dynamic>.from(data);
        _alertEventController.add(map);
        _allEventsController.add({'event': 'alert:new', 'data': map});
        notifyListeners();
      }
    });
  }

  /// Émet un événement local pour notifier immédiatement tous les écrans lors d'une mutation (POST/PUT/PATCH/DELETE)
  void emitLocalEvent(String event, [Map<String, dynamic>? data]) {
    final payload = {'event': event, ...(data ?? {})};
    _allEventsController.add(payload);
    final lower = event.toLowerCase();
    if (lower.contains('stock') || lower.contains('egg') || lower.contains('reception')) {
      _stockEventController.add(payload);
    }
    if (lower.contains('sale') || lower.contains('client') || lower.contains('caisse') || lower.contains('refund')) {
      _saleEventController.add(payload);
    }
    if (lower.contains('task') || lower.contains('activit')) {
      _taskEventController.add(payload);
      _activityEventController.add(payload);
    }
    if (lower.contains('anomal') || lower.contains('mortalit')) {
      _anomalyEventController.add(payload);
    }
    notifyListeners();
  }

  /// Déconnexion et nettoyage
  void disconnect() {
    try {
      _currentToken = null;
      _socket?.disconnect();
      _socket?.dispose();
      _socket = null;
      _isConnected = false;
      notifyListeners();
      AppLogger.info('Socket.IO fermé.');
    } catch (e) {
      AppLogger.error('Erreur lors de la fermeture Socket.IO: $e');
    }
  }

  @override
  void dispose() {
    _networkSubscription?.cancel();
    disconnect();
    _taskEventController.close();
    _activityEventController.close();
    _stockEventController.close();
    _alertEventController.close();
    _saleEventController.close();
    _orderEventController.close();
    _anomalyEventController.close();
    _allEventsController.close();
    super.dispose();
  }
}
