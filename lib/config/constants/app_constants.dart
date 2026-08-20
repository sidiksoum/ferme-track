/// Application Constants
class AppConstants {
  // App Info
  static const String appName = 'Ferme-track';
  static const String appVersion = '1.0.0';
  static const String farmName = 'Ferme Akoupé';

  // API Configuration
  static const String baseUrl = 'https://api.ferme-track.local/v1';
  static const Duration connectionTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);

  // Local Database
  static const String databaseName = 'ferme_track.db';
  static const int databaseVersion = 1;

  // Hive Boxes
  static const String boxUser = 'user';
  static const String boxActivities = 'activities';
  static const String boxBuildings = 'buildings';
  static const String boxStocks = 'stocks';
  static const String boxSales = 'sales';
  static const String boxClients = 'clients';
  static const String boxSync = 'sync_queue';

  // Sync Configuration
  static const Duration syncInterval = Duration(minutes: 5);
  static const int maxRetries = 3;

  // Pagination
  static const int pageSize = 20;

  // User Roles
  static const String roleDirector = 'directeur';
  static const String roleTechnician = 'technicien';
  static const String rolePoultryKeeper = 'volailler';
  static const String roleWarehouseManager = 'magasinier';

  // Activity Statuses
  static const String statusTodo = 'todo';
  static const String statusInProgress = 'in_progress';
  static const String statusDone = 'done';
  static const String statusPartial = 'partial';
  static const String statusLate = 'late';

  // Priority Levels
  static const int priorityLow = 1;
  static const int priorityMedium = 2;
  static const int priorityHigh = 3;

  // Notification Types
  static const String notifActivityLate = 'activity_late';
  static const String notifVaccinationDue = 'vaccination_due';
  static const String notifStockRupture = 'stock_rupture';
  static const String notifAbnormalMortality = 'abnormal_mortality';
  static const String notifDeliveryDelay = 'delivery_delay';
  static const String notifPaymentDue = 'payment_due';
  static const String notifAnomaly = 'anomaly';

  // Error Messages
  static const String errorNetworkConnection = 'Erreur de connexion réseau';
  static const String errorServerError = 'Erreur serveur';
  static const String errorUnauthorized = 'Non autorisé';
  static const String errorInvalidCredentials = 'Identifiants invalides';
  static const String errorOfflineMode = 'Mode hors ligne activé';

  // Success Messages
  static const String successLogin = 'Connexion réussie';
  static const String successActivityCreated = 'Activité créée';
  static const String successActivityUpdated = 'Activité mise à jour';
  static const String successSynced = 'Synchronisation réussie';

  // Timeouts & Delays
  static const Duration snackbarDuration = Duration(seconds: 3);
  static const Duration shortDelay = Duration(milliseconds: 300);
  static const Duration mediumDelay = Duration(milliseconds: 500);
  static const Duration longDelay = Duration(milliseconds: 1000);

  // Image & File
  static const int maxImageSize = 5 * 1024 * 1024; // 5MB
  static const String imageQuality = '80';

  // Locale
  static const String defaultLocale = 'fr_CI';
  static const List<String> supportedLocales = ['fr_CI'];
}

/// Route Names
class RouteNames {
  static const String splash = '/';
  static const String login = '/login';
  static const String directorDashboard = '/director/dashboard';
  static const String technicianPlanning = '/technician/planning';
  static const String poltrykeeperTasks = '/poultrykeeper/tasks';
  static const String warehouseHome = '/warehouse/home';
}

/// Activity Types
class ActivityTypes {
  static const String feeding = 'feeding';
  static const String watering = 'watering';
  static const String cleaning = 'cleaning';
  static const String eggCollection = 'egg_collection';
  static const String weighing = 'weighing';
  static const String vaccination = 'vaccination';
  static const String sanitaryTreatment = 'sanitary_treatment';
  static const String disinfection = 'disinfection';

  static const Map<String, String> labels = {
    'feeding': 'Alimentation',
    'watering': 'Abreuvement',
    'cleaning': 'Nettoyage',
    'egg_collection': 'Ramassage œufs',
    'weighing': 'Pesée',
    'vaccination': 'Vaccination',
    'sanitary_treatment': 'Traitement sanitaire',
    'disinfection': 'Désinfection',
  };
}

/// Client Types
class ClientTypes {
  static const String retailer = 'retailer';
  static const String wholesaler = 'wholesaler';
  static const String restaurant = 'restaurant';

  static const Map<String, String> labels = {
    'retailer': 'Détaillant',
    'wholesaler': 'Grossiste',
    'restaurant': 'Restaurateur',
  };
}

/// Anomaly Types
class AnomalyTypes {
  static const String technical = 'technical';
  static const String sanitary = 'sanitary';
  static const String security = 'security';

  static const Map<String, String> labels = {
    'technical': 'Technique',
    'sanitary': 'Sanitaire',
    'security': 'Sécurité',
  };
}

/// Mortality Causes
class MortalityCauses {
  static const String heat = 'heat';
  static const String disease = 'disease';
  static const String unknown = 'unknown';

  static const Map<String, String> labels = {
    'heat': 'Chaleur',
    'disease': 'Maladie',
    'unknown': 'Inconnue',
  };
}

/// Payment Methods
class PaymentMethods {
  static const String cash = 'cash';
  static const String mobileMoney = 'mobile_money';
  static const String transfer = 'transfer';

  static const Map<String, String> labels = {
    'cash': 'Espèces',
    'mobile_money': 'Mobile Money',
    'transfer': 'Virement',
  };
}
