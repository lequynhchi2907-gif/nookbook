import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nookbook/core/network/api_error.dart';
import 'package:nookbook/core/router/app_routes.dart';
import 'package:nookbook/core/theme/app_colors.dart';
import 'package:nookbook/core/widgets/primary_button.dart';
import 'package:nookbook/features/auth/application/auth_providers.dart';

/// Màn 20 "Đăng nhập người dùng" và màn 21 "Đăng nhập quản trị viên" (chuyển bằng tab).
class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _loading = false;
  bool _obscure = true;
  bool _admin = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await ref
          .read(authProvider.notifier)
          .login(_email.text.trim(), _password.text, asAdmin: _admin);
      if (mounted) {
        context.go(_admin ? AppRoutes.adminDashboard : AppRoutes.home);
      }
    } catch (e) {
      if (mounted) setState(() => _error = errorMessage(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _comingSoon(String what) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$what chưa được hỗ trợ ở phiên bản này.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('NookBook', style: theme.textTheme.headlineMedium),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        onPressed: () => context.go(AppRoutes.home),
                        icon: const Icon(Icons.arrow_back, size: 16),
                        label: const Text('Trở về'),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.textSecondary,
                          padding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                    _RoleTabs(
                      admin: _admin,
                      onChanged: (v) => setState(() {
                        _admin = v;
                        _error = null;
                      }),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      _admin ? 'KHÔNG GIAN QUẢN TRỊ' : 'CHÀO MỪNG ĐẾN NOOKBOOK',
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _admin ? 'Đăng nhập quản trị' : 'Thật vui khi gặp lại bạn.',
                      style: theme.textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _admin
                          ? 'Chỉ dành cho nhân sự được cấp quyền.'
                          : 'Đăng nhập để tiếp tục hành trình đọc của bạn.',
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 24),
                    const _Label('Email'),
                    TextFormField(
                      controller: _email,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        hintText: _admin ? 'admin@nookbook.vn' : 'ban@email.com',
                      ),
                      validator: (v) => (v == null || !v.contains('@'))
                          ? 'Nhập email hợp lệ'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    const _Label('Mật khẩu'),
                    TextFormField(
                      controller: _password,
                      obscureText: _obscure,
                      decoration: InputDecoration(
                        hintText: 'Nhập mật khẩu của bạn',
                        suffixIcon: IconButton(
                          onPressed: () => setState(() => _obscure = !_obscure),
                          icon: Icon(_obscure
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined),
                        ),
                      ),
                      validator: (v) =>
                          (v == null || v.isEmpty) ? 'Nhập mật khẩu' : null,
                    ),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton(
                        onPressed: () => _comingSoon('Khôi phục mật khẩu'),
                        style: TextButton.styleFrom(padding: EdgeInsets.zero),
                        child: const Text('Quên mật khẩu?'),
                      ),
                    ),
                    if (_error != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.dangerSoft,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(_error!,
                            style: const TextStyle(color: AppColors.danger)),
                      ),
                      const SizedBox(height: 12),
                    ],
                    PrimaryButton(
                      label: _admin ? 'Đăng nhập quản trị' : 'Đăng nhập',
                      isLoading: _loading,
                      onPressed: _submit,
                    ),
                    const SizedBox(height: 20),
                    if (_admin)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: const Text(
                          'Tài khoản quản trị được cấp bởi NookBook. Liên hệ người phụ trách nếu bạn cần quyền truy cập.',
                          style: TextStyle(
                              color: AppColors.textSecondary, fontSize: 13, height: 1.4),
                        ),
                      )
                    else ...[
                      const Center(
                        child: Text('hoặc tiếp tục với',
                            style: TextStyle(
                                color: AppColors.textSecondary, fontSize: 12)),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => _comingSoon('Đăng nhập Google'),
                              child: const Text('Google'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => _comingSoon('Đăng nhập Facebook'),
                              child: const Text('Facebook'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Center(
                        child: Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            const Text('Chưa có tài khoản? ',
                                style: TextStyle(fontSize: 13)),
                            GestureDetector(
                              onTap: () => context.go(AppRoutes.register),
                              child: const Text(
                                'Đăng ký ngay',
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
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(text,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
      );
}

/// Thanh chuyển "Người dùng / Quản trị viên".
class _RoleTabs extends StatelessWidget {
  const _RoleTabs({required this.admin, required this.onChanged});

  final bool admin;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    Widget tab(String label, IconData icon, bool selected, VoidCallback onTap) {
      return Expanded(
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: selected ? Colors.white : Colors.transparent,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon,
                    size: 16,
                    color: selected ? AppColors.primary : AppColors.textSecondary),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: selected ? AppColors.primary : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.cardTint,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          tab('Người dùng', Icons.person_outline, !admin, () => onChanged(false)),
          tab('Quản trị viên', Icons.shield_outlined, admin, () => onChanged(true)),
        ],
      ),
    );
  }
}
