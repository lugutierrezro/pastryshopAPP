import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:pastryshop/core/theme/app_theme.dart';
import 'package:pastryshop/presentation/providers/order_provider.dart';

// ============================================================
//  AdminOrdersScreen
// ============================================================
class AdminOrdersScreen extends StatefulWidget {
  const AdminOrdersScreen({super.key});
  @override
  State<AdminOrdersScreen> createState() => _AdminOrdersScreenState();
}

class _AdminOrdersScreenState extends State<AdminOrdersScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => context.read<OrderProvider>().fetchOrders());
  }

  @override
  Widget build(BuildContext context) {
    final op = context.watch<OrderProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Todos los Pedidos'),
        backgroundColor: AppTheme.adminPrimary,
        foregroundColor: Colors.white,
      ),
      body: op.loading
        ? const Center(child: CircularProgressIndicator())
        : ListView.builder(
            itemCount: op.orders.length,
            itemBuilder: (_, i) {
              final o = op.orders[i];
              return ListTile(
                title: Text('Pedido #${o.id} - \$${o.total.toStringAsFixed(2)}'),
                subtitle: Text('${o.cliente ?? "Cliente"} - Estado: ${o.estado.toUpperCase()}'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push('/orders/${o.id}'),
              );
            },
          ),
    );
  }
}
