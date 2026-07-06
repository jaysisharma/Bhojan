import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../domain/auth_state.dart';

// Base API URL. In Android emulators, 10.0.2.2 connects to host loopback.
const String _baseUrl = 'http://192.168.1.76:3000/api/v1';

class AuthNotifier extends StateNotifier<AuthState> {
  final Dio _dio = Dio();
  
  AuthNotifier() : super(AuthState.initial()) {
    _initializeFromCache();
  }

  /// Reads token details and user profile from Hive storage to restore active sessions.
  Future<void> _initializeFromCache() async {
    try {
      final authBox = await Hive.openBox('auth_box');
      final accessToken = authBox.get('accessToken') as String?;
      final refreshToken = authBox.get('refreshToken') as String?;
      final userJson = authBox.get('user') as String?;

      if (accessToken != null && refreshToken != null && userJson != null) {
        final user = UserProfile.fromJson(jsonDecode(userJson) as Map<String, dynamic>);
        // Automatically restore session as pinLocked to protect access on launch
        state = AuthState(
          status: AuthStatus.pinLocked,
          user: user,
          accessToken: accessToken,
          refreshToken: refreshToken,
        );
      }
    } catch (e) {
      state = AuthState(
        status: AuthStatus.unauthenticated,
        errorMessage: 'Failed to restore session from cache.',
      );
    }
  }

  /// Log in user using phone and password credentials.
  Future<void> login(String phone, String password) async {
    state = state.copyWith(status: AuthStatus.authenticating, errorMessage: null);

    try {
      final response = await _dio.post(
        '$_baseUrl/auth/login',
        data: {'phone': phone, 'password': password},
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        final responseData = response.data['data'] as Map<String, dynamic>;
        final accessToken = responseData['accessToken'] as String;
        final refreshToken = responseData['refreshToken'] as String;
        final userMap = responseData['user'] as Map<String, dynamic>;
        
        final user = UserProfile.fromJson(userMap);

        // Cache tokens and user details
        final authBox = await Hive.openBox('auth_box');
        await authBox.put('accessToken', accessToken);
        await authBox.put('refreshToken', refreshToken);
        await authBox.put('user', jsonEncode(user.toJson()));

        state = AuthState(
          status: AuthStatus.authenticated,
          user: user,
          accessToken: accessToken,
          refreshToken: refreshToken,
        );

        // Register FCM device token
        try {
          final fcmToken = await FirebaseMessaging.instance.getToken();
          if (fcmToken != null) {
            await _dio.post(
              '$_baseUrl/auth/device-token',
              data: {'token': fcmToken},
              options: Options(
                headers: {
                  'Authorization': 'Bearer $accessToken',
                  'X-Restaurant-Id': user.restaurantId,
                },
              ),
            );
          }
        } catch (_) {}
      } else {
        final errorMsg = response.data['error']?['message'] as String? ?? 'Authentication failed.';
        state = state.copyWith(status: AuthStatus.error, errorMessage: errorMsg);
      }
    } on DioException catch (e) {
      final errorMsg = e.response?.data['error']?['message'] as String? ?? 'Network connection failed.';
      state = state.copyWith(status: AuthStatus.error, errorMessage: errorMsg);
    } catch (e) {
      state = state.copyWith(status: AuthStatus.error, errorMessage: 'An unexpected error occurred.');
    }
  }

  /// Verify session resumption using the quick 4-digit PIN lock screen code.
  Future<bool> verifyPin(String pin) async {
    if (state.accessToken == null || state.user == null) {
      state = AuthState.initial();
      return false;
    }

    try {
      final response = await _dio.post(
        '$_baseUrl/auth/pin-verify',
        data: {'pin': pin},
        options: Options(
          headers: {
            'Authorization': 'Bearer ${state.accessToken}',
            'X-Restaurant-Id': state.user!.restaurantId,
          },
        ),
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        final isVerified = response.data['data']['verified'] as bool;
        if (isVerified) {
          state = state.copyWith(status: AuthStatus.authenticated, errorMessage: null);
          return true;
        }
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Locks the active session, routing the user to the PIN lock verification screen.
  void lockSession() {
    if (state.status == AuthStatus.authenticated) {
      state = state.copyWith(status: AuthStatus.pinLocked);
    }
  }

  /// Register and onboard a new restaurant tenant and its owner profile.
  Future<bool> registerRestaurant({
    required String restaurantName,
    required String ownerName,
    required String phone,
    required String password,
    required String address,
    required String panNumber,
  }) async {
    state = state.copyWith(status: AuthStatus.authenticating, errorMessage: null);

    try {
      final response = await _dio.post(
        '$_baseUrl/auth/register',
        data: {
          'restaurantName': restaurantName,
          'ownerName': ownerName,
          'phone': phone,
          'password': password,
          'address': address,
          'panNumber': panNumber.isEmpty ? null : panNumber,
        },
      );

      if ((response.statusCode == 200 || response.statusCode == 201) && response.data['success'] == true) {
        state = state.copyWith(status: AuthStatus.unauthenticated, errorMessage: null);
        return true;
      } else {
        final errorMsg = response.data['error']?['message'] as String? ?? 'Registration failed.';
        state = state.copyWith(status: AuthStatus.error, errorMessage: errorMsg);
        return false;
      }
    } on DioException catch (e) {
      final errorMsg = e.response?.data['error']?['message'] as String? ?? 'Network connection failed.';
      state = state.copyWith(status: AuthStatus.error, errorMessage: errorMsg);
      return false;
    } catch (e) {
      state = state.copyWith(status: AuthStatus.error, errorMessage: 'An unexpected error occurred.');
      return false;
    }
  }

  /// Logs out the user and clears all cached security tokens.
  Future<void> logout() async {
    try {
      final authBox = await Hive.openBox('auth_box');
      await authBox.clear();
    } catch (_) {}
    state = AuthState.initial();
  }
}

// Global provider mapping for the auth notifier state engine
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});
