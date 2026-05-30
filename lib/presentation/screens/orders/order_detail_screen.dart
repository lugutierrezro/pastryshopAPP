import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:pastryshop/core/theme/app_theme.dart';
import 'package:pastryshop/core/constants/app_constants.dart';
import 'package:pastryshop/presentation/providers/order_provider.dart';
import 'package:pastryshop/presentation/providers/auth_provider.dart';

// ============================================================
//  OrderDetailScreen
// ============================================================
class OrderDetailScreen extends StatefulWidget {
  final int id;
  const OrderDetailScreen({super.key, required this.id});
  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => context.read<OrderProvider>().fetchOrder(widget.id));
  }

  @override
  Widget build(BuildContext context) {
    final op   = context.watch<OrderProvider>();
    final auth = context.watch<AuthProvider>();
    
    return Scaffold(
      appBar: AppBar(
        title: Text('Pedido #${widget.id}'),
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios), onPressed: () => context.pop()),
      ),
      body: op.loading
        ? const Center(child: CircularProgressIndicator())
        : op.current == null
          ? const Center(child: Text('Pedido no encontrado'))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Header(order: op.current!),
                  const SizedBox(height: 24),
                  
                  Text('Artículos', style: Theme.of(context).textTheme.headlineMedium),
                  const SizedBox(height: 12),
                  ...op.current!.items.map((item) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(item.imagenUrl, width: 56, height: 56, fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(width: 56, height: 56, color: AppTheme.secondary)),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(item.producto, style: const TextStyle(fontWeight: FontWeight.w600)),
                              Text('\$${item.precioUnit.toStringAsFixed(2)} × ${item.cantidad}', style: const TextStyle(color: AppTheme.textSecondary)),
                            ],
                          ),
                        ),
                        Text('\$${item.subtotal.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                  )),
                  
                  const Divider(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total a pagar', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      Text('\$${op.current!.total.toStringAsFixed(2)}',
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.primary)),
                    ],
                  ),
                  const SizedBox(height: 32),
                  
                  // Acciones para admin/empleado
                  if (auth.isAdmin || auth.isEmpleado) _AdminActions(orderId: widget.id, currentStatus: op.current!.estado),
                ],
              ),
            ),
    );
  }
}

class _Header extends StatelessWidget {
  final order;
  const _Header({required this.order});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.cream,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Estado:', style: Theme.of(context).textTheme.bodyMedium),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: AppTheme.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                child: Text(AppConstants.orderStateLabels[order.estado] ?? order.estado,
                  style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text('Fecha: ${order.createdAt}'),
          Text('Entrega: ${order.tipoEntrega == 'domicilio' ? '🛵 Domicilio' : '🏪 En tienda'}'),
          if (order.tipoEntrega == 'domicilio' && order.direccionEntrega.isNotEmpty)
            Text('Dirección: ${order.direccionEntrega}'),
          if (order.notas.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text('Notas: ${order.notas}', style: const TextStyle(fontStyle: FontStyle.italic)),
            ),
        ],
      ),
    );
  }
}

class _AdminActions extends StatelessWidget {
  final int orderId;
  final String currentStatus;
  const _AdminActions({required this.orderId, required this.currentStatus});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Actualizar Estado (Staff)', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.adminPrimary)),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8, runSpacing: 8,
          children: ['pendiente', 'preparando', 'listo', 'entregado', 'cancelado'].map((st) {
            final isCurrent = currentStatus == st;
            return ActionChip(
              label: Text(AppConstants.orderStateLabels[st]!),
              backgroundColor: isCurrent ? AppTheme.adminPrimary : null,
              labelStyle: TextStyle(color: isCurrent ? Colors.white : Colors.black),
              onPressed: isCurrent ? null : () => _update(context, st),
            );
          }).toList(),
        ),
      ],
    );
  }
  
  void _update(BuildContext ctx, String st) async {
    final ok = await ctx.read<OrderProvider>().updateStatus(orderId, st);
    if (ok) {
      await ctx.read<OrderProvider>().fetchOrder(orderId);
      ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Estado actualizado')));
    }
  }
}
