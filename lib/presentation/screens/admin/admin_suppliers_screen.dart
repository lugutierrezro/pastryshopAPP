import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:pastryshop/core/theme/app_theme.dart';
import 'package:pastryshop/presentation/providers/supplier_provider.dart';
import 'package:pastryshop/presentation/widgets/admin/admin_sidebar.dart';
import 'package:pastryshop/presentation/widgets/shared/shimmer_loading.dart';
import 'package:pastryshop/core/utils/toast_utils.dart';

class AdminSuppliersScreen extends StatefulWidget {
  const AdminSuppliersScreen({super.key});
  @override
  State<AdminSuppliersScreen> createState() => _AdminSuppliersScreenState();
}

class _AdminSuppliersScreenState extends State<AdminSuppliersScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => context.read<SupplierProvider>().loadSuppliers());
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SupplierProvider>();

    return Scaffold(
      backgroundColor: AppTheme.background,
      drawer: const AdminSidebar(),
      appBar: AppBar(
        title: const Text('Directorio de Proveedores', style: TextStyle(fontWeight: FontWeight.bold)),
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
      body: provider.loading
        ? const ShimmerListLoading()
        : provider.suppliers.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.contact_phone_outlined, size: 80, color: Colors.grey.shade300),
                    const SizedBox(height: 16),
                    Text('No hay proveedores registrados', style: TextStyle(color: Colors.grey.shade500, fontSize: 18)),
                  ],
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: provider.suppliers.length,
                itemBuilder: (_, i) {
                  final s = provider.suppliers[i];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 16),
                    elevation: 3,
                    shadowColor: Colors.black12,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 24,
                                backgroundColor: AppTheme.adminPrimary.withOpacity(0.1),
                                child: Text(
                                  s.empresa.isNotEmpty ? s.empresa[0].toUpperCase() : 'P',
                                  style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.adminPrimary, fontSize: 20),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(s.empresa, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                                    Text(s.nombre, style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: s.activo ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  s.activo ? 'ACTIVO' : 'INACTIVO',
                                  style: TextStyle(color: s.activo ? Colors.green : Colors.red, fontWeight: FontWeight.bold, fontSize: 10),
                                ),
                              )
                            ],
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 12),
                            child: Divider(height: 1),
                          ),
                          Row(
                            children: [
                              Icon(Icons.phone, size: 16, color: Colors.grey.shade500),
                              const SizedBox(width: 8),
                              Text(s.telefono, style: const TextStyle(fontSize: 14)),
                              const SizedBox(width: 20),
                              Icon(Icons.email, size: 16, color: Colors.grey.shade500),
                              const SizedBox(width: 8),
                              Expanded(child: Text(s.email, style: const TextStyle(fontSize: 14), overflow: TextOverflow.ellipsis)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Row(
                                  children: [
                                    Icon(Icons.location_on, size: 16, color: Colors.grey.shade500),
                                    const SizedBox(width: 8),
                                    Expanded(child: Text(s.direccion, style: const TextStyle(fontSize: 14), overflow: TextOverflow.ellipsis)),
                                  ],
                                ),
                              ),
                              Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit_outlined, color: Colors.blue),
                                    tooltip: 'Editar',
                                    onPressed: () => context.push('/admin/suppliers/${s.id}'),
                                  ),
                                ],
                              )
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppTheme.adminPrimary,
        onPressed: () => context.push('/admin/suppliers/new'),
        icon: const Icon(Icons.add_business, color: Colors.white),
        label: const Text('Nuevo Proveedor', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }
}
