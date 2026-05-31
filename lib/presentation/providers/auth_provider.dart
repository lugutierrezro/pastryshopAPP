import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:pastryshop/core/constants/app_constants.dart';
import 'package:pastryshop/data/services/api_service.dart';
import 'package:pastryshop/domain/entities/entities.dart';
import 'package:pastryshop/core/constants/api_routes.dart';

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
    try {
      await GoogleSignIn.instance.initialize();
    } catch (e) {
      if (kDebugMode) print('GoogleSignIn init error: $e');
    }
    
    final prefs = await SharedPreferences.getInstance();
    final tok   = prefs.getString(AppConstants.tokenKey);
    final usr   = prefs.getString(AppConstants.userKey);
    if (tok != null && usr != null) {
      _token = tok;
      _user  = UserEntity.fromJson(jsonDecode(usr));
      notifyListeners();
    }
  }

  Future<bool> signInWithGoogle() async {
    _loading = true; _error = null; notifyListeners();
    try {
      final account = await GoogleSignIn.instance.authenticate();
      
      final auth = await account.authentication;
      final body = {
        'token': auth.idToken ?? 'mock_token',
        'email': account.email,
        'nombre': account.displayName?.split(' ').first ?? 'Usuario',
        'apellido': account.displayName?.split(' ').skip(1).join(' ') ?? '',
        'provider_id': account.id,
      };

      final res = await ApiService.post(ApiRoutes.googleAuth, body);
      if (res['success'] == true) {
        _token = res['data']['token'];
        _user  = UserEntity.fromJson(res['data']['user']);
        await _persist();
        return true;
      }
      _error = res['message'] ?? 'Error al iniciar sesión con Google';
      return false;
    } catch (e) {
      if (e is GoogleSignInException && e.code == GoogleSignInExceptionCode.canceled) {
        _error = 'Autenticación cancelada';
      } else {
        _error = 'Error de conexión con Google: $e';
      }
      return false;
    } finally {
      _loading = false; notifyListeners();
    }
  }

  Future<bool> login(String email, String password) async {
    _loading = true; _error = null; notifyListeners();
    try {
      final res = await ApiService.post(ApiRoutes.login, {'email': email, 'password': password});
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
      final res = await ApiService.post(ApiRoutes.register, {
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

  Future<bool> updateProfile(Map<String, dynamic> data) async {
    _loading = true; _error = null; notifyListeners();
    try {
      final res = await ApiService.put(ApiRoutes.me, data, auth: true);
      if (res['success'] == true) {
        // Refresh user info
        final meRes = await ApiService.get(ApiRoutes.me, auth: true);
        if (meRes['success'] == true) {
          _user = UserEntity.fromJson(meRes['data']);
          await _persist();
          return true;
        }
      }
      _error = res['message'] ?? 'Error al actualizar perfil';
      return false;
    } catch (e) {
      _error = 'Error de conexión';
      return false;
    } finally {
      _loading = false; notifyListeners();
    }
  }

  Future<String?> uploadProfilePicture(String fileName, List<int> fileBytes) async {
    _loading = true; notifyListeners();
    try {
      final res = await ApiService.postMultipart(
        ApiRoutes.upload,
        fileField: 'image',
        fileName: fileName,
        fileBytes: fileBytes,
        auth: true,
      );
      if (res['success'] == true && res['data'] != null) {
        final imageUrl = res['data']['url'];
        // Now update the user profile with this URL
        await updateProfile({'imagen_url': imageUrl});
        return imageUrl;
      }
    } catch (e) {
      _error = 'Error al subir imagen';
    } finally {
      _loading = false; notifyListeners();
    }
    return null;
  }

  Future<void> refreshUser() async {
    final res = await ApiService.get(ApiRoutes.me, auth: true);
    if (res['success'] == true) {
      _user = UserEntity.fromJson(res['data']);
      await _persist();
      notifyListeners();
    }
  }
}
