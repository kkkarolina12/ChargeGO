import 'package:chargego/src/core/widgets/premium_widgets.dart';
import 'package:chargego/src/features/auth/data/auth_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _codeController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  bool _codeSent = false;

  @override
  void dispose() {
    _emailController.dispose();
    _codeController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      if (!_codeSent) {
        // Step 1: just advance to code+new password fields
        setState(() => _codeSent = true);
      } else {
        // Step 2: reset password with code
        await ref.read(authRepositoryProvider).resetPasswordWithRecoveryCode(
          email: _emailController.text.trim(),
          code: _codeController.text.trim(),
          newPassword: _newPasswordController.text,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Contrasena actualizada correctamente'),
            ),
          );
          context.go('/login');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PremiumScaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 18, 24, 28),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Center(child: BrandLogo(size: 96)),
              const SizedBox(height: 24),
              Text(
                'Recuperar contrasena',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: premiumTextColor(context),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _codeSent
                    ? 'Introduce el codigo de recuperacion y tu nueva contrasena.'
                    : 'Introduce tu correo electronico para continuar.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: premiumMutedColor(context),
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 30),
              PremiumCard(
                child: Column(
                  children: [
                    TextFormField(
                      controller: _emailController,
                      enabled: !_codeSent,
                      decoration: const InputDecoration(
                        labelText: 'Correo electronico',
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null ||
                            value.isEmpty ||
                            !value.contains('@')) {
                          return 'Introduce un correo valido';
                        }
                        return null;
                      },
                    ),
                    if (_codeSent) ...[
                      const SizedBox(height: 18),
                      TextFormField(
                        controller: _codeController,
                        decoration: const InputDecoration(
                          labelText: 'Codigo de recuperacion',
                          prefixIcon: Icon(Icons.vpn_key_outlined),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Introduce el codigo de recuperacion';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 18),
                      TextFormField(
                        controller: _newPasswordController,
                        decoration: const InputDecoration(
                          labelText: 'Nueva contrasena',
                          prefixIcon: Icon(Icons.lock_outline),
                        ),
                        obscureText: true,
                        validator: (value) {
                          if (value == null || value.length < 6) {
                            return 'La contrasena debe tener al menos 6 caracteres';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 18),
                      TextFormField(
                        controller: _confirmPasswordController,
                        decoration: const InputDecoration(
                          labelText: 'Confirmar contrasena',
                          prefixIcon: Icon(Icons.lock_outline),
                        ),
                        obscureText: true,
                        validator: (value) {
                          if (value != _newPasswordController.text) {
                            return 'Las contrasenas no coinciden';
                          }
                          return null;
                        },
                      ),
                    ],
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: GradientButton(
                        label: _codeSent
                            ? 'Restablecer contrasena'
                            : 'Continuar',
                        icon: _codeSent
                            ? Icons.check_circle_outline
                            : Icons.arrow_forward_rounded,
                        isLoading: _isLoading,
                        onPressed: _submit,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '¿Recuerdas tu contrasena? ',
                    style: TextStyle(color: premiumMutedColor(context)),
                  ),
                  TextButton(
                    onPressed: () => context.go('/login'),
                    child: const Text('Iniciar sesion'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
