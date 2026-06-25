class ApiRoutes {
  // Auth
  static const String login       = 'auth/login';
  static const String register    = 'auth/register';
  static const String googleAuth  = 'auth/google';
  static const String me          = 'auth/me';
  static const String verifyEmail = 'auth/verify-email';
  static const String resendCode  = 'auth/resend-code';

  // Users
  static const String users = 'users';
  static String user(String id) => 'users/$id';

  // Suppliers
  static const String suppliers = 'suppliers';
  static String supplier(String id) => 'suppliers/$id';

  // Roles
  static const String roles = 'roles';
  static String role(String id) => 'roles/$id';

  // Purchases
  static const String purchases = 'purchases';

  // Categories
  static const String categories = 'categories';
  static String category(String id) => 'categories/$id';

  // Products
  static const String products = 'products';
  static String product(String id) => 'products/$id';
  static const String upload = 'upload';

  // Orders
  static const String orders = 'orders';
  static String order(String id) => 'orders/$id';
  static String orderStatus(String id) => 'orders/$id/status';
  static const String orderSummary = 'orders/summary';

  // Notifications
  static const String notifications = 'notifications';
  static String notificationRead(String id) => 'notifications/$id/read';

  // Logs
  static const String logs = 'logs';

  // Employees
  static const String employees = 'employees';
  static String employee(String id) => 'employees/$id';

  // Cart
  static const String cart = 'cart';
  static String cartItem(String id) => 'cart/$id';

  // Favorites
  static const String favorites = 'favorites';
  static String favoriteItem(String id) => 'favorites/$id';

  // Reviews
  static const String reviews = 'reviews';
  static String review(String id) => 'reviews/$id';
}
