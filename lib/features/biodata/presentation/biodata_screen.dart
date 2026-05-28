import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kinetra/core/constants/app_routes.dart';
import 'package:kinetra/core/constants/target_latihan.dart';
import 'package:kinetra/core/providers/providers.dart';
import 'package:kinetra/core/theme/app_colors.dart';
import 'package:kinetra/core/utils/app_snackbar.dart';
import 'package:kinetra/core/utils/validators.dart';
import 'package:kinetra/core/widgets/kinetra_primary_button.dart';
import 'package:kinetra/core/widgets/kinetra_text_field.dart';

class BiodataScreen extends ConsumerStatefulWidget {
  const BiodataScreen({super.key});

  @override
  ConsumerState<BiodataScreen> createState() => _BiodataScreenState();
}

class _BiodataScreenState extends ConsumerState<BiodataScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usiaController = TextEditingController();
  String? _jenisKelamin;
  TargetLatihan? _target;
  bool _isLoading = false;

  static const _genders = ['Laki-laki', 'Perempuan'];

  @override
  void dispose() {
    _usiaController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_jenisKelamin == null) {
      AppSnackbar.error(context, 'Pilih jenis kelamin');
      return;
    }
    if (_target == null) {
      AppSnackbar.error(context, 'Pilih target latihan');
      return;
    }

    final user = ref.read(authStateProvider).valueOrNull;
    if (user == null) return;

    setState(() => _isLoading = true);
    try {
      await ref.read(biodataRepositoryProvider).saveBiodata(
            userId: user.uid,
            jenisKelamin: _jenisKelamin!,
            usia: int.parse(_usiaController.text),
            targetLatihan: _target!,
          );
      if (mounted) {
        AppSnackbar.success(context, 'Biodata tersimpan');
        context.go(AppRoutes.home);
      }
    } catch (e) {
      if (mounted) AppSnackbar.error(context, e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Biodata')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Lengkapi profil Anda',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                const Text('Untuk rekomendasi latihan yang personal'),
                const SizedBox(height: 24),
                DropdownButtonFormField<String>(
                  // ignore: deprecated_member_use
                  value: _jenisKelamin,
                  decoration: const InputDecoration(labelText: 'Jenis Kelamin'),
                  items: _genders
                      .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                      .toList(),
                  onChanged: (v) => setState(() => _jenisKelamin = v),
                ),
                const SizedBox(height: 16),
                KinetraTextField(
                  controller: _usiaController,
                  label: 'Usia',
                  keyboardType: TextInputType.number,
                  prefixIcon: Icons.cake_outlined,
                  validator: Validators.age,
                ),
                const SizedBox(height: 24),
                Text(
                  'Target Latihan',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: Colors.white,
                      ),
                ),
                const SizedBox(height: 12),
                ...TargetLatihan.values.map((t) {
                  final selected = _target == t;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: FilterChip(
                      label: Text(t.label),
                      selected: selected,
                      onSelected: (_) => setState(() => _target = t),
                      selectedColor: AppColors.accentCyan.withValues(alpha: 0.3),
                      checkmarkColor: AppColors.accentGreen,
                    ),
                  );
                }),
                const SizedBox(height: 32),
                KinetraPrimaryButton(
                  label: 'Simpan & Lanjut',
                  isLoading: _isLoading,
                  onPressed: _save,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
