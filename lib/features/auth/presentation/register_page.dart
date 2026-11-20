import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nookbook/core/network/api_error.dart';
import 'package:nookbook/core/router/app_routes.dart';
import 'package:nookbook/core/theme/app_colors.dart';
import 'package:nookbook/core/widgets/primary_button.dart';
import 'package:nookbook/features/account/application/profile_providers.dart';
import 'package:nookbook/features/auth/application/auth_providers.dart';

/// Màn 22 "Đăng ký" và màn 23 "Lỗi xác thực biểu mẫu".
class RegisterPage extends ConsumerStatefulWidget {
  const RegisterPage({super.key});

  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _lastName = TextEditingController(); // "Họ"
  final _firstName = TextEditingController(); // "Tên"
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _repeatPassword = TextEditingController();
  final _address = TextEditingController();
  bool _loading = false;
  bool _obscure = true;
  bool _submitted = false;
  bool _invalid = false;
  String? _error;

  @override
  void dispose() {
    _lastName.dispose();
    _firstName.dispose();
    _email.dispose();
    _password.dispose();
    _repeatPassword.dispose();
    _address.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _submitted = true);
    final ok = _formKey.currentState!.validate();
    setState(() => _invalid = !ok);
    if (!ok) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final address = _address.text.trim();
      await ref.read(authRepositoryProvider).register(
            email: _email.text.trim(),
            password: _password.text,
            repeatPassword: _repeatPassword.text,
            firstName: _firstName.text.trim(),
            lastName: _lastName.text.trim(),
            shippingAddress: address.isEmpty ? null : address,
          );
      await ref.read(profileProvider.notifier).onRegister(
            lastName: _lastName.text.trim(),
            firstName: _firstName.text.trim(),
            email: _email.text.trim(),
            address: address.isEmpty ? null : address,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đăng ký thành công, hãy đăng nhập.')),
      );
      context.go(AppRoutes.login);
    } catch (e) {
      if (mounted) setState(() => _error = errorMessage(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mode = _submitted
        ? AutovalidateMode.onUserInteraction
        : AutovalidateMode.disabled;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Đăng ký'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go(AppRoutes.login),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _formKey,
                autovalidateMode: mode,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('Mở trang sách mới.', style: theme.textTheme.headlineMedium),
                    const SizedBox(height: 8),
                    Text(
                      'Tạo tài khoản để lưu những cuốn sách bạn yêu.',
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 20),
                    if (_invalid || _error != null) ...[
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.dangerSoft,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.danger),
                        ),
                        child: Text(
                          _error ?? 'Vui lòng kiểm tra lại thông tin bên dưới.',
                          style: const TextStyle(color: AppColors.danger),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: _Field(
                            label: 'Họ',
                            controller: _lastName,
                            validator: _required('Nhập họ'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _Field(
                            label: 'Tên',
                            controller: _firstName,
                            validator: _required('Nhập tên'),
                          ),
                        ),
                      ],
                    ),
                    _Field(
                      label: 'Email',
                      controller: _email,
                      keyboardType: TextInputType.emailAddress,
                      validator: (v) {
                        final t = (v ?? '').trim();
                        final ok = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(t);
                        return ok ? null : 'Vui lòng nhập địa chỉ email hợp lệ.';
                      },
                    ),
                    _Field(
                      label: 'Mật khẩu',
                      controller: _password,
                      obscure: _obscure,
                      suffix: IconButton(
                        onPressed: () => setState(() => _obscure = !_obscure),
                        icon: Icon(_obscure
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined),
                      ),
                      validator: (v) => (v == null || v.length < 8)
                          ? 'Mật khẩu cần có ít nhất 8 ký tự.'
                          : null,
                    ),
                    _Field(
                      label: 'Nhập lại mật khẩu',
                      controller: _repeatPassword,
                      obscure: _obscure,
                      validator: (v) => v != _password.text
                          ? 'Mật khẩu nhập lại chưa khớp.'
                          : null,
                    ),
                    _Field(
                      label: 'Địa chỉ',
                      controller: _address,
                      validator: null,
                    ),
                    Text(
                      'Bằng việc đăng ký, bạn đồng ý với Điều khoản sử dụng và Chính sách bảo mật của NookBook.',
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 16),
                    PrimaryButton(
                      label: 'Tạo tài khoản',
                      isLoading: _loading,
                      onPressed: _submit,
                    ),
                    const SizedBox(height: 12),
                    Center(
                      child: Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          const Text('Đã có tài khoản? ',
                              style: TextStyle(fontSize: 13)),
                          GestureDetector(
                            onTap: () => context.go(AppRoutes.login),
                            child: const Text(
                              'Đăng nhập',
                              style: TextStyle(
                                fontSize: 13,
                                color: AppColors.primary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String? Function(String?) _required(String message) =>
      (v) => (v == null || v.trim().isEmpty) ? message : null;
}

class _Field extends StatelessWidget {
  const _Field({
    required this.label,
    required this.controller,
    required this.validator,
    this.keyboardType,
    this.obscure = false,
    this.suffix,
  });

  final String label;
  final TextEditingController controller;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final bool obscure;
  final Widget? suffix;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
          const SizedBox(height: 8),
          TextFormField(
            controller: controller,
            obscureText: obscure,
            keyboardType: keyboardType,
            validator: validator,
            decoration: InputDecoration(suffixIcon: suffix),
          ),
        ],
      ),
    );
  }
}
