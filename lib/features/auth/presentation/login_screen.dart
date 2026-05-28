import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kinetra/core/constants/app_routes.dart';
import 'package:kinetra/core/providers/providers.dart';
import 'package:kinetra/core/theme/app_colors.dart';
import 'package:kinetra/core/utils/app_snackbar.dart';
import 'package:kinetra/core/utils/auth_error_mapper.dart';
import 'package:kinetra/core/utils/validators.dart';
import 'package:kinetra/core/widgets/kinetra_primary_button.dart';
import 'package:kinetra/core/widgets/kinetra_text_field.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      await ref.read(authRepositoryProvider).signIn(
            email: _emailController.text,
            password: _passwordController.text,
          );
      if (mounted) AppSnackbar.success(context, 'Login berhasil');
    } catch (e) {
      if (mounted) AppSnackbar.error(context, AuthErrorMapper.message(e));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 32),
                ShaderMask(
                  shaderCallback: (b) => AppColors.gradient.createShader(b),
                  child: Text(
                    'Kinetra',
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Masuk untuk melanjutkan latihan',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 40),
                KinetraTextField(
                  controller: _emailController,
                  label: 'Email',
                  keyboardType: TextInputType.emailAddress,
                  prefixIcon: Icons.email_outlined,
                  validator: Validators.email,
                ),
                const SizedBox(height: 16),
                KinetraTextField(
                  controller: _passwordController,
                  label: 'Password',
                  obscureText: true,
                  prefixIcon: Icons.lock_outline,
                  validator: Validators.password,
                ),
                const SizedBox(height: 32),
                KinetraPrimaryButton(
                  label: 'Login',
                  isLoading: _isLoading,
                  onPressed: _login,
                ),
                const SizedBox(height: 24),
                Center(
                  child: TextButton(
                    onPressed: () => context.push(AppRoutes.register),
                    child: const Text('Belum punya akun? Daftar'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
