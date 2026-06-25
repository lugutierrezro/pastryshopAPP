import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:pastryshop/core/theme/app_theme.dart';
import 'package:pastryshop/presentation/providers/auth_provider.dart';
import 'package:pastryshop/presentation/providers/cart_provider.dart';
import 'package:pastryshop/presentation/providers/order_provider.dart';
import 'package:pastryshop/domain/entities/entities.dart';

// ============================================================
//  CheckoutScreen
// ============================================================
class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});
  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _formKey   = GlobalKey<FormState>();
  String _tipo     = 'tienda';
  final _dirCtrl   = TextEditingController();
  final _notasCtrl = TextEditingController();
  
  // Customer Data Controllers (P-10)
  final _nombreCtrl = TextEditingController();
  final _apellidoCtrl = TextEditingController();
  final _telefonoCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();

  String _tipoComprobante = 'boleta';
  final _docCtrl = TextEditingController();
  
  // Map State
  final MapController _mapCtrl = MapController();
  LatLng _selectedLocation = const LatLng(-12.0464, -77.0428); // Lima
  bool _isLoadingAddress = false;

  // Autocomplete State
  List<dynamic> _addressSuggestions = [];
  bool _isSearchingAddress = false;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      if (!auth.isLoggedIn) {
        context.pushReplacement('/login');
      } else {
        final u = auth.user!;
        _nombreCtrl.text = u.nombre;
        _apellidoCtrl.text = u.apellido;
        _telefonoCtrl.text = u.telefono;
        _emailCtrl.text = u.email;
      }
      
      final cart = context.read<CartProvider>();
      if (cart.customNotes != null) {
        _notasCtrl.text = cart.customNotes!;
      }
    });
  }

  @override
  void dispose() {
    _dirCtrl.dispose();
    _notasCtrl.dispose();
    _nombreCtrl.dispose();
    _apellidoCtrl.dispose();
    _telefonoCtrl.dispose();
    _emailCtrl.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onAddressChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _searchAddress(query);
    });
  }

  Future<void> _searchAddress(String query) async {
    if (query.trim().length < 3) {
      setState(() => _addressSuggestions = []);
      return;
    }
    setState(() => _isSearchingAddress = true);
    try {
      final url = Uri.parse('https://nominatim.openstreetmap.org/search?format=json&q=${Uri.encodeComponent(query)}&limit=5');
      final response = await http.get(url, headers: {'User-Agent': 'PastryShopApp/1.0'});
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data is List) {
          setState(() {
            _addressSuggestions = data;
          });
        }
      }
    } catch (_) {
      // Ignore
    } finally {
      if (mounted) setState(() => _isSearchingAddress = false);
    }
  }

  void _selectSuggestion(dynamic suggestion) {
    final lat = double.tryParse(suggestion['lat'].toString()) ?? -12.0464;
    final lon = double.tryParse(suggestion['lon'].toString()) ?? -77.0428;
    final displayName = suggestion['display_name'] ?? '';
    
    setState(() {
      _selectedLocation = LatLng(lat, lon);
      _dirCtrl.text = displayName;
      _addressSuggestions = [];
    });
    _mapCtrl.move(_selectedLocation, 15.0);
  }

  Future<void> _getAddressFromLatLng(LatLng pos) async {
    setState(() {
      _selectedLocation = pos;
      _isLoadingAddress = true;
    });
    try {
      final url = Uri.parse('https://nominatim.openstreetmap.org/reverse?format=json&lat=${pos.latitude}&lon=${pos.longitude}');
      final response = await http.get(url, headers: {'User-Agent': 'PastryShopApp/1.0'});
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['display_name'] != null) {
          setState(() {
            _dirCtrl.text = data['display_name'];
          });
        }
      }
    } catch (_) {
      // Ignore
    } finally {
      if (mounted) setState(() => _isLoadingAddress = false);
    }
  }

  void _showPaymentGateway() {
    if (!_formKey.currentState!.validate()) return;
    if (_tipo == 'domicilio' && _dirCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Por favor, ingresa tu dirección'), backgroundColor: AppTheme.error));
      return;
    }
    if (_tipoComprobante == 'factura' && _docCtrl.text.trim().length != 11) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Por favor, ingresa un RUC válido (11 dígitos)'), backgroundColor: AppTheme.error));
      return;
    }
    if (_tipoComprobante == 'boleta' && _docCtrl.text.trim().isNotEmpty && _docCtrl.text.trim().length != 8) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Por favor, ingresa un DNI válido (8 dígitos)'), backgroundColor: AppTheme.error));
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _MockPaymentGateway(
        total: context.read<CartProvider>().total,
        onSuccess: () {
          Navigator.pop(ctx);
          _placeOrder();
        },
      ),
    );
  }

  Future<void> _placeOrder() async {
    final auth   = context.read<AuthProvider>();
    final orders = context.read<OrderProvider>();
    final cart   = context.read<CartProvider>();

    // Update profile if details changed (P-10)
    final u = auth.user;
    if (u != null) {
      final newNombre   = _nombreCtrl.text.trim();
      final newApellido = _apellidoCtrl.text.trim();
      final newTelefono = _telefonoCtrl.text.trim();
      if (newNombre != u.nombre || newApellido != u.apellido || newTelefono != u.telefono) {
        await auth.updateProfile({
          'nombre': newNombre,
          'apellido': newApellido,
          'telefono': newTelefono,
        });
      }
    }

    final orderId = await orders.placeOrder(
      tipoEntrega: _tipo,
      direccionEntrega: _tipo == 'domicilio' ? _dirCtrl.text.trim() : null,
      notas: _notasCtrl.text.trim().isEmpty ? null : _notasCtrl.text.trim(),
      tipoComprobante: _tipoComprobante,
      documentoCliente: _docCtrl.text.trim(),
    );
    if (!mounted) return;
    if (orderId != null) {
      cart.clearLocal();
      // Find the placed order or construct a fallback entity representing it
      final placedOrder = orders.orders.firstWhere(
        (o) => o.id == orderId,
        orElse: () => OrderEntity(
          id: orderId,
          userId: u?.id ?? 0,
          cliente: u?.fullName ?? '',
          email: u?.email ?? '',
          telefono: _telefonoCtrl.text.trim(),
          estado: 'pendiente',
          total: cart.total,
          tipoEntrega: _tipo,
          direccionEntrega: _tipo == 'domicilio' ? _dirCtrl.text.trim() : '',
          notas: _notasCtrl.text.trim(),
          tipoComprobante: _tipoComprobante,
          documentoCliente: _docCtrl.text.trim(),
          createdAt: DateTime.now().toIso8601String(),
        ),
      );
      context.pushReplacement('/payment-success', extra: placedOrder);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(orders.error ?? 'Error'), backgroundColor: AppTheme.error),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart   = context.watch<CartProvider>();
    final orders = context.watch<OrderProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Confirmar Pedido'),
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios), onPressed: () => context.pop()),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Order summary
              Text('Resumen del pedido', style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 12),
              ...cart.items.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(item.imagenUrl, width: 48, height: 48, fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(width: 48, height: 48, color: AppTheme.secondary)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: Text('${item.nombre} × ${item.cantidad}')),
                    Text('S/ ${item.subtotal.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.w600)),
                  ],
                ),
              )),
              const Divider(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Total', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  Text('S/ ${cart.total.toStringAsFixed(2)}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: AppTheme.primary)),
                ],
              ),
              const SizedBox(height: 28),
              Text('Datos del Cliente', style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _nombreCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Nombre',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                      validator: (v) => v == null || v.trim().isEmpty ? 'Requerido' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _apellidoCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Apellido',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                      validator: (v) => v == null || v.trim().isEmpty ? 'Requerido' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailCtrl,
                decoration: const InputDecoration(
                  labelText: 'Correo Electrónico',
                  prefixIcon: Icon(Icons.email_outlined),
                ),
                readOnly: true,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _telefonoCtrl,
                decoration: const InputDecoration(
                  labelText: 'Teléfono',
                  prefixIcon: Icon(Icons.phone_outlined),
                ),
                keyboardType: TextInputType.phone,
                validator: (v) => v == null || v.trim().isEmpty ? 'Requerido' : null,
              ),
              const SizedBox(height: 28),

              // Delivery type
              Text('Tipo de entrega', style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 12),
              Row(children: [
                _DeliveryOption(label: '🏪 En tienda', value: 'tienda',  group: _tipo, onChanged: (v) => setState(() => _tipo = v!)),
                const SizedBox(width: 12),
                _DeliveryOption(label: '🛵 Domicilio', value: 'domicilio', group: _tipo, onChanged: (v) => setState(() => _tipo = v!)),
              ]),

              if (_tipo == 'domicilio') ...[
                const SizedBox(height: 16),
                const Text('Escribe tu dirección para buscarla:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _dirCtrl,
                  decoration: InputDecoration(
                    labelText: 'Dirección de entrega',
                    prefixIcon: const Icon(Icons.location_on_outlined),
                    suffixIcon: _isSearchingAddress
                        ? const SizedBox(width: 20, height: 20, child: Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator(strokeWidth: 2)))
                        : (_dirCtrl.text.isNotEmpty ? IconButton(icon: const Icon(Icons.clear), onPressed: () => setState(() { _dirCtrl.clear(); _addressSuggestions = []; })) : null),
                  ),
                  onChanged: _onAddressChanged,
                  validator: (v) => _tipo == 'domicilio' && (v == null || v.isEmpty) ? 'Ingresa o selecciona una dirección' : null,
                ),
                if (_addressSuggestions.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(top: 8, bottom: 8),
                    constraints: const BoxConstraints(maxHeight: 200),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 10)],
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: _addressSuggestions.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final item = _addressSuggestions[index];
                        return ListTile(
                          leading: const Icon(Icons.location_on, color: AppTheme.primaryDark),
                          title: Text(item['display_name'] ?? '', style: const TextStyle(fontSize: 13)),
                          onTap: () => _selectSuggestion(item),
                        );
                      },
                    ),
                  ),
                const SizedBox(height: 16),
                const Text('Confirma la ubicación en el mapa (puedes mover el pin tocando el mapa):', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 8),
                Container(
                  height: 200,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.divider),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Stack(
                    children: [
                      FlutterMap(
                        mapController: _mapCtrl,
                        options: MapOptions(
                          initialCenter: _selectedLocation,
                          initialZoom: 15.0,
                          onTap: (_, pos) => _getAddressFromLatLng(pos),
                        ),
                        children: [
                          TileLayer(
                            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                            userAgentPackageName: 'com.example.pastryshop',
                          ),
                          MarkerLayer(
                            markers: [
                              Marker(
                                point: _selectedLocation,
                                width: 40, height: 40,
                                child: const Icon(Icons.location_pin, color: AppTheme.primaryDark, size: 40),
                              ),
                            ],
                          ),
                        ],
                      ),
                      if (_isLoadingAddress)
                        const Center(child: CircularProgressIndicator()),
                      Positioned(
                        bottom: 8, right: 8,
                        child: FloatingActionButton.small(
                          heroTag: 'map_btn',
                          backgroundColor: Colors.white,
                          child: const Icon(Icons.my_location, color: AppTheme.primaryDark),
                          onPressed: () {
                            _mapCtrl.move(const LatLng(-12.0464, -77.0428), 15);
                          },
                        ),
                      )
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 16),
              TextFormField(
                controller: _notasCtrl,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Notas adicionales (opcional)',
                  hintText: 'Sin azúcar, sin gluten, mensaje especial...',
                  prefixIcon: Icon(Icons.note_outlined),
                ),
              ),

              const SizedBox(height: 28),
              Text('Comprobante de Pago', style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 12),
              Row(children: [
                _DeliveryOption(label: '🧾 Boleta', value: 'boleta', group: _tipoComprobante, onChanged: (v) => setState(() { _tipoComprobante = v!; _docCtrl.clear(); })),
                const SizedBox(width: 12),
                _DeliveryOption(label: '🏢 Factura', value: 'factura', group: _tipoComprobante, onChanged: (v) => setState(() { _tipoComprobante = v!; _docCtrl.clear(); })),
              ]),
              const SizedBox(height: 16),
              TextFormField(
                controller: _docCtrl,
                decoration: InputDecoration(
                  labelText: _tipoComprobante == 'boleta' ? 'DNI (opcional)' : 'RUC (Requerido)',
                  prefixIcon: const Icon(Icons.badge_outlined),
                ),
                keyboardType: TextInputType.number,
                maxLength: _tipoComprobante == 'boleta' ? 8 : 11,
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: orders.loading ? null : _showPaymentGateway,
                  icon: orders.loading
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.payment),
                  label: const Text('Ir al Pago'),
                  style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DeliveryOption extends StatelessWidget {
  final String label, value, group;
  final ValueChanged<String?> onChanged;
  const _DeliveryOption({required this.label, required this.value, required this.group, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final selected = group == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => onChanged(value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: selected ? AppTheme.primaryLight.withOpacity(0.2) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: selected ? AppTheme.primary : AppTheme.divider, width: selected ? 2 : 1),
          ),
          child: Center(
            child: Text(label, style: TextStyle(fontWeight: selected ? FontWeight.bold : FontWeight.normal, color: selected ? AppTheme.primaryDark : Colors.black87)),
          ),
        ),
      ),
    );
  }
}

