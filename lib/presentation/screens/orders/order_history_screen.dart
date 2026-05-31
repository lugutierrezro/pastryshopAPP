import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:pastryshop/core/theme/app_theme.dart';
import 'package:pastryshop/core/constants/app_constants.dart';
import 'package:pastryshop/presentation/providers/order_provider.dart';

// ============================================================
//  OrderHistoryScreen
// ============================================================
class OrderHistoryScreen extends StatefulWidget {
  const OrderHistoryScreen({super.key});
  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => context.read<OrderProvider>().fetchOrders(all: false));
  }

  @override
  Widget build(BuildContext context) {
    final op = context.watch<OrderProvider>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Pedidos'),
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios), onPressed: () => context.go('/')),
      ),
      body: op.loading
        ? const Center(child: CircularProgressIndicator())
        : op.orders.isEmpty
          ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Text('📦', style: TextStyle(fontSize: 56)),
              const SizedBox(height: 16),
              Text('No tienes pedidos aún', style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 24),
              ElevatedButton(onPressed: () => context.go('/'), child: const Text('Hacer mi primer pedido')),
            ]))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: op.orders.length,
              itemBuilder: (_, i) => _OrderTile(order: op.orders[i]),
            ),
    );
  }
}

class _OrderTile extends StatelessWidget {
  final order;
  const _OrderTile({required this.order});

  @override
  Widget build(BuildContext context) {
    final stateColor = _stateColor(order.estado);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => context.push('/orders/${order.id}'),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48, height: 48,
                decoration: BoxDecoration(color: stateColor.withOpacity(0.15), shape: BoxShape.circle),
                child: Icon(_stateIcon(order.estado), color: stateColor),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Pedido #${order.id}', style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 2),
                    Text(AppConstants.orderStateLabels[order.estado] ?? order.estado,
                      style: TextStyle(color: stateColor, fontWeight: FontWeight.w600, fontSize: 13)),
                    Text(order.createdAt, style: Theme.of(context).textTheme.bodyMedium),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('S/ ${order.total.toStringAsFixed(2)}',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppTheme.primary, fontWeight: FontWeight.bold)),
                  const Icon(Icons.chevron_right, color: AppTheme.textSecondary),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _stateColor(String estado) => switch(estado) {
    'pendiente'  => AppTheme.warning,
    'preparando' => AppTheme.info,
    'listo'      => AppTheme.empPrimary,
    'entregado'  => AppTheme.success,
    'cancelado'  => AppTheme.error,
    _            => AppTheme.textSecondary,
  };

  IconData _stateIcon(String estado) => switch(estado) {
    'pendiente'  => Icons.schedule,
    'preparando' => Icons.soup_kitchen,
    'listo'      => Icons.check_circle_outline,
    'entregado'  => Icons.done_all,
    'cancelado'  => Icons.cancel_outlined,
    _            => Icons.receipt_long,
  };
}
