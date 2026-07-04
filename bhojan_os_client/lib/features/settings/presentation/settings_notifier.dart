import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_client.dart';

class TenantSettings {
  final String id;
  final String name;
  final String phone;
  final String address;
  final String? panNumber;
  final double vatRate;
  final double scRate;

  TenantSettings({
    required this.id,
    required this.name,
    required this.phone,
    required this.address,
    this.panNumber,
    required this.vatRate,
    required this.scRate,
  });

  factory TenantSettings.fromJson(Map<String, dynamic> json) {
    return TenantSettings(
      id: json['id'] as String,
      name: json['name'] as String,
      phone: json['phone'] as String,
      address: json['address'] as String,
      panNumber: json['panNumber'] as String?,
      vatRate: double.parse(json['vatRate'].toString()),
      scRate: double.parse(json['scRate'].toString()),
    );
  }
}

class SettingsState {
  final TenantSettings? settings;
  final bool isLoading;
  final String? errorMessage;

  SettingsState({
    this.settings,
    required this.isLoading,
    this.errorMessage,
  });

  SettingsState copyWith({
    TenantSettings? Function()? settings,
    bool? isLoading,
    String? Function()? errorMessage,
  }) {
    return SettingsState(
      settings: settings != null ? settings() : this.settings,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage != null ? errorMessage() : this.errorMessage,
    );
  }
}

class SettingsNotifier extends StateNotifier<SettingsState> {
  final Ref _ref;

  SettingsNotifier(this._ref)
      : super(SettingsState(isLoading: false)) {
    fetchSettings();
  }

  Future<void> fetchSettings() async {
    state = state.copyWith(isLoading: true, errorMessage: () => null);
    try {
      final response = await _ref.read(dioProvider).get('/tenant');
      if (response.statusCode == 200 && response.data['success'] == true) {
        final data = response.data['data'];
        final tenant = data != null ? TenantSettings.fromJson(data as Map<String, dynamic>) : null;
        state = state.copyWith(settings: () => tenant, isLoading: false);
      } else {
        state = state.copyWith(isLoading: false);
      }
    } catch (e) {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<bool> updateSettings({
    required String name,
    required String phone,
    required String address,
    required String panNumber,
    required double vatRate,
    required double scRate,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: () => null);
    try {
      final response = await _ref.read(dioProvider).put(
        '/tenant',
        data: {
          'name': name,
          'phone': phone,
          'address': address,
          'panNumber': panNumber.isEmpty ? null : panNumber,
          'vatRate': vatRate,
          'scRate': scRate,
        },
      );
      if (response.statusCode == 200 && response.data['success'] == true) {
        final data = response.data['data'];
        final tenant = TenantSettings.fromJson(data as Map<String, dynamic>);
        state = state.copyWith(settings: () => tenant, isLoading: false);
        return true;
      } else {
        final msg = response.data['error']?['message'] as String? ?? 'Failed to update settings.';
        state = state.copyWith(isLoading: false, errorMessage: () => msg);
        return false;
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: () => 'Failed to save settings.');
      return false;
    }
  }
}

final settingsProvider = StateNotifierProvider<SettingsNotifier, SettingsState>((ref) {
  return SettingsNotifier(ref);
});
