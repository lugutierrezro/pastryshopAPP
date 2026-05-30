import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:pastryshop/core/theme/app_theme.dart';
import 'package:pastryshop/presentation/providers/product_provider.dart';
import 'package:pastryshop/domain/entities/entities.dart';

// ============================================================
//  AdminProductFormScreen
// ============================================================
class AdminProductFormScreen extends StatefulWidget {
  final ProductEntity? product;
  const AdminProductFormScreen({super.key, this.product});

  @override
  State<AdminProductFormScreen> createState() => _AdminProductFormScreenState();
}

class _AdminProductFormScreenState extends State<AdminProductFormScreen> {
  final _formKey = GlobalKey<FormState>();
  
  late TextEditingController _nameCtrl;
  late TextEditingController _descCtrl;
  late TextEditingController _priceCtrl;
  late TextEditingController _stockCtrl;
  late TextEditingController _imgCtrl;
  
  int _selectedCategory = 1;
  bool _destacado = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    _nameCtrl  = TextEditingController(text: p?.nombre ?? '');
    _descCtrl  = TextEditingController(text: p?.descripcion ?? '');
    _priceCtrl = TextEditingController(text: p != null ? p.precio.toString() : '');
    _stockCtrl = TextEditingController(text: p != null ? p.stock.toString() : '');
    _imgCtrl   = TextEditingController(text: p?.imagenUrl ?? '');
    _destacado = p?.destacado ?? false;
    _selectedCategory = p?.categoryId ?? 1;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (context.read<ProductProvider>().categories.isEmpty) {
        context.read<ProductProvider>().fetchCategories();
      }
    });
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _priceCtrl.dispose();
    _stockCtrl.dispose();
    _imgCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final data = {
      'nombre': _nameCtrl.text.trim(),
      'descripcion': _descCtrl.text.trim(),
      'precio': double.tryParse(_priceCtrl.text) ?? 0.0,
      'stock': int.tryParse(_stockCtrl.text) ?? 0,
      'category_id': _selectedCategory,
      'imagen_url': _imgCtrl.text.trim(),
      'destacado': _destacado,
      'activo': true,
    };

    final pp = context.read<ProductProvider>();
    bool ok = false;
    
    if (widget.product == null) {
      ok = await pp.createProduct(data);
    } else {
      ok = await pp.updateProduct(widget.product!.id, data);
    }

    if (!mounted) return;
    setState(() => _saving = false);

    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ Producto guardado con éxito'), backgroundColor: AppTheme.success));
      context.pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('❌ Error al guardar: \${pp.error}'), backgroundColor: AppTheme.error));
    }
  }

  @override
  Widget build(BuildContext context) {
    final categories = context.watch<ProductProvider>().categories;
    final isEdit = widget.product != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Editar Producto' : 'Nuevo Producto'),
        backgroundColor: AppTheme.adminPrimary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Información Básica', style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: AppTheme.adminPrimary)),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(labelText: 'Nombre del Producto', border: OutlineInputBorder()),
                validator: (v) => v!.isEmpty ? 'Requerido' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descCtrl,
                decoration: const InputDecoration(labelText: 'Descripción', border: OutlineInputBorder()),
                maxLines: 3,
                validator: (v) => v!.isEmpty ? 'Requerido' : null,
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _priceCtrl,
                      decoration: const InputDecoration(labelText: 'Precio (\$)', border: OutlineInputBorder()),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      validator: (v) => double.tryParse(v ?? '') == null ? 'Inválido' : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _stockCtrl,
                      decoration: const InputDecoration(labelText: 'Stock Inicial', border: OutlineInputBorder()),
                      keyboardType: TextInputType.number,
                      validator: (v) => int.tryParse(v ?? '') == null ? 'Inválido' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              DropdownButtonFormField<int>(
                value: categories.any((c) => c.id == _selectedCategory) ? _selectedCategory : null,
                decoration: const InputDecoration(labelText: 'Categoría', border: OutlineInputBorder()),
                items: categories.map((c) => DropdownMenuItem(value: c.id, child: Text(c.nombre))).toList(),
                onChanged: (v) { if (v != null) setState(() => _selectedCategory = v); },
                validator: (v) => v == null ? 'Requerido' : null,
              ),
              const SizedBox(height: 24),
              Text('Imagen', style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: AppTheme.adminPrimary)),
              const SizedBox(height: 16),
              TextFormField(
                controller: _imgCtrl,
                decoration: const InputDecoration(labelText: 'URL de la Imagen', border: OutlineInputBorder(), hintText: 'https://ejemplo.com/imagen.jpg'),
                onChanged: (_) => setState(() {}), // refresh preview
                validator: (v) => v!.isEmpty ? 'Requerido' : null,
              ),
              const SizedBox(height: 16),
              if (_imgCtrl.text.isNotEmpty)
                Container(
                  height: 200,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.grey[200],
                    image: DecorationImage(image: NetworkImage(_imgCtrl.text), fit: BoxFit.cover, onError: (e,s) => const Icon(Icons.broken_image)),
                  ),
                ),
              const SizedBox(height: 24),
              SwitchListTile(
                title: const Text('Destacado en Inicio'),
                value: _destacado,
                activeColor: AppTheme.adminPrimary,
                onChanged: (v) => setState(() => _destacado = v),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _saving ? null : _save,
                  icon: _saving ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(Icons.save),
                  label: const Text('Guardar Producto'),
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.adminPrimary, padding: const EdgeInsets.symmetric(vertical: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
