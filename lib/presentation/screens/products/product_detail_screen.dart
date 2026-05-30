import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:pastryshop/core/theme/app_theme.dart';
import 'package:pastryshop/presentation/providers/cart_provider.dart';
import 'package:pastryshop/presentation/providers/product_provider.dart';

// ============================================================
//  ProductDetailScreen — Premium Redesign
// ============================================================
class ProductDetailScreen extends StatefulWidget {
  final int id;
  const ProductDetailScreen({super.key, required this.id});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  int _cantidad = 1;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductProvider>().fetchProduct(widget.id);
    });
  }

  void _addToCart(product) {
    context.read<CartProvider>().addItem(product, _cantidad);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: const Text('✅ Agregado al carrito', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      backgroundColor: AppTheme.success,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final pp = context.watch<ProductProvider>();
    final p = pp.selected;

    if (pp.loading || p == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: AppTheme.primaryDark)),
      );
    }

    final double totalPrice = p.precio * _cantidad;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: CircleAvatar(
            backgroundColor: Colors.white.withValues(alpha: 0.8),
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, color: AppTheme.primaryDark, size: 20),
              onPressed: () => context.pop(),
            ),
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: CircleAvatar(
              backgroundColor: Colors.white.withValues(alpha: 0.8),
              child: IconButton(
                icon: const Icon(Icons.favorite_border, color: AppTheme.primaryDark),
                onPressed: () {},
              ),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          // ---- Hero Image Background ----
          Positioned(
            top: 0, left: 0, right: 0,
            height: MediaQuery.of(context).size.height * 0.55,
            child: Image.network(
              p.imagenUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(color: AppTheme.secondary),
            ),
          ),
          
          // ---- Bottom Sheet Content ----
          Positioned(
            top: MediaQuery.of(context).size.height * 0.45,
            left: 0, right: 0, bottom: 0,
            child: Container(
              decoration: const BoxDecoration(
                color: AppTheme.background,
                borderRadius: BorderRadius.only(topLeft: Radius.circular(40), topRight: Radius.circular(40)),
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 20, offset: Offset(0, -5))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Drag handle
                  Center(
                    child: Container(
                      margin: const EdgeInsets.only(top: 12, bottom: 20),
                      width: 40, height: 5,
                      decoration: BoxDecoration(color: AppTheme.divider, borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(
                                  p.nombre,
                                  style: Theme.of(context).textTheme.headlineLarge,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: AppTheme.secondary.withValues(alpha: 0.3),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  '\$${p.precio.toStringAsFixed(2)}',
                                  style: const TextStyle(color: AppTheme.primaryDark, fontWeight: FontWeight.w800, fontSize: 18),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              const Icon(Icons.star, color: Colors.orange, size: 18),
                              const SizedBox(width: 4),
                              const Text('4.9', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                              const SizedBox(width: 8),
                              Text('(128 reseñas)', style: TextStyle(color: AppTheme.textSecondary.withValues(alpha: 0.7), fontSize: 14)),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  border: Border.all(color: AppTheme.primaryLight),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  p.categoria.toUpperCase(),
                                  style: const TextStyle(color: AppTheme.primaryDark, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          const Text('Descripción', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 12),
                          Text(
                            p.descripcion,
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.6, color: AppTheme.textSecondary),
                          ),
                          const SizedBox(height: 24),
                          
                          if (p.stock > 0) ...[
                            const Text('Cantidad', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                _QuantityButton(
                                  icon: Icons.remove,
                                  onTap: () { if (_cantidad > 1) setState(() => _cantidad--); },
                                ),
                                Container(
                                  width: 50,
                                  alignment: Alignment.center,
                                  child: Text('$_cantidad', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                                ),
                                _QuantityButton(
                                  icon: Icons.add,
                                  onTap: () { if (_cantidad < p.stock) setState(() => _cantidad++); },
                                ),
                                const Spacer(),
                                Text('Disponibles: ${p.stock}', style: TextStyle(color: AppTheme.textSecondary.withValues(alpha: 0.7))),
                              ],
                            ),
                          ] else
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(color: AppTheme.error.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                              child: Row(
                                children: [
                                  const Icon(Icons.error_outline, color: AppTheme.error),
                                  const SizedBox(width: 12),
                                  Expanded(child: Text('Lo sentimos, este producto está agotado por el momento.', style: TextStyle(color: AppTheme.error, fontWeight: FontWeight.w600))),
                                ],
                              ),
                            ),
                            
                          const SizedBox(height: 100), // spacing for bottom bar
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // ---- Sticky Bottom Add to Cart Bar ----
          if (p.stock > 0)
            Positioned(
              left: 0, right: 0, bottom: 0,
              child: ClipRRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.8),
                      border: Border(top: BorderSide(color: AppTheme.divider)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('Total', style: TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
                            Text('\$${totalPrice.toStringAsFixed(2)}', style: const TextStyle(color: AppTheme.onBackground, fontSize: 24, fontWeight: FontWeight.w900)),
                          ],
                        ),
                        ElevatedButton.icon(
                          onPressed: () => _addToCart(p),
                          icon: const Icon(Icons.shopping_bag),
                          label: const Text('Agregar'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryDark,
                            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _QuantityButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _QuantityButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          border: Border.all(color: AppTheme.divider, width: 2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, size: 20, color: AppTheme.primaryDark),
      ),
    );
  }
}
