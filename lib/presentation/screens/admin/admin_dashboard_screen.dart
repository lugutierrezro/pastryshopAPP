import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:pastryshop/core/theme/app_theme.dart';
import 'package:pastryshop/presentation/providers/order_provider.dart';
import 'package:pastryshop/presentation/providers/log_provider.dart';
import 'package:pastryshop/presentation/providers/auth_provider.dart';
import 'package:pastryshop/presentation/widgets/admin/admin_sidebar.dart';
import 'package:intl/intl.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});
  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<OrderProvider>().fetchSummary();
      context.read<OrderProvider>().fetchOrders(all: true); // For charts
      context.read<LogProvider>().loadLogs();
    });
  }

  @override
  Widget build(BuildContext context) {
    final op = context.watch<OrderProvider>();
    final summary = op.summary?['resumen'];
    final logs = context.watch<LogProvider>().logs;
    final user = context.read<AuthProvider>().user;
    
    // Chart logic
    final pendientes = int.tryParse(summary?['pendientes']?.toString() ?? '0') ?? 0;
    final listos = int.tryParse(summary?['listos']?.toString() ?? '0') ?? 0;
    final total = int.tryParse(summary?['total_pedidos']?.toString() ?? '0') ?? 0;
    final entregados = total - pendientes - listos;

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      drawer: const AdminSidebar(),
      appBar: AppBar(
        title: const Text('Panel de Control', style: TextStyle(fontWeight: FontWeight.bold)),
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppTheme.adminPrimary, AppTheme.primary],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Hola, ${user?.nombre} 👋', style: const TextStyle(fontSize: 28, color: Colors.white, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  const Text('Aquí tienes el resumen de tu negocio el día de hoy.', style: TextStyle(color: Colors.white70, fontSize: 16)),
                  const SizedBox(height: 30),
                ],
              ),
            ),
            
            // Stats Grid
            Transform.translate(
              offset: const Offset(0, -30),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    Row(
                      children: [
                        _DashboardCard(
                          title: 'Ingresos', 
                          value: NumberFormat.currency(symbol: 'S/ ').format(double.tryParse(summary?['ventas_totales']?.toString() ?? '0') ?? 0), 
                          icon: Icons.attach_money, color: Colors.green
                        ),
                        const SizedBox(width: 16),
                        _DashboardCard(title: 'Pedidos', value: '$total', icon: Icons.shopping_bag, color: Colors.blue),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        _DashboardCard(title: 'Pendientes', value: '$pendientes', icon: Icons.pending_actions, color: Colors.orange),
                        const SizedBox(width: 16),
                        _DashboardCard(title: 'Listos', value: '$listos', icon: Icons.check_circle, color: Colors.purple),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Charts Section
            if (total > 0)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Distribución de Pedidos', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.adminPrimary)),
                        const SizedBox(height: 20),
                        SizedBox(
                          height: 200,
                          child: PieChart(
                            PieChartData(
                              sectionsSpace: 2,
                              centerSpaceRadius: 40,
                              sections: [
                                PieChartSectionData(color: Colors.orange, value: pendientes.toDouble(), title: 'Pendientes', radius: 50, titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
                                PieChartSectionData(color: Colors.purple, value: listos.toDouble(), title: 'Listos', radius: 50, titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
                                PieChartSectionData(color: Colors.green, value: entregados.toDouble(), title: 'Entregados', radius: 50, titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            // Recent Activity Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Actividad Reciente', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.adminPrimary)),
                  TextButton(
                    onPressed: () => context.push('/admin/logs'),
                    child: const Text('Ver Todo', style: TextStyle(color: AppTheme.accent)),
                  )
                ],
              ),
            ),
            
            if (logs.isEmpty)
              const Center(child: Padding(padding: EdgeInsets.all(20.0), child: Text('No hay actividad reciente.')))
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: logs.length > 5 ? 5 : logs.length,
                itemBuilder: (ctx, i) {
                  final log = logs[i];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: AppTheme.adminPrimary.withOpacity(0.1), shape: BoxShape.circle),
                        child: const Icon(Icons.history, color: AppTheme.adminPrimary),
                      ),
                      title: Text(log.accion, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text('${log.modulo} • ${log.userNombre}\n${log.createdAt}'),
                      isThreeLine: true,
                    ),
                  );
                },
              ),
            
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

class _DashboardCard extends StatelessWidget {
  final String title, value;
  final IconData icon;
  final Color color;
  const _DashboardCard({required this.title, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(color: color.withOpacity(0.1), blurRadius: 15, offset: const Offset(0, 8)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 16),
            Text(title, style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.w600, fontSize: 14)),
            const SizedBox(height: 4),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(value, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: AppTheme.adminPrimary)),
            ),
          ],
        ),
      ),
    );
  }
}
