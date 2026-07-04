import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_client.dart';

class StaffMember {
  final String id;
  final String name;
  final String phone;
  final String role;
  final bool isActive;

  StaffMember({
    required this.id,
    required this.name,
    required this.phone,
    required this.role,
    required this.isActive,
  });

  factory StaffMember.fromJson(Map<String, dynamic> json) {
    return StaffMember(
      id: json['id'] as String,
      name: json['name'] as String,
      phone: json['phone'] as String,
      role: json['role'] as String,
      isActive: json['isActive'] as bool,
    );
  }
}

class StaffState {
  final List<StaffMember> roster;
  final bool isLoading;
  final String? errorMessage;

  StaffState({
    required this.roster,
    required this.isLoading,
    this.errorMessage,
  });

  StaffState copyWith({
    List<StaffMember>? roster,
    bool? isLoading,
    String? Function()? errorMessage,
  }) {
    return StaffState(
      roster: roster ?? this.roster,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage != null ? errorMessage() : this.errorMessage,
    );
  }
}

class StaffNotifier extends StateNotifier<StaffState> {
  final Ref _ref;

  StaffNotifier(this._ref)
      : super(StaffState(roster: [], isLoading: false)) {
    fetchStaff();
  }

  Future<void> fetchStaff() async {
    state = state.copyWith(isLoading: true, errorMessage: () => null);
    try {
      final response = await _ref.read(dioProvider).get('/staff');
      if (response.statusCode == 200 && response.data['success'] == true) {
        final data = response.data['data'] as List<dynamic>;
        final list = data.map((x) => StaffMember.fromJson(x as Map<String, dynamic>)).toList();
        state = state.copyWith(roster: list, isLoading: false);
      } else {
        state = state.copyWith(isLoading: false);
      }
    } catch (e) {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<bool> createStaff({
    required String name,
    required String phone,
    required String password,
    required String pin,
    required String role,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: () => null);
    try {
      final response = await _ref.read(dioProvider).post(
        '/staff',
        data: {
          'name': name,
          'phone': phone,
          'password': password,
          'pin': pin,
          'role': role,
        },
      );
      if (response.statusCode == 201 && response.data['success'] == true) {
        fetchStaff();
        return true;
      } else {
        final msg = response.data['error']?['message'] as String? ?? 'Failed to add staff.';
        state = state.copyWith(isLoading: false, errorMessage: () => msg);
        return false;
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: () => 'Failed to add staff user.');
      return false;
    }
  }

  Future<bool> updateStaff({
    required String id,
    required String name,
    required String phone,
    required String role,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: () => null);
    try {
      final response = await _ref.read(dioProvider).put(
        '/staff/$id',
        data: {
          'name': name,
          'phone': phone,
          'role': role,
        },
      );
      if (response.statusCode == 200 && response.data['success'] == true) {
        fetchStaff();
        return true;
      } else {
        final msg = response.data['error']?['message'] as String? ?? 'Failed to update staff.';
        state = state.copyWith(isLoading: false, errorMessage: () => msg);
        return false;
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: () => 'Failed to update staff user.');
      return false;
    }
  }

  Future<bool> toggleActive(String id, bool isActive) async {
    try {
      final response = await _ref.read(dioProvider).patch(
        '/staff/$id/toggle',
        data: {'isActive': isActive},
      );
      if (response.statusCode == 200 && response.data['success'] == true) {
        fetchStaff();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<bool> resetCredentials({
    required String id,
    String? password,
    String? pin,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: () => null);
    try {
      final response = await _ref.read(dioProvider).patch(
        '/staff/$id/reset-auth',
        data: {
          if (password != null && password.isNotEmpty) 'password': password,
          if (pin != null && pin.isNotEmpty) 'pin': pin,
        },
      );
      if (response.statusCode == 200 && response.data['success'] == true) {
        state = state.copyWith(isLoading: false);
        return true;
      } else {
        final msg = response.data['error']?['message'] as String? ?? 'Failed to reset credentials.';
        state = state.copyWith(isLoading: false, errorMessage: () => msg);
        return false;
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: () => 'Connection error: failed to reset credentials.');
      return false;
    }
  }

  Future<bool> deleteStaff(String id) async {
    state = state.copyWith(isLoading: true, errorMessage: () => null);
    try {
      final response = await _ref.read(dioProvider).delete('/staff/$id');
      if (response.statusCode == 200 && response.data['success'] == true) {
        fetchStaff();
        return true;
      } else {
        final msg = response.data['error']?['message'] as String? ?? 'Failed to delete staff member.';
        state = state.copyWith(isLoading: false, errorMessage: () => msg);
        return false;
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: () => 'Failed to delete staff member.');
      return false;
    }
  }
}

final staffProvider = StateNotifierProvider<StaffNotifier, StaffState>((ref) {
  return StaffNotifier(ref);
});
