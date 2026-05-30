import 'package:flutter/foundation.dart';
import 'package:pastryshop/data/services/api_service.dart';
import 'package:pastryshop/domain/entities/entities.dart';

// ============================================================
//  CartProvider
// ============================================================
class CartProvider extends ChangeNotifier {
  List<CartItemEntity> _items = [];
  double _total = 0;
  bool   _loading = false;
  String? _error;

  List<CartItemEntity> get items   => _items;
  double               get total   => _total;
  bool                 get loading => _loading;
  String?              get error   => _error;
  int get itemCount => _items.fold(0, (s, i) => s + i.cantidad);
  bool get isEmpty  => _items.isEmpty;

  Future<void> fetchCart() async {
    _loading = true; notifyListeners();
    try {
      final res = await ApiService.get('cart', auth: true);
      if (res['success'] == true) {
        final data = res['data'] as Map<String, dynamic>;
        _items = (data['items'] as List).map((e) => CartItemEntity.fromJson(e)).toList();
        _total = (data['total'] ?? 0).toDouble();
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false; notifyListeners();
    }
  }

  Future<bool> addItem(int productId, int cantidad) async {
    try {
      final res = await ApiService.post('cart', {'product_id': productId, 'cantidad': cantidad}, auth: true);
      if (res['success'] == true) { await fetchCart(); return true; }
      _error = res['message'];
      notifyListeners();
      return false;
    } catch (_) { return false; }
  }

  Future<void> removeItem(int itemId) async {
    await ApiService.delete('cart/$itemId', auth: true);
    await fetchCart();
  }

  Future<void> clearCart() async {
    await ApiService.delete('cart', auth: true);
    _items = []; _total = 0; notifyListeners();
  }

  void clearLocal() {
    _items = []; _total = 0; notifyListeners();
  }
}
