import 'package:flutter/foundation.dart';
import 'package:pastryshop/data/services/api_service.dart';
import 'package:pastryshop/domain/entities/entities.dart';

// ============================================================
//  ProductProvider
// ============================================================
class ProductProvider extends ChangeNotifier {
  List<ProductEntity>   _products   = [];
  List<CategoryEntity>  _categories = [];
  List<ProductEntity>   _featured   = [];
  ProductEntity?        _selected;
  bool    _loading = false;
  String? _error;
  int?    _selectedCategory;
  String  _search = '';

  List<ProductEntity>  get products   => _products;
  List<CategoryEntity> get categories => _categories;
  List<ProductEntity>  get featured   => _featured;
  ProductEntity?       get selected   => _selected;
  bool                 get loading    => _loading;
  String?              get error      => _error;
  int?                 get selectedCategory => _selectedCategory;

  Future<void> fetchCategories() async {
    try {
      final res = await ApiService.get('categories');
      if (res['success'] == true) {
        _categories = (res['data'] as List).map((e) => CategoryEntity.fromJson(e)).toList();
        notifyListeners();
      }
    } catch (e, stack) {
      print('FETCH CATEGORIES ERROR: \$e\\n\$stack');
    }
  }

  Future<void> fetchProducts({int? categoryId, String? search, bool featured = false}) async {
    _loading = true; _error = null; notifyListeners();
    try {
      final query = <String, String>{};
      if (categoryId != null) query['category_id'] = categoryId.toString();
      if (search != null && search.isNotEmpty) query['search'] = search;
      if (featured) query['featured'] = '1';
      final res = await ApiService.get('products', query: query.isEmpty ? null : query);
      if (res['success'] == true) {
        final list = (res['data'] as List).map((e) => ProductEntity.fromJson(e)).toList();
        if (featured) { _featured = list; } else { _products = list; }
      }
    } catch (e, stack) {
      _error = e.toString();
      print('FETCH PRODUCTS ERROR: \$e\\n\$stack');
    } finally {
      _loading = false; notifyListeners();
    }
  }

  Future<void> fetchProduct(int id) async {
    _loading = true; notifyListeners();
    final res = await ApiService.get('products/$id');
    if (res['success'] == true) _selected = ProductEntity.fromJson(res['data']);
    _loading = false; notifyListeners();
  }

  void setCategory(int? catId) {
    _selectedCategory = catId;
    fetchProducts(categoryId: catId, search: _search.isEmpty ? null : _search);
  }

  void setSearch(String q) {
    _search = q;
    fetchProducts(categoryId: _selectedCategory, search: q.isEmpty ? null : q);
  }

  // Admin
  Future<bool> createProduct(Map<String, dynamic> data) async {
    final res = await ApiService.post('products', data, auth: true);
    if (res['success'] == true) { await fetchProducts(); return true; }
    return false;
  }

  Future<bool> updateProduct(int id, Map<String, dynamic> data) async {
    final res = await ApiService.put('products/$id', data, auth: true);
    if (res['success'] == true) { await fetchProducts(); return true; }
    return false;
  }

  Future<bool> deleteProduct(int id) async {
    final res = await ApiService.delete('products/$id', auth: true);
    if (res['success'] == true) { await fetchProducts(); return true; }
    return false;
  }
}
