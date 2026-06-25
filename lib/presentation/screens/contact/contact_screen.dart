import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:pastryshop/core/theme/app_theme.dart';

// ============================================================
//  ContactScreen — P-20 a P-23
//  Dirección, teléfono, correo, mapa y redes sociales
// ============================================================
class ContactScreen extends StatelessWidget {
  const ContactScreen({super.key});

  // ── Datos de la pastelería ──────────────────────────────
  static const LatLng _storeLocation = LatLng(-12.0464, -77.0428);
  static const String _storeName     = 'La Pastelería';
  static const String _storeAddress  = 'Av. Pastelería 1234, Miraflores, Lima';
  static const String _storePhone    = '+51 999 123 456';
  static const String _storeEmail    = 'contacto@lapasteleria.pe';
  static const String _storeHours    = 'Lun – Sáb: 8:00 am – 8:00 pm\nDomingo: 9:00 am – 6:00 pm';

  static const List<_SocialLink> _socials = [
    _SocialLink(icon: Icons.facebook, label: 'Facebook',   color: Color(0xFF1877F2), url: 'https://facebook.com/lapasteleria'),
    _SocialLink(icon: Icons.camera_alt_rounded, label: 'Instagram', color: Color(0xFFE1306C), url: 'https://instagram.com/lapasteleria'),
    _SocialLink(icon: Icons.messenger_outline_rounded, label: 'WhatsApp',  color: Color(0xFF25D366), url: 'https://wa.me/51999123456?text=Hola%2C%20me%20gustar%C3%ADa%20hacer%20un%20pedido'),
    _SocialLink(icon: Icons.tiktok, label: 'TikTok',    color: Colors.black87,       url: 'https://tiktok.com/@lapasteleria'),
  ];

