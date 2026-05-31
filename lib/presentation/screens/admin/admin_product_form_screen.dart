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
  String? _currentImageUrl;
  Uint8List? _selectedImageBytes;
  String? _selectedImageName;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    _nameCtrl  = TextEditingController(text: p?.nombre ?? '');
    _descCtrl  = TextEditingController(text: p?.descripcion ?? '');
    _priceCtrl = TextEditingController(text: p != null ? p.precio.toString() : '');
    _stockCtrl = TextEditingController(text: p != null ? p.stock.toString() : '');
    _currentImageUrl = p?.imagenUrl;
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
    super.dispose();
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      final bytes = await image.readAsBytes();
      setState(() {
        _selectedImageBytes = bytes;
        _selectedImageName = image.name;
        _currentImageUrl = null; // Clear existing url preview
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_currentImageUrl == null && _selectedImageBytes == null) {
      ToastUtils.showError('Debes subir una imagen para el producto');
      return;
    }

    setState(() => _saving = true);
    final pp = context.read<ProductProvider>();

    String finalImageUrl = _currentImageUrl ?? '';

    // Upload new image if selected
    if (_selectedImageBytes != null && _selectedImageName != null) {
      final url = await pp.uploadImage(_selectedImageName!, _selectedImageBytes!.toList());
      if (url != null) {
        finalImageUrl = url;
      } else {
        setState(() => _saving = false);
        ToastUtils.showError('Error al subir la imagen al servidor');
        return;
      }
    }

    final data = {
      'nombre': _nameCtrl.text.trim(),
      'descripcion': _descCtrl.text.trim(),
      'precio': double.tryParse(_priceCtrl.text) ?? 0.0,
      'stock': int.tryParse(_stockCtrl.text) ?? 0,
      'category_id': _selectedCategory,
      'imagen_url': finalImageUrl,
      'destacado': _destacado,
      'activo': true,
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
              Center(
                child: GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    height: 220,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.grey.shade300, width: 2, style: BorderStyle.solid),
                      boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 5))],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: _selectedImageBytes != null
                        ? Image.memory(_selectedImageBytes!, fit: BoxFit.cover)
                        : _currentImageUrl != null && _currentImageUrl!.isNotEmpty
                            ? CachedNetworkImage(
                                imageUrl: _currentImageUrl!,
                                fit: BoxFit.cover,
                                placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
                                errorWidget: (context, url, error) => const Center(child: Icon(Icons.broken_image, size: 50, color: Colors.grey)),
                              )
                            : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.cloud_upload_outlined, size: 60, color: AppTheme.adminPrimary.withOpacity(0.5)),
                                  const SizedBox(height: 12),
                                  const Text('Toca para subir una imagen', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 4),
                                  Text('Formatos: JPG, PNG, WEBP', style: TextStyle(color: Colors.grey.shade400, fontSize: 12)),
                                ],
                              ),
                  ),
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
