import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../response/service_response.dart';

abstract class BaseApiService {
  static const String baseUrl = 'https://goodlifesync.com/api';
  static const Duration timeout = Duration(seconds: 30);

  static String? _authToken;

  // Token'ı kaydet (SharedPreferences ile kalıcı)
  static Future<void> setAuthToken(String? token) async {
    _authToken = token;
    if (token != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', token);
    }
  }

  // Token'ı al (SharedPreferences'tan)
  static Future<String?> getAuthToken() async {
    if (_authToken != null) return _authToken;

    final prefs = await SharedPreferences.getInstance();
    _authToken = prefs.getString('auth_token');
    return _authToken;
  }

  // Token'ı temizle
  static Future<void> clearAuthToken() async {
    _authToken = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
  }

  // Base headers
  static Future<Map<String, String>> _getHeaders({
    bool requiresAuth = true,
    Map<String, String>? additionalHeaders,
  }) async {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (requiresAuth) {
      final token = await getAuthToken();
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }
    }

    if (additionalHeaders != null) {
      headers.addAll(additionalHeaders);
    }

    return headers;
  }

  // GET Request
  static Future<ServiceResponse<T>> get<T>(
      String endpoint, {
        Map<String, dynamic>? queryParameters,
        bool requiresAuth = true,
        T Function(dynamic)? fromJson,
      }) async {
    try {
      var uri = Uri.parse('$baseUrl$endpoint');

      if (queryParameters != null && queryParameters.isNotEmpty) {
        uri = uri.replace(
          queryParameters: queryParameters.map(
                (key, value) => MapEntry(key, value.toString()),
          ),
        );
      }

      final headers = await _getHeaders(requiresAuth: requiresAuth);

      final response = await http
          .get(
        uri,
        headers: headers,
      )
          .timeout(timeout);

      return _handleResponse<T>(response, fromJson);
    } on SocketException {
      return ServiceResponse.error(
        statusCode: 503,
        message: 'İnternet bağlantınızı kontrol edin',
      );
    } on TimeoutException {
      return ServiceResponse.error(
        statusCode: 408,
        message: 'İstek zaman aşımına uğradı',
      );
    } on http.ClientException {
      return ServiceResponse.error(
        statusCode: 500,
        message: 'Sunucuya bağlanılamadı',
      );
    } catch (e) {
      return ServiceResponse.error(
        statusCode: 500,
        message: 'Bir hata oluştu: ${e.toString()}',
      );
    }
  }

  // POST Request
  static Future<ServiceResponse<T>> post<T>(
      String endpoint, {
        Map<String, dynamic>? body,
        bool requiresAuth = true,
        T Function(dynamic)? fromJson,
      }) async {
    try {
      final uri = Uri.parse('$baseUrl$endpoint');
      final headers = await _getHeaders(requiresAuth: requiresAuth);

      final response = await http
          .post(
        uri,
        headers: headers,
        body: body != null ? json.encode(body) : null,
      )
          .timeout(timeout);

      return _handleResponse<T>(response, fromJson);
    } on SocketException {
      return ServiceResponse.error(
        statusCode: 503,
        message: 'İnternet bağlantınızı kontrol edin',
      );
    } on TimeoutException {
      return ServiceResponse.error(
        statusCode: 408,
        message: 'İstek zaman aşımına uğradı',
      );
    } on http.ClientException {
      return ServiceResponse.error(
        statusCode: 500,
        message: 'Sunucuya bağlanılamadı',
      );
    } catch (e) {
      return ServiceResponse.error(
        statusCode: 500,
        message: 'Bir hata oluştu: ${e.toString()}',
      );
    }
  }

  // PUT Request
  static Future<ServiceResponse<T>> put<T>(
      String endpoint, {
        Map<String, dynamic>? body,
        bool requiresAuth = true,
        T Function(dynamic)? fromJson,
      }) async {
    try {
      final uri = Uri.parse('$baseUrl$endpoint');
      final headers = await _getHeaders(requiresAuth: requiresAuth);

      final response = await http
          .put(
        uri,
        headers: headers,
        body: body != null ? json.encode(body) : null,
      )
          .timeout(timeout);

      return _handleResponse<T>(response, fromJson);
    } on SocketException {
      return ServiceResponse.error(
        statusCode: 503,
        message: 'İnternet bağlantınızı kontrol edin',
      );
    } on TimeoutException {
      return ServiceResponse.error(
        statusCode: 408,
        message: 'İstek zaman aşımına uğradı',
      );
    } on http.ClientException {
      return ServiceResponse.error(
        statusCode: 500,
        message: 'Sunucuya bağlanılamadı',
      );
    } catch (e) {
      return ServiceResponse.error(
        statusCode: 500,
        message: 'Bir hata oluştu: ${e.toString()}',
      );
    }
  }

  // DELETE Request
  static Future<ServiceResponse<T>> delete<T>(
      String endpoint, {
        Map<String, dynamic>? body,
        bool requiresAuth = true,
        T Function(dynamic)? fromJson,
      }) async {
    try {
      final uri = Uri.parse('$baseUrl$endpoint');
      final headers = await _getHeaders(requiresAuth: requiresAuth);

      final response = await http
          .delete(
        uri,
        headers: headers,
        body: body != null ? json.encode(body) : null,
      )
          .timeout(timeout);

      return _handleResponse<T>(response, fromJson);
    } on SocketException {
      return ServiceResponse.error(
        statusCode: 503,
        message: 'İnternet bağlantınızı kontrol edin',
      );
    } on TimeoutException {
      return ServiceResponse.error(
        statusCode: 408,
        message: 'İstek zaman aşımına uğradı',
      );
    } on http.ClientException {
      return ServiceResponse.error(
        statusCode: 500,
        message: 'Sunucuya bağlanılamadı',
      );
    } catch (e) {
      return ServiceResponse.error(
        statusCode: 500,
        message: 'Bir hata oluştu: ${e.toString()}',
      );
    }
  }

  // Multipart Request (File Upload)
  static Future<ServiceResponse<T>> uploadFile<T>(
      String endpoint, {
        required File file,
        required String fieldName,
        Map<String, String>? additionalFields,
        bool requiresAuth = true,
        T Function(dynamic)? fromJson,
      }) async {
    try {
      final uri = Uri.parse('$baseUrl$endpoint');
      final request = http.MultipartRequest('POST', uri);

      // Headers (multipart için Content-Type otomatik eklenir)
      final headers = await _getHeaders(requiresAuth: requiresAuth);
      headers.remove('Content-Type'); // Multipart için kaldır
      request.headers.addAll(headers);

      // File
      request.files.add(
        await http.MultipartFile.fromPath(fieldName, file.path),
      );

      // Additional fields
      if (additionalFields != null) {
        request.fields.addAll(additionalFields);
      }

      final streamedResponse = await request.send().timeout(timeout);
      final response = await http.Response.fromStream(streamedResponse);

      return _handleResponse<T>(response, fromJson);
    } on SocketException {
      return ServiceResponse.error(
        statusCode: 503,
        message: 'İnternet bağlantınızı kontrol edin',
      );
    } on TimeoutException {
      return ServiceResponse.error(
        statusCode: 408,
        message: 'İstek zaman aşımına uğradı',
      );
    } on http.ClientException {
      return ServiceResponse.error(
        statusCode: 500,
        message: 'Sunucuya bağlanılamadı',
      );
    } catch (e) {
      return ServiceResponse.error(
        statusCode: 500,
        message: 'Bir hata oluştu: ${e.toString()}',
      );
    }
  }

  // Response Handler
  static ServiceResponse<T> _handleResponse<T>(
      http.Response response,
      T Function(dynamic)? fromJson,
      ) {
    final statusCode = response.statusCode;

    try {
      final jsonResponse = json.decode(response.body) as Map<String, dynamic>;

      final message = jsonResponse['message'] as String?;
      final success = jsonResponse['success'] as bool?;

      if (statusCode >= 200 && statusCode < 300) {
        // Success
        if (fromJson != null) {
          final dataToPass = jsonResponse['data'];

          if (dataToPass != null) {
            return ServiceResponse<T>(
              statusCode: statusCode,
              data: fromJson(dataToPass),
              message: message,
            );
          } else {
            return ServiceResponse<T>(
              statusCode: statusCode,
              data: null,
              message: message,
            );
          }
        } else {
          return ServiceResponse<T>(
            statusCode: statusCode,
            data: jsonResponse['data'] as T?,
            message: message,
          );
        }
      } else {
        // Error
        return ServiceResponse.error(
          statusCode: statusCode,
          message: message ?? 'Bir hata oluştu',
          errors: jsonResponse['errors'] as Map<String, dynamic>?,
        );
      }
    } catch (e) {
      return ServiceResponse.error(
        statusCode: statusCode,
        message: response.body.isNotEmpty
            ? response.body
            : 'Beklenmeyen bir hata oluştu',
      );
    }
  }

  // Paginated GET Request
  static Future<ServiceResponse<PaginatedResponse<T>>> getPaginated<T>(
      String endpoint, {
        Map<String, dynamic>? queryParameters,
        bool requiresAuth = true,
        required T Function(Map<String, dynamic>) fromJson,
      }) async {
    try {
      var uri = Uri.parse('$baseUrl$endpoint');

      if (queryParameters != null && queryParameters.isNotEmpty) {
        uri = uri.replace(
          queryParameters: queryParameters.map(
                (key, value) => MapEntry(key, value.toString()),
          ),
        );
      }

      final headers = await _getHeaders(requiresAuth: requiresAuth);

      final response = await http
          .get(
        uri,
        headers: headers,
      )
          .timeout(timeout);

      final statusCode = response.statusCode;

      if (statusCode >= 200 && statusCode < 300) {
        final jsonResponse = json.decode(response.body) as Map<String, dynamic>;
        final paginatedData = PaginatedResponse<T>.fromJson(
          jsonResponse,
          fromJson,
        );

        return ServiceResponse.success(
          statusCode: statusCode,
          data: paginatedData,
          message: jsonResponse['message'] as String?,
        );
      } else {
        final jsonResponse = json.decode(response.body) as Map<String, dynamic>;
        return ServiceResponse.error(
          statusCode: statusCode,
          message: jsonResponse['message'] as String?,
          errors: jsonResponse['errors'] as Map<String, dynamic>?,
        );
      }
    } on SocketException {
      return ServiceResponse.error(
        statusCode: 503,
        message: 'İnternet bağlantınızı kontrol edin',
      );
    } on TimeoutException {
      return ServiceResponse.error(
        statusCode: 408,
        message: 'İstek zaman aşımına uğradı',
      );
    } catch (e) {
      return ServiceResponse.error(
        statusCode: 500,
        message: 'Bir hata oluştu: ${e.toString()}',
      );
    }
  }
}