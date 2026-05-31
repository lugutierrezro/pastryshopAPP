import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:pastryshop/core/theme/app_theme.dart';
import 'package:pastryshop/presentation/providers/product_provider.dart';
import 'package:pastryshop/presentation/widgets/admin/admin_sidebar.dart';
import 'package:pastryshop/presentation/widgets/shared/shimmer_loading.dart';
import 'package:pastryshop/core/utils/toast_utils.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';

class AdminProductsScreen extends StatefulWidget {
  const AdminProductsScreen({super.key});
  @override
  State<AdminProductsScreen> createState() => _AdminProductsScreenState();
}

class _AdminProductsScreenState extends State<AdminProductsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => context.read<ProductProvider>().fetchProducts());
  }

  @override
  Widget build(BuildContext context) {
    final pp = context.watch<ProductProvider>();

    return Scaffold(
      backgroundColor: AppTheme.background,
      drawer: const AdminSidebar(),
      appBar: AppBar(
        title: const Text('Catálogo de Productos', style: TextStyle(fontWeight: FontWeight.bold)),
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
      ),
      body: pp.loading
        ? const ShimmerListLoading()
        : ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: pp.products.length,
            itemBuilder: (_, i) {
              final p = pp.products[i];
              return GestureDetector(
                onTap: () => context.push('/admin/product-detail', extra: p),
                child: Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  elevation: 4,
                  shadowColor: Colors.black12,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: CachedNetworkImage(
                          imageUrl: p.imagenUrl,
                          width: 80,
                          height: 80,
                          fit: BoxFit.cover,
                          color: p.activo ? null : Colors.grey,
                          colorBlendMode: p.activo ? null : BlendMode.saturation,
                          placeholder: (context, url) => Container(color: Colors.grey.shade200, child: const Icon(Icons.image, color: Colors.grey)),
                          errorWidget: (context, url, error) => Container(color: Colors.grey.shade200, child: const Icon(Icons.cake, color: Colors.grey, size: 30)),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(child: Text(p.nombre, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: p.activo ? Colors.black : Colors.grey))),
                                if (!p.activo)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(color: Colors.red.shade100, borderRadius: BorderRadius.circular(4)),
                                    child: const Text('INACTIVO', style: TextStyle(color: Colors.red, fontSize: 10, fontWeight: FontWeight.bold)),
                                  )
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(p.categoria, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  NumberFormat.currency(symbol: 'S/ ').format(p.precio),
                                  style: TextStyle(color: p.activo ? AppTheme.success : Colors.grey, fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: p.activo ? (p.stock > 10 ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1)) : Colors.grey.shade200,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text('Stock: ${p.stock}', style: TextStyle(color: p.activo ? (p.stock > 10 ? Colors.green : Colors.orange) : Colors.grey, fontWeight: FontWeight.bold, fontSize: 12)),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Column(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit_outlined, color: Colors.blue),
                            onPressed: () => _editProduct(p),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.red),
                            onPressed: () => _deleteProduct(p.id),
                          ),
                        ],
                      )
                    ],
                  ),
                ),
              ));
            },
          ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppTheme.adminPrimary,
        onPressed: () => _editProduct(null),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Nuevo Producto', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  void _editProduct(product) {
    context.push('/admin/product-form', extra: product);
  }

  void _deleteProduct(int id) async {
    // Confirmation dialog
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('¿Eliminar Producto?'),
        content: const Text('Esta acción no se puede deshacer.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Eliminar', style: TextStyle(color: Colors.white)),
          ),
        ],
      )
    );

    if (confirm == true && mounted) {
      final ok = await context.read<ProductProvider>().deleteProduct(id);
      if (ok) {
        ToastUtils.showSuccess('Producto eliminado correctamente');
      } else {
        ToastUtils.showError('Error al eliminar producto');
      }
    }
  }
}
