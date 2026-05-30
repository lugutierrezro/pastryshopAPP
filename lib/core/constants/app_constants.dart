// ============================================================
//  App Constants
// ============================================================
class AppConstants {
  // ---- API ----
  static const String baseUrl = 'http://127.0.0.1/pastryshop_api'; // Para Web/Desktop (fuerza IPv4)
  // Para emulador Android usa: 'http://10.0.2.2/pastryshop_api'
  // Para dispositivo físico en la misma red: 'http://192.168.1.x/pastryshop_api'

  static const String apiUrl = '$baseUrl';

  // ---- Storage keys ----
  static const String tokenKey    = 'auth_token';
  static const String userKey     = 'auth_user';

  // ---- Roles ----
  static const String roleCliente  = 'cliente';
  static const String roleEmpleado = 'empleado';
  static const String roleAdmin    = 'admin';

  // ---- Order states ----
  static const Map<String, String> orderStateLabels = {
    'pendiente':  'Pendiente',
    'preparando': 'Preparando',
    'listo':      'Listo para retirar',
    'entregado':  'Entregado',
    'cancelado':  'Cancelado',
  };
}
