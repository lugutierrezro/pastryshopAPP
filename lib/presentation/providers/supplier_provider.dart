import 'package:flutter/foundation.dart';
import 'package:pastryshop/data/services/api_service.dart';
import 'package:pastryshop/domain/entities/entities.dart';
import 'package:pastryshop/core/constants/api_routes.dart';

class SupplierProvider extends ChangeNotifier {
  List<SupplierEntity> _suppliers = [];
  bool _loading = false;
  String? _error;

  List<SupplierEntity> get suppliers => _suppliers;
  bool get loading => _loading;
  String? get error => _error;

  Future<void> loadSuppliers() async {
    _loading = true; _error = null; notifyListeners();
    try {
      final res = await ApiService.get(ApiRoutes.suppliers, auth: true);
      if (res['success'] == true) {
        _suppliers = (res['data'] as List).map((e) => SupplierEntity.fromJson(e)).toList();
      } else {
        _error = res['message'];
      }
    } catch (e) {
      _error = 'Error al cargar proveedores';
    } finally {
      _loading = false; notifyListeners();
    }
  }

  Future<bool> createSupplier(Map<String, dynamic> data) async {
    _loading = true; notifyListeners();
    try {
      final res = await ApiService.post(ApiRoutes.suppliers, data, auth: true);
      if (res['success'] == true) {
        await loadSuppliers();
        return true;
      }
      _error = res['message'];
      return false;
    } catch (e) {
      _error = 'Error al crear proveedor';
      return false;
    } finally {
      _loading = false; notifyListeners();
    }
  }
  Future<bool> updateSupplier(int id, Map<String, dynamic> data) async {
    _loading = true; notifyListeners();
    try {
      final res = await ApiService.put(ApiRoutes.supplier('$id'), data, auth: true);
      if (res['success'] == true) {
        await loadSuppliers();
        return true;
      }
      _error = res['message'];
      return false;
    } catch (e) {
      _error = 'Error al actualizar proveedor';
      return false;
    } finally {
      _loading = false; notifyListeners();
    }
  }
}
