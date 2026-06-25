import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:pastryshop/core/theme/app_theme.dart';
import 'package:pastryshop/core/constants/app_constants.dart';
import 'package:pastryshop/presentation/providers/order_provider.dart';
import 'package:pastryshop/presentation/providers/auth_provider.dart';
import 'package:pastryshop/core/utils/pdf_invoice_generator.dart';

// ============================================================
//  OrderDetailScreen (Rappi-style Tracker)
// ============================================================
class OrderDetailScreen extends StatefulWidget {
  final int id;
  const OrderDetailScreen({super.key, required this.id});
  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  final MapController _mapCtrl = MapController();
  final LatLng _storeLocation = const LatLng(-12.0464, -77.0428); // Lima centro
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => context.read<OrderProvider>().fetchOrder(widget.id));
  }

  @override
  Widget build(BuildContext context) {
    final op   = context.watch<OrderProvider>();
    final auth = context.watch<AuthProvider>();
    final order = op.current;
    
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
          child: IconButton(icon: const Icon(Icons.arrow_back, color: AppTheme.primaryDark), onPressed: () => context.pop()),
        ),
        actions: [
          if (order != null)
            Container(
              margin: const EdgeInsets.all(8),
              decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
              child: IconButton(
                icon: const Icon(Icons.print, color: AppTheme.primaryDark),
                tooltip: 'Ver Comprobante',
                onPressed: () {
                  PdfInvoiceGenerator.generateAndShow(order);
                },
              ),
            ),
        ],
      ),
      body: op.loading
        ? const Center(child: CircularProgressIndicator())
        : order == null
          ? const Center(child: Text('Pedido no encontrado'))
          : Stack(
              children: [
                // 1. Fullscreen Map
                FlutterMap(
                  mapController: _mapCtrl,
                  options: MapOptions(
                    initialCenter: _storeLocation,
                    initialZoom: 14.0,
                    interactionOptions: const InteractionOptions(flags: InteractiveFlag.all & ~InteractiveFlag.rotate),
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.example.pastryshop',
                    ),
                    MarkerLayer(
                      markers: [
                        // Store Marker
                        Marker(
                          point: _storeLocation,
                          width: 50, height: 50,
                          child: const Icon(Icons.storefront, color: AppTheme.primaryDark, size: 50),
                        ),
                        // If it's en camino, we could show a bike marker...
                        if (order.tipoEntrega == 'domicilio' && (order.estado == 'listo' || order.estado == 'entregado'))
                           Marker(
                            point: LatLng(_storeLocation.latitude - 0.005, _storeLocation.longitude + 0.005), // Fake destination
                            width: 50, height: 50,
                            child: const Icon(Icons.person_pin_circle, color: AppTheme.primary, size: 50),
                          ),
                      ],
                    ),
                    if (order.tipoEntrega == 'domicilio' && (order.estado == 'listo' || order.estado == 'entregado'))
                      PolylineLayer(
                        polylines: [
                          Polyline<Object>(
                            points: [
                              _storeLocation,
                              LatLng(_storeLocation.latitude - 0.005, _storeLocation.longitude + 0.005),
                            ],
                            color: AppTheme.primary,
                            strokeWidth: 4,
                          ),
                        ],
                      ),
                  ],
                ),
                
                // 2. Draggable Bottom Sheet
                DraggableScrollableSheet(
                  initialChildSize: 0.5,
                  minChildSize: 0.25,
                  maxChildSize: 0.9,
                  builder: (context, scrollController) {
                    return Container(
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                        boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 20)],
                      ),
                      child: SingleChildScrollView(
                        controller: scrollController,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Center(
                              child: Container(
                                width: 40, height: 5,
                                decoration: BoxDecoration(color: AppTheme.divider, borderRadius: BorderRadius.circular(10)),
                              ),
                            ),
                            const SizedBox(height: 20),
                            
                            // Delivery Header
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(color: AppTheme.primary.withOpacity(0.1), shape: BoxShape.circle),
                                  child: Icon(
                                    order.tipoEntrega == 'domicilio' ? Icons.delivery_dining : Icons.storefront,
                                    color: AppTheme.primaryDark,
                                    size: 32,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        order.tipoEntrega == 'domicilio' ? 'Entrega a domicilio' : 'Recojo en tienda',
                                        style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        order.tipoEntrega == 'domicilio' ? order.direccionEntrega : 'Av. Pastelería 123, Lima',
                                        style: TextStyle(color: AppTheme.textSecondary),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 32),
                            
                            // Tracking button (P-17)
                            if (order.tipoEntrega == 'domicilio' && order.estado == 'listo') ...[
                              SizedBox(
                                width: double.infinity,
                                height: 50,
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    context.push('/orders/${order.id}/tracking', extra: order);
                                  },
                                  icon: const Icon(Icons.map_outlined),
                                  label: const Text('Seguir Repartidor en Mapa', style: TextStyle(fontWeight: FontWeight.bold)),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.primaryDark,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 32),
                            ],

                            // Stepper (Timeline)
                            const Text('Estado del pedido', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 20),
                            _OrderTimeline(estado: order.estado),
                            const SizedBox(height: 32),

                            // Customer Information (P-15)
                            const Text('Datos del Cliente', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade50,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.grey.shade200),
                              ),
                              child: Column(
                                children: [
                                  _buildInfoRow(Icons.person_outline, 'Nombre:', order.cliente ?? 'No especificado'),
                                  const Divider(height: 20),
                                  _buildInfoRow(Icons.email_outlined, 'Correo:', order.email ?? 'No especificado'),
                                  const Divider(height: 20),
                                  _buildInfoRow(Icons.phone_outlined, 'Teléfono:', order.telefono ?? 'No especificado'),
                                ],
                              ),
                            ),
                            const SizedBox(height: 32),
                            
                            const Divider(),
                            const SizedBox(height: 16),
                            
                            // Items list
                            Text('Resumen (#${order.id})', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 16),
                            ...order.items.map((item) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Row(
                                children: [
                                  Container(
                                    width: 32, height: 32,
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(color: AppTheme.cream, borderRadius: BorderRadius.circular(8)),
                                    child: Text('${item.cantidad}x', style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryDark)),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(child: Text(item.producto, style: const TextStyle(fontWeight: FontWeight.w600))),
                                  Text('S/ ${item.subtotal.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                ],
                              ),
                            )),
                            
                            const Divider(height: 32),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Total', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                Text('S/ ${order.total.toStringAsFixed(2)}',
                                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.primary)),
                              ],
                            ),
                            const SizedBox(height: 32),
                            
                            if (auth.isAdmin || auth.isEmpleado) _AdminActions(orderId: widget.id, currentStatus: order.estado),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppTheme.primaryDark, size: 20),
        const SizedBox(width: 12),
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textSecondary)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(value, style: const TextStyle(fontWeight: FontWeight.w600), textAlign: TextAlign.right),
        ),
      ],
    );
  }
}

