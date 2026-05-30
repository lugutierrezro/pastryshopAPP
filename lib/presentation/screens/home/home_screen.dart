import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:badges/badges.dart' as badges;
import 'package:pastryshop/core/theme/app_theme.dart';
import 'package:pastryshop/presentation/providers/auth_provider.dart';
import 'package:pastryshop/presentation/providers/cart_provider.dart';
import 'package:pastryshop/presentation/providers/product_provider.dart';
import 'package:pastryshop/presentation/widgets/product/product_card.dart';
import 'package:pastryshop/presentation/widgets/common/category_chip.dart';
import 'package:pastryshop/presentation/widgets/common/shimmer_grid.dart';

// ============================================================
//  HomeScreen — Catálogo Principal (Premium Design)
// ============================================================
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final pp = context.read<ProductProvider>();
      // Use .catchError to prevent one failure from stopping the others
      pp.fetchCategories().catchError((_) {});
      pp.fetchProducts().catchError((_) {});
      pp.fetchProducts(featured: true).catchError((_) {});
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final cart = context.watch<CartProvider>();
    final pp   = context.watch<ProductProvider>();

    return Scaffold(
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ---- Premium App Bar ----
          SliverAppBar(
            expandedHeight: 140,
            floating: true,
            pinned: true,
            elevation: 0,
            backgroundColor: AppTheme.background,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppTheme.background, Colors.white],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                padding: const EdgeInsets.fromLTRB(24, 60, 24, 0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            auth.isLoggedIn ? 'Bienvenido,' : 'Buenos días,',
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppTheme.textSecondary),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            auth.isLoggedIn ? auth.user!.nombre : 'Amante del dulce',
                            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                  color: AppTheme.onBackground,
                                  fontWeight: FontWeight.w800,
                                ),
                          ),
                        ],
                      ),
                    ),
                    // Cart icon with glass effect
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))],
                      ),
                      child: badges.Badge(
                        badgeContent: Text('${cart.itemCount}', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                        showBadge: cart.itemCount > 0,
                        badgeStyle: const badges.BadgeStyle(badgeColor: AppTheme.primaryDark),
                        child: IconButton(
                          icon: const Icon(Icons.shopping_bag_outlined),
                          color: AppTheme.primaryDark,
                          onPressed: () => context.push('/cart'),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Profile / Admin menu
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))],
                      ),
                      child: PopupMenuButton<String>(
                        icon: Icon(auth.isLoggedIn ? Icons.account_circle : Icons.person_outline, color: AppTheme.primaryDark),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        position: PopupMenuPosition.under,
                        onSelected: (v) => _handleMenu(v, context, auth),
                        itemBuilder: (_) => _buildMenuItems(auth),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ---- Modern Search Pill ----
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 15, offset: const Offset(0, 5))],
                ),
                child: TextField(
                  controller: _searchCtrl,
                  decoration: InputDecoration(
                    hintText: 'Buscar delicias...',
                    prefixIcon: const Icon(Icons.search, color: AppTheme.primaryDark),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    fillColor: Colors.transparent,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  ),
                  onChanged: (v) => pp.setSearch(v),
                ),
              ),
            ),
          ),

          // ---- Featured Banner (Parallax/Glass) ----
          if (pp.selectedCategory == null && _searchCtrl.text.isEmpty)
            SliverToBoxAdapter(child: _FeaturedBanner(featured: pp.featured)),

          // ---- Categories ----
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.only(top: 20, bottom: 10),
              height: 48,
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: pp.categories.length + 1,
                itemBuilder: (_, i) {
                  if (i == 0) {
                    return CategoryChip(
                      label: 'Todo',
                      selected: pp.selectedCategory == null,
                      onTap: () => pp.setCategory(null),
                    );
                  }
                  final cat = pp.categories[i - 1];
                  return CategoryChip(
                    label: cat.nombre,
                    selected: pp.selectedCategory == cat.id,
                    onTap: () => pp.setCategory(cat.id),
                  );
                },
              ),
            ),
          ),

          // ---- Section title ----
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 10),
              child: Text(
                pp.selectedCategory == null ? 'Selección Exclusiva' : 'Productos',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
            ),
          ),

          // ---- Products Grid ----
          pp.loading
            ? const ShimmerGrid()
            : pp.products.isEmpty
              ? SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(40),
                      child: Column(children: [
                        const Text('🍰', style: TextStyle(fontSize: 64)),
                        const SizedBox(height: 16),
                        Text('Aún no hay productos aquí', style: Theme.of(context).textTheme.bodyLarge),
                      ]),
                    ),
                  ),
                )
              : SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  sliver: SliverGrid(
                    delegate: SliverChildBuilderDelegate(
                      (_, i) => ProductCard(product: pp.products[i]),
                      childCount: pp.products.length,
                    ),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2, 
                      childAspectRatio: 0.68,
                      crossAxisSpacing: 16, 
                      mainAxisSpacing: 16,
                    ),
                  ),
                ),

          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
      ),
    );
  }

  void _handleMenu(String v, BuildContext ctx, AuthProvider auth) {
    switch (v) {
      case 'login':    ctx.push('/login');     break;
      case 'register': ctx.push('/register');  break;
      case 'profile':  ctx.push('/profile');   break;
      case 'orders':   ctx.push('/orders');    break;
      case 'admin':    ctx.push('/admin');     break;
      case 'employee': ctx.push('/employee');  break;
      case 'logout':   auth.logout(); break;
    }
  }

  List<PopupMenuEntry<String>> _buildMenuItems(AuthProvider auth) {
    if (!auth.isLoggedIn) {
      return [
        const PopupMenuItem(value: 'login',    child: ListTile(leading: Icon(Icons.login),    title: Text('Iniciar sesión'))),
        const PopupMenuItem(value: 'register', child: ListTile(leading: Icon(Icons.person_add),title: Text('Registrarse'))),
      ];
    }
    final items = <PopupMenuEntry<String>>[
      PopupMenuItem(value: 'profile', child: ListTile(leading: const Icon(Icons.person),      title: Text(auth.user!.fullName))),
      const PopupMenuItem(value: 'orders',  child: ListTile(leading: Icon(Icons.receipt_long), title: Text('Mis pedidos'))),
    ];
    if (auth.isAdmin) {
      items.add(const PopupMenuDivider());
      items.add(const PopupMenuItem(value: 'admin',    child: ListTile(leading: Icon(Icons.admin_panel_settings, color: AppTheme.adminPrimary), title: Text('Panel Admin'))));
    }
    if (auth.isEmpleado) {
      items.add(const PopupMenuDivider());
      items.add(const PopupMenuItem(value: 'employee', child: ListTile(leading: Icon(Icons.work_outline, color: AppTheme.empPrimary), title: Text('Panel Empleado'))));
    }
    items.add(const PopupMenuDivider());
    items.add(const PopupMenuItem(value: 'logout', child: ListTile(leading: Icon(Icons.logout, color: Colors.red), title: Text('Cerrar sesión', style: TextStyle(color: Colors.red)))));
    return items;
  }
}

