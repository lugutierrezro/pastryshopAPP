import 'package:flutter/foundation.dart';
import 'package:pastryshop/data/services/api_service.dart';
import 'package:pastryshop/domain/entities/entities.dart';
import 'package:pastryshop/core/constants/api_routes.dart';

class RoleProvider extends ChangeNotifier {
  List<RoleEntity> _roles = [];
  bool _loading = false;
  String? _error;

  List<RoleEntity> get roles => _roles;
  bool get loading => _loading;
  String? get error => _error;

  Future<void> fetchRoles() async {
    _loading = true; notifyListeners();
    try {
      final res = await ApiService.get(ApiRoutes.roles, auth: true);
      if (res['success'] == true) {
        _roles = (res['data'] as List).map((e) => RoleEntity.fromJson(e)).toList();
        _error = null;
      } else {
        _error = res['message'];
      }
    } catch (e) {
      _error = 'Error al cargar roles';
    } finally {
      _loading = false; notifyListeners();
    }
  }

  Future<bool> createRole(String nombre, String descripcion, List<String> permisos) async {
    _loading = true; notifyListeners();
    final res = await ApiService.post(ApiRoutes.roles, {
      'nombre': nombre, 'descripcion': descripcion, 'permisos': permisos
    }, auth: true);
    _loading = false; notifyListeners();
    if (res['success'] == true) { await fetchRoles(); return true; }
    _error = res['message'];
    return false;
  }

  Future<bool> updateRole(int id, String nombre, String descripcion, List<String> permisos) async {
    _loading = true; notifyListeners();
    final res = await ApiService.put(ApiRoutes.role('$id'), {
      'nombre': nombre, 'descripcion': descripcion, 'permisos': permisos
    }, auth: true);
    _loading = false; notifyListeners();
    if (res['success'] == true) { await fetchRoles(); return true; }
    _error = res['message'];
    return false;
  }

  Future<bool> deleteRole(int id) async {
    _loading = true; notifyListeners();
    final res = await ApiService.delete(ApiRoutes.role('$id'), auth: true);
    _loading = false; notifyListeners();
    if (res['success'] == true) { await fetchRoles(); return true; }
    _error = res['message'];
    return false;
  }
}
