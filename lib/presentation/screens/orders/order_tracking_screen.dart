import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:pastryshop/core/theme/app_theme.dart';
import 'package:pastryshop/domain/entities/entities.dart';

// ============================================================
//  OrderTrackingScreen — P-17, P-18, P-19
//  Tracking simulado con ruta animada del repartidor
// ============================================================
class OrderTrackingScreen extends StatefulWidget {
  final OrderEntity order;
  const OrderTrackingScreen({super.key, required this.order});

  @override
  State<OrderTrackingScreen> createState() => _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends State<OrderTrackingScreen>
    with TickerProviderStateMixin {

  final MapController _mapCtrl = MapController();

  // Pastelería (origen)
  static const LatLng _store = LatLng(-12.0464, -77.0428);

  // Destino (derivado de la dirección — usamos offset simulado)
  late final LatLng _destination;

  // Posición actual del repartidor (animada)
  late LatLng _riderPos;
  int _routeStep = 0;
  late List<LatLng> _route;

  Timer? _timer;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  // ETA simulado (en minutos)
  int _etaMinutes = 20;

  // Estados del delivery
  static const List<_TrackStep> _steps = [
    _TrackStep('Pedido confirmado',     Icons.receipt_long_rounded,    AppTheme.primary),
    _TrackStep('Preparando tu pedido',  Icons.soup_kitchen_rounded,    Colors.orange),
    _TrackStep('Repartidor en camino',  Icons.delivery_dining_rounded, Colors.blue),
    _TrackStep('¡Pedido entregado!',    Icons.done_all_rounded,        AppTheme.success),
  ];

  int _currentStep = 2; // en camino (ya salió)

  @override
  void initState() {
    super.initState();

    // Destino simulado basado en store + offset aleatorio pequeño
    _destination = LatLng(_store.latitude - 0.018, _store.longitude + 0.022);

    // Ruta de 12 puntos del repartidor: de store → destination
    _route = _interpolateRoute(_store, _destination, 12);
    _riderPos = _route[0];

    // Animación de pulso para el marcador del repartidor
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Mover repartidor cada 3 segundos
    _timer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (!mounted) return;
      setState(() {
        if (_routeStep < _route.length - 1) {
          _routeStep++;
          _riderPos = _route[_routeStep];
          _etaMinutes = (((_route.length - 1 - _routeStep) / (_route.length - 1)) * 20).round();

          // Actualizar mapa para centrar entre repartidor y destino
          final midLat = (_riderPos.latitude  + _destination.latitude)  / 2;
          final midLon = (_riderPos.longitude + _destination.longitude) / 2;
          _mapCtrl.move(LatLng(midLat, midLon), 14.5);
        } else {
          // Llegó
          _currentStep = 3;
          _etaMinutes  = 0;
          _timer?.cancel();
        }
      });
    });
  }

  List<LatLng> _interpolateRoute(LatLng from, LatLng to, int steps) {
    return List.generate(steps, (i) {
      final t = i / (steps - 1);
      // Añadir pequeñas curvas para simular una ruta real
      final curve = (i % 3 == 1) ? 0.003 : (i % 3 == 2) ? -0.002 : 0.0;
      return LatLng(
        from.latitude  + (to.latitude  - from.latitude)  * t + curve,
        from.longitude + (to.longitude - from.longitude) * t + (curve * 0.5),
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool delivered = _currentStep == 3;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
          child: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppTheme.primaryDark),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        title: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(.1), blurRadius: 8)],
          ),
          child: Text(
            delivered ? '¡Pedido Entregado! 🎉' : 'Pedido en camino 🛵',
            style: const TextStyle(color: AppTheme.primaryDark, fontWeight: FontWeight.bold, fontSize: 15),
          ),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          // ── Mapa con ruta animada ─────────────────────
          FlutterMap(
            mapController: _mapCtrl,
            options: MapOptions(
              initialCenter: LatLng(
                (_store.latitude + _destination.latitude) / 2,
                (_store.longitude + _destination.longitude) / 2,
              ),
              initialZoom: 14.5,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.pinchZoom | InteractiveFlag.doubleTapZoom | InteractiveFlag.drag,
              ),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.pastryshop',
              ),

              // Ruta completa (gris, punteada)
              PolylineLayer(polylines: [
                Polyline<Object>(
                  points: _route,
                  color: Colors.grey.shade300,
                  strokeWidth: 5,
                ),
                // Ruta ya recorrida (coloreada)
                Polyline<Object>(
                  points: _route.sublist(0, _routeStep + 1),
                  color: AppTheme.primary,
                  strokeWidth: 5,
                ),
              ]),

              MarkerLayer(markers: [
                // Pastelería (origen)
                Marker(
                  point: _store,
                  width: 54, height: 54,
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppTheme.primaryDark,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                      boxShadow: [BoxShadow(color: AppTheme.primaryDark.withOpacity(.4), blurRadius: 10)],
                    ),
                    child: const Icon(Icons.storefront_rounded, color: Colors.white, size: 22),
                  ),
                ),

                // Destino (cliente)
                Marker(
                  point: _destination,
                  width: 54, height: 54,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppTheme.primary, width: 3),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(.2), blurRadius: 8)],
                    ),
                    child: const Icon(Icons.home_rounded, color: AppTheme.primary, size: 22),
                  ),
                ),

                // Repartidor (animado)
                Marker(
                  point: _riderPos,
                  width: 56, height: 56,
                  child: AnimatedBuilder(
                    animation: _pulseAnimation,
                    builder: (_, child) => Transform.scale(
                      scale: delivered ? 1.0 : _pulseAnimation.value,
                      child: child,
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        color: delivered ? AppTheme.success : Colors.blue,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                        boxShadow: [BoxShadow(
                          color: (delivered ? AppTheme.success : Colors.blue).withOpacity(.5),
                          blurRadius: 12, spreadRadius: 2,
                        )],
                      ),
                      child: Icon(
                        delivered ? Icons.done_all_rounded : Icons.delivery_dining_rounded,
                        color: Colors.white, size: 22,
                      ),
                    ),
                  ),
                ),
              ]),
            ],
          ),

          // ── Panel inferior ────────────────────────────
          Positioned(
            left: 0, right: 0, bottom: 0,
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 20)],
              ),
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Handle
                  Container(
                    width: 36, height: 4,
                    decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
                  ),
                  const SizedBox(height: 20),

                  // ETA
                  if (!delivered) ...[
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(.1),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(Icons.timer_outlined, color: Colors.blue, size: 28),
                        ),
                        const SizedBox(width: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Tiempo estimado de entrega', style: TextStyle(color: Colors.grey, fontSize: 13)),
                            Text(
                              '$_etaMinutes min',
                              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: AppTheme.primaryDark),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                  ] else ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.success.withOpacity(.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppTheme.success.withOpacity(.3)),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.check_circle_rounded, color: AppTheme.success, size: 32),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              '¡Tu pedido ha sido entregado! 🎉\n¿Disfrutaste tus postres?',
                              style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.success),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Stepper horizontal
                  Row(
                    children: _steps.asMap().entries.map((e) {
                      final i = e.key;
                      final s = e.value;
                      final isDone    = i < _currentStep;
                      final isCurrent = i == _currentStep;
                      final isLast    = i == _steps.length - 1;

                      return Expanded(
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                children: [
                                  Container(
                                    width: 36, height: 36,
                                    decoration: BoxDecoration(
                                      color: isDone || isCurrent ? s.color : Colors.grey.shade200,
                                      shape: BoxShape.circle,
                                      boxShadow: isCurrent ? [BoxShadow(color: s.color.withOpacity(.4), blurRadius: 8)] : null,
                                    ),
                                    child: Icon(s.icon, color: isDone || isCurrent ? Colors.white : Colors.grey, size: 16),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    s.label,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                                      color: isDone || isCurrent ? AppTheme.onBackground : Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (!isLast)
                              Expanded(
                                child: Container(
                                  height: 2,
                                  margin: const EdgeInsets.only(bottom: 24),
                                  color: isDone ? AppTheme.primary : Colors.grey.shade200,
                                ),
                              ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 20),

                  // Repartidor info
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 22,
                          backgroundColor: AppTheme.primary.withOpacity(.15),
                          child: const Text('JR', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primary)),
                        ),
                        const SizedBox(width: 14),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Juan Rodríguez', style: TextStyle(fontWeight: FontWeight.bold)),
                              Text('Tu repartidor • ⭐ 4.9', style: TextStyle(fontSize: 12, color: Colors.grey)),
                            ],
                          ),
                        ),
                        CircleAvatar(
                          backgroundColor: Colors.green.shade50,
                          child: const Icon(Icons.call_rounded, color: Colors.green),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TrackStep {
  final String label;
  final IconData icon;
  final Color color;
  const _TrackStep(this.label, this.icon, this.color);
}
