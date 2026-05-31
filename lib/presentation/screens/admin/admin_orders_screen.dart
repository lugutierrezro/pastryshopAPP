import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:pastryshop/core/theme/app_theme.dart';
import 'package:pastryshop/presentation/providers/order_provider.dart';
import 'package:pastryshop/domain/entities/entities.dart';
import 'package:pastryshop/presentation/widgets/admin/admin_sidebar.dart';
import 'package:pastryshop/presentation/widgets/shared/shimmer_loading.dart';
import 'package:pastryshop/core/utils/toast_utils.dart';
import 'package:intl/intl.dart';

class AdminOrdersScreen extends StatefulWidget {
  const AdminOrdersScreen({super.key});
  @override
  State<AdminOrdersScreen> createState() => _AdminOrdersScreenState();
}

class _AdminOrdersScreenState extends State<AdminOrdersScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<String> _statuses = ['Todos', 'pendiente', 'preparando', 'listo', 'entregado', 'cancelado'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _statuses.length, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<OrderProvider>().fetchOrders(all: true);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final op = context.watch<OrderProvider>();
    final pendingCount = op.orders.where((o) => o.estado == 'pendiente').length;

    return Scaffold(
      backgroundColor: AppTheme.background,
      drawer: const AdminSidebar(),
      appBar: AppBar(
        title: const Text('Gestión de Pedidos', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [AppTheme.adminPrimary, AppTheme.primary],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: AppTheme.accent,
          indicatorWeight: 4,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          tabs: _statuses.map((s) {
            if (s == 'pendiente' && pendingCount > 0) {
              return Tab(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(s.toUpperCase()),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                      child: Text('$pendingCount', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                    )
                  ],
                ),
              );
            }
            return Tab(text: s.toUpperCase());
          }).toList(),
        ),
      ),
      body: op.loading
          ? const ShimmerListLoading()
          : Column(
              children: [
                // Quick Summary Banner
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 5))],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildSummaryStat('Total Pedidos', op.orders.length.toString(), Icons.receipt_long, Colors.blue),
                      _buildSummaryStat('Pendientes', pendingCount.toString(), Icons.pending_actions, Colors.orange),
                      _buildSummaryStat('Entregados', op.orders.where((o) => o.estado == 'entregado').length.toString(), Icons.check_circle, Colors.green),
                    ],
                  ),
                ),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: _statuses.map((status) {
                      final filtered = status == 'Todos' 
                          ? op.orders 
                          : op.orders.where((o) => o.estado.toLowerCase() == status).toList();
                      
                      if (filtered.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(30),
                                decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20)]),
                                child: Icon(Icons.inbox_outlined, size: 80, color: Colors.grey.shade300),
                              ),
                              const SizedBox(height: 24),
                              Text('No hay pedidos', style: TextStyle(color: Colors.grey.shade600, fontSize: 22, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 8),
                              Text('En estado "${status.toUpperCase()}"', style: TextStyle(color: Colors.grey.shade400, fontSize: 16)),
                            ],
                          ),
                        );
                      }

                      return ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: filtered.length,
                        itemBuilder: (ctx, i) => _OrderCard(order: filtered[i]),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildSummaryStat(String label, String value, IconData icon, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
          child: Icon(icon, color: color, size: 28),
        ),
        const SizedBox(height: 8),
        Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.bold)),
      ],
    );
  }
}

class _OrderCard extends StatelessWidget {
  final OrderEntity order;
  const _OrderCard({required this.order});

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

  double _getStatusProgress(String status) {
    switch (status.toLowerCase()) {
      case 'pendiente': return 0.25;
      case 'preparando': return 0.50;
      case 'listo': return 0.75;
      case 'entregado': return 1.0;
      case 'cancelado': return 1.0;
      default: return 0.0;
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

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(order.estado);
    final progress = _getStatusProgress(order.estado);
    final nextStatus = _getNextStatus(order.estado);
    final isCancelled = order.estado.toLowerCase() == 'cancelado';

    return Card(
      margin: const EdgeInsets.only(bottom: 20),
      elevation: 8,
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push('/admin/orders/${order.id}'),
        child: Column(
          children: [
            // Header Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                border: Border(bottom: BorderSide(color: statusColor.withOpacity(0.2), width: 1)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: statusColor.withOpacity(0.2), blurRadius: 5)]),
                        child: Text('#${order.id}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: statusColor)),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(order.createdAt, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          Text('Fecha', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                        ],
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(color: statusColor, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: statusColor.withOpacity(0.4), blurRadius: 8, offset: const Offset(0, 4))]),
                    child: Row(
                      children: [
                        Icon(_getStatusIcon(order.estado), size: 18, color: Colors.white),
                        const SizedBox(width: 6),
                        Text(order.estado.toUpperCase(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Progress Bar
            LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.grey.shade200,
              color: isCancelled ? Colors.red : statusColor,
              minHeight: 4,
            ),
            // Body Content
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: AppTheme.adminPrimary.withOpacity(0.05), shape: BoxShape.circle),
                    child: const Icon(Icons.person, color: AppTheme.adminPrimary, size: 30),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Cliente', style: TextStyle(color: Colors.grey.shade500, fontSize: 12, fontWeight: FontWeight.bold)),
                        Text(order.cliente ?? 'Mostrador', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black87)),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('Total', style: TextStyle(color: Colors.grey.shade500, fontSize: 12, fontWeight: FontWeight.bold)),
                      Text(NumberFormat.currency(symbol: 'S/ ').format(order.total), style: const TextStyle(color: AppTheme.success, fontWeight: FontWeight.bold, fontSize: 22)),
                    ],
                  ),
                ],
              ),
            ),
            // Footer Quick Actions
            if (nextStatus.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(color: Colors.grey.shade50, border: Border(top: BorderSide(color: Colors.grey.shade200))),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (order.estado.toLowerCase() == 'pendiente') ...[
                      TextButton.icon(
                        onPressed: () => _updateStatus(context, order.id, 'cancelado'),
                        icon: const Icon(Icons.cancel, color: Colors.red),
                        label: const Text('Cancelar', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                      ),
                      const Spacer(),
                    ],
                    ElevatedButton.icon(
                      onPressed: () => _updateStatus(context, order.id, nextStatus),
                      icon: const Icon(Icons.fast_forward, color: Colors.white, size: 18),
                      label: Text(_getActionText(order.estado), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: statusColor,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 4,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _updateStatus(BuildContext context, int id, String status) async {
    final ok = await context.read<OrderProvider>().updateStatus(id, status);
    if (ok) {
      ToastUtils.showSuccess('Estado actualizado a \${status.toUpperCase()}');
    } else {
      ToastUtils.showError('Error al actualizar el estado');
    }
  }
}
