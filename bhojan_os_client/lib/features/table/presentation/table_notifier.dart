import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_client.dart';
import '../../sync/domain/sync_service.dart';
import '../domain/table_model.dart';

class TableNotifier extends StateNotifier<List<TableModel>> {
  final Ref _ref;

  TableNotifier(this._ref) : super(_initialTables) {
    fetchTables();
  }

  static final List<TableModel> _initialTables = [
    TableModel(id: 't1', tableNumber: 'T-1', capacity: 4, section: 'Ground Floor', status: 'FREE'),
    TableModel(id: 't2', tableNumber: 'T-2', capacity: 2, section: 'Ground Floor', status: 'OCCUPIED'),
    TableModel(id: 't3', tableNumber: 'T-3', capacity: 4, section: 'Ground Floor', status: 'FREE'),
    TableModel(id: 'bar1', tableNumber: 'Bar-1', capacity: 2, section: 'Ground Floor', status: 'FREE'),
    TableModel(id: 'r1', tableNumber: 'R-1', capacity: 6, section: 'Rooftop Garden', status: 'OCCUPIED'),
    TableModel(id: 'r2', tableNumber: 'R-2', capacity: 4, section: 'Rooftop Garden', status: 'FREE'),
    TableModel(id: 'r3', tableNumber: 'R-3', capacity: 8, section: 'Rooftop Garden', status: 'BILLING'),
  ];

  Future<void> fetchTables() async {
    try {
      final response = await _ref.read(dioProvider).get('/tables');
      if (response.statusCode == 200 && response.data['success'] == true) {
        final data = response.data['data'] as List<dynamic>;
        state = data.map((json) => TableModel.fromJson(json as Map<String, dynamic>)).toList();
      }
    } catch (e) {
      // Offline fallback: keep the initial local seeded tables.
      // In production, this can load cached data from Hive.
      // ignore: avoid_print
      print('Network offline. Loaded local mock table grid: $e');
    }
  }

  Future<void> updateTableStatus(String tableId, String status) async {
    // Optimistic UI updates
    state = [
      for (final table in state)
        if (table.id == tableId) table.copyWith(status: status) else table
    ];

    try {
      await _ref.read(dioProvider).patch('/tables/$tableId/status', data: {'status': status});
    } catch (e) {
      // Queue mutation for background synchronization
      await _ref.read(syncServiceProvider).queueMutation(
        '/tables/$tableId/status',
        'PATCH',
        {'status': status},
      );
    }
  }

  Future<bool> createTable({
    required String tableNumber,
    required int capacity,
    required String section,
  }) async {
    try {
      final response = await _ref.read(dioProvider).post(
        '/tables',
        data: {
          'tableNumber': tableNumber,
          'capacity': capacity,
          'section': section,
        },
      );
      if (response.statusCode == 201 && response.data['success'] == true) {
        await fetchTables();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<bool> updateTable({
    required String id,
    required String tableNumber,
    required int capacity,
    required String section,
  }) async {
    try {
      final response = await _ref.read(dioProvider).put(
        '/tables/$id',
        data: {
          'tableNumber': tableNumber,
          'capacity': capacity,
          'section': section,
        },
      );
      if (response.statusCode == 200 && response.data['success'] == true) {
        await fetchTables();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteTable(String id) async {
    try {
      final response = await _ref.read(dioProvider).delete('/tables/$id');
      if (response.statusCode == 200 && response.data['success'] == true) {
        await fetchTables();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }
}

final tableProvider = StateNotifierProvider<TableNotifier, List<TableModel>>((ref) {
  return TableNotifier(ref);
});

