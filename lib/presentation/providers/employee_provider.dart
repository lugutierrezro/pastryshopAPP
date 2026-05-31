import 'package:flutter/foundation.dart';
import 'package:pastryshop/data/services/api_service.dart';
import 'package:pastryshop/domain/entities/entities.dart';
import 'package:pastryshop/core/constants/api_routes.dart';

class EmployeeProvider extends ChangeNotifier {
  List<EmployeeProfileEntity> _employees = [];
  bool _loading = false;
  String? _error;

  List<EmployeeProfileEntity> get employees => _employees;
  bool get loading => _loading;
  String? get error => _error;

  Future<void> loadEmployees() async {
    _loading = true; _error = null; notifyListeners();
    try {
      final res = await ApiService.get(ApiRoutes.employees, auth: true);
      if (res['success'] == true) {
        _employees = (res['data'] as List).map((e) => EmployeeProfileEntity.fromJson(e)).toList();
      } else {
        _error = res['message'];
      }
    } catch (e) {
      _error = 'Error al cargar empleados';
    } finally {
      _loading = false; notifyListeners();
    }
  }

  Future<bool> updateProfile(int userId, Map<String, dynamic> data) async {
    _loading = true; notifyListeners();
    try {
      final res = await ApiService.put(ApiRoutes.employee('$userId'), data, auth: true);
      if (res['success'] == true) {
        await loadEmployees();
        return true;
      }
      _error = res['message'];
      return false;
    } catch (e) {
      _error = 'Error al actualizar perfil de empleado';
      return false;
    } finally {
      _loading = false; notifyListeners();
    }
  }
}
