import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:pastryshop/core/theme/app_theme.dart';
import 'package:pastryshop/domain/entities/entities.dart';
import 'package:pastryshop/presentation/providers/role_provider.dart';
import 'package:pastryshop/core/utils/toast_utils.dart';

class AdminRoleFormScreen extends StatefulWidget {
  final RoleEntity? role;
  const AdminRoleFormScreen({super.key, this.role});

  @override
  State<AdminRoleFormScreen> createState() => _AdminRoleFormScreenState();
}

class _AdminRoleFormScreenState extends State<AdminRoleFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nombreCtrl;
  late TextEditingController _descCtrl;
  
  final Map<String, String> _availablePermissions = {
    'manage_roles': 'Gestionar Roles',
    'manage_users': 'Gestionar Usuarios',
    'manage_products': 'Gestionar Productos',
    'manage_orders': 'Gestionar Pedidos',
    'manage_purchases': 'Gestionar Compras',
    'manage_suppliers': 'Gestionar Proveedores',
    'manage_employees': 'Gestionar Empleados',
    'view_dashboard': 'Ver Dashboard (Estadísticas)',
    'view_logs': 'Ver Registro de Actividad',
  };

  final Set<String> _selectedPermissions = {};

  @override
  void initState() {
    super.initState();
    _nombreCtrl = TextEditingController(text: widget.role?.nombre ?? '');
    _descCtrl = TextEditingController(text: widget.role?.descripcion ?? '');
    if (widget.role != null) {
      _selectedPermissions.addAll(widget.role!.permisos);
    }
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final rp = context.watch<RoleProvider>();

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(widget.role == null ? 'Nuevo Rol' : 'Editar Rol', style: const TextStyle(fontWeight: FontWeight.bold)),
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
      body: rp.loading
        ? const Center(child: CircularProgressIndicator(color: AppTheme.adminPrimary))
        : SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Form Fields
                  Card(
                    elevation: 4,
                    shadowColor: Colors.black12,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Información del Rol', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _nombreCtrl,
                            decoration: InputDecoration(
                              labelText: 'Nombre del Rol',
                              prefixIcon: const Icon(Icons.badge, color: AppTheme.adminPrimary),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                            validator: (v) => v!.isEmpty ? 'Requerido' : null,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _descCtrl,
                            decoration: InputDecoration(
                              labelText: 'Descripción',
                              prefixIcon: const Icon(Icons.description, color: AppTheme.adminPrimary),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                            maxLines: 2,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Permissions Selection
                  const Text('Permisos de Acceso', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
                  const SizedBox(height: 12),
                  Card(
                    elevation: 4,
                    shadowColor: Colors.black12,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      children: _availablePermissions.entries.map((entry) {
                        final isSelected = _selectedPermissions.contains(entry.key);
                        return CheckboxListTile(
                          title: Text(entry.value, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text('ID: ${entry.key}', style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                          value: isSelected,
                          activeColor: AppTheme.adminPrimary,
                          onChanged: (bool? val) {
                            setState(() {
                              if (val == true) _selectedPermissions.add(entry.key);
                              else _selectedPermissions.remove(entry.key);
                            });
                          },
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 32),
                  
                  // Save Button
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.adminPrimary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      onPressed: _saveRole,
                      icon: const Icon(Icons.save, color: Colors.white),
                      label: const Text('Guardar Rol', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                    ),
                  )
                ],
              ),
            ),
          ),
    );
  }

  void _saveRole() async {
    if (!_formKey.currentState!.validate()) return;
    
    final rp = context.read<RoleProvider>();
    bool ok;
    
    if (widget.role == null) {
      ok = await rp.createRole(_nombreCtrl.text, _descCtrl.text, _selectedPermissions.toList());
    } else {
      ok = await rp.updateRole(widget.role!.id, _nombreCtrl.text, _descCtrl.text, _selectedPermissions.toList());
    }

    if (ok) {
      ToastUtils.showSuccess('Rol guardado correctamente');
      if (mounted) context.pop();
    } else {
      ToastUtils.showError(rp.error ?? 'Error al guardar el rol');
    }
  }
}
