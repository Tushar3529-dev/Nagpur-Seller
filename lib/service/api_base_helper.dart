import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:curl_logger_dio_interceptor/curl_logger_dio_interceptor.dart';
import 'package:hyper_local_seller/service/security.dart';
import 'package:hyper_local_seller/service/session_manager.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';

class ApiBaseHelper {
  // One Dio client shared by every repository.
  static final Dio _dio = _createDio();

  static Dio _createDio() {
    final dio = Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 20),
        receiveTimeout: const Duration(seconds: 60),
        sendTimeout: const Duration(seconds: 120),
      ),
    );

    // dio.interceptors.add(CurlLoggerDioInterceptor(printOnSuccess: true));

    // dio.interceptors.add(
    //   PrettyDioLogger(
    //     requestHeader: true,
    //     requestBody: true,
    //     responseBody: true,
    //     responseHeader: false,
    //     error: true,
    //     compact: true,
    //     maxWidth: 120,
    //   ),
    // );

    // Add default headers interceptor
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final headers = await Security.headers;
          options.headers.addAll(headers);
          if (kDebugMode && options.extra['debugInventory'] == true) {
            debugPrint(
              '[Inventory] outgoing headers | Accept: ${options.headers['Accept']} | Content-Type: ${options.contentType} | Authorization: ${headers.containsKey('Authorization') ? 'Bearer [REDACTED]' : 'MISSING'}',
            );
          }
          return handler.next(options);
        },
        onError: (DioException e, handler) {
          // Expired/invalid token — log the user out globally.
          if (e.response?.statusCode == 401) {
            SessionManager.handleUnauthorized();
          }
          return handler.next(e);
        },
      ),
    );
    return dio;
  }

  Future<dynamic> post(
    String url,
    Map<String, dynamic> body, {
    bool debugInventory = false,
  }) async {
    try {
      if (kDebugMode && debugInventory) {
        debugPrint('[Inventory] POST $url | request: $body');
      }
      final response = await _dio.post(
        url,
        data: body,
        options: Options(extra: {'debugInventory': debugInventory}),
      );
      if (kDebugMode && debugInventory) {
        debugPrint(
          '[Inventory] POST $url | HTTP ${response.statusCode} | response: ${response.data}',
        );
      }
      return _returnResponse(response);
    } on DioException catch (e) {
      if (kDebugMode && debugInventory) {
        debugPrint(
          '[Inventory] redirect location: ${e.response?.headers.value('location')}',
        );
        debugPrint(
          '[Inventory] POST $url | HTTP ${e.response?.statusCode} | type: ${e.type} | message: ${e.message} | response: ${e.response?.data}',
        );
      }
      throw _handleError(e);
    }
  }

  Future<dynamic> get(
    String url, {
    Map<String, dynamic>? queryParameters,
    bool allowMissingSuccessFlag = false,
  }) async {
    try {
      final response = await _dio.get(url, queryParameters: queryParameters);
      return _returnResponse(
        response,
        allowMissingSuccessFlag: allowMissingSuccessFlag,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<dynamic> put(String url, Map<String, dynamic> body) async {
    try {
      final response = await _dio.put(url, data: body);
      return _returnResponse(response);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<dynamic> delete(String url, {Map<String, dynamic>? body}) async {
    try {
      final response = await _dio.delete(url, data: body);
      return _returnResponse(response);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<dynamic> postMultipart(String url, FormData formData) async {
    try {
      final response = await _dio.post(url, data: formData);
      return _returnResponse(response);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// [allowMissingSuccessFlag] accepts a 2xx body that has no `success` key at
  /// all (an explicit `success: false` is still treated as an error).
  dynamic _returnResponse(
    Response response, {
    bool allowMissingSuccessFlag = false,
  }) {
    switch (response.statusCode) {
      case 200:
      case 201:
        final responseBody = response.data;
        if (allowMissingSuccessFlag &&
            responseBody is Map<String, dynamic> &&
            !responseBody.containsKey('success')) {
          return responseBody;
        }
        // Robust check for { success, message, data } structure
        if (responseBody is Map<String, dynamic>) {
          bool success =
              responseBody['success'] ?? false; // Default to false if missing
          String message = responseBody['message'] ?? "Unknown error";

          if (success) {
            // Return full response body to allow access to root level fields like 'access_token'
            return responseBody;
          } else {
            // If success is false, throw the message
            throw ApiException(message, responseData: responseBody);
          }
        }

        // Fallback if structure is completely different (plain json)
        return responseBody;

      case 400:
        throw BadRequestException(response.data.toString());
      case 401:
      case 403:
        throw UnauthorisedException(response.data.toString());
      case 500:
      default:
        throw FetchDataException(
          'Error occurred while Communication with Server with StatusCode : ${response.statusCode}',
        );
    }
  }

  Exception _handleError(DioException error) {
    if (error.response != null) {
      final data = error.response?.data;
      final int? statusCode = error.response?.statusCode;

      if (data is Map<String, dynamic>) {
        // Preserve item/field errors from the order verification endpoint.
        if (statusCode == 422 &&
            data['data'] is Map &&
            (data['data'] as Map)['errors'] is List) {
          return ApiException(
            data['message'],
            statusCode: statusCode,
            responseData: data,
          );
        }
        // Handle validation errors (422)
        if (statusCode == 422 && data.containsKey('errors')) {
          final errors = data['errors'] as Map<String, dynamic>;
          final List<String> errorMessages = [];

          // Collect all error messages
          errors.forEach((key, value) {
            if (value is List) {
              errorMessages.addAll(value.map((e) => e.toString()));
            } else {
              errorMessages.add(value.toString());
            }
          });

          // If only one error, use the message field
          if (errorMessages.length == 1 && data.containsKey('message')) {
            return ApiException(data['message']);
          }

          // If multiple errors, show all detailed errors
          return ApiException(errorMessages.join('\n'));
        }

        // Handle other errors with message
        if (data.containsKey('message')) {
          return ApiException(
            data['message'],
            statusCode: statusCode,
          ); // Return backend message
        }
      }
      return ApiException(
        "${error.response?.statusMessage}",
        statusCode: statusCode,
      );
    } else {
      switch (error.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          return ApiException("Connection timeout");
        case DioExceptionType.connectionError:
          return ApiException("No Internet Connection");
        case DioExceptionType.unknown:
          if (error.error is SocketException) {
            return ApiException("No Internet Connection");
          }
          return ApiException("Unexpected error occurred");
        default:
          return ApiException("Something went wrong");
      }
    }
  }
}

class AppException implements Exception {
  final String? _message;
  final String? _prefix;

  AppException([this._message, this._prefix]);

  @override
  String toString() {
    return "$_prefix$_message";
  }
}

class FetchDataException extends AppException {
  FetchDataException([String? message])
    : super(message, "Error During Communication: ");
}

class BadRequestException extends AppException {
  BadRequestException([message]) : super(message, "Invalid Request: ");
}

class UnauthorisedException extends AppException {
  UnauthorisedException([message]) : super(message, "Unauthorised: ");
}

class InvalidInputException extends AppException {
  InvalidInputException([String? message]) : super(message, "Invalid Input: ");
}

/// Error carrying a user-facing message from the API; toString() is the
/// plain message so it can be shown directly in the UI.
class ApiException implements Exception {
  final String message;

  /// HTTP status of the failed response, when there was one.
  final int? statusCode;

  final Map<String, dynamic>? responseData;

  ApiException(dynamic message, {this.statusCode, this.responseData})
    : message = message?.toString() ?? '';

  @override
  String toString() => message;
}
