import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:pastryshop/core/theme/app_theme.dart';
import 'package:pastryshop/presentation/providers/auth_provider.dart';

// ============================================================
//  ProfileScreen
// ============================================================
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    if (!auth.isLoggedIn) return const Scaffold();
    
    final u = auth.user!;
    
    return Scaffold(
      appBar: AppBar(title: const Text('Mi Perfil'), leading: IconButton(icon: const Icon(Icons.arrow_back_ios), onPressed: () => context.pop())),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const CircleAvatar(radius: 50, backgroundColor: AppTheme.primaryLight, child: Icon(Icons.person, size: 50, color: Colors.white)),
            const SizedBox(height: 16),
            Text(u.fullName, style: Theme.of(context).textTheme.headlineMedium),
            Text(u.email, style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppTheme.textSecondary)),
            const SizedBox(height: 32),
            
            _InfoTile(icon: Icons.phone, title: 'Teléfono', subtitle: u.telefono.isEmpty ? 'No especificado' : u.telefono),
            const Divider(),
            _InfoTile(icon: Icons.location_on, title: 'Dirección', subtitle: u.direccion.isEmpty ? 'No especificada' : u.direccion),
            const Divider(),
            _InfoTile(icon: Icons.badge, title: 'Tipo de cuenta', subtitle: u.rol.toUpperCase()),
            
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.logout, color: AppTheme.error),
                label: const Text('Cerrar sesión', style: TextStyle(color: AppTheme.error)),
                style: OutlinedButton.styleFrom(side: const BorderSide(color: AppTheme.error)),
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

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String title, subtitle;
  const _InfoTile({required this.icon, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) => ListTile(
    contentPadding: EdgeInsets.zero,
    leading: Icon(icon, color: AppTheme.primary),
    title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
    subtitle: Text(subtitle),
  );
}
