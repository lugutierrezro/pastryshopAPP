import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pastryshop/core/theme/app_theme.dart';
import 'package:pastryshop/domain/entities/entities.dart';
import 'package:pastryshop/presentation/providers/favorite_provider.dart';
import 'package:pastryshop/presentation/providers/cart_provider.dart';
import 'package:pastryshop/core/utils/toast_utils.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FavoriteProvider>().fetchFavorites();
    });
  }

  void _addToCart(ProductEntity product) async {
    final success = await context.read<CartProvider>().addItem(product.id, 1);
    if (success) {
      ToastUtils.showSuccess('Añadido al carrito');
    } else {
      ToastUtils.showError('Error al añadir');
    }
  }

  @override
  Widget build(BuildContext context) {
    final favProvider = context.watch<FavoriteProvider>();

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Mis Favoritos', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: favProvider.loading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
          : favProvider.favorites.isEmpty
              ? _buildEmptyState()
              : GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.7,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: favProvider.favorites.length,
                  itemBuilder: (context, index) {
                    final product = favProvider.favorites[index];
                    return _ProductCard(
                      product: product,
                      onAddToCart: () => _addToCart(product),
                      onToggleFav: () => favProvider.toggleFavorite(product.id),
                    );
                  },
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.favorite_border, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          const Text('Aún no tienes favoritos', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('Explora nuestros productos y guarda los que más te gusten.',
              textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade600)),
        ],
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  final ProductEntity product;
  final VoidCallback onAddToCart;
  final VoidCallback onToggleFav;

  const _ProductCard({required this.product, required this.onAddToCart, required this.onToggleFav});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 5)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Stack(
              children: [
                Container(
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                    image: DecorationImage(
                      image: NetworkImage(product.imagenUrl.isNotEmpty ? product.imagenUrl : 'https://via.placeholder.com/150'),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: GestureDetector(
                    onTap: onToggleFav,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(color: Colors.white.withOpacity(0.9), shape: BoxShape.circle),
                      child: const Icon(Icons.favorite, color: Colors.red, size: 20),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.nombre,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 4),
                Text('\$${product.precio.toStringAsFixed(2)}', style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  height: 36,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: EdgeInsets.zero,
                    ),
                    onPressed: onAddToCart,
                    child: const Text('Añadir', style: TextStyle(color: Colors.white, fontSize: 12)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
