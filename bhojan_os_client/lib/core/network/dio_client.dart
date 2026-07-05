import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/auth/presentation/auth_notifier.dart';

final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: 'http://192.168.1.68:3000/api/v1',
      connectTimeout: const Duration(seconds: 5),
      receiveTimeout: const Duration(seconds: 5),
    ),
  );

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        final authState = ref.read(authProvider);
        if (authState.accessToken != null) {
          options.headers['Authorization'] = 'Bearer ${authState.accessToken}';
        }
        if (authState.user != null) {
          options.headers['X-Restaurant-Id'] = authState.user!.restaurantId;
        }
        return handler.next(options);
      },
      onError: (e, handler) {
        if (e.response?.statusCode == 401 || e.response?.statusCode == 403) {
          // If authorization fails, trigger session lock to prompt PIN unlock or re-login
          ref.read(authProvider.notifier).lockSession();
        }
        return handler.next(e);
      },
    ),
  );

  return dio;
});
