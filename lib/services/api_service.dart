import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/api_config.dart';

class AuthException implements Exception {
  final String message;
  AuthException(this.message);
  @override
  String toString() => message;
}

class ApiService {
  static const _storage = FlutterSecureStorage();
  static const _tokenKey = 'jwt_token';

  // ── Auth ──────────────────────────────────────────────────
  static Future<String?> getToken() async => await _storage.read(key: _tokenKey);
  static Future<void> saveToken(String token) async => await _storage.write(key: _tokenKey, value: token);
  static Future<void> clearToken() async => await _storage.delete(key: _tokenKey);
  static Future<bool> hasToken() async => await getToken() != null;

  static Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/auth/login'),
      headers: ApiConfig.headers(null),
      body: jsonEncode({'email': email, 'password': password}),
    );

    final data = jsonDecode(response.body);
    if (response.statusCode == 200) {
      await saveToken(data['token']);
      return data;
    } else {
      throw AuthException(data['message'] ?? 'Login failed');
    }
  }

  static Future<Map<String, dynamic>> register(String name, String email, String password) async {
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/auth/register'),
      headers: ApiConfig.headers(null),
      body: jsonEncode({'name': name, 'email': email, 'password': password}),
    );

    final data = jsonDecode(response.body);
    if (response.statusCode == 201) {
      await saveToken(data['token']);
      return data;
    } else {
      throw AuthException(data['message'] ?? 'Registration failed');
    }
  }

  // ── Workers ───────────────────────────────────────────────
  static Future<List<dynamic>> getWorkers({String? search}) async {
    final token = await getToken();
    var url = '${ApiConfig.baseUrl}/workers';
    if (search != null && search.isNotEmpty) {
      url += '?search=$search';
    }
    
    final response = await http.get(
      Uri.parse(url),
      headers: ApiConfig.headers(token),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to fetch workers');
    }
  }

  static Future<Map<String, dynamic>> createWorker(Map<String, dynamic> data) async {
    final token = await getToken();
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/workers'),
      headers: ApiConfig.headers(token),
      body: jsonEncode(data),
    );

    if (response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? 'Failed to create worker');
    }
  }

  static Future<Map<String, dynamic>> updateWorker(String id, Map<String, dynamic> data) async {
    final token = await getToken();
    final response = await http.put(
      Uri.parse('${ApiConfig.baseUrl}/workers/$id'),
      headers: ApiConfig.headers(token),
      body: jsonEncode(data),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to update worker');
    }
  }

  static Future<bool> deleteWorker(String id) async {
    final token = await getToken();
    final response = await http.delete(
      Uri.parse('${ApiConfig.baseUrl}/workers/$id'),
      headers: ApiConfig.headers(token),
    );

    return response.statusCode == 200;
  }

  // ── Records ───────────────────────────────────────────────
  static Future<List<dynamic>> getRecords({String? workerId}) async {
    final token = await getToken();
    var url = '${ApiConfig.baseUrl}/records';
    if (workerId != null) {
      url += '?workerId=$workerId';
    }

    final response = await http.get(
      Uri.parse(url),
      headers: ApiConfig.headers(token),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to fetch records');
    }
  }

  static Future<Map<String, dynamic>> createRecord(Map<String, dynamic> data) async {
    final token = await getToken();
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/records'),
      headers: ApiConfig.headers(token),
      body: jsonEncode(data),
    );

    if (response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to create record');
    }
  }

  static Future<Uint8List> downloadExcel(String workerId) async {
    final token = await getToken();
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/records/export/$workerId'),
      headers: ApiConfig.headers(token),
    );

    if (response.statusCode == 200) {
      return response.bodyBytes;
    } else {
      throw Exception('Failed to download Excel');
    }
  }
}
