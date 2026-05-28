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

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _namaController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _namaController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      await ref.read(authRepositoryProvider).signUp(
            nama: _namaController.text,
            email: _emailController.text,
            password: _passwordController.text,
          );
      if (mounted) {
        AppSnackbar.success(context, 'Registrasi berhasil');
        context.go(AppRoutes.biodata);
      }
    } catch (e) {
      if (mounted) AppSnackbar.error(context, AuthErrorMapper.message(e));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShaderMask(
                  shaderCallback: (b) => AppColors.gradient.createShader(b),
                  child: Text(
                    'Daftar',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                  ),
                ),
                const SizedBox(height: 8),
                const Text('Buat akun member gym Kinetra'),
                const SizedBox(height: 32),
                KinetraTextField(
                  controller: _namaController,
                  label: 'Nama',
                  prefixIcon: Icons.person_outline,
                  validator: (v) => Validators.requiredField(v, 'Nama'),
                ),
                const SizedBox(height: 16),
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
                  label: 'Register',
                  isLoading: _isLoading,
                  onPressed: _register,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
