import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pastryshop/core/theme/app_theme.dart';
import 'package:pastryshop/presentation/widgets/admin/admin_sidebar.dart';
import 'package:pastryshop/data/services/api_service.dart';
import 'package:pastryshop/presentation/providers/role_provider.dart';
import 'package:pastryshop/presentation/widgets/shared/shimmer_loading.dart';
import 'package:pastryshop/core/utils/toast_utils.dart';
import 'package:pastryshop/core/constants/api_routes.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});
  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  List _users = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadUsers();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RoleProvider>().fetchRoles();
    });
  }

  Future<void> _loadUsers() async {
    setState(() => _loading = true);
    final res = await ApiService.get(ApiRoutes.users, auth: true);
    if (res['success'] == true) {
      if (mounted) setState(() { _users = res['data']; _loading = false; });
    } else {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      drawer: const AdminSidebar(),
      appBar: AppBar(
        title: const Text('Gestión de Usuarios', style: TextStyle(fontWeight: FontWeight.bold)),
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
      body: _loading
        ? const ShimmerListLoading()
        : ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _users.length,
            itemBuilder: (_, i) {
              final u = _users[i];
              final isActive = u['activo'] == 1 || u['activo'] == true;
              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                elevation: 4,
                shadowColor: Colors.black12,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 25,
                        backgroundColor: isActive ? AppTheme.adminPrimary.withOpacity(0.1) : Colors.grey.shade200,
                        child: Text(
                          u['nombre'][0].toUpperCase(),
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: isActive ? AppTheme.adminPrimary : Colors.grey),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${u['nombre']} ${u['apellido']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            const SizedBox(height: 4),
                            Text(u['email'], style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(8)),
                                  child: Text(u['rol'].toUpperCase(), style: const TextStyle(fontSize: 10, color: Colors.blue, fontWeight: FontWeight.bold)),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(color: isActive ? Colors.green.shade50 : Colors.red.shade50, borderRadius: BorderRadius.circular(8)),
                                  child: Text(isActive ? 'ACTIVO' : 'INACTIVO', style: TextStyle(fontSize: 10, color: isActive ? Colors.green : Colors.red, fontWeight: FontWeight.bold)),
                                ),
                              ],
                            )
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.manage_accounts, color: AppTheme.adminPrimary),
                        onPressed: () => _showEditModal(u),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppTheme.adminPrimary,
        onPressed: _showCreateModal,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  void _showCreateModal() {
    final nombreCtrl = TextEditingController();
    final apellidoCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final passCtrl = TextEditingController();
    int selectedRoleId = 2; // Default to Cliente

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setStateModal) {
            final roles = ctx.watch<RoleProvider>().roles;
            if (roles.isEmpty) return const SizedBox(height: 200, child: Center(child: CircularProgressIndicator()));

            return Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, left: 24, right: 24, top: 24),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Nuevo Usuario', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    TextField(controller: nombreCtrl, decoration: InputDecoration(labelText: 'Nombre', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
                    const SizedBox(height: 12),
                    TextField(controller: apellidoCtrl, decoration: InputDecoration(labelText: 'Apellido', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
                    const SizedBox(height: 12),
                    TextField(controller: emailCtrl, decoration: InputDecoration(labelText: 'Email', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
                    const SizedBox(height: 12),
                    TextField(controller: passCtrl, obscureText: true, decoration: InputDecoration(labelText: 'Contraseña temporal', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
                    const SizedBox(height: 16),
                    const Text('Rol', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(12)),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<int>(
                          isExpanded: true,
                          value: selectedRoleId,
                          items: roles.map((r) => DropdownMenuItem(value: r.id, child: Text(r.nombre))).toList(),
                          onChanged: (v) => setStateModal(() => selectedRoleId = v!),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: AppTheme.adminPrimary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                        onPressed: () async {
                          if (nombreCtrl.text.isEmpty || apellidoCtrl.text.isEmpty || emailCtrl.text.isEmpty || passCtrl.text.isEmpty) {
                            ToastUtils.showError('Completa todos los campos');
                            return;
                          }
                          Navigator.pop(ctx);
                          _createUser(nombreCtrl.text, apellidoCtrl.text, emailCtrl.text, passCtrl.text, selectedRoleId);
                        },
                        child: const Text('Crear Usuario', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            );
          }
        );
      }
    );
  }

  void _createUser(String nombre, String apellido, String email, String password, int rolId) async {
    final res = await ApiService.post(ApiRoutes.users, {
      'nombre': nombre,
      'apellido': apellido,
      'email': email,
      'password': password,
      'rol_id': rolId,
    }, auth: true);
    
    if (res['success'] == true) {
      ToastUtils.showSuccess('Usuario creado exitosamente');
      _loadUsers();
    } else {
      ToastUtils.showError(res['message'] ?? 'Error al crear usuario');
    }
  }

  void _showEditModal(Map user) {
    int? selectedRoleId;
    bool isActive = user['activo'] == 1 || user['activo'] == true;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setStateModal) {
            final roles = ctx.watch<RoleProvider>().roles;
            if (roles.isEmpty) return const SizedBox(height: 200, child: Center(child: CircularProgressIndicator()));

            if (selectedRoleId == null) {
              // Try to find current role
              try {
                selectedRoleId = roles.firstWhere((r) => r.nombre.toLowerCase() == user['rol'].toString().toLowerCase()).id;
              } catch (_) {
                selectedRoleId = roles.first.id;
              }
            }

            return Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, left: 24, right: 24, top: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Editar Usuario', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text('${user['nombre']} ${user['apellido']}', style: TextStyle(color: Colors.grey.shade600)),
                  const SizedBox(height: 24),
                  
                  const Text('Rol Asignado', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(16)),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<int>(
                        isExpanded: true,
                        value: selectedRoleId,
                        items: roles.map((r) => DropdownMenuItem(value: r.id, child: Text(r.nombre))).toList(),
                        onChanged: (v) => setStateModal(() => selectedRoleId = v),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Cuenta Activa', style: TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: const Text('Si se desactiva, el usuario no podrá iniciar sesión.'),
                    activeColor: AppTheme.adminPrimary,
                    value: isActive,
                    onChanged: (v) => setStateModal(() => isActive = v),
                  ),
                  const SizedBox(height: 24),
                  
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: AppTheme.adminPrimary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                      onPressed: () async {
                        Navigator.pop(ctx);
                        _updateUser(user['id'], selectedRoleId!, isActive);
                      },
                      child: const Text('Guardar Cambios', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            );
          }
        );
      }
    );
  }

  void _updateUser(int id, int roleId, bool isActive) async {
    final res = await ApiService.put(ApiRoutes.user('$id'), {
      'rol_id': roleId,
      'activo': isActive ? 1 : 0,
    }, auth: true);
    
    if (res['success'] == true) {
      ToastUtils.showSuccess('Usuario actualizado');
      _loadUsers();
    } else {
      ToastUtils.showError('Error al actualizar usuario');
    }
  }
}
