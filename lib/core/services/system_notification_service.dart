import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../../config/constants/app_constants.dart';
import '../../core/di/service_locator.dart';
import '../../core/utils/app_logger.dart';
import '../../data/datasources/remote/api_client.dart';
import 'socket_client_service.dart';

/// Modèle local pour une notification ou alerte
class FarmAppNotification {
  final String id;
  final String title;
  final String message;
  final String type; // 'stock_alert', 'task', 'reception', 'sale', 'anomaly', 'credit'
  final DateTime timestamp;
  final String? targetRole;
  final List<String>? targetRoles;
  final bool isRead;
  final Map<String, dynamic>? data;

  FarmAppNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.timestamp,
    this.targetRole,
    this.targetRoles,
    this.isRead = false,
    this.data,
  });

  FarmAppNotification copyWith({bool? isRead}) {
    return FarmAppNotification(
      id: id,
      title: title,
      message: message,
      type: type,
      timestamp: timestamp,
      targetRole: targetRole,
      targetRoles: targetRoles,
      isRead: isRead ?? this.isRead,
      data: data,
    );
  }
}

/// Service de gestion des notifications système push locales et alertes temps réel
class SystemNotificationService extends ChangeNotifier {
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  final SocketClientService _socketService;
  final ApiClient? _apiClientOverride;

  bool _isInitialized = false;
  String? _currentUserRole;
  StreamSubscription? _taskSubscription;
  StreamSubscription? _activitySubscription;
  StreamSubscription? _stockSubscription;
  StreamSubscription? _alertSubscription;
  StreamSubscription? _socketEventSubscription;

  final List<FarmAppNotification> _notifications = [];

  ApiClient? get _apiClient => _apiClientOverride ??
      (getIt.isRegistered<ApiClient>() ? getIt<ApiClient>() : null);

  SystemNotificationService({
    required SocketClientService socketService,
    ApiClient? apiClient,
  })  : _socketService = socketService,
        _apiClientOverride = apiClient {
    _initListeners();
  }

  List<FarmAppNotification> get notifications {
    if (_currentUserRole == null) return List.unmodifiable(_notifications);
    return List.unmodifiable(_notifications.where((n) {
      final roles = <String>[];
      if (n.targetRole != null) roles.add(n.targetRole!);
      if (n.targetRoles != null) roles.addAll(n.targetRoles!);
      if (roles.isEmpty) return true;
      return roles.any(_isRole);
    }));
  }

  int get unreadCount => notifications.where((n) => !n.isRead).length;

  List<FarmAppNotification> get activeAlerts => notifications
      .where((n) =>
          n.type.contains('alert') ||
          n.type == 'anomaly' ||
          n.type == 'late' ||
          n.type == 'credit' ||
          n.type == 'stock_alert')
      .toList();

