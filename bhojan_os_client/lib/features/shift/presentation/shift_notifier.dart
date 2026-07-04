import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_client.dart';
import '../domain/shift_model.dart';

class ShiftState {
  final ShiftModel? activeShift;
  final List<ShiftModel> history;
  final bool isLoading;
  final String? errorMessage;

  ShiftState({
    this.activeShift,
    required this.history,
    required this.isLoading,
    this.errorMessage,
  });

  ShiftState copyWith({
    ShiftModel? Function()? activeShift,
    List<ShiftModel>? history,
    bool? isLoading,
    String? Function()? errorMessage,
  }) {
    return ShiftState(
      activeShift: activeShift != null ? activeShift() : this.activeShift,
      history: history ?? this.history,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage != null ? errorMessage() : this.errorMessage,
    );
  }
}

class ShiftNotifier extends StateNotifier<ShiftState> {
  final Ref _ref;

  ShiftNotifier(this._ref)
      : super(ShiftState(history: [], isLoading: false)) {
    fetchActiveShift();
  }

  Future<void> fetchActiveShift() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final response = await _ref.read(dioProvider).get('/shifts/active');
      if (response.statusCode == 200 && response.data['success'] == true) {
        final data = response.data['data'];
        final active = data != null ? ShiftModel.fromJson(data as Map<String, dynamic>) : null;
        state = state.copyWith(activeShift: () => active, isLoading: false);
      } else {
        state = state.copyWith(isLoading: false);
      }
    } catch (e) {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> fetchShiftHistory() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final response = await _ref.read(dioProvider).get('/shifts/history');
      if (response.statusCode == 200 && response.data['success'] == true) {
        final data = response.data['data'] as List<dynamic>;
        final history = data.map((x) => ShiftModel.fromJson(x as Map<String, dynamic>)).toList();
        state = state.copyWith(history: history, isLoading: false);
      } else {
        state = state.copyWith(isLoading: false);
      }
    } catch (e) {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<bool> openShift(double openingCash) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final response = await _ref.read(dioProvider).post(
        '/shifts/open',
        data: {'openingCash': openingCash},
      );
      if (response.statusCode == 200 && response.data['success'] == true) {
        final data = response.data['data'];
        final active = ShiftModel.fromJson(data as Map<String, dynamic>);
        state = state.copyWith(activeShift: () => active, isLoading: false);
        return true;
      } else {
        final msg = response.data['error']?['message'] as String? ?? 'Failed to open shift.';
        state = state.copyWith(isLoading: false, errorMessage: () => msg);
        return false;
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: () => 'Connection error: failed to open shift.');
      return false;
    }
  }

  Future<bool> closeShift(double actualCash) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final response = await _ref.read(dioProvider).post(
        '/shifts/close',
        data: {'actualCash': actualCash},
      );
      if (response.statusCode == 200 && response.data['success'] == true) {
        state = state.copyWith(activeShift: () => null, isLoading: false);
        fetchShiftHistory();
        return true;
      } else {
        final msg = response.data['error']?['message'] as String? ?? 'Failed to close shift.';
        state = state.copyWith(isLoading: false, errorMessage: () => msg);
        return false;
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: () => 'Connection error: failed to close shift.');
      return false;
    }
  }
}

final shiftProvider = StateNotifierProvider<ShiftNotifier, ShiftState>((ref) {
  return ShiftNotifier(ref);
});
