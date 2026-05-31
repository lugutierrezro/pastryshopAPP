import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:pastryshop/core/theme/app_theme.dart';
import 'package:pastryshop/presentation/providers/auth_provider.dart';
import 'package:pastryshop/presentation/screens/profile/edit_profile_screen.dart';
import 'package:pastryshop/presentation/screens/profile/favorites_screen.dart';
import 'package:pastryshop/presentation/screens/orders/order_history_screen.dart';

// ============================================================
//  ProfileScreen (User Panel)
// ============================================================
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    if (!auth.isLoggedIn) return const Scaffold();
    
    final u = auth.user!;
    
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Panel de Usuario', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // User Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [AppTheme.primary, AppTheme.primaryLight]),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [BoxShadow(color: AppTheme.primary.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 5))],
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: Colors.white,
                    backgroundImage: (u.imagenUrl != null && u.imagenUrl!.isNotEmpty)
                        ? NetworkImage(u.imagenUrl!)
                        : null,
                    child: (u.imagenUrl == null || u.imagenUrl!.isEmpty)
                        ? const Icon(Icons.person, size: 40, color: AppTheme.primary)
                        : null,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(u.fullName, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text(u.email, style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 14)),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
                          child: Text(u.rol.toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            
            // Menu Items
            _MenuSection(title: 'Mi Cuenta', items: [
              _MenuItem(
                icon: Icons.person_outline,
                title: 'Mis Datos Personales',
                subtitle: 'Actualiza tu información y foto',
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EditProfileScreen())),
              ),
              _MenuItem(
                icon: Icons.shopping_bag_outlined,
                title: 'Mis Compras',
                subtitle: 'Historial y estado de tus pedidos',
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const OrderHistoryScreen())),
              ),
              _MenuItem(
                icon: Icons.favorite_outline,
                title: 'Favoritos',
                subtitle: 'Productos que te gustan',
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FavoritesScreen())),
              ),
            ]),
            
            const SizedBox(height: 24),
            
            _MenuSection(title: 'Preferencias', items: [
              _MenuItem(
                icon: Icons.settings_outlined,
                title: 'Configuración',
                subtitle: 'Notificaciones, tema y privacidad',
                onTap: () {
                  // TODO: Implement settings screen
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Configuración próximamente')));
                },
              ),
              _MenuItem(
                icon: Icons.help_outline,
                title: 'Ayuda y Soporte',
                subtitle: 'Preguntas frecuentes y contacto',
                onTap: () {},
              ),
            ]),

            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.logout, color: AppTheme.error),
                label: const Text('Cerrar sesión', style: TextStyle(color: AppTheme.error, fontSize: 16, fontWeight: FontWeight.bold)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppTheme.error),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: () {
                  auth.logout();
                  context.go('/');
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuSection extends StatelessWidget {
  final String title;
  final List<_MenuItem> items;

  const _MenuSection({required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8, bottom: 8),
          child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey)),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 5))],
          ),
          child: Column(
            children: items.asMap().entries.map((entry) {
              final isLast = entry.key == items.length - 1;
              return Column(
                children: [
                  entry.value,
                  if (!isLast) const Divider(height: 1, indent: 56),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _MenuItem({required this.icon, required this.title, required this.subtitle, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: AppTheme.primary.withOpacity(0.1), shape: BoxShape.circle),
        child: Icon(icon, color: AppTheme.primary),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
      onTap: onTap,
    );
  }
}