  /// Initialise le plugin de notification système
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      const androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      const darwinSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: darwinSettings,
        macOS: darwinSettings,
      );

      await _localNotifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: (response) {
          AppLogger.info('Notification cliquée: ${response.payload}');
        },
      );

      // Création du canal haute importance pour Android
      final androidImplementation = _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      if (androidImplementation != null) {
        await androidImplementation.createNotificationChannel(
          const AndroidNotificationChannel(
            'ferme_track_alerts',
            'Alertes Ferme-Track',
            description: 'Alertes critiques, activités et mouvements de stock de la ferme',
            importance: Importance.max,
            enableVibration: true,
            playSound: true,
          ),
        );
      }

      _isInitialized = true;
      AppLogger.info('SystemNotificationService initialisé.');
    } catch (e, stackTrace) {
      AppLogger.error('Erreur initialisation SystemNotificationService: $e', e, stackTrace);
    }
  }

  /// Demande les permissions à l'utilisateur
  Future<bool> requestPermissions() async {
    try {
      final androidImplementation = _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      if (androidImplementation != null) {
        final granted =
            await androidImplementation.requestNotificationsPermission();
        return granted ?? true;
      }

      final iosImplementation = _localNotifications
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>();

      if (iosImplementation != null) {
        final granted = await iosImplementation.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
        return granted ?? true;
      }
    } catch (e) {
      AppLogger.warning('Erreur demande permissions notifications: $e');
    }
    return true;
  }

  Future<void> fetchNotifications({bool forceRefresh = false}) async {
    final apiClient = _apiClient;
    if (apiClient == null) {
      AppLogger.warning('SystemNotificationService: ApiClient non disponible, fetchNotifications ignoré.');
      return;
    }

    try {
      final response = await apiClient.get(
        '/notifications',
        queryParameters: {'unread_only': false},
        useCache: false,
        forceRefresh: forceRefresh,
      );
      if (response is! List) return;
      final incoming = <FarmAppNotification>[];
      for (final item in response) {
        if (item is! Map) continue;
        final map = Map<String, dynamic>.from(item);
        final notificationId = map['id']?.toString() ??
            map['notification_id']?.toString() ??
            DateTime.now().microsecondsSinceEpoch.toString();
        final title = map['title']?.toString() ?? 'Notification';
        final message = map['message']?.toString() ?? 'Nouvelle alerte';
        final type = map['notification_type']?.toString() ??
            map['type']?.toString() ??
            'system';
        final targetRole = map['target_role']?.toString() ??
            map['targetRole']?.toString();
        final timestamp = map['created_at'] != null
            ? DateTime.tryParse(map['created_at'].toString()) ?? DateTime.now()
            : DateTime.now();
        incoming.add(
          FarmAppNotification(
            id: notificationId,
            title: title,
            message: message,
            type: type.toLowerCase(),
            timestamp: timestamp,
            targetRole: targetRole,
            isRead: map['is_read'] == true,
            data: map,
          ),
        );
      }

      final merged = <FarmAppNotification>[];
      for (final notification in incoming) {
        final existingIndex = _notifications.indexWhere((n) => n.id == notification.id);
        if (existingIndex >= 0) {
          _notifications[existingIndex] = notification;
        } else {
          _notifications.insert(0, notification);
        }
        merged.add(notification);
      }
      if (merged.isNotEmpty) notifyListeners();
    } catch (e) {
      AppLogger.warning('Erreur récupération notifications backend: $e');
    }
  }

  /// Met à jour le rôle de l'utilisateur connecté pour filtrer les notifications
  void setUserRole(String? role) {
    final cleanRole = role?.toLowerCase();
    if (_currentUserRole == cleanRole) return;
    _currentUserRole = cleanRole;
    fetchNotifications(forceRefresh: true);
    notifyListeners();
  }

  /// Affiche une notification push système locale
  Future<void> showPushNotification({
    required String title,
    required String body,
    String? payload,
    int id = 0,
  }) async {
    if (!_isInitialized) await initialize();

    if (Platform.isAndroid) {
      final granted = await requestPermissions();
      if (!granted) {
        AppLogger.warning('Notification système ignorée : autorisation Android non accordée.');
        return;
      }
    }

    try {
      const androidDetails = AndroidNotificationDetails(
        'ferme_track_alerts',
        'Alertes Ferme-Track',
        channelDescription: 'Alertes critiques et mouvements de stock',
        importance: Importance.max,
        priority: Priority.high,
        showWhen: true,
        icon: '@mipmap/ic_launcher',
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _localNotifications.show(
        id == 0 ? DateTime.now().millisecondsSinceEpoch % 100000 : id,
        title,
        body,
        details,
        payload: payload,
      );
    } catch (e) {
      AppLogger.warning('Erreur affichage notification locale: $e');
    }
  }

  /// Ajoute une notification dans l'historique de l'application et déclenche le push
  void addNotification({
    required String title,
    required String message,
    required String type,
    String? targetRole,
    List<String>? targetRoles,
    Map<String, dynamic>? data,
  }) {
    final finalTargetRoles = targetRoles ??
        (targetRole == null ? null : <String>[targetRole]);
    final detailMessage = _buildNotificationMessage(
      type: type,
      message: message,
      data: data,
    );
    final notif = FarmAppNotification(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      title: title,
      message: detailMessage,
      type: type,
      timestamp: DateTime.now(),
      targetRole: finalTargetRoles == null || finalTargetRoles.isEmpty
          ? targetRole
          : finalTargetRoles.first,
      targetRoles: finalTargetRoles,
      data: data,
    );

    _notifications.insert(0, notif);
    if (_notifications.length > 50) {
      _notifications.removeLast();
    }
    notifyListeners();

    showPushNotification(title: title, body: detailMessage);
  }

  String _buildNotificationMessage({
    required String type,
    required String message,
    Map<String, dynamic>? data,
  }) {
    if (data == null || data.isEmpty) return message;

    final buildingName = data['buildingName'] ?? data['building'] ?? data['building_name'];
    final taskTitle = data['taskTitle'] ?? data['title'] ?? data['activityTitle'];
    final worker = data['workerName'] ?? data['responsibleName'] ?? data['userName'];
    final quantity = data['qty'] ?? data['quantity'] ?? data['verifiedCount'] ?? data['amount'];
    final customer = data['customer_name'] ?? data['client'] ?? data['supplier_name'];

    if (type == 'anomaly' && buildingName != null) {
      return '$message — ${buildingName.toString()}';
    }
    if (type == 'task' && taskTitle != null) {
      final suffix = worker != null ? ' • $worker' : '';
      return '$message — $taskTitle$suffix';
    }
    if (type == 'reception' && quantity != null) {
      final suffix = buildingName != null ? ' • $buildingName' : '';
      return '$message — $quantity$suffix';
    }
    if (type == 'stock_alert' && buildingName != null) {
      return '$message — $buildingName';
    }
    if (type == 'credit' && customer != null) {
      return '$message — $customer';
    }
    return message;
  }

  /// Marquer une notification comme lue
  void markAsRead(String id) {
    final index = _notifications.indexWhere((n) => n.id == id);
    if (index != -1) {
      _notifications[index] = _notifications[index].copyWith(isRead: true);
      notifyListeners();
    }
  }

  /// Tout marquer comme lu
  void markAllAsRead() {
    for (int i = 0; i < _notifications.length; i++) {
      _notifications[i] = _notifications[i].copyWith(isRead: true);
    }
    notifyListeners();
  }

  StreamSubscription? _saleSubscription;
  StreamSubscription? _orderSubscription;
  StreamSubscription? _anomalySubscription;

  void _initListeners() {
    _socketEventSubscription = _socketService.allEvents.listen((event) {
      final eventName = event['event']?.toString();
      if (eventName == 'notification:new') {
        final data = Map<String, dynamic>.from(event['data'] ?? event);
        final title = data['title']?.toString() ?? 'Notification';
        final message = data['message']?.toString() ?? 'Nouvelle notification';
        final type = (data['type'] ?? data['notification_type'] ?? 'system').toString();
        final targetRole = data['targetRole']?.toString() ?? data['target_role']?.toString();
        final existing = _notifications.any((n) => n.id == data['id']?.toString());
        if (!existing) {
          addNotification(
            title: title,
            message: message,
            type: type.toLowerCase(),
            targetRole: targetRole,
            data: data,
          );
        }
      }
    });

    // 1. Événements de tâches (Nouvelle tâche / Tâche clôturée)
    _taskSubscription = _socketService.taskEvents.listen((event) {
      final title = event['taskTitle']?.toString() ?? event['title']?.toString() ?? 'Tâche';
      final status = event['status']?.toString();
      final worker = event['workerName']?.toString() ?? event['assignedTo']?.toString() ?? 'Personnel';

      if (status == 'pending_validation' || status == 'submitted') {
        if (_isRole(AppConstants.roleTechnician) || _isRole(AppConstants.roleDirector)) {
          addNotification(
            title: 'Tâche à valider',
            message: '$worker a terminé la tâche "$title". En attente de validation.',
            type: 'task',
            targetRoles: [AppConstants.roleTechnician, AppConstants.roleDirector],
            data: event,
          );
        }
      } else {
        if (_isRole(AppConstants.rolePoultryKeeper) ||
            _isRole(AppConstants.roleDirector) ||
            _isRole(AppConstants.roleTechnician)) {
          addNotification(
            title: 'Nouvelle tâche assignée',
            message: 'Tâche : "$title" programmée dans votre planning.',
            type: 'task',
            targetRoles: [
              AppConstants.rolePoultryKeeper,
              AppConstants.roleTechnician,
              AppConstants.roleDirector,
            ],
            data: event,
          );
        }
      }
    });

    // 2. Événements de stock (Sortie d'œufs, Réception validée, Rupture)
    _stockSubscription = _socketService.stockEvents.listen((event) {
      final type = event['type']?.toString();
      final qty = event['qty'] ?? event['verifiedCount'] ?? event['quantity'] ?? '';
      final buildingName = event['buildingName'] ?? event['building'] ?? event['building_name'];

      if (type == 'egg_exit') {
        if (_isRole(AppConstants.roleWarehouseManager) || _isRole(AppConstants.roleDirector)) {
          addNotification(
            title: 'Nouvelle sortie d\'œufs déclarée',
            message: '$qty œufs en provenance du poulailler en attente de vérification au magasin${buildingName != null ? ' — ${buildingName.toString()}' : ''}.',
            type: 'reception',
            targetRoles: [AppConstants.roleWarehouseManager, AppConstants.roleDirector],
            data: event,
          );
        }
      } else if (type == 'egg_reception_validated') {
        if (_isRole(AppConstants.roleTechnician) ||
            _isRole(AppConstants.roleDirector) ||
            _isRole(AppConstants.roleWarehouseManager)) {
          addNotification(
            title: 'Réception d\'œufs validée',
            message: 'Le magasinier a validé la réception de $qty œufs${buildingName != null ? ' pour ${buildingName.toString()}' : ''}.',
            type: 'reception',
            targetRoles: [
              AppConstants.roleWarehouseManager,
              AppConstants.roleTechnician,
              AppConstants.roleDirector,
            ],
            data: event,
          );
        }
      } else if (type == 'critical_stock') {
        if (_isRole(AppConstants.roleTechnician) ||
            _isRole(AppConstants.roleDirector) ||
            _isRole(AppConstants.roleWarehouseManager)) {
          addNotification(
            title: 'Alerte : Seuil de stock critique !',
            message: 'Le stock de ${event['itemName'] ?? 'produit'} est inférieur au seuil d\'alerte${buildingName != null ? ' • ${buildingName.toString()}' : ''}.',
            type: 'stock_alert',
            targetRoles: [
              AppConstants.roleTechnician,
              AppConstants.roleWarehouseManager,
              AppConstants.roleDirector,
            ],
            data: event,
          );
        }
      }
    });

    // 3. Événements de ventes
    _saleSubscription = _socketService.saleEvents.listen((event) {
      final client = event['customer_name']?.toString() ?? event['client']?.toString() ?? 'Client';
      final total = event['total_amount'] ?? event['amount'] ?? 0;
      final paymentType = event['payment_type']?.toString() ?? 'comptant';
      if (_isRole(AppConstants.roleDirector) || _isRole(AppConstants.roleWarehouseManager)) {
        addNotification(
          title: 'Nouvelle vente enregistrée',
          message: 'Vente de $total FCFA ($paymentType) effectuée pour $client.',
          type: 'sale',
          data: event,
        );
      }
    });

    // 4. Événements de commandes fournisseurs
    _orderSubscription = _socketService.orderEvents.listen((event) {
      final supplier = event['supplier_name']?.toString() ?? 'Fournisseur';
      final total = event['total_cost'] ?? 0;
      if (_isRole(AppConstants.roleDirector) || _isRole(AppConstants.roleTechnician)) {
        addNotification(
          title: 'Nouvelle commande fournisseur',
          message: 'Commande de $total FCFA passée auprès de $supplier.',
          type: 'stock_alert',
          data: event,
        );
      }
    });

    // 5. Événements d'anomalies signalées
    _anomalySubscription = _socketService.anomalyEvents.listen((event) {
      final building = event['building_name']?.toString() ??
          event['building']?.toString() ??
          event['buildingName']?.toString() ??
          'Bâtiment';
      final desc = event['description']?.toString() ??
          event['message']?.toString() ??
          'Anomalie signalée';
      final severity = event['severity']?.toString() ??
          event['level']?.toString() ??
          'moyenne';
      if (_isRole(AppConstants.roleDirector) || _isRole(AppConstants.roleTechnician)) {
        addNotification(
          title: 'Anomalie signalée — $building',
          message: '$desc • Niveau $severity',
          type: 'anomaly',
          targetRoles: [AppConstants.roleDirector, AppConstants.roleTechnician],
          data: event,
        );
      }
    });

    // 6. Événements d'alertes génériques
    _alertSubscription = _socketService.alertEvents.listen((event) {
      final title = event['title']?.toString() ?? 'Alerte Ferme';
      final message = event['message']?.toString() ?? 'Une alerte a été signalée.';
      final type = event['type']?.toString() ?? 'anomaly';
      final targetRole = event['targetRole']?.toString();
      final eventData = Map<String, dynamic>.from(event);

      if (type == 'payment_due' ||
          event['credit'] == true ||
          title.toLowerCase().contains('créance') ||
          title.toLowerCase().contains('echeance')) {
        if (_isRole(AppConstants.roleWarehouseManager) || _isRole(AppConstants.roleDirector)) {
          addNotification(
            title: title,
            message: message,
            type: 'credit',
            targetRoles: [AppConstants.roleWarehouseManager, AppConstants.roleDirector],
            data: eventData,
          );
        }
        return;
      }

      addNotification(
        title: title,
        message: message,
        type: type,
        targetRole: targetRole,
        data: eventData,
      );
    });
  }

  bool _isRole(String role) {
    if (_currentUserRole == null) return true;
    final r = _currentUserRole!.toLowerCase();
    final target = role.toLowerCase();
    return r == target ||
        (target == 'technicien' && (r == 'technician' || r == 'technicien')) ||
        (target == 'directeur' && (r == 'director' || r == 'directeur')) ||
        (target == 'magasinier' && (r == 'warehouse' || r == 'magasinier')) ||
        (target == 'volailler' && (r == 'poultrykeeper' || r == 'volailler'));
  }

  @override
  void dispose() {
    _socketEventSubscription?.cancel();
    _taskSubscription?.cancel();
    _activitySubscription?.cancel();
    _stockSubscription?.cancel();
    _saleSubscription?.cancel();
    _orderSubscription?.cancel();
    _anomalySubscription?.cancel();
    _alertSubscription?.cancel();
    super.dispose();
  }
}
