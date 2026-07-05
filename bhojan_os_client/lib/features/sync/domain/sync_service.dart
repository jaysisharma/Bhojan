import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import '../../../core/network/dio_client.dart';
import '../data/sync_item.dart';

class SyncService extends ChangeNotifier {
  final Ref _ref;
  Box? _syncBox;
  bool _isProcessing = false;

  SyncService(this._ref) {
    _init();
  }

  int get queueLength => _syncBox?.length ?? 0;

  Future<void> _init() async {
    try {
      _syncBox = await Hive.openBox('sync_queue_box');
      notifyListeners();

      // Monitor network connection status changes (connectivity_plus v6.x uses List<ConnectivityResult>)
      Connectivity()
          .onConnectivityChanged
          .listen((List<ConnectivityResult> results) {
        final hasConnection =
            results.any((result) => result != ConnectivityResult.none);
        if (hasConnection) {
          // ignore: avoid_print
          print('Network connection status restored. Syncing queue...');
          processQueue();
        }
      });

      // Initial processing loop on session resume
      processQueue();
    } catch (e) {
      // ignore: avoid_print
      print('SyncService initialization failed: $e');
    }
  }

  Future<void> queueMutation(
      String endpoint, String method, Map<String, dynamic> payload) async {
    if (_syncBox == null) return;

    final item = SyncItem(
      id: 'sync_${DateTime.now().millisecondsSinceEpoch}',
      endpoint: endpoint,
      method: method,
      payload: payload,
      timestamp: DateTime.now(),
    );

    await _syncBox!.put(item.id, jsonEncode(item.toJson()));
    notifyListeners();
    // ignore: avoid_print
    print('Offline Mutation Cached: [$method] $endpoint');

    processQueue();
  }

  Future<void> processQueue() async {
    if (_syncBox == null || _isProcessing || _syncBox!.isEmpty) return;

    _isProcessing = true;
    final dio = _ref.read(dioProvider);

    final keys = List<String>.from(_syncBox!.keys);

    for (final key in keys) {
      final jsonString = _syncBox!.get(key) as String?;
      if (jsonString == null) continue;

      try {
        final syncItem =
            SyncItem.fromJson(jsonDecode(jsonString) as Map<String, dynamic>);
        Response response;

        if (syncItem.method == 'POST') {
          response = await dio.post(syncItem.endpoint, data: syncItem.payload);
        } else if (syncItem.method == 'PATCH') {
          response = await dio.patch(syncItem.endpoint, data: syncItem.payload);
        } else if (syncItem.method == 'PUT') {
          response = await dio.put(syncItem.endpoint, data: syncItem.payload);
        } else {
          throw Exception('Unsupported mutation method: ${syncItem.method}');
        }

        if (response.statusCode == 200 || response.statusCode == 201) {
          await _syncBox!.delete(key);
          notifyListeners();
          // ignore: avoid_print
          print(
              'Successfully reconciled queued request: [${syncItem.method}] ${syncItem.endpoint}');
        }
      } catch (e) {
        if (e is DioException) {
          final statusCode = e.response?.statusCode;
          if (statusCode != null && statusCode >= 400 && statusCode < 500) {
            await _syncBox!.delete(key);
            notifyListeners();
            // ignore: avoid_print
            print(
                'Poisoned request discarded from queue (Status $statusCode): $e');
            continue;
          }
        }
        // ignore: avoid_print
        print('Queue processing error on key $key: $e. Retries scheduled.');
        break;
      }
    }

    _isProcessing = false;
  }
}

final syncServiceProvider = ChangeNotifierProvider<SyncService>((ref) {
  return SyncService(ref);
});
