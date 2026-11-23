import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

enum SyncStatus { pending, inFlight, failed, completed }

class SyncAction {
  final String id;
  final String endpoint;
  final String httpMethod;
  final Map<String, dynamic> payload;
  SyncStatus status;
  int retryCount;
  final DateTime createdAt;

  SyncAction({
    required this.id,
    required this.endpoint,
    this.httpMethod = 'POST',
    required this.payload,
    this.status = SyncStatus.pending,
    this.retryCount = 0,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'id': id,
        'endpoint': endpoint,
        'http_method': httpMethod,
        'payload': payload,
        'status': status.name,
        'retry_count': retryCount,
        'created_at': createdAt.toIso8601String(),
      };

  factory SyncAction.fromJson(Map<String, dynamic> json) {
    return SyncAction(
      id: json['id'] as String? ?? DateTime.now().millisecondsSinceEpoch.toString(),
      endpoint: json['endpoint'] as String? ?? '',
      httpMethod: json['http_method'] as String? ?? 'POST',
      payload: (json['payload'] as Map<String, dynamic>?) ?? {},
      status: SyncStatus.values.firstWhere(
        (s) => s.name == json['status'],
        orElse: () => SyncStatus.pending,
      ),
      retryCount: json['retry_count'] as int? ?? 0,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}

/// Offline Sync Queue Manager for reliable two-way data sync across intermittent connectivity.
class OfflineSyncQueueService extends ChangeNotifier {
  static final OfflineSyncQueueService _instance = OfflineSyncQueueService._internal();
  factory OfflineSyncQueueService() => _instance;
  OfflineSyncQueueService._internal();

  static const String _storageKey = 'swasthyasathi_sync_queue';
  final List<SyncAction> _queue = [];
  bool _isProcessing = false;

  List<SyncAction> get queue => List.unmodifiable(_queue);
  int get pendingCount => _queue.where((a) => a.status == SyncStatus.pending).length;
  bool get isProcessing => _isProcessing;

  /// Loads persisted pending sync actions from disk.
  Future<void> loadQueue() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_storageKey);
      if (raw != null && raw.isNotEmpty) {
        final List<dynamic> list = json.decode(raw);
        _queue.clear();
        for (final item in list) {
          if (item is Map<String, dynamic>) {
            _queue.add(SyncAction.fromJson(item));
          }
        }
        notifyListeners();
      }
    } catch (e) {
      debugPrint('[OfflineSyncQueue] Failed to load queue: $e');
    }
  }

  /// Saves current queue to disk.
  Future<void> _persistQueue() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = _queue.map((a) => a.toJson()).toList();
      await prefs.setString(_storageKey, json.encode(list));
    } catch (e) {
      debugPrint('[OfflineSyncQueue] Failed to persist queue: $e');
    }
  }

  /// Enqueues an outgoing offline mutation.
  Future<SyncAction> enqueue({
    required String endpoint,
    required Map<String, dynamic> payload,
    String httpMethod = 'POST',
  }) async {
    final action = SyncAction(
      id: 'sync_${DateTime.now().millisecondsSinceEpoch}_${_queue.length}',
      endpoint: endpoint,
      httpMethod: httpMethod,
      payload: payload,
    );

    _queue.add(action);
    await _persistQueue();
    notifyListeners();
    return action;
  }

  /// Processes all pending actions sequentially (FIFO) when internet is available.
  Future<int> processQueue({required String baseUrl, required String? token}) async {
    if (_isProcessing || token == null) return 0;
    _isProcessing = true;
    notifyListeners();

    int syncedCount = 0;
    final pendingActions = _queue.where((a) => a.status == SyncStatus.pending).toList();

    for (final action in pendingActions) {
      action.status = SyncStatus.inFlight;
      notifyListeners();

      try {
        final url = Uri.parse('$baseUrl${action.endpoint}');
        http.Response res;

        final headers = {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        };

        if (action.httpMethod.toUpperCase() == 'POST') {
          res = await http.post(url, headers: headers, body: json.encode(action.payload));
        } else if (action.httpMethod.toUpperCase() == 'PUT') {
          res = await http.put(url, headers: headers, body: json.encode(action.payload));
        } else {
          res = await http.get(url, headers: headers);
        }

        if (res.statusCode >= 200 && res.statusCode < 300) {
          action.status = SyncStatus.completed;
          syncedCount++;
          _queue.removeWhere((a) => a.id == action.id);
        } else if (res.statusCode >= 400 && res.statusCode < 500) {
          // Client error (e.g. invalid payload) — don't retry endlessly
          action.status = SyncStatus.failed;
          action.retryCount++;
        } else {
          // Server error / network drop
          action.status = SyncStatus.pending;
          action.retryCount++;
          break; // Stop batch until connection recovers
        }
      } catch (err) {
        // Network unreachable
        action.status = SyncStatus.pending;
        action.retryCount++;
        break; // Stop and retry later
      }
    }

    await _persistQueue();
    _isProcessing = false;
    notifyListeners();
    return syncedCount;
  }

  /// Clears completed actions.
  Future<void> clearCompleted() async {
    _queue.removeWhere((a) => a.status == SyncStatus.completed);
    await _persistQueue();
    notifyListeners();
  }
}
