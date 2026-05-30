import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pastryshop/core/constants/app_constants.dart';
import 'package:pastryshop/data/services/api_service.dart';
import 'package:pastryshop/domain/entities/entities.dart';

// ============================================================
//  AuthProvider
// ============================================================
class AuthProvider extends ChangeNotifier {
  UserEntity? _user;
  String?     _token;
  bool        _loading = false;
  String?     _error;

  UserEntity? get user    => _user;
  String?     get token   => _token;
  bool        get loading => _loading;
  String?     get error   => _error;
  bool        get isLoggedIn => _user != null;
  bool        get isAdmin    => _user?.isAdmin  ?? false;
  bool        get isEmpleado => _user?.isEmpleado ?? false;
  bool        get isCliente  => _user?.isCliente ?? false;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final tok   = prefs.getString(AppConstants.tokenKey);
    final usr   = prefs.getString(AppConstants.userKey);
    if (tok != null && usr != null) {
      _token = tok;
      _user  = UserEntity.fromJson(jsonDecode(usr));
      notifyListeners();
    }
  }

  Future<bool> login(String email, String password) async {
    _loading = true; _error = null; notifyListeners();
    try {
      final res = await ApiService.post('auth/login', {'email': email, 'password': password});
      if (res['success'] == true) {
        _token = res['data']['token'];
        _user  = UserEntity.fromJson(res['data']['user']);
        await _persist();
        return true;
      }
      _error = res['message'] ?? 'Error al iniciar sesión';
      return false;
    } catch (e) {
      _error = 'No se pudo conectar al servidor';
      return false;
    } finally {
      _loading = false; notifyListeners();
    }
  }

  Future<bool> register({
    required String nombre, required String apellido,
    required String email,  required String password,
    String telefono = '',   String direccion = '',
  }) async {
    _loading = true; _error = null; notifyListeners();
    try {
      final res = await ApiService.post('auth/register', {
        'nombre': nombre, 'apellido': apellido, 'email': email,
        'password': password, 'telefono': telefono, 'direccion': direccion,
      });
      if (res['success'] == true) {
        _token = res['data']['token'];
        _user  = UserEntity.fromJson(res['data']['user']);
        await _persist();
        return true;
      }
      _error = res['message'] ?? 'Error al registrarse';
      return false;
    } catch (e) {
      _error = 'No se pudo conectar al servidor';
      return false;
    } finally {
      _loading = false; notifyListeners();
    }
  }

  Future<void> logout() async {
    _user = null; _token = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.tokenKey);
    await prefs.remove(AppConstants.userKey);
    notifyListeners();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.tokenKey, _token!);
    await prefs.setString(AppConstants.userKey, jsonEncode(_user!.toJson()));
  }
}
