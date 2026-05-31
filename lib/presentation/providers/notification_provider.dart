import 'package:flutter/foundation.dart';
import 'package:pastryshop/data/services/api_service.dart';
import 'package:pastryshop/domain/entities/entities.dart';
import 'package:pastryshop/core/constants/api_routes.dart';

class NotificationProvider extends ChangeNotifier {
  List<NotificationEntity> _notifications = [];
  bool _loading = false;
  String? _error;

  List<NotificationEntity> get notifications => _notifications;
  int get unreadCount => _notifications.where((n) => !n.leida).length;
  bool get loading => _loading;
  String? get error => _error;

  Future<void> loadNotifications() async {
    _loading = true; _error = null; notifyListeners();
    try {
      final res = await ApiService.get(ApiRoutes.notifications, auth: true);
      if (res['success'] == true) {
        _notifications = (res['data'] as List).map((e) => NotificationEntity.fromJson(e)).toList();
      } else {
        _error = res['message'];
      }
    } catch (e) {
      _error = 'Error al cargar notificaciones';
    } finally {
      _loading = false; notifyListeners();
    }
  }

  Future<bool> markAsRead(int id) async {
    try {
      final res = await ApiService.put(ApiRoutes.notificationRead('$id'), {}, auth: true);
      if (res['success'] == true) {
        final idx = _notifications.indexWhere((n) => n.id == id);
        if (idx != -1) {
          final old = _notifications[idx];
          _notifications[idx] = NotificationEntity(
            id: old.id, userId: old.userId, titulo: old.titulo,
            mensaje: old.mensaje, leida: true, tipo: old.tipo, createdAt: old.createdAt
          );
          notifyListeners();
        }
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }
}
