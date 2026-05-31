import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:pastryshop/core/theme/app_theme.dart';
import 'package:pastryshop/presentation/providers/auth_provider.dart';

// ============================================================
//  RegisterScreen
// ============================================================
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey      = GlobalKey<FormState>();
  final _nombreCtrl   = TextEditingController();
  final _apellidoCtrl = TextEditingController();
  final _emailCtrl    = TextEditingController();
  final _telCtrl      = TextEditingController();
  final _dirCtrl      = TextEditingController();
  final _passCtrl     = TextEditingController();
  final _pass2Ctrl    = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    for (final c in [_nombreCtrl, _apellidoCtrl, _emailCtrl, _telCtrl, _dirCtrl, _passCtrl, _pass2Ctrl]) c.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    final ok   = await auth.register(
      nombre: _nombreCtrl.text.trim(),
      apellido: _apellidoCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
      password: _passCtrl.text,
      telefono: _telCtrl.text.trim(),
      direccion: _dirCtrl.text.trim(),
    );
    if (!mounted) return;
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('¡Registro exitoso! Bienvenido/a 🎉'), backgroundColor: AppTheme.success),
      );
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
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppTheme.primaryDark, AppTheme.primary],
                begin: Alignment.topCenter, end: Alignment.bottomCenter,
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 32),
                Text('Crear cuenta', style: Theme.of(context).textTheme.headlineLarge?.copyWith(color: Colors.white)),
                Text('Únete a la familia', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white70)),
                const SizedBox(height: 32),
                Expanded(
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                    ),
                    padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                    child: SingleChildScrollView(
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(children: [
                              Expanded(child: TextFormField(
                                controller: _nombreCtrl,
                                decoration: const InputDecoration(labelText: 'Nombre', prefixIcon: Icon(Icons.person_outline)),
                                validator: (v) => v == null || v.isEmpty ? 'Requerido' : null,
                              )),
                              const SizedBox(width: 12),
                              Expanded(child: TextFormField(
                                controller: _apellidoCtrl,
                                decoration: const InputDecoration(labelText: 'Apellido'),
                                validator: (v) => v == null || v.isEmpty ? 'Requerido' : null,
                              )),
                            ]),
                            const SizedBox(height: 14),
                            TextFormField(
                              controller: _emailCtrl,
                              keyboardType: TextInputType.emailAddress,
                              decoration: const InputDecoration(labelText: 'Correo electrónico', prefixIcon: Icon(Icons.email_outlined)),
                              validator: (v) => v == null || !v.contains('@') ? 'Email inválido' : null,
                            ),
                            const SizedBox(height: 14),
                            TextFormField(
                              controller: _telCtrl,
                              keyboardType: TextInputType.phone,
                              decoration: const InputDecoration(labelText: 'Teléfono (opcional)', prefixIcon: Icon(Icons.phone_outlined)),
                            ),
                            const SizedBox(height: 14),
                            TextFormField(
                              controller: _dirCtrl,
                              decoration: const InputDecoration(labelText: 'Dirección (opcional)', prefixIcon: Icon(Icons.location_on_outlined)),
                            ),
                            const SizedBox(height: 14),
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
                            const SizedBox(height: 14),
                            TextFormField(
                              controller: _pass2Ctrl,
                              obscureText: true,
                              decoration: const InputDecoration(labelText: 'Confirmar contraseña', prefixIcon: Icon(Icons.lock_outline)),
                              validator: (v) => v != _passCtrl.text ? 'Las contraseñas no coinciden' : null,
                            ),
                            const SizedBox(height: 28),
                            ElevatedButton(
                              onPressed: auth.loading ? null : _register,
                              child: auth.loading
                                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                : const Text('Crear cuenta'),
                            ),
                            const SizedBox(height: 16),
                            // Google Auth Button
                            OutlinedButton.icon(
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Firebase no está configurado. Falta google-services.json.'),
                                    backgroundColor: Colors.orange,
                                    duration: Duration(seconds: 4),
                                  )
                                );
                              },
                              icon: Image.network('https://upload.wikimedia.org/wikipedia/commons/c/c1/Google_%22G%22_logo.svg', width: 24, height: 24),
                              label: const Text('Registrarse con Google', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                side: BorderSide(color: Colors.grey.shade300),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text('¿Ya tienes cuenta? '),
                                GestureDetector(
                                  onTap: () => context.pushReplacement('/login'),
                                  child: const Text('Inicia sesión', style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold)),
                                ),
                              ],
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
}
