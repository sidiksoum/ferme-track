import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../../config/constants/app_constants.dart';
import '../../core/utils/app_logger.dart';
import 'socket_client_service.dart';

/// Modèle local pour une notification ou alerte
class FarmAppNotification {
  final String id;
  final String title;
  final String message;
  final String type; // 'stock_alert', 'task', 'reception', 'sale', 'anomaly', 'credit'
  final DateTime timestamp;
  final String? targetRole;
  final bool isRead;
  final Map<String, dynamic>? data;

  FarmAppNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.timestamp,
    this.targetRole,
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

  bool _isInitialized = false;
  String? _currentUserRole;
  StreamSubscription? _taskSubscription;
  StreamSubscription? _activitySubscription;
  StreamSubscription? _stockSubscription;
  StreamSubscription? _alertSubscription;

  final List<FarmAppNotification> _notifications = [
    FarmAppNotification(
      id: 'N-1',
      title: 'Mortalité anormale — Bât. C',
      message: 'Taux de 1.8% sur 24h, seuil dépassé. Veuillez inspecter le lot.',
      type: 'anomaly',
      timestamp: DateTime.now().subtract(const Duration(minutes: 25)),
      targetRole: 'directeur',
      isRead: false,
    ),
    FarmAppNotification(
      id: 'N-2',
      title: 'Alerte : Seuil de stock critique !',
      message: 'Le stock d\'aliment démarrage est descendu sous le seuil critique (3 sacs restants).',
      type: 'stock_alert',
      timestamp: DateTime.now().subtract(const Duration(hours: 1)),
      targetRole: 'technicien',
      isRead: false,
    ),
    FarmAppNotification(
      id: 'N-3',
      title: 'Échéance de paiement dépassée',
      message: 'Le client Seydou Yao présente un retard de paiement de 65 000 FCFA.',
      type: 'credit',
      timestamp: DateTime.now().subtract(const Duration(hours: 3)),
      targetRole: 'magasinier',
      isRead: false,
    ),
    FarmAppNotification(
      id: 'N-4',
      title: 'Nouvelle sortie d\'œufs déclarée',
      message: '1 664 œufs en provenance du Bâtiment A en attente de vérification au magasin.',
      type: 'reception',
      timestamp: DateTime.now().subtract(const Duration(hours: 4)),
      targetRole: 'magasinier',
      isRead: false,
    ),
    FarmAppNotification(
      id: 'N-5',
      title: 'Nouvelle tâche assignée',
      message: 'Tâche : "Pesée hebdomadaire des poules pondeuses" programmée pour aujourd\'hui à 16:00.',
      type: 'task',
      timestamp: DateTime.now().subtract(const Duration(hours: 5)),
      targetRole: 'volailler',
      isRead: true,
    ),
  ];

  SystemNotificationService({
    required SocketClientService socketService,
  }) : _socketService = socketService {
    _initListeners();
  }

  List<FarmAppNotification> get notifications {
    if (_currentUserRole == null) return List.unmodifiable(_notifications);
    return List.unmodifiable(_notifications.where((n) {
      if (n.targetRole == null) return true;
      return _isRole(n.targetRole!);
    }));
  }

  int get unreadCount => notifications.where((n) => !n.isRead).length;

  List<FarmAppNotification> get activeAlerts =>
      notifications.where((n) => n.type.contains('alert') || n.type == 'anomaly' || n.type == 'late' || n.type == 'credit').toList();

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

  /// Met à jour le rôle de l'utilisateur connecté pour filtrer les notifications
  void setUserRole(String? role) {
    final cleanRole = role?.toLowerCase();
    if (_currentUserRole == cleanRole) return;
    _currentUserRole = cleanRole;
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
    Map<String, dynamic>? data,
  }) {
    final notif = FarmAppNotification(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      title: title,
      message: message,
      type: type,
      timestamp: DateTime.now(),
      targetRole: targetRole,
      data: data,
    );

    _notifications.insert(0, notif);
    if (_notifications.length > 50) {
      _notifications.removeLast();
    }
    notifyListeners();

    // Déclencher le push natif
    showPushNotification(title: title, body: message);
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
    // 1. Événements de tâches (Nouvelle tâche / Tâche clôturée)
    _taskSubscription = _socketService.taskEvents.listen((event) {
      final title = event['taskTitle']?.toString() ?? 'Tâche';
      final status = event['status']?.toString();
      final worker = event['workerName']?.toString() ?? 'Personnel';

      if (status == 'pending_validation') {
        // Notifier le Technicien & le Directeur
        if (_isRole(AppConstants.roleTechnician) || _isRole(AppConstants.roleDirector)) {
          addNotification(
            title: 'Tâche à valider',
            message: '$worker a terminé la tâche "$title". En attente de validation.',
            type: 'task',
            targetRole: 'technicien',
            data: event,
          );
        }
      } else {
        // Nouvelle tâche créée
        if (_isRole(AppConstants.rolePoultryKeeper) || _isRole(AppConstants.roleDirector)) {
          addNotification(
            title: 'Nouvelle tâche assignée',
            message: 'Tâche : "$title" programmée dans votre planning.',
            type: 'task',
            targetRole: 'volailler',
            data: event,
          );
        }
      }
    });

    // 2. Événements de stock (Sortie d'œufs, Réception validée, Rupture)
    _stockSubscription = _socketService.stockEvents.listen((event) {
      final type = event['type']?.toString();
      final qty = event['qty'] ?? event['verifiedCount'] ?? '';

      if (type == 'egg_exit') {
        if (_isRole(AppConstants.roleWarehouseManager) || _isRole(AppConstants.roleDirector)) {
          addNotification(
            title: 'Nouvelle sortie d\'œufs déclarée',
            message: '$qty œufs en provenance du poulailler en attente de vérification au magasin.',
            type: 'reception',
            targetRole: 'magasinier',
            data: event,
          );
        }
      } else if (type == 'egg_reception_validated') {
        if (_isRole(AppConstants.roleTechnician) || _isRole(AppConstants.roleDirector)) {
          addNotification(
            title: 'Réception d\'œufs validée',
            message: 'Le magasinier a validé la réception de $qty œufs.',
            type: 'reception',
            targetRole: 'technicien',
            data: event,
          );
        }
      } else if (type == 'critical_stock') {
        if (_isRole(AppConstants.roleTechnician) || _isRole(AppConstants.roleDirector) || _isRole(AppConstants.roleWarehouseManager)) {
          addNotification(
            title: 'Alerte : Seuil de stock critique !',
            message: 'Le stock de ${event['itemName'] ?? 'produit'} est inférieur au seuil d\'alerte.',
            type: 'stock_alert',
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
      final building = event['building_name']?.toString() ?? event['building']?.toString() ?? 'Bâtiment';
      final desc = event['description']?.toString() ?? 'Anomalie signalée';
      if (_isRole(AppConstants.roleDirector) || _isRole(AppConstants.roleTechnician)) {
        addNotification(
          title: 'Anomalie signalée — $building',
          message: desc,
          type: 'anomaly',
          data: event,
        );
      }
    });

    // 6. Événements d'alertes génériques
    _alertSubscription = _socketService.alertEvents.listen((event) {
      final title = event['title']?.toString() ?? 'Alerte Ferme';
      final message = event['message']?.toString() ?? 'Une alerte a été signalée.';
      addNotification(
        title: title,
        message: message,
        type: 'anomaly',
        data: event,
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
