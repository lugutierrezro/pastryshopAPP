import 'package:flutter/material.dart';
import 'package:pastryshop/core/theme/app_theme.dart';

class OffersScreen extends StatelessWidget {
  const OffersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Ofertas Especiales', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.campaign, size: 80, color: AppTheme.primary.withOpacity(0.5)),
            const SizedBox(height: 16),
            const Text('¡Próximamente!', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Aquí encontrarás nuestras mejores promociones', style: TextStyle(color: Colors.grey.shade600)),
          ],
        ),
      ),
    );
  }
}
