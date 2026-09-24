import 'package:flutter_test/flutter_test.dart';
import 'package:ferme_track/core/services/socket_client_service.dart';
import 'package:ferme_track/core/services/system_notification_service.dart';
import 'package:ferme_track/data/datasources/local/cache_manager.dart';

void main() {
  group('SystemNotificationService', () {
    test('starts without mock notifications and exposes only real runtime alerts', () {
      final socketService = SocketClientService(cacheManager: CacheManager());
      final service = SystemNotificationService(socketService: socketService);

      expect(service.notifications, isEmpty);
      expect(service.unreadCount, 0);
      expect(service.activeAlerts, isEmpty);
    });
  });
}
