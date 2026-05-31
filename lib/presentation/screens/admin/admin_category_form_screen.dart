import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:pastryshop/core/theme/app_theme.dart';
import 'package:pastryshop/domain/entities/entities.dart';
import 'package:pastryshop/presentation/providers/product_provider.dart';
import 'package:pastryshop/core/utils/toast_utils.dart';

class AdminCategoryFormScreen extends StatefulWidget {
  final CategoryEntity? category;
  const AdminCategoryFormScreen({super.key, this.category});

  @override
  State<AdminCategoryFormScreen> createState() => _AdminCategoryFormScreenState();
}

class _AdminCategoryFormScreenState extends State<AdminCategoryFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameCtrl;
  late TextEditingController _descCtrl;
  late TextEditingController _ordenCtrl;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final c = widget.category;
    _nameCtrl = TextEditingController(text: c?.nombre ?? '');
    _descCtrl = TextEditingController(text: c?.descripcion ?? '');
    _ordenCtrl = TextEditingController(text: c != null ? c.id.toString() : '0'); // using id as fallback order
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _ordenCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    
    final pp = context.read<ProductProvider>();
    final data = {
      'nombre': _nameCtrl.text.trim(),
      'descripcion': _descCtrl.text.trim(),
      'icono': '',
      'orden': int.tryParse(_ordenCtrl.text) ?? 0,
    };

    bool ok;
    if (widget.category == null) {
      ok = await pp.createCategory(data);
    } else {
      ok = await pp.updateCategory(widget.category!.id, data);
    }

    if (!mounted) return;
    setState(() => _saving = false);

    if (ok) {
      ToastUtils.showSuccess('Categoría guardada exitosamente');
      context.pop();
    } else {
      ToastUtils.showError('Error al guardar la categoría');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.category != null;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(isEdit ? 'Editar Categoría' : 'Nueva Categoría', style: const TextStyle(fontWeight: FontWeight.bold)),
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
              const Center(
                child: CircleAvatar(
                  radius: 50,
                  backgroundColor: AppTheme.primaryLight,
                  child: Icon(Icons.category, size: 50, color: AppTheme.primaryDark),
                ),
              ),
              const SizedBox(height: 32),
              const Text('Información de la Categoría', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppTheme.adminPrimary)),
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _nameCtrl,
                decoration: InputDecoration(
                  labelText: 'Nombre',
                  prefixIcon: const Icon(Icons.label, color: AppTheme.adminPrimary),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                  filled: true,
                  fillColor: Colors.white,
                ),
                validator: (v) => v == null || v.isEmpty ? 'Requerido' : null,
              ),
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _descCtrl,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Descripción',
                  prefixIcon: const Icon(Icons.description, color: AppTheme.adminPrimary),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _ordenCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Orden de visualización (Ej. 1, 2, 3)',
                  prefixIcon: const Icon(Icons.format_list_numbered, color: AppTheme.adminPrimary),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                  filled: true,
                  fillColor: Colors.white,
                ),
                validator: (v) => v == null || v.isEmpty ? 'Requerido' : null,
              ),
              
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _saving ? null : _save,
                  icon: _saving ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(Icons.save, color: Colors.white),
                  label: Text(isEdit ? 'Actualizar' : 'Crear', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
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
}
