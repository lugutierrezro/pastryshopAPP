import 'package:flutter/material.dart';
import 'package:pastryshop/domain/entities/entities.dart';
import 'package:pastryshop/data/services/api_service.dart';
import 'package:pastryshop/core/constants/api_routes.dart';

class LogProvider with ChangeNotifier {
  List<LogEntity> _logs = [];
  bool _loading = false;
  String? _error;

  List<LogEntity> get logs => _logs;
  bool get loading => _loading;
  String? get error => _error;

  Future<void> loadLogs() async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final res = await ApiService.get(ApiRoutes.logs, auth: true);
      if (res['success'] == true) {
        _logs = (res['data'] as List).map((e) => LogEntity.fromJson(e)).toList();
      } else {
        _error = res['message'] ?? 'Error al cargar logs';
      }
    } catch (e) {
      _error = 'Error de conexión: $e';
    }

    _loading = false;
    notifyListeners();
  }
}
