import 'package:flutter/foundation.dart';
import 'package:pastryshop/core/constants/api_routes.dart';
import 'package:pastryshop/data/services/api_service.dart';
import 'package:pastryshop/domain/entities/entities.dart';

class FavoriteProvider extends ChangeNotifier {
  List<ProductEntity> _favorites = [];
  bool _loading = false;
  String? _error;

  List<ProductEntity> get favorites => _favorites;
  bool get loading => _loading;
  String? get error => _error;

  Future<void> fetchFavorites() async {
    _loading = true; _error = null; notifyListeners();
    try {
      final res = await ApiService.get(ApiRoutes.favorites, auth: true);
      if (res['success'] == true) {
        _favorites = (res['data'] as List).map((e) => ProductEntity.fromJson(e)).toList();
      } else {
        _error = res['message'];
      }
    } catch (e) {
      _error = 'Error al cargar favoritos';
    } finally {
      _loading = false; notifyListeners();
    }
  }

  Future<bool> toggleFavorite(int productId) async {
    final isFav = isFavorite(productId);
    
    if (isFav) {
      final res = await ApiService.delete(ApiRoutes.favoriteItem(productId.toString()), auth: true);
      if (res['success'] == true) {
        _favorites.removeWhere((p) => p.id == productId);
        notifyListeners();
        return true;
      }
    } else {
      final res = await ApiService.post(ApiRoutes.favorites, {'product_id': productId}, auth: true);
      if (res['success'] == true) {
        await fetchFavorites(); // Refresh to get the full product details
        return true;
      }
    }
    return false;
  }

  bool isFavorite(int productId) {
    return _favorites.any((p) => p.id == productId);
  }
}
