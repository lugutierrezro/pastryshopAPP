import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:pastryshop/core/theme/app_theme.dart';
import 'package:pastryshop/presentation/providers/cart_provider.dart';

// ============================================================
//  CustomOrderScreen — Formulario de Pedidos Personalizados
// ============================================================
class CustomOrderScreen extends StatefulWidget {
  const CustomOrderScreen({super.key});

  @override
  State<CustomOrderScreen> createState() => _CustomOrderScreenState();
}

class _CustomOrderScreenState extends State<CustomOrderScreen> {
  final _formKey = GlobalKey<FormState>();
  String _sabor = 'Vainilla';
  int _porciones = 10;
  final _descCtrl = TextEditingController();
  DateTime? _fechaEntrega;

  final List<String> _sabores = ['Vainilla', 'Chocolate', 'Red Velvet', 'Fresa', 'Limón'];
  final List<int> _tamanos = [10, 20, 30, 40, 50];

  @override
  void dispose() {
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 3)),
      firstDate: DateTime.now().add(const Duration(days: 3)), // Minimo 3 dias de anticipacion
      lastDate: DateTime.now().add(const Duration(days: 60)),
    );
    if (picked != null) {
      setState(() => _fechaEntrega = picked);
    }
  }

  void _addToCart() async {
    if (!_formKey.currentState!.validate()) return;
    if (_fechaEntrega == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, selecciona una fecha de entrega'), backgroundColor: AppTheme.error),
      );
      return;
    }

    final detalles = '''
[PEDIDO PERSONALIZADO]
Sabor: $_sabor
Porciones: $_porciones
Fecha de Entrega: ${_fechaEntrega!.toString().split(' ')[0]}
Diseño/Notas: ${_descCtrl.text}
''';

    // Agregamos el "Pastel Personalizado" (ID=23) al carrito
    // Y guardamos los detalles en el estado temporal del carrito para pasarlos al Checkout
    final cart = context.read<CartProvider>();
    final ok = await cart.addItem(23, 1);
    
    if (ok) {
      cart.setCustomNotes(detalles);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('✅ Pastel Personalizado agregado al carrito', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          backgroundColor: AppTheme.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      context.pop();
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(cart.error ?? 'Error'), backgroundColor: AppTheme.error),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Arma tu Pastel', style: TextStyle(color: AppTheme.primaryDark, fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: AppTheme.primaryDark),
          onPressed: () => context.pop(),
        ),
      ),
      body: Stack(
        children: [
          // Background Gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppTheme.cream, Colors.white],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              physics: const BouncingScrollPhysics(),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Haz realidad tu idea', style: Theme.of(context).textTheme.headlineLarge),
                    const SizedBox(height: 8),
                    Text('Cuéntanos cómo quieres tu pastel y nosotros lo horneamos para ti.', style: TextStyle(color: AppTheme.textSecondary, fontSize: 16)),
                    const SizedBox(height: 32),

                    // Sabor
                    const Text('Sabor del bizcocho', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 10, runSpacing: 10,
                      children: _sabores.map((s) => ChoiceChip(
                        label: Text(s),
                        selected: _sabor == s,
                        onSelected: (val) { if (val) setState(() => _sabor = s); },
                        selectedColor: AppTheme.primaryLight.withOpacity(0.3),
                        labelStyle: TextStyle(color: _sabor == s ? AppTheme.primaryDark : AppTheme.textSecondary, fontWeight: _sabor == s ? FontWeight.bold : FontWeight.normal),
                      )).toList(),
                    ),
                    const SizedBox(height: 24),

                    // Tamaño
                    const Text('Tamaño (Porciones)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 10, runSpacing: 10,
                      children: _tamanos.map((t) => ChoiceChip(
                        label: Text('$t pers.'),
                        selected: _porciones == t,
                        onSelected: (val) { if (val) setState(() => _porciones = t); },
                        selectedColor: AppTheme.primaryLight.withOpacity(0.3),
                        labelStyle: TextStyle(color: _porciones == t ? AppTheme.primaryDark : AppTheme.textSecondary, fontWeight: _porciones == t ? FontWeight.bold : FontWeight.normal),
                      )).toList(),
                    ),
                    const SizedBox(height: 24),

                    // Diseño
                    const Text('Diseño y Decoración', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _descCtrl,
                      maxLines: 4,
                      decoration: InputDecoration(
                        hintText: 'Ej. Quiero un pastel de superhéroes con detalles en azul y rojo, que diga "Feliz Cumpleaños Juan".',
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppTheme.primary, width: 2)),
                      ),
                      validator: (v) => v == null || v.isEmpty ? 'Por favor describe el diseño que deseas' : null,
                    ),
                    const SizedBox(height: 24),

                    // Fecha de Entrega
                    const Text('Fecha de Entrega', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text('Nota: Los pasteles personalizados requieren al menos 3 días de anticipación.', style: TextStyle(color: AppTheme.error, fontSize: 12)),
                    const SizedBox(height: 12),
                    InkWell(
                      onTap: _selectDate,
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppTheme.divider),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_month, color: AppTheme.primaryDark),
                            const SizedBox(width: 16),
                            Text(
                              _fechaEntrega == null 
                                ? 'Seleccionar fecha' 
                                : _fechaEntrega!.toString().split(' ')[0],
                              style: TextStyle(fontSize: 16, color: _fechaEntrega == null ? AppTheme.textSecondary : AppTheme.onBackground, fontWeight: _fechaEntrega == null ? FontWeight.normal : FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 40),
                    
                    // Precio Base
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryLight.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppTheme.primaryLight),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline, color: AppTheme.primaryDark),
                          const SizedBox(width: 12),
                          const Expanded(child: Text('Precio base estimado. El precio final puede variar según la complejidad del diseño.', style: TextStyle(fontSize: 12))),
                          const SizedBox(width: 12),
                          Text('S/ 50.00', style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: AppTheme.primaryDark)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
          
          // ---- Sticky Bottom Button ----
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
                  child: ElevatedButton.icon(
                    onPressed: _addToCart,
                    icon: const Icon(Icons.shopping_bag),
                    label: const Text('Agregar Pedido al Carrito', style: TextStyle(fontSize: 16)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryDark,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    ),
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
