import 'dart:io';
import 'package:dio/dio.dart';
import 'package:curl_logger_dio_interceptor/curl_logger_dio_interceptor.dart';
import 'package:hyper_local_seller/service/security.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';

class ApiBaseHelper {
  final Dio _dio = Dio();

  ApiBaseHelper() {
    // In ApiBaseHelper constructor
    // _dio.interceptors.add(CurlLoggerDioInterceptor(printOnSuccess: true));

    // _dio.interceptors.add(
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
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final headers = await Security.headers;
          options.headers.addAll(headers);
          return handler.next(options);
        },
        onError: (DioException e, handler) {
          return handler.next(e);
        },
      ),
    );
  }

  Future<dynamic> post(String url, Map<String, dynamic> body) async {
    try {
      final response = await _dio.post(url, data: body);
      return _returnResponse(response);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<dynamic> get(
    String url, {
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      final response = await _dio.get(url, queryParameters: queryParameters);
      return _returnResponse(response);
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

  dynamic _returnResponse(Response response) {
    switch (response.statusCode) {
      case 200:
      case 201:
        final responseBody = response.data;
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
            throw Exception(message);
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
            return Exception(data['message']);
          }

          // If multiple errors, show all detailed errors
          return Exception(errorMessages.join('\n'));
        }

        // Handle other errors with message
        if (data.containsKey('message')) {
          return Exception(data['message']); // Return backend message
        }
      }
      return Exception("${error.response?.statusMessage}");
    } else {
      switch (error.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          return Exception("Connection timeout");
        case DioExceptionType.unknown:
          if (error.error is SocketException) {
            return Exception("No Internet Connection");
          }
          return Exception("Unexpected error occurred");
        default:
          return Exception("Something went wrong");
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
