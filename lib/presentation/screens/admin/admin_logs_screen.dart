import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pastryshop/presentation/providers/log_provider.dart';
import 'package:pastryshop/presentation/widgets/admin/admin_sidebar.dart';
import 'package:pastryshop/presentation/widgets/shared/shimmer_loading.dart';

class AdminLogsScreen extends StatefulWidget {
  const AdminLogsScreen({Key? key}) : super(key: key);

  @override
  State<AdminLogsScreen> createState() => _AdminLogsScreenState();
}

class _AdminLogsScreenState extends State<AdminLogsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LogProvider>().loadLogs();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Registro de Actividad (Logs)'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => context.read<LogProvider>().loadLogs(),
          ),
        ],
      ),
      drawer: const AdminSidebar(),
      body: Consumer<LogProvider>(
        builder: (context, provider, child) {
          if (provider.loading) {
            return const ShimmerListLoading();
          }

          if (provider.error != null) {
            return Center(child: Text(provider.error!, style: const TextStyle(color: Colors.red)));
          }

          if (provider.logs.isEmpty) {
            return const Center(child: Text('No hay registros de actividad.'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: provider.logs.length,
            itemBuilder: (context, index) {
              final log = provider.logs[index];
              return Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.blueAccent.withOpacity(0.2),
                    child: const Icon(Icons.history, color: Colors.blueAccent),
                  ),
                  title: Text(log.descripcion, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text('Módulo: ${log.modulo} | Acción: ${log.accion}'),
                      Text('Usuario: ${log.userNombre} (${log.userEmail})'),
                      Text('Fecha: ${log.createdAt}'),
                    ],
                  ),
                  isThreeLine: true,
                ),
              );
            },
          );
        },
      ),
    );
  }
}
