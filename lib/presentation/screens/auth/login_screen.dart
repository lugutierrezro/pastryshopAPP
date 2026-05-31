import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:pastryshop/core/theme/app_theme.dart';
import 'package:pastryshop/presentation/providers/auth_provider.dart';
import 'package:pastryshop/presentation/providers/cart_provider.dart';

// ============================================================
//  LoginScreen — Pantalla unificada de login
// ============================================================
class LoginScreen extends StatefulWidget {
  final bool fromCheckout;
  const LoginScreen({super.key, this.fromCheckout = false});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  final _formKey   = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl  = TextEditingController();
  bool _obscure    = true;
  late AnimationController _animCtrl;
  late Animation<double>   _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _emailCtrl.dispose(); _passCtrl.dispose(); _animCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    final ok   = await auth.login(_emailCtrl.text.trim(), _passCtrl.text);
    if (!mounted) return;
    if (ok) {
      // Load cart after login
      await context.read<CartProvider>().fetchCart();
      // Navigate based on role
      if (auth.isAdmin)    { context.go('/admin');    return; }
      if (auth.isEmpleado) { context.go('/employee'); return; }
      context.go('/');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(auth.error ?? 'Error'), backgroundColor: AppTheme.error),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      body: Stack(
        children: [
          // Background gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppTheme.primary, AppTheme.accent],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          // White card
          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: Column(
                children: [
                  // Minimal header
                  const SizedBox(height: 64),

                  // Card
                  Expanded(
                    child: Container(
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                      ),
                      padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
                      child: SingleChildScrollView(
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // App Logo Placeholder
                              Center(
                                child: Column(
                                  children: [
                                    Image.asset(
                                      'assets/images/logo.png',
                                      width: 100,
                                      height: 100,
                                      errorBuilder: (ctx, err, stack) => const Icon(Icons.cake, size: 80, color: AppTheme.primary),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'THE',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 2,
                                        color: AppTheme.onBackground,
                                      ),
                                    ),
                                    Text(
                                      'PASTRYSHOP',
                                      style: TextStyle(
                                        fontSize: 28,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 3,
                                        color: AppTheme.onBackground,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 48),

                              Text('Bienvenido/a', style: Theme.of(context).textTheme.headlineMedium),
                              const SizedBox(height: 4),
                              Text('Admin, empleado o cliente — mismo acceso',
                                style: Theme.of(context).textTheme.bodyMedium),

                              const SizedBox(height: 28),

                              // Email
                              TextFormField(
                                controller: _emailCtrl,
                                keyboardType: TextInputType.emailAddress,
                                decoration: const InputDecoration(
                                  labelText: 'Correo electrónico',
                                  prefixIcon: Icon(Icons.email_outlined),
                                ),
                                validator: (v) => v == null || !v.contains('@') ? 'Email inválido' : null,
                              ),
                              const SizedBox(height: 16),

                              // Password
                              TextFormField(
                                controller: _passCtrl,
                                obscureText: _obscure,
                                decoration: InputDecoration(
                                  labelText: 'Contraseña',
                                  prefixIcon: const Icon(Icons.lock_outline),
                                  suffixIcon: IconButton(
                                    icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility),
                                    onPressed: () => setState(() => _obscure = !_obscure),
                                  ),
                                ),
                                validator: (v) => v == null || v.length < 6 ? 'Mínimo 6 caracteres' : null,
                              ),
                              const SizedBox(height: 28),

                              // Login button
                              ElevatedButton(
                                onPressed: auth.loading ? null : _login,
                                child: auth.loading
                                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                  : const Text('Iniciar sesión'),
                              ),

                              const SizedBox(height: 16),

                              // Register link
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Text('¿No tienes cuenta? '),
                                  GestureDetector(
                                    onTap: () => context.pushReplacement('/register'),
                                    child: const Text('Regístrate', style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold)),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 16),

                              // Google Auth Button
                              OutlinedButton.icon(
                                onPressed: auth.loading ? null : () async {
                                  final ok = await auth.signInWithGoogle();
                                  if (ok && mounted) {
                                    await context.read<CartProvider>().fetchCart();
                                    if (auth.isAdmin) { context.go('/admin'); return; }
                                    if (auth.isEmpleado) { context.go('/employee'); return; }
                                    context.go('/');
                                  } else if (!ok && mounted && auth.error != null) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text(auth.error!), backgroundColor: AppTheme.error),
                                    );
                                  }
                                },
                                icon: Container(
                                  width: 24, height: 24,
                                  decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                                  alignment: Alignment.center,
                                  child: const Text('G', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.w900, fontSize: 18)),
                                ),
                                label: const Text('Continuar con Google', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  side: BorderSide(color: Colors.grey.shade300),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                              ),

                              const SizedBox(height: 16),

                              // Demo credentials
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppTheme.cream,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: AppTheme.divider),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Cuentas de prueba (contraseña: password)',
                                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                                    const SizedBox(height: 4),
                                    _demoTile('👤 Cliente',   'ana@email.com'),
                                    _demoTile('🔧 Empleado',  'empleado@pastryshop.com'),
                                    _demoTile('⚙️ Admin',     'admin@pastryshop.com'),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Back button
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.only(left: 8, top: 8),
              child: IconButton(
                icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                onPressed: () => context.canPop() ? context.pop() : context.go('/'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _demoTile(String label, String email) => GestureDetector(
    onTap: () {
      _emailCtrl.text = email;
      _passCtrl.text  = 'password';
    },
    child: Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Text('$label: $email', style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
    ),
  );
}
