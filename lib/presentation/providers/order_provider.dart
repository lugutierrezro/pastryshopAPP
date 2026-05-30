import 'package:flutter/foundation.dart';
import 'package:pastryshop/data/services/api_service.dart';
import 'package:pastryshop/domain/entities/entities.dart';

// ============================================================
//  OrderProvider
// ============================================================
class OrderProvider extends ChangeNotifier {
  List<OrderEntity> _orders  = [];
  OrderEntity?      _current;
  Map<String, dynamic>? _summary;
  bool    _loading = false;
  String? _error;
  String? _message;

  List<OrderEntity>     get orders  => _orders;
  OrderEntity?          get current => _current;
  Map<String, dynamic>? get summary => _summary;
  bool                  get loading => _loading;
  String?               get error   => _error;
  String?               get message => _message;

  Future<void> fetchOrders({String? estado}) async {
    _loading = true; notifyListeners();
    try {
      final q = estado != null ? {'estado': estado} : null;
      final res = await ApiService.get('orders', auth: true, query: q);
      if (res['success'] == true) {
        _orders = (res['data'] as List).map((e) => OrderEntity.fromJson(e)).toList();
      }
    } catch (e) { _error = e.toString(); }
    finally { _loading = false; notifyListeners(); }
  }

  Future<void> fetchOrder(int id) async {
    _loading = true; notifyListeners();
    final res = await ApiService.get('orders/$id', auth: true);
    if (res['success'] == true) _current = OrderEntity.fromJson(res['data']);
    _loading = false; notifyListeners();
  }

  Future<bool> placeOrder({
    required String tipoEntrega,
    String? direccionEntrega,
    String? notas,
  }) async {
    _loading = true; _error = null; notifyListeners();
    try {
      final body = {
        'tipo_entrega': tipoEntrega,
        if (direccionEntrega != null) 'direccion_entrega': direccionEntrega,
        if (notas != null) 'notas': notas,
      };
      final res = await ApiService.post('orders', body, auth: true);
      if (res['success'] == true) {
        _message = res['message'];
        await fetchOrders();
        return true;
      }
      _error = res['message'];
      return false;
    } catch (e) {
      _error = 'Error al crear pedido';
      return false;
    } finally {
      _loading = false; notifyListeners();
    }
  }

  Future<bool> updateStatus(int orderId, String estado, {String? notas}) async {
    final res = await ApiService.put('orders/$orderId/status', {
      'estado': estado, if (notas != null) 'notas': notas,
    }, auth: true);
    if (res['success'] == true) { await fetchOrders(); return true; }
    return false;
  }

  Future<void> fetchSummary() async {
    final res = await ApiService.get('orders/summary', auth: true);
    if (res['success'] == true) { _summary = res['data']; notifyListeners(); }
  }
}
