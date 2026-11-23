import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:swasthyasathi/src/services/offline_sync_queue_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('OfflineSyncQueueService Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('Enqueues action and updates pending count', () async {
      final service = OfflineSyncQueueService();
      await service.loadQueue();

      expect(service.pendingCount, equals(0));

      final action = await service.enqueue(
        endpoint: '/api/v1/conversations/123/messages',
        payload: {'message_content': 'Hello doctor, testing offline mode'},
      );

      expect(action.id.isNotEmpty, isTrue);
      expect(action.status, equals(SyncStatus.pending));
      expect(service.pendingCount, equals(1));
      expect(service.queue.first.endpoint, equals('/api/v1/conversations/123/messages'));
    });

    test('Serializes and deserializes SyncAction correctly', () {
      final now = DateTime.now();
      final action = SyncAction(
        id: 'test_1',
        endpoint: '/api/v1/conv-prescriptions',
        httpMethod: 'POST',
        payload: {'title': 'Rx 1'},
        status: SyncStatus.pending,
        retryCount: 1,
        createdAt: now,
      );

      final json = action.toJson();
      final revived = SyncAction.fromJson(json);

      expect(revived.id, equals('test_1'));
      expect(revived.endpoint, equals('/api/v1/conv-prescriptions'));
      expect(revived.status, equals(SyncStatus.pending));
      expect(revived.retryCount, equals(1));
    });

    test('Clears completed actions from queue', () async {
      final service = OfflineSyncQueueService();
      await service.loadQueue();

      final a1 = await service.enqueue(
        endpoint: '/api/v1/test',
        payload: {'data': 1},
      );
      a1.status = SyncStatus.completed;

      await service.clearCompleted();
      expect(service.queue.where((a) => a.id == a1.id).isEmpty, isTrue);
    });
  });
}
