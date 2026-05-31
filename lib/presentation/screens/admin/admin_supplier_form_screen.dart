import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:pastryshop/core/theme/app_theme.dart';
import 'package:pastryshop/presentation/providers/supplier_provider.dart';
import 'package:pastryshop/core/utils/toast_utils.dart';
import 'package:pastryshop/domain/entities/entities.dart';

class AdminSupplierFormScreen extends StatefulWidget {
  final SupplierEntity? supplier;
  const AdminSupplierFormScreen({super.key, this.supplier});

  @override
  State<AdminSupplierFormScreen> createState() => _AdminSupplierFormScreenState();
}

class _AdminSupplierFormScreenState extends State<AdminSupplierFormScreen> {
  final _formKey = GlobalKey<FormState>();
  
  late TextEditingController _nombreCtrl;
  late TextEditingController _empresaCtrl;
  late TextEditingController _telefonoCtrl;
  late TextEditingController _emailCtrl;
  late TextEditingController _direccionCtrl;
  late TextEditingController _rucCtrl;
  bool _activo = true;

  @override
  void initState() {
    super.initState();
    final s = widget.supplier;
    _nombreCtrl = TextEditingController(text: s?.nombre ?? '');
    _empresaCtrl = TextEditingController(text: s?.empresa ?? '');
    _telefonoCtrl = TextEditingController(text: s?.telefono ?? '');
    _emailCtrl = TextEditingController(text: s?.email ?? '');
    _direccionCtrl = TextEditingController(text: s?.direccion ?? '');
    _rucCtrl = TextEditingController(text: s?.ruc ?? '');
    _activo = s?.activo ?? true;
  }

  @override
  void dispose() {
    _nombreCtrl.dispose(); _empresaCtrl.dispose();
    _telefonoCtrl.dispose(); _emailCtrl.dispose();
    _direccionCtrl.dispose(); _rucCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    
    final data = {
      'nombre': _nombreCtrl.text.trim(),
      'empresa': _empresaCtrl.text.trim(),
      'telefono': _telefonoCtrl.text.trim(),
      'email': _emailCtrl.text.trim(),
      'direccion': _direccionCtrl.text.trim(),
      'ruc': _rucCtrl.text.trim(),
      'activo': _activo ? 1 : 0,
    };

    final prov = context.read<SupplierProvider>();
    bool ok;
    if (widget.supplier == null) {
      ok = await prov.createSupplier(data);
    } else {
      ok = await prov.updateSupplier(widget.supplier!.id, data);
    }

    if (ok && mounted) {
      ToastUtils.showSuccess(widget.supplier == null ? 'Proveedor creado' : 'Proveedor actualizado');
      context.pop();
    } else if (mounted) {
      ToastUtils.showError(prov.error ?? 'Error al guardar');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.supplier != null;
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(isEdit ? 'Editar Proveedor' : 'Nuevo Proveedor', style: const TextStyle(fontWeight: FontWeight.bold)),
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
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header Card
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 10))],
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.adminPrimary.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.business_center, size: 48, color: AppTheme.adminPrimary),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      isEdit ? 'Actualizar Datos' : 'Registrar Entidad',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Rellena la información del proveedor para el abastecimiento.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey.shade500),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              
              // Fields
              _buildField('Empresa (Razón Social)', _empresaCtrl, Icons.apartment),
              const SizedBox(height: 20),
              _buildField('Nombre del Contacto *', _nombreCtrl, Icons.person, required: true),
              const SizedBox(height: 20),
              
              Row(
                children: [
                  Expanded(child: _buildField('RUC', _rucCtrl, Icons.receipt_long)),
                  const SizedBox(width: 20),
                  Expanded(child: _buildField('Teléfono', _telefonoCtrl, Icons.phone)),
                ],
              ),
              const SizedBox(height: 20),
              _buildField('Correo Electrónico', _emailCtrl, Icons.email),
              const SizedBox(height: 20),
              _buildField('Dirección', _direccionCtrl, Icons.location_on, maxLines: 2),
              
              const SizedBox(height: 32),
              
              if (isEdit) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _activo ? Colors.green.shade200 : Colors.red.shade200),
                  ),
                  child: SwitchListTile(
                    title: Text('Estado: ${_activo ? 'Activo' : 'Inactivo'}', style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: const Text('Permitir compras a este proveedor'),
                    value: _activo,
                    activeColor: Colors.green,
                    onChanged: (v) => setState(() => _activo = v),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                const SizedBox(height: 32),
              ],
              
              ElevatedButton(
                onPressed: context.watch<SupplierProvider>().loading ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.adminPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  elevation: 5,
                  shadowColor: AppTheme.adminPrimary.withOpacity(0.5),
                ),
                child: context.watch<SupplierProvider>().loading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('GUARDAR PROVEEDOR', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField(String label, TextEditingController ctrl, IconData icon, {bool required = false, int maxLines = 1}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: TextFormField(
        controller: ctrl,
        maxLines: maxLines,
        validator: required ? (v) => v!.isEmpty ? 'Requerido' : null : null,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: AppTheme.adminPrimary),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
          filled: true,
          fillColor: Colors.white,
          floatingLabelStyle: const TextStyle(color: AppTheme.adminPrimary, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
