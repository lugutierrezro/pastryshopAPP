import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:pastryshop/core/theme/app_theme.dart';
import 'package:pastryshop/presentation/providers/product_provider.dart';

// ============================================================
//  AdminProductsScreen
// ============================================================
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
      appBar: AppBar(
        title: const Text('Gestión de Productos'),
        backgroundColor: AppTheme.adminPrimary,
        foregroundColor: Colors.white,
      ),
      body: pp.loading
        ? const Center(child: CircularProgressIndicator())
        : ListView.builder(
            itemCount: pp.products.length,
            itemBuilder: (_, i) {
              final p = pp.products[i];
              return ListTile(
                leading: Image.network(p.imagenUrl, width: 50, height: 50, fit: BoxFit.cover, errorBuilder: (_,__,___)=>const Icon(Icons.cake)),
                title: Text(p.nombre),
                subtitle: Text('\$${p.precio.toStringAsFixed(2)} - Stock: ${p.stock}'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(icon: const Icon(Icons.edit, color: Colors.blue), onPressed: () => _editProduct(p)),
                    IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _deleteProduct(p.id)),
                  ],
                ),
              );
            },
          ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppTheme.adminPrimary,
        onPressed: () => _editProduct(null),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  void _editProduct(product) {
    context.push('/admin/product-form', extra: product);
  }

  void _deleteProduct(int id) async {
    final ok = await context.read<ProductProvider>().deleteProduct(id);
    if (ok) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Producto eliminado')));
  }
}
