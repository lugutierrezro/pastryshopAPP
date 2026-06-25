import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:pastryshop/core/theme/app_theme.dart';
import 'package:pastryshop/presentation/providers/product_provider.dart';
import 'package:pastryshop/domain/entities/entities.dart';
import 'package:pastryshop/core/utils/toast_utils.dart';

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
  
  int _selectedCategory = 1;
  bool _destacado = false;
  bool _saving = false;
  
  // Image Upload State
  List<String> _currentImagesUrl = [];
  List<Map<String, dynamic>> _newImages = []; // { 'bytes': Uint8List, 'name': String }
  final ImagePicker _picker = ImagePicker();

  List<Map<String, dynamic>> _adicionales = [];

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    _nameCtrl  = TextEditingController(text: p?.nombre ?? '');
    _descCtrl  = TextEditingController(text: p?.descripcion ?? '');
    _priceCtrl = TextEditingController(text: p != null ? p.precio.toString() : '');
    _stockCtrl = TextEditingController(text: p != null ? p.stock.toString() : '');
    _destacado = p?.destacado ?? false;
    _selectedCategory = p?.categoryId ?? 1;
    
    if (p != null) {
      _currentImagesUrl = List<String>.from(p.imagenesUrl);
      if (_currentImagesUrl.isEmpty && p.imagenUrl.isNotEmpty) {
        _currentImagesUrl.add(p.imagenUrl);
      }
    }
    
    if (p != null && p.adicionales.isNotEmpty) {
      // Create a deep copy to avoid modifying the entity directly before saving
      _adicionales = p.adicionales.map((e) => Map<String, dynamic>.from(e)).toList();
    }

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
    super.dispose();
  }

  Future<void> _pickImages() async {
    final List<XFile> images = await _picker.pickMultiImage();
    if (images.isNotEmpty) {
      for (var image in images) {
        final bytes = await image.readAsBytes();
        setState(() {
          _newImages.add({
            'bytes': bytes,
            'name': image.name,
          });
        });
      }
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_currentImagesUrl.isEmpty && _newImages.isEmpty) {
      ToastUtils.showError('Debes subir al menos una imagen para el producto');
      return;
    }

    setState(() => _saving = true);
    final pp = context.read<ProductProvider>();

    List<String> uploadedUrls = [];

    // Upload new images
    for (var img in _newImages) {
      final url = await pp.uploadImage(img['name'], (img['bytes'] as Uint8List).toList());
      if (url != null) {
        uploadedUrls.add(url);
      } else {
        setState(() => _saving = false);
        ToastUtils.showError('Error al subir una de las imágenes al servidor');
        return;
      }
    }

    final allImages = [..._currentImagesUrl, ...uploadedUrls];

    final data = {
      'nombre': _nameCtrl.text.trim(),
      'descripcion': _descCtrl.text.trim(),
      'precio': double.tryParse(_priceCtrl.text) ?? 0.0,
      'stock': int.tryParse(_stockCtrl.text) ?? 0,
      'category_id': _selectedCategory,
      'imagen_url': allImages.isNotEmpty ? allImages.first : '',
      'imagenes_url': allImages,
      'destacado': _destacado,
      'activo': true,
      'adicionales': _adicionales.where((a) => a['nombre'] != null && a['nombre'].toString().trim().isNotEmpty).toList(),
    };
    
    bool ok = false;
    if (widget.product == null) {
      ok = await pp.createProduct(data);
    } else {
      ok = await pp.updateProduct(widget.product!.id, data);
    }

    if (!mounted) return;
    setState(() => _saving = false);

    if (ok) {
      ToastUtils.showSuccess('Producto guardado exitosamente');
      context.pop();
    } else {
      ToastUtils.showError('Error al guardar el producto');
    }
  }

  @override
  Widget build(BuildContext context) {
    final categories = context.watch<ProductProvider>().categories;
    final isEdit = widget.product != null;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(isEdit ? 'Editar Producto' : 'Nuevo Producto', style: const TextStyle(fontWeight: FontWeight.bold)),
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image Picker Section
              // Image Gallery Section
              const Text('Galería de Imágenes', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppTheme.adminPrimary)),
              const SizedBox(height: 12),
              SizedBox(
                height: 120,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    // Existing images
                    ..._currentImagesUrl.asMap().entries.map((e) {
                      final idx = e.key;
                      final url = e.value;
                      return Stack(
                        children: [
                          Container(
                            margin: const EdgeInsets.only(right: 12, top: 8),
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: CachedNetworkImage(
                              imageUrl: url,
                              fit: BoxFit.cover,
                              placeholder: (_, __) => const Center(child: CircularProgressIndicator()),
                              errorWidget: (_, __, ___) => const Icon(Icons.broken_image),
                            ),
                          ),
                          Positioned(
                            top: 0, right: 4,
                            child: CircleAvatar(
                              radius: 12,
                              backgroundColor: Colors.red,
                              child: IconButton(
                                padding: EdgeInsets.zero,
                                icon: const Icon(Icons.close, size: 14, color: Colors.white),
                                onPressed: () => setState(() => _currentImagesUrl.removeAt(idx)),
                              ),
                            ),
                          )
                        ],
                      );
                    }),
                    // New images
                    ..._newImages.asMap().entries.map((e) {
                      final idx = e.key;
                      final img = e.value;
                      return Stack(
                        children: [
                          Container(
                            margin: const EdgeInsets.only(right: 12, top: 8),
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppTheme.accent.withOpacity(0.5), width: 2),
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: Image.memory(
                              img['bytes'],
                              fit: BoxFit.cover,
                            ),
                          ),
                          Positioned(
                            top: 0, right: 4,
                            child: CircleAvatar(
                              radius: 12,
                              backgroundColor: Colors.red,
                              child: IconButton(
                                padding: EdgeInsets.zero,
                                icon: const Icon(Icons.close, size: 14, color: Colors.white),
                                onPressed: () => setState(() => _newImages.removeAt(idx)),
                              ),
                            ),
                          )
                        ],
                      );
                    }),
                    // Add Button
                    GestureDetector(
                      onTap: _pickImages,
                      child: Container(
                        margin: const EdgeInsets.only(right: 12, top: 8),
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade300, style: BorderStyle.solid),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_a_photo_outlined, color: AppTheme.adminPrimary.withOpacity(0.6)),
                            const SizedBox(height: 4),
                            const Text('Agregar', style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
              
              const Text('Información Básica', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppTheme.adminPrimary)),
              const SizedBox(height: 16),
              _buildTextField(_nameCtrl, 'Nombre del Producto', Icons.cake),
              const SizedBox(height: 16),
              _buildTextField(_descCtrl, 'Descripción', Icons.description, maxLines: 3),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _buildTextField(_priceCtrl, 'Precio (\$)', Icons.attach_money, isNumber: true)),
                  const SizedBox(width: 16),
                  Expanded(child: _buildTextField(_stockCtrl, 'Stock Inicial', Icons.inventory, isNumber: true)),
                ],
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<int>(
                value: categories.any((c) => c.id == _selectedCategory) ? _selectedCategory : (categories.isNotEmpty ? categories.first.id : null),
                decoration: InputDecoration(
                  labelText: 'Categoría',
                  prefixIcon: const Icon(Icons.category, color: AppTheme.adminPrimary),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                  filled: true,
                  fillColor: Colors.white,
                ),
                items: categories.map((c) => DropdownMenuItem(value: c.id, child: Text(c.nombre))).toList(),
                onChanged: (v) { if (v != null) setState(() => _selectedCategory = v); },
                validator: (v) => v == null ? 'Requerido' : null,
              ),
              const SizedBox(height: 24),
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: SwitchListTile(
                  title: const Text('Destacado en Inicio', style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: const Text('Se mostrará en la vitrina principal'),
                  value: _destacado,
                  activeColor: AppTheme.adminPrimary,
                  onChanged: (v) => setState(() => _destacado = v),
                ),
              ),
              const SizedBox(height: 24),
              const Text('Adicionales (Opciones Extra)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppTheme.adminPrimary)),
              const SizedBox(height: 8),
              ..._adicionales.asMap().entries.map((e) {
                final idx = e.key;
                final ad = e.value;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: TextFormField(
                          initialValue: ad['nombre'],
                          decoration: InputDecoration(
                            labelText: 'Nombre (ej. Velas)',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            filled: true, fillColor: Colors.white,
                          ),
                          onChanged: (v) => _adicionales[idx]['nombre'] = v,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 1,
                        child: TextFormField(
                          initialValue: ad['precio']?.toString() ?? '0',
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: InputDecoration(
                            labelText: 'Precio (+)',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            filled: true, fillColor: Colors.white,
                            prefixText: 'S/ ',
                          ),
                          onChanged: (v) => _adicionales[idx]['precio'] = double.tryParse(v) ?? 0.0,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => setState(() => _adicionales.removeAt(idx)),
                      )
                    ],
                  ),
                );
              }),
              TextButton.icon(
                onPressed: () => setState(() => _adicionales.add({'nombre': '', 'precio': 0.0})),
                icon: const Icon(Icons.add, color: AppTheme.adminPrimary),
                label: const Text('Agregar Adicional', style: TextStyle(color: AppTheme.adminPrimary, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _saving ? null : _save,
                  icon: _saving ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(Icons.save, color: Colors.white),
                  label: Text(isEdit ? 'Actualizar Producto' : 'Guardar Producto', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.adminPrimary, 
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 5,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController ctrl, String label, IconData icon, {int maxLines = 1, bool isNumber = false}) {
    return TextFormField(
      controller: ctrl,
      maxLines: maxLines,
      keyboardType: isNumber ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppTheme.adminPrimary),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
        filled: true,
        fillColor: Colors.white,
      ),
      validator: (v) {
        if (v == null || v.isEmpty) return 'Requerido';
        if (isNumber && double.tryParse(v) == null) return 'Inválido';
        return null;
      },
    );
  }
}
