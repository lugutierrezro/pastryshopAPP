import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:badges/badges.dart' as badges;
import 'package:pastryshop/core/theme/app_theme.dart';
import 'package:pastryshop/presentation/providers/auth_provider.dart';
import 'package:pastryshop/presentation/providers/notification_provider.dart';
import 'package:pastryshop/presentation/providers/order_provider.dart';

class AdminSidebar extends StatelessWidget {
  const AdminSidebar({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;
    
    final unreadCount = context.watch<NotificationProvider>().notifications.where((n) => !n.leida).length;
    final pendingCount = context.watch<OrderProvider>().orders.where((o) => o.estado == 'pendiente').length;

    if (user == null) return const SizedBox();

    return Drawer(
      backgroundColor: AppTheme.background,
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppTheme.adminPrimary, AppTheme.primary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.white24,
                    child: Text(
                      user.nombre.substring(0, 1).toUpperCase(),
                      style: const TextStyle(fontSize: 24, color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${user.nombre} ${user.apellido}',
                          style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          user.email,
                          style: const TextStyle(color: Colors.white70, fontSize: 14),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(10)),
                          child: Text(user.rol.toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                        )
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Menu Items
          Expanded(
            child: ListView(
              padding: const EdgeInsets.only(top: 10),
              children: [
                if (user.hasPermission('view_dashboard'))
                  _buildNavItem(context, Icons.dashboard, 'Dashboard', '/admin'),
                
                const Divider(height: 30),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Text('MÓDULOS', style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                ),

                if (user.hasPermission('manage_products') || user.hasPermission('manage_orders'))
                  _buildSubMenu(
                    title: 'Catálogo y Ventas',
                    icon: Icons.storefront,
                    children: [
                      if (user.hasPermission('manage_products')) _buildSubItem(context, 'Productos', '/admin/products'),
                      if (user.hasPermission('manage_orders')) _buildSubItem(context, 'Pedidos', '/admin/orders', badgeCount: pendingCount),
                    ],
                  ),

                if (user.hasPermission('manage_suppliers') || user.hasPermission('manage_purchases'))
                  _buildSubMenu(
                    title: 'Abastecimiento',
                    icon: Icons.inventory_2,
                    children: [
                      if (user.hasPermission('manage_suppliers')) _buildSubItem(context, 'Proveedores', '/admin/suppliers'),
                      if (user.hasPermission('manage_purchases')) _buildSubItem(context, 'Compras', '/admin/purchases'),
                    ],
                  ),

                if (user.hasPermission('manage_employees') || user.hasPermission('manage_users') || user.hasPermission('manage_roles'))
                  _buildSubMenu(
                    title: 'Recursos Humanos',
                    icon: Icons.people_alt,
                    children: [
                      if (user.hasPermission('manage_employees')) _buildSubItem(context, 'Perfiles', '/admin/employees'),
                      if (user.hasPermission('manage_users')) _buildSubItem(context, 'Usuarios', '/admin/users'),
                      if (user.hasPermission('manage_roles')) _buildSubItem(context, 'Roles y Permisos', '/admin/roles'),
                    ],
                  ),

                if (user.hasPermission('view_logs') || user.hasPermission('view_dashboard'))
                  _buildSubMenu(
                    title: 'Sistema',
                    icon: Icons.settings_system_daydream,
                    badgeCount: unreadCount,
                    children: [
                      if (user.hasPermission('view_logs')) _buildSubItem(context, 'Bitácora (Logs)', '/admin/logs'),
                      _buildSubItem(context, 'Notificaciones', '/admin/notifications', badgeCount: unreadCount),
                    ],
                  ),
              ],
            ),
          ),
          
          // Footer
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.redAccent),
            title: const Text('Cerrar Sesión', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
            onTap: () {
              auth.logout();
              context.go('/login');
            },
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildNavItem(BuildContext context, IconData icon, String title, String route) {
    final isActive = GoRouterState.of(context).matchedLocation == route;
    return ListTile(
      leading: Icon(icon, color: isActive ? AppTheme.adminPrimary : Colors.grey),
      title: Text(
        title,
        style: TextStyle(
          color: isActive ? AppTheme.adminPrimary : Colors.black87,
          fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      selected: isActive,
      selectedTileColor: AppTheme.adminPrimary.withOpacity(0.1),
      onTap: () {
        Navigator.pop(context); // Close drawer
        if (!isActive) context.push(route);
      },
    );
  }

  Widget _buildSubMenu({required String title, required IconData icon, required List<Widget> children, int badgeCount = 0}) {
    if (children.isEmpty) return const SizedBox();
    return ExpansionTile(
      leading: badgeCount > 0 
        ? badges.Badge(
            badgeContent: Text(badgeCount.toString(), style: const TextStyle(color: Colors.white, fontSize: 10)),
            child: Icon(icon, color: AppTheme.adminPrimary),
          )
        : Icon(icon, color: AppTheme.adminPrimary),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      childrenPadding: const EdgeInsets.only(left: 16),
      iconColor: AppTheme.adminPrimary,
      collapsedIconColor: Colors.grey,
      children: children,
    );
  }

  Widget _buildSubItem(BuildContext context, String title, String route, {int badgeCount = 0}) {
    final isActive = GoRouterState.of(context).matchedLocation == route;
    return ListTile(
      dense: true,
      leading: Icon(Icons.circle, size: 8, color: isActive ? AppTheme.adminPrimary : Colors.grey.shade400),
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              color: isActive ? AppTheme.adminPrimary : Colors.black87,
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          if (badgeCount > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(10)),
              child: Text(badgeCount.toString(), style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
            )
        ],
      ),
      onTap: () {
        Navigator.pop(context);
        if (!isActive) context.push(route);
      },
    );
  }
}
