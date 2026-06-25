import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:pastryshop/core/theme/app_theme.dart';
import 'package:pastryshop/presentation/providers/auth_provider.dart';

// ============================================================
//  VerifyEmailScreen — Verificación OTP de 6 dígitos
// ============================================================
class VerifyEmailScreen extends StatefulWidget {
  final String email;
  const VerifyEmailScreen({super.key, required this.email});

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen>
    with TickerProviderStateMixin {
  // 6 controllers, uno por dígito
  final List<TextEditingController> _controllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes =
      List.generate(6, (_) => FocusNode());

  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;
  late AnimationController _successController;
  late Animation<double> _successAnimation;

  // Countdown reenvío
  int _secondsLeft = 60;
  Timer? _timer;
  bool _canResend = false;

  @override
  void initState() {
    super.initState();

    // Shake animation para código incorrecto
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _shakeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.elasticIn),
    );

    // Success animation
    _successController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _successAnimation = CurvedAnimation(
      parent: _successController,
      curve: Curves.elasticOut,
    );

    _startTimer();
  }

  void _startTimer() {
    _secondsLeft = 60;
    _canResend = false;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) { t.cancel(); return; }
      setState(() {
        if (_secondsLeft > 0) {
          _secondsLeft--;
        } else {
          _canResend = true;
          t.cancel();
        }
      });
    });
  }

  @override
  void dispose() {
    for (final c in _controllers) c.dispose();
    for (final f in _focusNodes) f.dispose();
    _shakeController.dispose();
    _successController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  String get _otpCode => _controllers.map((c) => c.text).join();

  bool get _isComplete => _otpCode.length == 6 && !_otpCode.contains('');

  void _onDigitChanged(int index, String value) {
    if (value.length == 1 && index < 5) {
      _focusNodes[index + 1].requestFocus();
    }
    if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }
    setState(() {});
    if (_isComplete) _verify();
  }

  Future<void> _verify() async {
    if (!_isComplete) return;
    final auth = context.read<AuthProvider>();
    final ok = await auth.verifyEmail(
      email: widget.email,
      code: _otpCode,
    );
    if (!mounted) return;

    if (ok) {
      _successController.forward();
      await Future.delayed(const Duration(milliseconds: 800));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('¡Cuenta verificada! Bienvenido/a 🎉'),
            backgroundColor: AppTheme.success,
          ),
        );
        context.go('/');
      }
    } else {
      _shakeController.forward(from: 0);
      for (final c in _controllers) c.clear();
      _focusNodes[0].requestFocus();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(auth.error ?? 'Código incorrecto'),
          backgroundColor: AppTheme.error,
        ),
      );
    }
  }

  Future<void> _resend() async {
    if (!_canResend) return;
    final auth = context.read<AuthProvider>();
    final ok = await auth.resendCode(email: widget.email);
    if (!mounted) return;
    if (ok) {
      _startTimer();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Código reenviado ✉️'),
          backgroundColor: AppTheme.success,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(auth.error ?? 'Error al reenviar'),
          backgroundColor: AppTheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return Scaffold(
      body: Stack(
        children: [
          // Fondo degradado
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppTheme.primaryDark, AppTheme.primary],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 40),
                // Ícono animado
                ScaleTransition(
                  scale: _successAnimation,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 400),
                    child: _successController.isAnimating || _successController.isCompleted
                        ? const Icon(Icons.verified_rounded, size: 72, color: Colors.white, key: ValueKey('v'))
                        : const Icon(Icons.mark_email_unread_rounded, size: 72, color: Colors.white, key: ValueKey('e')),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Verifica tu correo',
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(color: Colors.white),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Text(
                    'Ingresa el código de 6 dígitos que enviamos a\n${widget.email}',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white70),
                  ),
                ),
                const SizedBox(height: 40),

                // Panel blanco
                Expanded(
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                    ),
                    padding: const EdgeInsets.fromLTRB(24, 40, 24, 24),
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          // Cajas OTP — con shake en error
                          AnimatedBuilder(
                            animation: _shakeAnimation,
                            builder: (context, child) {
                              final dx = _shakeController.isAnimating
                                  ? 8 * (0.5 - (_shakeAnimation.value % 1)).abs() * ((_shakeAnimation.value * 10).round().isEven ? 1 : -1)
                                  : 0.0;
                              return Transform.translate(
                                offset: Offset(dx, 0),
                                child: child,
                              );
                            },
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(6, (i) => _buildOtpBox(i)),
                            ),
                          ),

                          const SizedBox(height: 32),

                          // Botón verificar
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: (auth.loading || !_isComplete) ? null : _verify,
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              ),
                              child: auth.loading
                                  ? const SizedBox(
                                      width: 20, height: 20,
                                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                    )
                                  : const Text('Verificar cuenta', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            ),
                          ),

                          const SizedBox(height: 24),

                          // Reenviar código
                          Column(
                            children: [
                              Text(
                                '¿No recibiste el código?',
                                style: TextStyle(color: Colors.grey.shade600),
                              ),
                              const SizedBox(height: 8),
                              _canResend
                                  ? TextButton.icon(
                                      onPressed: auth.loading ? null : _resend,
                                      icon: const Icon(Icons.refresh_rounded),
                                      label: const Text('Reenviar código'),
                                    )
                                  : Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        const Icon(Icons.timer_outlined, size: 16, color: Colors.grey),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Reenviar en ${_secondsLeft}s',
                                          style: TextStyle(color: Colors.grey.shade500),
                                        ),
                                      ],
                                    ),
                            ],
                          ),

                          const SizedBox(height: 16),

                          // Cambiar correo
                          TextButton(
                            onPressed: () => context.go('/register'),
                            child: Text(
                              'Usar otro correo',
                              style: TextStyle(color: Colors.grey.shade500),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Botón atrás
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.only(left: 8, top: 8),
              child: IconButton(
                icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                onPressed: () => context.canPop() ? context.pop() : context.go('/login'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOtpBox(int index) {
    final filled = _controllers[index].text.isNotEmpty;
    return Container(
      width: 48,
      height: 58,
      margin: const EdgeInsets.symmetric(horizontal: 5),
      decoration: BoxDecoration(
        color: filled ? AppTheme.primary.withOpacity(0.08) : Colors.grey.shade50,
        border: Border.all(
          color: filled ? AppTheme.primary : Colors.grey.shade300,
          width: filled ? 2 : 1.5,
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: filled
            ? [BoxShadow(color: AppTheme.primary.withOpacity(0.15), blurRadius: 8, offset: const Offset(0, 3))]
            : [],
      ),
      child: TextField(
        controller: _controllers[index],
        focusNode: _focusNodes[index],
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        maxLength: 1,
        style: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: AppTheme.primary,
        ),
        decoration: const InputDecoration(
          counterText: '',
          border: InputBorder.none,
        ),
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        onChanged: (v) => _onDigitChanged(index, v),
      ),
    );
  }
}
