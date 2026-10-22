import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:gelir_gider_uygulamasi/services/storge_service.dart';
import 'package:get/get.dart' hide Response;

abstract class ApiConstants {
  static const baseUrl = "https://gelir-gider-backend.onrender.com/api";
  static const String login = '/auth/google';
  static const String profile = '/auth/profile';
  static const String categories = '/categories';
  static const String transactions = '/transactions';
  static const String serverClient =
      '567229315149-7sqmdlqnu3vbc87v8bkb6fs393fk1g1j.apps.googleusercontent.com';
}

class ApiServices extends GetxService {
  late StorgeService _storgeService;
  late Dio _dio;

  static String formatError(dynamic error) {
    if (error is DioException) {
      switch (error.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          return "Sunucu yanıt vermedi (Zaman aşımı)";
        case DioExceptionType.connectionError:
          return "İnternet bağlantısı yok veya sunucuya erişilemiyor";
        case DioExceptionType.badResponse:
          return "Sunucu hatası (${error.response?.statusCode})";
        case DioExceptionType.cancel:
          return "İstek iptal edildi";
        default:
          return error.message ?? "Ağ bağlantı hatası";
      }
    }
    return error.toString();
  }

  Future<ApiServices> init() async {
    _storgeService = Get.find<StorgeService>();
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout: const Duration(seconds: 45),
        receiveTimeout: const Duration(seconds: 45),
        sendTimeout: const Duration(seconds: 45),
        contentType: "application/json",
      ),
    );
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = _storgeService.getValue<String>(StorageKeys.userToken);
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (error, handler) async {
          if (error.response?.statusCode == 401) {
            await _storgeService.remove(StorageKeys.userToken);
          }
          return handler.next(error);
        },
      ),
    );
    return this;
  }

  Future<Response> get(
    String path, {
    Map<String, dynamic>? queryParametres,
    Options? options,
    int maxRetries = 2,
  }) async {
    int attempts = 0;
    while (true) {
      attempts++;
      try {
        return await _dio.get(
          path,
          queryParameters: queryParametres,
          options: options,
        );
      } catch (e) {
        final isTimeoutOrNetwork = e is DioException &&
            (e.type == DioExceptionType.connectionTimeout ||
                e.type == DioExceptionType.receiveTimeout ||
                e.type == DioExceptionType.sendTimeout ||
                e.type == DioExceptionType.connectionError);

        if (attempts <= maxRetries && isTimeoutOrNetwork) {
          debugPrint(
            "[API GET $path] Sunucu uyanıyor olabilir, yeniden deneniyor (Deneme $attempts/$maxRetries)...",
          );
          await Future.delayed(Duration(seconds: attempts * 2));
          continue;
        }

        debugPrint("[API GET $path] ${formatError(e)}");
        rethrow;
      }
    }
  }

  Future<Response> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParametres,
    Options? options,
  }) async {
    try {
      return await _dio.post(
        path,
        data: data,
        queryParameters: queryParametres,
        options: options,
      );
    } catch (e) {
      debugPrint("[API POST $path] ${formatError(e)}");
      rethrow;
    }
  }

  Future<Response> put(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParametres,
    Options? options,
  }) async {
    try {
      return await _dio.put(
        path,
        data: data,
        queryParameters: queryParametres,
        options: options,
      );
    } catch (e) {
      debugPrint("[API PUT $path] ${formatError(e)}");
      rethrow;
    }
  }

  Future<Response> delete(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.delete(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } catch (e) {
      debugPrint("[API DELETE $path] ${formatError(e)}");
      rethrow;
    }
  }
}