  Future<void> _launch(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _call() async {
    await _launch('tel:$_storePhone');
  }

  Future<void> _email() async {
    await _launch('mailto:$_storeEmail');
  }

  Future<void> _maps() async {
    await _launch('https://www.google.com/maps/search/?api=1&query=${_storeLocation.latitude},${_storeLocation.longitude}');
  }

  void _copyPhone(BuildContext ctx) {
    Clipboard.setData(const ClipboardData(text: _storePhone));
    ScaffoldMessenger.of(ctx).showSnackBar(
      const SnackBar(content: Text('Teléfono copiado 📋'), backgroundColor: AppTheme.success),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // ── SliverAppBar con mapa ──────────────────────
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            backgroundColor: AppTheme.primaryDark,
            leading: Container(
              margin: const EdgeInsets.all(8),
              decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: AppTheme.primaryDark),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              title: const Text(
                'Contáctanos',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, shadows: [Shadow(color: Colors.black45, blurRadius: 4)]),
              ),
              background: FlutterMap(
                options: const MapOptions(
                  initialCenter: _storeLocation,
                  initialZoom: 16.0,
                  interactionOptions: InteractionOptions(flags: InteractiveFlag.none),
                ),
                children: [
                  TileLayer(
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.example.pastryshop',
                  ),
                  MarkerLayer(markers: [
                    Marker(
                      point: _storeLocation,
                      width: 60, height: 60,
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppTheme.primary,
                              shape: BoxShape.circle,
                              boxShadow: [BoxShadow(color: AppTheme.primary.withOpacity(.4), blurRadius: 12, spreadRadius: 2)],
                            ),
                            child: const Icon(Icons.cake, color: Colors.white, size: 20),
                          ),
                          Container(width: 2, height: 10, color: AppTheme.primaryDark),
                        ],
                      ),
                    ),
                  ]),
                ],
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Nombre del negocio ────────────────
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [AppTheme.primary, AppTheme.primaryDark]),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(Icons.cake_rounded, color: Colors.white, size: 28),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_storeName,
                              style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w900)),
                            const SizedBox(height: 4),
                            Row(children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(color: AppTheme.success.withOpacity(.1), borderRadius: BorderRadius.circular(20)),
                                child: const Text('● Abierto', style: TextStyle(color: AppTheme.success, fontWeight: FontWeight.bold, fontSize: 12)),
                              ),
                            ]),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 28),

                  // ── Tarjetas de contacto ──────────────
                  _sectionTitle(context, '📍 Información de contacto'),
                  const SizedBox(height: 12),

                  _ContactCard(
                    icon: Icons.location_on_rounded,
                    iconColor: AppTheme.primary,
                    title: 'Dirección',
                    subtitle: _storeAddress,
                    trailing: IconButton(
                      icon: const Icon(Icons.directions_rounded, color: AppTheme.primary),
                      tooltip: 'Abrir en Maps',
                      onPressed: _maps,
                    ),
                  ),
                  const SizedBox(height: 10),

                  _ContactCard(
                    icon: Icons.phone_rounded,
                    iconColor: const Color(0xFF25D366),
                    title: 'Teléfono',
                    subtitle: _storePhone,
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(icon: const Icon(Icons.copy_rounded, size: 20), onPressed: () => _copyPhone(context)),
                        IconButton(icon: const Icon(Icons.call_rounded, color: Color(0xFF25D366)), onPressed: _call),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),

                  _ContactCard(
                    icon: Icons.email_rounded,
                    iconColor: Colors.deepOrange,
                    title: 'Correo electrónico',
                    subtitle: _storeEmail,
                    trailing: IconButton(
                      icon: const Icon(Icons.send_rounded, color: Colors.deepOrange),
                      onPressed: _email,
                    ),
                  ),
                  const SizedBox(height: 10),

                  _ContactCard(
                    icon: Icons.schedule_rounded,
                    iconColor: Colors.amber.shade700,
                    title: 'Horario de atención',
                    subtitle: _storeHours,
                  ),

                  const SizedBox(height: 28),

                  // ── Acción rápida WhatsApp ────────────
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _launch(_socials[2].url),
                      icon: const Icon(Icons.chat_bubble_rounded),
                      label: const Text('Chatear por WhatsApp', style: TextStyle(fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF25D366),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                    ),
                  ),

                  const SizedBox(height: 28),

                  // ── Redes sociales ────────────────────
                  _sectionTitle(context, '🌐 Síguenos'),
                  const SizedBox(height: 16),

                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 2.8,
                    children: _socials.map((s) => _SocialButton(social: s, onTap: () => _launch(s.url))).toList(),
                  ),

                  const SizedBox(height: 32),

                  // ── Mapa grande ───────────────────────
                  _sectionTitle(context, '🗺️ Cómo llegar'),
                  const SizedBox(height: 12),

                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: SizedBox(
                      height: 240,
                      child: FlutterMap(
                        options: const MapOptions(
                          initialCenter: _storeLocation,
                          initialZoom: 15.5,
                          interactionOptions: InteractionOptions(flags: InteractiveFlag.pinchZoom | InteractiveFlag.doubleTapZoom),
                        ),
                        children: [
                          TileLayer(
                            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                            userAgentPackageName: 'com.example.pastryshop',
                          ),
                          CircleLayer(circles: [
                            CircleMarker(
                              point: _storeLocation,
                              radius: 80,
                              color: AppTheme.primary.withOpacity(.15),
                              borderColor: AppTheme.primary,
                              borderStrokeWidth: 2,
                              useRadiusInMeter: true,
                            ),
                          ]),
                          MarkerLayer(markers: [
                            Marker(
                              point: _storeLocation,
                              width: 56, height: 56,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: AppTheme.primary,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 3),
                                  boxShadow: [BoxShadow(color: AppTheme.primary.withOpacity(.5), blurRadius: 10)],
                                ),
                                child: const Icon(Icons.cake, color: Colors.white, size: 22),
                              ),
                            ),
                          ]),
                        ],
                      ),
                    ),
                  ),

                  // Botón "Abrir en Maps"
                  const SizedBox(height: 12),
                  Center(
                    child: OutlinedButton.icon(
                      onPressed: _maps,
                      icon: const Icon(Icons.map_rounded),
                      label: const Text('Abrir en Google Maps'),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppTheme.primary),
                        foregroundColor: AppTheme.primary,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(BuildContext context, String text) => Text(
    text,
    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
  );
}

// ── Widgets helpers ───────────────────────────────────────────

class _ContactCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final Widget? trailing;

  const _ContactCard({
    required this.icon, required this.iconColor,
    required this.title, required this.subtitle, this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: iconColor.withOpacity(.12), shape: BoxShape.circle),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey)),
                const SizedBox(height: 2),
                Text(subtitle, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

class _SocialLink {
  final IconData icon;
  final String label;
  final Color color;
  final String url;
  const _SocialLink({required this.icon, required this.label, required this.color, required this.url});
}

class _SocialButton extends StatelessWidget {
  final _SocialLink social;
  final VoidCallback onTap;
  const _SocialButton({required this.social, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: social.color.withOpacity(.1),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: social.color.withOpacity(.25)),
        ),
        child: Row(
          children: [
            Icon(social.icon, color: social.color, size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                social.label,
                style: TextStyle(fontWeight: FontWeight.bold, color: social.color, fontSize: 13),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Icon(Icons.open_in_new_rounded, color: social.color.withOpacity(.5), size: 14),
          ],
        ),
      ),
    );
  }
}
