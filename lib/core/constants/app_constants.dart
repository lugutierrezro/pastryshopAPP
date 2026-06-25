// ============================================================
//  App Constants
// ============================================================
class AppConstants {
  // ---- API ----
  static const String baseUrl = 'https://pang-reprogram-pyramid.ngrok-free.dev/pastryshop_api';
  // Para emulador Android usa: 'http://10.0.2.2/pastryshop_api'
  // Para dispositivo físico en la misma red: 'http://192.168.1.x/pastryshop_api'

  static const String apiUrl = '$baseUrl';

  // ---- Google Sign-In ----
  // Coloca tu "Web Client ID" (Client ID de tipo 3 de Firebase/Google Cloud Console) aquí:
  static const String? googleServerClientId = '989250255492-ntij8tr004o3dd767cmm2ff97uc2st3b.apps.googleusercontent.com';

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
