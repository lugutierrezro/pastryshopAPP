import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:pastryshop/presentation/providers/auth_provider.dart';
import 'package:pastryshop/presentation/providers/supplier_provider.dart';
import 'package:pastryshop/domain/entities/entities.dart';
import 'package:pastryshop/presentation/screens/home/home_screen.dart';
import 'package:pastryshop/presentation/screens/auth/login_screen.dart';
import 'package:pastryshop/presentation/screens/auth/register_screen.dart';
import 'package:pastryshop/presentation/screens/products/product_detail_screen.dart';
import 'package:pastryshop/presentation/screens/cart/cart_screen.dart';
import 'package:pastryshop/presentation/screens/cart/checkout_screen.dart';
import 'package:pastryshop/presentation/screens/orders/custom_order_screen.dart';
import 'package:pastryshop/presentation/screens/orders/order_history_screen.dart';
import 'package:pastryshop/presentation/screens/orders/order_detail_screen.dart';
import 'package:pastryshop/presentation/screens/profile/profile_screen.dart';
import 'package:pastryshop/presentation/screens/profile/favorites_screen.dart';
import 'package:pastryshop/presentation/screens/layout/main_layout_screen.dart';
import 'package:pastryshop/presentation/screens/offers/offers_screen.dart';
import 'package:pastryshop/presentation/screens/admin/admin_dashboard_screen.dart';
import 'package:pastryshop/presentation/screens/admin/admin_categories_screen.dart';
import 'package:pastryshop/presentation/screens/admin/admin_category_form_screen.dart';
import 'package:pastryshop/presentation/screens/admin/admin_products_screen.dart';
import 'package:pastryshop/presentation/screens/admin/admin_users_screen.dart';
import 'package:pastryshop/presentation/screens/admin/admin_orders_screen.dart';
import 'package:pastryshop/presentation/screens/admin/admin_order_detail_screen.dart';
import 'package:pastryshop/presentation/screens/admin/admin_product_form_screen.dart';
import 'package:pastryshop/presentation/screens/admin/admin_product_detail_screen.dart';
import 'package:pastryshop/presentation/screens/admin/admin_suppliers_screen.dart';
import 'package:pastryshop/presentation/screens/admin/admin_supplier_form_screen.dart';
import 'package:pastryshop/presentation/screens/admin/admin_roles_screen.dart';
import 'package:pastryshop/presentation/screens/admin/admin_role_form_screen.dart';
import 'package:pastryshop/presentation/screens/admin/admin_purchases_screen.dart';
import 'package:pastryshop/presentation/screens/admin/admin_employees_screen.dart';
import 'package:pastryshop/presentation/screens/admin/admin_logs_screen.dart';
import 'package:pastryshop/presentation/screens/admin/admin_notifications_screen.dart';
import 'package:pastryshop/presentation/screens/employee/employee_dashboard_screen.dart';

// ============================================================
//  App Router — GoRouter with role-based redirects
// ============================================================
class AppRouter {
  static GoRouter router(AuthProvider auth) => GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      final loggedIn = auth.isLoggedIn;
      final path     = state.matchedLocation;

      // Admin area guard
      if (path.startsWith('/admin') && !auth.isAdmin) return '/';
      // Employee area guard
      if (path.startsWith('/employee') && !(auth.isEmpleado || auth.isAdmin)) return '/';
      // Profile/orders guard
      if ((path.startsWith('/orders') || path.startsWith('/profile')) && !loggedIn) return '/login';

      return null;
    },
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return MainLayoutScreen(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(routes: [GoRoute(path: '/', builder: (_, __) => const HomeScreen())]),
          StatefulShellBranch(routes: [GoRoute(path: '/offers', builder: (_, __) => const OffersScreen())]),
          StatefulShellBranch(routes: [GoRoute(path: '/favorites', builder: (_, __) => const FavoritesScreen())]),
          StatefulShellBranch(routes: [GoRoute(path: '/profile', builder: (_, __) => const ProfileScreen())]),
        ],
      ),
      GoRoute(path: '/login',        builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/register',     builder: (_, __) => const RegisterScreen()),
      GoRoute(path: '/product/:id',  builder: (_, s) => ProductDetailScreen(id: int.parse(s.pathParameters['id']!))),
      GoRoute(path: '/cart',         builder: (_, __) => const CartScreen()),
      GoRoute(path: '/checkout',     builder: (_, __) => const CheckoutScreen()),
      GoRoute(path: '/custom-order', builder: (_, __) => const CustomOrderScreen()),
      GoRoute(path: '/orders',       builder: (_, __) => const OrderHistoryScreen()),
      GoRoute(path: '/orders/:id',   builder: (_, s) => OrderDetailScreen(id: int.parse(s.pathParameters['id']!))),
      // Admin
      GoRoute(path: '/admin',          builder: (_, __) => const AdminDashboardScreen()),
      GoRoute(path: '/admin/products', builder: (_, __) => const AdminProductsScreen()),
      GoRoute(
        path: '/admin/product-form',
        builder: (_, s) => AdminProductFormScreen(product: s.extra as ProductEntity?),
      ),
      GoRoute(
        path: '/admin/product-detail',
        builder: (_, s) => AdminProductDetailScreen(product: s.extra as ProductEntity),
      ),
      GoRoute(path: '/admin/users',    builder: (_, __) => const AdminUsersScreen()),
      GoRoute(path: '/admin/orders',   builder: (_, __) => const AdminOrdersScreen()),
      GoRoute(
        path: '/admin/orders/:id',
        builder: (_, s) => AdminOrderDetailScreen(id: int.parse(s.pathParameters['id']!)),
      ),
      GoRoute(path: '/admin/suppliers', builder: (_, __) => const AdminSuppliersScreen()),
      GoRoute(path: '/admin/suppliers/new', builder: (_, __) => const AdminSupplierFormScreen()),
      GoRoute(
        path: '/admin/suppliers/:id',
        builder: (ctx, state) {
          final id = int.tryParse(state.pathParameters['id'] ?? '');
          if (id == null) return const AdminSuppliersScreen();
          final s = ctx.read<SupplierProvider>().suppliers.cast<SupplierEntity?>().firstWhere((e) => e?.id == id, orElse: () => null);
          return AdminSupplierFormScreen(supplier: s);
        },
      ),
      GoRoute(path: '/admin/categories', builder: (_, __) => const AdminCategoriesScreen()),
      GoRoute(path: '/admin/categories/new', builder: (_, __) => const AdminCategoryFormScreen()),
      GoRoute(
        path: '/admin/categories/:id',
        builder: (_, s) => AdminCategoryFormScreen(category: s.extra as CategoryEntity?),
      ),
      GoRoute(path: '/admin/purchases', builder: (_, __) => const AdminPurchasesScreen()),
      GoRoute(path: '/admin/roles', builder: (_, __) => const AdminRolesScreen()),
      GoRoute(
        path: '/admin/role-form',
        builder: (_, s) => AdminRoleFormScreen(role: s.extra as dynamic),
      ),
      GoRoute(path: '/admin/employees', builder: (_, __) => const AdminEmployeesScreen()),
      GoRoute(path: '/admin/logs',      builder: (_, __) => const AdminLogsScreen()),
      GoRoute(path: '/admin/notifications', builder: (_, __) => const AdminNotificationsScreen()),
      // Employee
      GoRoute(path: '/employee', builder: (_, __) => const EmployeeDashboardScreen()),
    ],
  );
}