class _OrderTimeline extends StatelessWidget {
  final String estado;
  const _OrderTimeline({required this.estado});

  @override
  Widget build(BuildContext context) {
    int currentIndex = _getIndex(estado);
    if (estado == 'cancelado') {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: AppTheme.error.withOpacity(0.1), borderRadius: BorderRadius.circular(16)),
        child: const Row(
          children: [
            Icon(Icons.cancel, color: AppTheme.error, size: 32),
            SizedBox(width: 16),
            Expanded(child: Text('Este pedido ha sido cancelado.', style: TextStyle(color: AppTheme.error, fontWeight: FontWeight.bold, fontSize: 16))),
          ],
        ),
      );
    }

    final steps = [
      {'title': 'Pedido recibido', 'icon': Icons.receipt_long},
      {'title': 'Preparando tu delicia', 'icon': Icons.soup_kitchen},
      {'title': 'Listo / En camino', 'icon': Icons.delivery_dining},
      {'title': 'Entregado', 'icon': Icons.done_all},
    ];

    return Column(
      children: List.generate(steps.length, (index) {
        bool isCompleted = index <= currentIndex;
        bool isCurrent = index == currentIndex;
        bool isLast = index == steps.length - 1;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                Container(
                  width: 32, height: 32,
                  decoration: BoxDecoration(
                    color: isCompleted ? AppTheme.primaryDark : AppTheme.divider,
                    shape: BoxShape.circle,
                    boxShadow: isCurrent ? [BoxShadow(color: AppTheme.primaryDark.withOpacity(0.4), blurRadius: 8, spreadRadius: 2)] : null,
                  ),
                  child: Icon(steps[index]['icon'] as IconData, color: Colors.white, size: 16),
                ),
                if (!isLast)
                  Container(
                    width: 2, height: 40,
                    color: isCompleted && !isCurrent ? AppTheme.primaryDark : AppTheme.divider,
                  ),
              ],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  steps[index]['title'] as String,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: isCurrent ? FontWeight.bold : FontWeight.w500,
                    color: isCompleted ? AppTheme.onBackground : AppTheme.textSecondary,
                  ),
                ),
              ),
            ),
          ],
        );
      }),
    );
  }

  int _getIndex(String estado) {
    switch (estado) {
      case 'pendiente': return 0;
      case 'preparando': return 1;
      case 'listo': return 2;
      case 'entregado': return 3;
      default: return 0;
    }
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
        const Text('Gestión Interna (Staff)', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.adminPrimary)),
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
