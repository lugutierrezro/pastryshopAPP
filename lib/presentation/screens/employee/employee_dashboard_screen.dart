import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:pastryshop/core/theme/app_theme.dart';
import 'package:pastryshop/presentation/providers/order_provider.dart';

// ============================================================
//  EmployeeDashboardScreen
// ============================================================
class EmployeeDashboardScreen extends StatefulWidget {
  const EmployeeDashboardScreen({super.key});
  @override
  State<EmployeeDashboardScreen> createState() => _EmployeeDashboardScreenState();
}

class _EmployeeDashboardScreenState extends State<EmployeeDashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => context.read<OrderProvider>().fetchOrders(all: true));
  }

  @override
  Widget build(BuildContext context) {
    final op = context.watch<OrderProvider>();
    // Filtrar solo los relevantes para cocina/entrega
    final activeOrders = op.orders.where((o) => ['pendiente', 'preparando', 'listo'].contains(o.estado)).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel de Empleado'),
        backgroundColor: AppTheme.empPrimary,
        foregroundColor: Colors.white,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios), onPressed: () => context.go('/')),
      ),
      body: op.loading
        ? const Center(child: CircularProgressIndicator())
        : activeOrders.isEmpty
          ? const Center(child: Text('No hay pedidos activos', style: TextStyle(fontSize: 18)))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: activeOrders.length,
              itemBuilder: (_, i) {
                final o = activeOrders[i];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    title: Text('Pedido #${o.id} - ${o.cliente ?? "Cliente"}', style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(o.createdAt),
                        Text('Entrega: ${o.tipoEntrega}'),
                        if (o.notas.isNotEmpty) Text('Notas: ${o.notas}', style: const TextStyle(color: AppTheme.error)),
                      ],
                    ),
                    trailing: _StatusBadge(status: o.estado),
                    onTap: () => context.push('/admin/orders/${o.id}'),
                  ),
                );
              },
            ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color c = AppTheme.textSecondary;
    if (status == 'pendiente') c = AppTheme.warning;
    if (status == 'preparando') c = AppTheme.info;
    if (status == 'listo') c = AppTheme.empPrimary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: c.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
      child: Text(status.toUpperCase(), style: TextStyle(color: c, fontWeight: FontWeight.bold, fontSize: 12)),
    );
  }
}
