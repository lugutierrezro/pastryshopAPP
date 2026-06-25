import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:badges/badges.dart' as badges;
import 'package:pastryshop/core/theme/app_theme.dart';
import 'package:pastryshop/core/constants/app_constants.dart';
import 'package:pastryshop/presentation/providers/auth_provider.dart';
import 'package:pastryshop/presentation/providers/cart_provider.dart';
import 'package:pastryshop/presentation/providers/order_provider.dart';
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
      
      final auth = context.read<AuthProvider>();
      if (auth.isLoggedIn) {
        context.read<OrderProvider>().fetchOrders(all: false).catchError((_) {});
      }
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
    final op   = context.watch<OrderProvider>();
    
    // Find active order (pendiente, preparando, listo)
    final activeOrders = op.orders.where((o) => ['pendiente', 'preparando', 'listo'].contains(o.estado)).toList();
    final hasActiveOrder = activeOrders.isNotEmpty;
    final activeOrder = hasActiveOrder ? activeOrders.first : null;

    return Scaffold(
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ---- Premium App Bar ----
          SliverAppBar(
            expandedHeight: 200,
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
                          Row(
                            children: [
                              Image.asset(
                                'assets/images/logo.png',
                                width: 40,
                                height: 40,
                                errorBuilder: (ctx, err, stack) => const Icon(Icons.cake, color: AppTheme.primary, size: 28),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'THE PASTRYSHOP',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1.5,
                                  color: AppTheme.onBackground,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
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
                        position: badges.BadgePosition.topEnd(top: -5, end: -5),
                        showBadge: cart.itemCount > 0,
                        badgeStyle: const badges.BadgeStyle(badgeColor: AppTheme.primaryDark),
                        badgeContent: Text('${cart.itemCount}', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
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
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: CircleAvatar(
                            radius: 14,
                            backgroundColor: Colors.transparent,
                            backgroundImage: auth.isLoggedIn && auth.user?.imagenUrl != null && auth.user!.imagenUrl!.isNotEmpty
                                ? NetworkImage(auth.user!.imagenUrl!) as ImageProvider
                                : null,
                            child: (auth.isLoggedIn && auth.user?.imagenUrl != null && auth.user!.imagenUrl!.isNotEmpty)
                                ? null
                                : Icon(auth.isLoggedIn ? Icons.account_circle : Icons.person_outline, color: AppTheme.primaryDark, size: 28),
                          ),
                        ),
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

          // ---- Modern Search Pill & Filter ----
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
              child: Row(
                children: [
                  Expanded(
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
                  const SizedBox(width: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: AppTheme.primaryDark,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [BoxShadow(color: AppTheme.primaryDark.withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 4))],
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.tune, color: Colors.white),
                      onPressed: () => _showFilterSheet(context, pp),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ---- Verification Banner ----
          if (auth.isLoggedIn && auth.user != null && !auth.user!.isVerified)
            SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded, color: Colors.orange),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text('Tu correo no está verificado. Por favor, verifica tu cuenta para realizar pedidos.', style: TextStyle(color: Colors.orange, fontSize: 12)),
                    ),
                    TextButton(
                      onPressed: () {
                        // In a real app this would call the /auth/resend-verification endpoint
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Correo de verificación enviado')));
                      },
                      child: const Text('Reenviar'),
                    ),
                  ],
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
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    pp.selectedCategory == null ? 'Selección Exclusiva' : 'Productos',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  if (pp.selectedCategory == null)
                    TextButton.icon(
                      onPressed: () => context.push('/custom-order'),
                      icon: const Icon(Icons.cake, color: AppTheme.primaryDark),
                      label: const Text('Arma tu Pastel', style: TextStyle(color: AppTheme.primaryDark, fontWeight: FontWeight.bold)),
                      style: TextButton.styleFrom(
                        backgroundColor: AppTheme.primaryLight.withOpacity(0.2),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      ),
                    ),
                ],
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

          const SliverToBoxAdapter(child: SizedBox(height: 100)), // Space for the floating widget
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: activeOrder != null
          ? Container(
              margin: const EdgeInsets.symmetric(horizontal: 24),
              width: double.infinity,
              child: FloatingActionButton.extended(
                onPressed: () => context.push('/orders/${activeOrder.id}'),
                backgroundColor: AppTheme.primaryDark,
                elevation: 8,
                label: Row(
                  children: [
                    const Icon(Icons.delivery_dining, color: Colors.white, size: 28),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('Sigue tu pedido', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                        Text('Estado: ${AppConstants.orderStateLabels[activeOrder.estado]}', style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 12)),
                      ],
                    ),
                    const SizedBox(width: 24),
                    const Icon(Icons.chevron_right, color: Colors.white),
                  ],
                ),
              ),
            )
          : auth.isLoggedIn
              ? FloatingActionButton.extended(
                  onPressed: () => context.push('/orders'),
                  icon: const Icon(Icons.receipt_long, color: AppTheme.primaryDark),
                  label: const Text('Mis Pedidos', style: TextStyle(color: AppTheme.primaryDark, fontWeight: FontWeight.bold)),
                  backgroundColor: Colors.white,
                )
              : null,
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

  void _showFilterSheet(BuildContext context, ProductProvider pp) {
    double minPrice = pp.minPrice ?? 0;
    double maxPrice = pp.maxPrice ?? 200;
    String sortOrder = pp.sortOrder;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40, height: 5,
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(color: AppTheme.divider, borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  Text('Filtros', style: Theme.of(context).textTheme.headlineMedium),
                  const SizedBox(height: 20),
                  Text('Rango de precio: S/ ${minPrice.toInt()} - S/ ${maxPrice.toInt()}', style: const TextStyle(fontWeight: FontWeight.bold)),
                  RangeSlider(
                    values: RangeValues(minPrice, maxPrice),
                    min: 0, max: 200, divisions: 40,
                    activeColor: AppTheme.primaryDark,
                    labels: RangeLabels('S/ ${minPrice.toInt()}', 'S/ ${maxPrice.toInt()}'),
                    onChanged: (v) => setState(() { minPrice = v.start; maxPrice = v.end; }),
                  ),
                  const SizedBox(height: 20),
                  const Text('Ordenar por', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 10,
                    children: [
                      ChoiceChip(
                        label: const Text('Relevancia'),
                        selected: sortOrder == 'none',
                        onSelected: (s) { if (s) setState(() => sortOrder = 'none'); },
                        selectedColor: AppTheme.primaryDark.withOpacity(0.2),
                      ),
                      ChoiceChip(
                        label: const Text('Precio: Menor a Mayor'),
                        selected: sortOrder == 'asc',
                        onSelected: (s) { if (s) setState(() => sortOrder = 'asc'); },
                        selectedColor: AppTheme.primaryDark.withOpacity(0.2),
                      ),
                      ChoiceChip(
                        label: const Text('Precio: Mayor a Menor'),
                        selected: sortOrder == 'desc',
                        onSelected: (s) { if (s) setState(() => sortOrder = 'desc'); },
                        selectedColor: AppTheme.primaryDark.withOpacity(0.2),
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            pp.setFilter(min: null, max: null);
                            pp.setSort('none');
                            Navigator.pop(ctx);
                          },
                          child: const Text('Limpiar'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            pp.setFilter(min: minPrice, max: maxPrice);
                            pp.setSort(sortOrder);
                            Navigator.pop(ctx);
                          },
                          child: const Text('Aplicar'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            );
          },
        );
      },
    );
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
                        Text('S/ ${p.precio.toStringAsFixed(2)}', style: const TextStyle(color: AppTheme.secondary, fontSize: 18, fontWeight: FontWeight.w600)),
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