class _MockPaymentGateway extends StatefulWidget {
  final double total;
  final VoidCallback onSuccess;
  const _MockPaymentGateway({required this.total, required this.onSuccess});

  @override
  State<_MockPaymentGateway> createState() => _MockPaymentGatewayState();
}

class _MockPaymentGatewayState extends State<_MockPaymentGateway> {
  bool _isProcessing = false;
  final _formKey = GlobalKey<FormState>();

  void _processPayment() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isProcessing = true);
    
    // Simular procesamiento del banco/pasarela
    await Future.delayed(const Duration(seconds: 2));
    
    if (!mounted) return;
    setState(() => _isProcessing = false);
    widget.onSuccess();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      padding: EdgeInsets.only(
        top: 24, left: 24, right: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Pago Seguro', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                Image.network('https://upload.wikimedia.org/wikipedia/commons/thumb/5/5e/Visa_Inc._logo.svg/2560px-Visa_Inc._logo.svg.png', width: 40, errorBuilder: (_,__,___) => const SizedBox()),
              ],
            ),
            const SizedBox(height: 8),
            Text('Total a pagar: S/ ${widget.total.toStringAsFixed(2)}', style: const TextStyle(fontSize: 18, color: AppTheme.primary, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            
            TextFormField(
              decoration: InputDecoration(
                labelText: 'Número de Tarjeta',
                hintText: '0000 0000 0000 0000',
                prefixIcon: const Icon(Icons.credit_card),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              keyboardType: TextInputType.number,
              maxLength: 16,
              validator: (v) => v!.length < 16 ? 'Ingresa una tarjeta válida' : null,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    decoration: InputDecoration(
                      labelText: 'Vencimiento',
                      hintText: 'MM/YY',
                      prefixIcon: const Icon(Icons.date_range),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    maxLength: 5,
                    validator: (v) => v!.isEmpty ? 'Requerido' : null,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    decoration: InputDecoration(
                      labelText: 'CVV',
                      hintText: '123',
                      prefixIcon: const Icon(Icons.security),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    keyboardType: TextInputType.number,
                    maxLength: 3,
                    obscureText: true,
                    validator: (v) => v!.isEmpty ? 'Requerido' : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              decoration: InputDecoration(
                labelText: 'Nombre del Titular',
                prefixIcon: const Icon(Icons.person_outline),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              validator: (v) => v!.isEmpty ? 'Ingresa el nombre' : null,
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isProcessing ? null : _processPayment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: _isProcessing
                  ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : Text('Pagar S/ ${widget.total.toStringAsFixed(2)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