// ---- Featured Banner (Glassmorphism) ----
class _FeaturedBanner extends StatelessWidget {
  final List featured;
  const _FeaturedBanner({required this.featured});

  @override
  Widget build(BuildContext context) {
    if (featured.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      height: 220,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(24, 16, 8, 16),
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: featured.length,
        itemBuilder: (_, i) {
          final p = featured[i];
          return GestureDetector(
            onTap: () => context.push('/product/${p.id}'),
            child: Container(
              width: 300,
              margin: const EdgeInsets.only(right: 16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 15, offset: const Offset(0, 8))],
                image: DecorationImage(
                  image: NetworkImage(p.imagenUrl),
                  fit: BoxFit.cover,
                ),
              ),
              child: Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      gradient: LinearGradient(
                        colors: [Colors.black.withValues(alpha: 0.1), Colors.black.withValues(alpha: 0.7)],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                  Positioned(
                    top: 16,
                    left: 16,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                          ),
                          child: const Text('🌟 TOP CHOICE', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 20,
                    left: 20,
                    right: 20,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(p.nombre, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold, height: 1.1)),
                        const SizedBox(height: 8),
                        Text('\$${p.precio.toStringAsFixed(2)}', style: const TextStyle(color: AppTheme.secondary, fontSize: 18, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
