import 'package:flutter/material.dart';
import 'package:pastryshop/core/constants/api_routes.dart';
import 'package:pastryshop/data/services/api_service.dart';

// ============================================================
//  ReviewEntity
// ============================================================
class ReviewEntity {
  final int id;
  final int userId;
  final int productId;
  final int calificacion;
  final String comentario;
  final String autor;
  final String? autorAvatar;
  final String createdAt;

  const ReviewEntity({
    required this.id, required this.userId, required this.productId,
    required this.calificacion, required this.comentario,
    required this.autor, this.autorAvatar, required this.createdAt,
  });

  factory ReviewEntity.fromJson(Map<String, dynamic> j) => ReviewEntity(
    id: j['id'] ?? 0, userId: j['user_id'] ?? 0, productId: j['product_id'] ?? 0,
    calificacion: j['calificacion'] ?? 0, comentario: j['comentario'] ?? '',
    autor: j['autor'] ?? 'Anónimo', autorAvatar: j['autor_avatar'],
    createdAt: j['created_at'] ?? '',
  );
}

// ============================================================
//  ReviewProvider
// ============================================================
class ReviewProvider extends ChangeNotifier {
  List<ReviewEntity> _reviews = [];
  double _promedio = 0.0;
  int    _total    = 0;
  bool   _loading  = false;
  String? _error;

  List<ReviewEntity> get reviews  => _reviews;
  double             get promedio => _promedio;
  int                get total    => _total;
  bool               get loading  => _loading;
  String?            get error    => _error;

  Future<void> fetchReviews(int productId) async {
    _loading = true; _error = null; notifyListeners();
    try {
      final res = await ApiService.get('${ApiRoutes.reviews}?product_id=$productId');
      if (res['success'] == true) {
        final data = res['data'] as Map<String, dynamic>;
        _reviews  = (data['reviews'] as List? ?? [])
            .map((e) => ReviewEntity.fromJson(e)).toList();
        _promedio = (data['promedio'] ?? 0.0).toDouble();
        _total    = data['total'] ?? 0;
      } else {
        _error = res['message'];
      }
    } catch (e) {
      _error = 'Error al cargar reseñas';
    } finally {
      _loading = false; notifyListeners();
    }
  }

  Future<bool> postReview({
    required int productId,
    required int calificacion,
    required String comentario,
  }) async {
    _loading = true; _error = null; notifyListeners();
    try {
      final res = await ApiService.post(ApiRoutes.reviews, {
        'product_id': productId,
        'calificacion': calificacion,
        'comentario': comentario,
      });
      if (res['success'] == true) {
        await fetchReviews(productId);
        return true;
      }
      _error = res['message'] ?? 'Error al publicar';
      return false;
    } catch (e) {
      _error = 'No se pudo conectar';
      return false;
    } finally {
      _loading = false; notifyListeners();
    }
  }

  Future<bool> deleteReview(int reviewId, int productId) async {
    try {
      final res = await ApiService.delete('${ApiRoutes.reviews}/$reviewId');
      if (res['success'] == true) {
        await fetchReviews(productId);
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  void clear() {
    _reviews = []; _promedio = 0.0; _total = 0;
    _error = null; _loading = false;
    notifyListeners();
  }
}
