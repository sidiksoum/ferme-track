import 'package:flutter_test/flutter_test.dart';
import 'package:ferme_track/data/models/sync_operation.dart';
import 'package:ferme_track/data/datasources/local/cache_manager.dart';
import 'package:ferme_track/core/interfaces/network_checker.dart';

void main() {
  group('SyncOperation Model Tests', () {
    test('should create SyncOperation with unique ID and pending status', () {
      final op = SyncOperation.create(
        endpoint: '/volailler/tasks/task-123/close',
        method: 'PATCH',
        payload: {'confirmed': true, 'feedQtyKg': 50.0},
        description: 'Clôture alimentation',
      );

      expect(op.id, isNotEmpty);
      expect(op.endpoint, equals('/volailler/tasks/task-123/close'));
      expect(op.method, equals('PATCH'));
      expect(op.status, equals(SyncStatus.pending));
      expect(op.payload?['feedQtyKg'], equals(50.0));
      expect(op.description, equals('Clôture alimentation'));
    });

    test('should correctly serialize toMap and deserialize fromMap', () {
      final original = SyncOperation.create(
        endpoint: '/activities/bulk',
        method: 'POST',
        payload: {'count': 3, 'buildingId': 'b-1'},
      );

      final map = original.toMap();
      final restored = SyncOperation.fromMap(map);

      expect(restored.id, equals(original.id));
      expect(restored.endpoint, equals(original.endpoint));
      expect(restored.method, equals('POST'));
      expect(restored.payload?['count'], equals(3));
      expect(restored.status, equals(SyncStatus.pending));
    });

    test('copyWith should update fields immutably', () {
      final op = SyncOperation.create(
        endpoint: '/test',
        method: 'POST',
      );

      final updated = op.copyWith(
        status: SyncStatus.syncing,
        retryCount: 1,
      );

      expect(updated.status, equals(SyncStatus.syncing));
      expect(updated.retryCount, equals(1));
      expect(op.status, equals(SyncStatus.pending));
      expect(op.retryCount, equals(0));
    });
  });

  group('CacheManager Key Generation Tests', () {
    test('makeKey should produce deterministic keys regardless of param ordering', () {
      final key1 = CacheManager.makeKey('/api/v1/tasks', {'building': 'A', 'status': 'todo'});
      final key2 = CacheManager.makeKey('/api/v1/tasks', {'status': 'todo', 'building': 'A'});

      expect(key1, equals(key2));
      expect(key1, equals('/api/v1/tasks?building=A&status=todo'));
    });

    test('makeKey without params should return trimmed endpoint', () {
      final key = CacheManager.makeKey('  /volailler/tasks  ');
      expect(key, equals('/volailler/tasks'));
    });

    test('deepCast should recursively cast Map<dynamic, dynamic> to Map<String, dynamic>', () {
      final dynamicMap = <dynamic, dynamic>{
        'id': 'u-1',
        'info': <dynamic, dynamic>{
          'name': 'Koffi',
          'tags': <dynamic>['volailler', 'actif'],
        },
      };

      final casted = CacheManager.deepCast(dynamicMap);
      expect(casted, isA<Map<String, dynamic>>());
      expect((casted as Map<String, dynamic>)['info'], isA<Map<String, dynamic>>());
    });
  });

  group('NetworkCheckerStub Tests', () {
    test('stub should report online', () async {
      final checker = NetworkCheckerStub();
      expect(await checker.hasConnection, isTrue);
    });
  });
}

