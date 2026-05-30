import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pastryshop/core/constants/app_constants.dart';

// ============================================================
//  API Service — HTTP Client con JWT
// ============================================================
class ApiService {
  static const _timeout = Duration(seconds: 15);

  static Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(AppConstants.tokenKey);
  }

  static Future<Map<String, String>> _headers({bool auth = false}) async {
    final h = {'Content-Type': 'application/json', 'Accept': 'application/json'};
    if (auth) {
      final token = await _getToken();
      if (token != null) h['Authorization'] = 'Bearer $token';
    }
    return h;
  }

  // ---- GET ----
  static Future<Map<String, dynamic>> get(String path, {bool auth = false, Map<String, String>? query}) async {
    var uri = Uri.parse('${AppConstants.apiUrl}/$path');
    if (query != null) uri = uri.replace(queryParameters: query);
    final res = await http.get(uri, headers: await _headers(auth: auth)).timeout(_timeout);
    return _parse(res);
  }

  // ---- POST ----
  static Future<Map<String, dynamic>> post(String path, Map<String, dynamic> body, {bool auth = false}) async {
    final res = await http.post(
      Uri.parse('${AppConstants.apiUrl}/$path'),
      headers: await _headers(auth: auth),
      body: jsonEncode(body),
    ).timeout(_timeout);
    return _parse(res);
  }

  // ---- PUT ----
  static Future<Map<String, dynamic>> put(String path, Map<String, dynamic> body, {bool auth = false}) async {
    final res = await http.put(
      Uri.parse('${AppConstants.apiUrl}/$path'),
      headers: await _headers(auth: auth),
      body: jsonEncode(body),
    ).timeout(_timeout);
    return _parse(res);
  }

  // ---- DELETE ----
  static Future<Map<String, dynamic>> delete(String path, {bool auth = false}) async {
    final res = await http.delete(
      Uri.parse('${AppConstants.apiUrl}/$path'),
      headers: await _headers(auth: auth),
    ).timeout(_timeout);
    return _parse(res);
  }

  static Map<String, dynamic> _parse(http.Response res) {
    try {
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      data['_statusCode'] = res.statusCode;
      return data;
    } catch (_) {
      return {'success': false, 'message': 'Error de servidor', '_statusCode': res.statusCode};
    }
  }
}
