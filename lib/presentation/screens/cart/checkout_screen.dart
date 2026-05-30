import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:pastryshop/core/theme/app_theme.dart';
import 'package:pastryshop/presentation/providers/auth_provider.dart';
import 'package:pastryshop/presentation/providers/cart_provider.dart';
import 'package:pastryshop/presentation/providers/order_provider.dart';

// ============================================================
//  CheckoutScreen
// ============================================================
class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});
  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _formKey   = GlobalKey<FormState>();
  String _tipo     = 'tienda';
  final _dirCtrl   = TextEditingController();
  final _notasCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      if (!auth.isLoggedIn) context.pushReplacement('/login');
    });
  }

  @override
  void dispose() {
    _dirCtrl.dispose(); _notasCtrl.dispose(); super.dispose();
  }

  Future<void> _placeOrder() async {
    if (!_formKey.currentState!.validate()) return;
    final orders = context.read<OrderProvider>();
    final cart   = context.read<CartProvider>();
    final ok     = await orders.placeOrder(
      tipoEntrega: _tipo,
      direccionEntrega: _tipo == 'domicilio' ? _dirCtrl.text.trim() : null,
      notas: _notasCtrl.text.trim().isEmpty ? null : _notasCtrl.text.trim(),
    );
    if (!mounted) return;
    if (ok) {
      cart.clearLocal();
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🎉', style: TextStyle(fontSize: 64)),
              const SizedBox(height: 16),
              const Text('¡Pedido realizado!', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text('Tu pedido está en proceso. Recibirás actualizaciones sobre su estado.',
                textAlign: TextAlign.center, style: TextStyle(color: AppTheme.textSecondary)),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () { Navigator.pop(context); context.go('/orders'); },
              child: const Text('Ver mis pedidos'),
            ),
          ],
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(orders.error ?? 'Error'), backgroundColor: AppTheme.error),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart   = context.watch<CartProvider>();
    final orders = context.watch<OrderProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Confirmar Pedido'),
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios), onPressed: () => context.pop()),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Order summary
              Text('Resumen del pedido', style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 12),
              ...cart.items.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(item.imagenUrl, width: 48, height: 48, fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(width: 48, height: 48, color: AppTheme.secondary)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: Text('${item.nombre} × ${item.cantidad}')),
                    Text('\$${item.subtotal.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.w600)),
                  ],
                ),
              )),
              const Divider(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Total', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  Text('\$${cart.total.toStringAsFixed(2)}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: AppTheme.primary)),
                ],
              ),
              const SizedBox(height: 28),

              // Delivery type
              Text('Tipo de entrega', style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 12),
              Row(children: [
                _DeliveryOption(label: '🏪 En tienda', value: 'tienda',  group: _tipo, onChanged: (v) => setState(() => _tipo = v!)),
                const SizedBox(width: 12),
                _DeliveryOption(label: '🛵 Domicilio', value: 'domicilio', group: _tipo, onChanged: (v) => setState(() => _tipo = v!)),
              ]),

              if (_tipo == 'domicilio') ...[
                const SizedBox(height: 16),
                TextFormField(
                  controller: _dirCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Dirección de entrega',
                    prefixIcon: Icon(Icons.location_on_outlined),
                  ),
                  validator: (v) => _tipo == 'domicilio' && (v == null || v.isEmpty) ? 'Ingresa una dirección' : null,
                ),
              ],

              const SizedBox(height: 16),
              TextFormField(
                controller: _notasCtrl,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Notas adicionales (opcional)',
                  hintText: 'Sin azúcar, sin gluten, mensaje especial...',
                  prefixIcon: Icon(Icons.note_outlined),
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: orders.loading ? null : _placeOrder,
                  icon: orders.loading
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.check_circle_outline),
                  label: const Text('Confirmar pedido'),
                  style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DeliveryOption extends StatelessWidget {
  final String label, value, group;
  final ValueChanged<String?> onChanged;
  const _DeliveryOption({required this.label, required this.value, required this.group, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final selected = group == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => onChanged(value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: selected ? AppTheme.primary.withOpacity(0.1) : AppTheme.cream,
            border: Border.all(color: selected ? AppTheme.primary : AppTheme.divider, width: selected ? 2 : 1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Radio<String>(value: value, groupValue: group, onChanged: onChanged, activeColor: AppTheme.primary),
              Text(label, style: TextStyle(fontWeight: selected ? FontWeight.bold : FontWeight.normal, color: selected ? AppTheme.primary : AppTheme.onBackground)),
            ],
          ),
        ),
      ),
    );
  }
}
