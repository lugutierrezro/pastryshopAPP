import 'package:flutter/material.dart';
import 'package:pastryshop/core/theme/app_theme.dart';
import 'package:pastryshop/data/services/api_service.dart';

// ============================================================
//  AdminUsersScreen
// ============================================================
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
  }

  Future<void> _loadUsers() async {
    final res = await ApiService.get('users', auth: true);
    if (res['success'] == true) {
      if (mounted) setState(() { _users = res['data']; _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de Usuarios'),
        backgroundColor: AppTheme.adminPrimary,
        foregroundColor: Colors.white,
      ),
      body: _loading
        ? const Center(child: CircularProgressIndicator())
        : ListView.builder(
            itemCount: _users.length,
            itemBuilder: (_, i) {
              final u = _users[i];
              return ListTile(
                leading: CircleAvatar(child: Text(u['rol'][0].toUpperCase())),
                title: Text('${u['nombre']} ${u['apellido']}'),
                subtitle: Text('${u['email']}\nRol: ${u['rol']} - Activo: ${u['activo'] == 1 ? "Sí" : "No"}'),
                isThreeLine: true,
                trailing: IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () => _editRole(u['id'], u['rol']),
                ),
              );
            },
          ),
    );
  }

  void _editRole(int id, String currentRole) {
    // Mostrar modal para cambiar rol
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Edición de roles en desarrollo')));
  }
}
