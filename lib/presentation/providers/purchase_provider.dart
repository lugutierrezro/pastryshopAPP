import 'package:flutter/foundation.dart';
import 'package:pastryshop/data/services/api_service.dart';
import 'package:pastryshop/domain/entities/entities.dart';
import 'package:pastryshop/core/constants/api_routes.dart';

class PurchaseProvider extends ChangeNotifier {
  List<PurchaseEntity> _purchases = [];
  bool _loading = false;
  String? _error;

  List<PurchaseEntity> get purchases => _purchases;
  bool get loading => _loading;
  String? get error => _error;

  Future<void> loadPurchases() async {
    _loading = true; _error = null; notifyListeners();
    try {
      final res = await ApiService.get(ApiRoutes.purchases, auth: true);
      if (res['success'] == true) {
        _purchases = (res['data'] as List).map((e) => PurchaseEntity.fromJson(e)).toList();
      } else {
        _error = res['message'];
      }
    } catch (e) {
      _error = 'Error al cargar compras';
    } finally {
      _loading = false; notifyListeners();
    }
  }

  Future<bool> registerPurchase(Map<String, dynamic> data) async {
    _loading = true; notifyListeners();
    try {
      final res = await ApiService.post(ApiRoutes.purchases, data, auth: true);
      if (res['success'] == true) {
        await loadPurchases();
        return true;
      }
      _error = res['message'];
      return false;
    } catch (e) {
      _error = 'Error al registrar compra';
      return false;
    } finally {
      _loading = false; notifyListeners();
    }
  }
}
