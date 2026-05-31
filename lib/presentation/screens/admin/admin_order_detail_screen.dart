import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:pastryshop/core/theme/app_theme.dart';
import 'package:pastryshop/core/constants/app_constants.dart';
import 'package:pastryshop/presentation/providers/order_provider.dart';
import 'package:pastryshop/core/utils/toast_utils.dart';
import 'package:pastryshop/core/utils/pdf_invoice_generator.dart';

class AdminOrderDetailScreen extends StatefulWidget {
  final int id;
  const AdminOrderDetailScreen({super.key, required this.id});

  @override
  State<AdminOrderDetailScreen> createState() => _AdminOrderDetailScreenState();
}

class _AdminOrderDetailScreenState extends State<AdminOrderDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<OrderProvider>().fetchOrder(widget.id);
    });
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pendiente': return Colors.orange;
      case 'preparando': return Colors.blue;
      case 'listo': return Colors.purple;
      case 'entregado': return Colors.green;
      case 'cancelado': return Colors.red;
      default: return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'pendiente': return Icons.pending_actions;
      case 'preparando': return Icons.soup_kitchen;
      case 'listo': return Icons.room_service;
      case 'entregado': return Icons.check_circle;
      case 'cancelado': return Icons.cancel;
      default: return Icons.help_outline;
    }
  }

  String _getNextStatus(String current) {
    switch (current.toLowerCase()) {
      case 'pendiente': return 'preparando';
      case 'preparando': return 'listo';
      case 'listo': return 'entregado';
      default: return '';
    }
  }

  String _getActionText(String current) {
    switch (current.toLowerCase()) {
      case 'pendiente': return 'Iniciar Preparación';
      case 'preparando': return 'Marcar como Listo';
      case 'listo': return 'Entregar Pedido';
      default: return '';
    }
  }

  void _updateStatus(BuildContext context, int id, String status) async {
    final ok = await context.read<OrderProvider>().updateStatus(id, status);
    if (ok) {
      ToastUtils.showSuccess('Estado actualizado a ${status.toUpperCase()}');
      context.read<OrderProvider>().fetchOrder(id);
    } else {
      ToastUtils.showError('Error al actualizar el estado');
    }
  }

  @override
  Widget build(BuildContext context) {
    final op = context.watch<OrderProvider>();
    final order = op.current;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text('Pedido #${widget.id}'),
        backgroundColor: AppTheme.adminPrimary,
        foregroundColor: Colors.white,
        actions: [
          if (order != null)
            IconButton(
              icon: const Icon(Icons.print),
              tooltip: 'Ver Comprobante',
              onPressed: () {
                PdfInvoiceGenerator.generateAndShow(order);
              },
            ),
        ],
      ),
      body: op.loading
          ? const Center(child: CircularProgressIndicator())
          : order == null
              ? const Center(child: Text('Pedido no encontrado'))
              : _buildContent(context, order),
      bottomNavigationBar: order != null && _getNextStatus(order.estado).isNotEmpty
          ? Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))],
              ),
              child: ElevatedButton.icon(
                onPressed: () => _updateStatus(context, order.id, _getNextStatus(order.estado)),
                icon: const Icon(Icons.fast_forward, color: Colors.white),
                label: Text(_getActionText(order.estado), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _getStatusColor(order.estado),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildContent(BuildContext context, order) {
    final c = _getStatusColor(order.estado);
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Estado Actual', style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.bold)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(color: c.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                      child: Row(
                        children: [
                          Icon(_getStatusIcon(order.estado), color: c, size: 20),
                          const SizedBox(width: 8),
                          Text(order.estado.toUpperCase(), style: TextStyle(color: c, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ],
                ),
                const Divider(height: 30),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: AppTheme.primaryLight.withOpacity(0.2), shape: BoxShape.circle),
                      child: const Icon(Icons.person, color: AppTheme.primaryDark),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(order.cliente ?? 'Cliente', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                          Text(order.createdAt, style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                        ],
                      ),
                    ),
                  ],
                ),
                if (order.tipoEntrega == 'domicilio') ...[
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(16)),
                    child: Row(
                      children: [
                        const Icon(Icons.location_on, color: AppTheme.primary),
                        const SizedBox(width: 12),
                        Expanded(child: Text(order.direccionEntrega, style: const TextStyle(fontWeight: FontWeight.w500))),
                      ],
                    ),
                  ),
                ],
                if (order.notas.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.orange.shade200)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(children: [Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 18), SizedBox(width: 8), Text('Notas del cliente:', style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold))]),
                        const SizedBox(height: 8),
                        Text(order.notas, style: const TextStyle(color: Colors.black87)),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          
          const SizedBox(height: 30),
          const Text('Productos a Preparar', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          
          // Items
          ...order.items.map<Widget>((item) => Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 5)],
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(item.imagenUrl, width: 60, height: 60, fit: BoxFit.cover, errorBuilder: (_,__,___) => Container(width: 60, height: 60, color: Colors.grey.shade200, child: const Icon(Icons.cake, color: Colors.grey))),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item.producto, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          const SizedBox(height: 4),
                          Text('S/ ${item.precioUnit.toStringAsFixed(2)} c/u', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                          if (item.opcionesPersonalizadas != null && item.opcionesPersonalizadas!['notas'] != null) ...[
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(6)),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(Icons.edit_note, size: 14, color: Colors.orange),
                                  const SizedBox(width: 4),
                                  Expanded(child: Text(item.opcionesPersonalizadas!['notas'], style: const TextStyle(color: Colors.orange, fontSize: 12, fontStyle: FontStyle.italic))),
                                ],
                              ),
                            )
                          ],
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(color: AppTheme.primaryLight.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
                      child: Text('x${item.cantidad}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryDark, fontSize: 18)),
                    ),
                  ],
                ),
              )).toList(),
              
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: AppTheme.adminPrimary, borderRadius: BorderRadius.circular(20)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Total a Cobrar:', style: TextStyle(color: Colors.white, fontSize: 16)),
                Text('S/ ${order.total.toStringAsFixed(2)}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 24)),
              ],
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}
