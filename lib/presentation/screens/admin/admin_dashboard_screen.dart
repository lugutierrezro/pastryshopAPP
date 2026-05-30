import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:pastryshop/core/theme/app_theme.dart';
import 'package:pastryshop/presentation/providers/order_provider.dart';

// ============================================================
//  AdminDashboardScreen
// ============================================================
class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});
  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => context.read<OrderProvider>().fetchSummary());
  }

  @override
  Widget build(BuildContext context) {
    final op = context.watch<OrderProvider>();
    final summary = op.summary?['resumen'];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        backgroundColor: AppTheme.adminPrimary,
        foregroundColor: Colors.white,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios), onPressed: () => context.go('/')),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (summary != null) ...[
              const Text('Resumen General', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Row(
                children: [
                  _StatCard(title: 'Ventas', value: '\$${summary['ventas_totales'] ?? 0}', icon: Icons.attach_money, color: Colors.green),
                  const SizedBox(width: 16),
                  _StatCard(title: 'Pedidos', value: '${summary['total_pedidos'] ?? 0}', icon: Icons.shopping_bag, color: Colors.blue),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  _StatCard(title: 'Pendientes', value: '${summary['pendientes'] ?? 0}', icon: Icons.pending_actions, color: Colors.orange),
                  const SizedBox(width: 16),
                  _StatCard(title: 'Listos', value: '${summary['listos'] ?? 0}', icon: Icons.check_circle, color: Colors.purple),
                ],
              ),
            ],
            
            const SizedBox(height: 40),
            const Text('Gestión', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            
            _MenuTile(icon: Icons.cake, title: 'Productos', onTap: () => context.push('/admin/products')),
            _MenuTile(icon: Icons.receipt_long, title: 'Todos los Pedidos', onTap: () => context.push('/admin/orders')),
            _MenuTile(icon: Icons.people, title: 'Usuarios y Roles', onTap: () => context.push('/admin/users')),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title, value;
  final IconData icon;
  final Color color;
  const _StatCard({required this.title, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 4))],
          border: Border(left: BorderSide(color: color, width: 4)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 12),
            Text(title, style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  const _MenuTile({required this.icon, required this.title, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(icon, color: AppTheme.adminPrimary),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
