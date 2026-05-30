import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:pastryshop/core/theme/app_theme.dart';
import 'package:pastryshop/presentation/providers/cart_provider.dart';
import 'package:pastryshop/presentation/providers/auth_provider.dart';

// ============================================================
//  CartScreen
// ============================================================
class CartScreen extends StatefulWidget {
  const CartScreen({super.key});
  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (context.read<AuthProvider>().isLoggedIn) {
        context.read<CartProvider>().fetchCart();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Carrito'),
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios), onPressed: () => context.pop()),
        actions: [
          if (cart.items.isNotEmpty)
            TextButton(
              onPressed: () => _clearCart(context, cart),
              child: const Text('Vaciar', style: TextStyle(color: AppTheme.error)),
            ),
        ],
      ),
      body: !auth.isLoggedIn
        ? _LoginPrompt()
        : cart.loading
          ? const Center(child: CircularProgressIndicator())
          : cart.isEmpty
            ? _EmptyCart()
            : Column(
                children: [
                  Expanded(
                    child: ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: cart.items.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (_, i) => _CartItemTile(
                        item: cart.items[i],
                        onRemove: () => cart.removeItem(cart.items[i].id),
                      ),
                    ),
                  ),
                  _CartSummary(cart: cart, auth: auth),
                ],
              ),
    );
  }

  void _clearCart(BuildContext ctx, CartProvider cart) {
    showDialog(
      context: ctx,
      builder: (_) => AlertDialog(
        title: const Text('Vaciar carrito'),
        content: const Text('¿Eliminar todos los productos?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () { Navigator.pop(ctx); cart.clearCart(); },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            child: const Text('Vaciar'),
          ),
        ],
      ),
    );
  }
}

class _CartItemTile extends StatelessWidget {
  final item;
  final VoidCallback onRemove;
  const _CartItemTile({required this.item, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(item.imagenUrl, width: 72, height: 72, fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(width: 72, height: 72, color: AppTheme.secondary,
                child: const Icon(Icons.cake))),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.nombre, style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600), maxLines: 2, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Text('\$${item.precio.toStringAsFixed(2)} × ${item.cantidad}',
                  style: Theme.of(context).textTheme.bodyMedium),
                Text('Subtotal: \$${item.subtotal.toStringAsFixed(2)}',
                  style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: AppTheme.error),
            onPressed: onRemove,
          ),
        ],
      ),
    );
  }
}

class _CartSummary extends StatelessWidget {
  final CartProvider cart;
  final AuthProvider auth;
  const _CartSummary({required this.cart, required this.auth});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 16, offset: Offset(0, -4))],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('${cart.itemCount} productos', style: Theme.of(context).textTheme.bodyMedium),
              Text('Total: \$${cart.total.toStringAsFixed(2)}',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: AppTheme.primary)),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => context.push('/checkout'),
              icon: const Icon(Icons.payment),
              label: const Text('Proceder al pedido'),
              style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
            ),
          ),
        ],
      ),
    );
  }
}

class _LoginPrompt extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🛒', style: TextStyle(fontSize: 56)),
          const SizedBox(height: 16),
          Text('Inicia sesión para ver tu carrito', style: Theme.of(context).textTheme.headlineMedium, textAlign: TextAlign.center),
          const SizedBox(height: 24),
          ElevatedButton(onPressed: () => context.push('/login'), child: const Text('Iniciar sesión')),
          const SizedBox(height: 12),
          OutlinedButton(onPressed: () => context.pop(), child: const Text('Seguir viendo')),
        ],
      ),
    ),
  );
}

class _EmptyCart extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🧺', style: TextStyle(fontSize: 56)),
          const SizedBox(height: 16),
          Text('Tu carrito está vacío', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 8),
          Text('Explora nuestro catálogo y agrega algo delicioso', style: Theme.of(context).textTheme.bodyMedium, textAlign: TextAlign.center),
          const SizedBox(height: 24),
          ElevatedButton(onPressed: () => context.go('/'), child: const Text('Ver catálogo')),
        ],
      ),
    ),
  );
}
